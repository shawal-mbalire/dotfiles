#!/usr/bin/env python3
"""Entry point shim for the display keybinding.

Kept at this path so ``HYPR_DISPLAY_TOGGLE`` and the keybinding keep working;
all logic lives in the domain/adapters via ``main.py``.
"""

from __future__ import annotations

import os
import sys

SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, SCRIPTS_DIR)

from main import main  # noqa: E402

if __name__ == "__main__":
    raise SystemExit(main([sys.argv[0], "display-toggle", *sys.argv[1:]]))
