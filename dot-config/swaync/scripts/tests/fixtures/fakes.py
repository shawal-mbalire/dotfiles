"""In-memory fakes implementing the domain ports.

Domain and workflow tests use these instead of mocks: same interface as the
real adapters, no I/O, deterministic.
"""

from __future__ import annotations

from dataclasses import replace

from domain.models import StyleSheet, SwayncConfig
from infra.config import Config, load_config


class FakeLogger:
    def __init__(self) -> None:
        self.messages: list[tuple[str, str]] = []

    def debug(self, message: str) -> None:
        self.messages.append(("debug", message))

    def info(self, message: str) -> None:
        self.messages.append(("info", message))

    def warning(self, message: str) -> None:
        self.messages.append(("warning", message))

    def error(self, message: str) -> None:
        self.messages.append(("error", message))

    def has_message(self, needle: str) -> bool:
        return any(needle in message for _, message in self.messages)


class FakeTime:
    def __init__(self, now_ms: int = 0, step_ms: int = 7) -> None:
        self.current_ms = now_ms
        self.step_ms = step_ms

    def now_ms(self) -> int:
        self.current_ms += self.step_ms
        return self.current_ms

    def elapsed_ms(self, start_ms: int) -> int:
        return self.current_ms - start_ms


class FakeLifetime:
    def __init__(self) -> None:
        self.cleanups: list[object] = []
        self.exit_handlers: list[object] = []
        self.reason = "normal"
        self.shutting_down = False

    def register_cleanup(self, handler: object) -> None:
        self.cleanups.append(handler)

    def on_exit(self, handler: object) -> None:
        self.exit_handlers.append(handler)

    def get_exit_reason(self) -> str:
        return self.reason

    def is_shutting_down(self) -> bool:
        return self.shutting_down


class FakeArtifactWriter:
    def __init__(self) -> None:
        self.config: SwayncConfig | None = None
        self.style: StyleSheet | None = None

    def write_config(self, config: SwayncConfig) -> None:
        self.config = config

    def write_style(self, sheet: StyleSheet) -> None:
        self.style = sheet


class FakeCommands:
    def __init__(self, returncode: int = 0) -> None:
        self.returncode = returncode
        self.commands: list[str] = []

    def run(self, command: str) -> int:
        self.commands.append(command)
        return self.returncode


def base_config(**overrides: object) -> Config:
    """Deterministic config for tests, with optional field overrides."""
    return replace(load_config(), **overrides)
