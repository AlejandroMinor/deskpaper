"""Backup: the whole data dir in one .tar.gz, to move it between machines."""
import json
import os
import shutil
import tarfile
import tempfile
from datetime import datetime
from pathlib import Path, PurePosixPath

from . import board, paths

PARTS = ("board.json", "assets", "data")


class BackupError(ValueError):
    pass


def export(dest: Path) -> Path:
    dest = Path(dest)
    root = paths.root()
    with tarfile.open(dest, "w:gz") as t:
        for part in PARTS:
            if (root / part).exists():
                t.add(root / part, arcname=part)
    return dest


def _check_members(t: tarfile.TarFile) -> None:
    for m in t.getmembers():
        p = PurePosixPath(m.name)
        if p.is_absolute() or ".." in p.parts or not (m.isfile() or m.isdir()):
            raise BackupError(f"unsafe entry in backup: {m.name}")


def restore(src: Path, replace: bool = False) -> None:
    root = paths.root()
    if paths.board().exists() and not replace:
        raise BackupError(f"{root} already has a board (use --replace)")
    root.parent.mkdir(parents=True, exist_ok=True)
    staging = Path(tempfile.mkdtemp(dir=root.parent, prefix=".deskpaper-restore-"))
    try:
        with tarfile.open(src, "r:gz") as t:
            _check_members(t)
            t.extractall(staging, filter="data")
        try:
            board.validate(json.loads((staging / "board.json").read_text()))
        except (OSError, json.JSONDecodeError, board.BoardError) as e:
            raise BackupError(f"backup has no valid board.json: {e}") from e
        if root.exists():
            stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
            os.replace(root, root.with_name(f"{root.name}.old-{stamp}"))
        os.replace(staging, root)
    except (tarfile.TarError, OSError) as e:
        raise BackupError(f"cannot restore {src}: {e}") from e
    finally:
        shutil.rmtree(staging, ignore_errors=True)
