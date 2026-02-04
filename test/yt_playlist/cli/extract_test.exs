defmodule YtPlaylist.CLI.ExtractTest do
  use ExUnit.Case, async: true

  alias YtPlaylist.CLI.Extract
  alias YtPlaylist.{Playlist, Repo, Video}

  @test_playlist_url "https://www.youtube.com/playlist?list=PLbpi6ZahtOH73nBVnYgO3xfzfuO5RurZS"

  describe "run/2 with force option" do
    @tag :integration
    test "force: true skips existing db check" do
      {:ok, playlist_id} = Extract.extract_playlist_id(@test_playlist_url)
      db_path = Playlist.db_path(playlist_id)

      videos = [%Video{title: "Test", webpage_url: "https://youtube.com/watch?v=test"}]
      {:ok, 1} = Repo.save_videos(db_path, "Test", videos)

      assert {:ok, _msg} = Extract.run(@test_playlist_url, force: true)
    end
  end
end
