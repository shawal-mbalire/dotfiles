"""Structured logger adapter.

All output goes to stderr so waybar's JSON on stdout is never corrupted.
"""

from __future__ import annotations

import sys

LEVELS = {"debug": 10, "info": 20, "warning": 30, "error": 40}


class ConsoleLogger:
    def __init__(self, level: str = "warning") -> None:
        self._threshold = LEVELS.get(level.lower(), LEVELS["warning"])

    def _emit(self, level: str, message: str) -> None:
        if LEVELS[level] < self._threshold:
            return
        print(f"waybar[{level}] {message}", file=sys.stderr)

    def debug(self, message: str) -> None:
        self._emit("debug", message)

    def info(self, message: str) -> None:
        self._emit("info", message)

    def warning(self, message: str) -> None:
        self._emit("warning", message)

    def error(self, message: str) -> None:
        self._emit("error", message)
