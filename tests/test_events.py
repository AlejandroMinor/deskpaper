import json
from datetime import datetime

from conftest import run_cli
from deskpaper import paths
from deskpaper.sources import events

NOW = datetime(2026, 10, 24, 9, 0)  # Saturday


def write(entries, name="events.json"):
    paths.data().mkdir(parents=True, exist_ok=True)
    f = paths.data() / name
    if name.endswith(".json"):
        f.write_text(json.dumps(entries))
    else:
        f.write_text("".join(f"- when: '{e['when']}'\n  title: {e['title']}\n" for e in entries))


def titles(out):
    return [i["title"] for i in out["items"]]


def test_events_sorted_future_only(home):
    write([{"when": "2026-10-30T10:00", "title": "B"},
           {"when": "2026-10-20T10:00", "title": "old"},
           {"when": "2026-10-25", "title": "A"}])
    out = events.collect(now=NOW)
    assert titles(out) == ["A", "B"]
    assert out["error"] is None


def test_events_today_all_day_counts(home):
    write([{"when": "2026-10-24", "title": "today"},
           {"when": "2026-10-24T08:00", "title": "earlier"}])
    assert titles(events.collect(now=NOW)) == ["today"]


def test_events_labels(home):
    write([{"when": "2026-10-24T10:00", "title": "a"},
           {"when": "2026-10-25T18:30", "title": "b"},
           {"when": "2026-10-30T10:00", "title": "c"},
           {"when": "2026-11-20", "title": "d"},
           {"when": "2026-10-26", "title": "e"}])
    labels = {i["title"]: i["label"] for i in events.collect(now=NOW)["items"]}
    assert labels == {"a": "Today 10:00", "b": "Tomorrow 18:30", "e": "Mon",
                      "c": "Fri 10:00", "d": "Nov 20"}


def test_events_limit(home):
    write([{"when": f"2026-11-{d:02d}", "title": str(d)} for d in range(1, 10)])
    assert len(events.collect(now=NOW, limit=5)["items"]) == 5


def test_events_yaml(home):
    write([{"when": "2026-10-30T10:00", "title": "B"}], name="events.yml")
    assert titles(events.collect(now=NOW)) == ["B"]


def test_events_missing_file(home):
    assert events.collect(now=NOW) == {"items": [], "error": None}


def test_events_bad_date_skipped(home):
    write([{"when": "someday", "title": "Bad"}, {"when": "2026-10-30", "title": "Ok"}])
    out = events.collect(now=NOW)
    assert titles(out) == ["Ok"]
    assert "Bad" in out["error"]


def test_events_not_a_list(home):
    paths.data().mkdir(parents=True)
    (paths.data() / "events.json").write_text("{nope")
    out = events.collect(now=NOW)
    assert out["items"] == [] and out["error"]


def test_cli_source_events(home):
    r = run_cli("source", "events")
    assert r.returncode == 0
    assert json.loads(r.stdout)["items"] == []


def test_cli_unknown_source_exit_2(home):
    assert run_cli("source", "nope").returncode == 2


def test_events_with_timezone(home):
    write([{"when": "2026-10-30T10:00-06:00", "title": "tz"}])
    out = events.collect(now=NOW)
    assert titles(out) == ["tz"]
    assert out["error"] is None
