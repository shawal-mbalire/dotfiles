"""LoggerPort — structured logging, implemented by adapters, not infra."""

from __future__ import annotations

from typing import Any, Protocol, runtime_checkable


@runtime_checkable
class LoggerPort(Protocol):
    """CONTRACT — LoggerPort.

    Every call takes a ``component`` and a human message plus structured
    ``context``. A failure is reported through here, never swallowed and never a
    bare print.
    """

    def debug(self, component: str, message: str, **context: Any) -> None: ...

    def info(self, component: str, message: str, **context: Any) -> None: ...

    def warning(self, component: str, message: str, **context: Any) -> None: ...

    def error(self, component: str, message: str, **context: Any) -> None: ...
