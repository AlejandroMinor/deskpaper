import json
import os

from conftest import run_cli
from deskpaper import wallpapers

QUERY = """: HDMI-A-1: 1080x1920, scale: 1, currently displaying: image: /w/a b.png
: DP-2: 2560x1440, scale: 1, currently displaying: color: 000000
"""


def fake_daemon(tmp_path, monkeypatch, name="awww", out=QUERY, code=0):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir(exist_ok=True)
    f = bin_dir / name
    f.write_text(f"#!/bin/sh\n/usr/bin/cat <<'X'\n{out}X\nexit {code}\n")
    f.chmod(0o755)
    monkeypatch.setenv("PATH", str(bin_dir))


def test_parse_query():
    assert wallpapers.parse(QUERY) == {"HDMI-A-1": "/w/a b.png"}


def test_current_uses_awww(tmp_path, monkeypatch):
    fake_daemon(tmp_path, monkeypatch)
    assert wallpapers.current() == {"HDMI-A-1": "/w/a b.png"}


def test_current_falls_back_to_swww(tmp_path, monkeypatch):
    fake_daemon(tmp_path, monkeypatch, name="swww")
    assert wallpapers.current() == {"HDMI-A-1": "/w/a b.png"}


def test_current_without_daemon(tmp_path, monkeypatch):
    monkeypatch.setenv("PATH", str(tmp_path))
    assert wallpapers.current() == {}


def test_cli_wallpapers(home, tmp_path, monkeypatch):
    fake_daemon(tmp_path, monkeypatch)
    r = run_cli("wallpapers")
    assert r.returncode == 0
    assert json.loads(r.stdout) == {"HDMI-A-1": "/w/a b.png"}
