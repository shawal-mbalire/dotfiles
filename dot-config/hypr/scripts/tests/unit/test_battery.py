from domain.models import BatteryStatus

from domain.workflows import battery
from tests.fixtures.fakes import (
    FakeBatteryReader,
    FakeLogger,
    FakeMarkerStore,
    FakeNotifier,
    FakeTime,
)


def test_select_notification_discharging_thresholds():
    assert battery.select_notification(BatteryStatus(3, "Discharging")).marker == "3p"
    assert battery.select_notification(BatteryStatus(10, "Discharging")).marker == "10p"
    assert battery.select_notification(BatteryStatus(20, "Discharging")).marker == "20p"
    assert battery.select_notification(BatteryStatus(50, "Discharging")) is None


def test_select_notification_charging_thresholds():
    assert battery.select_notification(BatteryStatus(100, "Charging")).marker == "100c"
    assert battery.select_notification(BatteryStatus(85, "Charging")).marker == "80c"
    assert battery.select_notification(BatteryStatus(15, "Charging")).marker == "20c"
    assert battery.select_notification(BatteryStatus(50, "Charging")) is None


def test_select_notification_full_and_unknown():
    assert battery.select_notification(BatteryStatus(100, "Full")).marker == "full"
    assert battery.select_notification(BatteryStatus(None, "Discharging")) is None
    assert battery.select_notification(BatteryStatus(50, "Unknown")) is None


def test_notify_battery_emits_once_per_marker():
    deps = (
        FakeBatteryReader(BatteryStatus(5, "Discharging")),
        FakeMarkerStore(),
        FakeNotifier(),
        FakeLogger(),
        FakeTime(),
    )
    reader, store, notifier, logger, time = deps
    battery.notify_battery(reader, store, notifier, logger, time)
    battery.notify_battery(reader, store, notifier, logger, time)

    assert len(notifier.notifications) == 1, "same marker must not notify twice"
    summary, body, urgency, icon = notifier.notifications[0]
    assert summary == "Low Battery"
    assert body == "5% remaining"
    assert urgency == "high"
    assert icon == "battery-low"


def test_notify_battery_rearms_on_state_change():
    reader = FakeBatteryReader(BatteryStatus(5, "Discharging"))
    store = FakeMarkerStore()
    notifier = FakeNotifier()
    logger = FakeLogger()
    time = FakeTime()

    battery.notify_battery(reader, store, notifier, logger, time)
    reader._status = BatteryStatus(5, "Charging")
    battery.notify_battery(reader, store, notifier, logger, time)

    markers = [n[0] for n in notifier.notifications]
    assert markers == ["Low Battery", "Charging"], markers


def test_notify_battery_no_battery_is_quiet():
    notifier = FakeNotifier()
    logger = FakeLogger()
    battery.notify_battery(
        FakeBatteryReader(BatteryStatus(None, None)),
        FakeMarkerStore(),
        notifier,
        logger,
        FakeTime(),
    )
    assert notifier.notifications == []
    assert logger.has("debug", "battery unavailable")
