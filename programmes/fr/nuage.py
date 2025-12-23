#!/usr/bin/env python3

import argparse
from pathlib import Path
import re
import numpy as np
from PIL import Image
from wordcloud import WordCloud

# Placez les mots à l'endroit correct en arrière-plan.
def auto_invert_if_needed(mask: np.ndarray) -> np.ndarray:

    black_ratio = np.mean(mask < 10)
    white_ratio = np.mean(mask > 245)

    if black_ratio > 0.70 and white_ratio < 0.25:
        return 255 - mask

    return mask


# Définir les paramètres
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--text", required=True) # fichier texte d'entrée
    ap.add_argument("--mask", default="mask.png")
    ap.add_argument("--out", default="out.png")
    ap.add_argument("--font", default="")
    ap.add_argument("--max_words", type=int, default=120)
    ap.add_argument("--min_font", type=int, default=10)
    ap.add_argument("--max_font", type=int, default=90)
    ap.add_argument("--prefer_horizontal", type=float, default=0.95)
    args = ap.parse_args()

    text = Path(args.text).read_text(encoding="utf-8", errors="ignore")
    text = text.lower()

    # Gérer les contractions françaises (l', d', qu', etc.)
    text = re.sub(r"\b([ldjtmcns])'", r"\1 ", text)

    # Charger le mask
    mask_img = Image.open(args.mask).convert("L")
    mask = np.array(mask_img, dtype=np.uint8)
    mask = auto_invert_if_needed(mask)

    # Stopwords français
    FRENCH_STOPWORDS = {
        "le", "la", "les", "un", "une", "des", "de", "du", "votre", "Wiki", "user", "ppe"
        "et", "à", "en", "pour", "que", "qui", "dans", "sur", "fr_fr", "vous", "index",
        "au", "aux", "ce", "ces", "cet", "cette", "www", "com", "url", "file", "yaoshiyi"
        "son", "sa", "ses", "leur", "leurs", "https", "html", "fr", "wiki", "urls", "est"
        "ne", "pas", "plus", "ou", "mais", "donc", "or", "ni", "car", "et", "org", "Yaoshiyi"
    }

    stop = FRENCH_STOPWORDS

    wc = WordCloud(
        width=mask.shape[1],
        height=mask.shape[0],
        mask=mask,
        background_color=None,
        mode="RGBA",
        max_words=args.max_words,
        min_font_size=args.min_font,
        max_font_size=args.max_font,
        prefer_horizontal=args.prefer_horizontal,
        collocations=False,
        stopwords=stop,
        font_path=args.font if args.font else None,
    ).generate(text)

    def white_color_func(*args, **kwargs):
        return "rgb(255,255,255)"

    out_img = wc.recolor(color_func=white_color_func).to_image()
    out_img.save(args.out)


if __name__ == "__main__":
    main()
