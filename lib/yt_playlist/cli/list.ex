defmodule YtPlaylist.CLI.List do
  @moduledoc """
  Handles the list command - shows cached playlists.
  """

  alias YtPlaylist.{Config, Playlist}

  @doc """
  Lists all cached playlist databases.

  Shows playlist ID and full path for easy deletion.
  """
  def run do
    config_dir = Config.config_dir()

    case File.ls(config_dir) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".db"))
        |> Enum.sort()
        |> format_output(config_dir)

      {:error, :enoent} ->
        IO.puts("No cached playlists.")
        :ok
    end
  end

  defp format_output([], _config_dir) do
    IO.puts("No cached playlists.")
    :ok
  end

  defp format_output(db_files, config_dir) do
    db_files
    |> Enum.each(fn file ->
      playlist_id = Playlist.id_from_filename(file)
      full_path = Path.join(config_dir, file)
      IO.puts("#{playlist_id}  #{full_path}")
    end)

    :ok
  end
end
