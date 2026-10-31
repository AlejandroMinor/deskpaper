import json
from datetime import datetime

from deskpaper import paths
from deskpaper.sources import REGISTRY, events, hyprflow, month

NOW = datetime(2026, 10, 24, 9, 0)


def calendar(tmp_path, monkeypatch, months):
    d = tmp_path / "calendar"
    d.mkdir()
    for name, entries in months.items():
        (d / f"{name}.json").write_text(json.dumps(entries))
    monkeypatch.setenv("HYPRFLOW_CALENDAR_DIR", str(d))
    return d


def test_entries_map_start_to_when(tmp_path, monkeypatch):
    calendar(tmp_path, monkeypatch, {"2026-10": [
        {"title": "Talk", "start": "2026-10-30T10:00", "end": "2026-10-30T11:00", "where": "", "link": ""}]})
    assert hyprflow.entries(now=NOW) == [{"when": "2026-10-30T10:00", "end": "2026-10-30T11:00", "title": "Talk"}]


def test_entries_read_this_and_next_month(tmp_path, monkeypatch):
    calendar(tmp_path, monkeypatch, {
        "2026-10": [{"title": "a", "start": "2026-10-30T10:00", "end": "2026-10-30T11:00"}],
        "2026-11": [{"title": "b", "start": "2026-11-02T10:00", "end": "2026-11-02T11:00"}],
        "2026-09": [{"title": "old", "start": "2026-09-02T10:00", "end": "2026-09-02T11:00"}]})
    assert [e["title"] for e in hyprflow.entries(now=NOW)] == ["a", "b"]


def test_entries_missing_dir(tmp_path, monkeypatch):
    monkeypatch.setenv("HYPRFLOW_CALENDAR_DIR", str(tmp_path / "nope"))
    assert hyprflow.entries(now=NOW) == []


def test_event_in_progress_is_kept(home):
    out = events.collect(now=NOW, entries=[
        {"when": "2026-10-24T08:00", "end": "2026-10-24T10:00", "title": "now"},
        {"when": "2026-10-24T07:00", "end": "2026-10-24T08:00", "title": "done"}])
    assert [i["title"] for i in out["items"]] == ["now"]


def test_hyprflow_names_still_work():
    assert REGISTRY["hyprflow-events"] is REGISTRY["events"]
    assert REGISTRY["hyprflow-month"] is REGISTRY["month"]


def test_events_file_and_hyprflow_together(home, tmp_path, monkeypatch):
    calendar(tmp_path, monkeypatch, {"2026-10": [
        {"title": "Talk", "start": "2026-10-30T10:00", "end": "2026-10-30T11:00"}]})
    paths.data().mkdir(parents=True)
    (paths.data() / "events.json").write_text(json.dumps([{"when": "2026-10-27", "title": "Mine"}]))
    assert [i["title"] for i in events.collect(now=NOW)["items"]] == ["Mine", "Talk"]
    assert month.collect(now=NOW)["marked"] == [27, 30]


def test_hyprflow_alone(home, tmp_path, monkeypatch):
    calendar(tmp_path, monkeypatch, {"2026-10": [{"title": "Talk", "start": "2026-10-30T10:00"}]})
    out = events.collect(now=NOW)
    assert [i["title"] for i in out["items"]] == ["Talk"] and out["error"] is None
