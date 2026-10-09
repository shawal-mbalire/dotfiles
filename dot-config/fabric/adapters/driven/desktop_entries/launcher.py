"""DesktopEntriesLaunchAdapter — LaunchPort over the freedesktop database.

Discovers ``.desktop`` entries on the XDG data paths, maps them to domain
``AppEntry`` models (the DTO boundary), and launches them as detached processes.
No ``ls`` and no shell — pure Python over the filesystem.
"""

from __future__ import annotations

import subprocess
from pathlib import Path

from adapters.driven.desktop_entries.icons import icon_search_roots, resolve_icon
from adapters.driven.desktop_entries.parser import (
    RawEntry,
    build_launch_argv,
    is_displayable,
    parse_desktop_entry,
)
from adapters.driven.observable import Observable
from domain.models import AppEntry


class DesktopEntriesLaunchAdapter(Observable[tuple[AppEntry, ...]]):
    def __init__(
        self,
        *,
        data_home: Path,
        data_dirs: tuple[Path, ...],
        terminal_command: tuple[str, ...] = ("kitty", "-e"),
        logger=None,
    ) -> None:
        super().__init__(())
        self._data_home = data_home
        self._data_dirs = data_dirs
        self._terminal_command = terminal_command
        self._logger = logger
        self._entries: dict[str, RawEntry] = {}
        self._icons = icon_search_roots(data_home, data_dirs)

    def start(self) -> None:
        self.refresh()

    def stop(self) -> None:
        pass

    # ── scanning ──────────────────────────────────────────────────────────
    def refresh(self) -> None:
        apps: list[AppEntry] = []
        entries: dict[str, RawEntry] = {}
        for directory in self._application_dirs():
            if not directory.is_dir():
                continue
            for path in sorted(directory.rglob("*.desktop")):
                entry_id = self._entry_id(path, directory)
                if entry_id in entries:
                    continue
                raw = self._read_entry(path, entry_id)
                if raw is None or not is_displayable(raw):
                    continue
                entries[entry_id] = raw
                apps.append(
                    AppEntry(
                        id=entry_id,
                        name=raw.name,
                        generic_name=raw.generic_name,
                        comment=raw.comment,
                        keywords=raw.keywords,
                        icon_source=resolve_icon(raw.icon, self._icons),
                    )
                )
        apps.sort(key=lambda app: app.name.lower())
        self._entries = entries
        self.notify(tuple(apps))

    def _application_dirs(self) -> tuple[Path, ...]:
        dirs = [self._data_home / "applications"]
        dirs.extend(base / "applications" for base in self._data_dirs)
        return tuple(dict.fromkeys(dirs))

    def _entry_id(self, path: Path, directory: Path) -> str:
        return str(path.relative_to(directory)).replace("/", "-")

    def _read_entry(self, path: Path, entry_id: str) -> RawEntry | None:
        try:
            text = path.read_text(errors="replace")
        except OSError as exc:
            self._warn("cannot read entry", path=str(path), error=str(exc))
            return None
        return parse_desktop_entry(text, entry_id)

    # ── launching ─────────────────────────────────────────────────────────
    def launch(self, app_id: str) -> bool:
        raw = self._entries.get(app_id)
        if raw is None:
            self._warn("unknown desktop entry", id=app_id)
            return False
        argv = build_launch_argv(
            raw.exec_line, terminal=raw.terminal, terminal_command=self._terminal_command
        )
        if not argv:
            self._warn("empty argv for entry", id=app_id)
            return False
        try:
            subprocess.Popen(  # noqa: S603 - argv is parsed from trusted .desktop files
                argv,
                start_new_session=True,
                close_fds=True,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except OSError as exc:
            self._warn("launch failed", id=app_id, error=str(exc))
            return False
        return True

    def _warn(self, message: str, **context) -> None:
        if self._logger is not None:
            self._logger.warning("launcher", message, **context)
