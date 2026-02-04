defmodule YtPlaylist.Config do
  @moduledoc """
  Application configuration and directory management.

  Stores user preferences in `~/.config/yt-playlist/config.json`.
  """

  @default_config_dir Path.expand("~/.config/yt-playlist")

  def config_dir do
    Application.get_env(:yt_playlist, :config_dir, @default_config_dir)
  end

  @doc """
  Returns the path to the JSON config file.
  """
  def config_path, do: Path.join(config_dir(), "config.json")

  def ensure_dirs! do
    File.mkdir_p!(config_dir())
  end

  @doc """
  Reads and decodes the config file.

  Returns `{:ok, map}` or `:empty` if the file is missing.
  """
  def read do
    case File.read(config_path()) do
      {:ok, contents} -> {:ok, Jason.decode!(contents)}
      {:error, :enoent} -> :empty
    end
  end

  @doc """
  Encodes a map to JSON and writes it to the config file.
  """
  def write!(config) when is_map(config) do
    ensure_dirs!()
    config |> Jason.encode!(pretty: true) |> then(&File.write!(config_path(), &1))
  end

  @doc """
  Returns the configured browser, or nil if not set.
  """
  def browser do
    case read() do
      {:ok, %{"browser" => browser}} -> browser
      _ -> nil
    end
  end

  # TODO: consider replacing this with a more gneric update method?
  @doc """
  Saves the browser preference, preserving other config keys.
  """
  def save_browser!(browser) when is_binary(browser) do
    case read() do
      {:ok, config} -> config
      :empty -> %{}
    end
    |> Map.put("browser", browser)
    |> write!()
  end
end
