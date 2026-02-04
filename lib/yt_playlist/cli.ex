defmodule YtPlaylist.CLI do
  @moduledoc """
  Command-line interface entry point for yt_playlist.
  """

  alias YtPlaylist.CLI.{Extract, Export, Query}
  alias YtPlaylist.Config

  @doc """
  Main entry point for the escript.
  """
  @dialyzer {:nowarn_function, main: 1}
  def main(args) do
    Config.ensure_dirs!()

    case args do
      ["extract", url] -> Extract.run(url)
      ["export-to-md" | rest] -> parse_export(rest)
      ["query" | rest] -> parse_query(rest)
      _ -> exit_with_usage()
    end
    |> handle_result()
  end

  defp parse_export([db_path | rest]) do
    {opts, _, _} =
      OptionParser.parse(rest, strict: [sort: :string, limit: :integer])

    sort =
      opts
      |> Keyword.get(:sort, "recent")
      |> String.to_atom()

    limit = Keyword.get(opts, :limit)

    Export.run(db_path, sort: sort, limit: limit)
  end

  defp parse_export([]), do: exit_with_usage()

  defp parse_query([db_path | rest]) do
    {opts, _, _} =
      OptionParser.parse(rest, strict: [sort: :string, limit: :integer])

    sort =
      opts
      |> Keyword.get(:sort, "recent")
      |> String.to_atom()

    limit = Keyword.get(opts, :limit)

    Query.run(db_path, sort: sort, limit: limit)
  end

  defp parse_query([]), do: exit_with_usage()

  @dialyzer {:nowarn_function, handle_result: 1}
  defp handle_result({:ok, msg}), do: IO.puts(msg)
  defp handle_result(:ok), do: :ok
  defp handle_result({:error, reason}), do: exit_with_error(reason)

  @dialyzer {:nowarn_function, exit_with_usage: 0}
  defp exit_with_usage do
    IO.puts("""
    Usage: yt_playlist <command>

    Commands:
      extract <url>                    Extract playlist to SQLite
      export-to-md <db> [options]      Export videos as markdown
      query <db> [options]             Query videos as ASCII table

    Options:
      --sort hot|recent|popular    Sort order (default: recent)
      --limit N            Limit output to N videos
    """)

    System.halt(1)
  end

  @dialyzer {:nowarn_function, exit_with_error: 1}
  defp exit_with_error(reason) do
    IO.puts("Error: #{reason}")
    System.halt(1)
  end
end
