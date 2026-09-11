#!/usr/bin/env python3
"""Shared gammastep night-light state.

gammastep's `-O` is one-shot: it applies the temperature and exits, so a
process check can never tell whether the filter is active. We persist the
desired state in a file instead.
"""

from __future__ import annotations

import os
from pathlib import Path

# Kelvin: neutral is 6500K, lower is warmer. 3500K is a strong night light.
NIGHT_TEMP = 3500


def state_dir() -> Path:
    base = os.environ.get("XDG_STATE_HOME") or str(Path.home() / ".local" / "state")
    return Path(base) / "gammastep"


def state_file() -> Path:
    return state_dir() / "night"


def is_on() -> bool:
    return state_file().exists()


def set_on(on: bool) -> None:
    path = state_file()
    if on:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f"{NIGHT_TEMP}\n")
    else:
        path.unlink(missing_ok=True)
