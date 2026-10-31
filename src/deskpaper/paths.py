"""Single place for every file location."""
import os
from pathlib import Path


def root() -> Path:
    env = os.environ.get("DESKPAPER_DIR")
    return Path(env) if env else Path.home() / ".config" / "deskpaper"


def board() -> Path:
    return root() / "board.json"


def assets() -> Path:
    return root() / "assets"


def data() -> Path:
    return root() / "data"


def qml() -> Path:
    return Path(__file__).resolve().parents[2] / "qml"
