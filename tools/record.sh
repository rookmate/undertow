#!/usr/bin/env bash
# Records a progress video: the autopilot plays the game while Godot's Movie Maker captures frames,
# then ffmpeg converts it to MP4. Videos go OUTSIDE the repo.
#   tools/record.sh <name> [seconds=40] [scenario=slice] [extra game args...]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${OUT_DIR:-$(dirname "$ROOT")/undertow-recordings}"
NAME="${1:?usage: record.sh <name> [seconds] [scenario] [extra args]}"
SECS="${2:-40}"
SCENARIO="${3:-slice}"
shift $(( $# < 3 ? $# : 3 ))
mkdir -p "$OUT_DIR"
TMP="$(mktemp -d /tmp/undertow-rec-XXXX)"
trap 'rm -rf "$TMP"' EXIT

cd "$ROOT"
timeout $((SECS * 6 + 120)) godot --path . --write-movie "$TMP/$NAME.avi" --fixed-fps 30 --disable-vsync --resolution 1280x720 \
  -- --autopilot --autopilot-seconds="$SECS" --autopilot-scenario="$SCENARIO" "$@" > "$TMP/run.log" 2>&1 || {
  echo "recording run failed:"; tail -30 "$TMP/run.log"; exit 1; }
ffmpeg -loglevel error -y -i "$TMP/$NAME.avi" -c:v libx264 -preset medium -crf 22 -pix_fmt yuv420p \
  -movflags +faststart -c:a aac -b:a 160k "$OUT_DIR/$NAME.mp4"
echo "$OUT_DIR/$NAME.mp4"
