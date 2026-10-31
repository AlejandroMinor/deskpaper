import io
import tarfile

import pytest

from deskpaper import backup, board, paths
from deskpaper.backup import BackupError


def fill():
    board.save({"stickers": [{"id": "a", "kind": "image", "skin": "diecut",
                              "monitor": "DP-2", "x": 0.2, "y": 0.3,
                              "props": {"asset": "p.png"}}]})
    paths.assets().mkdir()
    (paths.assets() / "p.png").write_bytes(b"png")
    paths.data().mkdir()
    (paths.data() / "events.json").write_text("[]")


def test_export_restore_roundtrip(home, tmp_path):
    fill()
    archive = backup.export(tmp_path / "b.tar.gz")
    expected = board.load()
    import shutil
    shutil.rmtree(home)
    backup.restore(archive)
    assert board.load() == expected
    assert (paths.assets() / "p.png").read_bytes() == b"png"
    assert (paths.data() / "events.json").read_text() == "[]"


def test_restore_refuses_without_replace(home, tmp_path):
    fill()
    archive = backup.export(tmp_path / "b.tar.gz")
    with pytest.raises(BackupError):
        backup.restore(archive)


def test_restore_replace_keeps_old(home, tmp_path):
    fill()
    archive = backup.export(tmp_path / "b.tar.gz")
    (paths.data() / "marker").write_text("old")
    backup.restore(archive, replace=True)
    olds = list(home.parent.glob("deskpaper.old-*"))
    assert len(olds) == 1 and (olds[0] / "data" / "marker").read_text() == "old"
    assert not (paths.data() / "marker").exists()


def _tar(path, members):
    with tarfile.open(path, "w:gz") as t:
        for name, data in members.items():
            info = tarfile.TarInfo(name)
            info.size = len(data)
            t.addfile(info, io.BytesIO(data))
    return path


def test_restore_rejects_path_traversal(home, tmp_path):
    bad = _tar(tmp_path / "bad.tar.gz", {"board.json": b'{"stickers": []}',
                                         "../evil": b"x"})
    with pytest.raises(BackupError):
        backup.restore(bad)
    assert not (tmp_path / "evil").exists()
    assert not home.exists()


def test_restore_rejects_invalid_board(home, tmp_path):
    fill()
    before = paths.board().read_text()
    bad = _tar(tmp_path / "bad.tar.gz", {"board.json": b'{"stickers": [{"id": 1}]}'})
    with pytest.raises(BackupError):
        backup.restore(bad, replace=True)
    assert paths.board().read_text() == before
