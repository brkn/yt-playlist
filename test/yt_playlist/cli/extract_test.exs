defmodule YtPlaylist.CLI.ExtractTest do
  use ExUnit.Case, async: true

  alias YtPlaylist.CLI.Extract
  alias YtPlaylist.{Config, Repo, Video}

  @test_playlist_url "https://www.youtube.com/playlist?list=PLbpi6ZahtOH73nBVnYgO3xfzfuO5RurZS"

  describe "run/2 with force option" do
    @tag :integration
    test "force: true skips existing db check" do
      {:ok, playlist_id} = Extract.extract_playlist_id(@test_playlist_url)
      db_path = Config.db_path(playlist_id)

      videos = [%Video{title: "Test", webpage_url: "https://youtube.com/watch?v=test"}]
      {:ok, 1} = Repo.save_videos(db_path, "Test", videos)

      assert {:ok, _msg} = Extract.run(@test_playlist_url, force: true)
    end
  end

  describe "extract_playlist_id/1" do
    test "extracts playlist ID from standard URL" do
      url = "https://www.youtube.com/playlist?list=PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf"
      assert {:ok, "PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf"} = Extract.extract_playlist_id(url)
    end

    test "extracts playlist ID from URL with extra params" do
      url = "https://www.youtube.com/playlist?list=PLxxxxx&foo=bar"
      assert {:ok, "PLxxxxx"} = Extract.extract_playlist_id(url)
    end

    test "returns error for URL without list param" do
      url = "https://www.youtube.com/watch?v=abc123"
      assert {:error, "could not extract playlist ID from URL"} = Extract.extract_playlist_id(url)
    end

    test "returns error for URL without query string" do
      url = "https://www.youtube.com/channel/UCxxxxx"
      assert {:error, "could not extract playlist ID from URL"} = Extract.extract_playlist_id(url)
    end
  end
end
