"""DirectoryWallpaperStore — WallpaperPort over a wallpaper directory.

Holds the scanned set and the current selection; ``set`` simply publishes the
new ``current``. What "apply" means is the driving side's business — in this
shell, Fabric's own GTK background windows render it (see
``adapters/driving/gtk/wallpaper.py``). No hyprpaper, no CLI.
"""

from __future__ import annotations

import random
from collections.abc import Callable
from pathlib import Path

from adapters.driven.observable import Observable
from domain import logic
from domain.models import Wallpaper


class DirectoryWallpaperStore(Observable[Wallpaper]):
    def __init__(
        self,
        directory: Path,
        *,
        logger=None,
        unit_random: Callable[[], float] = random.random,
    ) -> None:
        super().__init__(Wallpaper())
        self._directory = Path(directory)
        self._logger = logger
        self._unit_random = unit_random
        self.refresh()

    # ── commands ──────────────────────────────────────────────────────────
    def refresh(self) -> None:
        wallpapers = self._list_wallpapers()
        current = self.read().current if self.read().current in wallpapers else ""
        self.notify(Wallpaper(wallpapers=tuple(wallpapers), current=current))

    def set(self, path: str) -> None:
        if path not in self.read().wallpapers:
            self._warn("wallpaper is not in the list", path=path)
            return
        self.notify(Wallpaper(wallpapers=self.read().wallpapers, current=path))

    def next(self) -> None:
        self._step(1)

    def previous(self) -> None:
        self._step(-1)

    def random(self) -> None:
        state = self.read()
        if not state.wallpapers:
            return
        index = logic.random_index(len(state.wallpapers), self._unit_random())
        self.set(state.wallpapers[index])

    # ── internals ─────────────────────────────────────────────────────────
    def _step(self, direction: int) -> None:
        state = self.read()
        if not state.wallpapers:
            return
        current = state.wallpapers.index(state.current) if state.current in state.wallpapers else -1
        index = (
            logic.next_index(current, len(state.wallpapers))
            if direction > 0
            else logic.prev_index(current, len(state.wallpapers))
        )
        self.set(state.wallpapers[index])

    def _list_wallpapers(self) -> list[str]:
        directory = self._directory
        if not directory.is_dir():
            return []
        try:
            names = sorted(p.name for p in directory.iterdir() if p.is_file())
        except OSError as exc:
            self._warn("cannot list wallpapers", error=str(exc))
            return []
        return [
            path
            for path in (logic.parse_wallpaper_listing(name, str(directory)) for name in names)
            if path
        ]

    def _warn(self, message: str, **context) -> None:
        if self._logger is not None:
            self._logger.warning("wallpaper", message, **context)
