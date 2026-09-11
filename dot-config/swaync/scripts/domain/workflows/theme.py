"""Theme workflow: compose the stylesheet from the pill design language.

Pure: turns the injected palette, design tokens and accent cycle into a
``StyleSheet``. Containers, pills, chips and buttons are built once here and
reused across the control center, popups and every widget.
"""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import replace

from domain import constants
from domain import style as s
from domain.models import Color, CssComponent, DesignTokens, StyleSheet

PANEL = (constants.SELECTOR_FLOATING, constants.SELECTOR_CONTROL_CENTER)

# Reusable selector groups ---------------------------------------------------
GRID_CELL = ".widget-buttons-grid flowboxchild"
GRID_CHIP = f"{GRID_CELL} > button"
CLEARBAR_CHIP = ".widget-buttons-grid.clearbar flowboxchild > button"
VOLUME_FIELD = ".widget-volume > box"
BACKLIGHT_FIELD = ".widget-backlight"
PILL_FIELD = (VOLUME_FIELD, BACKLIGHT_FIELD)
VOLUME_CHIP = ".widget-volume > box > label"
BACKLIGHT_CHIP = ".widget-backlight > label"
MPRIS_BUTTON = ".widget-mpris button"


def _palette(config: object) -> dict[str, Color]:
    return {color.name: color for color in config.palette}


def _base(tokens: DesignTokens) -> CssComponent:
    return s.rule(
        "base",
        ["*"],
        [
            s.decl("font-family", '"Sono Medium", "JetBrainsMono Nerd Font", sans-serif'),
            s.decl("font-size", "13px"),
        ],
    )


def _notification_cards(tokens: DesignTokens, palette: dict[str, Color]) -> list[CssComponent]:
    red = palette["red"]
    blue = palette["blue"]
    sapphire = palette["sapphire"]
    row = constants.panel_selectors(".notification-row")
    background = constants.panel_selectors(".notification-background")
    note = constants.panel_selectors(".notification")
    critical = constants.panel_selectors(".notification.critical")
    default_action = constants.panel_selectors(".notification-default-action")
    action = constants.panel_selectors(".notification-action")

    return [
        s.rule(
            "notification-row",
            row,
            [s.decl("background", "transparent"), s.decl("outline", "none")],
        ),
        # One container: the notification itself carries the card. The
        # background wrapper is flattened so nothing is nested inside a card.
        s.rule(
            "notification-background",
            background,
            [s.decl("background", "transparent"), s.decl("margin", "6px 0")],
        ),
        s.rule(
            "notification-card",
            note,
            [
                s.decl("background-color", palette["mantle"].alpha(0.95)),
                s.decl("border", f"1px solid {palette['mauve'].alpha(0.55)}"),
                s.decl("border-radius", tokens.radius_card),
                s.decl("padding", "8px"),
                s.decl("box-shadow", tokens.card_shadow),
                s.decl("transition", tokens.transition),
            ],
        ),
        s.rule("notification-critical", critical, [s.decl("border-color", red.ref())]),
        s.rule(
            "notification-default-action",
            default_action,
            [
                s.decl("background", "transparent"),
                s.decl("border", "none"),
                s.decl("box-shadow", "none"),
                s.decl("color", "@text"),
                s.decl("border-radius", tokens.radius_pill),
                s.decl("padding", "0"),
                s.decl("margin", "0"),
                s.decl("transition", tokens.transition),
            ],
        ),
        s.rule(
            "notification-action",
            action,
            [
                s.decl("background-color", tokens.field_background),
                s.decl("color", "@text"),
                s.decl("border", tokens.field_border),
                s.decl("border-radius", tokens.radius_pill),
                s.decl("padding", "8px 16px"),
                s.decl("margin", "4px 2px"),
                s.decl("min-width", "80px"),
                s.decl("transition", tokens.transition),
            ],
        ),
        s.rule(
            "notification-action-hover",
            s.with_hover(action),
            [
                s.decl("background-image", s.gradient([blue, sapphire])),
                s.decl("color", "@crust"),
                s.decl("border-color", blue.ref()),
                s.decl("box-shadow", s.glow(blue, 0.75)),
            ],
        ),
    ]


def _notification_content(palette: dict[str, Color]) -> list[CssComponent]:
    return [
        s.rule(
            "notification-content",
            [".notification-content"],
            [s.decl("background", "transparent"), s.decl("padding", "0")],
        ),
        s.rule(
            "notification-content-media",
            [".notification-content .image", ".notification-content .notification-icon"],
            [s.decl("border-radius", "8px"), s.decl("margin", "4px")],
        ),
        s.rule(
            "notification-content-textbox",
            [".notification-content .text-box"],
            [s.decl("margin-left", "8px")],
        ),
        s.rule(
            "notification-content-label",
            [".notification-content label"],
            [
                s.decl("color", "@text"),
                s.decl("filter", "none"),
                s.decl("-gtk-icon-filter", "none"),
            ],
        ),
        s.rule(
            "notification-summary",
            [".notification-content .summary"],
            [
                s.decl("color", "@text"),
                s.decl("font-weight", "bold"),
                s.decl("font-size", "15px"),
                s.decl("letter-spacing", "0.3px"),
                s.decl("margin-bottom", "2px"),
            ],
        ),
        s.rule(
            "notification-time",
            [".notification-content .time"],
            [s.decl("color", palette["overlay0"].ref()), s.decl("font-size", "12px")],
        ),
        s.rule(
            "notification-body-text",
            [".notification-content .body"],
            [
                s.decl("color", "@subtext1"),
                s.decl("font-size", "13px"),
                s.decl("line-height", "1.35"),
                s.decl("margin-top", "2px"),
            ],
        ),
        s.rule(
            "notification-app-name",
            [".notification-content .app-name"],
            [
                s.decl("color", "@lavender"),
                s.decl("font-size", "12px"),
                s.decl("font-weight", "bold"),
                s.decl("letter-spacing", "0.5px"),
            ],
        ),
    ]


def _close_and_groups(tokens: DesignTokens, palette: dict[str, Color]) -> list[CssComponent]:
    red = palette["red"]
    blue = palette["blue"]
    return [
        s.rule(
            "close-button",
            [".close-button"],
            [
                s.decl("background-color", tokens.field_background),
                s.decl("color", "@subtext0"),
                s.decl("border", tokens.field_border),
                s.decl("border-radius", "50%"),
                s.decl("padding", "4px"),
                s.decl("min-width", "20px"),
                s.decl("min-height", "20px"),
                s.decl("transition", tokens.transition),
            ],
        ),
        s.rule(
            "close-button-hover",
            [".close-button:hover"],
            [
                s.decl("background-color", red.ref()),
                s.decl("color", "@crust"),
                s.decl("border-color", red.ref()),
                s.decl("box-shadow", s.glow(red, 0.7)),
            ],
        ),
        s.rule(
            "notification-group",
            [".notification-group"],
            [s.decl("background", "transparent"), s.decl("margin", "4px 0")],
        ),
        s.rule(
            "notification-group-header",
            [".notification-group-header"],
            [
                s.decl("background-color", tokens.field_background),
                s.decl("border", tokens.field_border),
                s.decl("border-radius", tokens.radius_card),
                s.decl("padding", "6px 10px"),
                s.decl("margin", "4px 0"),
            ],
        ),
        s.rule(
            "notification-group-title",
            [".notification-group-header .notification-group-title"],
            [s.decl("color", "@lavender"), s.decl("font-weight", "bold")],
        ),
        s.rule(
            "notification-group-collapse",
            [".notification-group-collapse-button"],
            [
                s.decl("background-color", "@surface1"),
                s.decl("color", "@text"),
                s.decl("border", tokens.field_border),
                s.decl("border-radius", tokens.radius_small),
                s.decl("padding", "2px 8px"),
                s.decl("transition", tokens.transition),
            ],
        ),
        s.rule(
            "notification-group-collapse-hover",
            [".notification-group-collapse-button:hover"],
            [
                s.decl("background-color", blue.ref()),
                s.decl("color", "@crust"),
                s.decl("border-color", blue.ref()),
            ],
        ),
    ]


def _control_center(tokens: DesignTokens, palette: dict[str, Color]) -> list[CssComponent]:
    return [
        s.rule(
            "control-center",
            [".control-center"],
            [
                s.decl("background-color", "@base"),
                s.decl("border", f"1px solid {palette['surface1'].alpha(0.55)}"),
                s.decl("border-top", "none"),
                s.decl("border-radius", f"0 0 {tokens.radius_card} {tokens.radius_card}"),
                s.decl("box-shadow", tokens.card_shadow),
            ],
        ),
        s.rule("control-center-children", [".control-center > *"], [s.decl("margin", "6px 8px")]),
        # Low-opacity rule above each widget to mark where a section starts.
        s.rule(
            "section-divider",
            [".control-center .widget"],
            [
                s.decl("border-top", tokens.divider),
                s.decl("border-top-left-radius", "0"),
                s.decl("border-top-right-radius", "0"),
            ],
        ),
        s.rule(
            "section-divider-first",
            [".control-center .widget:first-child"],
            [s.decl("border-top", "none")],
        ),
    ]


def _volume_brightness(tokens: DesignTokens, palette: dict[str, Color]) -> list[CssComponent]:
    components: list[CssComponent] = []
    # Two-part pill: chip on the left, translucent field joining on the right.
    components += s.info_field(
        "volume-field",
        PILL_FIELD,
        tokens,
        radius=f"0 {tokens.radius_pill} {tokens.radius_pill} 0",
        padding="0",
        margin="6px 0",
    )
    components += s.icon_chip(
        "volume-chip",
        [VOLUME_CHIP],
        palette["sapphire"],
        tokens,
        radius=f"{tokens.radius_pill} 0 0 {tokens.radius_pill}",
        padding="6px 12px",
        margin="-1px 10px -1px -1px",
    )
    components += s.icon_chip(
        "backlight-chip",
        [BACKLIGHT_CHIP],
        palette["yellow"],
        tokens,
        radius=f"{tokens.radius_pill} 0 0 {tokens.radius_pill}",
        padding="6px 12px",
        margin="-1px 10px -1px -1px",
    )
    components.append(
        s.rule(
            "pill-scale",
            [".widget-volume > box > scale", ".widget-backlight > scale"],
            [s.decl("margin", "0 12px 0 0")],
        )
    )
    components += _scale(tokens, palette)
    return components


def _scale(tokens: DesignTokens, palette: dict[str, Color]) -> list[CssComponent]:
    blue = palette["blue"]
    sapphire = palette["sapphire"]
    return [
        s.rule(
            "scale-trough",
            ["scale trough"],
            [
                s.decl("background-color", "@surface1"),
                s.decl("border-radius", "4px"),
                s.decl("min-height", "8px"),
            ],
        ),
        s.rule(
            "scale-highlight",
            ["scale trough highlight"],
            [
                s.decl("background-image", s.gradient([blue, sapphire])),
                s.decl("border-radius", "4px"),
                s.decl("box-shadow", s.glow(blue, 0.5, "0 0 6px")),
            ],
        ),
        s.rule(
            "scale-slider",
            ["scale slider"],
            [
                s.decl("background-color", "@text"),
                s.decl("border-radius", "50%"),
                s.decl("min-width", "14px"),
                s.decl("min-height", "14px"),
            ],
        ),
    ]


def _buttons_grid(
    config: object,
    tokens: DesignTokens,
    palette: dict[str, Color],
) -> list[CssComponent]:
    accents = [palette[name] for name in config.accent_cycle]
    components: list[CssComponent] = [
        # swaync's FlowBox is not homogeneous, so pin every cell to the same
        # width; all chips then render at one standard size.
        s.rule(
            "grid-cell",
            [GRID_CELL],
            [s.decl("min-width", tokens.grid_button_width)],
        ),
        s.rule(
            "grid-chip",
            [GRID_CHIP],
            [
                s.decl("color", "@crust"),
                # Adwaita's button background-image would otherwise paint over
                # our accent background-color (only checked toggles showed it).
                s.decl("background-image", "none"),
                s.decl("border", tokens.field_border),
                s.decl("border-radius", tokens.radius_pill),
                s.decl("min-width", tokens.grid_button_width),
                s.decl("min-height", tokens.grid_button_height),
                s.decl("padding", "0 6px"),
                s.decl("margin", "2px"),
                s.decl("font-size", "14px"),
                s.decl("font-weight", "bold"),
                s.decl("transition", tokens.transition),
            ],
        ),
        s.rule(
            "grid-chip-hover",
            s.with_hover([GRID_CHIP]),
            [
                s.decl("border-color", tokens.hover_border),
                s.decl("box-shadow", s.glow(palette["overlay1"], 0.6)),
            ],
        ),
    ]

    # Reuse the accent cycle: each grid button gets its colour and matching glow.
    # :nth-child lives on the flowboxchild (the button is its only child).
    for index, accent in enumerate(accents):
        cells = s.nth([GRID_CELL], index + 1)
        selectors = tuple(f"{cell} > button" for cell in cells)
        components.append(
            s.rule(
                f"grid-accent-{index + 1}",
                selectors,
                [s.decl("background-color", accent.ref())],
            )
        )
        components.append(
            s.rule(
                f"grid-accent-{index + 1}-hover",
                s.with_hover(selectors),
                [s.decl("box-shadow", s.glow(accent, 0.55))],
            )
        )

    components += [
        s.rule(
            "grid-toggle-off",
            [f"{GRID_CHIP}.toggle:not(:checked)"],
            [s.decl("opacity", "0.55")],
        ),
        s.rule(
            "grid-toggle-on",
            [f"{GRID_CHIP}.toggle:checked"],
            [s.decl("box-shadow", s.glow(palette["blue"], 0.45))],
        ),
        s.rule(
            "grid-clearbar-cell",
            [".widget-buttons-grid.clearbar flowboxchild"],
            [s.decl("min-width", tokens.clear_button_width)],
        ),
        s.rule(
            "grid-clearbar",
            [CLEARBAR_CHIP],
            [
                s.decl("min-width", tokens.clear_button_width),
                s.decl("min-height", "36px"),
                s.decl("border-radius", tokens.radius_pill),
                s.decl("background-color", tokens.field_background),
                s.decl("background-image", "none"),
                s.decl("color", "@subtext0"),
                s.decl("border", tokens.field_border),
                s.decl("font-weight", "bold"),
                s.decl("font-size", "13px"),
                s.decl("transition", tokens.transition),
            ],
        ),
        s.rule(
            "grid-clearbar-hover",
            s.with_hover([CLEARBAR_CHIP]),
            [
                s.decl("background-color", palette["red"].alpha(0.14)),
                s.decl("color", palette["red"].ref()),
                s.decl("border-color", palette["red"].alpha(0.55)),
                s.decl("box-shadow", s.glow(palette["red"], 0.3)),
            ],
        ),
    ]
    return components


def _mpris(tokens: DesignTokens, palette: dict[str, Color]) -> list[CssComponent]:
    blue = palette["blue"]
    return [
        s.rule(
            "mpris",
            [".widget-mpris"],
            [
                s.decl("background-color", tokens.field_background),
                s.decl("border", tokens.field_border),
                s.decl("border-radius", tokens.radius_card),
                s.decl("margin", "6px 0"),
                s.decl("padding", "8px"),
            ],
        ),
        s.rule(
            "mpris-player",
            [".widget-mpris-player"],
            [s.decl("background", "transparent"), s.decl("padding", "4px")],
        ),
        s.rule("mpris-art", [".widget-mpris-art"], [s.decl("border-radius", tokens.radius_inner)]),
        s.rule(
            "mpris-title",
            [".widget-mpris-title"],
            [s.decl("color", "@text"), s.decl("font-weight", "bold"), s.decl("font-size", "15px")],
        ),
        s.rule(
            "mpris-subtitle",
            [".widget-mpris-subtitle"],
            [s.decl("color", "@subtext0"), s.decl("font-size", "13px")],
        ),
        s.rule(
            "mpris-button",
            [MPRIS_BUTTON],
            [
                s.decl("background-color", tokens.field_background),
                s.decl("color", "@text"),
                s.decl("border", tokens.field_border),
                s.decl("border-radius", tokens.radius_pill),
                s.decl("min-width", "32px"),
                s.decl("min-height", "32px"),
                s.decl("padding", "4px"),
                s.decl("transition", tokens.transition),
            ],
        ),
        s.rule(
            "mpris-button-hover",
            s.with_hover([MPRIS_BUTTON]),
            [
                s.decl("background-color", blue.ref()),
                s.decl("color", "@crust"),
                s.decl("border-color", blue.ref()),
                s.decl("box-shadow", s.glow(blue, 0.5)),
            ],
        ),
    ]


def _misc(tokens: DesignTokens, palette: dict[str, Color]) -> list[CssComponent]:
    return [
        s.rule(
            "empty-state",
            [".empty-state"],
            [
                s.decl("color", "@overlay0"),
                s.decl("padding", "20px"),
                s.decl("font-style", "italic"),
            ],
        ),
        s.rule("scrollbar", ["scrollbar"], [s.decl("background", "transparent")]),
        s.rule(
            "scrollbar-slider",
            ["scrollbar slider"],
            [
                s.decl("background-color", "@surface1"),
                s.decl("border-radius", "4px"),
                s.decl("min-width", "6px"),
            ],
        ),
        s.rule(
            "scrollbar-slider-hover",
            ["scrollbar slider:hover"],
            [s.decl("background-color", "@surface2")],
        ),
    ]


def _section(name: str, components: Sequence[CssComponent]) -> list[CssComponent]:
    """Tag a group of components so the generated CSS stays readable."""
    return [replace(component, section=name) for component in components]


def build(config: object) -> StyleSheet:
    """Compose every reusable component into one stylesheet."""
    tokens: DesignTokens = config.tokens
    palette = _palette(config)

    components: list[CssComponent] = []
    components += _section("Base", [_base(tokens)])
    components += _section("Notification cards", _notification_cards(tokens, palette))
    components += _section("Notification content", _notification_content(palette))
    components += _section("Close button & groups", _close_and_groups(tokens, palette))
    components += _section("Control center", _control_center(tokens, palette))
    components += _section("Volume & brightness pills", _volume_brightness(tokens, palette))
    components += _section("Buttons grid", _buttons_grid(config, tokens, palette))
    components += _section("MPRIS", _mpris(tokens, palette))
    components += _section("Misc", _misc(tokens, palette))

    return StyleSheet(
        palette=tuple(config.palette),
        tokens=tuple(config.root_tokens),
        components=tuple(components),
    )


def component_count(sheet: StyleSheet) -> int:
    return len(sheet.components)


def selectors_of(components: Sequence[CssComponent]) -> tuple[str, ...]:
    """Pure helper: every selector referenced by a component collection."""
    return tuple(selector for component in components for selector in component.selectors)
