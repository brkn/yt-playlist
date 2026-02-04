defmodule YtPlaylist.Playlist do
  @moduledoc """
  Playlist identification and path resolution.
  """

  alias YtPlaylist.Config

  @doc """
  Extracts the playlist ID from a YouTube playlist URL.

  ## Examples
    iex> YtPlaylist.Playlist.id("https://www.youtube.com/playlist?list=PLxxxxx")
    {:ok, "PLxxxxx"}

    iex> YtPlaylist.Playlist.id("https://www.youtube.com/playlist?list=PLxxxxx&foo=bar")
    {:ok, "PLxxxxx"}

    iex> YtPlaylist.Playlist.id("https://www.youtube.com/watch?v=abc123")
    {:error, "could not extract playlist ID from URL"}

    iex> YtPlaylist.Playlist.id("https://www.youtube.com/channel/UCxxxxx")
    {:error, "could not extract playlist ID from URL"}
  """
  def id(url) do
    with %URI{query: query} when query != nil <- URI.parse(url),
         {:ok, id} <- query |> URI.decode_query() |> Map.fetch("list") do
      {:ok, id}
    else
      _ -> {:error, "could not extract playlist ID from URL"}
    end
  end

  @doc """
  Extracts the playlist ID from a database filename.

  ## Examples
    iex> YtPlaylist.Playlist.id_from_filename("PLxxxxx.db")
    "PLxxxxx"
  """
  def id_from_filename(filename) do
    String.trim_trailing(filename, ".db")
  end

  @doc """
  Returns the database path for a playlist ID.

  ## Examples
    iex> YtPlaylist.Playlist.db_path("PLxxxxx") |> String.ends_with?("PLxxxxx.db")
    true
  """
  def db_path(playlist_id) do
    Config.config_dir() |> Path.join("#{playlist_id}.db")
  end
end
