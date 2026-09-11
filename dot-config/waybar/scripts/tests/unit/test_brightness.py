from domain.workflows import brightness

from tests.fixtures.fakes import FakeBrightnessGateway, FakeLogger, FakePrompt


def test_step_is_smaller_at_low_brightness():
    assert brightness.step_for(5, "up") == 1
    assert brightness.step_for(20, "up") == 2
    assert brightness.step_for(80, "up") == 5


def test_delta_never_drops_below_one_percent():
    assert brightness.brightness_delta(50, "down") == -5
    assert brightness.brightness_delta(3, "down") == -1
    assert brightness.brightness_delta(1, "down") == 0


def test_delta_up_matches_step():
    assert brightness.brightness_delta(5, "up") == 1
    assert brightness.brightness_delta(25, "up") == 2
    assert brightness.brightness_delta(60, "up") == 5


def test_adjust_applies_relative_delta():
    gateway = FakeBrightnessGateway(percent=60)
    brightness.adjust(gateway, "down", FakeLogger())
    assert gateway.relative == [-5], f"expected [-5], got {gateway.relative}"


def test_adjust_at_minimum_is_noop():
    gateway = FakeBrightnessGateway(percent=1)
    brightness.adjust(gateway, "down", FakeLogger())
    assert gateway.relative == []


def test_choose_preset_sets_absolute_percent():
    gateway = FakeBrightnessGateway()
    prompt = FakePrompt(response="75%")
    brightness.choose_preset(gateway, prompt, FakeLogger())
    assert gateway.absolute == [75], f"expected [75], got {gateway.absolute}"


def test_choose_preset_cancelled():
    gateway = FakeBrightnessGateway()
    brightness.choose_preset(gateway, FakePrompt(response=None), FakeLogger())
    assert gateway.absolute == []
