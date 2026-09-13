"""Reusable CSS builders: containers, buttons, pills and chips.

Pure helpers that assemble :class:`~domain.models.CssComponent` values. The
generated CSS keeps the waybar pill design language: rounded pills, translucent
surface fields and calm 0.25s transitions. Depth comes from a single soft panel
shadow and hairline borders rather than coloured glows.
"""

from __future__ import annotations

from collections.abc import Iterable, Sequence

from domain.models import Color, CssComponent, CssDeclaration, DesignTokens


def decl(prop: str, value: str) -> CssDeclaration:
    return CssDeclaration(prop=prop, value=value)


def rule(
    name: str,
    selectors: Sequence[str],
    declarations: Iterable[CssDeclaration],
) -> CssComponent:
    return CssComponent(
        name=name,
        selectors=tuple(selectors),
        declarations=tuple(declarations),
    )


def with_hover(selectors: Sequence[str]) -> tuple[str, ...]:
    return tuple(f"{selector}:hover" for selector in selectors)


def with_state(selectors: Sequence[str], state: str) -> tuple[str, ...]:
    return tuple(f"{selector}.{state}" for selector in selectors)


def nth(selectors: Sequence[str], index: int) -> tuple[str, ...]:
    return tuple(f"{selector}:nth-child({index})" for selector in selectors)


def prefixed(prefixes: Sequence[str], suffix: str) -> tuple[str, ...]:
    return tuple(f"{prefix} {suffix}" for prefix in prefixes)


def gradient(colors: Sequence[Color], angle: int = 135) -> str:
    stops = ", ".join(color.ref() for color in colors)
    return f"linear-gradient({angle}deg, {stops})"


def icon_chip(
    name: str,
    selectors: Sequence[str],
    background: Color,
    tokens: DesignTokens,
    *,
    radius: str | None = None,
    padding: str = "6px 12px",
    margin: str | None = None,
) -> list[CssComponent]:
    """The left half of a pill: solid accent field, crust glyph, bold."""
    corner = radius if radius is not None else tokens.radius_pill
    declarations = [
        decl("background-color", background.ref()),
        decl("color", "@crust"),
        decl("font-weight", "bold"),
        decl("border-radius", corner),
        decl("padding", padding),
        decl("transition", tokens.transition),
    ]
    if margin is not None:
        declarations.insert(4, decl("margin", margin))
    return [rule(name, selectors, declarations)]


def info_field(
    name: str,
    selectors: Sequence[str],
    tokens: DesignTokens,
    *,
    radius: str,
    padding: str = "0 12px",
    margin: str | None = None,
) -> list[CssComponent]:
    """The right half of a pill: translucent surface with a hairline border."""
    declarations = [
        decl("background-color", tokens.field_background),
        decl("border", tokens.field_border),
        decl("border-radius", radius),
        decl("color", "@subtext1"),
        decl("padding", padding),
        decl("transition", tokens.transition),
    ]
    if margin is not None:
        declarations.append(decl("margin", margin))
    base = rule(name, selectors, declarations)
    hover = rule(
        f"{name}-hover",
        with_hover(selectors),
        [decl("border-color", tokens.hover_border)],
    )
    return [base, hover]


def pill_button(
    name: str,
    selectors: Sequence[str],
    accent: Color,
    tokens: DesignTokens,
    *,
    radius: str | None = None,
) -> list[CssComponent]:
    """A chip button: accent fill, crust text, crisp border on hover."""
    corner = radius if radius is not None else tokens.radius_pill
    base = rule(
        name,
        selectors,
        [
            decl("background-color", accent.ref()),
            decl("color", "@crust"),
            decl("border", "1px solid " + accent.alpha(0.6)),
            decl("border-radius", corner),
            decl("font-weight", "bold"),
            decl("transition", tokens.transition),
        ],
    )
    hover = rule(
        f"{name}-hover",
        with_hover(selectors),
        [decl("border-color", "@text")],
    )
    return [base, hover]
