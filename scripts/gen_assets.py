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


def make_app_icon():
    import qrcode
    from qrcode.constants import ERROR_CORRECT_M

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

    # white card
    card = (232, 190, 812, 790)
    shadow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [card[0] + 10, card[1] + 24, card[2] + 10, card[3] + 24],
        radius=120, fill=(0, 0, 0, 90),
    )
    bg = Image.alpha_composite(bg.convert("RGBA"), shadow.filter(ImageFilter.GaussianBlur(22)))

    layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(layer).rounded_rectangle(card, radius=120, fill=(255, 255, 255, 255))
    bg = Image.alpha_composite(bg, layer)

    # QR inside card
    qr = qrcode.QRCode(box_size=1, border=0, error_correction=ERROR_CORRECT_M)
    qr.add_data("AFS1:NhatKyCanhTacAFS")
    qr.make(fit=True)
    qimg = qr.make_image(fill_color=(20, 70, 25), back_color="white").convert("RGBA").resize((470, 470), Image.NEAREST)
    bg.alpha_composite(qimg, (287, 258))

    # fruit (mango) overlapping bottom-right
    mango = Image.open(io.BytesIO(fetch(OPENMOJI.format("1F96D")))).convert("RGBA")
    mango = mango.resize((360, 360), Image.LANCZOS).rotate(-12, expand=True, resample=Image.BICUBIC)
    bg.alpha_composite(mango, (612, 566))

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
