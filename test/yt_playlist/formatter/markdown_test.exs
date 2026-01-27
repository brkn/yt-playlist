defmodule YtPlaylist.Formatter.MarkdownTest do
  use ExUnit.Case, async: true

  alias YtPlaylist.Formatter.Markdown
  alias YtPlaylist.Video

  describe "format/1" do
    test "formats a single video" do
      video = %Video{
        title: "Test Video",
        webpage_url: "https://youtube.com/watch?v=abc123",
        duration_string: "12:34",
        view_count: 1_234_567,
        like_count: 12_345,
        description: "A test description."
      }

      result = Markdown.format([video])

      expected =
        """
        ## Test Video

        - URL: https://youtube.com/watch?v=abc123
        - Duration: 12:34
        - Views: 1,234,567
        - Likes: 12,345

        A test description.
        """
        |> String.trim_trailing()

      assert result == expected
    end

    test "formats multiple videos with separator" do
      video1 = %Video{
        title: "First Video",
        webpage_url: "https://youtube.com/watch?v=first",
        duration_string: "5:00",
        view_count: 100,
        like_count: 10,
        description: "First description."
      }

      video2 = %Video{
        title: "Second Video",
        webpage_url: "https://youtube.com/watch?v=second",
        duration_string: "10:00",
        view_count: 200,
        like_count: 20,
        description: "Second description."
      }

      result = Markdown.format([video1, video2])

      assert result =~ "## First Video"
      assert result =~ "## Second Video"
      assert result =~ "\n\n---\n\n"
    end

    test "handles nil values gracefully" do
      video = %Video{
        title: "Minimal Video",
        webpage_url: "https://youtube.com/watch?v=min",
        duration_string: nil,
        view_count: nil,
        like_count: nil,
        description: nil
      }

      result = Markdown.format([video])

      assert result =~ "## Minimal Video"
      assert result =~ "- Views: 0"
      assert result =~ "- Likes: 0"
    end

    test "returns empty string for empty list" do
      assert Markdown.format([]) == ""
    end
  end
end
