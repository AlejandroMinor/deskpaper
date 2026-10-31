import json

import pytest
from PIL import Image

from conftest import run_cli
from deskpaper import assets, paths
from deskpaper.assets import AssetError

B = 12


def square_png(path, size=100, inner=40):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    o = (size - inner) // 2
    img.paste((200, 30, 30, 255), (o, o, o + inner, o + inner))
    img.save(path)
    return path


def test_import_png_with_alpha(home, tmp_path):
    info = assets.import_image(square_png(tmp_path / "s.png"), border=B)
    cut = Image.open(paths.assets() / info["cut"])
    assert cut.size == (100 + 2 * B, 100 + 2 * B)
    assert (info["width"], info["height"]) == cut.size
    # Square spans 30..70 in the source, 42..82 once padded.
    assert cut.getpixel((42 - B + 2, 62))[3] == 255
    assert cut.getpixel((62, 42 - B + 2))[:3] == (255, 255, 255)
    assert cut.getpixel((0, 0))[3] == 0
    assert Image.open(paths.assets() / info["asset"]).size == cut.size


def test_import_makes_card(home, tmp_path):
    info = assets.import_image(square_png(tmp_path / "s.png"), border=B)
    card = Image.open(paths.assets() / info["card"])
    assert card.size == (info["width"], info["height"])
    # Filled out to the edges, around the transparent corners of the picture.
    assert card.getpixel((B, B))[3] == 255
    assert card.getpixel((0, 0))[3] == 0


def test_list_makes_missing_card(home, tmp_path):
    info = assets.import_image(square_png(tmp_path / "s.png"))
    (paths.assets() / info["card"]).unlink()
    assert assets.list_assets()[0]["card"] == info["card"]
    assert (paths.assets() / info["card"]).is_file()


def test_import_without_alpha_rounded(home, tmp_path):
    src = tmp_path / "p.jpg"
    Image.new("RGB", (80, 60), (10, 120, 200)).save(src)
    info = assets.import_image(src, border=B)
    cut = Image.open(paths.assets() / info["cut"])
    assert cut.getpixel((0, 0))[3] == 0
    assert cut.getpixel((cut.width // 2, cut.height // 2))[3] == 255


def test_import_downscales(home, tmp_path):
    src = tmp_path / "big.png"
    Image.new("RGB", (3000, 1000), (1, 2, 3)).save(src)
    assert assets.import_image(src, border=B)["width"] == 1024 + 2 * B


def test_import_not_an_image(home, tmp_path):
    src = tmp_path / "notes.txt"
    src.write_text("hello")
    with pytest.raises(AssetError):
        assets.import_image(src)
    assert not paths.assets().exists() or not any(paths.assets().iterdir())


def test_import_twice_same_id(home, tmp_path):
    src = square_png(tmp_path / "s.png")
    a = assets.import_image(src)
    b = assets.import_image(src)
    assert a == b
    assert len(list(paths.assets().iterdir())) == 3  # picture, die-cut, card


def test_list_assets(home, tmp_path):
    info = assets.import_image(square_png(tmp_path / "s.png"))
    assert assets.list_assets() == [info]


def test_cli_import_and_assets(home, tmp_path):
    r = run_cli("import", str(square_png(tmp_path / "s.png")))
    assert r.returncode == 0, r.stderr
    info = json.loads(r.stdout)
    assert json.loads(run_cli("assets").stdout) == [info]
    bad = tmp_path / "x.txt"
    bad.write_text("no")
    r = run_cli("import", str(bad))
    assert r.returncode == 1 and r.stderr


def test_remove_deletes_both_files(home, tmp_path):
    info = assets.import_image(square_png(tmp_path / "s.png"))
    assets.remove(info["asset"])
    assert assets.list_assets() == []
    assert not any(paths.assets().iterdir())


def test_remove_refuses_when_in_use(home, tmp_path):
    from deskpaper import board
    info = assets.import_image(square_png(tmp_path / "s.png"))
    board.save({"stickers": [{"id": "a", "kind": "image", "skin": "diecut", "monitor": "DP-2",
                              "x": 0.5, "y": 0.5, "props": {"asset": info["asset"]}}]})
    with pytest.raises(AssetError, match="1 sticker"):
        assets.remove(info["asset"])
    assert assets.list_assets() == [info]


def test_remove_rejects_paths(home):
    with pytest.raises(AssetError):
        assets.remove("../board.json")


def test_cli_remove(home, tmp_path):
    info = assets.import_image(square_png(tmp_path / "s.png"))
    assert run_cli("remove", info["asset"]).returncode == 0
    assert run_cli("remove", "nope.png").returncode == 1


def flat_bg(path, bg=(255, 255, 255), size=100, inner=40, mode="RGB"):
    img = Image.new(mode, (size, size), bg if mode == "RGB" else bg + (255,))
    o = (size - inner) // 2
    img.paste((20, 20, 160) if mode == "RGB" else (20, 20, 160, 255), (o, o, o + inner, o + inner))
    img.save(path)
    return path


def test_import_removes_flat_white_background(home, tmp_path):
    info = assets.import_image(flat_bg(tmp_path / "w.png"), border=B)
    pic = Image.open(paths.assets() / info["asset"])
    cut = Image.open(paths.assets() / info["cut"])
    assert pic.getpixel((B + 5, B + 5))[3] == 0        # old background is gone
    assert pic.getpixel((62, 62))[3] == 255            # the drawing stays
    assert cut.getpixel((B + 5, B + 5))[3] == 0        # die-cut follows the drawing
    assert cut.getpixel((42 - B + 2, 62))[3] == 255


def test_import_removes_opaque_rgba_background(home, tmp_path):
    info = assets.import_image(flat_bg(tmp_path / "w.png", mode="RGBA"), border=B)
    assert Image.open(paths.assets() / info["asset"]).getpixel((B + 5, B + 5))[3] == 0


def test_import_keeps_busy_background(home, tmp_path):
    import random
    rnd = random.Random(1)
    img = Image.new("RGB", (80, 60))
    img.putdata([(rnd.randrange(256), rnd.randrange(256), rnd.randrange(256)) for _ in range(80 * 60)])
    img.save(tmp_path / "photo.png")
    info = assets.import_image(tmp_path / "photo.png", border=B)
    assert Image.open(paths.assets() / info["asset"]).getpixel((B + 5, B + 5))[3] == 255


def test_import_keep_background_flag(home, tmp_path):
    info = assets.import_image(flat_bg(tmp_path / "w.png"), border=B, remove_bg=False)
    assert Image.open(paths.assets() / info["asset"]).getpixel((B + 5, B + 5))[3] == 255


def test_recut_removes_background_of_old_import(home, tmp_path):
    info = assets.import_image(flat_bg(tmp_path / "w.png"), border=B, remove_bg=False)
    again = assets.recut(info["asset"], border=B)
    assert again["asset"] == info["asset"] and again["changed"]
    assert Image.open(paths.assets() / info["asset"]).getpixel((B + 5, B + 5))[3] == 0
    assert Image.open(paths.assets() / info["cut"]).getpixel((B + 5, B + 5))[3] == 0


def test_recut_leaves_a_cut_out_picture(home, tmp_path):
    info = assets.import_image(square_png(tmp_path / "s.png"), border=B)
    before = (paths.assets() / info["asset"]).read_bytes()
    assert assets.recut(info["asset"], border=B)["changed"] is False
    assert (paths.assets() / info["asset"]).read_bytes() == before


def test_writes_leave_no_temp_files(home, tmp_path):
    assets.import_image(square_png(tmp_path / "s.png"))
    assert not [p for p in paths.assets().iterdir() if p.name.startswith(".")]


def test_cli_recut(home, tmp_path):
    info = assets.import_image(flat_bg(tmp_path / "w.png"), remove_bg=False)
    assert run_cli("recut", info["asset"]).returncode == 0
    assert run_cli("recut", "../x.png").returncode == 1


def test_import_removes_white_background_with_stray_transparency(home, tmp_path):
    path = flat_bg(tmp_path / "w.png", mode="RGBA")
    img = Image.open(path)
    img.putpixel((50, 50), (0, 0, 0, 0))  # one hole inside the drawing
    img.save(path)
    info = assets.import_image(path, border=B)
    assert Image.open(paths.assets() / info["asset"]).getpixel((B + 5, B + 5))[3] == 0


def test_import_keeps_dark_background(home, tmp_path):
    # Dark art often touches a dark background: removing it eats the drawing.
    info = assets.import_image(flat_bg(tmp_path / "k.png", bg=(5, 5, 5)), border=B)
    assert Image.open(paths.assets() / info["asset"]).getpixel((B + 5, B + 5))[3] == 255
