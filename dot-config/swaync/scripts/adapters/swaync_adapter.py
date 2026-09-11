"""Adapter: writes the domain models as swaync's config.json and style.css.

Implements the ``ConfigWriter`` and ``StyleWriter`` ports. Paths are injected by
the composition root; this adapter never reads the environment.
"""

from __future__ import annotations

import os
from pathlib import Path

from domain.models import StyleSheet, SwayncConfig

from adapters import swaync_mappings as mappings


class SwayncArtifactWriter:
    def __init__(self, config_path: Path | str, style_path: Path | str) -> None:
        self._config_path = Path(config_path)
        self._style_path = Path(style_path)

    @staticmethod
    def _write_atomic(path: Path, text: str) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        temporary = path.with_suffix(path.suffix + ".tmp")
        temporary.write_text(text, encoding="utf-8")
        os.replace(temporary, path)

    def write_config(self, config: SwayncConfig) -> None:
        self._write_atomic(self._config_path, mappings.config_to_json(config))

    def write_style(self, sheet: StyleSheet) -> None:
        self._write_atomic(self._style_path, mappings.stylesheet_to_css(sheet))
