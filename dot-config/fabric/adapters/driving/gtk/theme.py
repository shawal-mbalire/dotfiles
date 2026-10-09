"""Theme CSS generation from domain tokens — pure and testable."""

from __future__ import annotations

from domain.constants import Theme


def build_css(theme: Theme) -> str:
    """Return a GTK CSS stylesheet for the given theme tokens."""
    p = theme.palette
    return f"""
.fabric-bar {{
  background-color: {p.mantle};
  min-height: {theme.font_size + 15}px;
  padding: 0 {theme.spacing + 6}px;
}}
.fabric-workspace {{
  min-width: 22px;
  min-height: 20px;
  border-radius: 6px;
  background-color: {p.surface1};
  color: {p.subtext0};
  font-family: "{theme.font}";
  font-size: 11px;
  font-weight: 800;
}}
.fabric-workspace.active {{
  min-width: 32px;
  background-color: {p.green};
  color: {p.crust};
}}
.fabric-clock-date {{
  color: {p.overlay0};
  font-family: "{theme.font}";
  font-size: {theme.font_size}px;
  font-weight: {theme.font_weight};
}}
.fabric-clock-time {{
  color: {p.text};
  font-family: "{theme.font}";
  font-size: {theme.font_size}px;
  font-weight: {theme.font_weight};
}}
.fabric-indicator-label {{
  color: {p.text};
  font-family: "{theme.font}";
  font-size: {theme.font_size}px;
  font-weight: {theme.font_weight};
}}
.fabric-overlay {{
  background-color: {p.base};
  border: 1px solid {p.surface1};
  border-radius: {theme.radius_lg}px;
  padding: {theme.padding_lg}px;
}}
.fabric-card {{
  background-color: {p.surface0};
  border: 1px solid {p.surface1};
  border-radius: {theme.radius}px;
  padding: {theme.padding}px;
}}
.fabric-pill {{
  border-radius: 14px;
  padding: 4px 12px;
  background-color: {p.surface1};
  color: {p.subtext0};
  font-family: "{theme.font}";
  font-size: 11px;
  font-weight: 700;
}}
.fabric-pill.checked {{
  background-color: {p.blue};
  color: {p.crust};
}}
.fabric-title {{
  color: {p.text};
  font-family: "{theme.font}";
  font-size: 13px;
  font-weight: 800;
}}
.fabric-muted {{
  color: {p.overlay0};
  font-family: "{theme.font}";
  font-size: 11px;
}}
"""


def apply_css(css: str) -> None:
    """Install the stylesheet on the default display (lazy GTK import)."""
    import gi

    gi.require_version("Gtk", "4.0")
    from gi.repository import Gdk, Gtk

    provider = Gtk.CssProvider()
    provider.load_from_data(css.encode())
    display = Gdk.Display.get_default()
    if display is not None:
        Gtk.StyleContext.add_provider_for_display(
            display, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )


def glyph_or_blank(text: str) -> str:
    return text if text else ""
