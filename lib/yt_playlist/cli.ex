defmodule YtPlaylist.CLI do
  @moduledoc """
  Command-line interface entry point for yt_playlist.
  """

  alias YtPlaylist.CLI.{List, Query}
  alias YtPlaylist.Config

  @supported_sorts ~w(hot recent popular)

  @doc """
  Main entry point for the escript.
  """
  @dialyzer {:nowarn_function, main: 1}
  def main(args) do
    Config.ensure_dirs!()

    args
    |> parse_args()
    |> case do
      :list -> List.run()
      {:query, source, opts} -> Query.run(source, opts)
      error -> error
    end
    |> handle_command_result()
  end

  defp parse_args([]), do: {:error, :usage}
  defp parse_args(["list"]), do: :list

  defp parse_args(args) do
    args
    |> call_option_parser()
    |> case do
      {opts, [source], []} -> parse_opts(source, opts)
      {_, _, [{flag, _} | _]} -> {:error, "unknown option: #{flag}"}
      _ -> {:error, :usage}
    end
  end

  defp parse_opts(source, opts) do
    sort_option = Keyword.get(opts, :sort, "recent")

    with {:ok, sort} <- parse_sort(sort_option) do
      {:query, source, Keyword.put(opts, :sort, sort)}
    end
  end

  defp call_option_parser(args) do
    OptionParser.parse(args,
      strict: [sort: :string, limit: :integer, output: :string],
      aliases: [s: :sort, n: :limit, o: :output]
    )
  end

  @doc """
  Parses a sort string into a supported sort atom.
  """
  def parse_sort(sort) when sort in @supported_sorts, do: {:ok, String.to_atom(sort)}

  def parse_sort(sort) do
    {:error, "sort '#{sort}' not supported. Use: #{Enum.join(@supported_sorts, ", ")}"}
  end

  @dialyzer {:nowarn_function, handle_command_result: 1}
  defp handle_command_result({:ok, msg}), do: IO.puts(msg)
  defp handle_command_result(:ok), do: :ok
  defp handle_command_result({:error, :usage}), do: exit_with_usage()
  defp handle_command_result({:error, reason}), do: exit_with_error(reason)

  @dialyzer {:nowarn_function, exit_with_usage: 0}
  defp exit_with_usage do
    IO.puts("""
    Usage: yt_playlist <url|db_path> [options]
           yt_playlist list

    Commands:
      <url>       Extract and query a YouTube playlist (caches locally)
      <db_path>   Query an existing cached playlist
      list        Show all cached playlists

    Options:
      -s, --sort <method>   Sort by: hot, recent, popular (default: recent)
      -n, --limit <n>       Limit output to n videos
      -o <file>             Write markdown to file instead of ASCII table
    """)

    System.halt(1)
  end

  @dialyzer {:nowarn_function, exit_with_error: 1}
  defp exit_with_error(reason) do
    IO.puts("Error: #{reason}")
    System.halt(1)
  end
end
