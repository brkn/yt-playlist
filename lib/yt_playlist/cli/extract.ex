defmodule YtPlaylist.CLI.Extract do
  @moduledoc """
  Handles the extract command - fetches playlist metadata and saves to SQLite.
  """

  alias YtPlaylist.{YtDlp, Repo}

  @doc """
  Extracts playlist metadata from URL and saves to a SQLite database.
  """
  def run(url) do
    with {:ok, title} <- YtDlp.playlist_title(url),
         db_path = sanitize_filename(title) <> ".db",
         :ok <- check_existing(db_path),
         {:ok, videos} <- YtDlp.fetch_playlist(url),
         {:ok, count} <- Repo.save_videos(db_path, title, videos) do
      {:ok, "Saved #{count} videos to #{db_path}"}
    end
  end

  defp sanitize_filename(name) do
    name
    |> String.replace(~r/[^a-zA-Z0-9_-]/, "_")
    |> String.replace(~r/_+/, "_")
  end

  defp check_existing(db_path) do
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
