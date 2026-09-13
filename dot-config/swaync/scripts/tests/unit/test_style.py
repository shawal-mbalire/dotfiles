from domain import style as s
from domain.models import Color, DesignTokens


def _tokens() -> DesignTokens:
    return DesignTokens(
        radius_pill="9px",
        radius_card="12px",
        radius_inner="7px",
        radius_small="6px",
        transition="all 0.25s ease",
        field_background="alpha(@surface0, 0.5)",
        field_border="1px solid alpha(@surface1, 0.6)",
        hover_border="alpha(@overlay1, 0.8)",
        card_background="@mantle",
        card_border="1px solid @surface0",
        card_shadow="0 6px 20px alpha(@crust, 0.35)",
        panel_padding="8px",
        module_margin="6px 5px",
        grid_button_width="96px",
        grid_button_height="40px",
        clear_button_width="342px",
    )


def test_rule_copies_selectors_into_a_component():
    component = s.rule("x", [".a", ".b"], [s.decl("color", "red")])
    assert component.selectors == (".a", ".b")
    assert component.declarations[0].value == "red"


def test_hover_and_state_and_nth_build_selector_variants():
    assert s.with_hover([".a", ".b"]) == (".a:hover", ".b:hover")
    assert s.with_state([".a"], "toggle") == (".a.toggle",)
    assert s.nth([".a"], 3) == (".a:nth-child(3)",)
    assert s.prefixed([".x"], ".y") == (".x .y",)


def test_gradient_lists_color_references():
    blue = Color.from_hex("blue", "#89b4fa")
    sapphire = Color.from_hex("sapphire", "#74c7ec")
    assert s.gradient([blue, sapphire]) == "linear-gradient(135deg, @blue, @sapphire)"


def test_pill_button_emits_base_and_border_hover():
    accent = Color.from_hex("blue", "#89b4fa")
    components = s.pill_button("chip", [".chip"], accent, _tokens())
    assert len(components) == 2
    base, hover = components
    assert base.declarations[0].value == "@blue"
    assert hover.selectors == (".chip:hover",)
    assert hover.declarations[0] == s.decl("border-color", "@text")


def test_info_field_uses_translucent_surface_tokens():
    components = s.info_field("field", [".field"], _tokens(), radius="9px")
    base, hover = components
    assert base.declarations[0].value == "alpha(@surface0, 0.5)"
    assert hover.declarations[0].value == "alpha(@overlay1, 0.8)"
