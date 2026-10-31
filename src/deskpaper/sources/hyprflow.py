"""HyprFlow's calendar (the bar's), as event entries for the events and
month sources: ~/.local/share/hyprflow/calendar/YYYY-MM.json, one file per
month, entries {"title", "start", "end", ...}.
"""
import json
import os
from datetime import datetime
from pathlib import Path


def calendar_dir() -> Path:
    env = os.environ.get("HYPRFLOW_CALENDAR_DIR")
    return Path(env) if env else Path.home() / ".local" / "share" / "hyprflow" / "calendar"


def entries(now: datetime | None = None) -> list[dict]:
    """This month's and next month's events, as {"when", "end", "title"}."""
    now = now or datetime.now()
    following = (now.year + now.month // 12, now.month % 12 + 1)
    found = []
    for year, mon in ((now.year, now.month), following):
        try:
            data = json.loads((calendar_dir() / f"{year:04d}-{mon:02d}.json").read_text())
        except (OSError, ValueError):
            continue
        for e in data if isinstance(data, list) else []:
            if isinstance(e, dict) and "start" in e and "title" in e:
                found.append({"when": e["start"], "end": e.get("end"), "title": e["title"]})
    return found
