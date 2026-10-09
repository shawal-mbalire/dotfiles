"""Launcher, clipboard, and wallpaper workflows."""

from __future__ import annotations

from domain import logic
from domain.errors import NotFoundError, ValidationError
from domain.ports import (
    ClipboardPort,
    LaunchPort,
    LoggerPort,
    RandomPort,
    WallpaperPort,
)
from domain.result import Result, fail, ok


class LauncherWorkflow:
    def __init__(self, launcher: LaunchPort, logger: LoggerPort) -> None:
        self._launcher = launcher
        self._logger = logger

    def search(self, query: str):
        """Pure — no port call, just a filtered list for the view."""
        return logic.filter_apps(self._launcher.read(), query)

    def launch(self, app_id: str) -> Result[str]:
        known = {app.id for app in self._launcher.read()}
        if app_id not in known:
            return fail(NotFoundError("unknown desktop entry", context={"id": app_id}))
        if not self._launcher.launch(app_id):
            return fail(NotFoundError("desktop entry failed to launch", context={"id": app_id}))
        self._logger.info("launcher", "launched", id=app_id)
        return ok(app_id)


class ClipboardWorkflow:
    def __init__(self, clipboard: ClipboardPort, logger: LoggerPort) -> None:
        self._clipboard = clipboard
        self._logger = logger

    def copy(self, text: str) -> Result[str]:
        if not logic.is_usable_text(text):
            return fail(ValidationError("clipboard text is not usable"))
        self._clipboard.copy(text)
        return ok(text)

    def remove(self, text: str) -> Result[str]:
        self._clipboard.remove(text)
        return ok(text)

    def clear(self) -> Result[bool]:
        self._clipboard.clear()
        return ok(True)


class WallpaperWorkflow:
    def __init__(self, wallpaper: WallpaperPort, random: RandomPort, logger: LoggerPort) -> None:
        self._wallpaper = wallpaper
        self._random = random
        self._logger = logger

    def _apply_index(self, index: int) -> Result[str]:
        state = self._wallpaper.read()
        if not state.wallpapers or index < 0:
            return fail(NotFoundError("no wallpapers available"))
        path = state.wallpapers[index]
        self._wallpaper.set(path)
        return ok(path)

    def refresh(self) -> Result[bool]:
        self._wallpaper.refresh()
        return ok(True)

    def next(self) -> Result[str]:
        state = self._wallpaper.read()
        current = state.wallpapers.index(state.current) if state.current in state.wallpapers else -1
        return self._apply_index(logic.next_index(current, len(state.wallpapers)))

    def previous(self) -> Result[str]:
        state = self._wallpaper.read()
        current = state.wallpapers.index(state.current) if state.current in state.wallpapers else 0
        return self._apply_index(logic.prev_index(current, len(state.wallpapers)))

    def random(self) -> Result[str]:
        state = self._wallpaper.read()
        return self._apply_index(logic.random_index(len(state.wallpapers), self._random.random()))

    def set(self, path: str) -> Result[str]:
        if path not in self._wallpaper.read().wallpapers:
            return fail(NotFoundError("wallpaper is not in the list", context={"path": path}))
        self._wallpaper.set(path)
        return ok(path)
