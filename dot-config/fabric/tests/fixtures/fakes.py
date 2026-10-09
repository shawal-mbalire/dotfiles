"""Shared test fixtures: fake ports and builders.

Fakes are pure in-memory implementations of the ports. They are reused across
every test tier and never duplicated per test.
"""

from __future__ import annotations

from dataclasses import replace

from domain.models import (
    AppEntry,
    Audio,
    Battery,
    Bluetooth,
    Brightness,
    Clipboard,
    Network,
    NightLight,
    NotificationEntry,
    NotificationFeed,
    TrayItem,
    Urgency,
    Wallpaper,
    WifiEntry,
    Workspace,
    WorkspaceState,
)
from domain.ports.base import Listener, Unsubscribe


class FakeSource:
    """An in-memory observable reading. Notify via :meth:`emit`."""

    def __init__(self, initial):
        self._value = initial
        self._listeners: list[Listener] = []

    def read(self):
        return self._value

    def subscribe(self, listener: Listener) -> Unsubscribe:
        self._listeners.append(listener)
        listener(self._value)
        return lambda: self._listeners.remove(listener)

    def emit(self, value) -> None:
        self._value = value
        for listener in tuple(self._listeners):
            listener(value)


class FakeAudioPort(FakeSource):
    def __init__(self) -> None:
        super().__init__(Audio(ready=True, muted=False, volume=40))

    def set_volume(self, percent: int) -> None:
        value = self.read()
        self.emit(
            Audio(
                ready=value.ready, muted=value.muted, volume=int(max(0, min(150, round(percent))))
            )
        )

    def set_muted(self, muted: bool) -> None:
        value = self.read()
        self.emit(Audio(ready=value.ready, muted=muted, volume=value.volume))


class FakeBrightnessPort(FakeSource):
    def __init__(self) -> None:
        super().__init__(Brightness(available=True, percent=70))

    def set_percent(self, percent: int) -> None:
        value = self.read()
        self.emit(
            Brightness(available=value.available, percent=int(max(0, min(100, round(percent)))))
        )


class FakeNightLightPort(FakeSource):
    def __init__(self) -> None:
        super().__init__(NightLight(active=False))
        self.refreshes = 0

    def set_active(self, active: bool) -> None:
        self.emit(NightLight(active=active))

    def refresh(self) -> None:
        self.refreshes += 1


class FakeBluetoothPort(FakeSource):
    def __init__(self) -> None:
        super().__init__(Bluetooth(available=True, enabled=False, connected_name=""))

    def set_enabled(self, enabled: bool) -> None:
        value = self.read()
        name = value.connected_name if enabled else ""
        self.emit(Bluetooth(available=value.available, enabled=enabled, connected_name=name))


class FakeBatteryPort(FakeSource):
    def __init__(self, battery: Battery | None = None) -> None:
        super().__init__(
            battery
            or Battery(
                present=True, level=62, charging=False, state="Discharging", time_text="3h 10m left"
            )
        )


class FakeColorSchemePort(FakeSource):
    def __init__(self, dark: bool = True) -> None:
        super().__init__(dark)

    def set_dark(self, dark: bool) -> None:
        self.emit(dark)


def sample_network() -> Network:
    return Network(
        available=True,
        wifi_enabled=True,
        connected=True,
        ssid="home",
        strength=0.8,
        scanning=False,
        networks=(
            WifiEntry(name="home", signal=80, secured=True, known=True, connected=True),
            WifiEntry(name="cafe", signal=55, secured=True, known=False, connected=False),
            WifiEntry(name="open", signal=30, secured=False, known=False, connected=False),
        ),
    )


class FakeNetworkPort(FakeSource):
    def __init__(self) -> None:
        super().__init__(sample_network())
        self.attempts: list[tuple[str, str]] = []
        self._failure_listeners: list = []

    def subscribe_failures(self, listener):
        self._failure_listeners.append(listener)
        return lambda: self._failure_listeners.remove(listener)

    def emit_failure(self, name: str, reason: str) -> None:
        for listener in tuple(self._failure_listeners):
            listener(name, reason)

    def set_wifi_enabled(self, enabled: bool) -> None:
        self.emit(replace(self.read(), wifi_enabled=enabled))

    def set_scanning(self, scanning: bool) -> None:
        self.emit(replace(self.read(), scanning=scanning))

    def connect_to(self, name: str) -> None:
        self.attempts.append((name, ""))

    def connect_with_psk(self, name: str, psk: str) -> None:
        self.attempts.append((name, psk))


class FakeClipboardPort(FakeSource):
    def __init__(self) -> None:
        super().__init__(Clipboard(history=("first entry", "second entry"), state="ready"))
        self.copied: list[str] = []

    def copy(self, text: str) -> None:
        self.copied.append(text)
        value = self.read()
        history = (text, *(t for t in value.history if t != text))
        self.emit(Clipboard(history=history, state=value.state))

    def remove(self, text: str) -> None:
        value = self.read()
        self.emit(
            Clipboard(history=tuple(t for t in value.history if t != text), state=value.state)
        )

    def clear(self) -> None:
        value = self.read()
        self.emit(Clipboard(history=(), state=value.state))


class FakeLaunchPort(FakeSource):
    def __init__(self, apps: tuple[AppEntry, ...] | None = None) -> None:
        super().__init__(apps or sample_apps())
        self.launched: list[str] = []

    def launch(self, app_id: str) -> bool:
        if app_id not in {a.id for a in self.read()}:
            return False
        self.launched.append(app_id)
        return True


class FakeWorkspacePort(FakeSource):
    def __init__(self) -> None:
        super().__init__(
            WorkspaceState(
                workspaces=(Workspace(1, True), Workspace(2, False)),
                focused_id=1,
                count=10,
            )
        )
        self.focused: list[int] = []

    def focus(self, workspace_id: int) -> None:
        self.focused.append(workspace_id)


class FakeTrayPort(FakeSource):
    def __init__(self) -> None:
        super().__init__((TrayItem(id="app", title="App", icon=""),))
        self.activated: list[str] = []

    def activate(self, item_id: str) -> None:
        self.activated.append(item_id)

    def secondary_activate(self, item_id: str) -> None:
        self.activated.append("secondary:" + item_id)

    def context_menu(self, item_id: str) -> None:
        self.activated.append("menu:" + item_id)


class FakeNotificationFeedPort(FakeSource):
    def __init__(self) -> None:
        super().__init__(NotificationFeed())
        self.dismissed: list[int] = []

    def dismiss(self, key: int) -> None:
        self.dismissed.append(key)

    def expire(self, key: int) -> None:
        self.dismissed.append(key)

    def invoke_default(self, key: int) -> bool:
        return False

    def has_default_action(self, key: int) -> bool:
        return False

    def pause(self, key: int) -> bool:
        return True

    def resume(self, key: int) -> bool:
        return True

    def clear_history(self) -> None:
        self.emit(NotificationFeed())

    def dismiss_all(self) -> None:
        self.emit(NotificationFeed())


class FakeWallpaperPort(FakeSource):
    def __init__(self) -> None:
        super().__init__(Wallpaper(wallpapers=("a.jpg", "b.png", "c.webp"), current="a.jpg"))
        self.applied: list[str] = []

    def refresh(self) -> None:
        pass

    def set(self, path: str) -> None:
        self.applied.append(path)
        self.emit(Wallpaper(wallpapers=self.read().wallpapers, current=path))

    def next(self) -> None:
        pass

    def previous(self) -> None:
        pass

    def random(self) -> None:
        pass


class FakeRandomPort:
    def __init__(self, value: float = 0.5) -> None:
        self.value = value

    def random(self) -> float:
        return self.value


class FakeLoggerPort:
    def __init__(self) -> None:
        self.entries: list[tuple[str, str, str, dict]] = []

    def _log(self, level: str, component: str, message: str, **context) -> None:
        self.entries.append((level, component, message, context))

    def debug(self, component: str, message: str, **context) -> None:
        self._log("debug", component, message, **context)

    def info(self, component: str, message: str, **context) -> None:
        self._log("info", component, message, **context)

    def warning(self, component: str, message: str, **context) -> None:
        self._log("warning", component, message, **context)

    def error(self, component: str, message: str, **context) -> None:
        self._log("error", component, message, **context)


def sample_apps() -> tuple[AppEntry, ...]:
    return (
        AppEntry(
            id="firefox.desktop",
            name="Firefox",
            generic_name="Web Browser",
            keywords=("internet", "www"),
        ),
        AppEntry(id="files.desktop", name="Files", generic_name="File Manager"),
        AppEntry(
            id="gimp.desktop", name="GNU Image Manipulation Program", generic_name="Image Editor"
        ),
        AppEntry(id="kitty.desktop", name="kitty", generic_name="Terminal Emulator"),
        AppEntry(id="code.desktop", name="Visual Studio Code", comment="Code editing. Redefined."),
    )


def sample_notification(key: int = 1) -> NotificationEntry:
    return NotificationEntry(
        key=key, app_name="App", summary="Hello", body="World", urgency=Urgency.NORMAL
    )
