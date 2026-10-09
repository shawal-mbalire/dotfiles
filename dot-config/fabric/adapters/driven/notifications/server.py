"""NotificationServerAdapter — NotificationFeedPort over org.freedesktop.Notifications.

Owns a D-Bus name and serves Notify / GetCapabilities / CloseNotification, and
emits NotificationClosed / ActionInvoked. No notification-daemon shell-out.
"""

from __future__ import annotations

import threading
import time

from adapters.driven.dbus import BusConnection
from adapters.driven.observable import Observable
from domain import logic
from domain.models import NotificationEntry, NotificationFeed, Urgency
from domain.ports import ClockPort

IFACE = "org.freedesktop.Notifications"
PATH = "/org/freedesktop/Notifications"
SERVICE = IFACE

REASON_EXPIRED = 1
REASON_DISMISSED = 2
REASON_CLOSE_METHOD = 3

CAPABILITIES = ["actions", "body", "body-markup", "icon-static", "persistence", "urgency"]


class NotificationServerAdapter(Observable[NotificationFeed]):
    def __init__(
        self,
        bus: BusConnection,
        clock: ClockPort,
        *,
        max_visible: int = 5,
        max_history: int = 20,
        logger=None,
    ) -> None:
        super().__init__(NotificationFeed())
        self._bus = bus
        self._clock = clock
        self._max_visible = max_visible
        self._max_history = max_history
        self._logger = logger
        self._active: list[NotificationEntry] = []
        self._history: list[NotificationEntry] = []
        self._next_key = 1
        self._actions: dict[int, list[tuple[str, str]]] = {}
        self._refs: dict[int, object] = {}
        self._timings: dict[int, dict] = {}
        self._lock = threading.RLock()
        self._stop = threading.Event()
        self._thread: threading.Thread | None = None

    def start(self) -> None:
        self._bus.request_name(SERVICE, 0)
        self._bus.on_method_call(IFACE, "Notify", self._handle_notify)
        self._bus.on_method_call(IFACE, "GetCapabilities", self._handle_capabilities)
        self._bus.on_method_call(IFACE, "GetServerInformation", self._handle_server_info)
        self._bus.on_method_call(IFACE, "CloseNotification", self._handle_close)
        self._thread = threading.Thread(
            target=self._tick_loop, daemon=True, name="fabric-notifications"
        )
        self._thread.start()

    def stop(self) -> None:
        self._stop.set()

    # ── D-Bus methods ─────────────────────────────────────────────────────
    def _handle_notify(self, call) -> None:
        args = call.body if isinstance(call.body, tuple) else (call.body,)
        try:
            app_name, _replaces, app_icon, summary, body, actions, hints, timeout = args
        except (ValueError, TypeError):
            call.reply_error("org.freedesktop.Notifications.Error.Invalid", "bad Notify args")
            return
        key = self.add(
            app_name=str(app_name),
            app_icon=str(app_icon),
            summary=str(summary),
            body=str(body),
            actions=list(actions or ()),
            hints=hints if isinstance(hints, dict) else {},
            expire_timeout=int(timeout),
        )
        call.reply("u", (key,))

    def _handle_capabilities(self, call) -> None:
        call.reply("as", (CAPABILITIES,))

    def _handle_server_info(self, call) -> None:
        call.reply("ssss", ("fabric", "fabric", "1.0", "1.2"))

    def _handle_close(self, call) -> None:
        body = call.body
        if isinstance(body, int):
            key = body
        elif isinstance(body, tuple) and body and isinstance(body[0], int):
            key = body[0]
        else:
            key = 0
        self._begin_leave(key, REASON_CLOSE_METHOD)
        call.reply("", ())

    # ── port commands ─────────────────────────────────────────────────────
    def dismiss(self, key: int) -> None:
        self._begin_leave(key, REASON_DISMISSED)

    def expire(self, key: int) -> None:
        self._begin_leave(key, REASON_EXPIRED)

    def invoke_default(self, key: int) -> bool:
        with self._lock:
            actions = self._actions.get(key, [])
        for identifier, _label in actions:
            if identifier == "default":
                self._emit_action(key, identifier)
                self._begin_leave(key, REASON_CLOSE_METHOD)
                return True
        return False

    def has_default_action(self, key: int) -> bool:
        return any(identifier == "default" for identifier, _ in self._actions.get(key, []))

    def pause(self, key: int) -> bool:
        with self._lock:
            timing = self._timings.get(key)
            if timing is None or timing.get("paused") or timing.get("expires_at", 0) <= 0:
                return False
            timing["remaining_ms"] = max(0, timing["expires_at"] - self._now_ms())
            timing["paused"] = True
            return True

    def resume(self, key: int) -> bool:
        with self._lock:
            timing = self._timings.get(key)
            if timing is None or not timing.get("paused"):
                return False
            timing["expires_at"] = self._now_ms() + timing["remaining_ms"]
            timing["paused"] = False
            return True

    def clear_history(self) -> None:
        with self._lock:
            self._history = []
        self._publish()

    def dismiss_all(self) -> None:
        with self._lock:
            keys = [entry.key for entry in self._active]
        for key in keys:
            self._begin_leave(key, REASON_DISMISSED)

    # ── state machine ─────────────────────────────────────────────────────
    def add(
        self,
        *,
        app_name: str,
        app_icon: str,
        summary: str,
        body: str,
        actions: list[tuple[str, str]],
        hints: dict,
        expire_timeout: int,
    ) -> int:
        urgency = _urgency_from_hint(hints)
        is_critical = urgency == Urgency.CRITICAL
        is_transient = _bool_hint(hints, "transient")
        duration_ms = logic.notification_timeout_ms(
            expire_timeout, is_critical, urgency == Urgency.LOW
        )
        cleaned = _clean_actions(actions)
        with self._lock:
            key = self._next_key
            self._next_key += 1
            entry = NotificationEntry(
                key=key,
                app_name=app_name or "Notification",
                app_icon=app_icon or "",
                summary=summary or _fallback_summary(summary, body, app_name),
                body=body,
                urgency=urgency,
                critical=is_critical,
                transient=is_transient,
                duration_ms=duration_ms,
                received_at=self._clock.now(),
            )
            self._actions[key] = cleaned
            self._refs[key] = None
            now = self._now_ms()
            self._timings[key] = {
                "expires_at": now + duration_ms if duration_ms > 0 else 0,
                "remaining_ms": duration_ms,
                "paused": False,
            }
            self._active.append(entry)
            overflow = self._active[: -self._max_visible]
            if overflow:
                for old in overflow:
                    self._self_expire(old.key)
            if not is_transient:
                self._history.insert(0, entry)
                self._history = self._history[: self._max_history]
        self._publish()
        return key

    def _self_expire(self, key: int) -> None:
        self._remove_entry(key, emit_signal=True)

    def _begin_leave(self, key: int, reason: int) -> None:
        with self._lock:
            exists = any(entry.key == key for entry in self._active)
        if not exists:
            return
        self._remove_entry(key, emit_signal=True, reason=reason)

    def _remove_entry(self, key: int, *, emit_signal: bool, reason: int = REASON_EXPIRED) -> None:
        with self._lock:
            self._active = [entry for entry in self._active if entry.key != key]
            self._actions.pop(key, None)
            self._refs.pop(key, None)
            self._timings.pop(key, None)
        self._publish()
        if emit_signal:
            self._emit_closed(key, reason)

    def _publish(self) -> None:
        with self._lock:
            feed = NotificationFeed(
                active=tuple(self._active),
                history=tuple(self._history),
                now_ms=self._now_ms(),
            )
        self.notify(feed)

    # ── tick ──────────────────────────────────────────────────────────────
    def _tick_loop(self) -> None:
        while not self._stop.wait(0.1):
            now = self._now_ms()
            expired: list[int] = []
            with self._lock:
                for key, timing in self._timings.items():
                    expires_at = timing.get("expires_at", 0)
                    if not timing.get("paused") and expires_at > 0 and now >= expires_at:
                        expired.append(key)
            for key in expired:
                self._begin_leave(key, REASON_EXPIRED)

    def _now_ms(self) -> float:
        return time.time() * 1000.0

    # ── signals ───────────────────────────────────────────────────────────
    def _emit_closed(self, key: int, reason: int) -> None:
        self._bus.emit_signal(
            path=PATH,
            interface=IFACE,
            member="NotificationClosed",
            signature="uu",
            args=(key, reason),
        )

    def _emit_action(self, key: int, identifier: str) -> None:
        self._bus.emit_signal(
            path=PATH,
            interface=IFACE,
            member="ActionInvoked",
            signature="us",
            args=(key, identifier),
        )

    def _warn(self, message: str, **context) -> None:
        if self._logger is not None:
            self._logger.warning("notifications", message, **context)


def _urgency_from_hint(hints: dict) -> Urgency:
    from adapters.driven.dbus import Variant

    urgency = hints.get("urgency")
    if isinstance(urgency, Variant):
        urgency = urgency.value
    if not isinstance(urgency, int):
        return Urgency.NORMAL
    return {0: Urgency.LOW, 1: Urgency.NORMAL, 2: Urgency.CRITICAL}.get(urgency, Urgency.NORMAL)


def _bool_hint(hints: dict, key: str) -> bool:
    from adapters.driven.dbus import Variant

    value = hints.get(key)
    value = value.value if isinstance(value, Variant) else value
    return bool(value)


def _fallback_summary(summary: str, body: str, app_name: str) -> str:
    if summary:
        return summary
    if body:
        return app_name
    return "New notification"


def _clean_actions(actions: list) -> list[tuple[str, str]]:
    cleaned: list[tuple[str, str]] = []
    for pair in actions or ():
        if not isinstance(pair, (tuple, list)) or len(pair) < 2:
            continue
        identifier, label = pair[0], pair[1]
        if identifier == "default" or not label:
            continue
        cleaned.append((str(identifier), str(label)))
    return cleaned
