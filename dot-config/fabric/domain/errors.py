"""Domain errors — every failure is an AppError with a stable code.

A failure is never a bare string or a raw vendor error. It carries:

- ``code``           a stable, registry-backed identifier
- ``context``        structured data for diagnostics
- ``cause``          the original exception, preserved
- ``origin``         layer + location where it was raised
- ``correlation_id`` ties a request to its logs/events

Expected *domain* outcomes ride the failure track as ``Failure`` values (see
``domain.result``). Invalid *system* state raises an ``AppError`` and halts.
"""

from __future__ import annotations

from enum import StrEnum
from typing import Any


class ErrorCode(StrEnum):
    """Stable error codes. Add new codes here — never inline strings."""

    VALIDATION = "FAB-1001"
    NOT_FOUND = "FAB-1002"
    CONTRACT_VIOLATION = "FAB-1003"
    UNAVAILABLE = "FAB-1004"
    EXTERNAL = "FAB-1005"
    CONFIG = "FAB-1006"
    WIRING = "FAB-1007"
    UNSUPPORTED = "FAB-1008"


# Human-readable description per code, used by the error reporter.
REGISTRY: dict[ErrorCode, str] = {
    ErrorCode.VALIDATION: "input failed a precondition",
    ErrorCode.NOT_FOUND: "a required resource does not exist",
    ErrorCode.CONTRACT_VIOLATION: "an adapter broke its port postcondition",
    ErrorCode.UNAVAILABLE: "a required capability is not available",
    ErrorCode.EXTERNAL: "an external system reported a failure",
    ErrorCode.CONFIG: "configuration is missing or invalid",
    ErrorCode.WIRING: "the composition root is misconfigured",
    ErrorCode.UNSUPPORTED: "the requested operation is not supported",
}


class AppError(Exception):
    """Base error for the whole application.

    Raise for *defects* (invalid state, missing dependency). Return
    ``Failure(AppError)`` for *expected* outcomes.
    """

    def __init__(
        self,
        code: ErrorCode,
        message: str,
        *,
        context: dict[str, Any] | None = None,
        cause: BaseException | None = None,
        origin: str = "",
        correlation_id: str = "",
    ) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.context = dict(context or {})
        self.cause = cause
        self.origin = origin
        self.correlation_id = correlation_id

    def __str__(self) -> str:
        return f"[{self.code.value}] {self.message}"

    def to_dict(self) -> dict[str, Any]:
        return {
            "code": self.code.value,
            "message": self.message,
            "context": self.context,
            "origin": self.origin,
            "correlation_id": self.correlation_id,
            "cause": repr(self.cause) if self.cause else None,
        }


class ValidationError(AppError):
    """A precondition failed at a boundary. Raised before any side effect."""

    def __init__(self, message: str, **kw: Any) -> None:
        super().__init__(ErrorCode.VALIDATION, message, **kw)


class NotFoundError(AppError):
    def __init__(self, message: str, **kw: Any) -> None:
        super().__init__(ErrorCode.NOT_FOUND, message, **kw)


class ContractViolationError(AppError):
    """A driven adapter returned partial/malformed data. Internal defect."""

    def __init__(self, message: str, **kw: Any) -> None:
        super().__init__(ErrorCode.CONTRACT_VIOLATION, message, **kw)


class UnavailableError(AppError):
    def __init__(self, message: str, **kw: Any) -> None:
        super().__init__(ErrorCode.UNAVAILABLE, message, **kw)


class ExternalError(AppError):
    """An external system failed. Retry only if transient."""

    def __init__(self, message: str, **kw: Any) -> None:
        super().__init__(ErrorCode.EXTERNAL, message, **kw)
