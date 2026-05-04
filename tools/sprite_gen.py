"""Generate the actor sprites for Grizzy's Treasure.

Run from project root: `python3 tools/sprite_gen.py`
Outputs PNGs into ./sprites/.
All art is original ("inspired by" the show, not a reproduction of its characters).
Sprites are drawn top-down with the actor facing UP in image space; the Godot
side rotates them at runtime and applies a +PI/2 offset.
"""
from __future__ import annotations

import os
import random

from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "sprites")
os.makedirs(OUT, exist_ok=True)


def _shadow(size: int, cx: int, cy: int, rx: int, ry: int) -> Image.Image:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=(0, 0, 0, 90))
    return layer.filter(ImageFilter.GaussianBlur(2.5))


def make_grizzy(path: str) -> None:
    size = 128
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    img.alpha_composite(_shadow(size, 64, 110, 38, 10))

    d = ImageDraw.Draw(img)

    body = (110, 70, 40, 255)
    body_dark = (70, 42, 22, 255)
    belly = (188, 142, 96, 255)
    ear_inner = (224, 176, 132, 255)
    snout = (228, 188, 144, 255)
    nose = (28, 18, 12, 255)

    # ears
    d.ellipse((22, 14, 50, 42), fill=body, outline=body_dark, width=3)
    d.ellipse((78, 14, 106, 42), fill=body, outline=body_dark, width=3)
    d.ellipse((30, 22, 42, 34), fill=ear_inner)
    d.ellipse((86, 22, 98, 34), fill=ear_inner)

    # body (rounded)
    d.ellipse((20, 38, 108, 116), fill=body, outline=body_dark, width=3)

    # belly
    d.ellipse((40, 70, 88, 112), fill=belly)

    # head over body, slightly forward (up in image space)
    d.ellipse((28, 28, 100, 86), fill=body, outline=body_dark, width=3)

    # snout
    d.ellipse((48, 50, 80, 78), fill=snout, outline=body_dark, width=2)

    # mouth line
    d.arc((54, 60, 74, 76), start=20, end=160, fill=body_dark, width=2)

    # nose
    d.ellipse((58, 52, 70, 62), fill=nose)
    d.ellipse((61, 54, 64, 57), fill=(120, 90, 70, 255))  # nose highlight

    # eyes
    eye_white = (252, 250, 244, 255)
    d.ellipse((38, 40, 52, 54), fill=eye_white, outline=body_dark, width=2)
    d.ellipse((76, 40, 90, 54), fill=eye_white, outline=body_dark, width=2)
    # pupils (looking forward = up)
    d.ellipse((43, 44, 49, 50), fill=(20, 14, 8, 255))
    d.ellipse((81, 44, 87, 50), fill=(20, 14, 8, 255))
    d.ellipse((45, 45, 47, 47), fill=eye_white)
    d.ellipse((83, 45, 85, 47), fill=eye_white)

    # eyebrows — angry/alert
    d.line((36, 36, 52, 40), fill=body_dark, width=3)
    d.line((90, 36, 76, 40), fill=body_dark, width=3)

    img.save(path)


def make_lemming(path: str) -> None:
    size = 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    img.alpha_composite(_shadow(size, 32, 54, 18, 5))

    d = ImageDraw.Draw(img)

    cream = (248, 240, 222, 255)
    cream_dark = (172, 156, 130, 255)
    fur = (228, 218, 196, 255)

    # ears
    d.ellipse((14, 6, 24, 18), fill=cream, outline=cream_dark, width=2)
    d.ellipse((40, 6, 50, 18), fill=cream, outline=cream_dark, width=2)
    d.ellipse((17, 9, 21, 14), fill=(220, 170, 160, 255))
    d.ellipse((43, 9, 47, 14), fill=(220, 170, 160, 255))

    # body
    d.ellipse((10, 14, 54, 56), fill=cream, outline=cream_dark, width=2)
    # subtle face fluff
    d.ellipse((16, 22, 48, 46), fill=fur)

    # eyes — wide/mischievous
    d.ellipse((20, 22, 28, 32), fill=(255, 255, 255, 255), outline=(40, 30, 20, 255), width=1)
    d.ellipse((36, 22, 44, 32), fill=(255, 255, 255, 255), outline=(40, 30, 20, 255), width=1)
    d.ellipse((23, 25, 27, 30), fill=(20, 14, 8, 255))
    d.ellipse((39, 25, 43, 30), fill=(20, 14, 8, 255))
    d.ellipse((24, 26, 25, 27), fill=(255, 255, 255, 255))
    d.ellipse((40, 26, 41, 27), fill=(255, 255, 255, 255))

    # nose + smile
    d.ellipse((30, 33, 34, 37), fill=(60, 40, 30, 255))
    d.arc((26, 36, 38, 44), start=10, end=170, fill=(60, 40, 30, 255), width=2)

    # paws hint
    d.ellipse((18, 48, 26, 56), fill=cream, outline=cream_dark, width=1)
    d.ellipse((38, 48, 46, 56), fill=cream, outline=cream_dark, width=1)

    img.save(path)


def make_yummy(path: str) -> None:
    size = 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    img.alpha_composite(_shadow(size, 32, 54, 18, 6))

    d = ImageDraw.Draw(img)

    gold = (242, 198, 64, 255)
    gold_dark = (168, 124, 28, 255)
    lid = (190, 80, 52, 255)
    lid_dark = (108, 38, 18, 255)
    label = (252, 246, 220, 255)

    # jar body
    d.rounded_rectangle((12, 18, 52, 56), radius=10, fill=gold, outline=gold_dark, width=2)
    # jar shading
    d.rounded_rectangle((14, 20, 22, 54), radius=4, fill=(255, 230, 130, 200))
    d.rounded_rectangle((44, 22, 50, 54), radius=4, fill=(180, 130, 30, 180))

    # lid
    d.rounded_rectangle((10, 8, 54, 24), radius=6, fill=lid, outline=lid_dark, width=2)
    d.rectangle((10, 18, 54, 22), fill=lid_dark)

    # label
    d.rectangle((22, 30, 42, 46), fill=label, outline=gold_dark, width=1)
    # tiny "Y"
    d.line((28, 34, 32, 40), fill=(170, 90, 30, 255), width=2)
    d.line((36, 34, 32, 40), fill=(170, 90, 30, 255), width=2)
    d.line((32, 40, 32, 44), fill=(170, 90, 30, 255), width=2)

    # sparkle
    d.line((46, 12, 50, 16), fill=(255, 255, 255, 220), width=2)
    d.line((50, 12, 46, 16), fill=(255, 255, 255, 220), width=2)

    img.save(path)


def main() -> None:
    make_grizzy(os.path.join(OUT, "grizzy.png"))
    make_lemming(os.path.join(OUT, "lemming.png"))
    make_yummy(os.path.join(OUT, "yummy.png"))
    print("wrote sprites to", OUT)


if __name__ == "__main__":
    main()
