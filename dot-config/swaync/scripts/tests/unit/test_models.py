from domain.models import Button, ButtonKind, Color, Widget, button_labels


def test_color_parses_hex_and_renders_references():
    color = Color.from_hex("Mauve", "#CBA6F7")
    assert color.hex == "cba6f7"
    assert color.ref() == "@Mauve"
    assert color.literal() == "#cba6f7"
    assert color.alpha(0.5) == "alpha(@Mauve, 0.5)"


def test_toggle_button_carries_state_and_update_command():
    button = Button.toggle("DND", "swaync-client -d", "swaync-client -D", active=False)
    assert button.kind is ButtonKind.TOGGLE
    assert button.active is False
    assert button.update_command == "swaync-client -D"


def test_action_button_has_no_update_command():
    button = Button.action("Lock", "hyprlock")
    assert button.kind is ButtonKind.NORMAL
    assert button.update_command is None


def test_widget_key_includes_instance():
    assert Widget(type="volume").key() == "volume"
    assert Widget(type="buttons-grid", instance="clearbar").key() == "buttons-grid#clearbar"


def test_button_labels_preserve_order():
    buttons = (Button.action("A", "a"), Button.action("B", "b"))
    assert button_labels(buttons) == ("A", "B")
