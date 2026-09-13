"""In-memory fakes implementing the domain ports.

Domain and workflow tests use these instead of mocks: same interface as the
real adapters, no I/O, deterministic.
"""

from __future__ import annotations

from domain.models import BatteryStatus, Monitor, MonitorRule


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

    def has(self, level: str, fragment: str) -> bool:
        return any(lvl == level and fragment in msg for lvl, msg in self.messages)


class FakeTime:
    def __init__(self, now_ms: int = 0) -> None:
        self.current_ms = now_ms

    def now_ms(self) -> int:
        return self.current_ms

    def elapsed_ms(self, start_ms: int) -> int:
        return self.current_ms - start_ms

    def advance(self, ms: int) -> None:
        self.current_ms += ms


class FakeNotifier:
    def __init__(self) -> None:
        self.notifications: list[tuple[str, str, str, str | None]] = []

    def notify(
        self,
        summary: str,
        body: str,
        urgency: str = "normal",
        icon: str | None = None,
    ) -> None:
        self.notifications.append((summary, body, urgency, icon))


class FakeLifetime:
    def __init__(self) -> None:
        self.cleanups: list[object] = []
        self.reason = "normal"
        self.shutting_down = False

    def register_cleanup(self, handler: object) -> None:
        self.cleanups.append(handler)

    def on_exit(self, handler: object) -> None:
        pass

    def get_exit_reason(self) -> str:
        return self.reason

    def is_shutting_down(self) -> bool:
        return self.shutting_down


class FakeBatteryReader:
    def __init__(self, status: BatteryStatus | None = None) -> None:
        self._status = status or BatteryStatus(capacity=73, state="Discharging")

    def read(self) -> BatteryStatus:
        return self._status


class FakeMarkerStore:
    def __init__(self) -> None:
        self.sent: set[str] = set()
        self.state: str | None = None
        self.resets: list[str] = []

    def reset_for_state(self, state: str) -> None:
        self.resets.append(state)
        if state != self.state:
            self.state = state
            self.sent.clear()

    def claim(self, marker: str) -> bool:
        if marker in self.sent:
            return False
        self.sent.add(marker)
        return True


class FakeMonitorGateway:
    def __init__(
        self,
        monitors: list[Monitor] | None = None,
        available: bool = True,
    ) -> None:
        self.monitors = (
            monitors
            if monitors is not None
            else [
                Monitor(name="eDP-1", width=1920),
                Monitor(name="HDMI-A-2", width=1920, mirror_of="eDP-1"),
            ]
        )
        self._available = available
        self.applied: list[MonitorRule] = []

    def list_monitors(self) -> list[Monitor]:
        return list(self.monitors)

    def apply(self, rule: MonitorRule) -> None:
        self.applied.append(rule)
