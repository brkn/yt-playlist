defmodule YtPlaylist.CLITest do
  use ExUnit.Case, async: true

  alias YtPlaylist.CLI

  describe "parse_sort/1" do
    test "parses supported sort strings" do
      assert {:ok, :hot} = CLI.parse_sort("hot")
      assert {:ok, :recent} = CLI.parse_sort("recent")
      assert {:ok, :popular} = CLI.parse_sort("popular")
    end

    test "returns error for unsupported sort" do
      assert {:error, "sort 'nonsense' not supported. Use: hot, recent, popular"} =
               CLI.parse_sort("nonsense")
    end
  end
end
