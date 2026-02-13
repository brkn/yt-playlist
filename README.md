# yt_playlist

Sort any YouTube playlist by recent popularity.

## Quick start

```bash
# Extract + query a playlist in one step (sorted by hot score, top 10)
yt_playlist "https://www.youtube.com/playlist?list=PLxyz..." -s hot -n 10

# Query an already-cached playlist
yt_playlist ~/.config/yt-playlist/PLxyz.db -s hot

# Export to markdown
yt_playlist https://www.youtube.com/playlist?list=PLvL2NEhYV4Zu421KzHuLICUqieJXI2o_Z -s hot -o output.md

# See cached playlists
yt_playlist list
```

Output:

```
  #  Date        Views  Title                                   URL
  1  2015-11-25   62.6M  Jimmy Fallon, Adele & The Roots Sing ...  https://www.youtube.com/watch?v=-yL7VP4-kP4
  2  2015-11-23   10.4M  Adele - Hello | Ten Second Songs 25 S...  https://www.youtube.com/watch?v=ZgMAAzzQz7s
```

## Install

### Homebrew

> [!NOTE]
> Only macOS ARM (Apple Silicon) is available for now. Other platforms will be added soon.

```bash
brew install brkn/tap/yt-playlist
```

### Build from source

Clone and run `./build.sh` (requires Elixir 1.19+).

## Options

| Flag                  | Description                                             |
| --------------------- | ------------------------------------------------------- |
| `-s, --sort <method>` | Sort by: `hot`, `recent`, `popular` (default: `recent`) |
| `-n, --limit <n>`     | Limit output to n videos                                |
| `-o <file>`           | Write markdown to file instead of ASCII table           |

Passing a URL extracts the playlist (if not already cached) and queries it. Passing a db path queries an existing cache.

## Requirements

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) (for extraction only, not needed for querying existing databases)
- A browser logged into YouTube (you'll be prompted to select which browser on first run)

## TODO

- [ ] `--help` should render the usage message
- [ ] Suppress yt-dlp output / show progress during extraction
- [ ] Cross-platform binaries (Linux, Windows)
- `list` improvements:
  - [ ] Rename to `cache`
  - [ ] Add header line
  - [ ] Show playlist name instead of ID
- [ ] Show a message when fetching a playlist for the first time (cold call is silent)
