#!/bin/bash

# --- Entrée : dossiers et fichiers existants ---
INPUT_FILE="../../corpus/corpus_arabe.txt"   # ton fichier texte original

# --- Sortie PALS ---

OUTPUT_FILE="./corpus_tokeniser.txt"

# Vider le fichier de sortie s’il existe déjà
> "$OUTPUT_FILE"

# --- Tokenisation : 1 mot par ligne, ligne vide pour séparation ---
cat "$INPUT_FILE" \
| tr ' ' '\n' \
| sed '/^$/d' \
>> "$OUTPUT_FILE"

# Ajouter une ligne vide à la fin (séparation)
echo "" >> "$OUTPUT_FILE"

echo "Corpus tokenisé créé : $OUTPUT_FILE"
