"""Headless text presenter — renders the shell in the terminal.

Proves the whole wiring end-to-end without a display or GTK, and is the smoke
test used by ``just render`` / ``just check``.
"""

from __future__ import annotations

import sys
import time
from typing import TextIO

from adapters.driving.view_model import ShellViewModel


class TextPresenter:
    def __init__(self, view_model: ShellViewModel, stream: TextIO | None = None) -> None:
        self._vm = view_model
        self._stream = stream or sys.stdout
        self._dirty = True
        self._vm.on_change(self._mark_dirty)

    def _mark_dirty(self) -> None:
        self._dirty = True

    def render(self) -> str:
        model = self._vm.bar_model()
        left = " ".join(
            f"[{pill.id}]" if pill.active else str(pill.id)
            for pill in model.workspaces
            if pill.visible
        )
        tray = f" tray:{len(model.tray)}" if model.tray else ""
        indicators = "  ".join(f"{seg.glyph}{seg.label}" for seg in model.indicators if seg.visible)
        clock = f"{model.clock.date_text} {model.clock.time_text}"
        return f"{left}{tray}   {clock}   {indicators}"

    def run(self, seconds: float, tick_interval: float = 1.0) -> None:
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            self._stream.write(self.render() + "\n")
            self._stream.flush()
            time.sleep(tick_interval)
