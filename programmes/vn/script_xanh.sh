#!/bin/bash


fichier_urls="../URLS/vietnamien.txt"
fichier_tableau="../tableaux/tableau_vietnamien.html"

# en tete du tableau
echo "<html><head><meta charset=\"UTF-8\"></head><body>" > "$fichier_tableau"
echo "<table border=\"1\" align=\"center\">" >> "$fichier_tableau"
echo "<tr><th>N°</th><th>URL</th><th>Code HTTP</th><th>Encodage</th><th>Occurrences</th><th>Aspirations</th><th>Dump</th><th>Contexte (txt)</th><th>Concordancier (html)</th></tr>" >> "$fichier_tableau"

lineno=1

while read -r URL; do
    echo "Traitement URL n°$lineno : $URL"

    #noms de fichiers
    basename="vietnamien-$lineno"
    fichier_html="../aspirations/$basename.html"
    fichier_text="../dumps-text/$basename.txt"
    fichier_context="../contextes/$basename.txt"
    fichier_concordance="../concordances/$basename.html"

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
        echo "<html><head><meta charset=\"UTF-8\"></head><body>" > "$fichier_concordance"
        echo "<h3>Concordancier pour le mot 'XANH'</h3>" >> "$fichier_concordance"
        echo "<p>Source : <a href=\"$URL\">$URL</a></p>" >> "$fichier_concordance"
        echo "<table border=\"1\">" >> "$fichier_concordance"
        

        #grep récupère les lignes avec "xanh"
        #sed remplace "xanh" par une version en rouge et gras 
        #puis entoure chaque ligne de balises <tr><td>...</td></tr> pour le tableau
        grep -i "xanh" "$fichier_text" | \
        sed -E 's/(xanh)/<span style="color: red; font-weight: bold;">\1<\/span>/Ig' | \
        sed 's/^/<tr><td>/' | sed 's/$/<\/td><\/tr>/' >> "$fichier_concordance"

        echo "</table></body></html>" >> "$fichier_concordance"

    else
        echo "   -> Échec du téléchargement (Code: $code_http)"
        encodage="N/A"
        echo "<html><body><p>Erreur de téléchargement</p></body></html>" > "$fichier_concordance"
    fi

    #remplissage tabluea
    echo "<tr>" >> "$fichier_tableau"
    echo "<td>$lineno</td>" >> "$fichier_tableau"
    echo "<td><a href=\"$URL\">$URL</a></td>" >> "$fichier_tableau"
    echo "<td>$code_http</td>" >> "$fichier_tableau"
    echo "<td>$encodage</td>" >> "$fichier_tableau"
    echo "<td>$nb_mot</td>" >> "$fichier_tableau"
    echo "<td><a href=\"../aspirations/$basename.html\">html</a></td>" >> "$fichier_tableau"
    echo "<td><a href=\"../dumps-text/$basename.txt\">text</a></td>" >> "$fichier_tableau"
    echo "<td><a href=\"../contextes/$basename.txt\">contexte</a></td>" >> "$fichier_tableau"
    echo "<td><a href=\"../concordances/$basename.html\">Concordancier</a></td>" >> "$fichier_tableau"
    echo "</tr>" >> "$fichier_tableau"

    lineno=$((lineno + 1))

done < "$fichier_urls"

echo "</table></body></html>" >> "$fichier_tableau"