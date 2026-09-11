#!/usr/bin/env python3
"""Hyprland config developer helpers: logs, watch-reload, e2e, lint, format,
typecheck and clean.

Invoked by the justfile — keeps all non-trivial logic in Python instead of
shell recipes.
"""

from __future__ import annotations

import glob
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
IGNORED_DIRS = {"build", ".git"}


def lua_files() -> list[Path]:
    return sorted(
        path
        for path in ROOT.rglob("*.lua")
        if not any(part in IGNORED_DIRS for part in path.parts)
    )


def run(argv: list[str]) -> int:
    return subprocess.run(argv).returncode


def cmd_logs() -> int:
    runtime = os.environ.get("XDG_RUNTIME_DIR", "")
    candidates = glob.glob(os.path.join(runtime, "hypr", "*", "hyprland.log"))
    if not candidates:
        print(f"No Hyprland log found under {runtime}/hypr", file=sys.stderr)
        return 1
    newest = max(candidates, key=os.path.getmtime)
    os.execvp("tail", ["tail", "-f", newest])
    return 0


def cmd_watch() -> int:
    if shutil.which("inotifywait") is None:
        print("inotifywait not installed; falling back to 'just logs'", file=sys.stderr)
        return cmd_logs()
    print(f"Watching {ROOT} for changes (Ctrl-C to stop)...")
    while True:
        subprocess.run(
            ["inotifywait", "-qr", "-e", "close_write,modify,move", str(ROOT)],
            check=False,
        )
        subprocess.run(["hyprctl", "reload"], check=False)


def cmd_e2e() -> int:
    if shutil.which("hyprctl") is None:
        print("Hyprland is not running; skipping e2e")
        return 0
    if subprocess.run(["hyprctl", "version"], capture_output=True).returncode != 0:
        print("Hyprland is not running; skipping e2e")
        return 0
    run(["hyprctl", "reload"])
    print("e2e reload OK")
    return 0


def cmd_typecheck() -> int:
    files = [str(path) for path in lua_files()]
    if not files:
        print("no Lua files found", file=sys.stderr)
        return 1
    result = subprocess.run(["luac", "-p", *files])
    if result.returncode == 0:
        print("syntax OK")
    return result.returncode


def cmd_lint() -> int:
    if shutil.which("luacheck"):
        return run(["luacheck", str(ROOT)])
    print("luacheck not installed; falling back to syntax check")
    return cmd_typecheck()


def cmd_format() -> int:
    if shutil.which("stylua"):
        return run(["stylua", str(ROOT)])
    print("stylua not installed; skipping format")
    return 0


def cmd_clean() -> int:
    for path in ROOT.rglob("*.luac"):
        path.unlink()
    for cache in ROOT.rglob("__pycache__"):
        shutil.rmtree(cache, ignore_errors=True)
    shutil.rmtree(ROOT / "build", ignore_errors=True)
    print("cleaned")
    return 0


COMMANDS = {
    "logs": cmd_logs,
    "watch": cmd_watch,
    "e2e": cmd_e2e,
    "typecheck": cmd_typecheck,
    "lint": cmd_lint,
    "format": cmd_format,
    "clean": cmd_clean,
}


def main(argv: list[str]) -> int:
    if len(argv) != 2 or argv[1] not in COMMANDS:
        print(f"usage: {Path(argv[0]).name} {{{'|'.join(COMMANDS)}}}", file=sys.stderr)
        return 2
    return COMMANDS[argv[1]]()


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
