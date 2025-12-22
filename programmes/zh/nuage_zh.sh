#!/usr/bin/env bash
set -e
#le script s’arrête immédiatement dès qu’une commande échoue

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BASE_DIR=$(cd "$SCRIPT_DIR/../.." && pwd)
#Ces deux lignes servent à localiser précisément la racine du projet.
#La première récupère le chemin absolu du script lui-même, et la seconde remonte de deux niveaux pour atteindre la racine.

TEXT=${1:-"$BASE_DIR/corpus/corpus_zh.txt"}
#La syntaxe ${1:-...} est utilisée pour définir une valeur par défaut :
#si aucun argument n'est fourni lors de l'exécution, le script charge automatiquement le corpus chinois prédéfini.
MASK="$BASE_DIR/nuage/mask.png"
OUT="$BASE_DIR/nuage/zh_cloud.png"
FONT="$BASE_DIR/assets/chinois.ttf" #police chinoise spécialisée à télécharger

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
  #ici, le script Bash joue le rôle d'ordonnanceur. Il appelle le script Python en lui transmettant une série de paramètres

echo "Saved: $OUT"
