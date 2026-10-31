import json
from datetime import datetime

from deskpaper import paths
from deskpaper.sources import month

NOW = datetime(2026, 10, 24, 9, 0)


def test_month_grid_starts_monday(home):
    out = month.collect(now=NOW)
    assert out["title"] == "October 2026"
    assert out["days"] == ["M", "T", "W", "T", "F", "S", "S"]
    # 1 Oct 2026 is a Thursday: three blanks first.
    assert out["weeks"][0] == [None, None, None, 1, 2, 3, 4]
    assert out["weeks"][-1][-1] in (None, 31)
    assert out["today"] == 24


def test_month_marks_days_with_events(home):
    paths.data().mkdir(parents=True)
    (paths.data() / "events.json").write_text(json.dumps([
        {"when": "2026-10-30T10:00", "title": "a"},
        {"when": "2026-11-02", "title": "next month"},
        {"when": "2026-10-03", "title": "past"}]))
    assert month.collect(now=NOW)["marked"] == [3, 30]


def test_month_in_registry():
    from deskpaper.sources import REGISTRY
    assert "month" in REGISTRY
