import Config

config :yt_playlist,
  ecto_repos: [YtPlaylist.Repo]

# Database path set dynamically at runtime
config :yt_playlist, YtPlaylist.Repo, database: ":memory:"
