# !/bin/bash

# ---------- Chemin absolu logique ----------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)" # Récupère le chemin absolu du dossier où se trouve le script
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)" # Récupère le dossier racine du projet

URLS=../../URLs/urls-fr.txt # Fichier contenant les URLs en français
TABLE=../../tableaux/fr_tableau.html # Fichier HTML de sortie (tableau en français)
MOT="\bvert\(e\|es\|s\)\?\b" # Mot à rechercher (vert et ses variantes, via expression régulière)


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


basename="urls-fr" # Nom de base utilisé pour les fichiers générés

# Dossiers de sortie (français)
aspiration_fr="$ROOT_DIR/aspirations/fr"
concordance_fr="$ROOT_DIR/concordances/fr"
dumps_fr="$ROOT_DIR/dumps-text/fr"
contextes_fr="$ROOT_DIR/contextes/fr"


lineno=1
while read -r URL;
do
    # ------- Récupération des métadonnées HTTP -------

    # Télécharge la page et récupère le type de contenu et le code HTTP
    curl -o tmp.txt -k -i -s -L -w "%{content_type}\n%{http_code}" ${URL} > metadata.tmp
    code=$(cat metadata.tmp | tail -n 1)

    # Détecte l’encodage de la page (par défaut UTF-8)
    encodage=$(cat metadata.tmp | head -n 1 | grep -E -o "charset=.*" | cut -d= -f2)
    if [[ -z "$encodage" ]]; then
        encodage="UTF-8"
    fi

    # ------- Aspiration et dump texte -------

    # Télécharge le contenu HTML de la page
    aspiration=$(curl -s $URL)
    echo "$aspiration" > $aspiration_fr/$basename-$lineno.html

    # Conversion HTML → texte brut avec lynx
    dumpfile="$dumps_fr/$basename-$lineno.txt"
    lynx -dump -display_charset="UTF-8" "$aspiration_fr/$basename-$lineno.html" > "$dumpfile"

    # ------- Recherche du mot et contextes -------

    # Compte le nombre d’occurrences du mot recherché
    compte=$(grep -o "$MOT" "$dumpfile" | wc -l)

    # Sauvegarde toutes les lignes contenant le mot
    ctxfile="$contextes_fr/$basename-$lineno.txt"
    grep -n "$MOT" "$dumpfile" > "$ctxfile"

    # ------- Génération de la concordance HTML -------
    concfile="$concordance_fr/$basename-$lineno.html"
    echo "<html><head><meta charset=\"UTF-8\"/></head><body><table border='1'>" > "$concfile"
    echo "<tr><th>Contexte gauche</th><th>Cible</th><th>Contexte droit</th></tr>" >> "$concfile"

    # Découpe chaque ligne en contexte gauche / mot / contexte droit
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

