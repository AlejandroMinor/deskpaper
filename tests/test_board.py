import json

import pytest

from conftest import run_cli
from deskpaper import board, paths
from deskpaper.board import BoardError


def sticker(**kw):
    s = {"id": "a1", "kind": "image", "skin": "diecut", "monitor": "DP-2",
         "x": 0.5, "y": 0.5, "props": {"asset": "x.png"}}
    s.update(kw)
    return s


def test_load_missing_is_empty(home):
    assert board.load() == {"version": 1, "stickers": []}


def test_save_roundtrip_fills_defaults(home):
    board.save({"stickers": [sticker()]})
    s = board.load()["stickers"][0]
    assert (s["scale"], s["rotation"], s["z"]) == (1.0, 0, 0)


def test_validate_rejects_bad_kind(home):
    with pytest.raises(BoardError, match="a1"):
        board.validate({"stickers": [sticker(kind="video")]})


def test_validate_rejects_x_out_of_range(home):
    with pytest.raises(BoardError, match="a1"):
        board.validate({"stickers": [sticker(x=1.5)]})


def test_validate_rejects_duplicate_ids(home):
    with pytest.raises(BoardError, match="a1"):
        board.validate({"stickers": [sticker(), sticker()]})


def test_data_sticker_default_interval(home):
    data = board.validate({"stickers": [sticker(kind="data", skin="postit",
                                                props={"source": "events"})]})
    assert data["stickers"][0]["props"]["interval"] == 300


def test_save_keeps_corrupt_file(home):
    home.mkdir(parents=True)
    paths.board().write_text("{oops")
    board.save({"stickers": []})
    assert (home / "board.json.bad").read_text() == "{oops"
    assert board.load() == {"version": 1, "stickers": []}


def test_load_corrupt_raises(home):
    home.mkdir(parents=True)
    paths.board().write_text("{oops")
    with pytest.raises(BoardError):
        board.load()


def test_annotate_flags_missing_asset(home):
    paths.assets().mkdir(parents=True)
    (paths.assets() / "here.png").write_bytes(b"")
    data = board.annotate(board.validate({"stickers": [
        sticker(id="a", props={"asset": "gone.png"}),
        sticker(id="b", props={"asset": "here.png"})]}))
    a, b = data["stickers"]
    assert a["missing"] is True
    assert "missing" not in b


def test_cli_get_corrupt_prints_empty_board(home):
    home.mkdir(parents=True)
    paths.board().write_text("{oops")
    r = run_cli("board", "get")
    assert r.returncode == 1
    assert json.loads(r.stdout) == {"version": 1, "stickers": []}


def test_cli_set_invalid_exits_1(home):
    board.save({"stickers": [sticker()]})
    before = paths.board().read_text()
    r = run_cli("board", "set", stdin=json.dumps({"stickers": [sticker(x=9)]}))
    assert r.returncode == 1
    assert "a1" in r.stderr
    assert paths.board().read_text() == before


def test_cli_set_then_get(home):
    r = run_cli("board", "set", stdin=json.dumps({"stickers": [sticker()]}))
    assert r.returncode == 0, r.stderr
    got = json.loads(run_cli("board", "get").stdout)
    assert got["stickers"][0]["missing"] is True
    assert got["root"] == str(home)


def test_text_sticker_needs_text(home):
    ok = board.validate({"stickers": [sticker(kind="text", skin="ransom", props={"text": "HOLA"})]})
    assert ok["stickers"][0]["props"]["text"] == "HOLA"
    with pytest.raises(BoardError, match="a1"):
        board.validate({"stickers": [sticker(kind="text", skin="ransom", props={})]})


def test_annotate_ignores_text_stickers(home):
    data = board.annotate(board.validate({"stickers": [
        sticker(kind="text", skin="ransom", props={"text": "x"})]}))
    assert "missing" not in data["stickers"][0]


def test_widget_sticker_needs_no_props(home):
    ok = board.validate({"stickers": [sticker(kind="widget", skin="clock", props={})]})
    assert ok["stickers"][0]["kind"] == "widget"
