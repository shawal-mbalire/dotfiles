"""Domain errors: business-rule failures, never infrastructure leaks."""

from __future__ import annotations


class SwayncError(Exception):
    """Base class for every domain error raised by the config generator."""


class DuplicateWidgetError(SwayncError):
    """Raised when two widgets resolve to the same swaync key."""

    def __init__(self, key: str) -> None:
        super().__init__(f"Duplicate widget key: {key!r}")
        self.key = key


class InvalidWidgetError(SwayncError):
    """Raised when a widget is missing required options (e.g. no buttons)."""

    def __init__(self, widget: str, reason: str) -> None:
        super().__init__(f"Invalid widget {widget!r}: {reason}")
        self.widget = widget
        self.reason = reason


class MissingArtifactError(SwayncError):
    """Raised by the check command when a generated artifact is absent."""

    def __init__(self, path: str) -> None:
        super().__init__(f"Generated artifact missing: {path}")
        self.path = path
