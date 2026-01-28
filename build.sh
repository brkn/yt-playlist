#!/usr/bin/env bash
set -euo pipefail

# Clear Burrito runtime cache
rm -rf "${HOME}/Library/Application Support/.burrito/yt_playlist"*
rm -rf "${HOME}/Library/Caches/burrito_file_cache"

MIX_ENV=prod mix release --overwrite

echo ""
echo "Binary: burrito_out/yt_playlist_macos_arm64"
