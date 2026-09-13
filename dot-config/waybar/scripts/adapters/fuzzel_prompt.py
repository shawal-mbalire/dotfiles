"""Driving adapter: fuzzel menu used by the interactive workflows."""

from __future__ import annotations

import shutil
import subprocess


class FuzzelPrompt:
    def __init__(self, theme: str = "", command: str = "fuzzel") -> None:
        self._theme = theme
        self._command = command

    def is_available(self) -> bool:
        return shutil.which(self._command) is not None

    def choose(self, lines: list[str], prompt: str) -> str | None:
        if not self.is_available():
            return None

        command = [self._command, "--dmenu", "-p", prompt]
        if self._theme:
            command.extend(["--config", self._theme])

        try:
            result = subprocess.run(
                command,
                input="\n".join(lines),
                capture_output=True,
                text=True,
                check=False,
            )
        except OSError:
            return None
        chosen = result.stdout.strip()
        return chosen or None
