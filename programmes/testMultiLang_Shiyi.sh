# !/bin/bash

# --------- verification de paramètres ----------

if [ $# -ne 3 ]; then
  echo "Usage: $0 URLS.txt table_lang.html Lang"
  echo "Lang = zh | fr | ar | vi"
  exit 1
fi

URLS="$1"
TABLE="$2"
Lang="$3"

# --------- “vert” dans différentes langues ----------

if [ "$Lang" = "zh" ]; then
  MOT="绿"

elif [ "$Lang" = "fr" ]; then
  MOT="\bvert\(e\|es\|s\)\?\b"

elif [ "$Lang" = "ar" ]; then
  MOT="أخضر"

elif [ "$Lang" = "vi" ]; then
  MOT="xanh"

else
  echo "langue inconnu: $Lang"
  exit 1
fi

# ---------- HTML header ----------

echo -e "
<html lang="$Lang">
<head>
  <meta charset=\"UTF-8\"/>
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
  <link rel=\"stylesheet\" href=\"https://cdn.jsdelivr.net/npm/bulma@1.0.2/css/versions/bulma-no-dark-mode.min.css\">
  <link rel=\"stylesheet\" href=\"assets/css/style.css\">
  <title>Résultats du mini-projet</title>
</head>

<body>
  <section class=\"section\">
    <div class=\"container has-background-white\">
      <h1 class=\"title has-text-centered\">Tableau des résultats</h1>
      <table border=\"1\" class=\"table is-striped is-hoverable is-fullwidth\">
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
        <tr> " > tableaux/$TABLE

# ---------- Traitement des URLS ----------

basename=$(basename -s .txt $URLS)

lineno=1
while read -r URL;
do
    echo $URL
    curl -o tmp.txt -k -i -s -L -w "%{content_type}\n%{http_code}" ${URL} > metadata.tmp
    code=$(cat metadata.tmp | tail -n 1)
    encodage=$(cat metadata.tmp | head -n 1 | grep -E -o "charset=.*" | cut -d= -f2)
    if [[ -z "$encodage" ]]; then
        encodage="UTF-8"
    fi
    aspiration=$(curl -s $URL)
    echo "$aspiration" > aspirations/$Lang/$basename-$lineno.html
    dumpfile="dumps-text/$Lang/$basename-$lineno.txt"
    lynx -dump -display_charset="UTF-8" "aspirations/$Lang/$basename-$lineno.html" > "$dumpfile"
    compte=$(grep -o "$MOT" "$dumpfile" | wc -l)
    ctxfile="contextes/$Lang/$basename-$lineno.txt"
    grep -n "$MOT" "$dumpfile" > "$ctxfile"
    concfile="concordances/$Lang/$basename-$lineno.html"
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
            <td><a href="../aspirations/$Lang/$basename-$lineno.html">aspiration</a></td>
            <td><a href="../dumps-text/$Lang/$basename-$lineno.txt">dump</a></td>
            <td>$compte</td>
            <td><a href="../contextes/$Lang/$basename-$lineno.txt">contextes</a></td>
            <td><a href="../concordances/$Lang/$basename-$lineno.html">concordance</a></td>
        </tr>" >> tableaux/$TABLE
    lineno=$((lineno+1))
done < "$URLS"

echo -e "
      </table>
    </div>
  </section>
</body>
</html>
" >> tableaux/$TABLE

