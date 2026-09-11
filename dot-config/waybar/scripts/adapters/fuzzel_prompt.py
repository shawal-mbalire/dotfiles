"""Driving adapter: fuzzel menu used by the interactive workflows."""

from __future__ import annotations

import shutil
import subprocess


class FuzzelPrompt:
    def __init__(self, theme: str = "") -> None:
        self._theme = theme

    def is_available(self) -> bool:
        return shutil.which("fuzzel") is not None

    def choose(self, lines: list[str], prompt: str) -> str | None:
        if not self.is_available():
            return None

        command = ["fuzzel", "--dmenu", "-p", prompt]
        if self._theme:
            command.extend(["--config", self._theme])

        result = subprocess.run(
            command,
            input="\n".join(lines),
            capture_output=True,
            text=True,
            check=False,
        )
        chosen = result.stdout.strip()
        return chosen or None
