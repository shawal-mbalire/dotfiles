"""Domain errors: business-rule failures, never infrastructure leaks."""

from __future__ import annotations


class WaybarError(Exception):
    """Base class for every domain error raised by the waybar scripts."""


class UnknownPowerProfileError(WaybarError):
    """Raised when a profile is requested that the domain does not know."""

    def __init__(self, name: str) -> None:
        super().__init__(f"Unknown power profile: {name!r}")
        self.name = name


class TimeBudgetError(WaybarError):
    """Raised when a script overruns its millisecond time budget."""

    def __init__(self, budget_ms: int) -> None:
        super().__init__(f"Time budget of {budget_ms}ms exceeded")
        self.budget_ms = budget_ms


class ExternalCommandError(WaybarError):
    """Raised when an external command required by an adapter is missing."""

    def __init__(self, command: str) -> None:
        super().__init__(f"Required command not found: {command}")
        self.command = command
