"""ShellViewModel — subscribes to every port and exposes current view models.

This is driving-side plumbing: it does no rendering. Both the text presenter and
the GTK presenter subscribe here, so model construction is written once.
"""

from __future__ import annotations

from collections.abc import Callable
from datetime import datetime

from domain.constants import Theme
from domain.models import BarModel, ControlCenterModel
from domain.ports import (
    AudioPort,
    BatteryPort,
    BluetoothPort,
    BrightnessPort,
    ClockPort,
    NetworkPort,
    NightLightPort,
    NotificationFeedPort,
    TrayPort,
    WorkspacePort,
)
from domain.workflows.presentation import build_bar_model, build_control_center_model
from domain.workflows.theme import ThemeWorkflow

ChangeCallback = Callable[[], None]


class ShellViewModel:
    def __init__(
        self,
        *,
        theme: ThemeWorkflow,
        clock: ClockPort,
        workspaces: WorkspacePort,
        tray: TrayPort,
        nightlight: NightLightPort,
        network: NetworkPort,
        bluetooth: BluetoothPort,
        audio: AudioPort,
        brightness: BrightnessPort,
        battery: BatteryPort,
        notifications: NotificationFeedPort,
    ) -> None:
        self._theme_workflow = theme
        self._clock = clock
        self._workspaces = workspaces
        self._tray = tray
        self._nightlight = nightlight
        self._network = network
        self._bluetooth = bluetooth
        self._audio = audio
        self._brightness = brightness
        self._battery = battery
        self._notifications = notifications
        self._callbacks: list[ChangeCallback] = []
        self._unsubscribes = [
            source.subscribe(self._noop)
            for source in (
                workspaces,
                tray,
                nightlight,
                network,
                bluetooth,
                audio,
                brightness,
                battery,
                notifications,
            )
        ]

    @property
    def theme(self) -> Theme:
        return self._theme_workflow.current

    def _noop(self, _value: object) -> None:
        self._changed()

    def on_change(self, callback: ChangeCallback) -> None:
        self._callbacks.append(callback)

    def _changed(self) -> None:
        for callback in tuple(self._callbacks):
            callback()

    def bar_model(self, now: datetime | None = None) -> BarModel:
        return build_bar_model(
            theme=self.theme,
            workspaces=self._workspaces.read(),
            tray=self._tray.read(),
            now=now or self._clock.now(),
            nightlight=self._nightlight.read(),
            network=self._network.read(),
            bluetooth=self._bluetooth.read(),
            audio=self._audio.read(),
            brightness=self._brightness.read().percent,
            brightness_available=self._brightness.read().available,
            battery=self._battery.read(),
        )

    def control_center_model(self) -> ControlCenterModel:
        return build_control_center_model(
            theme=self.theme,
            battery=self._battery.read(),
            audio=self._audio.read(),
            brightness=self._brightness.read().percent,
            brightness_available=self._brightness.read().available,
            network=self._network.read(),
            history=self._notifications.read().history,
        )

    def close(self) -> None:
        for unsubscribe in self._unsubscribes:
            unsubscribe()
        self._unsubscribes.clear()
