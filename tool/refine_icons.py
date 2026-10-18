#!/usr/bin/env python3
"""Fix up the three things flutter_launcher_icons does not get right.

Run after `dart run flutter_launcher_icons`:

  1. Maskable web icons. The tool copies the normal icon verbatim, but a
     maskable icon is cropped by the launcher to a circle or squircle, which
     eats roughly 10% off each edge and clips the ring. These are replaced with
     the inset master instead.
  2. The Windows .ico ships a single 256px image, so Explorer and the taskbar
     downscale it badly at 16-32px. A real multi-resolution .ico lets Windows
     pick a properly rendered size.
  3. The favicon is emitted at 16px, which looks soft on any HiDPI screen.

It also generates the Linux icon set, which flutter_launcher_icons does not
handle at all: Flutter's Linux runner ships no icon, so a package needs PNGs in
the freedesktop hicolor layout plus a .desktop entry.

Run from the project root:  python3 tool/refine_icons.py
"""
from pathlib import Path

from PIL import Image

ICO_SIZES = [16, 24, 32, 48, 64, 128, 256]
LINUX_SIZES = [16, 24, 32, 48, 64, 128, 256, 512]
APP_ID = "chronoflux"


def resize(src, size):
    return src.resize((size, size), Image.LANCZOS)


def main():
    full = Image.open("assets/icon/icon.png").convert("RGB")
    maskable = Image.open("assets/icon/icon_maskable.png").convert("RGB")

    for size in (192, 512):
        path = f"web/icons/Icon-maskable-{size}.png"
        resize(maskable, size).save(path)
        print(f"{path}  {size}x{size}  (inset for safe-zone cropping)")

    resize(full, 32).save("web/favicon.png")
    print("web/favicon.png  32x32")

    ico = "windows/runner/resources/app_icon.ico"
    resize(full, 256).save(ico, sizes=[(s, s) for s in ICO_SIZES])
    print(f"{ico}  {ICO_SIZES}")

    for size in LINUX_SIZES:
        d = Path(f"linux/icons/hicolor/{size}x{size}/apps")
        d.mkdir(parents=True, exist_ok=True)
        resize(full, size).save(d / f"{APP_ID}.png")
    print(f"linux/icons/hicolor/*/apps/{APP_ID}.png  {LINUX_SIZES}")

    desktop = Path(f"linux/{APP_ID}.desktop")
    desktop.write_text(
        "[Desktop Entry]\n"
        "Type=Application\n"
        "Name=Chronoflux\n"
        "Comment=A futuristic Pomodoro timer\n"
        f"Exec={APP_ID}\n"
        f"Icon={APP_ID}\n"
        "Terminal=false\n"
        "Categories=Utility;Office;ProjectManagement;\n"
        "Keywords=pomodoro;timer;focus;productivity;\n"
        "StartupWMClass=Chronoflux\n"
    )
    print(f"{desktop}")


if __name__ == "__main__":
    main()
