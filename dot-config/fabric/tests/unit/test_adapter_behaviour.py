"""Adapter behaviour tests: desktop entries, wallpaper store, notifications,
control socket, and the text presenter."""

from __future__ import annotations

from datetime import datetime
from pathlib import Path

from adapters.driven.desktop_entries.launcher import DesktopEntriesLaunchAdapter
from adapters.driven.desktop_entries.parser import (
    build_launch_argv,
    is_displayable,
    parse_desktop_entry,
    tokenize_exec,
)
from adapters.driven.notifications.server import (
    NotificationServerAdapter,
    _clean_actions,
    _fallback_summary,
    _urgency_from_hint,
)
from adapters.driven.wallpaper.store import DirectoryWallpaperStore
from adapters.driving.gtk.control_socket import ControlSocket, send_command
from adapters.driving.text.presenter import TextPresenter
from adapters.driving.view_model import ShellViewModel
from domain.models import Urgency
from domain.workflows.theme import ThemeWorkflow
from tests.fixtures.fakes import (
    FakeAudioPort,
    FakeBatteryPort,
    FakeBluetoothPort,
    FakeBrightnessPort,
    FakeColorSchemePort,
    FakeLoggerPort,
    FakeNetworkPort,
    FakeNightLightPort,
    FakeNotificationFeedPort,
    FakeTrayPort,
    FakeWorkspacePort,
)

# ── desktop entry parser ──────────────────────────────────────────────────


def test_parse_desktop_entry():
    text = """[Desktop Entry]
Type=Application
Name=Firefox
GenericName=Web Browser
Comment=Browse the web
Keywords=internet;www;
Icon=firefox
Exec=firefox %u
Terminal=false
"""
    entry = parse_desktop_entry(text, "firefox.desktop")
    assert entry is not None
    assert entry.name == "Firefox"
    assert entry.keywords == ("internet", "www")
    assert entry.exec_line == "firefox %u"
    assert not entry.terminal
    assert is_displayable(entry)
    assert parse_desktop_entry("NoGroup=1", "x.desktop") is None


def test_tokenize_exec_quoting_and_codes():
    assert tokenize_exec('flatpak run --branch="stable" org.app %u %%') == [
        "flatpak",
        "run",
        "--branch=stable",
        "org.app",
        "%",
    ]


def test_build_launch_argv_terminal_wrapper():
    argv = build_launch_argv("bash -lc htop", terminal=True, terminal_command=("kitty", "-e"))
    assert argv == ["kitty", "-e", "bash", "-lc", "htop"]


def test_launcher_scans_directory(tmp_path: Path, monkeypatch):
    apps_dir = tmp_path / "applications"
    apps_dir.mkdir()
    (apps_dir / "a.desktop").write_text(
        "[Desktop Entry]\nType=Application\nName=Alpha\nExec=alpha\n", encoding="utf-8"
    )
    (apps_dir / "hidden.desktop").write_text(
        "[Desktop Entry]\nType=Application\nName=Hidden\nNoDisplay=true\nExec=hidden\n",
        encoding="utf-8",
    )
    launcher = DesktopEntriesLaunchAdapter(data_home=tmp_path, data_dirs=tuple())
    launcher.start()
    apps = launcher.read()
    assert [app.name for app in apps] == ["Alpha"]
    captured: list[list[str]] = []

    def fake_popen(argv, **kwargs):
        captured.append(argv)
        return object()

    monkeypatch.setattr("adapters.driven.desktop_entries.launcher.subprocess.Popen", fake_popen)
    assert launcher.launch("a.desktop") is True
    assert captured == [["alpha"]]
    assert launcher.launch("nope.desktop") is False


# ── wallpaper store ───────────────────────────────────────────────────────


def test_wallpaper_store_lists_and_cycles(tmp_path: Path):
    (tmp_path / "b.jpg").write_bytes(b"x")
    (tmp_path / "a.png").write_bytes(b"x")
    (tmp_path / "notes.txt").write_text("not a wallpaper", encoding="utf-8")
    store = DirectoryWallpaperStore(tmp_path)
    assert list(store.read().wallpapers) == [f"{tmp_path}/a.png", f"{tmp_path}/b.jpg"]
    assert store.read().current == ""
    store.next()
    assert store.read().current == f"{tmp_path}/a.png"
    store.next()
    assert store.read().current == f"{tmp_path}/b.jpg"
    store.next()
    assert store.read().current == f"{tmp_path}/a.png"  # wraps
    store.previous()
    assert store.read().current == f"{tmp_path}/b.jpg"
    store.set("missing.jpg")
    assert store.read().current == f"{tmp_path}/b.jpg"


# ── notifications helpers ─────────────────────────────────────────────────


def test_notification_helpers():
    assert _fallback_summary("", "body", "App") == "App"
    assert _fallback_summary("", "", "App") == "New notification"
    assert _fallback_summary("S", "B", "App") == "S"
    assert _clean_actions([("default", "Open"), ("ok", "OK"), ("bad", "")]) == [("ok", "OK")]
    assert _urgency_from_hint({"urgency": 2}) is Urgency.CRITICAL
    assert _urgency_from_hint({"urgency": 7}) is Urgency.NORMAL


class FakeBus:
    def __init__(self) -> None:
        self.signal_emits: list[tuple[str, str, tuple]] = []
        self.names: list[str] = []

    def request_name(self, name: str, flags: int) -> int:
        self.names.append(name)
        return 1

    def on_method_call(self, *_args) -> None:
        pass

    def emit_signal(self, *, member: str, args: tuple, **_) -> None:
        self.signal_emits.append((member, args))


class FakeClock:
    def __init__(self) -> None:
        self.value = datetime(2026, 10, 9, 12, 0)

    def now(self) -> datetime:
        return self.value


def test_notification_server_state_machine():
    server = NotificationServerAdapter(FakeBus(), FakeClock())
    server.add(
        app_name="WhatsApp",
        app_icon="",
        summary="Hello",
        body="There",
        actions=[],
        hints={"urgency": 1},
        expire_timeout=5000,
    )
    feed = server.read()
    assert len(feed.active) == 1 and feed.active[0].summary == "Hello"
    assert len(feed.history) == 1
    assert server.pause(1) is True
    server.start()
    server.stop()


# ── control socket ────────────────────────────────────────────────────────


def test_control_socket_roundtrip(tmp_path: Path):
    path = tmp_path / "fabric.sock"
    calls: list[str] = []
    server = ControlSocket(path, {"toggle bar": lambda: calls.append("bar")})
    server.start()
    try:
        assert send_command(path, "toggle bar") == "ok"
        assert send_command(path, "nope") == "unknown command"
        assert calls == ["bar"]
    finally:
        server.stop()


# ── text presenter (headless smoke) ───────────────────────────────────────


def test_text_presenter_renders_model():
    class Capture:
        def __init__(self) -> None:
            self.lines: list[str] = []

        def write(self, text: str) -> None:
            self.lines.append(text)

        def flush(self) -> None:
            pass

    theme = ThemeWorkflow(FakeColorSchemePort(dark=True), FakeLoggerPort())
    vm = ShellViewModel(
        theme=theme,
        clock=FakeClock(),
        workspaces=FakeWorkspacePort(),
        tray=FakeTrayPort(),
        nightlight=FakeNightLightPort(),
        network=FakeNetworkPort(),
        bluetooth=FakeBluetoothPort(),
        audio=FakeAudioPort(),
        brightness=FakeBrightnessPort(),
        battery=FakeBatteryPort(),
        notifications=FakeNotificationFeedPort(),
    )
    capture = Capture()
    presenter = TextPresenter(vm, stream=capture)
    line = presenter.render()
    assert "Oct 9" in line
    assert "40%" in line
    assert "62%" in line
