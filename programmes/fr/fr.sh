# !/bin/bash

# ---------- Chemin absolu logique ----------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

URLS=../../URLs/urls-fr.txt
TABLE=../../tableaux/fr_tableau.html
MOT="\bvert\(e\|es\|s\)\?\b"


# ---------- HTML header ----------

echo -e "
<html lang=\"fr\">
<head>
  <meta charset=\"UTF-8\" />
  <title>Tableau — Français</title>
  <link rel=\"stylesheet\" href=\"../assets/css/base.css\">
  <link rel=\"stylesheet\" href=\"../assets/css/components.css\">
  <link rel=\"stylesheet\" href=\"../assets/css/pages/table.css\">
</head>

<body>
  <section class=\"section\">
    <div class=\"glass-container\">
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
        <tr> " > $TABLE


# ---------- Traitement des URLS ----------


basename="urls-fr"
aspiration_fr="$ROOT_DIR/aspirations/fr"
concordance_fr="$ROOT_DIR/concordances/fr"
dumps_fr="$ROOT_DIR/dumps-text/fr"
contextes_fr="$ROOT_DIR/contextes/fr"

lineno=1
while read -r URL;
do
    curl -o tmp.txt -k -i -s -L -w "%{content_type}\n%{http_code}" ${URL} > metadata.tmp
    code=$(cat metadata.tmp | tail -n 1)
    encodage=$(cat metadata.tmp | head -n 1 | grep -E -o "charset=.*" | cut -d= -f2)
    if [[ -z "$encodage" ]]; then
        encodage="UTF-8"
    fi
    aspiration=$(curl -s $URL)
    echo "$aspiration" > $aspiration_fr/$basename-$lineno.html
    dumpfile="$dumps_fr/$basename-$lineno.txt"
    lynx -dump -display_charset="UTF-8" "$aspiration_fr/$basename-$lineno.html" > "$dumpfile"

    compte=$(grep -o "$MOT" "$dumpfile" | wc -l)
    ctxfile="$contextes_fr/$basename-$lineno.txt"
    grep -n "$MOT" "$dumpfile" > "$ctxfile"
    concfile="$concordance_fr/$basename-$lineno.html"
    echo "<html><head><meta charset=\"UTF-8\"/></head><body><table border='1'>" > "$concfile"
    echo "<tr><th>Contexte gauche</th><th>Cible</th><th>Contexte droit</th></tr>" >> "$concfile"

    grep -n "$MOT" "$dumpfile" | while read -r line; do
        txt=$(echo "$line" | cut -d: -f2-)
        center=$(echo "$txt" | grep -o $MOT | head -n 1)
        left=$(echo "$txt" | sed "s/\(.*\)$MOT.*/\1/")
        right=$(echo "$txt" | sed "s/.*$MOT\(.*\)/\1/")

        echo "<tr><td>$left</td>
                  <td style='color:red;font-weight:bold'>$center</td>
                  <td>$right</td></tr>" >> "$concfile"
    done
    echo "</table></body></html>" >> "$concfile"

    echo "<tr>
            <td>$lineno</td>
            <td>$code</td>
            <td><a href=\"$URL\" target=\"_blank\">$URL</a></td>
            <td>$encodage</td>
            <td><a href="$aspiration_fr/$basename-$lineno.html">aspiration</a></td>
            <td><a href="$dumps_fr/$basename-$lineno.txt">dump</a></td>
            <td>$compte</td>
            <td><a href="$contextes_fr/$basename-$lineno.txt">contextes</a></td>
            <td><a href="$concordance_fr/$basename-$lineno.html">concordance</a></td>
        </tr>" >> $TABLE
    lineno=$((lineno+1))
done < "$URLS"


echo -e "
      </table>
    </div>
  </section>
</body>
</html>
" >> $TABLE

