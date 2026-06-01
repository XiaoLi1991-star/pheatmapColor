from PIL import Image, ImageDraw, ImageFilter
import math
import random
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "articles" / "assets"
OUT.mkdir(parents=True, exist_ok=True)


SCHEMES = {
    "balanced": {
        "low": (33, 102, 172),
        "mid": (247, 247, 247),
        "high": (178, 24, 43),
        "anno": [
            (78, 121, 167),
            (242, 142, 43),
            (89, 161, 79),
            (176, 122, 161),
            (118, 183, 178),
            (237, 201, 72),
        ],
    },
    "soft": {
        "low": (94, 129, 172),
        "mid": (248, 249, 250),
        "high": (191, 97, 106),
        "anno": [
            (107, 143, 179),
            (214, 160, 106),
            (131, 166, 123),
            (181, 138, 165),
            (140, 184, 178),
            (215, 199, 122),
        ],
    },
}


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def diverge(v, scheme):
    v = max(-1, min(1, v))
    if v < 0:
        return lerp(scheme["low"], scheme["mid"], v + 1)
    return lerp(scheme["mid"], scheme["high"], v)


def background(size):
    w, h = size
    img = Image.new("RGB", size, (250, 250, 248))
    draw = ImageDraw.Draw(img, "RGBA")
    for y in range(h):
        t = y / max(1, h - 1)
        c = lerp((252, 253, 253), (237, 242, 244), t)
        draw.line([(0, y), (w, y)], fill=c)
    for i in range(18):
        x = int(w * (i / 17))
        draw.line([(x, 0), (x + int(w * 0.08), h)], fill=(218, 226, 231, 55), width=1)
    return img


def heatmap_values(rows, cols, seed=1):
    random.seed(seed)
    values = []
    for r in range(rows):
        row = []
        for c in range(cols):
            block = 0.0
            if r < rows * 0.36 and c < cols * 0.55:
                block = 0.72
            elif rows * 0.36 <= r < rows * 0.68 and c < cols * 0.46:
                block = -0.65
            elif c > cols * 0.62 and r > rows * 0.55:
                block = 0.42
            noise = random.gauss(0, 0.22)
            wave = 0.13 * math.sin(r * 0.65 + c * 0.35)
            row.append(max(-1, min(1, block + noise + wave)))
        values.append(row)
    return values


def draw_heatmap(draw, box, rows, cols, scheme, seed=1, alpha=255):
    x0, y0, x1, y1 = box
    values = heatmap_values(rows, cols, seed)
    gap = max(1, int((x1 - x0) * 0.002))
    cw = (x1 - x0 - gap * (cols - 1)) / cols
    ch = (y1 - y0 - gap * (rows - 1)) / rows
    for r in range(rows):
        for c in range(cols):
            x = x0 + c * (cw + gap)
            y = y0 + r * (ch + gap)
            color = diverge(values[r][c], scheme)
            draw.rounded_rectangle(
                [x, y, x + cw, y + ch],
                radius=1.5,
                fill=(*color, alpha),
            )


def draw_annotations(draw, box, scheme, cols=18, rows=3):
    x0, y0, x1, y1 = box
    gap = 2
    h = (y1 - y0 - gap * (rows - 1)) / rows
    w = (x1 - x0) / cols
    for rr in range(rows):
        for c in range(cols):
            color = scheme["anno"][(c + rr * 2) % len(scheme["anno"])]
            if rr == 0:
                color = lerp(color, (255, 255, 255), c / max(1, cols - 1) * 0.35)
            draw.rectangle(
                [x0 + c * w, y0 + rr * (h + gap), x0 + (c + 1) * w, y0 + rr * (h + gap) + h],
                fill=(*color, 245),
            )


def draw_tree(draw, origin, width, height, color=(74, 85, 104), alpha=170):
    x0, y0 = origin
    levels = 5
    for i in range(levels):
        y = y0 + height * i / levels
        span = width * (1 - i / (levels + 1))
        draw.line([(x0 + width - span, y), (x0 + width, y)], fill=(*color, alpha), width=2)
        draw.line([(x0 + width - span, y), (x0 + width - span, y + height / levels * 0.65)], fill=(*color, alpha), width=2)


def make_cover():
    w, h = 900, 383
    img = background((w, h))
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")
    scheme = SCHEMES["balanced"]
    card = [84, 52, 816, 332]
    draw.rounded_rectangle(card, radius=26, fill=(255, 255, 255, 210), outline=(215, 225, 232, 150), width=1)
    draw_annotations(draw, (170, 82, 730, 122), scheme, cols=18, rows=3)
    draw_heatmap(draw, (170, 138, 730, 292), 16, 24, scheme, seed=9, alpha=245)
    draw_tree(draw, (112, 138), 42, 154)
    draw_tree(draw, (170, 36), 560, 34, alpha=130)
    for i, color in enumerate(scheme["anno"][:5]):
        draw.rounded_rectangle([758, 146 + i * 28, 790, 166 + i * 28], radius=4, fill=(*color, 235))
    img = Image.alpha_composite(img.convert("RGBA"), overlay)
    img = img.filter(ImageFilter.UnsharpMask(radius=1.1, percent=110, threshold=3))
    out = OUT / "wechat-cover.png"
    img.convert("RGB").save(out, quality=95)
    return out


def make_square():
    w = h = 900
    img = background((w, h))
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")
    scheme = SCHEMES["soft"]
    draw.rounded_rectangle([110, 100, 790, 800], radius=38, fill=(255, 255, 255, 220), outline=(214, 224, 230, 150), width=2)
    draw_annotations(draw, (190, 155, 710, 225), scheme, cols=13, rows=3)
    draw_heatmap(draw, (190, 255, 710, 705), 24, 18, scheme, seed=12, alpha=246)
    draw_tree(draw, (132, 255), 42, 450, alpha=150)
    draw_tree(draw, (190, 112), 520, 38, alpha=125)
    for i, color in enumerate(scheme["anno"][:6]):
        draw.rounded_rectangle([735, 275 + i * 42, 770, 304 + i * 42], radius=5, fill=(*color, 238))
    img = Image.alpha_composite(img.convert("RGBA"), overlay)
    img = img.filter(ImageFilter.UnsharpMask(radius=1.1, percent=110, threshold=3))
    out = OUT / "wechat-square.png"
    img.convert("RGB").save(out, quality=95)
    return out


def make_combo(cover_path, square_path):
    cover = Image.open(cover_path).convert("RGB")
    square = Image.open(square_path).convert("RGB")
    gap = 28
    margin = 36
    w = cover.width + gap + square.width + margin * 2
    h = max(cover.height, square.height) + margin * 2
    img = Image.new("RGB", (w, h), (245, 248, 250))
    img.paste(cover, (margin, margin + (h - 2 * margin - cover.height) // 2))
    img.paste(square, (margin + cover.width + gap, margin))
    out = OUT / "wechat-cover-square-combo.png"
    img.save(out, quality=95)
    return out


if __name__ == "__main__":
    cover = make_cover()
    square = make_square()
    combo = make_combo(cover, square)
    print(cover)
    print(square)
    print(combo)
