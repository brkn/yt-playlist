defmodule YtPlaylist.HotScore do
  @moduledoc """
  Hot score calculation for ranking videos by engagement and recency.

  Formula: (views + k × likes)^e / (days + 1)^g
  """

  @time_gravity 1.5
  @engagement_exp 0.8
  @like_weight 0.6
  @time_base 1

  @doc """
  Calculate hot score for a video.

  ## Examples
    iex> YtPlaylist.HotScore.calculate(1000, 100, 1)
    202.12638015052887
  """
  def calculate(view_count, like_count, days_since_upload) do
    views = view_count || 0
    likes = like_count || 0
    days = max(days_since_upload || 0, 0)

    engagement = views + @like_weight * likes
    time_factor = days + @time_base

    :math.pow(engagement, @engagement_exp) / :math.pow(time_factor, @time_gravity)
  end

  @doc """
  Parse yt-dlp upload_date (YYYYMMDD) and calculate days since that date.

  Returns nil if the date cannot be parsed.

  ## Examples
    iex> YtPlaylist.HotScore.days_since_upload("20260101")
    28
  """
  def days_since_upload(upload_date) when is_binary(upload_date) do
    with <<y::binary-4, m::binary-2, d::binary-2>> <- upload_date,
         {:ok, date} <- Date.new(String.to_integer(y), String.to_integer(m), String.to_integer(d)) do
      Date.diff(Date.utc_today(), date)
    else
      _ -> nil
    end
  end

  def days_since_upload(_), do: nil
end
