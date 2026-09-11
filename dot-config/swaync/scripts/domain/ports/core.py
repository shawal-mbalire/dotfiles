"""Cross-cutting ports: logging, time, lifetime and command execution.

These are the contracts the domain needs fulfilled. Concrete adapters live in
``adapters/`` and are injected by the composition root.
"""

from __future__ import annotations

from collections.abc import Callable
from enum import StrEnum
from typing import Protocol, runtime_checkable


@runtime_checkable
class Logger(Protocol):
    def debug(self, message: str) -> None: ...

    def info(self, message: str) -> None: ...

    def warning(self, message: str) -> None: ...

    def error(self, message: str) -> None: ...


@runtime_checkable
class TimePort(Protocol):
    """Wall-clock access. Injected so tests can control time."""

    def now_ms(self) -> int: ...

    def elapsed_ms(self, start_ms: int) -> int: ...


class ExitReason(StrEnum):
    NORMAL = "normal"
    USER_EXIT = "user_exit"
    CRASH = "crash"
    TIMEOUT = "timeout"
    SHUTDOWN = "shutdown"


@runtime_checkable
class LifetimePort(Protocol):
    """Detect why a process is ending so no resource is left behind."""

    def register_cleanup(self, handler: Callable[[], None]) -> None: ...

    def on_exit(self, handler: Callable[[ExitReason], None]) -> None: ...

    def get_exit_reason(self) -> ExitReason: ...

    def is_shutting_down(self) -> bool: ...


@runtime_checkable
class CommandRunner(Protocol):
    """Run an external command (e.g. reload swaync after generating)."""

    def run(self, command: str) -> int: ...
