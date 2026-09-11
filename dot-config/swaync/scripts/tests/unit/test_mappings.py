import json

from adapters import swaync_mappings as mappings
from domain.models import Button
from domain.workflows import config as config_wf
from domain.workflows import theme as theme_wf

from tests.fixtures.fakes import base_config


def test_button_to_dict_toggle_includes_active_and_update():
    button = Button.toggle("DND", "off", "status", active=True)
    assert mappings.button_to_dict(button) == {
        "label": "DND",
        "type": "toggle",
        "active": True,
        "command": "off",
        "update-command": "status",
    }


def test_button_to_dict_action_is_minimal():
    button = Button.action("Lock", "hyprlock")
    assert mappings.button_to_dict(button) == {
        "label": "Lock",
        "type": "normal",
        "command": "hyprlock",
    }


def test_config_to_dict_has_widgets_and_config_sections():
    model = config_wf.build(base_config())
    payload = mappings.config_to_dict(model)
    assert payload["widgets"] == list(model.widget_keys())
    assert payload["widget-config"]["volume"]["label"]
    actions = payload["widget-config"]["buttons-grid"]["actions"]
    assert len(actions) == 9
    assert {"label", "type", "command"} <= set(actions[0])


def test_config_to_json_keeps_unicode_glyphs():
    model = config_wf.build(base_config())
    text = mappings.config_to_json(model)
    parsed = json.loads(text)
    assert parsed["positionX"] == "right"
    assert any(ord(char) > 0xE000 for char in text)


def test_stylesheet_to_css_has_palette_tokens_and_sections():
    sheet = theme_wf.build(base_config())
    css = mappings.stylesheet_to_css(sheet)
    assert "@define-color mauve" in css
    assert ":root {" in css
    assert "--notification-icon-size: 40px;" in css
    assert "/* ── Buttons grid ── */" in css
    assert ".widget-buttons-grid flowboxchild > button:first-child" not in css
    assert "linear-gradient(135deg" in css


def test_component_css_uses_comma_separated_selectors():
    sheet = theme_wf.build(base_config())
    card = next(
        component for component in sheet.components if component.name == "notification-card"
    )
    rendered = mappings.component_to_css(card)
    assert rendered.startswith(
        ".floating-notifications.background .notification,\n.control-center .notification {"
    )


def test_popup_has_a_single_container():
    sheet = theme_wf.build(base_config())
    components = {component.name: component for component in sheet.components}

    background = components["notification-background"]
    values = {declaration.prop: declaration.value for declaration in background.declarations}
    assert values["background"] == "transparent"
    assert "border" not in values and "border-radius" not in values

    card = components["notification-card"]
    card_values = {declaration.prop: declaration.value for declaration in card.declarations}
    assert card_values["padding"] == "8px"
    assert card_values["border-radius"] == "12px"
    assert "margin" not in card_values  # spacing lives on the flat wrapper
