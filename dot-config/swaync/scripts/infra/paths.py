"""Infrastructure: output path resolution.

The only place that decides where the generated artifacts live.
"""

from __future__ import annotations

import os
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent


def output_dir() -> Path:
    override = os.environ.get("SWAYNC_OUTPUT_DIR")
    if override:
        return Path(override).expanduser()
    return PROJECT_ROOT
