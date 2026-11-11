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
INPUT="${2-}"
if [[ -z "$NAME" || "$NAME" == */* || "$NAME" == . || "$NAME" == .. || ($# == 2 && -z "$INPUT") ]]; then
  echo "name must be a nonempty filename; input must not be empty." >&2
  exit 64
fi
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT_DIR/clips"
OUT_MP4="$OUT_DIR/$NAME.mp4"
MAX_BYTES=15000000

# Tunables — override via env.
CLIP_BG="${CLIP_BG:-0x0B0B0F}"
CLIP_CRF="${CLIP_CRF:-23}"

mkdir -p "$OUT_DIR"

if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v ffprobe >/dev/null 2>&1; then
  echo "ffmpeg and ffprobe are required. install with: brew install ffmpeg" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d "$OUT_DIR/.record-XXXXXX")"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
TMP_MP4="$TMP_DIR/clip.mp4"

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

  TMP_MOV="$TMP_DIR/recording.mov"
  echo "recording booted simulator -> $TMP_MOV"
  echo "press Ctrl+C in this terminal to stop and convert."

  trap ':' INT
  recording_status=0
  xcrun simctl io booted recordVideo --codec=h264 --force "$TMP_MOV" || recording_status=$?
  trap 'exit 130' INT
  if (( recording_status != 0 && recording_status != 130 )); then
    echo "simulator recording failed ($recording_status)." >&2
    exit "$recording_status"
  fi

  if [[ ! -s "$TMP_MOV" ]]; then
    echo "recording produced no output." >&2
    exit 1
  fi
  SRC="$TMP_MOV"
fi

VF="fps=30,scale=1080:1920:force_original_aspect_ratio=decrease:flags=lanczos,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=$CLIP_BG,setsar=1"

echo
echo "converting to clip (1080x1920, 30fps, crf=$CLIP_CRF) -> $OUT_MP4"

ffmpeg -y -loglevel error -i "$SRC" -vf "$VF" \
  -c:v libx264 -pix_fmt yuv420p -preset slow -crf "$CLIP_CRF" \
  -maxrate 4M -bufsize 8M -an -movflags +faststart "$TMP_MP4"

size_of() {
  wc -c < "$1"
}

if (( $(size_of "$TMP_MP4") >= MAX_BYTES )); then
  DURATION="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$SRC")"
  K="$(awk -v d="$DURATION" 'BEGIN { if (d !~ /^[0-9]+([.][0-9]+)?$/ || d <= 0) exit 1; printf "%d", 14000*8 / d }')"
  if (( K < 1 )); then
    echo "input is too long for a clip under 15 MB." >&2
    exit 1
  fi
  echo "over 15 MB; re-encoding at ${K}k video bitrate"

  ffmpeg -y -loglevel error -i "$SRC" -vf "$VF" \
    -c:v libx264 -pix_fmt yuv420p -preset slow \
    -b:v "${K}k" -maxrate "${K}k" -bufsize "$((K * 2))k" \
    -an -movflags +faststart "$TMP_MP4"
fi

if (( $(size_of "$TMP_MP4") >= MAX_BYTES )); then
  echo "clip still exceeds 15 MB; use a shorter input." >&2
  exit 1
fi
mv -f "$TMP_MP4" "$OUT_MP4"

SIZE=$(du -h "$OUT_MP4" | awk '{print $1}')
echo "done: $OUT_MP4 ($SIZE)"
