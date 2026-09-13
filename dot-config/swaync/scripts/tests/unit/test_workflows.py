import pytest
from domain.errors import InvalidWidgetError
from domain.workflows import config as config_wf
from domain.workflows import generate as generate_wf
from domain.workflows import theme as theme_wf

from tests.fixtures.fakes import FakeArtifactWriter, FakeLogger, FakeTime, base_config


def test_build_widget_order_and_keys():
    model = config_wf.build(base_config())
    assert model.widget_keys() == (
        "mpris",
        "buttons-grid",
        "volume",
        "backlight",
        "notifications",
        "buttons-grid#clearbar",
    )


def test_buttons_grid_uses_reusable_buttons():
    model = config_wf.build(base_config())
    grid = next(widget for widget in model.widgets if widget.key() == "buttons-grid")
    actions = grid.options["actions"]
    assert len(actions) == 9
    toggles = [button for button in actions if button.kind.value == "toggle"]
    assert len(toggles) == 4


def test_grid_is_three_per_row():
    model = config_wf.build(base_config(buttons_per_row=3))
    grid = next(widget for widget in model.widgets if widget.key() == "buttons-grid")
    assert grid.options["buttons-per-row"] == 3


def test_grid_chips_share_a_standard_width():
    sheet = theme_wf.build(base_config())
    components = {component.name: component for component in sheet.components}
    cell = {item.prop: item.value for item in components["grid-cell"].declarations}
    chip = {item.prop: item.value for item in components["grid-chip"].declarations}
    assert cell["min-width"] == "96px"
    assert chip["min-width"] == "96px"
    assert chip["min-height"] == "40px"
    assert chip["border-radius"] == "9px"
    # No inline margin, so the FlowBox minimum equals the drawn row width.
    assert chip["margin"] == "2px 0"


def test_clear_all_is_a_neutral_fixed_width_pill():
    sheet = theme_wf.build(base_config())
    components = {component.name: component for component in sheet.components}
    clear = {item.prop: item.value for item in components["grid-clearbar"].declarations}
    assert clear["min-width"] == "342px"
    assert clear["background-color"] == "alpha(@surface0, 0.5)"
    assert clear["color"] == "@subtext0"

    hover = {item.prop: item.value for item in components["grid-clearbar-hover"].declarations}
    assert hover["color"] == "@red"
    assert hover["background-color"] == "alpha(@red, 0.14)"


def test_control_center_is_a_padded_floating_panel():
    sheet = theme_wf.build(base_config())
    components = {component.name: component for component in sheet.components}
    panel = {item.prop: item.value for item in components["control-center"].declarations}
    assert panel["padding"] == "8px"
    assert panel["border-radius"] == "12px"

    # Every module shares one inline margin and no padding, so they all render
    # at the same width despite GTK's lack of flex or percentage sizing.
    frame = {item.prop: item.value for item in components["module-frame"].declarations}
    assert frame["margin"] == "6px 5px"
    assert frame["padding"] == "0"


def test_notifications_span_the_module_width():
    sheet = theme_wf.build(base_config())
    components = {component.name: component for component in sheet.components}
    background = {
        item.prop: item.value for item in components["notification-background"].declarations
    }
    assert background["padding"] == "0"
    assert background["margin"] == "6px -6px"

    flats = components["notification-list-flat"]
    assert len(flats.selectors) >= 5
    values = {item.prop: item.value for item in flats.declarations}
    assert values["padding"] == "0"


def test_empty_buttons_grid_is_rejected():
    with pytest.raises(InvalidWidgetError):
        config_wf.build(base_config(buttons=()))


def test_behavior_is_mapped_from_config():
    model = config_wf.build(base_config(timeout=42, text_empty="Nothing here"))
    assert model.behavior.timeout == 42
    assert model.behavior.text_empty == "Nothing here"
    assert model.behavior.image_visibility.value == "when-available"


def test_theme_has_palette_and_design_tokens():
    sheet = theme_wf.build(base_config())
    names = [color.name for color in sheet.palette]
    assert names[0] == "base"
    assert "mauve" in names
    # The icon sizes plus swaync's native variables, all Catppuccin-aligned.
    root = {item.prop: item.value for item in sheet.tokens}
    assert root["--notification-icon-size"] == "40px"
    assert root["--noti-bg"] == "30, 30, 46"
    assert root["--text-color"] == "@text"
    assert root["--border-radius"] == "12px"


def test_theme_reuses_pill_components_across_widgets():
    sheet = theme_wf.build(base_config())
    names = {component.name for component in sheet.components}
    assert {"notification-card", "notification-action", "volume-chip", "backlight-chip"} <= names
    assert {"grid-chip", "mpris-button", "close-button"} <= names


def test_theme_applies_the_accent_cycle_to_grid_buttons():
    sheet = theme_wf.build(base_config())
    first = next(component for component in sheet.components if component.name == "grid-accent-1")
    assert first.declarations[0].prop == "color"
    assert first.declarations[0].value == "@lavender"
    assert first.selectors == (".widget-buttons-grid flowboxchild:nth-child(1) > button",)


def test_active_grid_toggles_fill_with_their_accent():
    sheet = theme_wf.build(base_config())
    checked = next(
        component for component in sheet.components if component.name == "grid-accent-1-checked"
    )
    values = {item.prop: item.value for item in checked.declarations}
    assert values["background-color"] == "@lavender"
    assert values["color"] == "@crust"
    assert checked.selectors == (
        ".widget-buttons-grid flowboxchild:nth-child(1) > button.toggle:checked",
    )


def test_theme_sections_cover_the_panel():
    sheet = theme_wf.build(base_config())
    sections = {component.section for component in sheet.components}
    assert "Notification cards" in sections
    assert "Volume & brightness pills" in sections
    assert "Buttons grid" in sections


def test_generate_writes_both_artifacts_and_reports():
    writer = FakeArtifactWriter()
    logger = FakeLogger()
    result = generate_wf.generate(base_config(), writer, writer, logger, FakeTime())

    assert writer.config is not None
    assert writer.style is not None
    assert result.widgets == 6
    assert result.components == len(writer.style.components)
    assert logger.has_message("generated")
