defmodule YtPlaylist.CLI.Query do
  @moduledoc """
  Handles the query command - displays videos from database as ASCII table or markdown.
  """

  alias YtPlaylist.{Playlist, Repo, YtDlp}
  alias YtPlaylist.Formatter.{AsciiTable, Markdown}

  @supported_sorts [:hot, :recent, :popular]

  @doc """
  Queries videos from a source (URL or db_path) and outputs as table or markdown.

  Options:
    - `:sort` - :hot, :recent, :popular (default: :recent)
    - `:limit` - integer or nil
    - `:output` - path to write markdown file (nil = ASCII table to stdout)
  """
  def run(source, opts \\ []) do
    sort = Keyword.get(opts, :sort, :recent)

    with :ok <- validate_sort(sort),
         {:ok, db_path} <- resolve_source(source),
         {:ok, videos} <- Repo.videos(db_path, opts) do
      output(videos, opts)
    end
  end

  defp resolve_source("http" <> _ = url), do: ensure_indexed(url)
  defp resolve_source(db_path), do: validate_db_exists(db_path)

  defp ensure_indexed(url) do
    with {:ok, playlist_id} <- Playlist.id(url),
         db_path = Playlist.db_path(playlist_id) do
      case Repo.db_exists?(db_path) do
        {:ok, _mtime} -> {:ok, db_path}
        {:error, :not_found} -> fetch_and_save(url, db_path)
      end
    end
  end

  defp fetch_and_save(url, db_path) do
    with {:ok, title} <- YtDlp.playlist_title(url),
         {:ok, videos} <- YtDlp.fetch_playlist(url),
         {:ok, _count} <- Repo.save_videos(db_path, title, videos) do
      {:ok, db_path}
    end
  end

  defp validate_db_exists(db_path) do
    case Repo.db_exists?(db_path) do
      {:ok, _mtime} -> {:ok, db_path}
      {:error, :not_found} -> {:error, "database not found: #{db_path}"}
    end
  end

  defp validate_sort(sort) when sort in @supported_sorts, do: :ok
  defp validate_sort(sort), do: {:error, "sort '#{sort}' not implemented"}

  defp output(videos, opts) do
    case Keyword.get(opts, :output) do
      nil ->
        videos |> AsciiTable.format() |> IO.puts()
        :ok

      path ->
        videos |> Markdown.format() |> then(&File.write!(path, &1))
        {:ok, "Saved to #{path}"}
    end
  end
end
