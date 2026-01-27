defmodule YtPlaylist.CLI do
  @moduledoc """
  Command-line interface entry point for yt_playlist.
  """

  alias YtPlaylist.CLI.Extract

  @doc """
  Main entry point for the escript.
  """
  @dialyzer {:nowarn_function, main: 1}
  def main(args) do
    case args do
      ["extract", url] -> Extract.run(url)
      ["export", _db_path] -> {:error, "not implemented"}
      ["query", _db_path] -> {:error, "not implemented"}
      _ -> exit_with_usage()
    end
    |> handle_result()
  end

  @dialyzer {:nowarn_function, handle_result: 1}
  defp handle_result({:ok, msg}), do: IO.puts(msg)
  defp handle_result(:ok), do: :ok
  defp handle_result({:error, reason}), do: exit_with_error(reason)

  @dialyzer {:nowarn_function, exit_with_usage: 0}
  defp exit_with_usage do
    IO.puts("Usage: yt_playlist [extract <url>|export <db>|query <db>]")
    System.halt(1)
  end

  @dialyzer {:nowarn_function, exit_with_error: 1}
  defp exit_with_error(reason) do
    IO.puts("Error: #{reason}")
    System.halt(1)
  end
end
