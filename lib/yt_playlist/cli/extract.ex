defmodule YtPlaylist.CLI.Extract do
  @moduledoc """
  Handles the extract command - fetches playlist metadata and saves to SQLite.
  """

  alias YtPlaylist.{Config, YtDlp, Repo}

  @doc """
  Extracts playlist metadata from URL and saves to a SQLite database.

  Options:
    - `:force` - skip existing database check (default: false)
  """
  def run(url, opts \\ []) do
    force = Keyword.get(opts, :force, false)

    with {:ok, playlist_id} <- extract_playlist_id(url),
         {:ok, title} <- YtDlp.playlist_title(url),
         db_path = Config.db_path(playlist_id),
         :ok <- maybe_check_existing(db_path, force),
         {:ok, videos} <- YtDlp.fetch_playlist(url),
         {:ok, count} <- Repo.save_videos(db_path, title, videos) do
      {:ok, "Saved #{count} videos to #{db_path}"}
    end
  end

  @doc """
  Extracts the playlist ID from a YouTube playlist URL.

  Returns `{:ok, playlist_id}` or `{:error, reason}` if not found.
  """
  def extract_playlist_id(url) do
    with %URI{query: query} when query != nil <- URI.parse(url),
         {:ok, id} <- query |> URI.decode_query() |> Map.fetch("list") do
      {:ok, id}
    else
      _ -> {:error, "could not extract playlist ID from URL"}
    end
  end

  defp maybe_check_existing(_db_path, true), do: :ok

  defp maybe_check_existing(db_path, false) do
    case Repo.db_exists?(db_path) do
      {:error, :not_found} ->
        :ok

      {:ok, mtime} ->
        date = mtime |> DateTime.from_unix!() |> DateTime.to_date()
        IO.puts("Already indexed on #{date}. Continue? [y/n]")

        case IO.gets("") |> String.trim() |> String.downcase() do
          "y" -> :ok
          _ -> {:error, "aborted"}
        end
    end
  end
end
