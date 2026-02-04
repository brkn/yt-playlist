defmodule YtPlaylist.CLI.Query do
  @moduledoc """
  Handles the query command - displays videos from database as ASCII table.
  """

  alias YtPlaylist.{Repo, Formatter.AsciiTable}

  @supported_sorts [:hot, :recent, :popular]

  @doc """
  Queries videos from database and displays as ASCII table to stdout.

  Options:
    - `:sort` - :hot, :recent, :popular (default: :recent)
    - `:limit` - integer or nil
  """
  def run(db_path, opts \\ []) do
    sort = Keyword.get(opts, :sort, :recent)

    with :ok <- validate_db_exists(db_path),
         :ok <- validate_sort(sort),
         {:ok, videos} <- Repo.videos(db_path, opts) do
      videos
      |> AsciiTable.format()
      |> IO.puts()

      :ok
    end
  end

  defp validate_db_exists(db_path) do
    case Repo.db_exists?(db_path) do
      {:ok, _mtime} -> :ok
      {:error, :not_found} -> {:error, "database not found: #{db_path}"}
    end
  end

  defp validate_sort(sort) when sort in @supported_sorts, do: :ok
  defp validate_sort(sort), do: {:error, "sort '#{sort}' not implemented"}
end
