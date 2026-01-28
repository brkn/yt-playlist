defmodule YtPlaylist.CLI.ExportTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias YtPlaylist.CLI.Export
  alias YtPlaylist.{Repo, Video}

  @test_db_dir System.tmp_dir!()

  setup do
    db_path = Path.join(@test_db_dir, "export_test_#{System.unique_integer([:positive])}.db")

    on_exit(fn ->
      File.rm(db_path)
    end)

    {:ok, db_path: db_path}
  end

  describe "run/2" do
    test "exports videos as markdown", %{db_path: db_path} do
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

      output =
        capture_io(fn ->
          assert :ok = Export.run(db_path)
        end)

      expected = File.read!("test/fixtures/expected_export.md")
      assert String.trim(output) == String.trim(expected)
    end

    test "returns error for non-existent database" do
      result = Export.run("/nonexistent/path.db")

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
          assert :ok = Export.run(db_path, sort: :hot)
        end)

      new_pos = :binary.match(output, "New Video") |> elem(0)
      old_pos = :binary.match(output, "Old Popular Video") |> elem(0)

      assert new_pos < old_pos, "New video should appear before old popular video with hot sort"
    end

    test "--sort top returns not implemented error", %{db_path: db_path} do
      videos = [%Video{title: "Test", webpage_url: "https://youtube.com/watch?v=test"}]
      {:ok, 1} = Repo.save_videos(db_path, "Test", videos)

      result = Export.run(db_path, sort: :top)

      assert {:error, "sort 'top' not implemented"} = result
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
          assert :ok = Export.run(db_path, sort: :recent, limit: 2)
        end)

      assert output =~ "Video 5"
      assert output =~ "Video 4"
      refute output =~ "Video 3"
      refute output =~ "Video 2"
      refute output =~ "Video 1"
    end
  end
end
