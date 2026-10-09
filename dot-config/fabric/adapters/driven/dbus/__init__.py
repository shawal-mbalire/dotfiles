"""A minimal, standard-library D-Bus client and server.

Provides the native transport used by the NetworkManager, BlueZ, notification,
portal, and logind adapters. No third-party dependency and no CLI shell-out.
"""

from __future__ import annotations

from adapters.driven.dbus.codec import Variant, marshal, unmarshal
from adapters.driven.dbus.message import DBusError
from adapters.driven.dbus.transport import (
    BusConnection,
    IncomingCall,
    session_address,
    system_address,
)

__all__ = [
    "BusConnection",
    "DBusError",
    "IncomingCall",
    "Variant",
    "marshal",
    "session_address",
    "system_address",
    "unmarshal",
]
