"""Driven adapter: network state from ``/proc`` and ``/sys`` (subprocess-free)."""

from __future__ import annotations

import fcntl
import socket
import struct
from pathlib import Path

from domain.models import NetworkStatus

SIOCGIFADDR = 0x8915
DEFAULT_ROUTE_DESTINATION = "00000000"
RTF_UP = 0x1
NET_ROOT = Path("/sys/class/net")


def default_interface(route_table: str) -> str | None:
    """Return the interface carrying the default route."""
    for line in route_table.splitlines()[1:]:
        fields = line.split()
        if len(fields) < 4:
            continue
        interface, destination, _gateway, flags = fields[0], fields[1], fields[2], fields[3]
        try:
            up = int(flags, 16) & RTF_UP
        except ValueError:
            continue
        if destination == DEFAULT_ROUTE_DESTINATION and up:
            return interface
    return None


def ipv4_address(interface: str) -> str | None:
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
            request = struct.pack("256s", interface[:15].encode())
            response = fcntl.ioctl(sock.fileno(), SIOCGIFADDR, request)
        return socket.inet_ntoa(response[20:24])
    except OSError:
        return None


def is_wireless(interface: str, net_root: Path = NET_ROOT) -> bool:
    return (Path(net_root) / interface / "wireless").exists()


class ProcNetwork:
    def __init__(
        self,
        route_file: Path = Path("/proc/net/route"),
        net_root: Path = NET_ROOT,
    ) -> None:
        self._route_file = Path(route_file)
        self._net_root = Path(net_root)

    def status(self) -> NetworkStatus:
        try:
            route_table = self._route_file.read_text()
        except OSError:
            return NetworkStatus()

        interface = default_interface(route_table)
        if interface is None:
            return NetworkStatus()

        return NetworkStatus(
            interface=interface,
            ip_address=ipv4_address(interface),
            wireless=is_wireless(interface, self._net_root),
        )
