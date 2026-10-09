"""Contract tests — every adapter satisfies its port protocol."""

from __future__ import annotations

from pathlib import Path

from adapters.driven.desktop_entries.launcher import DesktopEntriesLaunchAdapter
from adapters.driven.fallback import (
    UnavailableAudioAdapter,
    UnavailableBluetoothAdapter,
    UnavailableClipboardAdapter,
    UnavailableNetworkAdapter,
    UnavailableNightLightAdapter,
    UnavailableNotificationFeedAdapter,
    UnavailableTrayAdapter,
    UnavailableWallpaperAdapter,
    UnavailableWorkspaceAdapter,
)
from adapters.driven.wallpaper.store import DirectoryWallpaperStore
from domain.ports import (
    AudioPort,
    BatteryPort,
    BluetoothPort,
    BrightnessPort,
    ClipboardPort,
    LaunchPort,
    NetworkPort,
    NightLightPort,
    NotificationFeedPort,
    TrayPort,
    WallpaperPort,
    WorkspacePort,
)
from tests.fixtures.fakes import (
    FakeAudioPort,
    FakeBatteryPort,
    FakeBluetoothPort,
    FakeBrightnessPort,
    FakeClipboardPort,
    FakeLaunchPort,
    FakeNetworkPort,
    FakeNightLightPort,
    FakeSource,
    FakeTrayPort,
    FakeWallpaperPort,
    FakeWorkspacePort,
)

# Each row: protocol, real/fallback adapter, fake adapter.
CONTRACTS = [
    (AudioPort, UnavailableAudioAdapter, FakeAudioPort),
    (BatteryPort, None, FakeBatteryPort),
    (BluetoothPort, UnavailableBluetoothAdapter, FakeBluetoothPort),
    (BrightnessPort, None, FakeBrightnessPort),
    (ClipboardPort, UnavailableClipboardAdapter, FakeClipboardPort),
    (LaunchPort, None, FakeLaunchPort),
    (NetworkPort, UnavailableNetworkAdapter, FakeNetworkPort),
    (NightLightPort, UnavailableNightLightAdapter, FakeNightLightPort),
    (NotificationFeedPort, UnavailableNotificationFeedAdapter, None),
    (TrayPort, UnavailableTrayAdapter, FakeTrayPort),
    (WallpaperPort, UnavailableWallpaperAdapter, FakeWallpaperPort),
    (WorkspacePort, UnavailableWorkspaceAdapter, FakeWorkspacePort),
]


def test_adapters_satisfy_their_ports():
    for protocol, fallback_cls, fake_cls in CONTRACTS:
        if fallback_cls is not None:
            assert isinstance(fallback_cls(), protocol), (
                f"{fallback_cls.__name__} ⊭ {protocol.__name__}"
            )
        if fake_cls is not None:
            assert isinstance(fake_cls(), protocol), f"{fake_cls.__name__} ⊭ {protocol.__name__}"


def test_directory_wallpaper_store_satisfies_port(tmp_path: Path):
    assert isinstance(DirectoryWallpaperStore(tmp_path), WallpaperPort)


def test_desktop_launcher_satisfies_port(tmp_path: Path):
    launcher = DesktopEntriesLaunchAdapter(data_home=tmp_path, data_dirs=tuple())
    launcher.start()
    assert isinstance(launcher, LaunchPort)


def test_observable_contract_immediate_subscribe():
    source = FakeSource(1)
    seen = []
    source.subscribe(seen.append)
    assert seen == [1]
