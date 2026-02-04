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

  describe "videos/2" do
    test "sorts by recent (upload_date desc) by default", %{db_path: db_path} do
      videos = [
        %Video{
          title: "Old",
          webpage_url: "https://youtube.com/watch?v=old",
          upload_date: "20230101"
        },
        %Video{
          title: "New",
          webpage_url: "https://youtube.com/watch?v=new",
          upload_date: "20240601"
        }
      ]

      {:ok, 2} = Repo.save_videos(db_path, "Test", videos)
      {:ok, results} = Repo.videos(db_path)

      assert [first, second] = results
      assert first.title == "New"
      assert second.title == "Old"
    end

    test "sorts by hot score with gravity decay", %{db_path: db_path} do
      # Expected: recent viral dominates, ancient loses despite high views
      # Formula: (views + 0.6 × likes)^0.8 / (days + 1)^1.5
      today = Date.utc_today()

      videos = [
        %Video{
          title: "Ancient legendary",
          webpage_url: "https://youtube.com/watch?v=ancient",
          upload_date: date_string(Date.add(today, -18 * 365)),
          view_count: 22_000_000,
          like_count: 1_000_000
        },
        %Video{
          title: "Old mega-viral",
          webpage_url: "https://youtube.com/watch?v=old",
          upload_date: date_string(Date.add(today, -10 * 365)),
          view_count: 57_000_000,
          like_count: 2_000_000
        },
        %Video{
          title: "Fresh modest",
          webpage_url: "https://youtube.com/watch?v=fresh",
          upload_date: date_string(Date.add(today, -180)),
          view_count: 175_000,
          like_count: 10_000
        },
        %Video{
          title: "Recent viral",
          webpage_url: "https://youtube.com/watch?v=recent",
          upload_date: date_string(Date.add(today, -30)),
          view_count: 18_000_000,
          like_count: 900_000
        }
      ]

      {:ok, 4} = Repo.save_videos(db_path, "Test", videos)
      {:ok, results} = Repo.videos(db_path, sort: :hot)

      titles = Enum.map(results, & &1.title)

      assert titles == ["Recent viral", "Old mega-viral", "Fresh modest", "Ancient legendary"]
      assert List.last(titles) == "Ancient legendary"
    end

    test "respects limit option", %{db_path: db_path} do
      videos = [
        %Video{title: "A", webpage_url: "https://youtube.com/watch?v=a", upload_date: "20240101"},
        %Video{title: "B", webpage_url: "https://youtube.com/watch?v=b", upload_date: "20240102"},
        %Video{title: "C", webpage_url: "https://youtube.com/watch?v=c", upload_date: "20240103"}
      ]

      {:ok, 3} = Repo.save_videos(db_path, "Test", videos)
      {:ok, results} = Repo.videos(db_path, limit: 2)

      assert length(results) == 2
    end

    test "returns all videos when no limit specified", %{db_path: db_path} do
      videos = [
        %Video{title: "A", webpage_url: "https://youtube.com/watch?v=a", upload_date: "20240101"},
        %Video{title: "B", webpage_url: "https://youtube.com/watch?v=b", upload_date: "20240102"},
        %Video{title: "C", webpage_url: "https://youtube.com/watch?v=c", upload_date: "20240103"}
      ]

      {:ok, 3} = Repo.save_videos(db_path, "Test", videos)
      {:ok, results} = Repo.videos(db_path)

      assert length(results) == 3
    end

    test "sorts by popular (view_count desc)", %{db_path: db_path} do
      videos = [
        %Video{
          title: "Low views",
          webpage_url: "https://youtube.com/watch?v=low",
          view_count: 100
        },
        %Video{
          title: "High views",
          webpage_url: "https://youtube.com/watch?v=high",
          view_count: 1_000_000
        },
        %Video{
          title: "Medium views",
          webpage_url: "https://youtube.com/watch?v=medium",
          view_count: 50_000
        }
      ]

      {:ok, 3} = Repo.save_videos(db_path, "Test", videos)
      {:ok, results} = Repo.videos(db_path, sort: :popular)

      titles = Enum.map(results, & &1.title)
      assert titles == ["High views", "Medium views", "Low views"]
    end
  end

  defp date_string(%Date{year: y, month: m, day: d}) do
    :io_lib.format("~4..0B~2..0B~2..0B", [y, m, d]) |> to_string()
  end
end
