"""Fallback driven adapters.

These satisfy a port's *surface* but report the capability as unavailable and
log any command, so the shell always starts and degrades honestly. They are the
default when the native binding for a capability is not present at runtime.
"""

from __future__ import annotations

from adapters.driven.observable import Observable
from domain.models import (
    Audio,
    Bluetooth,
    Clipboard,
    Network,
    NightLight,
    NotificationFeed,
    TrayItem,
    Wallpaper,
    WorkspaceState,
)


class _LoggingMixin:
    _logger = None
    _name = "fallback"

    def _warn(self, message: str, **context) -> None:
        if self._logger is not None:
            self._logger.warning(self._name, message, **context)


class UnavailableAudioAdapter(_LoggingMixin, Observable[Audio]):
    def __init__(self, logger=None) -> None:
        super().__init__(Audio(ready=False))
        self._logger = logger
        self._name = "audio"

    def set_volume(self, percent: int) -> None:
        self._warn("no audio backend; ignoring set_volume", percent=percent)

    def set_muted(self, muted: bool) -> None:
        self._warn("no audio backend; ignoring set_muted", muted=muted)


class UnavailableBluetoothAdapter(_LoggingMixin, Observable[Bluetooth]):
    def __init__(self, logger=None) -> None:
        super().__init__(Bluetooth(available=False))
        self._logger = logger
        self._name = "bluetooth"

    def set_enabled(self, enabled: bool) -> None:
        self._warn("no bluetooth backend; ignoring set_enabled", enabled=enabled)


class UnavailableNetworkAdapter(_LoggingMixin, Observable[Network]):
    def __init__(self, logger=None) -> None:
        super().__init__(Network(available=False))
        self._logger = logger
        self._name = "network"
        self._failure_listeners: list = []

    def subscribe_failures(self, listener):
        self._failure_listeners.append(listener)
        return lambda: self._failure_listeners.remove(listener)

    def set_wifi_enabled(self, enabled: bool) -> None:
        self._warn("no network backend; ignoring set_wifi_enabled")

    def set_scanning(self, scanning: bool) -> None:
        self._warn("no network backend; ignoring set_scanning")

    def connect_to(self, name: str) -> None:
        self._warn("no network backend; ignoring connect_to", name=name)

    def connect_with_psk(self, name: str, psk: str) -> None:
        self._warn("no network backend; ignoring connect_with_psk", name=name)


class UnavailableNightLightAdapter(_LoggingMixin, Observable[NightLight]):
    def __init__(self, logger=None) -> None:
        super().__init__(NightLight(active=False))
        self._logger = logger
        self._name = "nightlight"

    def set_active(self, active: bool) -> None:
        self._warn("no night-light backend; ignoring set_active", active=active)

    def refresh(self) -> None:
        pass


class UnavailableClipboardAdapter(_LoggingMixin, Observable[Clipboard]):
    def __init__(self, logger=None) -> None:
        super().__init__(Clipboard(state="unavailable"))
        self._logger = logger
        self._name = "clipboard"

    def copy(self, text: str) -> None:
        self._warn("no clipboard backend; ignoring copy")

    def remove(self, text: str) -> None:
        pass

    def clear(self) -> None:
        pass


class UnavailableTrayAdapter(_LoggingMixin, Observable[tuple[TrayItem, ...]]):
    def __init__(self, logger=None) -> None:
        super().__init__(())
        self._logger = logger
        self._name = "tray"

    def activate(self, item_id: str) -> None:
        self._warn("no tray backend; ignoring activate", id=item_id)

    def secondary_activate(self, item_id: str) -> None:
        pass

    def context_menu(self, item_id: str) -> None:
        pass


class UnavailableNotificationFeedAdapter(_LoggingMixin, Observable[NotificationFeed]):
    def __init__(self, logger=None) -> None:
        super().__init__(NotificationFeed())
        self._logger = logger
        self._name = "notifications"

    def dismiss(self, key: int) -> None:
        pass

    def expire(self, key: int) -> None:
        pass

    def invoke_default(self, key: int) -> bool:
        return False

    def has_default_action(self, key: int) -> bool:
        return False

    def pause(self, key: int) -> bool:
        return False

    def resume(self, key: int) -> bool:
        return False

    def clear_history(self) -> None:
        self.notify(NotificationFeed())

    def dismiss_all(self) -> None:
        self.notify(NotificationFeed())


class UnavailableWallpaperAdapter(_LoggingMixin, Observable[Wallpaper]):
    def __init__(self, logger=None) -> None:
        super().__init__(Wallpaper())
        self._logger = logger
        self._name = "wallpaper"

    def refresh(self) -> None:
        pass

    def set(self, path: str) -> None:
        self._warn("no wallpaper backend; ignoring set", path=path)

    def next(self) -> None:
        pass

    def previous(self) -> None:
        pass

    def random(self) -> None:
        pass


class UnavailableWorkspaceAdapter(_LoggingMixin, Observable[WorkspaceState]):
    def __init__(self, logger=None, count: int = 10) -> None:
        super().__init__(WorkspaceState(count=count))
        self._logger = logger
        self._name = "workspaces"

    def focus(self, workspace_id: int) -> None:
        self._warn("no compositor connection; ignoring focus", workspace=workspace_id)
