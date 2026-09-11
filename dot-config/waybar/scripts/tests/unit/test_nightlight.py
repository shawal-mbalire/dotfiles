from domain.workflows import nightlight

from tests.fixtures.fakes import FakeLogger, FakeNightLightGateway, FakeNotifier

TEMPERATURE = "16000"


def test_toggle_enables_when_inactive():
    gateway = FakeNightLightGateway(active=False)
    notifier = FakeNotifier()
    nightlight.toggle(gateway, notifier, FakeLogger(), TEMPERATURE)
    assert gateway.enables == 1
    assert notifier.notifications == [("Gammastep", f"Enabled ({TEMPERATURE}K)", "normal")]


def test_toggle_disables_when_active():
    gateway = FakeNightLightGateway(active=True)
    notifier = FakeNotifier()
    nightlight.toggle(gateway, notifier, FakeLogger(), TEMPERATURE)
    assert gateway.disables == 1
    assert notifier.notifications == [("Gammastep", "Disabled", "normal")]


def test_toggle_missing_binary_notifies_critical():
    gateway = FakeNightLightGateway(available=False)
    notifier = FakeNotifier()
    nightlight.toggle(gateway, notifier, FakeLogger(), TEMPERATURE)
    assert notifier.notifications[0][2] == "critical"
    assert gateway.enables == 0 and gateway.disables == 0
