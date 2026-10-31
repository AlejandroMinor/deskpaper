"""This month as a grid, with the days that have events (for the calendar)."""
import calendar
from datetime import datetime

from . import events

MONTHS = ("January", "February", "March", "April", "May", "June", "July",
          "August", "September", "October", "November", "December")
DAYS = ["M", "T", "W", "T", "F", "S", "S"]


def _marked(now: datetime, entries: list | None) -> list[int]:
    if entries is None:
        entries = events.combined(now)[0]
    days = set()
    for e in entries if isinstance(entries, list) else []:
        try:
            at, _ = events._parse(e["when"])
        except (KeyError, TypeError, ValueError):
            continue
        if (at.year, at.month) == (now.year, now.month):
            days.add(at.day)
    return sorted(days)


def collect(now: datetime | None = None, entries: list | None = None) -> dict:
    now = now or datetime.now()
    weeks = [[d or None for d in week]
             for week in calendar.Calendar(firstweekday=0).monthdayscalendar(now.year, now.month)]
    return {"title": f"{MONTHS[now.month - 1]} {now.year}", "days": DAYS,
            "weeks": weeks, "today": now.day, "marked": _marked(now, entries)}
