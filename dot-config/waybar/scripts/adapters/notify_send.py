"""``Notifier`` adapter backed by ``notify-send``."""

from __future__ import annotations

import shutil
import subprocess


class NotifySend:
    def __init__(self, app: str, default_urgency: str = "normal") -> None:
        self._app = app
        self._default_urgency = default_urgency

    def notify(self, summary: str, body: str, urgency: str | None = None) -> None:
        if shutil.which("notify-send") is None:
            return
        subprocess.run(
            [
                "notify-send",
                "-a",
                self._app,
                "-u",
                urgency or self._default_urgency,
                summary,
                body,
            ],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
