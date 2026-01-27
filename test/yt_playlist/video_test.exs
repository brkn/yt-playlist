defmodule YtPlaylist.VideoTest do
  use ExUnit.Case, async: true

  alias YtPlaylist.Video

  describe "from_json/1" do
    test "converts yt-dlp JSON map to Video struct" do
      json = %{
        "id" => "abc123",
        "title" => "Test Video",
        "channel" => "Test Channel",
        "uploader" => "Test Uploader",
        "duration" => 272,
        "duration_string" => "4:32",
        "webpage_url" => "https://www.youtube.com/watch?v=abc123",
        "view_count" => 1_000_000,
        "like_count" => 50_000,
        "channel_follower_count" => 100_000,
        "channel_is_verified" => true,
        "description" => "A test video description",
        "categories" => ["Music", "Entertainment"],
        "tags" => ["test", "video"],
        "upload_date" => "20240115",
        "availability" => "public"
      }

      video = Video.from_json(json)

      assert %Video{} = video
      assert video.id == "abc123"
      assert video.title == "Test Video"
      assert video.channel == "Test Channel"
      assert video.uploader == "Test Uploader"
      assert video.duration == 272
      assert video.duration_string == "4:32"
      assert video.webpage_url == "https://www.youtube.com/watch?v=abc123"
      assert video.view_count == 1_000_000
      assert video.like_count == 50_000
      assert video.channel_follower_count == 100_000
      assert video.channel_is_verified == true
      assert video.description == "A test video description"
      assert video.categories == ["Music", "Entertainment"]
      assert video.tags == ["test", "video"]
      assert video.upload_date == "20240115"
      assert video.availability == "public"
    end

    test "handles missing fields gracefully with nil" do
      json = %{
        "id" => "minimal",
        "title" => "Minimal Video"
      }

      video = Video.from_json(json)

      assert video.id == "minimal"
      assert video.title == "Minimal Video"
      assert video.channel == nil
      assert video.view_count == nil
      assert video.categories == nil
    end
  end
end
