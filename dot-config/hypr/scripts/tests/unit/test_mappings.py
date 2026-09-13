from domain.models import Monitor, MonitorRule

from adapters import hyprctl_mappings as mappings


def test_parse_monitors_maps_names_widths_and_mirror():
    payload = [
        {"name": "eDP-1", "width": 1920, "mirrorOf": "none"},
        {"name": "HDMI-A-2", "width": 2560, "mirrorOf": "eDP-1"},
    ]
    monitors = mappings.parse_monitors(payload)
    assert monitors == [
        Monitor(name="eDP-1", width=1920, mirror_of=None),
        Monitor(name="HDMI-A-2", width=2560, mirror_of="eDP-1"),
    ]


def test_rule_to_lua_renders_flat_call_without_mirror():
    rule = MonitorRule(output="HDMI-A-2", mode="highres", position="1920x0", scale=1)
    expected = (
        'hl.monitor({ output = "HDMI-A-2", mode = "highres", position = "1920x0", scale = 1 })'
    )
    assert mappings.rule_to_lua(rule) == expected


def test_rule_to_lua_includes_mirror_when_present():
    rule = MonitorRule(
        output="HDMI-A-2",
        mode="highres",
        position="0x0",
        scale=1,
        mirror="eDP-1",
    )
    assert 'mirror = "eDP-1"' in mappings.rule_to_lua(rule)
