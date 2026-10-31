import os
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))
BIN = ROOT / "deskpaper"


@pytest.fixture(autouse=True)
def no_hyprflow(tmp_path, monkeypatch):
    # Keep the real HyprFlow calendar out of every test.
    monkeypatch.setenv("HYPRFLOW_CALENDAR_DIR", str(tmp_path / "no-hyprflow"))


@pytest.fixture
def home(tmp_path, monkeypatch):
    d = tmp_path / "deskpaper"
    monkeypatch.setenv("DESKPAPER_DIR", str(d))
    return d


def run_cli(*args, stdin=None):
    return subprocess.run([sys.executable, str(BIN), *args], input=stdin,
                          capture_output=True, text=True, env=os.environ.copy())
