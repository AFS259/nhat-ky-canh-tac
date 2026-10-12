"""Generate app icon + fruit icon assets for NhatKyCanhTacAFS.

Downloads fruit emoji PNGs (OpenMoji, 618px) from URL and builds
Xcode asset imagesets. Also renders a 1024x1024 app icon (fruit + QR).

Run:  python scripts/gen_assets.py
"""

import io
import json
import os
import urllib.request

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "NhatKyCanhTacAFS", "Assets.xcassets")

OPENMOJI = "https://raw.githubusercontent.com/hfg-gmuend/openmoji/master/color/618x618/{}.png"

# crop-type keyword -> (asset name, openmoji hex code)
FRUITS = [
    ("FruitGuava", "1F350"),        # Ổi (pear)
    ("FruitMango", "1F96D"),        # Xoài
    ("FruitPomelo", "1F34A"),       # Bưởi (tangerine)
    ("FruitOrange", "1F7E0"),       # Cam
    ("FruitLemon", "1F34B"),        # Chanh
    ("FruitDragonFruit", "1F409"),  # Thanh Long
    ("FruitWatermelon", "1F349"),   # Dưa Hấu
    ("FruitTomato", "1F345"),       # Cà Chua
    ("FruitChili", "1F336"),        # Ớt
    ("FruitGrape", "1F347"),        # Nho
    ("FruitSeedling", "1F331"),     # fallback
]


def fetch(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "afs-asset-gen"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def write_contents(folder: str, images: list, extra: dict | None = None):
    data = {"images": images, "info": {"author": "xcode", "version": 1}}
    if extra:
        data.update(extra)
    with open(os.path.join(folder, "Contents.json"), "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)


def make_imageset(name: str, source: Image.Image, sizes=(60, 120, 180)):
    folder = os.path.join(ASSETS, name + ".imageset")
    os.makedirs(folder, exist_ok=True)
    images = []
    for scale, px in zip(("1x", "2x", "3x"), sizes):
        img = source.resize((px, px), Image.LANCZOS)
        fn = f"{name}-{scale}.png"
        img.save(os.path.join(folder, fn))
        images.append({"filename": fn, "idiom": "universal", "scale": scale})
    write_contents(folder, images)
    print("wrote", name)


def make_logo(source: Image.Image):
    folder = os.path.join(ASSETS, "Logo.imageset")
    os.makedirs(folder, exist_ok=True)
    img = source.convert("RGBA")
    img.thumbnail((540, 540), Image.LANCZOS)
    fn = "Logo.png"
    img.save(os.path.join(folder, fn))
    write_contents(folder, [{"filename": fn, "idiom": "universal", "scale": "1x"}])
    print("wrote Logo")


def _fit_font(path: str, text: str, max_w: int, start_size: int):
    from PIL import ImageFont

    size = start_size
    while size > 12:
        font = ImageFont.truetype(path, size)
        b = font.getbbox(text)
        if (b[2] - b[0]) <= max_w:
            return font
        size -= 4
    return ImageFont.truetype(path, 12)


def _draw_text(base, text, font, xy, fill, blur=16, off=(0, 12), shadow=(0, 0, 0, 150)):
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).text((xy[0] + off[0], xy[1] + off[1]), text, font=font, fill=shadow, anchor="mm")
    base.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur)))
    ImageDraw.Draw(base).text(xy, text, font=font, fill=fill, anchor="mm")


def make_app_icon():
    W = 1024
    bg = Image.new("RGB", (W, W))
    top = (14, 61, 20)
    bottom = (76, 175, 80)
    d = ImageDraw.Draw(bg)
    for y in range(W):
        t = y / (W - 1)
        d.line(
            [(0, y), (W, y)],
            fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)),
        )

    # soft radial highlight
    glow = Image.new("L", (W, W), 0)
    gd = ImageDraw.Draw(glow)
    gd.ellipse([-160, -220, 640, 560], fill=70)
    bg.paste(Image.new("RGB", (W, W), (255, 255, 255)), (0, 0), glow.filter(ImageFilter.GaussianBlur(180)))
    bg = bg.convert("RGBA")

    # white badge + seedling on top
    cx, cy, r = W // 2, 250, 145
    shadow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse([cx - r, cy - r, cx + r, cy + r], fill=(0, 0, 0, 90))
    bg = Image.alpha_composite(bg, shadow.filter(ImageFilter.GaussianBlur(18)))

    layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 255, 255, 255))
    bg = Image.alpha_composite(bg, layer)

    try:
        seed = Image.open(io.BytesIO(fetch(OPENMOJI.format("1F331")))).convert("RGBA")
        seed = seed.resize((220, 220), Image.LANCZOS)
        bg.alpha_composite(seed, (cx - 110, cy - 110))
    except Exception as e:  # noqa: BLE001
        print("seedling failed", e)

    # AFS
    afs_font = _fit_font(r"C:\Windows\Fonts\ariblk.ttf", "AFS", 770, 400)
    _draw_text(bg, "AFS", afs_font, (W // 2, 585), (255, 255, 255, 255), blur=18, off=(0, 14))

    # divider
    ImageDraw.Draw(bg).rounded_rectangle([W // 2 - 130, 726, W // 2 + 130, 740], radius=7, fill=(255, 255, 255, 190))

    # KHÔNG GIAN VƯỜN
    sub_font = _fit_font(r"C:\Windows\Fonts\segoeuib.ttf", "KHÔNG GIAN VƯỜN", 840, 150)
    _draw_text(bg, "KHÔNG GIAN VƯỜN", sub_font, (W // 2, 845), (235, 255, 235, 255), blur=14, off=(0, 9))

    icon = bg.convert("RGB")
    folder = os.path.join(ASSETS, "AppIcon.appiconset")
    os.makedirs(folder, exist_ok=True)
    icon.save(os.path.join(folder, "icon-1024.png"))
    write_contents(folder, [{
        "filename": "icon-1024.png",
        "idiom": "universal",
        "platform": "ios",
        "size": "1024x1024",
    }])
    print("wrote AppIcon")


def main():
    for name, code in FRUITS:
        try:
            src = Image.open(io.BytesIO(fetch(OPENMOJI.format(code)))).convert("RGBA")
            make_imageset(name, src)
        except Exception as e:  # noqa: BLE001
            print("FAILED", name, e)

    logo_path = os.path.join(ROOT, "scripts", "afs_logo.png")
    if os.path.exists(logo_path):
        make_logo(Image.open(logo_path))

    make_app_icon()


if __name__ == "__main__":
    main()
