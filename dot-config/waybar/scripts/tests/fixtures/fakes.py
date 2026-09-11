"""In-memory fakes implementing the domain ports.

Domain and workflow tests use these instead of mocks: same interface as the
real adapters, no I/O, deterministic.
"""

from __future__ import annotations

from datetime import datetime

from domain.models import (
    AudioSink,
    AudioStatus,
    BatteryStatus,
    BluetoothDevice,
    NetworkStatus,
)


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


class FakeTime:
    def __init__(self, now_ms: int = 0, now: datetime | None = None) -> None:
        self.current_ms = now_ms
        self._now = now or datetime(2026, 1, 2, 15, 4, 5)

    def now_ms(self) -> int:
        return self.current_ms

    def elapsed_ms(self, start_ms: int) -> int:
        return self.current_ms - start_ms

    def now(self) -> datetime:
        return self._now

    def advance(self, ms: int) -> None:
        self.current_ms += ms


class FakeNotifier:
    def __init__(self) -> None:
        self.notifications: list[tuple[str, str, str]] = []

    def notify(self, summary: str, body: str, urgency: str = "normal") -> None:
        self.notifications.append((summary, body, urgency))


class FakePrompt:
    def __init__(
        self,
        response: str | None = None,
        available: bool = True,
        responses: list[str | None] | None = None,
    ) -> None:
        self.response = response
        self.responses = list(responses) if responses is not None else None
        self._available = available
        self.calls: list[tuple[list[str], str]] = []

    def is_available(self) -> bool:
        return self._available

    def choose(self, lines: list[str], prompt: str) -> str | None:
        self.calls.append((list(lines), prompt))
        if self.responses is not None:
            return self.responses.pop(0) if self.responses else None
        return self.response


class FakeBar:
    def __init__(self) -> None:
        self.refreshes: list[int] = []

    def refresh(self, signal_offset: int) -> None:
        self.refreshes.append(signal_offset)


class FakeSound:
    def __init__(self) -> None:
        self.plays: list[tuple[str, float]] = []

    def play(self, path: str, volume: float = 0.3) -> None:
        self.plays.append((path, volume))


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


class FakePowerGateway:
    def __init__(self, active: str | None = "balanced", succeed: bool = True) -> None:
        self.active = active
        self.succeed = succeed
        self.sets: list[str] = []

    def get_active(self) -> str | None:
        return self.active

    def set_profile(self, name: str) -> bool:
        self.sets.append(name)
        if self.succeed:
            self.active = name
        return self.succeed


class FakeAudioControl:
    def __init__(self, volume: int = 50, muted: bool = False) -> None:
        self.volume = volume
        self.muted = muted
        self.adjustments: list[int] = []
        self.toggles = 0

    def get_status(self) -> AudioStatus:
        return AudioStatus(volume_percent=self.volume, muted=self.muted)

    def adjust_volume(self, step: int) -> None:
        self.adjustments.append(step)
        self.volume = max(0, min(100, self.volume + step))

    def toggle_mute(self) -> None:
        self.toggles += 1
        self.muted = not self.muted


class FakeAudioDevices:
    def __init__(
        self,
        sinks: list[AudioSink] | None = None,
        default: str = "sink-a",
    ) -> None:
        self._sinks = sinks or [
            AudioSink(name="sink-a", description="Speakers"),
            AudioSink(name="sink-b", description="Headphones"),
        ]
        self.default = default
        self.set_calls: list[str] = []

    def list_sinks(self) -> list[AudioSink]:
        return [
            AudioSink(
                name=sink.name, description=sink.description, is_default=sink.name == self.default
            )
            for sink in self._sinks
        ]

    def get_default_sink(self) -> str | None:
        return self.default

    def set_default_sink(self, name: str) -> bool:
        self.set_calls.append(name)
        self.default = name
        return True


class FakeBluetoothGateway:
    def __init__(
        self,
        devices: list[BluetoothDevice] | None = None,
        powered: bool = True,
        available: bool = True,
    ) -> None:
        self.devices = devices or []
        self.powered = powered
        self._available = available
        self.actions: list[tuple[str, str]] = []

    def is_available(self) -> bool:
        return self._available

    def launch_console(self) -> None:
        self.actions.append(("console", ""))

    def is_powered(self) -> bool:
        return self.powered

    def set_power(self, on: bool) -> None:
        self.actions.append(("power", "on" if on else "off"))
        self.powered = on

    def list_devices(self) -> list[BluetoothDevice]:
        return list(self.devices)

    def connect(self, mac: str) -> None:
        self.actions.append(("connect", mac))

    def disconnect(self, mac: str) -> None:
        self.actions.append(("disconnect", mac))

    def pair(self, mac: str) -> None:
        self.actions.append(("pair", mac))

    def trust(self, mac: str) -> None:
        self.actions.append(("trust", mac))

    def scan(self, seconds: int) -> None:
        self.actions.append(("scan", str(seconds)))


class FakeBrightnessGateway:
    def __init__(self, percent: int = 50) -> None:
        self.percent = percent
        self.relative: list[int] = []
        self.absolute: list[int] = []

    def get_percent(self) -> int:
        return self.percent

    def set_relative(self, delta: int) -> None:
        self.relative.append(delta)
        self.percent = max(1, self.percent + delta)

    def set_percent(self, percent: int) -> None:
        self.absolute.append(percent)
        self.percent = percent


class FakeNightLightGateway:
    def __init__(self, active: bool = False, available: bool = True) -> None:
        self.active = active
        self._available = available
        self.enables = 0
        self.disables = 0

    def is_available(self) -> bool:
        return self._available

    def is_active(self) -> bool:
        return self.active

    def enable(self) -> None:
        self.enables += 1
        self.active = True

    def disable(self) -> None:
        self.disables += 1
        self.active = False


class FakeNetworkGateway:
    def __init__(self, status: NetworkStatus | None = None) -> None:
        self._status = status or NetworkStatus(
            interface="wlan0", ip_address="10.0.0.2", wireless=True
        )

    def status(self) -> NetworkStatus:
        return self._status


class FakeBatteryGateway:
    def __init__(self, status: BatteryStatus | None = None) -> None:
        self._status = status or BatteryStatus(capacity=73, state="Discharging")

    def status(self) -> BatteryStatus:
        return self._status
