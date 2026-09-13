import pytest
from domain.errors import NoSecondaryMonitorError
from domain.models import Monitor, MonitorRule

from domain.workflows import display
from tests.fixtures.fakes import FakeLogger, FakeMonitorGateway, FakeNotifier, FakeTime

PRIMARY = Monitor(name="eDP-1", width=1920)
SECONDARY = Monitor(name="HDMI-A-2", width=1920)


def test_build_toggle_rule_extends_when_currently_mirrored():
    rule = display.build_toggle_rule(PRIMARY, SECONDARY, currently_mirrored=True)
    assert rule == MonitorRule(output="HDMI-A-2", mode="highres", position="1920x0", scale=1)


def test_build_toggle_rule_mirrors_when_currently_extended():
    rule = display.build_toggle_rule(PRIMARY, SECONDARY, currently_mirrored=False)
    assert rule == MonitorRule(
        output="HDMI-A-2", mode="highres", position="0x0", scale=1, mirror="eDP-1"
    )


def test_toggle_message_describes_target_mode():
    assert display.toggle_message(PRIMARY, SECONDARY, True).startswith("Mode: Extended")
    assert display.toggle_message(PRIMARY, SECONDARY, False).startswith("Mode: Mirrored")


def test_toggle_display_applies_rule_and_notifies():
    gateway = FakeMonitorGateway([PRIMARY, Monitor(name="HDMI-A-2", width=1920, mirror_of="eDP-1")])
    notifier = FakeNotifier()
    logger = FakeLogger()

    rule = display.toggle_display(gateway, notifier, logger, FakeTime())

    assert gateway.applied == [rule]
    assert rule.mirror is None, "mirrored input should switch to extend"
    assert notifier.notifications[0][0] == "Display"


def test_toggle_display_raises_without_secondary():
    gateway = FakeMonitorGateway([PRIMARY])
    with pytest.raises(NoSecondaryMonitorError):
        display.toggle_display(gateway, FakeNotifier(), FakeLogger(), FakeTime())
