defmodule YtPlaylist.Config do
  @moduledoc """
  Manages application configuration and paths.
  """

  @config_dir Path.expand("~/.config/yt-playlist")

  def config_dir, do: @config_dir

  def db_path(playlist_id) do
    Path.join(config_dir(), playlist_id <> ".db")
  end

  def ensure_dirs! do
    File.mkdir_p!(config_dir())
  end
end
