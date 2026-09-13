"""Domain errors: business-rule failures, never infrastructure leaks."""

from __future__ import annotations


class HyprScriptError(Exception):
    """Base class for every domain error raised by the helper scripts."""


class NoSecondaryMonitorError(HyprScriptError):
    """Raised when the display toggle finds no secondary output."""

    def __init__(self) -> None:
        super().__init__("Secondary display not detected")
