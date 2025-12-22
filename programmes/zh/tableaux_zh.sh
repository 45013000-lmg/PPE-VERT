#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BASE_DIR=$(cd "$SCRIPT_DIR/../.." && pwd)
#Ces deux lignes servent à localiser précisément la racine du projet.
#La première récupère le chemin absolu du script lui-même, et la seconde remonte de deux niveaux pour atteindre la racine.

if [ $# -ne 2 ]; then
    echo "Le script attend exactement 2 arguments."
    exit 1
fi

FICHIER_URLS=$1
FICHIER_SORTIE=$2

echo -e "<!DOCTYPE html>
<html lang=\"fr\">
<head>
  <meta charset=\"UTF-8\"/>
  <link rel=\"stylesheet\" href=\"../assets/css/base.css\">
  <link rel=\"stylesheet\" href=\"../assets/css/components.css\">
  <link rel=\"stylesheet\" href=\"../assets/css/pages/table.css\">
  <title>Résultats du mini-projet</title>
</head>
<body>
  <section class=\"section\">
    <div class=\"glass-container\">
      <h1 class=\"title has-text-centered\">Tableau Chinois</h1>
      <table class=\"table\">
        <tr>
          <th>ligne</th>
          <th>code</th>
          <th>URL</th>
          <th>encodage</th>
          <th>aspirations</th>
          <th>dumps</th>
          <th>compte</th>
          <th>contextes</th>
          <th>concordances</th>
        </tr>" > "$FICHIER_SORTIE"

basename=$(basename -s .txt "$FICHIER_URLS")
# Récupère le nom du fichier sans .txt

ASP_DIR="aspirations/zh"
DUMP_DIR="dumps-text/zh"
CTX_DIR="contextes/zh"
CONC_DIR="concordances/zh"
# Ici sont définis les dossiers cibles pour chaque étape du pipeline de traitement du corpus chinois

lineno=1
while read -r URL;
do
    curl -o "$BASE_DIR/tmp.txt" -k -i -s -L -w "%{content_type}\n%{http_code}" "${URL}" > "$BASE_DIR/metadata.tmp"
    code=$(tail -n 1 "$BASE_DIR/metadata.tmp")
    encodage=$(head -n 1 "$BASE_DIR/metadata.tmp" | grep -E -o "charset=.*" | cut -d= -f2)
    #Le script extrait l'information du jeu de caractères depuis l'en-tête HTTP via les commandes grep et cut.

    if [[ -z "$encodage" ]]; then
        encodage="UTF-8"
    fi
    #En cas d'absence d'information explicite, le script définit l'encodage par défaut sur UTF-8

    curl -s "$URL" > "$BASE_DIR/$ASP_DIR/$basename-$lineno.html"
   #Télécharge la page HTML originale

    dumpfile="$BASE_DIR/$DUMP_DIR/$basename-$lineno.txt"
    lynx -dump "$BASE_DIR/$ASP_DIR/$basename-$lineno.html" > "$dumpfile"
    #Transforme HTML en texte brut lisible

    MOT="绿"
    compte=$(grep -o "$MOT" "$dumpfile" | wc -l)
    #Compte les occurrences du mot chinois « 绿 »

    ctxfile="$BASE_DIR/$CTX_DIR/$basename-$lineno.txt"
    grep -n "$MOT" "$dumpfile" > "$ctxfile"

    concfile="$BASE_DIR/$CONC_DIR/$basename-$lineno.html"

    echo "<html><head><meta charset=\"UTF-8\"><link rel=\"stylesheet\" href=\"../../assets/css/base.css\"></head><body><table border=\"1\">" > "$concfile"
    echo "<tr><th>Contexte gauche</th><th style=\"color:red;\">Cible</th><th>Contexte droit</th></tr>" >> "$concfile"

    grep -n "$MOT" "$dumpfile" | while read -r line; do
        txt=$(echo "$line" | cut -d: -f2-)
        left=$(echo "$txt" | sed "s/\(.*\)$MOT.*/\1/")
        right=$(echo "$txt" | sed "s/.*$MOT\(.*\)/\1/")
        #On utilise des expressions régulières avec sed pour scinder chaque ligne contenant le mot-cible en "contexte gauche" et "contexte droit"

        echo "<tr><td>$left</td>
                  <td style=\"color:red; font-weight:bold;\">$MOT</td>
                  <td>$right</td></tr>" >> "$concfile"
                  #Dans le tableau HTML, le mot-cible est stylisé en rouge
    done
    echo "</table></body></html>" >> "$concfile"

    echo "<tr>
          <td>$lineno</td>
          <td>$code</td>
          <td><a href=\"$URL\" target=\"_blank\">$URL</a></td>
          <td>$encodage</td>
          <td><a href=\"../$ASP_DIR/$basename-$lineno.html\">aspiration</a></td>
          <td><a href=\"../$DUMP_DIR/$basename-$lineno.txt\">dump</a></td>
          <td>$compte</td>
          <td><a href=\"../$CTX_DIR/$basename-$lineno.txt\">contextes</a></td>
          <td><a href=\"../$CONC_DIR/$basename-$lineno.html\">concordance</a></td>
        </tr>" >> "$FICHIER_SORTIE"

    lineno=$((lineno+1))
done < "$FICHIER_URLS"

echo -e "
      </table>
    </div>
  </section>
</body>
</html>" >> "$FICHIER_SORTIE"

rm -f "$BASE_DIR/tmp.txt" "$BASE_DIR/metadata.tmp"
#On supprime automatiquement les fichiers temporaires créés durant l'exécution
