import json

from adapters.waybar_json import render, render_fallback
from domain.models import ModuleOutput


def test_render_omits_empty_class():
    payload = json.loads(render(ModuleOutput(text="50%", tooltip="tip")))
    assert payload == {"text": "50%", "tooltip": "tip"}


def test_render_includes_class_when_set():
    payload = json.loads(render(ModuleOutput(text="x", tooltip="t", css_class="muted")))
    assert payload["class"] == "muted"


def test_render_preserves_nerd_font_glyphs():
    assert json.loads(render(ModuleOutput(text="\U000f057e")))["text"] == "\U000f057e"


def test_render_fallback_is_valid_json():
    payload = json.loads(render_fallback("boom"))
    assert payload["text"] == "—"
    assert payload["tooltip"] == "boom"
