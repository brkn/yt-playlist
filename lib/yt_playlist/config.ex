defmodule YtPlaylist.Config do
  @moduledoc """
  Application configuration and directory management.
  """

  @config_dir Path.expand("~/.config/yt-playlist")

  def config_dir, do: @config_dir

  def ensure_dirs! do
    File.mkdir_p!(config_dir())
  end
end
