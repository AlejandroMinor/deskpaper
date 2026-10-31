"""Static checks of the QML side (no Quickshell is started)."""
import re
import shutil
import subprocess
from pathlib import Path

import pytest

from conftest import ROOT

QML = ROOT / "qml"
QT6_QMLLINT = Path("/usr/lib/qt6/bin/qmllint")
SKINS = ("Diecut", "Holo", "Stamp", "Polaroid", "Postit", "Ticket", "Calendar", "News", "Ransom", "Clock", "Tape")


def read(rel):
    return (QML / rel).read_text()


@pytest.mark.parametrize("skin", SKINS)
def test_skin_interface(skin):
    text = read(f"skins/{skin}.qml")
    assert "property var sticker" in text
    assert "property var payload" in text
    # `data` is Item's default property: shadowing it breaks the children.
    assert "property var data" not in text


def test_desktop_layer_is_bottom_and_click_through():
    text = read("DesktopLayer.qml")
    assert "WlrLayer.Bottom" in text
    assert 'namespace: "deskpaper"' in text
    assert "mask: Region {}" in text


def test_qml_never_writes_files():
    for f in QML.rglob("*.qml"):
        assert not re.search(r"\bsetText\(|writeAdapter|\bwriteFile", f.read_text()), f


def test_singletons_have_clean_pragma():
    for f in (QML / "services").glob("*.qml"):
        text = f.read_text()
        if "pragma Singleton" in text:
            assert "{" not in text.split("pragma Singleton")[0], f


def test_qmllint_syntax():
    # /usr/bin/qmllint may be Qt 5's, which prints nothing.
    lint = QT6_QMLLINT if QT6_QMLLINT.exists() else shutil.which("qmllint")
    if not lint:
        pytest.skip("qmllint not installed")
    files = [str(f) for f in QML.rglob("*.qml")]
    r = subprocess.run([str(lint), "-I", str(QML), *files], capture_output=True, text=True)
    errors = [line for line in (r.stdout + r.stderr).splitlines()
              if line.startswith("Error") or "[syntax]" in line
              or "[duplicate-property-binding]" in line]
    assert not errors, "\n".join(errors)


def test_editor_draws_with_sticker_view():
    canvas = read("editor/EditorCanvas.qml")
    assert "StickerView {" in canvas
    assert "skins/" not in canvas


def test_editor_saves_through_cli():
    text = read("Editor.qml")
    assert '["board", "set"]' in text


def test_editor_ipc_has_no_show():
    text = read("Editor.qml")
    assert 'target: "editor"' in text
    assert "function show(" not in text


def test_shell_loads_editor_and_layer():
    text = read("shell.qml")
    assert "DesktopLayer {}" in text and "Editor {}" in text


def test_fonts_ship_with_licenses():
    fonts = QML / "fonts"
    for ttf, lic in (("PermanentMarker-Regular.ttf", "PermanentMarker-LICENSE.txt"),
                     ("Caveat.ttf", "Caveat-OFL.txt"),
                     ("SpecialElite-Regular.ttf", "SpecialElite-LICENSE.txt"),
                     ("UnifrakturMaguntia.ttf", "UnifrakturMaguntia-OFL.txt")):
        assert (fonts / ttf).is_file() and (fonts / lic).is_file()
        assert ttf in read("services/Look.qml")


def test_skin_lists_match_files():
    look = read("services/Look.qml")
    names = re.findall(r'"(\w+)"', look.split("imageSkins:")[1].split("\n")[0])
    for name in names:
        assert (QML / "skins" / f"{name.capitalize()}.qml").is_file(), name


def test_editor_edits_go_through_set_draft():
    # One undo step per edit: only setDraft, undo, redo, the snap back and
    # opening the editor assign the draft.
    text = read("Editor.qml")
    assignments = re.findall(r"^\s*draft = (.+)$", text, re.M)
    assert len(assignments) == 5, assignments
    assert "Qt.Key_Z" in text and "Qt.Key_D" in text
