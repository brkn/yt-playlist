defmodule YtPlaylist.CLI.Export do
  @moduledoc """
  Handles the export-to-md command - exports videos from database as markdown.
  """

  alias YtPlaylist.{Repo, Formatter.Markdown}

  @supported_sorts [:hot, :recent]

  @doc """
  Exports videos from database as markdown to stdout.

  Options:
    - `:sort` - :hot, :recent (default: :recent)
    - `:limit` - integer or nil
  """
  def run(db_path, opts \\ []) do
    sort = Keyword.get(opts, :sort, :recent)

    with :ok <- validate_db_exists(db_path),
         :ok <- validate_sort(sort),
         {:ok, videos} <- Repo.videos(db_path, opts) do
      videos
      |> Markdown.format()
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
