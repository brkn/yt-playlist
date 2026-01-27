defmodule YtPlaylist.RepoTest do
  use ExUnit.Case, async: false

  alias YtPlaylist.Repo
  alias YtPlaylist.Video

  @test_db_dir System.tmp_dir!()

  setup do
    db_path = Path.join(@test_db_dir, "test_#{System.unique_integer([:positive])}.db")

    on_exit(fn ->
      File.rm(db_path)
    end)

    {:ok, db_path: db_path}
  end

  describe "db_exists?/1" do
    test "returns {:error, :not_found} for non-existent file" do
      assert {:error, :not_found} = Repo.db_exists?("/nonexistent/path.db")
    end

    test "returns {:ok, mtime} for existing database", %{db_path: db_path} do
      videos = [%Video{title: "Test", webpage_url: "https://youtube.com/watch?v=test"}]
      {:ok, 1} = Repo.save_videos(db_path, "Test", videos)

      assert {:ok, mtime} = Repo.db_exists?(db_path)
      assert is_integer(mtime)
    end
  end

  describe "save_videos/3" do
    test "creates database and inserts videos", %{db_path: db_path} do
      videos = [
        %Video{
          title: "Test Video",
          channel: "Test Channel",
          webpage_url: "https://youtube.com/watch?v=abc123",
          view_count: 1000,
          like_count: 100,
          upload_date: "20240101"
        }
      ]

      assert {:ok, 1} = Repo.save_videos(db_path, "Test Playlist", videos)
      assert File.exists?(db_path)
    end

    test "handles duplicate URLs with on_conflict: :nothing", %{db_path: db_path} do
      video = %Video{title: "Test", webpage_url: "https://youtube.com/watch?v=dup"}

      {:ok, 1} = Repo.save_videos(db_path, "Test", [video])
      {:ok, 0} = Repo.save_videos(db_path, "Test", [video])
    end
  end

  describe "all_videos/1" do
    test "retrieves saved videos with correct field values", %{db_path: db_path} do
      videos = [
        %Video{
          title: "Video One",
          channel: "Channel A",
          webpage_url: "https://youtube.com/watch?v=one",
          view_count: 500,
          like_count: 50,
          upload_date: "20240315",
          categories: "[\"Music\",\"Entertainment\"]",
          tags: "[\"tag1\",\"tag2\"]"
        }
      ]

      {:ok, 1} = Repo.save_videos(db_path, "My Playlist", videos)
      {:ok, [video]} = Repo.all_videos(db_path)

      assert video.title == "Video One"
      assert video.channel == "Channel A"
      assert video.webpage_url == "https://youtube.com/watch?v=one"
      assert video.view_count == 500
      assert video.like_count == 50
      assert video.upload_date == "20240315"
      assert video.playlist_name == "My Playlist"
    end
  end
end
