#!/usr/bin/env python3
"""Render the Chronoflux app icon masters into assets/icon/.

The mark is the app's own progress ring: a thick cyan-to-blue arc with a lit
head, over the same deep navy the interface uses. It is drawn deliberately
bold — a thin ring with tick marks would look right at 1024px and turn to mush
at the 16px favicon size, so the detail is spent on stroke weight and contrast
instead.

Outputs (all 1024x1024):
  icon.png             full-bleed, for iOS / Windows / web
  icon_macos.png       padded rounded tile, per Apple's macOS icon grid
  icon_maskable.png    inset mark, for web maskable icons (cropped to a circle)
  icon_ios_dark.png    transparent mark, for the iOS 18 dark / tinted variants
  icon_foreground.png  transparent, mark inset to Android's adaptive safe zone
  icon_monochrome.png  transparent white mark, for Android 13 themed icons

Run from the project root:  python3 tool/generate_icon.py
"""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
SS = 4                      # supersample factor; downscaled with LANCZOS
S = SIZE * SS

NAVY = (4, 6, 15)           # matches NeonSurfaces.canvas
GLOW_BG = (14, 44, 96)      # cool bloom behind the ring
CYAN = (34, 225, 255)       # PhasePalette.focus.start
BLUE = (76, 107, 255)       # PhasePalette.focus.end

# Geometry as fractions of the canvas. The gap is centred on twelve o'clock
# so the ring reads as a symmetric, nearly-complete gauge; an off-centre gap
# made the mark look like a spiral rather than a ring.
RING_DIAMETER = 0.70
STROKE = 0.122
GAP_DEG = 54.0
START_DEG = -90.0 + GAP_DEG / 2.0
SWEEP_DEG = 360.0 - GAP_DEG

# macOS icons sit in a rounded tile with padding rather than filling the
# square, per Apple's icon grid.
MACOS_TILE = 0.805
MACOS_RADIUS = 0.225        # of the tile


def background():
    """Deep navy with a soft radial bloom, sitting slightly above centre."""
    y, x = np.mgrid[0:S, 0:S]
    cx, cy = S / 2.0, S * 0.46
    r = np.sqrt((x - cx) ** 2 + (y - cy) ** 2) / (S * 0.60)
    t = np.clip(1.0 - r, 0.0, 1.0) ** 1.7

    base = np.array(NAVY, dtype=float)
    glow = np.array(GLOW_BG, dtype=float)
    img = base[None, None, :] + (glow - base)[None, None, :] * t[:, :, None]
    return Image.fromarray(img.astype("uint8"))


def draw_ring(scale=1.0, mono=False):
    """The arc on its own transparent layer, plus a separate blurred glow."""
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    diameter = S * RING_DIAMETER * scale
    stroke = int(S * STROKE * scale)
    cx = cy = S / 2.0
    r = diameter / 2.0
    box = [cx - r, cy - r, cx + r, cy + r]

    # Many overlapping short arcs approximate a gradient stroke; PIL has no
    # sweep gradient of its own.
    steps = 400
    for i in range(steps):
        f = i / (steps - 1)
        a0 = START_DEG + SWEEP_DEG * (i / steps)
        a1 = START_DEG + SWEEP_DEG * ((i + 1) / steps) + 0.5
        if mono:
            col = (255, 255, 255, 255)
        else:
            col = tuple(
                int(CYAN[k] + (BLUE[k] - CYAN[k]) * f) for k in range(3)
            ) + (255,)
        d.arc(box, a0, a1, fill=col, width=stroke)

    # Round the ends; PIL's arc leaves them square. Note the stroke is drawn
    # *inward* from the bounding box, so the caps centre on r - stroke/2 —
    # centring them on r makes them bulge past the ring as little ears.
    centreline = r - stroke / 2.0
    for angle, colour in (
        (START_DEG, CYAN),
        (START_DEG + SWEEP_DEG, BLUE),
    ):
        rad = np.radians(angle)
        ex = cx + centreline * np.cos(rad)
        ey = cy + centreline * np.sin(rad)
        h = stroke / 2.0
        fill = (255, 255, 255, 255) if mono else colour + (255,)
        d.ellipse([ex - h, ey - h, ex + h, ey + h], fill=fill)

    # The lit head riding the leading edge, as on the running timer.
    rad = np.radians(START_DEG + SWEEP_DEG)
    hx = cx + centreline * np.cos(rad)
    hy = cy + centreline * np.sin(rad)
    hr = stroke * 0.30
    d.ellipse([hx - hr, hy - hr, hx + hr, hy + hr], fill=(255, 255, 255, 255))

    if mono:
        return layer, None

    # Glow: the ring's own silhouette, blurred and tinted.
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    glow.paste((34, 225, 255, 190), mask=layer.split()[3])
    glow = glow.filter(ImageFilter.GaussianBlur(S * 0.022))
    return layer, glow


def finish(img):
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def build_full_bleed():
    bg = background().convert("RGBA")
    ring, glow = draw_ring(scale=1.0)
    bg.alpha_composite(glow)
    bg.alpha_composite(ring)
    return finish(bg).convert("RGB")


def build_macos():
    """Rounded tile with padding, the way macOS app icons are drawn."""
    tile_px = S * MACOS_TILE
    off = (S - tile_px) / 2.0
    radius = tile_px * MACOS_RADIUS

    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [off, off, off + tile_px, off + tile_px], radius=radius, fill=255
    )

    plate = background().convert("RGBA")
    ring, glow = draw_ring(scale=MACOS_TILE)
    plate.alpha_composite(glow)
    plate.alpha_composite(ring)

    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    out.paste(plate, (0, 0), mask)
    return finish(out)


def build_web_maskable():
    """Maskable icons get cropped to a circle, so the mark is inset."""
    bg = background().convert("RGBA")
    ring, glow = draw_ring(scale=0.62)
    bg.alpha_composite(glow)
    bg.alpha_composite(ring)
    return finish(bg).convert("RGB")


def build_ios_dark():
    """iOS 18 dark variant: Apple composites it over a dark system plate, so
    the mark ships on transparency rather than on our own navy."""
    canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ring, glow = draw_ring(scale=1.0)
    canvas.alpha_composite(glow)
    canvas.alpha_composite(ring)
    return finish(canvas)


def build_foreground():
    """Android adaptive icons crop to the inner ~66%, so the mark is inset."""
    canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ring, glow = draw_ring(scale=0.60)
    canvas.alpha_composite(glow)
    canvas.alpha_composite(ring)
    return finish(canvas)


def build_monochrome():
    canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ring, _ = draw_ring(scale=0.60, mono=True)
    canvas.alpha_composite(ring)
    return finish(canvas)


if __name__ == "__main__":
    out = {
        "assets/icon/icon.png": build_full_bleed(),
        "assets/icon/icon_macos.png": build_macos(),
        "assets/icon/icon_maskable.png": build_web_maskable(),
        "assets/icon/icon_ios_dark.png": build_ios_dark(),
        "assets/icon/icon_foreground.png": build_foreground(),
        "assets/icon/icon_monochrome.png": build_monochrome(),
    }
    for path, img in out.items():
        img.save(path)
        print(f"{path}  {img.size[0]}x{img.size[1]}  {img.mode}")
