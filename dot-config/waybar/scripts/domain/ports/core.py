"""Cross-cutting ports: logging, time, lifetime, notifications, UI, sound.

These are the contracts the domain needs fulfilled. Concrete adapters live in
``adapters/`` and are injected by the composition root.
"""

from __future__ import annotations

from collections.abc import Callable
from datetime import datetime
from enum import StrEnum
from typing import Protocol


class Logger(Protocol):
    def debug(self, message: str) -> None: ...

    def info(self, message: str) -> None: ...

    def warning(self, message: str) -> None: ...

    def error(self, message: str) -> None: ...


class TimePort(Protocol):
    """Wall-clock access. Injected so tests can control time."""

    def now_ms(self) -> int: ...

    def elapsed_ms(self, start_ms: int) -> int: ...

    def now(self) -> datetime: ...


class ExitReason(StrEnum):
    NORMAL = "normal"
    USER_EXIT = "user_exit"
    CRASH = "crash"
    TIMEOUT = "timeout"
    SHUTDOWN = "shutdown"


class LifetimePort(Protocol):
    """Detect why a process is ending so no resource is left behind."""

    def register_cleanup(self, handler: Callable[[], None]) -> None: ...

    def on_exit(self, handler: Callable[[ExitReason], None]) -> None: ...

    def get_exit_reason(self) -> ExitReason: ...

    def is_shutting_down(self) -> bool: ...


class Notifier(Protocol):
    def notify(self, summary: str, body: str, urgency: str = "normal") -> None: ...


class Prompt(Protocol):
    """Driving port: show a menu and return the chosen line, or ``None``."""

    def is_available(self) -> bool: ...

    def choose(self, lines: list[str], prompt: str) -> str | None: ...


class BarGateway(Protocol):
    """Signal the running waybar so a module re-runs immediately."""

    def refresh(self, signal_offset: int) -> None: ...


class SoundPlayer(Protocol):
    def play(self, path: str, volume: float = 0.3) -> None: ...
