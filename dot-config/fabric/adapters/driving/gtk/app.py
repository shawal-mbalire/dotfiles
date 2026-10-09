"""GtkShell — the GTK composition of the driving adapters.

Builds the bar, overlay windows, and the native wallpaper background; applies
the theme; serves the control socket for keybinds; and ticks the clock. No
business logic lives here.
"""

# ruff: noqa: E402
from __future__ import annotations

from pathlib import Path

import gi

gi.require_version("Gtk", "4.0")
from gi.repository import Gio, GLib, Gtk  # noqa: F401

from adapters.driving.gtk.bar import BarWindow
from adapters.driving.gtk.control_socket import ControlSocket
from adapters.driving.gtk.layer_shell import gtk_available, layer_shell_available
from adapters.driving.gtk.overlays import (
    AppLauncherWindow,
    ClipboardWindow,
    ControlCenterWindow,
)
from adapters.driving.gtk.theme import apply_css, build_css
from adapters.driving.gtk.wallpaper import WallpaperBackground


class GtkShell:
    def __init__(
        self,
        *,
        view_model,
        config,
        logger,
        lifetime,
        theme,
        volume,
        brightness,
        nightlight,
        bluetooth,
        workspaces,
        wifi,
        launcher,
        clipboard_port,
        clipboard,
        wallpaper_store,
        wallpaper,
        control_path: Path,
    ) -> None:
        if not gtk_available():
            raise RuntimeError("GTK4 is not available")
        if not layer_shell_available():
            raise RuntimeError("gtk4-layer-shell is not available")

        self._vm = view_model
        self._config = config
        self._logger = logger
        self._lifetime = lifetime
        self._theme = theme
        self._volume = volume
        self._brightness = brightness
        self._nightlight = nightlight
        self._bluetooth = bluetooth
        self._workspaces = workspaces
        self._wifi = wifi
        self._launcher = launcher
        self._clipboard_port = clipboard_port
        self._clipboard = clipboard
        self._wallpaper_store = wallpaper_store
        self._wallpaper = wallpaper
        self._control_path = control_path

        self._app = Gtk.Application(
            application_id="org.fabric.Shell", flags=Gio.ApplicationFlags.NON_UNIQUE
        )
        self._app.connect("activate", self._activate)
        self._bar: BarWindow | None = None
        self._control: ControlSocket | None = None
        self._background: WallpaperBackground | None = None

    def run(self) -> int:
        self._lifetime.install_signal_handlers()
        return self._app.run()

    # ── wiring (the only construction site on the driving side) ───────────
    def _activate(self, app: Gtk.Application) -> None:
        apply_css(build_css(self._theme.current))

        self._bar = BarWindow(
            self._vm,
            height=self._config.bar_height,
            volume=self._volume,
            brightness=self._brightness,
            nightlight=self._nightlight,
            bluetooth=self._bluetooth,
            workspaces=self._workspaces,
            logger=self._logger,
        )
        app.add_window(self._bar)
        self._bar.present()

        self._control_center = ControlCenterWindow(
            self._vm,
            theme=self._theme,
            volume=self._volume,
            brightness=self._brightness,
            wifi=self._wifi,
            bluetooth=self._bluetooth,
            nightlight=self._nightlight,
        )
        app.add_window(self._control_center)

        self._menu = AppLauncherWindow(self._launcher)
        app.add_window(self._menu)

        self._clipboard_window = ClipboardWindow(self._clipboard_port, self._clipboard)
        app.add_window(self._clipboard_window)

        self._background = WallpaperBackground(app, self._wallpaper_store, logger=self._logger)

        def toggle(window: Gtk.Window):
            def do_toggle() -> None:
                if window.get_visible():
                    window.set_visible(False)
                else:
                    window.set_visible(True)
                    window.grab_focus()  # type: ignore[attr-defined]

            return do_toggle

        handlers = {
            "toggle bar": self._toggle_bar,
            "toggle control-center": toggle(self._control_center),
            "toggle menu": toggle(self._menu),
            "toggle clipboard": toggle(self._clipboard_window),
            "wallpaper next": self._wallpaper.next,
            "wallpaper prev": self._wallpaper.previous,
            "wallpaper random": self._wallpaper.random,
            "quit": app.quit,
        }
        self._control = ControlSocket(self._control_path, handlers)
        self._control.start()

        self._theme.subscribe(lambda _theme: apply_css(build_css(_theme)))
        self._lifetime.on_exit(self._shutdown)
        GLib.timeout_add_seconds(1, self._tick)

        self._logger.info("shell", "GTK shell started")

    def _toggle_bar(self) -> None:
        target = not self._bar.get_visible() if self._bar else False
        for window in self._app.get_windows():
            if isinstance(window, BarWindow):
                window.set_visible(target)

    def _tick(self) -> bool:
        if self._bar is not None:
            self._bar.refresh()
        return True

    def _shutdown(self, _reason) -> None:
        if self._control is not None:
            self._control.stop()
        if self._background is not None:
            self._background.close()
        self._vm.close()
        self._logger.info("shell", "shutting down")
