defmodule YtPlaylist.Formatter.Markdown do
  @moduledoc """
  Formats Video structs to markdown.
  """

  alias YtPlaylist.Video

  @doc """
  Formats a list of videos as markdown.
  """
  def format(videos) when is_list(videos) do
    videos
    |> Enum.map(&format_video/1)
    |> Enum.join("\n\n---\n\n")
  end

  defp format_video(%Video{} = video) do
    """
    ## #{video.title}

    - URL: #{video.webpage_url}
    - Date: #{format_date(video.upload_date)}
    - Duration: #{video.duration_string}
    - Views: #{format_number(video.view_count)}
    - Likes: #{format_number(video.like_count)}
    """
    |> String.trim_trailing()
  end

  defp format_date(nil), do: "Unknown"

  defp format_date(date) when is_binary(date) do
    case date do
      <<year::binary-size(4), month::binary-size(2), day::binary-size(2)>> ->
        "#{year}-#{month}-#{day}"

      _ ->
        date
    end
  end

  defp format_number(nil), do: "0"

  defp format_number(n) when is_integer(n) do
    n
    |> Integer.to_string()
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end
end
