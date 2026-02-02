# yt_playlist

YouTube's playlist sorting is broken. Popular videos from 5 years ago drown out recent content. This tool fixes it.

## What it does

Extracts YouTube playlist metadata into SQLite and provides a "hot" ranking that balances views with recency:

```
hot_score = (views + 0.6 × likes)^0.8 / (days + 1)^1.5
```

Recent videos with moderate engagement rank higher than ancient viral hits.

## Quick start

Try it with the included demo database:

```bash
# Download the binary (macOS ARM64)
curl -LO https://github.com/user/yt_playlist/releases/latest/download/yt_playlist_macos_arm64
chmod +x yt_playlist_macos_arm64

# Query with hot ranking
./yt_playlist_macos_arm64 query examples/demo.db --sort hot --limit 10
```

Output:

```
  #  Date        Views  Title                                   URL
  1  2015-11-25   62.6M  Jimmy Fallon, Adele & The Roots Sing ...  https://www.youtube.com/watch?v=-yL7VP4-kP4
  2  2015-11-23   10.4M  Adele - Hello | Ten Second Songs 25 S...  https://www.youtube.com/watch?v=ZgMAAzzQz7s
```

## Install

### Binary (recommended)

Download from releases. Available for macOS ARM64.

### Build from source

Requires Elixir 1.19+:

```bash
git clone https://github.com/user/yt_playlist
cd yt_playlist
./build.sh
# Binary at burrito_out/yt_playlist_macos_arm64
```

## Usage

### extract

Extract a playlist to SQLite (requires yt-dlp):

```bash
./yt_playlist extract "https://www.youtube.com/playlist?list=PLxyz..."
# Creates: Playlist_Name.db
```

### query

Display videos as ASCII table:

```bash
./yt_playlist query MyPlaylist.db --sort hot --limit 20
./yt_playlist query MyPlaylist.db --sort recent
```

### export-to-md

Export as markdown:

```bash
./yt_playlist export-to-md MyPlaylist.db --sort hot --limit 10 > output.md
```

## Requirements

- yt-dlp (for extraction only, not needed for querying existing databases)
- Firefox with YouTube cookies (yt-dlp uses `--cookies-from-browser firefox`)
  - [ ] TODO: remove this after ux improvements. There is a task for configuration.

## TODO

- [ ] BUG: extract command printing: 0 videos saved?

- [ ] `--sort popular` option (pure view count)
- [ ] Suppress yt-dlp output unless `--verbose` passed
  - Commands should still hold the hand of the user
  - `...fetching the playlist 1/?` or spinner idk

- [ ] UX rewrite
  - [x] Cache databases in `~/.config/yt-playlist`
  - [x] Name db files by playlist ID (`PLxxxxx.db`)
  - [ ] Interactive browser config on first extract:
    ```
    $ yt_playlist "https://..."
    No browser configured. Which browser are you logged into YouTube with?
      1. chrome
      2. firefox
      3. safari
      4. edge
    > 1
    Saved to ~/.config/yt_playlist/
    ```
  - [ ] Accept URL directly for query/export (auto-extract if not cached)
  - [ ] Command to show cached playlists
    - Naming: `list` `playlists` or  `ls`?
    - Output: show full path (`~/...`) as last column for easy `rm`
  - [ ] Flag to force re-extraction
    - [ ] Naming: `--refresh`? `--update`? `--force`?

- [ ] Cross-platform binaries (Linux, Windows)
