"""``LifetimePort`` adapter: signal handling and graceful cleanup."""

from __future__ import annotations

import contextlib
import signal
import sys
from collections.abc import Callable

from domain.ports.core import ExitReason, Logger


class ProcessLifetime:
    """Tracks why the process is exiting and runs registered cleanups once."""

    def __init__(self, logger: Logger | None = None) -> None:
        self._logger = logger
        self._reason = ExitReason.NORMAL
        self._cleanups: list[Callable[[], None]] = []
        self._exit_handlers: list[Callable[[ExitReason], None]] = []
        self._shutting_down = False
        self._installed = False

    def register_cleanup(self, handler: Callable[[], None]) -> None:
        self._cleanups.append(handler)

    def on_exit(self, handler: Callable[[ExitReason], None]) -> None:
        self._exit_handlers.append(handler)

    def get_exit_reason(self) -> ExitReason:
        return self._reason

    def is_shutting_down(self) -> bool:
        return self._shutting_down

    def install(self) -> None:
        if self._installed:
            return
        self._install(signal.SIGINT, ExitReason.USER_EXIT)
        self._install(signal.SIGTERM, ExitReason.SHUTDOWN)
        self._installed = True

    def _install(self, signum: int, reason: ExitReason) -> None:
        def handler(_signum: int, _frame: object) -> None:
            self._reason = reason
            self._shutting_down = True
            raise KeyboardInterrupt

        with contextlib.suppress(OSError, ValueError):
            signal.signal(signum, handler)

    def shutdown(self, reason: ExitReason | None = None) -> None:
        if reason is not None:
            self._reason = reason
        self._shutting_down = True

        for cleanup in reversed(self._cleanups):
            try:
                cleanup()
            except Exception as error:  # pragma: no cover - defensive
                self._report_cleanup_failure(error)
        self._cleanups.clear()

        for handler in self._exit_handlers:
            with contextlib.suppress(Exception):
                handler(self._reason)
        self._exit_handlers.clear()

    def _report_cleanup_failure(self, error: Exception) -> None:
        message = f"cleanup failed: {error}"
        if self._logger is not None:
            self._logger.error(message)
        else:
            print(f"hypr[error] {message}", file=sys.stderr)

    def __enter__(self) -> ProcessLifetime:
        self.install()
        return self

    def __exit__(self, exc_type: object, exc: object, traceback: object) -> bool:
        if exc_type is KeyboardInterrupt:
            if self._reason is ExitReason.NORMAL:
                self._reason = ExitReason.USER_EXIT
        elif exc_type is not None:
            self._reason = ExitReason.CRASH
        self.shutdown()
        return False
