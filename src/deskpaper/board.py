"""Repository for board.json: the stickers and where they sit."""
import json
import os
import tempfile

from . import paths

VERSION = 1
KINDS = ("image", "data", "text", "widget")  # widget: draws itself, needs no props
DEFAULTS = {"scale": 1.0, "rotation": 0, "z": 0}
DEFAULT_INTERVAL = 300


class BoardError(ValueError):
    pass


def empty() -> dict:
    return {"version": VERSION, "stickers": []}


def load() -> dict:
    try:
        text = paths.board().read_text()
    except FileNotFoundError:
        return empty()
    try:
        return validate(json.loads(text))
    except (json.JSONDecodeError, BoardError) as e:
        raise BoardError(f"{paths.board()} is corrupt: {e}") from e


def _number(s: dict, key: str, lo=None, hi=None) -> float:
    v = s.get(key)
    if isinstance(v, bool) or not isinstance(v, (int, float)):
        raise BoardError(f"sticker {s.get('id')}: {key} must be a number")
    if (lo is not None and v < lo) or (hi is not None and v > hi):
        raise BoardError(f"sticker {s.get('id')}: {key} out of range")
    return v


def _sticker(s) -> dict:
    if not isinstance(s, dict) or not isinstance(s.get("id"), str) or not s["id"]:
        raise BoardError(f"sticker without id: {s!r}")
    sid = s["id"]
    if s.get("kind") not in KINDS:
        raise BoardError(f"sticker {sid}: kind must be one of {KINDS}")
    for key in ("skin", "monitor"):
        if not isinstance(s.get(key), str) or not s[key]:
            raise BoardError(f"sticker {sid}: {key} is required")
    out = {**DEFAULTS, **s}
    out["x"] = _number(out, "x", 0, 1)
    out["y"] = _number(out, "y", 0, 1)
    out["scale"] = _number(out, "scale", 0.05, 20)
    out["rotation"] = _number(out, "rotation")
    out["z"] = int(_number(out, "z"))
    props = dict(out.get("props") or {})
    if out["kind"] == "image" and not isinstance(props.get("asset"), str):
        raise BoardError(f"sticker {sid}: props.asset is required")
    if out["kind"] == "text" and not (isinstance(props.get("text"), str) and props["text"]):
        raise BoardError(f"sticker {sid}: props.text is required")
    if out["kind"] == "data":
        if not isinstance(props.get("source"), str):
            raise BoardError(f"sticker {sid}: props.source is required")
        props.setdefault("interval", DEFAULT_INTERVAL)
    out["props"] = props
    out.pop("missing", None)
    return out


def validate(data) -> dict:
    if not isinstance(data, dict) or not isinstance(data.get("stickers", []), list):
        raise BoardError("board must be an object with a stickers list")
    stickers = [_sticker(s) for s in data.get("stickers", [])]
    seen = set()
    for s in stickers:
        if s["id"] in seen:
            raise BoardError(f"sticker {s['id']}: duplicate id")
        seen.add(s["id"])
    return {"version": VERSION, "stickers": stickers}


def save(data: dict) -> None:
    clean = validate(data)
    target = paths.board()
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        try:
            json.loads(target.read_text())
        except json.JSONDecodeError:
            os.replace(target, target.with_name("board.json.bad"))
    fd, tmp = tempfile.mkstemp(dir=target.parent, prefix=".board-")
    with os.fdopen(fd, "w") as f:
        json.dump(clean, f, indent=2)
    os.replace(tmp, target)


def annotate(data: dict) -> dict:
    out = []
    for s in data["stickers"]:
        s = dict(s)
        if s["kind"] == "image" and not (paths.assets() / s["props"]["asset"]).is_file():
            s["missing"] = True
        out.append(s)
    return {**data, "stickers": out}
