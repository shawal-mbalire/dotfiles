"""Pure domain logic tests (mirrors the QML tst_domainModels.qml suite)."""

from __future__ import annotations

import math
from datetime import datetime

from domain import logic
from domain.models import Urgency, Workspace, WorkspaceState
from tests.fixtures.fakes import sample_apps


def names(apps):
    return [a.name for a in apps]


# ── App search ─────────────────────────────────────────────────────────────


def test_empty_query_returns_all_in_order():
    assert names(logic.filter_apps(sample_apps(), "   ")) == [
        "Firefox",
        "Files",
        "GNU Image Manipulation Program",
        "kitty",
        "Visual Studio Code",
    ]


def test_prefix_beats_word_prefix_beats_contains():
    assert names(logic.filter_apps(sample_apps(), "fi")) == [
        "Firefox",
        "Files",
        "Visual Studio Code",
    ]
    assert names(logic.filter_apps(sample_apps(), "code")) == ["Visual Studio Code"]
    assert names(logic.filter_apps(sample_apps(), "image"))[0] == "GNU Image Manipulation Program"


def test_matches_generic_name_and_keywords():
    assert names(logic.filter_apps(sample_apps(), "browser")) == ["Firefox"]
    assert names(logic.filter_apps(sample_apps(), "www")) == ["Firefox"]
    assert names(logic.filter_apps(sample_apps(), "terminal")) == ["kitty"]


def test_subsequence_is_last_resort():
    assert names(logic.filter_apps(sample_apps(), "ffx")) == ["Firefox"]
    assert logic.filter_apps(sample_apps(), "zzz") == []


def test_case_insensitive():
    assert names(logic.filter_apps(sample_apps(), "KITTY")) == ["kitty"]


# ── Clipboard ──────────────────────────────────────────────────────────────


def test_usable_text_accepts_normal_text():
    assert logic.is_usable_text("hello\tworld\r\n") is True


def test_usable_text_rejects_empty_binary_and_huge():
    assert logic.is_usable_text("") is False
    assert logic.is_usable_text("   \n") is False
    assert logic.is_usable_text("PNG\x00\x01") is False
    assert logic.is_usable_text("x" * 32001) is False
    assert logic.is_usable_text("x" * 32000) is True


def test_push_unique_moves_to_front_and_bounds():
    assert logic.push_unique(["a", "b", "c"], "b", 5) == ["b", "a", "c"]
    assert logic.push_unique(["a", "b", "c"], "d", 3) == ["d", "a", "b"]


def test_restore_sanitizes_persisted_history():
    assert logic.restore_history(["a", 3, "", "a", "b\x00", "c", "d"], 3) == ["a", "c", "d"]
    assert logic.restore_history({"not": "an array"}, 5) == []
    assert logic.restore_history(None, 5) == []


def test_preview_collapses_whitespace():
    assert logic.clipboard_preview("  a\n\n b\tc  ") == "a b c"


# ── Duration ───────────────────────────────────────────────────────────────


def test_humanize():
    assert logic.humanize_seconds(3900) == "1h 5m"
    assert logic.humanize_seconds(600) == "10m"
    assert logic.humanize_seconds(0) == ""
    assert logic.humanize_seconds(-5) == ""
    assert logic.humanize_seconds(math.nan) == ""


def test_battery_time_text():
    assert logic.battery_time_text(True, 3600) == "1h 0m to full"
    assert logic.battery_time_text(False, 600) == "10m left"
    assert logic.battery_time_text(False, 0) == ""


# ── Notifications ──────────────────────────────────────────────────────────


def test_timeout_critical_never_expires():
    assert logic.notification_timeout_ms(5000, True, False) == 0


def test_timeout_defaults_by_urgency():
    assert logic.notification_timeout_ms(-1, False, False) == 5000
    assert logic.notification_timeout_ms(0, False, True) == 4000


def test_timeout_seconds_and_cap():
    assert logic.notification_timeout_ms(3, False, False) == 3000
    assert logic.notification_timeout_ms(8000, False, False) == 8000
    assert logic.notification_timeout_ms(60000, False, False) == 10000


def test_plain_text_strips_markup():
    assert logic.plain_text("<b>Hi</b> &amp; <i>bye</i>") == "Hi & bye"
    assert logic.plain_text("a<br/>b") == "a\nb"
    assert logic.plain_text("1 &lt; 2") == "1 < 2"
    assert logic.plain_text("") == ""


def test_urgency_name():
    assert logic.urgency_name(Urgency.CRITICAL) == "critical"
    assert logic.urgency_name(Urgency.LOW) == "low"


# ── Indicators ─────────────────────────────────────────────────────────────


def test_battery_glyph_and_tone():
    assert logic.icon_for_battery(50, True) == chr(0xF0084)
    assert logic.icon_for_battery(100, False) == chr(0xF0079)
    assert logic.icon_for_battery(5, False) == chr(0xF0083)
    assert logic.icon_for_battery(50, False) == chr(0xF007A + 4)
    assert logic.battery_tone(10, False) == "critical"
    assert logic.battery_tone(25, False) == "low"
    assert logic.battery_tone(80, False) == "normal"


def test_volume_and_brightness_glyphs():
    assert logic.icon_for_volume(50, False, False) == chr(0xF0581)
    assert logic.icon_for_volume(50, True, True) == chr(0xF075F)
    assert logic.icon_for_volume(80, False, True) == chr(0xF057E)
    assert logic.icon_for_brightness(0) == chr(0xF00DA)
    assert logic.icon_for_brightness(100) == chr(0xF00E0)


def test_wifi_tiers():
    assert logic.signal_tier(0.80) == 4
    assert logic.signal_tier(0.60) == 3
    assert logic.signal_tier(0.30) == 2
    assert logic.signal_tier(0.10) == 1
    assert logic.icon_for_wifi(0.8, True, True) == chr(0xF091F + 9)
    assert logic.icon_for_wifi(0.0, False, False) == chr(0xF05AA)


# ── Network dedupe ─────────────────────────────────────────────────────────


def test_dedupe_networks_keeps_best_and_sorts():
    raw = [
        ("home", 0.5, True, True, False),
        ("home", 0.8, True, True, True),
        ("cafe", 0.3, True, False, False),
    ]
    entries = logic.dedupe_networks(raw)
    assert [e.name for e in entries] == ["home", "cafe"]
    assert entries[0].signal == 80 and entries[0].connected


# ── Workspaces ─────────────────────────────────────────────────────────────


def test_workspace_pills_visibility():
    state = WorkspaceState(
        workspaces=(Workspace(1, True), Workspace(3, False)), focused_id=1, count=4
    )
    pills = logic.workspace_pills(state)
    assert pills[0] == (1, True, True, True)
    assert pills[1] == (2, False, False, False)
    assert pills[2] == (3, False, True, True)
    assert pills[3] == (4, False, False, False)


def test_next_workspace_clamps():
    assert logic.next_workspace(1, -1, 10) == 1
    assert logic.next_workspace(10, 1, 10) == 10
    assert logic.next_workspace(5, 1, 10) == 6


# ── Wallpaper ──────────────────────────────────────────────────────────────


def test_wallpaper_policy():
    assert logic.is_supported_wallpaper("/x/a.JPG") is True
    assert logic.is_supported_wallpaper("/x/a.txt") is False
    assert logic.parse_wallpaper_listing("  a.png\n", "/w") == "/w/a.png"
    assert logic.parse_wallpaper_listing("a.txt", "/w") == ""
    assert logic.next_index(2, 3) == 0
    assert logic.prev_index(0, 3) == 2
    assert logic.random_index(3, 0.5) == 1
    assert logic.random_index(0, 0.5) == -1


# ── Tray / colour scheme / clock ───────────────────────────────────────────


def test_tray_suppression():
    assert logic.is_tray_item_suppressed("nm-applet", "Network") is True
    assert logic.is_tray_item_suppressed("blueman", "") is True
    assert logic.is_tray_item_suppressed("discord", "Discord") is False
    assert logic.is_tray_item_suppressed("", "") is False


def test_color_scheme_mode():
    assert logic.color_scheme_mode_for_line("'prefer-dark'") == "dark"
    assert logic.color_scheme_mode_for_line("prefer-light") == "light"
    assert logic.color_scheme_mode_for_line("") == ""


def test_format_clock():
    now = datetime(2026, 10, 9, 7, 5)
    assert logic.format_clock(now) == ("Oct 9", "07:05")


def test_is_finite():
    assert logic.is_finite(3) is True
    assert logic.is_finite(3.5) is True
    assert logic.is_finite(float("inf")) is False
    assert logic.is_finite(float("nan")) is False
    assert logic.is_finite("x") is False
    assert logic.is_finite(True) is False


def test_battery_from_sysfs():
    battery = logic.battery_from_sysfs(True, 60.0, 100.0, False, 600)
    assert battery.present and battery.level == 60 and battery.state == "Discharging"
    assert battery.time_text == "10m left"
    assert logic.battery_from_sysfs(False, 0, 0, False, 0).present is False
