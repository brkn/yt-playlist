defmodule YtPlaylist.Formatter.AsciiTable do
  @moduledoc """
  Formats Video structs as an ASCII table for terminal display.
  """

  alias YtPlaylist.Video

  @title_width 40

  @doc """
  Formats a list of videos as an ASCII table.

  ## Example

      iex> videos = [%YtPlaylist.Video{title: "Test Video", upload_date: "20241105", view_count: 50_200_000, webpage_url: "https://www.youtube.com/watch?v=abc123"}]
      iex> YtPlaylist.Formatter.AsciiTable.format(videos)
      "  #  Date        Views  Title                                   URL\\n  1  2024-11-05  50.2M  Test Video                              https://www.youtube.com/watch?v=abc123"
  """
  def format(videos) when is_list(videos) do
    header = header_row()

    rows =
      videos
      |> Enum.with_index(1)
      |> Enum.map(&format_row/1)

    [header | rows] |> Enum.join("\n")
  end

  defp header_row do
    "  #  Date        Views  Title#{String.duplicate(" ", @title_width - 5)}URL"
  end

  defp format_row({%Video{} = video, index}) do
    rank = index |> Integer.to_string() |> String.pad_leading(3)
    date = format_date(video.upload_date)
    views = format_views(video.view_count)
    title = truncate_title(video.title || "", @title_width)
    url = video.webpage_url || ""

    "#{rank}  #{date}  #{views}  #{title}  #{url}"
  end

  defp format_views(nil), do: String.pad_leading("0", 6)

  defp format_views(n) when n >= 1_000_000 do
    (n / 1_000_000)
    |> Float.round(1)
    |> format_float_with_unit("M")
    |> String.pad_leading(6)
  end

  defp format_views(n) when n >= 1_000 do
    (n / 1_000)
    |> Float.round(1)
    |> format_float_with_unit("K")
    |> String.pad_leading(6)
  end

  defp format_views(n) do
    n
    |> Integer.to_string()
    |> String.pad_leading(6)
  end

  defp format_float_with_unit(f, unit) do
    # Remove trailing .0 for whole numbers
    if trunc(f) == f do
      "#{trunc(f)}#{unit}"
    else
      "#{f}#{unit}"
    end
  end

  defp format_date(nil), do: "          "

  defp format_date(<<y::binary-4, m::binary-2, d::binary-2>>) do
    "#{y}-#{m}-#{d}"
  end

  defp format_date(date), do: String.pad_trailing(date, 10)

  defp truncate_title(title, max) do
    if String.length(title) > max do
      String.slice(title, 0, max - 3) <> "..."
    else
      String.pad_trailing(title, max)
    end
  end
end
