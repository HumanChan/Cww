#!/usr/bin/env python3
"""Generate platform icon assets from the approved MoYuStock brand mark."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageOps


ROOT = Path(__file__).resolve().parents[1]
BRAND_DIR = ROOT / "assets" / "branding"
SOURCE_PATH = BRAND_DIR / "app_icon_source.png"
MARK_PATH = BRAND_DIR / "app_icon_mark.png"
MASTER_PATH = BRAND_DIR / "app_icon_master.png"


def _extract_foreground(source: Image.Image) -> Image.Image:
    """Build the adaptive foreground from the bright cyan emblem.

    The generated master already has the approved navy backdrop. Android uses
    the same navy as its adaptive background, so keeping a faint part of the
    emblem aura produces a seamless result while the dark field stays clear.
    """
    foreground = source.convert("RGBA")
    red, green, blue, _ = foreground.split()
    intensity = ImageChops.lighter(red, ImageChops.lighter(green, blue))
    alpha = intensity.point(
        lambda value: max(0, min(255, round((value - 58) * 2.55))),
    )
    foreground.putalpha(alpha)
    return foreground


def _save_resized(image: Image.Image, path: Path, size: int, *, rgb: bool = True) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    resized = image.resize((size, size), Image.Resampling.LANCZOS)
    if rgb:
        resized = resized.convert("RGB")
    resized.save(path, format="PNG", optimize=True)


def main() -> None:
    source = Image.open(SOURCE_PATH).convert("RGB")
    master = ImageOps.fit(
        source,
        (1024, 1024),
        method=Image.Resampling.LANCZOS,
    )
    foreground = _extract_foreground(master)
    MASTER_PATH.parent.mkdir(parents=True, exist_ok=True)
    master.save(MASTER_PATH, format="PNG", optimize=True)
    foreground.save(MARK_PATH, format="PNG", optimize=True)
    foreground.save(BRAND_DIR / "app_icon_foreground.png", format="PNG", optimize=True)

    ios_dir = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for filename, size in ios_sizes.items():
        _save_resized(master, ios_dir / filename, size)

    android_sizes = {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }
    adaptive_sizes = {
        "mdpi": 108,
        "hdpi": 162,
        "xhdpi": 216,
        "xxhdpi": 324,
        "xxxhdpi": 432,
    }
    for density, size in android_sizes.items():
        directory = ROOT / "android" / "app" / "src" / "main" / "res" / f"mipmap-{density}"
        _save_resized(master, directory / "ic_launcher.png", size)
    for density, size in adaptive_sizes.items():
        directory = ROOT / "android" / "app" / "src" / "main" / "res" / f"mipmap-{density}"
        _save_resized(foreground, directory / "ic_launcher_foreground.png", size, rgb=False)

    web_dir = ROOT / "web"
    _save_resized(master, web_dir / "icons" / "Icon-192.png", 192)
    _save_resized(master, web_dir / "icons" / "Icon-512.png", 512)
    _save_resized(master, web_dir / "icons" / "Icon-maskable-192.png", 192)
    _save_resized(master, web_dir / "icons" / "Icon-maskable-512.png", 512)
    _save_resized(master, web_dir / "favicon.png", 32)


if __name__ == "__main__":
    main()
