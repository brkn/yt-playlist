defmodule YtPlaylist.Repo do
  @moduledoc """
  SQLite database boundary module for storing video metadata.

  Uses dynamic database paths since each playlist gets its own database file.
  """

  # TODO: we don't need to up and down the process for the repo via superviser all the time.
  # In future we should do it better.

  use Ecto.Repo, otp_app: :yt_playlist, adapter: Ecto.Adapters.SQLite3

  import Ecto.Query

  alias YtPlaylist.HotScore
  alias YtPlaylist.Video

  @create_table_sql """
  CREATE TABLE IF NOT EXISTS videos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    playlist_name TEXT NOT NULL,
    title TEXT NOT NULL,
    channel TEXT,
    uploader TEXT,
    duration INTEGER,
    duration_string TEXT,
    webpage_url TEXT UNIQUE NOT NULL,
    view_count INTEGER,
    like_count INTEGER,
    channel_follower_count INTEGER,
    channel_is_verified BOOLEAN,
    description TEXT,
    categories TEXT,
    tags TEXT,
    upload_date TEXT,
    availability TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )
  """

  @doc """
  Check if database file exists and when it was indexed.

  Returns `{:ok, mtime}` for existing database, or `{:error, :not_found}`.
  """
  def db_exists?(db_path) do
    case File.stat(db_path, time: :posix) do
      {:ok, %{mtime: mtime}} -> {:ok, mtime}
      {:error, :enoent} -> {:error, :not_found}
    end
  end

  @doc """
  Save videos to database. Creates schema if needed.

  Returns `{:ok, count}` with number of videos saved.
  """
  def save_videos(db_path, playlist_name, videos) do
    with_connection(db_path, fn ->
      Ecto.Adapters.SQL.query!(__MODULE__, @create_table_sql)

      count =
        videos
        |> Enum.map(&Video.to_changeset(&1, playlist_name))
        |> Enum.count(fn changeset ->
          case insert(changeset, on_conflict: :nothing) do
            {:ok, %{id: id}} when not is_nil(id) -> true
            {:ok, _} -> false
            {:error, _} -> false
          end
        end)

      {:ok, count}
    end)
  end

  @doc """
  Fetch all videos from database.

  Returns `{:ok, videos}` list of Video structs.
  """
  def all_videos(db_path) do
    with_connection(db_path, fn ->
      {:ok, all(Video)}
    end)
  end

  @doc """
  Query videos with sorting and limiting.

  Options:
    - `:sort` - `:hot` (engagement/recency score) or `:recent` (upload_date desc, default)
    - `:limit` - integer or nil (default: nil, meaning all)

  Returns `{:ok, videos}` list of Video structs.
  """
  def videos(db_path, opts \\ []) do
    sort = Keyword.get(opts, :sort, :recent)
    limit = Keyword.get(opts, :limit)

    with_connection(db_path, fn ->
      videos = all(sorted_videos_query(sort))

      sorted =
        case sort do
          :hot -> sort_by_hot_score(videos)
          _ -> videos
        end

      limited = if limit, do: Enum.take(sorted, limit), else: sorted
      {:ok, limited}
    end)
  end

  defp sort_by_hot_score(videos) do
    videos
    |> Enum.map(fn video ->
      days = HotScore.days_since_upload(video.upload_date)
      score = HotScore.calculate(video.view_count, video.like_count, days)
      {video, score}
    end)
    |> Enum.sort_by(fn {_, score} -> score end, :desc)
    |> Enum.map(fn {video, _} -> video end)
  end

  defp with_connection(db_path, fun) do
    {:ok, _pid} = start_link(database: db_path, name: __MODULE__, pool_size: 1)
    result = fun.()
    Supervisor.stop(__MODULE__)
    result
  end

  defp sorted_videos_query(:recent) do
    from(v in Video, order_by: [desc: v.upload_date])
  end

  defp sorted_videos_query(:hot) do
    # Hot sorting is done in Elixir via sort_by_hot_score/1
    from(v in Video)
  end
end
