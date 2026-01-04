#!/bin/bash

# Configuration des chemins (directement dans le script)
URL_FILE="../urls/arabe_url.txt"
sortie="../tableaux/AR_tableau.html"
mot='أ[ً-ْ]*خ[ً-ْ]*ض[ً-ْ]*ر'

# Vérification de l'existence du fichier source
if [ ! -f "$URL_FILE" ]; then
    echo "Erreur : Le fichier $URL_FILE est introuvable."
    exit 1
fi

# Dossiers de sortie
aspirations_arabe="../aspirations/AR"
dumps_arabe="../dumps-text/AR"
contextes_arabe="../contextes/AR"
concordances_arabe="../concordances/AR"

# Création des dossiers s'ils n'existent pas
mkdir -p "$aspirations_arabe" "$dumps_arabe" "$contextes_arabe" "$concordances_arabe"

# Début du HTML
echo -e "<!DOCTYPE html>
<html lang=\"ar\">
<head>
  <meta charset=\"UTF-8\" />
  <title>Tableau — Arabe </title>
  <link rel=\"stylesheet\" href=\"../assets/css/base.css\">
  <link rel=\"stylesheet\" href=\"../assets/css/components.css\">
  <link rel=\"stylesheet\" href=\"../assets/css/pages/table.css\">
</head>
<body>
  <section class=\"section\">
    <div class=\"glass-container\">
      <h1 class=\"title has-text-centered\">Tableau Arabe</h1>
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
        </tr>" > "$sortie"

base="arabe_url"
num=1

# Lecture du fichier ligne par ligne
while read -r url_ligne; do
    # On ignore les lignes vides
    [[ -z "$url_ligne" ]] && continue

    echo "Traitement de : $url_ligne"

    # En-têtes HTTP
    http_info=$(curl -sI -L "$url_ligne" | tr -d '\r')
    code=$(echo "$http_info" | grep -i "HTTP/" | tail -1 | awk '{print $2}')
    [ -z "$code" ] && code="inconnu"

    # Encodage
    encodage=$(echo "$http_info" | grep -i "charset=" | grep -o -E 'charset=([^ ;"]+)' | cut -d= -f2 | head -n1)
    if [ -z "$encodage" ]; then
        encodage=$(curl -s -L "$url_ligne" | grep -i "<meta" | grep -i "charset=" | grep -o -E 'charset=([^ ;">]+)' | cut -d= -f2 | head -n1)
    fi
    [ -z "$encodage" ] && encodage="inconnu"

    # Aspiration HTML
    asp_file="$aspirations_arabe/$base-$num.html"
    curl -s -L "$url_ligne" -o "$asp_file"

    # Dump texte avec lynx
    DUMP="$dumps_arabe/$base-$num.txt"
    lynx -dump -display_charset="UTF-8" -nolist "$asp_file" > "$DUMP"

    # Compte d'occurrences (sur le dump pour être plus précis que le HTML)
    compte=$(grep -oP "$mot" "$DUMP" | wc -l)

    # Contextes
    CONTEXTE="$contextes_arabe/$base-$num.txt"
    grep -n -P "$mot" "$DUMP" > "$CONTEXTE"

    # Concordances
    CONCORDANCES="$concordances_arabe/$base-$num.html"
    echo "<html><head><meta charset='UTF-8'><style>
    body{font-family:Arial,sans-serif;direction:rtl}
    table{border-collapse:collapse;width:100%}
    td.gauche{text-align:right;color:#555;width:40%}
    td.cible{text-align:center;color:red;font-weight:bold;width:10%}
    td.droite{text-align:left;color:#555;width:40%}
    </style></head><body dir='rtl'><table>" > "$CONCORDANCES"

    grep -P "$mot" "$DUMP" | while read -r line; do
        # On utilise une logique simple pour séparer gauche/cible/droite
        cible=$(echo "$line" | grep -oP "$mot" | head -1)
        gauche=$(echo "$line" | sed -E "s/(.*)$mot.*/\1/")
        droite=$(echo "$line" | sed -E "s/.*$mot(.*)/\1/")
        echo "<tr><td class='gauche'>$gauche</td><td class='cible'>$cible</td><td class='droite'>$droite</td></tr>" >> "$CONCORDANCES"
    done
    echo "</table></body></html>" >> "$CONCORDANCES"

    # Ajout de la ligne au tableau récapitulatif
    echo "<tr>
        <td>$num</td>
        <td>$code</td>
        <td><a href=\"$url_ligne\">$url_ligne</a></td>
        <td>$encodage</td>
        <td><a href=\"$asp_file\">HTML</a></td>
        <td><a href=\"$DUMP\">TEXT</a></td>
        <td>$compte</td>
        <td><a href=\"$CONTEXTE\">Contextes</a></td>
        <td><a href=\"$CONCORDANCES\">Concordancier</a></td>
    </tr>" >> "$sortie"

    num=$((num + 1))
done < "$URL_FILE"

# Fermeture des balises HTML
echo -e "      </table>
    </div>
  </section>
</body>
</html>" >> "$sortie"

echo "Terminé ! Résultats enregistrés dans $sortie"
