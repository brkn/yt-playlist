defmodule YtPlaylist.CLI.QueryTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias YtPlaylist.CLI.Query
  alias YtPlaylist.{Repo, Video}

  @test_db_dir System.tmp_dir!()

  setup do
    db_path = Path.join(@test_db_dir, "query_test_#{System.unique_integer([:positive])}.db")

    on_exit(fn ->
      File.rm(db_path)
    end)

    {:ok, db_path: db_path}
  end

  describe "run/2" do
    test "outputs ASCII table with header and data rows", %{db_path: db_path} do
      videos = [
        %Video{
          title: "Test Video",
          webpage_url: "https://youtube.com/watch?v=test1",
          view_count: 1000,
          upload_date: "20240115"
        }
      ]

      {:ok, 1} = Repo.save_videos(db_path, "Test Playlist", videos)

      output =
        capture_io(fn ->
          assert :ok = Query.run(db_path)
        end)

      # TODO: replace it with an exact response assertion.
      # See test/yt_playlist/cli/export_test.exs:42 using a fixture
      assert output =~ "#  Date        Views  Title"
      assert output =~ "2024-01-15"
      assert output =~ "Test Video"
      assert output =~ "https://youtube.com/watch?v=test1"
    end

    test "returns error for non-existent database" do
      result = Query.run("/nonexistent/path.db")

      assert {:error, "database not found: /nonexistent/path.db"} = result
    end

    test "--sort hot returns videos sorted by hot score", %{db_path: db_path} do
      today = Date.utc_today() |> Date.to_iso8601(:basic)
      old_date = "20200101"

      videos = [
        %Video{
          title: "Old Popular Video",
          webpage_url: "https://youtube.com/watch?v=old",
          view_count: 1_000_000,
          upload_date: old_date
        },
        %Video{
          title: "New Video",
          webpage_url: "https://youtube.com/watch?v=new",
          view_count: 10_000,
          upload_date: today
        }
      ]

      {:ok, 2} = Repo.save_videos(db_path, "Test", videos)

      output =
        capture_io(fn ->
          assert :ok = Query.run(db_path, sort: :hot)
        end)

      # TODO: make simpler assertions
      # Maybe the regex would just suffice since they would be ordered.
      new_pos = :binary.match(output, "New Video") |> elem(0)
      old_pos = :binary.match(output, "Old Popular Video") |> elem(0)

      assert new_pos < old_pos, "New video should appear before old popular video with hot sort"
    end

    test "--sort recent returns videos sorted by upload date descending", %{db_path: db_path} do
      videos = [
        %Video{
          title: "Older Video",
          webpage_url: "https://youtube.com/watch?v=older",
          upload_date: "20240101"
        },
        %Video{
          title: "Newer Video",
          webpage_url: "https://youtube.com/watch?v=newer",
          upload_date: "20240201"
        }
      ]

      {:ok, 2} = Repo.save_videos(db_path, "Test", videos)

      output =
        capture_io(fn ->
          assert :ok = Query.run(db_path, sort: :recent)
        end)

      # TODO: make simpler assertions
      # Maybe the regex would just suffice since they would be ordered.
      newer_pos = :binary.match(output, "Newer Video") |> elem(0)
      older_pos = :binary.match(output, "Older Video") |> elem(0)

      assert newer_pos < older_pos, "Newer video should appear first with recent sort"
    end

    test "--limit restricts output count", %{db_path: db_path} do
      videos =
        1..5
        |> Enum.map(fn i ->
          %Video{
            title: "Video #{i}",
            webpage_url: "https://youtube.com/watch?v=v#{i}",
            upload_date: "2024010#{i}"
          }
        end)

      {:ok, 5} = Repo.save_videos(db_path, "Test", videos)

      output =
        capture_io(fn ->
          assert :ok = Query.run(db_path, sort: :recent, limit: 2)
        end)

      # TODO: make simpler assertions
      # Maybe the regex would just suffice since they would be ordered.

      # TODO: also how come limit 2 is returning 5 results
      assert output =~ "Video 5"
      assert output =~ "Video 4"
      refute output =~ "Video 3"
      refute output =~ "Video 2"
      refute output =~ "Video 1"
    end

    test "--sort popular returns videos sorted by view count descending", %{db_path: db_path} do
      videos = [
        %Video{
          title: "Low Views",
          webpage_url: "https://youtube.com/watch?v=low",
          view_count: 100
        },
        %Video{
          title: "High Views",
          webpage_url: "https://youtube.com/watch?v=high",
          view_count: 1_000_000
        }
      ]

      {:ok, 2} = Repo.save_videos(db_path, "Test", videos)

      output =
        capture_io(fn ->
          assert :ok = Query.run(db_path, sort: :popular)
        end)

      high_pos = :binary.match(output, "High Views") |> elem(0)
      low_pos = :binary.match(output, "Low Views") |> elem(0)

      assert high_pos < low_pos, "High views video should appear first with popular sort"
    end
  end

  describe "run/2 with -o output option" do
    test "writes markdown to file", %{db_path: db_path} do
      videos = [
        %Video{
          title: "Test Video",
          webpage_url: "https://youtube.com/watch?v=test1",
          duration_string: "10:00",
          view_count: 1000,
          like_count: 100,
          description: "A test video",
          upload_date: "20240101"
        }
      ]

      {:ok, 1} = Repo.save_videos(db_path, "Test Playlist", videos)

      output_path = Path.join(@test_db_dir, "output_#{System.unique_integer([:positive])}.md")

      on_exit(fn ->
        File.rm(output_path)
      end)

      result = Query.run(db_path, output: output_path)

      assert {:ok, "Saved to " <> ^output_path} = result

      expected = File.read!("test/fixtures/expected_export.md")
      actual = File.read!(output_path)
      assert String.trim(actual) == String.trim(expected)
    end

    test "--sort hot with -o writes sorted markdown to file", %{db_path: db_path} do
      today = Date.utc_today() |> Date.to_iso8601(:basic)
      old_date = "20200101"

      videos = [
        %Video{
          title: "Old Popular Video",
          webpage_url: "https://youtube.com/watch?v=old",
          view_count: 1_000_000,
          upload_date: old_date
        },
        %Video{
          title: "New Video",
          webpage_url: "https://youtube.com/watch?v=new",
          view_count: 10_000,
          upload_date: today
        }
      ]

      {:ok, 2} = Repo.save_videos(db_path, "Test", videos)

      output_path = Path.join(@test_db_dir, "output_#{System.unique_integer([:positive])}.md")

      on_exit(fn ->
        File.rm(output_path)
      end)

      assert {:ok, _} = Query.run(db_path, sort: :hot, output: output_path)

      output = File.read!(output_path)
      new_pos = :binary.match(output, "New Video") |> elem(0)
      old_pos = :binary.match(output, "Old Popular Video") |> elem(0)

      assert new_pos < old_pos, "New video should appear before old popular video with hot sort"
    end

    test "--limit with -o restricts output count", %{db_path: db_path} do
      videos =
        1..5
        |> Enum.map(fn i ->
          %Video{
            title: "Video #{i}",
            webpage_url: "https://youtube.com/watch?v=v#{i}",
            upload_date: "2024010#{i}"
          }
        end)

      {:ok, 5} = Repo.save_videos(db_path, "Test", videos)

      output_path = Path.join(@test_db_dir, "output_#{System.unique_integer([:positive])}.md")

      on_exit(fn ->
        File.rm(output_path)
      end)

      assert {:ok, _} = Query.run(db_path, sort: :recent, limit: 2, output: output_path)

      output = File.read!(output_path)
      assert output =~ "Video 5"
      assert output =~ "Video 4"
      refute output =~ "Video 3"
      refute output =~ "Video 2"
      refute output =~ "Video 1"
    end
  end
end
