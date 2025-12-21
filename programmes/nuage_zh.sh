#!/usr/bin/env bash
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BASE_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

TEXT=${1:-"$BASE_DIR/corpus/corpus_zh.txt"}
MASK="$BASE_DIR/nuage/mask.png"
OUT="$BASE_DIR/nuage/zh_cloud.png"
FONT="$BASE_DIR/assets/chinois.ttf"

MAX_WORDS=500
MIN_FONT=4
MAX_FONT=150
PREFER_HORIZONTAL=0.9

python3 "$SCRIPT_DIR/nuage_zh.py" \
  --text "$TEXT" \
  --mask "$MASK" \
  --out "$OUT" \
  --font "$FONT" \
  --max_words "$MAX_WORDS" \
  --min_font "$MIN_FONT" \
  --max_font "$MAX_FONT" \
  --prefer_horizontal "$PREFER_HORIZONTAL"

echo "Saved: $OUT"
