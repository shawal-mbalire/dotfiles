"""The GTK4 layer-shell bar.

Renders the ``BarModel`` and emits user intents into the workflows. It never
touches an adapter directly — only the view model and the workflow ports.
"""

# ruff: noqa: E402
from __future__ import annotations

import gi

gi.require_version("Gtk", "4.0")
from gi.repository import GLib, Gtk

from adapters.driving.gtk.layer_shell import setup_bar_window
from domain import constants as C
from domain.models import Segment
from domain.workflows.connectivity import BluetoothWorkflow
from domain.workflows.media import BrightnessWorkflow, NightLightWorkflow, VolumeWorkflow


class BarWindow(Gtk.Window):
    def __init__(
        self,
        view_model,
        *,
        height: int,
        volume: VolumeWorkflow,
        brightness: BrightnessWorkflow,
        nightlight: NightLightWorkflow,
        bluetooth: BluetoothWorkflow,
        workspaces,
        logger=None,
    ) -> None:
        super().__init__()
        self._vm = view_model
        self._volume = volume
        self._brightness = brightness
        self._nightlight = nightlight
        self._bluetooth = bluetooth
        self._workspaces = workspaces
        self._logger = logger
        self._indicator_widgets: dict[str, tuple[Gtk.Label, Gtk.Label]] = {}

        setup_bar_window(self, height=height)
        self.set_child(self._build())
        self._vm.on_change(self._on_change)
        self.refresh()

    # ── construction ──────────────────────────────────────────────────────
    def _build(self) -> Gtk.Widget:
        center_box = Gtk.CenterBox(orientation=Gtk.Orientation.HORIZONTAL)
        center_box.add_css_class("fabric-bar")

        left = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=C.BAR_LEFT_SPACING)
        self._workspace_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        left.append(self._workspace_box)
        self._tray_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=C.TRAY_SPACING)
        left.append(self._tray_box)
        center_box.set_start_widget(left)

        clock = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=C.CLOCK_SPACING)
        self._date_label = Gtk.Label()
        self._date_label.add_css_class("fabric-clock-date")
        self._time_label = Gtk.Label()
        self._time_label.add_css_class("fabric-clock-time")
        clock.append(self._date_label)
        clock.append(self._time_label)
        center_box.set_center_widget(clock)

        right = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=C.BAR_RIGHT_SPACING)
        for segment in self._vm.bar_model().indicators:
            right.append(self._indicator(segment))
        center_box.set_end_widget(right)
        return center_box

    def _indicator(self, segment: Segment) -> Gtk.Widget:
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        glyph = Gtk.Label()
        label = Gtk.Label()
        label.add_css_class("fabric-indicator-label")
        box.append(glyph)
        box.append(label)
        self._indicator_widgets[segment.key] = (glyph, label)
        self._wire_indicator(box, segment.key)
        return box

    def _wire_indicator(self, widget: Gtk.Widget, key: str) -> None:
        click = Gtk.GestureClick()
        click.connect("released", lambda *_: self._on_click(key))
        widget.add_controller(click)
        scroll = Gtk.EventControllerScroll.new(Gtk.EventControllerScrollFlags.VERTICAL)
        scroll.connect("scroll", lambda _c, _dx, dy: self._on_scroll(key, dy))
        widget.add_controller(scroll)

    # ── intents ───────────────────────────────────────────────────────────
    def _on_click(self, key: str) -> None:
        if key == "volume":
            self._volume.toggle_muted()
        elif key == "nightlight":
            self._nightlight.toggle()
        elif key == "bluetooth":
            self._bluetooth.toggle()

    def _on_scroll(self, key: str, dy: float) -> bool:
        step = -C.SCROLL_STEP if dy > 0 else C.SCROLL_STEP
        if key == "volume":
            self._volume.scroll(step)
        elif key == "brightness":
            self._brightness.scroll(step)
        return True

    def _focus_workspace(self, workspace_id: int) -> None:
        self._workspaces.focus(workspace_id)

    # ── rendering ─────────────────────────────────────────────────────────
    def _on_change(self) -> None:
        GLib.idle_add(self._refresh_idle)

    def _refresh_idle(self) -> bool:
        self.refresh()
        return False

    def refresh(self) -> None:
        model = self._vm.bar_model()
        self._date_label.set_text(model.clock.date_text)
        self._time_label.set_text(model.clock.time_text)
        self._render_workspaces(model)
        self._render_tray(model)
        for segment in model.indicators:
            widgets = self._indicator_widgets.get(segment.key)
            if widgets is None:
                continue
            glyph, label = widgets
            glyph.set_markup(
                f'<span foreground="{segment.glyph_color}">{_escape(segment.glyph)}</span>'
            )
            label.set_text(segment.label)
            label.set_visible(segment.label != "")
            if segment.max_label_width:
                label.set_max_width_chars(max(1, segment.max_label_width // 8))
                label.set_ellipsize(3)  # Pango.EllipsizeMode.END

    def _render_workspaces(self, model) -> None:
        while (child := self._workspace_box.get_first_child()) is not None:
            self._workspace_box.remove(child)
        for pill in model.workspaces:
            button = Gtk.Button(label=str(pill.id))
            button.add_css_class("fabric-workspace")
            if pill.active:
                button.add_css_class("active")
            button.set_visible(pill.visible)
            button.connect("clicked", lambda _b, wid=pill.id: self._focus_workspace(wid))
            self._workspace_box.append(button)

    def _render_tray(self, model) -> None:
        while (child := self._tray_box.get_first_child()) is not None:
            self._tray_box.remove(child)
        for item in model.tray:
            if item.icon and item.icon.startswith("/"):
                widget = Gtk.Image.new_from_file(item.icon)
                widget.set_pixel_size(C.TRAY_ICON_SIZE)
            else:
                widget = Gtk.Label()
                color = self._vm.theme.palette.subtext0
                widget.set_markup(f'<span foreground="{color}">{_escape(C.GLYPH_MISSING)}</span>')
            self._tray_box.append(widget)


def _escape(text: str) -> str:
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
