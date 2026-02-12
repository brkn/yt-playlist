defmodule YtPlaylist.ConfigTest do
  use ExUnit.Case, async: false

  alias YtPlaylist.Config

  describe "config_dir/0" do
    test "expands path at runtime using current user's home" do
      Application.delete_env(:yt_playlist, :config_dir)

      result = Config.config_dir()
      expected = Path.expand("~/.config/yt-playlist")

      assert result == expected
      assert String.starts_with?(result, System.user_home!())
    end
  end

  describe "browser/0" do
    setup :with_temp_config_dir

    test "returns nil when no config file exists" do
      assert Config.browser() == nil
    end

    test "returns browser string after save_browser!/1" do
      Config.save_browser!("chrome")

      assert Config.browser() == "chrome"
    end
  end

  describe "save_browser!/1" do
    setup :with_temp_config_dir

    test "creates config.json with browser key" do
      Config.save_browser!("safari")

      assert {:ok, contents} = File.read(Config.config_path())
      assert %{"browser" => "safari"} = Jason.decode!(contents)
    end

    test "preserves other keys in existing config" do
      Config.write!(%{"other_key" => "value"})

      Config.save_browser!("edge")

      assert {:ok, %{"browser" => "edge", "other_key" => "value"}} = Config.read()
    end
  end

  defp with_temp_config_dir(_context) do
    test_dir = Path.join(System.tmp_dir!(), "yt_playlist_config_test_#{:rand.uniform(100_000)}")
    File.mkdir_p!(test_dir)

    Application.put_env(:yt_playlist, :config_dir, test_dir)

    on_exit(fn ->
      File.rm_rf!(test_dir)
      Application.delete_env(:yt_playlist, :config_dir)
    end)

    :ok
  end
end
