"""Upcoming events from data/events.json (or .yml / .yaml) and HyprFlow's
calendar, together. Either one may be missing.

File: [{"when": "2026-10-30T10:00" | "2026-10-31", "end"?: "...", "title": "..."}]
Out:  {"items": [{"when", "label", "title"}], "error": str | None}
"""
import json
from datetime import date, datetime, timedelta

from .. import paths
from . import hyprflow

DAYS = ("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
MONTHS = ("Jan", "Feb", "Mar", "Apr", "May", "Jun",
          "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
NAMES = ("events.json", "events.yml", "events.yaml")


def _read():
    for name in NAMES:
        f = paths.data() / name
        if f.is_file():
            text = f.read_text()
            if name.endswith(".json"):
                return json.loads(text)
            import yaml
            return yaml.safe_load(text)
    return None


def combined(now: datetime | None = None) -> tuple[list, str | None]:
    """The events file's entries plus HyprFlow's, and what went wrong reading the file."""
    found, error = hyprflow.entries(now=now), None
    try:
        own = _read()
    except Exception as e:  # OSError, ValueError, ImportError, yaml.YAMLError
        own, error = None, f"cannot read events: {e}"
    if own is not None:
        if isinstance(own, list):
            found = own + found
        else:
            error = "events file must be a list"
    return found, error


def _parse(when):
    """Return (datetime, all_day)."""
    if isinstance(when, datetime):  # YAML parses unquoted dates itself
        return (when.astimezone().replace(tzinfo=None) if when.tzinfo else when), False
    if isinstance(when, date):
        return datetime(when.year, when.month, when.day), True
    when = str(when)
    all_day = "T" not in when and " " not in when
    at = datetime.fromisoformat(when)
    if at.tzinfo:  # compare in local time, like `now`
        at = at.astimezone().replace(tzinfo=None)
    return at, all_day


def _label(at: datetime, all_day: bool, now: datetime) -> str:
    days = (at.date() - now.date()).days
    if days == 0:
        day = "Today"
    elif days == 1:
        day = "Tomorrow"
    elif days < 7:
        day = DAYS[at.weekday()]
    else:
        return f"{MONTHS[at.month - 1]} {at.day}"
    return day if all_day else f"{day} {at:%H:%M}"


def collect(now: datetime | None = None, limit: int = 5, entries: list | None = None) -> dict:
    now = now or datetime.now()
    error = None
    if entries is None:
        entries, error = combined(now)
    found, bad = [], []
    for e in entries:
        try:
            at, all_day = _parse(e["when"])
            end = _parse(e["end"])[0] if e.get("end") else None
            title = str(e["title"])
        except (KeyError, TypeError, ValueError):
            bad.append(str(e.get("title", "?")) if isinstance(e, dict) else "?")
            continue
        if end is not None:
            ended = end <= now
        else:
            ended = at.date() < now.date() if all_day else at < now
        if not ended:
            found.append((at, all_day, title))
    found.sort(key=lambda t: t[0])
    items = [{"when": at.isoformat(), "label": _label(at, all_day, now), "title": title}
             for at, all_day, title in found[:limit]]
    if bad:
        error = f"bad date in: {', '.join(bad)}"
    return {"items": items, "error": error}
