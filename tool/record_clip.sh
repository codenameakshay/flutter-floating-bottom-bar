#!/usr/bin/env bash
# Record the booted iOS simulator (or convert an existing .mov) to a 1080x1920 mp4 clip.
#
# Usage:
#   tool/record_clip.sh <name> [input.mov]
#
# Example:
#   tool/record_clip.sh 1-issues-dock
#   tool/record_clip.sh 1-issues-dock ~/Desktop/capture.mov
#
# Workflow:
#   1. Boot a simulator and run the example app: `make run-ios` (or `flutter run -d ios`).
#   2. Navigate to the demo you want to record.
#   3. In another terminal, run this script with the demo's slug.
#   4. Interact with the sim. Press Ctrl+C in this terminal to stop.
#   5. The script converts the .mov to clips/<name>.mp4.
#
# Requirements: ffmpeg, Xcode command line tools.

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: $0 <name> [input.mov]" >&2
  echo "  e.g. $0 1-issues-dock" >&2
  exit 64
fi

NAME="$1"
INPUT="${2:-}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT_DIR/clips"
OUT_MP4="$OUT_DIR/$NAME.mp4"
TMP_MOV=""
MAX_BYTES=$((15 * 1024 * 1024))

# Tunables — override via env.
CLIP_BG="${CLIP_BG:-0x0B0B0F}"
CLIP_CRF="${CLIP_CRF:-23}"

mkdir -p "$OUT_DIR"

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg not found. install with: brew install ffmpeg" >&2
  exit 1
fi

if [[ -n "$INPUT" ]]; then
  if [[ ! -s "$INPUT" ]]; then
    echo "input missing or empty: $INPUT" >&2
    exit 1
  fi
  SRC="$INPUT"
else
  if ! xcrun simctl list devices booted | grep -q Booted; then
    echo "no booted iOS simulator. open one with 'open -a Simulator' or run the app first." >&2
    exit 1
  fi

  TMP_MOV="$(mktemp -t fbb-record-XXXX).mov"
  echo "recording booted simulator -> $TMP_MOV"
  echo "press Ctrl+C in this terminal to stop and convert."

  # simctl handles SIGINT cleanly and finalizes the mov.
  xcrun simctl io booted recordVideo --codec=h264 --force "$TMP_MOV" || true

  if [[ ! -s "$TMP_MOV" ]]; then
    echo "recording produced no output." >&2
    rm -f "$TMP_MOV"
    exit 1
  fi
  SRC="$TMP_MOV"
fi

VF="fps=30,scale=1080:1920:force_original_aspect_ratio=decrease:flags=lanczos,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=$CLIP_BG,setsar=1"

echo
echo "converting to clip (1080x1920, 30fps, crf=$CLIP_CRF) -> $OUT_MP4"

ffmpeg -y -loglevel error -i "$SRC" -vf "$VF" \
  -c:v libx264 -pix_fmt yuv420p -preset slow -crf "$CLIP_CRF" \
  -maxrate 4M -bufsize 8M -an -movflags +faststart "$OUT_MP4"

size_of() {
  stat -f%z "$1" 2>/dev/null || stat -c%s "$1"
}

if (( $(size_of "$OUT_MP4") > MAX_BYTES )); then
  DURATION="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$SRC")"
  K="$(awk -v d="$DURATION" 'BEGIN { printf "%d", 14*1024*8 / d }')"
  echo "over 15 MB; re-encoding at ${K}k video bitrate"

  ffmpeg -y -loglevel error -i "$SRC" -vf "$VF" \
    -c:v libx264 -pix_fmt yuv420p -preset slow \
    -b:v "${K}k" -maxrate "${K}k" -bufsize "$((K * 2))k" \
    -an -movflags +faststart "$OUT_MP4"
fi

if [[ -n "$TMP_MOV" ]]; then
  rm -f "$TMP_MOV"
fi

SIZE=$(du -h "$OUT_MP4" | awk '{print $1}')
echo "done: $OUT_MP4 ($SIZE)"
