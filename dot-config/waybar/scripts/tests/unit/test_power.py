import pytest
from domain.errors import UnknownPowerProfileError
from domain.workflows import power

from tests.fixtures.fakes import (
    FakeBar,
    FakeLogger,
    FakeNotifier,
    FakePowerGateway,
    FakePrompt,
    FakeTime,
)

SIGNAL = 7


def test_next_profile_cycles_in_order():
    assert power.next_profile("power-saver").name == "balanced"
    assert power.next_profile("balanced").name == "performance"
    assert power.next_profile("performance").name == "power-saver"


def test_next_profile_unknown_wraps_to_first():
    assert power.next_profile("bogus").name == "power-saver"


def test_validate_current_falls_back_to_default():
    assert power.validate_current(None).name == "balanced"
    assert power.validate_current("nonsense").name == "balanced"
    assert power.validate_current("performance").name == "performance"


def test_status_output_exposes_label_class_and_tooltip():
    profile = power.find_profile("performance")
    assert profile is not None
    output = power.status_output(profile)
    assert output.text == "Performance"
    assert output.css_class == "performance"
    assert "POWER" in output.tooltip and "Performance" in output.tooltip


def test_pill_output_uses_icon():
    profile = power.find_profile("balanced")
    assert profile is not None
    assert power.pill_output(profile).text == profile.icon


def test_cycle_switches_to_next_profile_and_refreshes_bar():
    gateway = FakePowerGateway(active="balanced")
    notifier, bar, logger, time = FakeNotifier(), FakeBar(), FakeLogger(), FakeTime()

    assert power.cycle(gateway, notifier, bar, logger, time, SIGNAL) is True
    assert gateway.sets == ["performance"], f"expected performance, got {gateway.sets}"
    assert bar.refreshes == [SIGNAL]
    assert ("Power Profile", "Switched to: Performance", "normal") in notifier.notifications


def test_set_unknown_profile_raises_and_notifies():
    gateway = FakePowerGateway()
    notifier, bar, logger, time = FakeNotifier(), FakeBar(), FakeLogger(), FakeTime()

    with pytest.raises(UnknownPowerProfileError):
        power.set_profile("bogus", gateway, notifier, bar, logger, time, SIGNAL)

    assert gateway.sets == []
    assert notifier.notifications[0][2] == "critical"


def test_set_profile_failure_notifies_and_returns_false():
    gateway = FakePowerGateway(succeed=False)
    notifier, bar, logger, time = FakeNotifier(), FakeBar(), FakeLogger(), FakeTime()

    assert power.set_profile("balanced", gateway, notifier, bar, logger, time, SIGNAL) is False
    assert notifier.notifications[0][2] == "critical"
    assert bar.refreshes == []


def test_select_marks_current_and_switches_choice():
    gateway = FakePowerGateway(active="power-saver")
    prompt = FakePrompt(response="Performance")
    notifier, bar, logger, time = FakeNotifier(), FakeBar(), FakeLogger(), FakeTime()

    assert power.select(gateway, prompt, notifier, bar, logger, time, SIGNAL) is True
    lines, _ = prompt.calls[0]
    assert "Low power  ✓" in lines
    assert gateway.sets == ["performance"]


def test_select_cancelled_does_nothing():
    gateway = FakePowerGateway(active="balanced")
    prompt = FakePrompt(response=None)
    notifier, bar, logger, time = FakeNotifier(), FakeBar(), FakeLogger(), FakeTime()

    assert power.select(gateway, prompt, notifier, bar, logger, time, SIGNAL) is True
    assert gateway.sets == []
