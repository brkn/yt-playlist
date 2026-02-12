defmodule YtPlaylist.MixProject do
  use Mix.Project

  def project do
    [
      app: :yt_playlist,
      version: "0.1.3",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {YtPlaylist.Application, []}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:ecto_sqlite3, "~> 0.22"},
      {:burrito, "~> 1.0"}
    ]
  end

  defp releases do
    [
      yt_playlist: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            macos_arm64: [os: :darwin, cpu: :aarch64]
          ]
        ]
      ]
    ]
  end
end
