"""Railway-oriented results — expected failures as values, not exceptions.

Workflows return ``Result[T]`` (``Success`` / ``Failure``). The driving adapter
renders both tracks in one ``match``. Compose with the fixed toolkit only:
``and_then`` / ``map_value`` / ``pipeline`` / ``recover`` over *named steps*.

Defects raise; expected outcomes ride the failure track.
"""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
from typing import Any, Generic, TypeVar

from domain.errors import AppError

T = TypeVar("T")
U = TypeVar("U")
V = TypeVar("V")


@dataclass(frozen=True, slots=True)
class Success(Generic[T]):
    value: T

    def is_ok(self) -> bool:
        return True

    def is_failure(self) -> bool:
        return False


@dataclass(frozen=True, slots=True)
class Failure:
    error: AppError

    def is_ok(self) -> bool:
        return False

    def is_failure(self) -> bool:
        return True


Result = Success[T] | Failure


def ok(value: T) -> Success[T]:
    return Success(value)


def fail(error: AppError) -> Failure:
    return Failure(error)


def and_then(result: Result[T], step: Callable[[T], Result[U]]) -> Result[U]:
    """Chain a step that itself returns a Result. Short-circuits on Failure."""
    match result:
        case Success(value):
            return step(value)
        case Failure() as f:
            return f


def map_value(result: Result[T], transform: Callable[[T], U]) -> Result[U]:
    """Transform a success value with a pure function. Leaves Failure untouched."""
    match result:
        case Success(value):
            return Success(transform(value))
        case Failure() as f:
            return f


def pipeline(value: T, *steps: Callable[[Any], Result[Any]]) -> Result[Any]:
    """Run *named steps* left-to-right, stopping at the first Failure."""
    current: Result[Any] = Success(value)
    for step in steps:
        current = and_then(current, step)
        if isinstance(current, Failure):
            break
    return current


def recover(result: Result[T], handler: Callable[[AppError], Result[T]]) -> Result[T]:
    """Convert a Failure back to the success track (or another Failure)."""
    match result:
        case Failure(error):
            return handler(error)
        case success:
            return success


def unwrap_or(result: Result[T], default: T) -> T:
    match result:
        case Success(value):
            return value
        case Failure():
            return default
