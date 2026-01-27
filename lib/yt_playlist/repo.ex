defmodule YtPlaylist.Repo do
  @moduledoc """
  SQLite database boundary module for storing video metadata.

  Uses dynamic database paths since each playlist gets its own database file.
  """

  # TODO: we don't need to up and down the process for the repo via superviser all the time.
  # In future we should do it better.

  use Ecto.Repo, otp_app: :yt_playlist, adapter: Ecto.Adapters.SQLite3

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
    {:ok, _pid} = start_link(database: db_path, name: __MODULE__, pool_size: 1)

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

    Supervisor.stop(__MODULE__)
    {:ok, count}
  end

  @doc """
  Fetch all videos from database.

  Returns `{:ok, videos}` list of Video structs.
  """
  def all_videos(db_path) do
    {:ok, _pid} = start_link(database: db_path, name: __MODULE__, pool_size: 1)

    videos = all(Video)

    Supervisor.stop(__MODULE__)
    {:ok, videos}
  end
end
