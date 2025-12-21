#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BASE_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

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
  <link rel=\"stylesheet\" href=\"../assets/css/pages/table.css\">
  <title>Résultats du mini-projet</title>
</head>
<body>
  <header>
    <a href=\"../index/accueil.html\">Accueil</a>
    <a href=\"../index/chinois.html\">Chinois</a>
  </header>
  <section class=\"section\">
    <div class=\"container\">
      <h1 class=\"title has-text-centered\">Tableau Français</h1>
      <table class=\"table\">
        <tr>
          <th>ligne</th>
          <th>code</th>
          <th>Url</th>
          <th>encodage</th>
          <th>aspirations</th>
          <th>dumps</th>
          <th>compte</th>
          <th>contextes</th>
          <th>concordances</th>
        </tr>" > "$FICHIER_SORTIE"

basename=$(basename -s .txt "$FICHIER_URLS")

ASP_DIR="aspirations/zh"
DUMP_DIR="dumps-text/zh"
CTX_DIR="contextes/zh"
CONC_DIR="concordances/zh"

lineno=1
while read -r URL;
do
    [[ -z "$URL" ]] && continue

    curl -o "$BASE_DIR/tmp.txt" -k -i -s -L -w "%{content_type}\n%{http_code}" "${URL}" > "$BASE_DIR/metadata.tmp"
    code=$(tail -n 1 "$BASE_DIR/metadata.tmp")
    encodage=$(head -n 1 "$BASE_DIR/metadata.tmp" | grep -E -o "charset=.*" | cut -d= -f2)

    if [[ -z "$encodage" ]]; then
        encodage="UTF-8"
    fi

    curl -s "$URL" > "$BASE_DIR/$ASP_DIR/$basename-$lineno.html"

    dumpfile="$BASE_DIR/$DUMP_DIR/$basename-$lineno.txt"
    lynx -dump "$BASE_DIR/$ASP_DIR/$basename-$lineno.html" > "$dumpfile"

    MOT="绿"
    compte=$(grep -o "$MOT" "$dumpfile" | wc -l)

    ctxfile="$BASE_DIR/$CTX_DIR/$basename-$lineno.txt"
    grep -n "$MOT" "$dumpfile" > "$ctxfile"

    concfile="$BASE_DIR/$CONC_DIR/$basename-$lineno.html"

    echo "<html><head><meta charset=\"UTF-8\"><link rel=\"stylesheet\" href=\"../../assets/css/base.css\"></head><body><table border=\"1\">" > "$concfile"
    echo "<tr><th>Contexte gauche</th><th style=\"color:red;\">Cible</th><th>Contexte droit</th></tr>" >> "$concfile"

    grep -n "$MOT" "$dumpfile" | while read -r line; do
        txt=$(echo "$line" | cut -d: -f2-)
        left=$(echo "$txt" | sed "s/\(.*\)$MOT.*/\1/")
        right=$(echo "$txt" | sed "s/.*$MOT\(.*\)/\1/")

        echo "<tr><td>$left</td>
                  <td style=\"color:red; font-weight:bold;\">$MOT</td>
                  <td>$right</td></tr>" >> "$concfile"
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
