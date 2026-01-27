defmodule YtPlaylist.YtDlpTest do
  use ExUnit.Case, async: true

  alias YtPlaylist.{Video, YtDlp}

  @test_playlist_url "https://www.youtube.com/playlist?list=PLbpi6ZahtOH73nBVnYgO3xfzfuO5RurZS"

  describe "playlist_title/1" do
    @tag :integration
    test "returns playlist title from YouTube URL" do
      assert {:ok, "Best 'Hello' Covers (and Spoofs)"} =
               YtDlp.playlist_title(@test_playlist_url)
    end

    @tag :integration
    test "returns error for invalid URL" do
      assert {:error, "yt-dlp failed with exit code 1"} =
               YtDlp.playlist_title("https://www.youtube.com/playlist?list=INVALID_PLAYLIST_ID")
    end
  end

  describe "fetch_playlist/1" do
    @tag :integration
    test "returns list of Video structs from YouTube playlist" do
      assert {:ok, videos} = YtDlp.fetch_playlist(@test_playlist_url)
      assert length(videos) == 10

      first_video = hd(videos)
      assert %Video{id: "ZgMAAzzQz7s"} = first_video
    end
  end
end
