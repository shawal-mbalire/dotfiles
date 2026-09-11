"""Verify an adapter satisfies a domain port contract.

Fail loud: the first adapter that drifts from its port aborts with a precise
message, mirroring ``hypr/domain/ports/verify.lua``. The port protocols are
re-exported here so the composition root can name them.
"""

from __future__ import annotations

from typing import Protocol

from domain.ports.artifacts import ConfigWriter, StyleWriter
from domain.ports.core import CommandRunner, LifetimePort, Logger, TimePort

__all__ = [
    "CommandRunner",
    "ConfigWriter",
    "LifetimePort",
    "Logger",
    "StyleWriter",
    "TimePort",
    "assert_port",
    "assert_ports",
]


def assert_port(adapter: object, port: type[Protocol]) -> None:
    if not isinstance(adapter, port):
        raise TypeError(f"{type(adapter).__name__} does not implement {port.__name__}")


def assert_ports(adapter: object, ports: tuple[type[Protocol], ...]) -> None:
    for port in ports:
        assert_port(adapter, port)
