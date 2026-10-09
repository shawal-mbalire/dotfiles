"""Overlay windows: control center, app launcher, clipboard history.

Each window renders domain state and emits intents into the workflows. They get
ports/workflows injected; they never construct an adapter.
"""

# ruff: noqa: E402
from __future__ import annotations

import gi

gi.require_version("Gtk", "4.0")
from gi.repository import GLib, Gtk

from adapters.driving.gtk.layer_shell import setup_overlay_window
from domain.workflows.desktop import ClipboardWorkflow, LauncherWorkflow
from domain.workflows.media import BrightnessWorkflow, VolumeWorkflow
from domain.workflows.theme import ThemeWorkflow


class OverlayWindow(Gtk.Window):
    def __init__(
        self, namespace: str, width: int, height: int, *, anchor_right: bool = False
    ) -> None:
        super().__init__()
        setup_overlay_window(
            self, namespace=namespace, width=width, height=height, anchor_right=anchor_right
        )
        self.connect("close-request", self._on_close_request)

    def _on_close_request(self) -> bool:
        self.set_visible(False)
        return True  # keep the window alive; just hide it

    def present(self) -> None:
        self.set_visible(True)


class ControlCenterWindow(OverlayWindow):
    def __init__(
        self,
        view_model,
        *,
        theme: ThemeWorkflow,
        volume: VolumeWorkflow,
        brightness: BrightnessWorkflow,
        wifi,
        bluetooth,
        nightlight,
    ) -> None:
        super().__init__("fabric:controlcenter", 320, 480)
        self._vm = view_model
        self._theme = theme
        self._volume = volume
        self._brightness = brightness
        self._wifi = wifi
        self._bluetooth = bluetooth
        self._nightlight = nightlight
        self._updating = False

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.add_css_class("fabric-overlay")

        title = Gtk.Label(label="Control Center")
        title.add_css_class("fabric-title")
        box.append(title)

        self._dark_switch = self._toggle_row(box, "Dark mode")
        self._dark_switch.connect("toggled", self._on_dark)

        self._wifi_button = self._toggle_row(box, "Wi-Fi")
        self._wifi_button.connect("toggled", self._on_wifi)

        self._bt_button = self._toggle_row(box, "Bluetooth")
        self._bt_button.connect("toggled", self._on_bt)

        self._night_button = self._toggle_row(box, "Night light")
        self._night_button.connect("toggled", self._on_night)

        self._volume_scale = self._slider(box, "Volume", 0, 150)
        self._volume_scale.connect("value-changed", self._on_volume)

        self._brightness_scale = self._slider(box, "Brightness", 0, 100)
        self._brightness_scale.connect("value-changed", self._on_brightness)

        self._status = Gtk.Label()
        self._status.add_css_class("fabric-muted")
        box.append(self._status)

        self.set_child(box)
        self._vm.on_change(self._on_change)
        self.refresh()

    def _toggle_row(self, parent: Gtk.Box, label: str) -> Gtk.Switch:
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        text = Gtk.Label(label=label)
        text.add_css_class("fabric-indicator-label")
        row.append(text)
        switch = Gtk.Switch()
        switch.set_halign(Gtk.Align.END)
        switch.set_hexpand(True)
        row.append(switch)
        parent.append(row)
        return switch

    def _slider(self, parent: Gtk.Box, label: str, low: int, high: int) -> Gtk.Scale:
        text = Gtk.Label(label=label)
        text.add_css_class("fabric-muted")
        parent.append(text)
        scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, low, high, 1)
        scale.set_draw_value(True)
        parent.append(scale)
        return scale

    # ── intents ───────────────────────────────────────────────────────────
    def _on_dark(self, switch: Gtk.Switch) -> None:
        if not self._updating:
            self._theme.set_dark(switch.get_active())

    def _on_wifi(self, switch: Gtk.Switch) -> None:
        if not self._updating:
            self._wifi.set_wifi_enabled(switch.get_active())

    def _on_bt(self, switch: Gtk.Switch) -> None:
        if not self._updating:
            self._bluetooth.set_enabled(switch.get_active())

    def _on_night(self, switch: Gtk.Switch) -> None:
        if not self._updating:
            self._nightlight.set_active(switch.get_active())

    def _on_volume(self, scale: Gtk.Scale) -> None:
        if not self._updating:
            self._volume.set_volume(int(scale.get_value()))

    def _on_brightness(self, scale: Gtk.Scale) -> None:
        if not self._updating:
            self._brightness.set_percent(int(scale.get_value()))

    # ── rendering ─────────────────────────────────────────────────────────
    def _on_change(self) -> None:
        GLib.idle_add(self._refresh_idle)

    def _refresh_idle(self) -> bool:
        self.refresh()
        return False

    def refresh(self) -> None:
        model = self._vm.control_center_model()
        fields = model.fields
        self._updating = True
        try:
            self._dark_switch.set_active(self._vm.theme.dark)
            self._wifi_button.set_active(bool(fields.get("wifi_enabled")))
            self._bt_button.set_active(bool(fields.get("bluetooth_enabled")))
            self._night_button.set_active(bool(fields.get("night_light_active")))
            self._volume_scale.set_value(float(fields.get("volume", 0)))
            self._brightness_scale.set_value(float(fields.get("brightness", 0)))
            self._status.set_text(model.network_status)
        finally:
            self._updating = False


class AppLauncherWindow(OverlayWindow):
    def __init__(self, launcher: LauncherWorkflow) -> None:
        super().__init__("fabric:menu", 460, 440)
        self._launcher = launcher
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.add_css_class("fabric-overlay")
        self._entry = Gtk.SearchEntry()
        self._entry.set_placeholder_text("Search apps…")
        box.append(self._entry)
        self._list = Gtk.ListBox()
        box.append(self._list)
        self.set_child(box)
        self._entry.connect("search-changed", lambda _w: self.refresh())
        self._entry.connect("activate", lambda _w: self._launch_first())
        self.refresh()

    def refresh(self) -> None:
        while (row := self._list.get_first_child()) is not None:
            self._list.remove(row)
        for app in self._launcher.search(self._entry.get_text()):
            row = Gtk.ListBoxRow()
            label = Gtk.Label(label=app.name, xalign=0)
            row.set_child(label)
            row.app_id = app.id  # type: ignore[attr-defined]
            self._list.append(row)

    def present(self) -> None:
        super().present()
        self._entry.grab_focus()

    def _launch_first(self) -> None:
        row = self._list.get_first_child()
        if row is not None:
            app_id = getattr(row, "app_id", "")
            if app_id:
                self._launcher.launch(app_id)
                self.set_visible(False)


class ClipboardWindow(OverlayWindow):
    def __init__(self, clipboard_port, clipboard: ClipboardWorkflow) -> None:
        super().__init__("fabric:clipboard", 420, 460)
        self._port = clipboard_port
        self._clipboard = clipboard
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.add_css_class("fabric-overlay")
        self._entry = Gtk.SearchEntry()
        self._entry.set_placeholder_text("Search clipboard…")
        box.append(self._entry)
        self._list = Gtk.ListBox()
        box.append(self._list)
        self.set_child(box)
        self._entry.connect("search-changed", lambda _w: self.refresh())
        self._port.subscribe(lambda _state: GLib.idle_add(self._refresh_idle))
        self.refresh()

    def _refresh_idle(self) -> bool:
        self.refresh()
        return False

    def refresh(self) -> None:
        while (row := self._list.get_first_child()) is not None:
            self._list.remove(row)
        query = self._entry.get_text().strip().lower()
        for text in self._port.read().history:
            if query and query not in text.lower():
                continue
            preview = " ".join(text.split())
            row = Gtk.ListBoxRow()
            row.set_child(Gtk.Label(label=preview[:120], xalign=0))
            row.text = text  # type: ignore[attr-defined]
            self._list.append(row)

    def present(self) -> None:
        super().present()
        self._entry.grab_focus()
