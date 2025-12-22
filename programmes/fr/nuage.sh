#!/usr/bin/env bash

# ---------- Chemin absolu logique ----------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

ressource="$ROOT_DIR/dumps-text/fr/*.txt"
sortie_corpus="$ROOT_DIR/corpus/corpus.txt"

iconv -f UTF-8 -t UTF-8 -c $ressource > $sortie_corpus

set -e

TEXT=$sortie_corpus
MASK="$ROOT_DIR/nuage/mask.png"
OUT="$ROOT_DIR/nuage/fr.png"
FONT="$ROOT_DIR/assets/Latin-Arabe.ttf"

MAX_WORDS=2000
MIN_FONT=6
MAX_FONT=150
PREFER_HORIZONTAL=0.98


python3 nuage.py \
  --text "$TEXT" \
  --mask "$MASK" \
  --out "$OUT" \
  --font "$FONT" \
  --max_words "$MAX_WORDS" \
  --min_font "$MIN_FONT" \
  --max_font "$MAX_FONT" \
  --prefer_horizontal "$PREFER_HORIZONTAL" \

echo "Saved: $OUT"


