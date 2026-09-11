from adapters.bluetoothctl_gateway import parse_devices, parse_info
from adapters.busctl_power import parse_active_profile
from adapters.pactl_audio import parse_sinks, shorten_description
from adapters.proc_network import default_interface
from adapters.wpctl_audio import parse_volume_output


def test_parse_volume_output_plain():
    status = parse_volume_output("Volume: 0.26\n")
    assert status.volume_percent == 26
    assert status.muted is False


def test_parse_volume_output_muted():
    status = parse_volume_output("Volume: 1.00 [MUTED]")
    assert status.volume_percent == 100
    assert status.muted is True


def test_parse_active_profile_quoted():
    assert parse_active_profile('s "balanced"') == "balanced"
    assert parse_active_profile("") is None


def test_shorten_description_strips_vendor_noise():
    description = "Core Ultra 200H/200V Series Processors HD Audio Realtek ALC256 Analog"
    assert shorten_description(description) == "Analog"


def test_parse_sinks_builds_models():
    payload = (
        '[{"name": "sink-a", "description": "Speakers"},'
        ' {"name": "sink-b", "description": "Headphones"}]'
    )
    sinks = parse_sinks(payload)
    assert [sink.name for sink in sinks] == ["sink-a", "sink-b"]
    assert sinks[1].description == "Headphones"


def test_parse_devices():
    output = "Device AA:BB:CC Headset\nDevice DD:EE:FF Mouse\n"
    assert parse_devices(output) == [("AA:BB:CC", "Headset"), ("DD:EE:FF", "Mouse")]


def test_parse_info_paired_connected_and_battery():
    output = (
        "Device AA:BB:CC (public)\n"
        "\tPaired: yes\n"
        "\tConnected: no\n"
        "\tBattery Percentage: 0x50 (80)\n"
    )
    info = parse_info(output)
    assert info["paired"] is True
    assert info["connected"] is False
    assert info["battery"] == 80


def test_parse_info_hex_battery_without_parens():
    info = parse_info("\tBattery Percentage: 0x64\n")
    assert info["battery"] == 100


def test_default_interface_picks_default_route():
    table = (
        "Iface\tDestination\tGateway\tFlags\tRefCnt\tUse\tMetric\tMask\tMTU\tWindow\tIRTT\n"
        "wlan0\t00000000\t0101A8C0\t0003\t0\t0\t600\t00000000\t0\t0\t0\n"
        "eth0\t0001A8C0\t00000000\t0001\t0\t0\t100\t00FFFFFF\t0\t0\t0\n"
    )
    assert default_interface(table) == "wlan0"


def test_default_interface_none_when_no_route():
    assert default_interface("Iface Destination Gateway Flags\n") is None
