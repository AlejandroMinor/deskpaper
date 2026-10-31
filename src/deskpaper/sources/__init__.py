"""Data sources: each one returns a dict in a fixed shape for its skin.

A new source is a module here plus one line in REGISTRY.
"""
from . import events, month

REGISTRY = {
    "events": events.collect,  # data/events.json and HyprFlow's calendar
    "month": month.collect,
    # Older names, kept for stickers placed with them.
    "hyprflow-events": events.collect,
    "hyprflow-month": month.collect,
}
