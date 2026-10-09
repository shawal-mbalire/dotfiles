"""Wi-Fi and Bluetooth workflows."""

from __future__ import annotations

from domain.errors import NotFoundError, ValidationError
from domain.ports import BluetoothPort, LoggerPort, NetworkPort
from domain.result import Result, fail, ok


class NetworkWorkflow:
    def __init__(self, network: NetworkPort, logger: LoggerPort) -> None:
        self._network = network
        self._logger = logger

    def _require_known(self, name: str) -> Result[str]:
        known = {entry.name for entry in self._network.read().networks}
        if name not in known:
            return fail(NotFoundError("network is not in the scan list", context={"name": name}))
        return ok(name)

    def connect(self, name: str) -> Result[str]:
        result = self._require_known(name)
        if result.is_failure():
            return result
        self._network.connect_to(name)
        self._logger.info("network", "connecting", name=name)
        return ok(name)

    def connect_with_psk(self, name: str, psk: str) -> Result[str]:
        if not psk:
            return fail(ValidationError("psk must not be empty", context={"name": name}))
        result = self._require_known(name)
        if result.is_failure():
            return result
        self._network.connect_with_psk(name, psk)
        self._logger.info("network", "connecting with psk", name=name)
        return ok(name)

    def set_wifi_enabled(self, enabled: bool) -> Result[bool]:
        self._network.set_wifi_enabled(enabled)
        return ok(enabled)

    def set_scanning(self, scanning: bool) -> Result[bool]:
        self._network.set_scanning(scanning)
        return ok(scanning)


class BluetoothWorkflow:
    def __init__(self, bluetooth: BluetoothPort, logger: LoggerPort) -> None:
        self._bluetooth = bluetooth
        self._logger = logger

    def set_enabled(self, enabled: bool) -> Result[bool]:
        if not self._bluetooth.read().available:
            self._logger.warning("bluetooth", "no adapter; ignoring toggle")
            return ok(enabled)
        self._bluetooth.set_enabled(enabled)
        return ok(enabled)

    def toggle(self) -> Result[bool]:
        return self.set_enabled(not self._bluetooth.read().enabled)
