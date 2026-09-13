"""``SentMarkerStore`` adapter: filesystem-backed notification markers.

Markers re-arm whenever the charging state changes, so each threshold fires
once per state change instead of on every invocation.
"""

from __future__ import annotations

from pathlib import Path

STATE_FILE = "state"
MARKER_SUFFIX = ".sent"


class SentMarkerStore:
    def __init__(self, directory: str | Path) -> None:
        self._directory = Path(directory)

    def reset_for_state(self, state: str) -> None:
        self._directory.mkdir(parents=True, exist_ok=True)
        state_file = self._directory / STATE_FILE
        previous = state_file.read_text().strip() if state_file.exists() else ""
        if previous == state:
            return
        for marker in self._directory.glob(f"*{MARKER_SUFFIX}"):
            marker.unlink(missing_ok=True)
        state_file.write_text(state)

    def claim(self, marker: str) -> bool:
        """Return True the first time a marker is claimed, then mark it sent."""
        marker_file = self._directory / f"{marker}{MARKER_SUFFIX}"
        if marker_file.exists():
            return False
        marker_file.touch()
        return True
