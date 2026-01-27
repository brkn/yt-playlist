defmodule YtPlaylist.YtDlp do
  @moduledoc """
  Wrapper around yt-dlp CLI for extracting YouTube playlist metadata.
  """

  alias YtPlaylist.Video

  @doc """
  Fetches the title of a YouTube playlist.

  Returns `{:ok, title}` on success, `{:error, message}` on failure.
  """
  def playlist_title(url) do
    {output, exit_code} =
      System.cmd(
        "yt-dlp",
        [
          "--playlist-items",
          "1",
          "--print",
          "playlist_title",
          "--cookies-from-browser",
          "firefox",
          url
        ]
      )

    case exit_code do
      0 -> {:ok, String.trim(output)}
      _ -> {:error, "yt-dlp failed with exit code #{exit_code}"}
    end
  end

  @doc """
  Fetches all videos from a YouTube playlist.

  Returns `{:ok, videos}` on success where videos is a list of Video structs,
  or `{:error, message}` on failure.
  """
  def fetch_playlist(url) do
    {output, exit_code} =
      System.cmd(
        "yt-dlp",
        [
          "--skip-download",
          "--ignore-no-formats-error",
          "--dump-json",
          "--cookies-from-browser",
          "firefox",
          url
        ]
      )

    case exit_code do
      0 ->
        videos =
          output
          |> String.splitter("\n", trim: true)
          |> Stream.map(&Jason.decode!/1)
          |> Stream.map(&Video.from_json/1)
          |> Enum.to_list()

        {:ok, videos}

      _ ->
        {:error, "yt-dlp failed with exit code #{exit_code}"}
    end
  end
end
