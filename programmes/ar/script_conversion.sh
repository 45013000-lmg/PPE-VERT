#!/bin/bash

mkdir -p ../../dumps-text/AR/utf8

for f in ../../dumps-text/AR/*.txt; do
    enc=$(file -bi "$f" | sed 's/.*charset=//')

    echo "Traitement de $f (encodage détecté: $enc)"

    if [[ "$enc" != "utf-8" && "$enc" != "us-ascii" ]]; then
        iconv -f "$enc" -t utf-8 "$f" -o ../../dumps-text/AR/utf8/$(basename "$f") \
        2>/dev/null
    else
        iconv -f utf-8 -t utf-8 "$f" -o ../../dumps-text/AR/utf8/$(basename "$f") \
        2>/dev/null
    fi
done

echo "Conversion UTF-8 terminée"
