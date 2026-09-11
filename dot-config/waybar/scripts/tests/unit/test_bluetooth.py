from domain.constants import ICON_BLUETOOTH, ICON_BT_AVAILABLE, ICON_BT_CONNECTED
from domain.models import BluetoothDevice
from domain.workflows import bluetooth

from tests.fixtures.fakes import FakeBluetoothGateway, FakeLogger, FakeNotifier, FakePrompt


def test_build_menu_groups_connected_and_available():
    devices = [
        BluetoothDevice("AA", "Headset", paired=True, connected=True, battery_percent=80),
        BluetoothDevice("BB", "Mouse", paired=True, connected=False),
        BluetoothDevice("CC", "New Thing", paired=False),
    ]
    lines = bluetooth._build_menu(devices)
    assert "── Connected ────────────" in lines
    assert f" {ICON_BT_CONNECTED} Headset (80%)" in lines
    assert "── Available ────────────" in lines
    assert f" {ICON_BT_AVAILABLE} Mouse" in lines
    assert f" {ICON_BLUETOOTH} Toggle Power" in lines
    assert " Scan & Pair New Device" in lines


def test_build_menu_empty_shows_placeholder():
    lines = bluetooth._build_menu([])
    assert "  No paired devices" in lines


def test_toggle_power_off():
    gateway = FakeBluetoothGateway(powered=True)
    notifier = FakeNotifier()
    bluetooth.toggle_power(gateway, notifier, FakeLogger())
    assert gateway.actions == [("power", "off")]
    assert notifier.notifications == [("Bluetooth", "Powered off", "normal")]


def test_toggle_power_unavailable_notifies_critical():
    gateway = FakeBluetoothGateway(available=False)
    notifier = FakeNotifier()
    bluetooth.toggle_power(gateway, notifier, FakeLogger())
    assert notifier.notifications[0][2] == "critical"


def test_gui_offers_turn_on_when_unpowered():
    gateway = FakeBluetoothGateway(powered=False)
    prompt = FakePrompt(response="  Turn On")
    notifier = FakeNotifier()

    bluetooth.gui(gateway, prompt, notifier, _lifetime(), FakeLogger())

    assert gateway.actions == [("power", "on")]
    assert notifier.notifications == [("Bluetooth", "Powered on", "normal")]


def test_gui_toggle_power_command():
    gateway = FakeBluetoothGateway(powered=True)
    prompt = FakePrompt(response=f" {ICON_BLUETOOTH} Toggle Power")
    bluetooth.gui(gateway, prompt, FakeNotifier(), _lifetime(), FakeLogger())
    assert gateway.actions == [("power", "off")]


def test_gui_connect_available_device():
    device = BluetoothDevice("BB", "Mouse", paired=True, connected=False)
    gateway = FakeBluetoothGateway(devices=[device], powered=True)
    prompt = FakePrompt(response=f" {ICON_BT_AVAILABLE} Mouse")
    notifier = FakeNotifier()

    bluetooth.gui(gateway, prompt, notifier, _lifetime(), FakeLogger())

    assert gateway.actions == [("connect", "BB")], f"got {gateway.actions}"
    assert notifier.notifications == [("Bluetooth", "Connected: Mouse", "normal")]


def test_gui_disconnect_connected_device():
    device = BluetoothDevice("AA", "Headset", paired=True, connected=True)
    gateway = FakeBluetoothGateway(devices=[device], powered=True)
    prompt = FakePrompt(response=f" {ICON_BT_CONNECTED} Headset")
    notifier = FakeNotifier()

    bluetooth.gui(gateway, prompt, notifier, _lifetime(), FakeLogger())

    assert gateway.actions == [("disconnect", "AA")]
    assert notifier.notifications == [("Bluetooth", "Disconnected: Headset", "normal")]


def test_gui_scan_and_pair_new_device():
    gateway = FakeBluetoothGateway(
        devices=[BluetoothDevice("CC", "New Thing", paired=False)], powered=True
    )
    prompt = FakePrompt(responses=[" Scan & Pair New Device", "New Thing"])
    notifier = FakeNotifier()

    bluetooth.gui(gateway, prompt, notifier, _lifetime(), FakeLogger())

    assert ("scan", "10") in gateway.actions
    assert ("pair", "CC") in gateway.actions
    assert ("trust", "CC") in gateway.actions
    assert ("connect", "CC") in gateway.actions


def _lifetime():
    from tests.fixtures.fakes import FakeLifetime

    return FakeLifetime()
