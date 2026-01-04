#!/usr/bin/env python3
from wordcloud import WordCloud
import arabic_reshaper
import os
import re
import numpy as np
from PIL import Image

# chemins
tsv_path = "./cooccurrents_ar.tsv"
mask_path = "../../nuage/mask.png"
font_path = "../../assets/Amiri-Regular.ttf"
output_folder = "../../nuage"
output_name = "nuage_arabe.png"

# Liste des stopwords à exclure pour nuage de mots arabe
stopwords = {
    # --- PRÉPOSITIONS ET PARTICULES ---
    "من", "في", "على", "إلى", "عن", "مع", "حتى", "عند", "بين", "تحت", "فوق",
    "منذ", "خلال", "بدون", "نحو", "لدى", "بواسطة", "عبر", "لدن", "منذ",
    "إذ", "إذا", "بما", "كما", "لكي", "كي", "إلا", "غير", "سوى", "فقط",

    # --- PRONOMS PERSONNELS (Sujets et Compléments) ---
    "أنا", "نحن", "أنت", "أنتِ", "أنتما", "أنتم", "أنتن",
    "هو", "هي", "هما", "هم", "هن",
    "إياك", "إياي", "إياه", "إيانا",

    # --- PRONOMS DÉMONSTRATIFS ---
    "هذا", "هذه", "هذان", "هاتان", "هؤلاء",
    "ذلك", "تلك", "ذلكم", "ذلكن", "أولئك", "هنا", "هناك",

    # --- PRONOMS RELATIFS ---
    "الذي", "التي", "الذان", "اللتان", "الذين", "اللواتي", "اللاتي", "اللاي", "من", "ما",

    # --- MOTS DE LIAISON ET CONJONCTIONS ---
    "أو", "أم", "بل", "لكن", "لكنَّ", "إنَّ", "أنَّ", "لأن", "بينما", "حيث", "حيثما",

    # --- ADVERBES ET QUANTIFICATEURS ---
    "كل", "بعض", "جميع", "كافة", "أكثر", "أقل", "جدا", "أيضا", "كذلك", "فقط",
    "هكذا", "أي", "أين", "كيف", "متى", "كم",

    # --- AUTRES PARASITES TECHNIQUES ---
    "31.05", "logo-img", "TEA", "GREEN", "URL", "http", "https", "www",
    "com", "html", "php", "image", "img", "png", "jpg", "pdf", "index"
}
MAX_REPEAT_PER_WORD = 200

#lecture et filtrage
arabic_regex = re.compile(r'^[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]+$')
tokens_expanded = []

with open(tsv_path, "r", encoding="utf-8", errors="ignore") as f:
    next(f, None)
    for line in f:
        parts = line.rstrip("\n").split("\t")
        if len(parts) < 5: continue
        token = parts[0].strip()
        try:
            freq = int(parts[4])
        except: continue
        if token in stopwords or len(token) < 3 or not arabic_regex.match(token) or freq <= 0 or token.startswith("و"):
            continue
        tokens_expanded.extend([token] * min(freq, MAX_REPEAT_PER_WORD))

text_clean = " ".join(tokens_expanded)

#reshape ( pour que les mots soient dans le bon sens )
final_text = arabic_reshaper.reshape(text_clean)

#génération
mask_img = np.array(Image.open(mask_path))
wc = WordCloud(
    font_path=font_path,
    mask=mask_img,
    background_color=None,
    mode="RGBA",
    collocations=False,
    regexp=r"\S+",
    prefer_horizontal=0.95
).generate(final_text)

wc.recolor(color_func=lambda *args, **kwargs: "rgb(255, 255, 255)")
wc.to_file(os.path.join(output_folder, output_name))
print(f"nuage enregistrée dans {output_name}")
