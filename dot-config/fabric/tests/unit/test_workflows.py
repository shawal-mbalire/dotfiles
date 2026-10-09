"""Workflow tests — pure orchestrators with fake ports."""

from __future__ import annotations

from domain.errors import NotFoundError, UnavailableError, ValidationError
from domain.result import Failure, Success, and_then, map_value, pipeline
from domain.workflows import (
    BluetoothWorkflow,
    BrightnessWorkflow,
    ClipboardWorkflow,
    LauncherWorkflow,
    NetworkWorkflow,
    NightLightWorkflow,
    ThemeWorkflow,
    VolumeWorkflow,
    WallpaperWorkflow,
)
from tests.fixtures.fakes import (
    FakeAudioPort,
    FakeBluetoothPort,
    FakeBrightnessPort,
    FakeClipboardPort,
    FakeColorSchemePort,
    FakeLaunchPort,
    FakeLoggerPort,
    FakeNetworkPort,
    FakeNightLightPort,
    FakeRandomPort,
    FakeWallpaperPort,
)


def test_volume_clamps_and_reports():
    audio, logger = FakeAudioPort(), FakeLoggerPort()
    wf = VolumeWorkflow(audio, logger)
    result = wf.set_volume(999)
    assert isinstance(result, Success) and result.value == 150
    assert audio.read().volume == 150


def test_volume_invalid_is_failure_before_side_effect():
    audio = FakeAudioPort()
    wf = VolumeWorkflow(audio, FakeLoggerPort())
    result = wf.set_volume(float("nan"))
    assert isinstance(result, Failure) and result.error.code.value == "FAB-1001"
    assert audio.read().volume == 40  # unchanged


def test_volume_scroll_caps_at_bar_ceiling_but_never_lowers_current():
    audio = FakeAudioPort()
    audio.emit(type(audio.read())(ready=True, muted=False, volume=120))
    wf = VolumeWorkflow(audio, FakeLoggerPort())
    assert wf.scroll(+5).value == 120  # cannot rise above current when >100
    assert wf.scroll(-5).value == 115


def test_volume_unavailable_when_not_ready():
    audio = FakeAudioPort()
    audio.emit(type(audio.read())(ready=False, muted=False, volume=0))
    result = VolumeWorkflow(audio, FakeLoggerPort()).set_volume(50)
    assert isinstance(result, Failure) and isinstance(result.error, UnavailableError)


def test_brightness_and_nightlight():
    brightness = FakeBrightnessPort()
    assert BrightnessWorkflow(brightness, FakeLoggerPort()).set_percent(150).value == 100
    night = FakeNightLightPort()
    NightLightWorkflow(night, FakeLoggerPort()).toggle()
    assert night.read().active is True


def test_bluetooth_no_adapter_is_logged_noop():
    bluetooth = FakeBluetoothPort()
    bluetooth.emit(type(bluetooth.read())(available=False, enabled=False, connected_name=""))
    logger = FakeLoggerPort()
    result = BluetoothWorkflow(bluetooth, logger).toggle()
    assert isinstance(result, Success) and logger.entries[0][0] == "warning"


def test_launcher_search_and_launch():
    launcher = FakeLaunchPort()
    wf = LauncherWorkflow(launcher, FakeLoggerPort())
    assert [a.name for a in wf.search("fire")] == ["Firefox"]
    assert isinstance(wf.launch("firefox.desktop"), Success)
    missing = wf.launch("nope.desktop")
    assert isinstance(missing, Failure) and isinstance(missing.error, NotFoundError)


def test_clipboard_workflow_validates():
    wf = ClipboardWorkflow(FakeClipboardPort(), FakeLoggerPort())
    bad = wf.copy("\x00\x01")
    assert isinstance(bad, Failure) and isinstance(bad.error, ValidationError)
    assert isinstance(wf.copy("hello"), Success)
    assert isinstance(wf.remove("hello"), Success)
    assert isinstance(wf.clear(), Success)


def test_network_workflow_requires_known_network_and_psk():
    wf = NetworkWorkflow(FakeNetworkPort(), FakeLoggerPort())
    assert isinstance(wf.connect("home"), Success)
    assert isinstance(wf.connect("ghost"), Failure)
    assert isinstance(wf.connect_with_psk("cafe", ""), Failure)
    assert isinstance(wf.connect_with_psk("cafe", "secret"), Success)


def test_wallpaper_workflow_next_and_set():
    wallpaper = FakeWallpaperPort()
    wf = WallpaperWorkflow(wallpaper, FakeRandomPort(0.5), FakeLoggerPort())
    assert wf.next().value == "b.png"
    assert wf.set("a.jpg").value == "a.jpg"
    assert isinstance(wf.set("missing.jpg"), Failure)


def test_theme_workflow_mirrors_and_notifies():
    scheme = FakeColorSchemePort(dark=True)
    wf = ThemeWorkflow(scheme, FakeLoggerPort())
    seen = []
    wf.subscribe(lambda theme: seen.append(theme.dark))
    assert seen == [True]
    assert wf.current.dark is True
    wf.toggle()
    assert wf.current.dark is False


def test_result_toolkit():
    def add(x):
        return Success(x + 1)

    assert and_then(Success(1), add).value == 2
    assert map_value(Success(2), lambda v: v * 3).value == 6
    assert pipeline(0, add, add, add).value == 3
    assert isinstance(and_then(Failure(ValidationError("x")), add), Failure)
