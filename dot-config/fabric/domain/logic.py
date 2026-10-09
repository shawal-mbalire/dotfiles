"""Pure domain logic.

Every function here is pure: same input → same output, no side effects, no I/O.
This is where all the behaviour extracted from the QML views lives, and it is
where the unit tests concentrate.
"""

from __future__ import annotations

from datetime import datetime

from domain import constants as C
from domain.models import (
    AppEntry,
    Battery,
    NotificationEntry,
    Urgency,
    WifiEntry,
    WorkspaceState,
)


def clamp(value: float, low: float, high: float) -> float:
    """Clamp *value* to the inclusive range [low, high]."""
    return max(low, min(high, value))


def is_finite(value: object) -> bool:
    """True when *value* is a finite real number (rejects NaN/inf/non-numbers)."""
    return (
        isinstance(value, (int, float))
        and not isinstance(value, bool)
        and value == value
        and value not in (float("inf"), float("-inf"))
    )


def glyph(codepoint: int) -> str:
    """Render a Nerd Font private-use codepoint as a string."""
    try:
        return chr(codepoint)
    except (ValueError, OverflowError):
        return C.GLYPH_MISSING


# ── Indicators ─────────────────────────────────────────────────────────────


def icon_for_battery(level: int, charging: bool) -> str:
    if charging:
        return glyph(C.GLYPH_BATTERY_CHARGING)
    if level >= 100:
        return glyph(C.GLYPH_BATTERY_FULL)
    if level < 10:
        return glyph(C.GLYPH_BATTERY_EMPTY)
    return glyph(C.GLYPH_BATTERY_STEPS + (level // 10) - 1)


def battery_tone(level: int, charging: bool) -> str:
    if charging:
        return "charging"
    if level <= C.BATTERY_CRITICAL:
        return "critical"
    if level <= C.BATTERY_LOW:
        return "low"
    return "normal"


def icon_for_brightness(level: int) -> str:
    if level <= 0:
        return glyph(C.GLYPH_BRIGHTNESS_OFF)
    if level < C.BRIGHTNESS_TIER_LOW:
        return glyph(C.GLYPH_BRIGHTNESS_LOW)
    if level < C.BRIGHTNESS_TIER_HIGH:
        return glyph(C.GLYPH_BRIGHTNESS_MED)
    return glyph(C.GLYPH_BRIGHTNESS_HIGH)


def icon_for_volume(volume: int, muted: bool, ready: bool) -> str:
    if not ready:
        return glyph(C.GLYPH_VOLUME_OFF)
    if muted:
        return glyph(C.GLYPH_VOLUME_MUTED)
    if volume <= 0:
        return glyph(C.GLYPH_VOLUME_OFF)
    if volume < C.VOLUME_TIER_LOW:
        return glyph(C.GLYPH_VOLUME_LOW)
    if volume < C.VOLUME_TIER_HIGH:
        return glyph(C.GLYPH_VOLUME_MED)
    return glyph(C.GLYPH_VOLUME_HIGH)


def signal_tier(signal: float) -> int:
    if signal >= C.SIGNAL_STRONG:
        return 4
    if signal >= C.SIGNAL_GOOD:
        return 3
    if signal >= C.SIGNAL_WEAK:
        return 2
    return 1


def icon_for_wifi(signal: float, wifi_enabled: bool, connected: bool) -> str:
    if not wifi_enabled:
        return glyph(C.GLYPH_WIFI_OFF)
    if not connected:
        return glyph(C.GLYPH_WIFI_DISCONNECTED)
    return glyph(C.GLYPH_WIFI_SIGNAL_BASE + (signal_tier(signal) - 1) * 3)


def icon_for_bluetooth(enabled: bool, connected: bool) -> str:
    if not enabled:
        return glyph(C.GLYPH_BLUETOOTH_OFF)
    if connected:
        return glyph(C.GLYPH_BLUETOOTH_CONNECTED)
    return glyph(C.GLYPH_BLUETOOTH_ON)


def icon_for_dark_mode(dark: bool) -> str:
    return glyph(C.GLYPH_DARK_MODE if dark else C.GLYPH_LIGHT_MODE)


# ── Colour tone → theme key resolution (pure; adapter maps key → colour) ────


def tone_key_for_battery(level: int, charging: bool) -> str:
    return {
        "charging": "green",
        "critical": "red",
        "low": "peach",
        "normal": "green",
    }[battery_tone(level, charging)]


# ── Workspaces ─────────────────────────────────────────────────────────────


def workspace_pills(state: WorkspaceState) -> tuple[tuple[int, bool, bool, bool], ...]:
    """Return (id, active, occupied, visible) tuples for the workspace strip."""
    occupied_ids = {ws.id for ws in state.workspaces}
    out: list[tuple[int, bool, bool, bool]] = []
    for wid in range(1, state.count + 1):
        active = state.focused_id == wid
        occupied = wid in occupied_ids
        out.append((wid, active, occupied, occupied or active))
    return tuple(out)


def next_workspace(focused: int, step: int, count: int) -> int:
    if count <= 0:
        return focused
    return int(clamp(focused + step, 1, count))


# ── Wi-Fi network list (pure transform) ────────────────────────────────────


def dedupe_networks(raw: list[tuple[str, float, bool, bool, bool]]) -> list[WifiEntry]:
    """Dedupe by SSID keeping the best entry, then sort.

    raw entries are (name, signal_0_1, secured, known, connected). A later entry
    wins if it is connected, or if the previous is not connected and its signal
    is stronger.
    """
    best: dict[str, tuple[str, float, bool, bool, bool]] = {}
    for entry in raw:
        name = entry[0]
        prev = best.get(name)
        if prev is None:
            best[name] = entry
            continue
        _, prev_signal, _, _, prev_connected = prev
        _, signal, _, _, connected = entry
        if connected or (not prev_connected and signal > prev_signal):
            best[name] = entry

    entries = [
        WifiEntry(
            name=name,
            signal=round(signal * 100),
            secured=secured,
            known=known,
            connected=connected,
        )
        for (name, signal, secured, known, connected) in best.values()
    ]
    entries.sort(key=lambda e: (not e.connected, -e.signal))
    return entries


# ── App search (from domain/models/appSearch.js) ───────────────────────────

SCORE_PREFIX = 0
SCORE_WORD_PREFIX = 1
SCORE_NAME_CONTAINS = 2
SCORE_METADATA = 3
SCORE_SUBSEQUENCE = 4

_WORD_SEPARATORS = " \t-_."


def is_subsequence(needle: str, haystack: str) -> bool:
    it = iter(haystack)
    return all(ch in it for ch in needle)


def score_app(app: AppEntry, query: str) -> int:
    """Lower score = better match. -1 means no match."""
    name = app.name.lower()
    if name.startswith(query):
        return SCORE_PREFIX

    words = name.replace("-", " ").replace("_", " ").replace(".", " ").split()
    if any(word.startswith(query) for word in words):
        return SCORE_WORD_PREFIX

    if query in name:
        return SCORE_NAME_CONTAINS

    metadata = " ".join([app.generic_name, app.comment, *app.keywords]).lower()
    if query in metadata:
        return SCORE_METADATA

    if len(query) > 1 and is_subsequence(query, name):
        return SCORE_SUBSEQUENCE

    return -1


def filter_apps(apps: tuple[AppEntry, ...] | list[AppEntry], query: str) -> list[AppEntry]:
    q = (query or "").strip().lower()
    if q == "":
        return list(apps)
    scored = [(score_app(app, q), index, app) for index, app in enumerate(apps)]
    matched = [(s, i, app) for (s, i, app) in scored if s >= 0]
    matched.sort(key=lambda t: (t[0], t[1]))
    return [app for _, _, app in matched]


# ── Clipboard (from domain/models/clipboard.js) ────────────────────────────

TAB = 9
LF = 10
CR = 13
FIRST_PRINTABLE = 32


def is_usable_text(text: str, max_chars: int = C.CLIPBOARD_MAX_CHARS) -> bool:
    if not text or not text.strip():
        return False
    if len(text) > max_chars:
        return False
    for ch in text:
        code = ord(ch)
        if code < FIRST_PRINTABLE and code not in (TAB, LF, CR):
            return False
    return True


def push_unique(history: list[str], text: str, limit: int) -> list[str]:
    return [text, *[t for t in history if t != text]][:limit]


def clipboard_preview(text: str) -> str:
    return " ".join(text.split())


def restore_history(saved: object, limit: int) -> list[str]:
    if not isinstance(saved, list):
        return []
    out: list[str] = []
    for item in saved:
        if isinstance(item, str) and is_usable_text(item) and item not in out:
            out.append(item)
        if len(out) >= limit:
            break
    return out


# ── Duration ───────────────────────────────────────────────────────────────


def humanize_seconds(seconds: float) -> str:
    if seconds is None or seconds != seconds or seconds <= 0:  # NaN-safe
        return ""
    hours = int(seconds // C.SECONDS_PER_HOUR)
    minutes = int(round((seconds % C.SECONDS_PER_HOUR) / C.SECONDS_PER_MINUTE))
    if hours > 0:
        return f"{hours}h {minutes}m"
    return f"{minutes}m"


def battery_time_text(charging: bool, seconds: float) -> str:
    text = humanize_seconds(seconds)
    if text == "":
        return ""
    return f"{text} to full" if charging else f"{text} left"


# ── Notifications (from domain/models/notification.js) ─────────────────────


def notification_timeout_ms(expire_timeout: float, is_critical: bool, is_low: bool) -> int:
    if is_critical:
        return 0
    if not (expire_timeout > 0):
        ms = C.NOTIFICATION_TIMEOUT_LOW_MS if is_low else C.NOTIFICATION_TIMEOUT_NORMAL_MS
    elif expire_timeout <= C.SECONDS_THRESHOLD:
        ms = int(expire_timeout * C.MS_PER_SECOND)
    else:
        ms = int(expire_timeout)
    return min(ms, C.NOTIFICATION_TIMEOUT_MAX_MS)


def urgency_name(urgency: Urgency) -> str:
    return {
        Urgency.LOW: "low",
        Urgency.NORMAL: "normal",
        Urgency.CRITICAL: "critical",
    }[urgency]


def plain_text(text: str) -> str:
    if not text:
        return ""
    out = text
    for br in ("<br>", "<br/>", "<br />", "<BR>", "<BR/>", "<BR />"):
        out = out.replace(br, "\n")
    # Strip simple tags without a regex library dependency.
    result_chars: list[str] = []
    in_tag = False
    for ch in out:
        if ch == "<":
            in_tag = True
        elif ch == ">":
            in_tag = False
        elif not in_tag:
            result_chars.append(ch)
    out = "".join(result_chars)
    for entity, replacement in (
        ("&lt;", "<"),
        ("&gt;", ">"),
        ("&quot;", '"'),
        ("&apos;", "'"),
        ("&#39;", "'"),
        ("&amp;", "&"),
    ):
        out = out.replace(entity, replacement)
    return out.strip()


def notification_progress(
    entry: NotificationEntry, now_ms: float, remaining_ms: float, paused: bool, expires_at: float
) -> float:
    if entry.duration_ms <= 0:
        return 0.0
    end = now_ms + remaining_ms if paused else expires_at
    return clamp((end - now_ms) / entry.duration_ms, 0.0, 1.0)


# ── Wallpaper (from Domain/Constants/WallpaperPolicy.qml) ──────────────────


def is_supported_wallpaper(path: str) -> bool:
    if not path:
        return False
    dot = path.rfind(".")
    if dot <= 0:
        return False
    return path[dot + 1 :].lower() in C.WALLPAPER_EXTENSIONS


def join_path(directory: str, name: str) -> str:
    if not directory:
        return name
    return directory.rstrip("/") + "/" + name


def parse_wallpaper_listing(line: str, directory: str) -> str:
    name = line.strip()
    if name == "" or not is_supported_wallpaper(name):
        return ""
    return join_path(directory, name)


def next_index(index: int, length: int) -> int:
    if length <= 0:
        return -1
    return (index + 1) % length


def prev_index(index: int, length: int) -> int:
    if length <= 0:
        return -1
    return (index - 1) % length


def random_index(length: int, unit_random: float) -> int:
    if length <= 0:
        return -1
    r = unit_random if 0.0 <= unit_random < 1.0 else 0.0
    return int(r * length)


# ── System tray policy ─────────────────────────────────────────────────────

import re as _re  # noqa: E402  (kept local to this module's policy section)

_TRAY_SUPPRESS = _re.compile(C.TRAY_SUPPRESS_PATTERN, _re.IGNORECASE)


def is_tray_item_suppressed(item_id: str, title: str) -> bool:
    if item_id == "" and title == "":
        return False
    return bool(_TRAY_SUPPRESS.search(f"{item_id or ''} {title or ''}"))


# ── Colour scheme sync ─────────────────────────────────────────────────────


def color_scheme_mode_for_line(line: str) -> str:
    if not line:
        return ""
    if "prefer-dark" in line:
        return "dark"
    if "prefer-light" in line:
        return "light"
    return ""


# ── Clock formatting ───────────────────────────────────────────────────────


_MONTHS = (
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
)


def format_clock(now: datetime) -> tuple[str, str]:
    """Return (date_text "MMM d", time_text "HH:MM")."""
    return (f"{_MONTHS[now.month - 1]} {now.day}", f"{now.hour:02d}:{now.minute:02d}")


def format_hhmm(now: datetime) -> str:
    return f"{now.hour:02d}:{now.minute:02d}"


# ── Battery reading helper ─────────────────────────────────────────────────


def battery_from_sysfs(
    present: bool, energy_now: float, energy_full: float, charging: bool, seconds: float
) -> Battery:
    if not present or energy_full <= 0:
        return Battery(present=False, state="Unknown", time_text="")
    level = int(clamp(round(energy_now / energy_full * 100), 0, 100))
    state = "Charging" if charging else "Discharging"
    return Battery(
        present=True,
        level=level,
        charging=charging,
        state=state,
        time_text=battery_time_text(charging, seconds),
    )


_STATUS_TO_STATE = {
    "charging": "Charging",
    "discharging": "Discharging",
    "full": "Full",
    "not charging": "Plugged in",
    "unknown": "Unknown",
}


def battery_state_text(status: str) -> str:
    return _STATUS_TO_STATE.get((status or "").strip().lower(), "Unknown")


def battery_from_capacity(
    present: bool, capacity: float, status: str, seconds_to_empty: float, seconds_to_full: float
) -> Battery:
    """Map raw sysfs values to a Battery reading."""
    if not present:
        return Battery(present=False, state="Unknown", time_text="")
    charging = (status or "").strip().lower() == "charging"
    level = int(clamp(round(capacity), 0, 100))
    seconds = seconds_to_full if charging else seconds_to_empty
    return Battery(
        present=True,
        level=level,
        charging=charging,
        state=battery_state_text(status),
        time_text=battery_time_text(charging, seconds),
    )


def brightness_percent(raw: int, max_raw: int) -> int:
    if max_raw <= 0:
        return 0
    return int(clamp(round(raw * 100 / max_raw), 0, 100))


def raw_from_percent(percent: int, max_raw: int) -> int:
    if max_raw <= 0:
        return 0
    return int(round(clamp(percent, 0, 100) * max_raw / 100))
