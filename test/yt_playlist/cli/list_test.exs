defmodule YtPlaylist.CLI.ListTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias YtPlaylist.CLI.List
  alias YtPlaylist.{Config, Repo, Video}

  setup do
    config_dir = Config.config_dir()
    test_db = Path.join(config_dir, "PLtest123.db")

    on_exit(fn ->
      File.rm(test_db)
    end)

    {:ok, config_dir: config_dir, test_db: test_db}
  end

  describe "run/0" do
    test "lists cached playlist databases", %{test_db: test_db} do
      videos = [%Video{title: "Test", webpage_url: "https://youtube.com/watch?v=test"}]
      {:ok, 1} = Repo.save_videos(test_db, "Test", videos)

      output = capture_io(fn -> List.run() end)

      assert output =~ "PLtest123"
      assert output =~ test_db
    end

    test "shows message when no playlists cached", %{config_dir: config_dir} do
      empty_dir = Path.join(config_dir, "empty_test_#{System.unique_integer([:positive])}")
      File.mkdir_p!(empty_dir)

      on_exit(fn -> File.rm_rf!(empty_dir) end)

      output = capture_io(fn -> List.run() end)

      assert is_binary(output)
    end
  end
end
