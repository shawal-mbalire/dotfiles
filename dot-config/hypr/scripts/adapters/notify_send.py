"""``Notifier`` adapter: desktop notifications via ``notify-send``."""

from __future__ import annotations

import shutil
import subprocess


class NotifySend:
    def __init__(self, app: str = "hypr", urgency: str = "normal") -> None:
        self._app = app
        self._urgency = urgency

    def is_available(self) -> bool:
        return shutil.which("notify-send") is not None

    def notify(
        self,
        summary: str,
        body: str,
        urgency: str = "normal",
        icon: str | None = None,
    ) -> None:
        if not self.is_available():
            return
        argv = [
            "notify-send",
            "-a",
            self._app,
            "-u",
            urgency or self._urgency,
            summary,
            body,
        ]
        if icon:
            argv.extend(["-i", icon])
        subprocess.run(argv, check=False)
