#!/usr/bin/env python3
"""SwayNC config developer helpers: watch-reload and log streaming.

Invoked by the Justfile — keeps non-trivial logic in Python instead of shell
recipes.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAIN = ROOT / "scripts" / "main.py"
WATCH_DIR = ROOT / "scripts"
IGNORE_PATTERN = r"(\.pyc|__pycache__|\.venv|\.pytest_cache|\.ruff_cache)"


def _python() -> str:
    return sys.executable or "python3"


def _generate(reload: bool = True) -> int:
    argv = [_python(), str(MAIN), "generate"]
    if reload:
        argv.append("--reload")
    return subprocess.run(argv, cwd=ROOT, check=False).returncode


def cmd_watch() -> int:
    if shutil.which("inotifywait") is None:
        print("inotifywait not installed; running a single generate", file=sys.stderr)
        return _generate()

    print(f"Watching {WATCH_DIR} (Ctrl-C to stop)...")
    _generate()
    while True:
        subprocess.run(
            [
                "inotifywait",
                "-qr",
                "-e",
                "close_write,modify,move",
                "--exclude",
                IGNORE_PATTERN,
                str(WATCH_DIR),
            ],
            check=False,
        )
        _generate()


def cmd_logs() -> int:
    if shutil.which("journalctl") is None:
        print("journalctl not available", file=sys.stderr)
        return 1
    return subprocess.run(["journalctl", "--user", "-f", "-t", "swaync"], check=False).returncode


COMMANDS = {
    "watch": cmd_watch,
    "logs": cmd_logs,
}


def main(argv: list[str]) -> int:
    if len(argv) != 2 or argv[1] not in COMMANDS:
        print(f"usage: {Path(argv[0]).name} {{{'|'.join(COMMANDS)}}}", file=sys.stderr)
        return 2
    return COMMANDS[argv[1]]()


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
