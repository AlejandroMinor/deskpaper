"""Starts the Quickshell side: the stickers on the desktop and the editor."""
import subprocess
import time

from . import paths


class ShellError(Exception):
    pass


def _qs(*args, **kw) -> subprocess.CompletedProcess:
    try:
        return subprocess.run(["qs", "-p", str(paths.qml()), *args], **kw)
    except FileNotFoundError:
        raise ShellError("qs not found: install quickshell") from None


def start() -> None:
    """The desktop layer, unless it is already running."""
    _qs("-n", "-d", stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def edit(timeout: float = 10) -> None:
    """Opens the editor, starting the desktop layer first if needed."""
    start()
    deadline = time.monotonic() + timeout
    # A layer that has just started takes a moment to answer.
    while _qs("ipc", "call", "editor", "open", capture_output=True).returncode != 0:
        if time.monotonic() > deadline:
            raise ShellError("the editor did not answer; run `qs -p qml` to see why")
        time.sleep(0.2)
