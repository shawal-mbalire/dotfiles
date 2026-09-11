"""``CommandRunner`` adapter: run a shell command via subprocess."""

from __future__ import annotations

import shutil
import subprocess


class SubprocessCommands:
    def __init__(self, shell: str | None = None) -> None:
        self._shell = shell or shutil.which("sh") or "/bin/sh"

    def run(self, command: str) -> int:
        return subprocess.run([self._shell, "-c", command], check=False).returncode
