"""``Notifier`` adapter backed by ``notify-send``."""

from __future__ import annotations

import shutil
import subprocess

from domain.models import Urgency


class NotifySend:
    def __init__(
        self,
        app: str,
        default_urgency: str = "normal",
        command: str = "notify-send",
    ) -> None:
        self._app = app
        self._default_urgency = default_urgency
        self._command = command

    def notify(self, summary: str, body: str, urgency: Urgency | None = None) -> None:
        if shutil.which(self._command) is None:
            return
        level = urgency.value if urgency is not None else self._default_urgency
        try:
            subprocess.run(
                [self._command, "-a", self._app, "-u", level, summary, body],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except OSError:
            return
