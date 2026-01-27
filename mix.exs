defmodule YtPlaylist.MixProject do
  use Mix.Project

  def project do
    [
      app: :yt_playlist,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: YtPlaylist.CLI]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:ecto_sqlite3, "~> 0.22"}
    ]
  end
end
