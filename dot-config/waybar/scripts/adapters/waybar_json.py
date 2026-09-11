"""Presentation adapter: domain ``ModuleOutput`` -> waybar JSON."""

from __future__ import annotations

import json

from domain.models import ModuleOutput

EMPTY_TEXT = "—"


def render(output: ModuleOutput) -> str:
    payload: dict[str, str] = {"text": output.text, "tooltip": output.tooltip}
    if output.css_class:
        payload["class"] = output.css_class
    return json.dumps(payload, ensure_ascii=False)


def render_fallback(message: str = "") -> str:
    return json.dumps({"text": EMPTY_TEXT, "tooltip": message}, ensure_ascii=False)
