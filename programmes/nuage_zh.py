#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import re
import jieba
import numpy as np
from pathlib import Path
from PIL import Image
from wordcloud import WordCloud, STOPWORDS

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--text", required=True, help="input text file")
    ap.add_argument("--mask", required=True, help="mask png")
    ap.add_argument("--out", required=True, help="output png")
    ap.add_argument("--font", default="../assets/chinois.ttf", help="font path")
    ap.add_argument("--max_words", type=int, default=500)
    ap.add_argument("--min_font", type=int, default=4)
    ap.add_argument("--max_font", type=int, default=150)
    ap.add_argument("--prefer_horizontal", type=float, default=0.9)
    args = ap.parse_args()

    raw_text = Path(args.text).read_text(encoding="utf-8", errors="ignore")

    words = jieba.cut(raw_text)

    chinese_only_words = [
        word for word in words
        if len(word) > 1 and re.match(r'^[\u4e00-\u9fa5]+$', word)
    ]

    text_processed = " ".join(chinese_only_words)

    mask_img = Image.open(args.mask).convert("L")
    mask_array = np.array(mask_img)

    wc = WordCloud(
        font_path=args.font,
        mask=mask_array,
        background_color=None,
        mode="RGBA",
        max_words=args.max_words,
        min_font_size=args.min_font,
        max_font_size=args.max_font,
        random_state=42,
        prefer_horizontal=args.prefer_horizontal,
        collocations=False
    )

    wc.generate(text_processed)

    def white_color_func(*args, **kwargs):
        return "rgb(255, 255, 255)"

    wc.recolor(color_func=white_color_func)

    wc.to_file(args.out)
    print(f"Saved: {args.out}")

if __name__ == "__main__":
    main()
