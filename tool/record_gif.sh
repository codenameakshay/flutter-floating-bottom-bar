#!/usr/bin/env bash
# Record the booted iOS simulator and convert to an optimized gif.
#
# Usage:
#   tool/record_gif.sh <name>
#
# Example:
#   tool/record_gif.sh 1-issues-dock
#
# Workflow:
#   1. Boot a simulator and run the example app: `make run-ios` (or `flutter run -d ios`).
#   2. Navigate to the demo you want to record.
#   3. In another terminal, run this script with the demo's slug.
#   4. Interact with the sim. Press Ctrl+C in this terminal to stop.
#   5. The script converts the .mov to screenshots/<name>.gif.
#
# Requirements: ffmpeg, Xcode command line tools.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <name>" >&2
  echo "  e.g. $0 1-issues-dock" >&2
  exit 64
fi

NAME="$1"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT_DIR/screenshots"
TMP_MOV="$(mktemp -t fbb-record-XXXX).mov"
OUT_GIF="$OUT_DIR/$NAME.gif"

# Tunables — override via env.
GIF_FPS="${GIF_FPS:-24}"
GIF_WIDTH="${GIF_WIDTH:-360}"

mkdir -p "$OUT_DIR"

if ! xcrun simctl list devices booted | grep -q Booted; then
  echo "no booted iOS simulator. open one with 'open -a Simulator' or run the app first." >&2
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg not found. install with: brew install ffmpeg" >&2
  exit 1
fi

echo "recording booted simulator -> $TMP_MOV"
echo "press Ctrl+C in this terminal to stop and convert."

# simctl handles SIGINT cleanly and finalizes the mov.
xcrun simctl io booted recordVideo --codec=h264 --force "$TMP_MOV" || true

if [[ ! -s "$TMP_MOV" ]]; then
  echo "recording produced no output." >&2
  exit 1
fi

echo
echo "converting to gif (fps=$GIF_FPS, width=$GIF_WIDTH) -> $OUT_GIF"

# Two-pass palette-based conversion for smaller, cleaner gifs.
PALETTE="$(mktemp -t fbb-palette-XXXX).png"
ffmpeg -y -loglevel error -i "$TMP_MOV" \
  -vf "fps=$GIF_FPS,scale=$GIF_WIDTH:-1:flags=lanczos,palettegen=stats_mode=diff" \
  "$PALETTE"

ffmpeg -y -loglevel error -i "$TMP_MOV" -i "$PALETTE" \
  -lavfi "fps=$GIF_FPS,scale=$GIF_WIDTH:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
  -loop 0 "$OUT_GIF"

rm -f "$PALETTE" "$TMP_MOV"

SIZE=$(du -h "$OUT_GIF" | awk '{print $1}')
echo "done: $OUT_GIF ($SIZE)"
