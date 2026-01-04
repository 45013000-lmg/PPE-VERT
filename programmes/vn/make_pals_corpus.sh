#!/bin/bash


DOSSIER_DUMPS="$1"
NOM_BASE="$2"
FICHIER_SORTIE="corpus/dump-$NOM_BASE.txt"

# Chemin vers le tokenizer vietnamien
TOKENIZER_VN="./tokenize_vietnamese.py"

# Vérifier que le dossier existe
if [ ! -d "$DOSSIER_DUMPS" ]; then
    echo "Erreur: Le dossier $DOSSIER_DUMPS n'existe pas"
    exit 1
fi

# Vider le fichier de sortie
> "$FICHIER_SORTIE"

echo "Création du corpus PALS pour $NOM_BASE..."
echo "Dossier source: $DOSSIER_DUMPS"
echo "Fichier de sortie: $FICHIER_SORTIE"

# Parcourir tous les fichiers .txt du dossier
for fichier in "$DOSSIER_DUMPS"/*.txt; do
    if [ -f "$fichier" ]; then
        echo "Traitement de: $(basename "$fichier")"
        
        # Utiliser le tokenizer vietnamien pour tous les fichiers
        python3 "$TOKENIZER_VN" < "$fichier" >> "$FICHIER_SORTIE"
        
        # Ajouter une ligne vide entre les fichiers pour séparer les documents
        echo "" >> "$FICHIER_SORTIE"
    fi
done

# Nettoyer les lignes vides en fin de fichier
sed -i '/^$/N;/^\n$/d' "$FICHIER_SORTIE"

echo "Corpus PALS créé: $FICHIER_SORTIE"
echo "Nombre de mots: $(wc -w < "$FICHIER_SORTIE")"
echo "Nombre de lignes: $(wc -l < "$FICHIER_SORTIE")"