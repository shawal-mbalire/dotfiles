"""ProcessLifetime — the LifetimePort implementation.

Registers cleanup callbacks, traps SIGINT/SIGTERM, and runs every callback once
in reverse registration order, whatever the exit reason. No resource is left
behind.
"""

from __future__ import annotations

import contextlib
import signal
from collections.abc import Callable
from typing import Any

from domain.ports.lifetime import ExitReason


class ProcessLifetime:
    """Owns the process's graceful shutdown."""

    def __init__(self, on_request_exit: Callable[[], None] | None = None) -> None:
        self._reason = ExitReason.NORMAL
        self._callbacks: list[Callable[[ExitReason], None]] = []
        self._started = False
        self._on_request_exit = on_request_exit

    @property
    def reason(self) -> ExitReason:
        return self._reason

    def on_exit(self, callback: Callable[[ExitReason], None]) -> None:
        if callback not in self._callbacks:
            self._callbacks.append(callback)

    def install_signal_handlers(self) -> None:
        """Trap SIGINT/SIGTERM so the shell shuts down cleanly."""
        if self._started:
            return
        self._started = True
        for sig in (signal.SIGINT, signal.SIGTERM):
            with contextlib.suppress(ValueError, OSError):
                signal.signal(sig, self._handle_signal)

    def _handle_signal(self, signum: int, _frame: Any) -> None:
        self._reason = ExitReason.SIGNAL
        if self._on_request_exit is not None:
            self._on_request_exit()
        else:
            self.exit(ExitReason.SIGNAL)

    def exit(self, reason: ExitReason = ExitReason.NORMAL) -> None:
        self._reason = reason
        while self._callbacks:
            callback = self._callbacks.pop()
            try:
                callback(reason)
            except Exception:  # noqa: BLE001 - cleanup must not mask the exit
                continue
