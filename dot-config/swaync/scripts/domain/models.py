"""Pure domain models for the swaync configuration generator.

Reusable building blocks (colors, style components, buttons, widgets and the
panel config) live here. No imports outside the standard library: the domain
never depends on a framework, adapter, or the file system.
"""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from dataclasses import dataclass, field
from enum import StrEnum


class ButtonKind(StrEnum):
    """How swaync renders and drives a grid button."""

    NORMAL = "normal"
    TOGGLE = "toggle"


class ImageVisibility(StrEnum):
    """When swaync shows a notification image."""

    ALWAYS = "always"
    WHEN_AVAILABLE = "when-available"
    NEVER = "never"


class AlbumArt(StrEnum):
    """How the mpris widget shows album art."""

    ALWAYS = "always"
    WHEN_AVAILABLE = "when-available"
    NEVER = "never"


@dataclass(frozen=True)
class Color:
    """A named palette entry, reusable as ``@name`` in generated CSS."""

    name: str
    hex: str

    @classmethod
    def from_hex(cls, name: str, value: str) -> Color:
        return cls(name=name, hex=value.lstrip("#").lower())

    def ref(self) -> str:
        """GTK CSS reference to the ``@define-color`` name."""
        return f"@{self.name}"

    def literal(self) -> str:
        """Literal ``#rrggbb`` value for the ``@define-color`` declaration."""
        return f"#{self.hex}"

    def alpha(self, amount: float) -> str:
        """Translucent reference, e.g. ``alpha(@surface0, 0.5)``."""
        return f"alpha({self.ref()}, {amount:g})"


@dataclass(frozen=True)
class DesignTokens:
    """The pill design language, resolved to CSS values.

    Shapes, radii, translucency and transitions are shared by every container
    and button so swaync matches the waybar pill language.
    """

    radius_pill: str
    radius_card: str
    radius_inner: str
    radius_small: str
    transition: str
    field_background: str
    field_border: str
    hover_border: str
    card_background: str
    card_border: str
    card_shadow: str
    glow_blur: str
    grid_button_width: str
    grid_button_height: str
    divider: str
    clear_button_width: str


@dataclass(frozen=True)
class CssDeclaration:
    """A single ``property: value`` pair."""

    prop: str
    value: str


@dataclass(frozen=True)
class CssComponent:
    """A reusable style component: one rule with one or more selectors."""

    name: str
    selectors: tuple[str, ...]
    declarations: tuple[CssDeclaration, ...]
    section: str | None = None


@dataclass(frozen=True)
class StyleSheet:
    """The whole generated stylesheet: palette, design tokens and components."""

    palette: tuple[Color, ...]
    tokens: tuple[CssDeclaration, ...]
    components: tuple[CssComponent, ...]


@dataclass(frozen=True)
class Button:
    """A reusable buttons-grid action."""

    label: str
    command: str
    kind: ButtonKind = ButtonKind.NORMAL
    active: bool = False
    update_command: str | None = None

    @classmethod
    def toggle(
        cls,
        label: str,
        command: str,
        update_command: str,
        active: bool = False,
    ) -> Button:
        return cls(
            label=label,
            command=command,
            kind=ButtonKind.TOGGLE,
            active=active,
            update_command=update_command,
        )

    @classmethod
    def action(cls, label: str, command: str) -> Button:
        return cls(label=label, command=command)


@dataclass(frozen=True)
class Widget:
    """A control-center widget, optionally a named instance (e.g. clearbar)."""

    type: str
    options: Mapping[str, object] = field(default_factory=dict)
    instance: str | None = None

    def key(self) -> str:
        """The identifier swaync uses in ``widgets`` and ``widget-config``."""
        return f"{self.type}#{self.instance}" if self.instance else self.type


@dataclass(frozen=True)
class Margins:
    top: int
    bottom: int
    right: int
    left: int


@dataclass(frozen=True)
class Position:
    x: str
    y: str


@dataclass(frozen=True)
class Layer:
    layer: str
    control_center_layer: str


@dataclass(frozen=True)
class Layout:
    notification_width: int
    control_center_width: int
    control_center_height: int
    fit_to_screen: bool
    margins: Margins


@dataclass(frozen=True)
class Behavior:
    """Notification and panel behaviour flags (the flat swaync options)."""

    layer_shell: bool
    layer_shell_cover_screen: bool
    css_priority: str
    transition_time_ms: int
    timeout: int
    timeout_low: int
    timeout_critical: int
    hide_on_clear: bool
    hide_on_action: bool
    text_empty: str
    script_fail_notify: bool
    notification_2fa_action: bool
    inline_replies: bool
    grouping: bool
    relative_timestamps: bool
    image_visibility: ImageVisibility
    keyboard_shortcuts: bool


@dataclass(frozen=True)
class SwayncConfig:
    """The complete control-center configuration."""

    schema: str
    position: Position
    layer: Layer
    layout: Layout
    behavior: Behavior
    widgets: tuple[Widget, ...]

    def widget_keys(self) -> tuple[str, ...]:
        return tuple(widget.key() for widget in self.widgets)


@dataclass(frozen=True)
class GenerationResult:
    """Summary of a generate run (used for logging and tests)."""

    widgets: int
    components: int
    elapsed_ms: int


def button_labels(buttons: Sequence[Button]) -> tuple[str, ...]:
    """Pure helper: labels of a button collection, in order."""
    return tuple(button.label for button in buttons)
