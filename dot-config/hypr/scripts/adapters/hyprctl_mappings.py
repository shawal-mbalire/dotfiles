"""Pure mapping helpers: compositor payloads <-> domain models.

No I/O here, so these are trivially unit-testable.
"""

from __future__ import annotations

from domain.models import Monitor, MonitorRule


def parse_monitors(payload: list[dict]) -> list[Monitor]:
    """Map ``hyprctl -j monitors`` JSON into domain monitors."""
    return [
        Monitor(
            name=str(entry.get("name", "")),
            width=entry.get("width"),
            mirror_of=_clean_mirror(entry.get("mirrorOf")),
        )
        for entry in payload
    ]


def _clean_mirror(value: object) -> str | None:
    text = str(value or "").strip()
    if not text or text.lower() == "none":
        return None
    return text


def _render_value(value: object) -> str:
    if isinstance(value, str):
        return f'"{value}"'
    return str(value)


def rule_to_lua(rule: MonitorRule) -> str:
    """Serialize a flat monitor rule into an ``hl.monitor({...})`` call."""
    fields: list[tuple[str, object]] = [
        ("output", rule.output),
        ("mode", rule.mode),
        ("position", rule.position),
        ("scale", rule.scale),
    ]
    if rule.mirror:
        fields.append(("mirror", rule.mirror))

    rendered = ", ".join(f"{key} = {_render_value(value)}" for key, value in fields)
    return f"hl.monitor({{ {rendered} }})"
