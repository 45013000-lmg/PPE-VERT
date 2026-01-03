#!/bin/bash


fichier_urls="../../URLs/vietnamien.txt"
fichier_tableau="../../tableaux/tableaux_vn.html"

# en tete du tableau
echo -e "
<html lang=\"vn\">
<head>
  <meta charset=\"UTF-8\" />
  <title>Tableau — Vietnamien</title>
  <link rel=\"stylesheet\" href=\"../assets/css/base.css\">
  <link rel=\"stylesheet\" href=\"../assets/css/components.css\">
  <link rel=\"stylesheet\" href=\"../assets/css/pages/table.css\">
</head>

<body>
  <section class=\"section\">
    <div class=\"glass-container\">
      <h1 class=\"title has-text-centered\">Tableau Vietnamien</h1>
      <table class=\"table\">
        <tr>
          <th>N°</th>
          <th>Code HTTP</th>
          <th>URL</th>
          <th>Encodage</th>
          <th>Occurrences</th>
          <th>Aspirations</th>
          <th>Dump</th>
          <th>Contexte (txt)</th>
          <th>Concordancier (html)</th>
        </tr> " > "$fichier_tableau"

lineno=1

while read -r URL; do
    echo "Traitement URL n°$lineno : $URL"

    #noms de fichiers
    basename="vietnamien-$lineno"
    fichier_html="../../aspirations/vn/$basename.html"
    fichier_text="../../dumps-text/vn/$basename.txt"
    fichier_context="../../contextes/vn/$basename.txt"
    fichier_concordance="../../concordances/vn/$basename.html"

    code_http=$(curl -s -L -w "%{http_code}" -o "$fichier_html" "$URL")
    encodage=""
    nb_mot=0

    if [ "$code_http" -eq 200 ]; then
        
        #détection encodage
        encodage=$(file -b --mime-encoding "$fichier_html")
        
        #traitement selon encodage
        if [[ "$encodage" == "utf-8" || "$encodage" == "us-ascii" ]]; then
            lynx -dump -nolist "$fichier_html" > "$fichier_text"
        else
            #conversion si ce n'est pas de l'utf-8
            iconv -f "$encodage" -t "utf-8" "$fichier_html" > "$fichier_html.utf8" 2>/dev/null
            if [ $? -eq 0 ]; then
                 lynx -dump -nolist "$fichier_html.utf8" > "$fichier_text"
                 rm "$fichier_html.utf8"
            else
                 #si iconv échoue, on laisse lynx essayer
                 lynx -dump -nolist -assume_charset="$encodage" -display_charset="utf-8" "$fichier_html" > "$fichier_text"
            fi
        fi
        
        #occurrences
        nb_mot=$(grep -o -i "xanh" "$fichier_text" | wc -l)

        #contexte 
        grep -i -C 3 "xanh" "$fichier_text" > "$fichier_context"

        
        # page concordancier
        echo "<html lang=\"vn\"><head><meta charset=\"UTF-8\">" > "$fichier_concordance"
        echo "  <link rel=\"stylesheet\" href=\"../../assets/css/base.css\">" >> "$fichier_concordance"
        echo "  <link rel=\"stylesheet\" href=\"../../assets/css/components.css\">" >> "$fichier_concordance"
        echo "  <link rel=\"stylesheet\" href=\"../../assets/css/pages/table.css\">" >> "$fichier_concordance"
        echo "</head><body>" >> "$fichier_concordance"
        echo "<section class=\"section\">" >> "$fichier_concordance"
        echo "  <div class=\"glass-container\">" >> "$fichier_concordance"
        echo "    <h1 class=\"title has-text-centered\">Concordancier pour le mot 'XANH'</h1>" >> "$fichier_concordance"
        echo "    <p>Source : <a href=\"$URL\">$URL</a></p>" >> "$fichier_concordance"
        echo "    <table class=\"table\">" >> "$fichier_concordance"
        

        #grep récupère les lignes avec "xanh"
        #sed remplace "xanh" par une version en rouge et gras 
        #puis entoure chaque ligne de balises <tr><td>...</td></tr> pour le tableau
        grep -i "xanh" "$fichier_text" | \
        sed -E 's/(xanh)/<span style="color: red; font-weight: bold;">\1<\/span>/Ig' | \
        sed 's/^/<tr><td>/' | sed 's/$/<\/td><\/tr>/' >> "$fichier_concordance"

        echo "    </table>" >> "$fichier_concordance"
        echo "  </div>" >> "$fichier_concordance"
        echo "</section>" >> "$fichier_concordance"
        echo "</body></html>" >> "$fichier_concordance"

    else
        echo "   -> Échec du téléchargement (Code: $code_http)"
        encodage="N/A"
        echo "<html lang=\"vn\"><head><meta charset=\"UTF-8\">" > "$fichier_concordance"
        echo "  <link rel=\"stylesheet\" href=\"../../assets/css/base.css\">" >> "$fichier_concordance"
        echo "</head><body>" >> "$fichier_concordance"
        echo "<section class=\"section\">" >> "$fichier_concordance"
        echo "  <div class=\"glass-container\">" >> "$fichier_concordance"
        echo "    <p>Erreur de téléchargement</p>" >> "$fichier_concordance"
        echo "  </div>" >> "$fichier_concordance"
        echo "</section></body></html>" >> "$fichier_concordance"
    fi

    #remplissage tabluea
    echo "<tr>" >> "$fichier_tableau"
    echo "<td>$lineno</td>" >> "$fichier_tableau"
    echo "<td>$code_http</td>" >> "$fichier_tableau"
    echo "<td><a href=\"$URL\">$URL</a></td>" >> "$fichier_tableau"
    echo "<td>$encodage</td>" >> "$fichier_tableau"
    echo "<td>$nb_mot</td>" >> "$fichier_tableau"
    echo "<td><a href=\"../aspirations/vn/$basename.html\">html</a></td>" >> "$fichier_tableau"
    echo "<td><a href=\"../dumps-text/vn/$basename.txt\">text</a></td>" >> "$fichier_tableau"
    echo "<td><a href=\"../contextes/vn/$basename.txt\">contexte</a></td>" >> "$fichier_tableau"
    echo "<td><a href=\"../concordances/vn/$basename.html\">Concordancier</a></td>" >> "$fichier_tableau"
    echo "</tr>" >> "$fichier_tableau"

    lineno=$((lineno + 1))

done < "$fichier_urls"

echo -e "
      </table>
    </div>
  </section>
</body>
</html>
" >> "$fichier_tableau"