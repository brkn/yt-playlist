defmodule YtPlaylist.HotScoreTest do
  use ExUnit.Case, async: true

  alias YtPlaylist.HotScore

  describe "calculate/3" do
    test "recent modest beats old mega-viral" do
      # Decision doc: 175K view 6mo video beats 50M 11yr
      recent = HotScore.calculate(175_000, 10_000, 180)
      old = HotScore.calculate(50_000_000, 2_000_000, 11 * 365)

      assert recent > old
    end

    test "recent viral beats everything" do
      # 18M views, 1 month old should beat all others
      recent_viral = HotScore.calculate(18_000_000, 900_000, 30)
      fresh_modest = HotScore.calculate(175_000, 10_000, 180)
      old_mega_viral = HotScore.calculate(57_000_000, 2_000_000, 10 * 365)
      ancient = HotScore.calculate(22_000_000, 1_000_000, 18 * 365)

      assert recent_viral > fresh_modest
      assert recent_viral > old_mega_viral
      assert recent_viral > ancient
    end

    test "handles nil values" do
      score = HotScore.calculate(nil, nil, nil)
      assert score == 0.0
    end

    test "handles negative days" do
      score = HotScore.calculate(1000, 100, -5)
      assert score > 0
    end

    test "likes provide small boost" do
      without_likes = HotScore.calculate(100_000, 0, 30)
      with_likes = HotScore.calculate(100_000, 6_000, 30)

      # 6% like ratio should give ~3% boost
      boost = (with_likes - without_likes) / without_likes

      assert boost > 0.02
      assert boost < 0.05
    end
  end

  describe "days_since_upload/1" do
    test "parses YYYYMMDD format" do
      days = HotScore.days_since_upload("20260101")
      assert is_integer(days)
      assert days >= 0
    end

    test "returns nil for invalid format" do
      assert HotScore.days_since_upload("2026-01-01") == nil
      assert HotScore.days_since_upload("invalid") == nil
      assert HotScore.days_since_upload("") == nil
    end

    test "returns nil for nil input" do
      assert HotScore.days_since_upload(nil) == nil
    end

    test "returns nil for non-binary input" do
      assert HotScore.days_since_upload(123) == nil
    end
  end
end
