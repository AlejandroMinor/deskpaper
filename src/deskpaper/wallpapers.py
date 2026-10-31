"""The picture each screen shows now, so the editor draws the real desktop."""
import re
import shutil
import subprocess

DAEMONS = ("awww", "swww")
LINE = re.compile(r"^:?\s*([^:\s]+):.*currently displaying: image: (.+)$")


def parse(text: str) -> dict[str, str]:
    found = {}
    for line in text.splitlines():
        m = LINE.match(line.strip())
        if m:
            found[m.group(1)] = m.group(2).strip()
    return found


def current() -> dict[str, str]:
    for daemon in DAEMONS:
        if not shutil.which(daemon):
            continue
        try:
            r = subprocess.run([daemon, "query"], capture_output=True, text=True, timeout=5)
        except (OSError, subprocess.TimeoutExpired):
            continue
        if r.returncode == 0:
            return parse(r.stdout)
    return {}
