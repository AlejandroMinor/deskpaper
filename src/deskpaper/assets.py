"""Imported pictures and their die-cut silhouette, made once at import."""
import hashlib
import os
import re
from collections import Counter
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps, UnidentifiedImageError

from . import paths

MAX_SIDE = 1024
BORDER = 12  # die-cut white border, px (provisional)
FLAT_TOL = 28     # how far from the background color still counts as background
FLAT_SHARE = 0.85  # share of the edge that must be that color
LIGHT_MIN = 200    # every channel of a removable background at least this
MAGIC = (1, 254, 3)  # flood-fill marker, a color no picture uses


class AssetError(ValueError):
    pass


def _dilate(mask: Image.Image, radius: int) -> Image.Image:
    # MaxFilter is slow on big kernels: grow in steps of at most 4 px.
    while radius > 0:
        step = min(radius, 4)
        mask = mask.filter(ImageFilter.MaxFilter(2 * step + 1))
        radius -= step
    return mask


def _cut_mask(img: Image.Image, border: int) -> Image.Image:
    w, h = img.size
    has_alpha = img.mode in ("RGBA", "LA") or "transparency" in img.info
    if has_alpha and img.convert("RGBA").getchannel("A").getextrema()[0] < 255:
        alpha = img.convert("RGBA").getchannel("A").point(lambda v: 255 if v > 8 else 0)
        mask = Image.new("L", (w + 2 * border, h + 2 * border), 0)
        mask.paste(alpha, (border, border))
        mask = _dilate(mask, border)
        mask = mask.filter(ImageFilter.GaussianBlur(1.5))
        return mask.point(lambda v: 255 if v >= 128 else 0)
    # No transparency: a rounded card around the whole picture.
    return _card_mask((w + 2 * border, h + 2 * border), border)


def _card_mask(size: tuple, border: int) -> Image.Image:
    """A rounded card the size of the padded picture: the die-cut of a sticker
    with a backing (a color behind the picture)."""
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size[0] - 1, size[1] - 1), radius=int(border * 1.5), fill=255)
    return mask


def _save(img: Image.Image, dest: Path) -> None:
    """Write whole or not at all: a killed write never leaves half a PNG."""
    tmp = dest.with_name(f".{dest.name}.tmp")
    img.save(tmp, format="PNG")
    os.replace(tmp, dest)


def _save_card(sid: str, size: tuple, border: int = BORDER) -> None:
    card = Image.new("RGBA", size, (255, 255, 255, 0))
    card.putalpha(_card_mask(size, border))
    _save(card, paths.assets() / f"{sid}.card.png")


def _info(sid: str) -> dict:
    w, h = Image.open(paths.assets() / f"{sid}.png").size
    if not (paths.assets() / f"{sid}.card.png").is_file():  # imported before cards
        _save_card(sid, (w, h))
    return {"asset": f"{sid}.png", "cut": f"{sid}.cut.png", "card": f"{sid}.card.png",
            "width": w, "height": h}


def _edges(img: Image.Image) -> list:
    w, h = img.size
    px = img.load()
    return ([px[x, 0] for x in range(w)] + [px[x, h - 1] for x in range(w)]
            + [px[0, y] for y in range(h)] + [px[w - 1, y] for y in range(h)])


def _close(a, b, tol: int = FLAT_TOL) -> bool:
    return max(abs(a[i] - b[i]) for i in range(3)) <= tol


def _flat_color(rgb: Image.Image):
    """The background color when the picture's edge is (almost) one color."""
    edges = _edges(rgb)
    common = Counter((r // 16, g // 16, b // 16) for r, g, b in edges).most_common(1)[0][0]
    guess = tuple(c * 16 + 8 for c in common)
    share = sum(_close(e, guess) for e in edges) / len(edges)
    # Only light backgrounds: dark art often touches a dark background.
    return guess if share >= FLAT_SHARE and min(guess) >= LIGHT_MIN else None


def remove_background(img: Image.Image) -> Image.Image | None:
    """Make a flat background transparent, filling in from the edges.

    Returns None when there is nothing to remove: the picture already has
    transparency, or its edge is busy (a photo).
    """
    rgba = img.convert("RGBA")
    alpha = rgba.getchannel("A")
    edge_alpha = _edges(alpha)
    if sum(a < 128 for a in edge_alpha) > len(edge_alpha) / 2:
        return None  # already cut out
    rgb = rgba.convert("RGB")
    bg = _flat_color(rgb)
    if bg is None:
        return None
    w, h = rgb.size
    step = max(1, min(w, h) // 64)
    seeds = ([(x, 0) for x in range(0, w, step)] + [(x, h - 1) for x in range(0, w, step)]
             + [(0, y) for y in range(0, h, step)] + [(w - 1, y) for y in range(0, h, step)])
    px = rgb.load()
    for seed in seeds:
        if px[seed] != MAGIC and _close(px[seed], bg):
            ImageDraw.floodfill(rgb, seed, MAGIC, thresh=FLAT_TOL)
    filled = ImageChops.difference(rgb, Image.new("RGB", rgb.size, MAGIC)).convert("L")
    keep = filled.point(lambda v: 255 if v else 0)
    if sum(keep.histogram()[255:]) < 0.02 * w * h:
        return None  # all background: a plain swatch, keep it whole
    # Shave the halo the old background leaves on the edge.
    keep = keep.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.6))
    rgba.putalpha(ImageChops.darker(alpha, keep))
    return rgba


def _write(sid: str, img: Image.Image, border: int) -> dict:
    mask = _cut_mask(img, border)
    padded = Image.new("RGBA", mask.size, (0, 0, 0, 0))
    padded.paste(img.convert("RGBA"), (border, border))
    cut = Image.new("RGBA", mask.size, (255, 255, 255, 0))
    cut.putalpha(mask)
    out = paths.assets()
    out.mkdir(parents=True, exist_ok=True)
    # Write the cut last: an asset counts as imported only with both files.
    _save(padded, out / f"{sid}.png")
    _save_card(sid, mask.size, border)
    _save(cut, out / f"{sid}.cut.png")
    return _info(sid)


def import_image(src: Path, border: int = BORDER, remove_bg: bool = True) -> dict:
    src = Path(src)
    raw = src.read_bytes()
    sid = hashlib.sha1(raw).hexdigest()[:12]
    out = paths.assets()
    if (out / f"{sid}.png").is_file() and (out / f"{sid}.cut.png").is_file():
        return _info(sid)
    try:
        img = Image.open(src)
        img.load()
    except (UnidentifiedImageError, OSError) as e:
        raise AssetError(f"{src}: not an image") from e
    img = ImageOps.exif_transpose(img)
    img.thumbnail((MAX_SIDE, MAX_SIDE))
    if remove_bg:
        img = remove_background(img) or img
    return _write(sid, img, border)


def recut(asset: str, border: int = BORDER) -> dict:
    """Remove the flat background of an asset imported before, in place.

    `changed` says whether there was one: a photo or a picture already cut
    out is left as it is.
    """
    _check_name(asset)
    img = Image.open(paths.assets() / asset).convert("RGBA")
    img = img.crop(img.getchannel("A").getbbox() or (0, 0, *img.size))
    cut = remove_background(img)
    if cut is None:
        return {**_info(asset.removesuffix(".png")), "changed": False}
    return {**_write(asset.removesuffix(".png"), cut, border), "changed": True}


def list_assets() -> list[dict]:
    d = paths.assets()
    if not d.is_dir():
        return []
    cuts = sorted(d.glob("*.cut.png"), key=lambda p: p.stat().st_mtime, reverse=True)
    return [_info(p.name.removesuffix(".cut.png")) for p in cuts
            if (d / p.name.replace(".cut.png", ".png")).is_file()]


def _check_name(asset: str) -> None:
    if not re.fullmatch(r"[0-9a-f]{12}\.png", asset):
        raise AssetError(f"not an asset name: {asset}")
    if not (paths.assets() / asset).is_file():
        raise AssetError(f"no such asset: {asset}")


def remove(asset: str) -> None:
    """Delete a picture and its die-cut, unless a sticker still uses it."""
    from . import board

    _check_name(asset)
    try:
        stickers = board.load()["stickers"]
    except board.BoardError as e:
        raise AssetError(f"cannot check the board: {e}") from e
    used = sum(1 for s in stickers if s["kind"] == "image" and s["props"]["asset"] == asset)
    if used:
        raise AssetError(f"{asset} is used by {used} sticker(s): remove them first")
    (paths.assets() / asset).unlink()
    (paths.assets() / asset.replace(".png", ".cut.png")).unlink(missing_ok=True)
    (paths.assets() / asset.replace(".png", ".card.png")).unlink(missing_ok=True)
