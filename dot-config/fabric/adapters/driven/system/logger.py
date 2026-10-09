"""Logger adapters — ConsoleLogger (dev) and JsonLogger (prod/CI).

Logging is an adapter behind LoggerPort, never infra and never a bare print.
"""

from __future__ import annotations

import json
import sys
import threading
from datetime import UTC, datetime
from typing import Any, TextIO


class ConsoleLogger:
    """Structured, human-readable lines on stderr. Colour only on a TTY."""

    def __init__(self, stream: TextIO | None = None, min_level: str = "info") -> None:
        self._stream = stream or sys.stderr
        self._min_level = min_level
        self._lock = threading.Lock()
        self._levels = {"debug": 10, "info": 20, "warning": 30, "error": 40}

    def _log(self, level: str, component: str, message: str, **context: Any) -> None:
        if self._levels[level] < self._levels[self._min_level]:
            return
        stamp = datetime.now(UTC).strftime("%H:%M:%S")
        suffix = ""
        if context:
            suffix = " " + " ".join(f"{key}={value!r}" for key, value in context.items())
        with self._lock:
            self._stream.write(f"{stamp} {level.upper():<7} [{component}] {message}{suffix}\n")
            self._stream.flush()

    def debug(self, component: str, message: str, **context: Any) -> None:
        self._log("debug", component, message, **context)

    def info(self, component: str, message: str, **context: Any) -> None:
        self._log("info", component, message, **context)

    def warning(self, component: str, message: str, **context: Any) -> None:
        self._log("warning", component, message, **context)

    def error(self, component: str, message: str, **context: Any) -> None:
        self._log("error", component, message, **context)


class JsonLogger:
    """One JSON object per line — for journald, files, or a log shipper."""

    def __init__(self, stream: TextIO | None = None) -> None:
        self._stream = stream or sys.stderr
        self._lock = threading.Lock()

    def _log(self, level: str, component: str, message: str, **context: Any) -> None:
        record = {
            "ts": datetime.now(UTC).isoformat(),
            "level": level,
            "component": component,
            "message": message,
            **context,
        }
        line = json.dumps(record, default=str)
        with self._lock:
            self._stream.write(line + "\n")
            self._stream.flush()

    def debug(self, component: str, message: str, **context: Any) -> None:
        self._log("debug", component, message, **context)

    def info(self, component: str, message: str, **context: Any) -> None:
        self._log("info", component, message, **context)

    def warning(self, component: str, message: str, **context: Any) -> None:
        self._log("warning", component, message, **context)

    def error(self, component: str, message: str, **context: Any) -> None:
        self._log("error", component, message, **context)
