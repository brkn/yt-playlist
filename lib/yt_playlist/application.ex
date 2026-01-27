defmodule YtPlaylist.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    if Burrito.Util.running_standalone?() do
      args = Burrito.Util.Args.get_arguments()
      result = YtPlaylist.CLI.main(args)

      code =
        case result do
          :ok -> 0
          {:ok, _} -> 0
          _ -> 1
        end

      System.halt(code)
    end

    children = []
    opts = [strategy: :one_for_one, name: YtPlaylist.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
