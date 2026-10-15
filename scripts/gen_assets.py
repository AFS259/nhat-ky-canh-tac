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
    # --- Trái cây ---
    ("FruitGuava", "1F350"),        # Ổi, Lê (nhóm quả xanh)
    ("FruitMango", "1F96D"),        # Xoài
    ("FruitPomelo", "1F34A"),       # Bưởi, Quýt (quả có múi)
    ("FruitOrange", "1F7E0"),       # Cam
    ("FruitLemon", "1F34B"),        # Chanh, Chanh dây
    ("FruitDragonFruit", "1F409"),  # Thanh Long
    ("FruitWatermelon", "1F349"),   # Dưa Hấu
    ("FruitMelon", "1F348"),        # Dưa Lưới, Dưa Gang
    ("FruitApple", "1F34E"),        # Táo
    ("FruitGreenApple", "1F34F"),   # Táo Xanh
    ("FruitBanana", "1F34C"),       # Chuối
    ("FruitPineapple", "1F34D"),    # Dứa, Thơm, Mãng Cầu
    ("FruitPeach", "1F351"),        # Đào, Mận, Mơ
    ("FruitCherry", "1F352"),       # Anh Đào, Sơ Ri
    ("FruitStrawberry", "1F353"),   # Dâu Tây, Chôm Chôm
    ("FruitKiwi", "1F95D"),         # Kiwi
    ("FruitCoconut", "1F965"),      # Dừa
    ("FruitAvocado", "1F951"),      # Bơ
    ("FruitGrape", "1F347"),        # Nho, Nhãn, Vải
    ("FruitBlueberry", "1FAD0"),    # Việt Quất
    ("FruitOlive", "1FAD2"),        # Ô Liu
    # --- Rau củ ---
    ("FruitTomato", "1F345"),       # Cà Chua
    ("FruitChili", "1F336"),        # Ớt
    ("FruitBellPepper", "1FAD1"),   # Ớt Ngọt, Ớt Chuông
    ("FruitCucumber", "1F952"),     # Dưa Leo, Khổ Qua
    ("FruitEggplant", "1F346"),     # Cà Tím
    ("FruitPumpkin", "1F383"),      # Bí Đỏ, Bí Ngô
    ("FruitCorn", "1F33D"),         # Ngô, Bắp
    ("FruitPotato", "1F954"),       # Khoai Tây
    ("FruitSweetPotato", "1F360"),  # Khoai Lang
    ("FruitCarrot", "1F955"),       # Cà Rốt
    ("FruitGarlic", "1F9C4"),       # Tỏi
    ("FruitOnion", "1F9C5"),        # Hành
    ("FruitBroccoli", "1F966"),     # Súp Lơ, Cải
    ("FruitLeafyGreen", "1F96C"),   # Rau ăn lá
    ("FruitMushroom", "1F344"),     # Nấm
    ("FruitChestnut", "1F330"),     # Hạt Dẻ
    ("FruitPeanut", "1F95C"),       # Lạc, Đậu Phộng
    ("FruitRice", "1F33E"),         # Lúa
    ("FruitHerb", "1F33F"),         # Rau Thơm
    ("FruitCoffee", "2615"),        # Cà Phê
    ("FruitSeedling", "1F331"),     # fallback
]


# Bộ icon công việc canh tác (asset name -> openmoji hex code)
WORK_ICONS = [
    ("WorkWater", "1F4A7"),         # Tưới nước
    ("WorkFertilizer", "1F343"),    # Bón phân hữu cơ
    ("WorkLeafFertilizer", "1F33F"),# Phân bón lá
    ("WorkRootFertilizer", "1F955"),# Phân bón gốc
    ("WorkSpray", "1F9F4"),         # Phun thuốc
    ("WorkPesticide", "1F9EA"),     # Thuốc BVTV
    ("WorkBug", "1F41B"),           # Sâu bệnh
    ("WorkDisease", "1F9A0"),       # Nấm bệnh
    ("WorkBind", "1F9F6"),          # Quấn dây
    ("WorkPrune", "2702"),          # Tỉa chồi / cắt tỉa
    ("WorkPollinate", "1F41D"),     # Thụ phấn
    ("WorkHarvest", "1F9FA"),       # Thu hoạch
    ("WorkSeed", "1F331"),          # Gieo hạt
    ("WorkPlant", "1F333"),         # Trồng cây
    ("WorkTractor", "1F69C"),       # Cày đất
    ("WorkDig", "26CF"),            # Xới đất
    ("WorkAxe", "1FA93"),           # Đốn / cắt cành
    ("WorkBroom", "1F9F9"),         # Làm cỏ
    ("WorkSearch", "1F50D"),        # Kiểm tra
    ("WorkNote", "1F4DD"),          # Ghi chép
    ("WorkSell", "1F4B0"),          # Bán nông sản
    ("WorkTruck", "1F69B"),         # Vận chuyển
    ("WorkBox", "1F4E6"),           # Bao trái / Đóng gói
    ("WorkHammer", "1F528"),        # Sửa dụng cụ
    ("WorkGear", "2699"),           # Dụng cụ
    ("WorkSun", "2600"),            # Nắng / Che nắng
    ("WorkRain", "1F327"),          # Mưa
    ("WorkFire", "1F525"),          # Đốt
    ("WorkCalendar", "1F4C5"),      # Lịch
    ("WorkBell", "1F514"),          # Nhắc việc
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


def generate_icon(name: str, code: str) -> bool:
    """Tải icon OpenMoji (thử thêm biến thể -FE0F) và ghi imageset."""
    for cand in (code, code + "-FE0F"):
        try:
            src = Image.open(io.BytesIO(fetch(OPENMOJI.format(cand)))).convert("RGBA")
            make_imageset(name, src)
            return True
        except Exception:  # noqa: BLE001
            continue
    print("FAILED", name, code)
    return False


def main():
    for name, code in FRUITS + WORK_ICONS:
        generate_icon(name, code)

    logo_path = os.path.join(ROOT, "scripts", "afs_logo.png")
    if os.path.exists(logo_path):
        make_logo(Image.open(logo_path))

    make_app_icon()


if __name__ == "__main__":
    main()
