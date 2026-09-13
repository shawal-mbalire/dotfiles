# Embedded Systems — Hexagonal Architecture Guide

Embedded-specific patterns for hexagonal architecture covering MicroPython and C++ (ESP32, STM32, Arduino). See [SKILL.md](./SKILL.md) for core architecture principles and [python.md](./python.md) / [cpp.md](./cpp.md) for language-specific details.

## Constraints

Embedded systems impose unique constraints that shape hexagonal architecture:

- **Limited RAM/Flash** — minimize allocations, prefer stack over heap
- **Real-time deadlines** — ISRs must be fast, defer work to main loop
- **Hardware abstraction** — ports abstract GPIO, SPI, I2C, ADC
- **Power management** — adapters handle sleep/wake cycles
- **No OS or RTOS** — bare-metal or cooperative scheduling
- **Device-specific tooling** — `ampy`, `esptool`, `openocd`, `platformio`
- **Adapter-as-ORM** — no ORM on any target; the repository adapter owns its SQL and maps rows to domain models (see [SKILL.md](./SKILL.md) persistence rules)
- **No embedded DuckDB** — the local-first DuckDB hub (see [SKILL.md](./SKILL.md)) targets dev/desktop; on MCU targets keep logs/metrics/events in RAM or SQLite and upload or flush through a port

## Driving Adapters: ISR / RTOS / Main Loop

In embedded, the driving adapters are hardware events, not HTTP routes:

| Driving Adapter | Trigger | Speed Requirement |
|----------------|---------|-------------------|
| **ISR (Interrupt)** | Button press, sensor edge, timer overflow | Must return in microseconds — defer to main loop |
| **RTOS Task** | Periodic sensor read, MQTT heartbeat | Cooperative scheduling, can block |
| **Main Loop** | Background polling, state machine | Runs forever, calls workflows each iteration |

```
ISR (Button Press)
  │
  ├─ Sets flag / pushes event to queue
  │  (DO NOT call workflow directly from ISR)
  │
RTOS Task (Sensor Read)
  │
  ├─ Calls workflow.execute() on schedule
  │
Main Loop
  │
  ├─ Checks flags / dequeues events
  ├─ Calls workflow.execute()
  └─ Handles power management (sleep/wake)
```

**Rule:** Never call domain workflows directly from an ISR. ISRs set flags or push events to a queue. The main loop or RTOS task processes them.

## Project Structure

```
embedded/
├── domain/
│   ├── models/
│   │   └── device_state
│   ├── constants
│   ├── errors/
│   ├── ports/
│   │   ├── relay_port
│   │   ├── sensor_port
│   │   ├── logger_port
│   │   └── timer_port
│   └── workflows/
│       ├── pump_controller
│       └── data_collector
├── infra/
│   └── config
├── adapters/
│   ├── esp32_relay_adapter
│   ├── dht_sensor_adapter
│   ├── serial_logger
│   └── hardware_timer_adapter
├── tests/
│   ├── unit/
│   └── integration/
├── main.py  (MicroPython) or main.cpp (C++)
└── justfile
```

## MicroPython Example (Irrigation Controller)

```python
# domain/ports/relay_port.py
from abc import ABC, abstractmethod

class RelayPort(ABC):
    @abstractmethod
    def turn_on(self) -> None: ...

    @abstractmethod
    def turn_off(self) -> None: ...

# domain/ports/sensor_port.py
from abc import ABC, abstractmethod

class SensorPort(ABC):
    @abstractmethod
    def read_temperature(self) -> float: ...

    @abstractmethod
    def read_humidity(self) -> float: ...

# domain/ports/logger_port.py
from abc import ABC, abstractmethod

class LoggerPort(ABC):
    @abstractmethod
    def info(self, message: str) -> None: ...

    @abstractmethod
    def error(self, message: str) -> None: ...

# domain/ports/timer_port.py
from abc import ABC, abstractmethod

class TimerPort(ABC):
    @abstractmethod
    def now_ms(self) -> int: ...

    @abstractmethod
    def sleep_ms(self, ms: int) -> None: ...

# domain/ports/lifetime_port.py
from abc import ABC, abstractmethod
from typing import Callable

class LifetimePort(ABC):
    @abstractmethod
    def register_cleanup(self, handler: Callable[[], None]) -> None: ...

    @abstractmethod
    def on_exit(self, handler: Callable[[str], None]) -> None: ...

    @abstractmethod
    def get_exit_reason(self) -> str: ...

    @abstractmethod
    def is_shutting_down(self) -> bool: ...

# domain/models/device_state.py
class IrrigationState:
    def __init__(self):
        self.is_active = False
        self.last_toggle_ms = 0
        self.cycle_count = 0

# domain/constants.py
from dataclasses import dataclass

# Static constants
MIN_TOGGLE_INTERVAL_MS = 5000  # Debounce: 5 seconds between toggles
MAX_DAILY_CYCLES = 10          # Safety limit

# Configurable constants
@dataclass(frozen=True)
class IrrigationConfig:
    relay_pin: int
    sensor_pin: int
    moisture_threshold: float
    check_interval_ms: int

# domain/workflows/pump_controller.py
from domain.ports.relay_port import RelayPort
from domain.ports.sensor_port import SensorPort
from domain.ports.logger_port import LoggerPort
from domain.ports.timer_port import TimerPort
from domain.models.device_state import IrrigationState
from domain.constants import IrrigationConfig, MIN_TOGGLE_INTERVAL_MS, MAX_DAILY_CYCLES

class PumpController:
    def __init__(
        self,
        pump_relay: RelayPort,
        sensor: SensorPort,
        logger: LoggerPort,
        timer: TimerPort,
        config: IrrigationConfig,
    ):
        self.pump = pump_relay
        self.sensor = sensor
        self.logger = logger
        self.timer = timer
        self.config = config
        self.state = IrrigationState()

    def check_and_toggle(self):
        now = self.timer.now_ms()

        # Debounce check
        if now - self.state.last_toggle_ms < MIN_TOGGLE_INTERVAL_MS:
            return

        # Safety limit check
        if self.state.cycle_count >= MAX_DAILY_CYCLES:
            self.logger.error("Daily cycle limit reached")
            return

        temperature = self.sensor.read_temperature()
        humidity = self.sensor.read_humidity()

        self.logger.info(f"Temp: {temperature}C, Humidity: {humidity}%")

        if humidity < self.config.moisture_threshold and not self.state.is_active:
            self.pump.turn_on()
            self.state.is_active = True
            self.state.last_toggle_ms = now
            self.state.cycle_count += 1
            self.logger.info("Irrigation started")

        elif humidity >= self.config.moisture_threshold and self.state.is_active:
            self.pump.turn_off()
            self.state.is_active = False
            self.state.last_toggle_ms = now
            self.logger.info("Irrigation stopped")

# infra/config.py
import os

class EmbeddedConfig:
    RELAY_PIN = int(os.getenv("RELAY_PIN", "14"))
    SENSOR_PIN = int(os.getenv("SENSOR_PIN", "4"))
    MOISTURE_THRESHOLD = float(os.getenv("MOISTURE_THRESHOLD", "60.0"))
    CHECK_INTERVAL_MS = int(os.getenv("CHECK_INTERVAL_MS", "30000"))
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

# adapters/serial_logger.py
from domain.ports.logger_port import LoggerPort

class SerialLogger(LoggerPort):
    def info(self, message: str) -> None:
        print(f"[INFO] {message}")

    def error(self, message: str) -> None:
        print(f"[ERROR] {message}")

# adapters/sensor_mappings.py (Pure helpers — no hardware, trivial to test)
from domain.models.device_state import IrrigationState

def format_sensor_reading(temperature: float, humidity: float) -> str:
    """Format sensor data for logging. Pure function."""
    return f"Temp: {temperature:.1f}C, Humidity: {humidity:.1f}%"

def should_activate_irrigation(humidity: float, threshold: float, is_active: bool) -> bool:
    """Decide if irrigation should start. Pure function — no I/O."""
    return humidity < threshold and not is_active

def should_deactivate_irrigation(humidity: float, threshold: float, is_active: bool) -> bool:
    """Decide if irrigation should stop. Pure function — no I/O."""
    return humidity >= threshold and is_active

# tests/unit/test_sensor_mappings.py (Test pure helpers — no hardware needed)
from adapters.sensor_mappings import format_sensor_reading, should_activate_irrigation

def test_format_sensor_reading():
    result = format_sensor_reading(23.5, 60.0)
    assert result == "Temp: 23.5C, Humidity: 60.0%"

def test_should_activate_when_humidity_low():
    assert should_activate_irrigation(40.0, 60.0, False) is True

def test_should_not_activate_when_already_active():
    assert should_activate_irrigation(40.0, 60.0, True) is False

def test_should_not_activate_when_humidity_high():
    assert should_activate_irrigation(80.0, 60.0, False) is False

# adapters/esp32_relay_adapter.py
from machine import Pin
from domain.ports.relay_port import RelayPort

class ESP32RelayAdapter(RelayPort):
    def __init__(self, pin_number: int):
        self.pin = Pin(pin_number, Pin.OUT, value=0)

    def turn_on(self) -> None:
        self.pin.value(1)

    def turn_off(self) -> None:
        self.pin.value(0)

# adapters/dht_sensor_adapter.py
from machine import Pin
import dht
from domain.ports.sensor_port import SensorPort

class DHTSensorAdapter(SensorPort):
    def __init__(self, pin_number: int):
        self.sensor = dht.DHT22(Pin(pin_number))

    def read_temperature(self) -> float:
        self.sensor.measure()
        return self.sensor.temperature()

    def read_humidity(self) -> float:
        self.sensor.measure()
        return self.sensor.humidity()

# adapters/hardware_timer_adapter.py
import time
from domain.ports.timer_port import TimerPort

class HardwareTimerAdapter(TimerPort):
    def now_ms(self) -> int:
        return time.ticks_ms()

    def sleep_ms(self, ms: int) -> None:
        time.sleep_ms(ms)

# adapters/watchdog_lifetime.py (Embedded-specific exit detection)
import machine
from domain.ports.lifetime_port import LifetimePort
from typing import Callable

class WatchdogLifetimeAdapter(LifetimePort):
    def __init__(self):
        self._cleanup_handlers: list[Callable[[], None]] = []
        self._exit_handlers: list[Callable[[str], None]] = []
        self._exit_reason = "normal"
        self._shutting_down = False
        self._watchdog = None

    def register_cleanup(self, handler: Callable[[], None]) -> None:
        self._cleanup_handlers.append(handler)

    def on_exit(self, handler: Callable[[str], None]) -> None:
        self._exit_handlers.append(handler)

    def get_exit_reason(self) -> str:
        return self._exit_reason

    def is_shutting_down(self) -> bool:
        return self._shutting_down

    def _handle_interrupt(self, pin):
        self._shutting_down = True
        self._exit_reason = "user_exit"
        for handler in self._exit_handlers:
            handler(self._exit_reason)
        for handler in self._cleanup_handlers:
            handler()

    def install(self, button_pin: int = 0):
        """Install interrupt handler for graceful shutdown."""
        button = machine.Pin(button_pin, machine.Pin.IN, machine.Pin.PULL_UP)
        button.irq(trigger=machine.Pin.IRQ_FALLING, handler=self._handle_interrupt)

    def enter_deep_sleep(self, sleep_seconds: int):
        """Clean up and enter deep sleep."""
        self._shutting_down = True
        self._exit_reason = "shutdown"
        for handler in self._cleanup_handlers:
            handler()
        machine.deepsleep(sleep_seconds * 1000)

# adapters/mock_lifetime.py (for testing on PC)
from domain.ports.lifetime_port import LifetimePort
from typing import Callable

class MockLifetimeAdapter(LifetimePort):
    def __init__(self):
        self._cleanup_handlers: list[Callable[[], None]] = []
        self._exit_handlers: list[Callable[[str], None]] = []
        self._exit_reason = "normal"
        self._shutting_down = False
        self.cleanup_count = 0

    def register_cleanup(self, handler: Callable[[], None]) -> None:
        self._cleanup_handlers.append(handler)

    def on_exit(self, handler: Callable[[str], None]) -> None:
        self._exit_handlers.append(handler)

    def get_exit_reason(self) -> str:
        return self._exit_reason

    def is_shutting_down(self) -> bool:
        return self._shutting_down

    def trigger_exit(self, reason: str) -> None:
        self._shutting_down = True
        self._exit_reason = reason
        for handler in self._exit_handlers:
            handler(reason)
        for handler in self._cleanup_handlers:
            handler()
            self.cleanup_count += 1

# main.py (Composition Root + Driving Adapter)
from adapters.esp32_relay_adapter import ESP32RelayAdapter
from adapters.dht_sensor_adapter import DHTSensorAdapter
from adapters.serial_logger import SerialLogger
from adapters.hardware_timer_adapter import HardwareTimerAdapter
from infra.config import EmbeddedConfig
from domain.workflows.pump_controller import PumpController
from domain.constants import IrrigationConfig

def main():
    config = IrrigationConfig(
        relay_pin=EmbeddedConfig.RELAY_PIN,
        sensor_pin=EmbeddedConfig.SENSOR_PIN,
        moisture_threshold=EmbeddedConfig.MOISTURE_THRESHOLD,
        check_interval_ms=EmbeddedConfig.CHECK_INTERVAL_MS,
    )

    relay = ESP32RelayAdapter(config.relay_pin)
    sensor = DHTSensorAdapter(config.sensor_pin)
    logger = SerialLogger()
    timer = HardwareTimerAdapter()

    controller = PumpController(
        pump_relay=relay,
        sensor=sensor,
        logger=logger,
        timer=timer,
        config=config,
    )

    # Main loop
    while True:
        controller.check_and_toggle()
        timer.sleep_ms(config.check_interval_ms)

if __name__ == "__main__":
    main()
```

## C++ Example (ESP32 with ESP-IDF)

```cpp
// domain/ports/relay_port.h
#pragma once

class RelayPort {
public:
    virtual ~RelayPort() = default;
    virtual void turn_on() = 0;
    virtual void turn_off() = 0;
};

// domain/ports/sensor_port.h
#pragma once

struct SensorReading {
    float temperature;
    float humidity;
};

class SensorPort {
public:
    virtual ~SensorPort() = default;
    virtual SensorReading read() = 0;
};

// domain/ports/logger_port.h
#pragma once
#include <string>

class LoggerPort {
public:
    virtual ~LoggerPort() = default;
    virtual void info(const std::string& message) = 0;
    virtual void error(const std::string& message) = 0;
};

// domain/ports/timer_port.h
#pragma once

class TimerPort {
public:
    virtual ~TimerPort() = default;
    virtual uint32_t now_ms() = 0;
    virtual void delay_ms(uint32_t ms) = 0;
};

// domain/models/device_state.h
#pragma once
#include <cstdint>

struct IrrigationState {
    bool is_active = false;
    uint32_t last_toggle_ms = 0;
    uint32_t cycle_count = 0;
};

// domain/constants.h
#pragma once
#include <cstdint>

// Static constants
constexpr uint32_t MIN_TOGGLE_INTERVAL_MS = 5000;
constexpr uint32_t MAX_DAILY_CYCLES = 10;

// Configurable constants
struct IrrigationConfig {
    int relay_pin;
    int sensor_pin;
    float moisture_threshold;
    uint32_t check_interval_ms;
};

// domain/workflows/pump_controller.h
#pragma once
#include <domain/ports/relay_port.h>
#include <domain/ports/sensor_port.h>
#include <domain/ports/logger_port.h>
#include <domain/ports/timer_port.h>
#include <domain/models/device_state.h>
#include <domain/constants.h>

class PumpController {
public:
    PumpController(
        RelayPort& pump_relay,
        SensorPort& sensor,
        LoggerPort& logger,
        TimerPort& timer,
        const IrrigationConfig& config
    );

    void check_and_toggle();

private:
    RelayPort& pump_;
    SensorPort& sensor_;
    LoggerPort& logger_;
    TimerPort& timer_;
    IrrigationConfig config_;
    IrrigationState state_;
};

// domain/workflows/pump_controller.cpp
#include "pump_controller.h"
#include <string>

PumpController::PumpController(
    RelayPort& pump_relay,
    SensorPort& sensor,
    LoggerPort& logger,
    TimerPort& timer,
    const IrrigationConfig& config
) : pump_(pump_relay), sensor_(sensor), logger_(logger),
    timer_(timer), config_(config) {}

void PumpController::check_and_toggle() {
    uint32_t now = timer_.now_ms();

    if (now - state_.last_toggle_ms < MIN_TOGGLE_INTERVAL_MS) {
        return;
    }

    if (state_.cycle_count >= MAX_DAILY_CYCLES) {
        logger_.error("Daily cycle limit reached");
        return;
    }

    auto reading = sensor_.read();
    logger_.info("Temp: " + std::to_string(reading.temperature) +
                 "C, Humidity: " + std::to_string(reading.humidity) + "%");

    if (reading.humidity < config_.moisture_threshold && !state_.is_active) {
        pump_.turn_on();
        state_.is_active = true;
        state_.last_toggle_ms = now;
        state_.cycle_count++;
        logger_.info("Irrigation started");
    } else if (reading.humidity >= config_.moisture_threshold && state_.is_active) {
        pump_.turn_off();
        state_.is_active = false;
        state_.last_toggle_ms = now;
        logger_.info("Irrigation stopped");
    }
}

// adapters/esp32_relay_adapter.h
#pragma once
#include <domain/ports/relay_port.h>
#include <driver/gpio.h>

class ESP32RelayAdapter : public RelayPort {
public:
    explicit ESP32RelayAdapter(gpio_num_t pin);
    void turn_on() override;
    void turn_off() override;

private:
    gpio_num_t pin_;
};

// adapters/esp32_relay_adapter.cpp
#include "esp32_relay_adapter.h"

ESP32RelayAdapter::ESP32RelayAdapter(gpio_num_t pin) : pin_(pin) {
    gpio_reset_pin(pin_);
    gpio_set_direction(pin_, GPIO_MODE_OUTPUT);
    gpio_set_level(pin_, 0);
}

void ESP32RelayAdapter::turn_on() {
    gpio_set_level(pin_, 1);
}

void ESP32RelayAdapter::turn_off() {
    gpio_set_level(pin_, 0);
}

// adapters/dht_sensor_adapter.h
#pragma once
#include <domain/ports/sensor_port.h>
#include <driver/gpio.h>

class DHTSensorAdapter : public SensorPort {
public:
    explicit DHTSensorAdapter(gpio_num_t pin);
    SensorReading read() override;

private:
    gpio_num_t pin_;
};

// adapters/dht_sensor_adapter.cpp
#include "dht_sensor_adapter.h"
#include <dht.h>

DHTSensorAdapter::DHTSensorAdapter(gpio_num_t pin) : pin_(pin) {}

SensorReading DHTSensorAdapter::read() {
    SensorReading reading;
    dht_read_float_data(DHT_TYPE_DHT22, pin_, &reading.humidity, &reading.temperature);
    return reading;
}

// adapters/serial_logger.h
#pragma once
#include <domain/ports/logger_port.h>
#include <cstdio>

class SerialLogger : public LoggerPort {
public:
    void info(const std::string& message) override {
        printf("[INFO] %s\n", message.c_str());
    }

    void error(const std::string& message) override {
        printf("[ERROR] %s\n", message.c_str());
    }
};

// adapters/esp32_timer_adapter.h
#pragma once
#include <domain/ports/timer_port.h>
#include <esp_timer.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>

class ESP32TimerAdapter : public TimerPort {
public:
    uint32_t now_ms() override {
        return esp_timer_get_time() / 1000;
    }

    void delay_ms(uint32_t ms) override {
        vTaskDelay(pdMS_TO_TICKS(ms));
    }
};

// main.cpp (Composition Root + Driving Adapter)
#include <domain/workflows/pump_controller.h>
#include <adapters/esp32_relay_adapter.h>
#include <adapters/dht_sensor_adapter.h>
#include <adapters/serial_logger.h>
#include <adapters/esp32_timer_adapter.h>
#include <domain/constants.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>

extern "C" void app_main() {
    IrrigationConfig config = {
        .relay_pin = GPIO_NUM_14,
        .sensor_pin = GPIO_NUM_4,
        .moisture_threshold = 60.0f,
        .check_interval_ms = 30000,
    };

    ESP32RelayAdapter relay(config.relay_pin);
    DHTSensorAdapter sensor(config.sensor_pin);
    SerialLogger logger;
    ESP32TimerAdapter timer;

    PumpController controller(relay, sensor, logger, timer, config);

    while (true) {
        controller.check_and_toggle();
        timer.delay_ms(config.check_interval_ms);
    }
}
```

## Lifecycle Hooks

### MicroPython

```python
# main.py (startup/shutdown for embedded)
import machine
import gc

def shutdown():
    """Called before deep sleep or power off"""
    # Turn off actuators
    relay_adapter.turn_off()
    # Close WiFi
    wifi_adapter.disconnect()
    # Force garbage collection before sleep
    gc.collect()

# Register shutdown with deep sleep
machine.Pin(0).irq(
    trigger=machine.Pin.IRQ_FALLING,
    handler=lambda p: shutdown()
)
```

### C++ / ESP-IDF

```cpp
// main.cpp (ESP32 lifecycle)
#include "esp_sleep.h"

void shutdown() {
    // Turn off actuators
    relay_adapter.turn_off();
    // Disconnect WiFi
    wifi_adapter.disconnect();
    // Enter deep sleep
    esp_sleep_enable_timer_wakeup(SLEEP_SECONDS * 1000000);
    esp_deep_sleep_start();
}

// Watchdog timer for auto-recovery
void app_main() {
    esp_task_wdt_init(TIMEOUT_SECONDS, true);
    esp_task_wdt_add(NULL);
    // ... main loop
    esp_task_wdt_reset();  // Feed watchdog each iteration
}
```

### Watchdog Pattern

| Concern | Pattern |
|---------|---------|
| Hardware watchdog | Reset timer each main loop iteration; triggers reboot on hang |
| Deep sleep | Shutdown adapters, configure wake source, enter sleep |
| Graceful stop | Set flag from ISR, main loop checks and cleans up |
| OTA updates | Stop domain, backup state, apply update, restart |

## Hard-Fail Patterns (Embedded)

```python
# BAD: soft fail — device continues with bad state
try:
    temp = sensor.read_temperature()
except:
    pass  # Sensor failed, but device keeps running with stale data

# GOOD: hard fail — log error, enter safe state
try:
    temp = sensor.read_temperature()
except Exception as e:
    logger.error(f"Sensor read failed: {e}")
    controller.enter_safe_state()
    raise  # Re-raise so watchdog can trigger recovery

# C++: hard fail with watchdog
try {
    temp = sensor.read();
} catch (const SensorError& e) {
    logger.error("sensor_read_failed", {{"error", e.what()}});
    enter_safe_state();
    // Watchdog will reboot if we don't recover
}
```

### Structured Logging (Embedded)

```python
# adapters/structured_logger.py
import json
import time

class StructuredLogger(LoggerPort):
    def __init__(self, device_id: str):
        self.device_id = device_id

    def info(self, event: str, **kwargs):
        log = {"level": "info", "device": self.device_id, "event": event, "ts": time.time()}
        log.update(kwargs)
        print(json.dumps(log))

    def error(self, event: str, **kwargs):
        log = {"level": "error", "device": self.device_id, "event": event, "ts": time.time()}
        log.update(kwargs)
        print(json.dumps(log))

# Usage
logger.info("sensor_reading", temp=23.5, humidity=60.0)
logger.error("sensor_read_failed", error="timeout", pin=4)
```

## Diagnostics & Failure Localization (Embedded)

No backtraces or ring buffers on an MCU — keep it tiny: a numeric code, a short context, and a distinct reset reason.

```python
# domain/errors/app_error.py (MicroPython)
class AppError(Exception):
    def __init__(self, code, message, context=None):
        super().__init__(message)
        self.code = code            # registry-backed, e.g. 0x0101
        self.message = message
        self.context = context or {}   # small: pin, state, retry count

class SensorTimeoutError(AppError):
    def __init__(self, pin):
        super().__init__(code=0x0101, message="sensor read timed out", context={"pin": pin})

# main loop — log the code + context, then reset with a distinct reason
try:
    read_sensor()
except AppError as e:
    logger.error("app_error", code=hex(e.code), message=e.message, **e.context)
    machine.reset_cause = e.code      # persist before reset for the next boot
    machine.reset()
```

- **Error codes are a registry too** — a small `ERROR_CODES` table in firmware maps code → meaning; keep it in sync with the host-side `errors.toml` and check in CI.
- **Breadcrumbs are expensive** — store only the last error code in NVRAM/RTC memory and log it on the next boot.
- **Fault injection** — wrap the sensor/relay ports with fakes that return `None`/timeout and assert the code + that the watchdog is fed. Run these on the host, not the device.

## Property & Formal Verification (Embedded)

- **Property tests run on the host**, not the device. The pure domain (state machines, control math, protocol framing) is exercised by `hypothesis` / `proptest` / RapidCheck against fake ports; only integration tests touch hardware.
- **Formal**: control loops and protocol state machines are exactly where **TLA+** (design) and **CBMC/ESBMC** (bounded C verification) pay off — verify the pure core before flashing, and keep ISRs trivial and side-effect-free.
- **Mutation** is usually skipped on MCU targets (tooling/size); rely on property + contract tests and the host-side mutation gate on shared domain code.

## Testing Embedded Code

The key insight: **test domain logic on your development machine, not on the device**. Only adapter integration tests run on hardware.

```python
# tests/unit/test_pump_controller.py (runs on PC, not device)
import pytest
from domain.workflows.pump_controller import PumpController
from domain.constants import IrrigationConfig, MIN_TOGGLE_INTERVAL_MS

class FakeRelay:
    def __init__(self):
        self.is_on = False
        self.on_count = 0
        self.off_count = 0

    def turn_on(self):
        self.is_on = True
        self.on_count += 1

    def turn_off(self):
        self.is_on = False
        self.off_count += 1

class FakeSensor:
    def __init__(self):
        self.temperature = 25.0
        self.humidity = 70.0

    def read_temperature(self):
        return self.temperature

    def read_humidity(self):
        return self.humidity

class FakeLogger:
    def __init__(self):
        self.messages = []
        self.info_count = 0

    def info(self, msg):
        self.messages.append(("info", msg))
        self.info_count += 1

    def error(self, msg):
        self.messages.append(("error", msg))

class FakeTimer:
    def __init__(self):
        self._now = 0

    def now_ms(self):
        return self._now

    def sleep_ms(self, ms):
        self._now += ms

@pytest.fixture
def config():
    return IrrigationConfig(
        relay_pin=14,
        sensor_pin=4,
        moisture_threshold=60.0,
        check_interval_ms=30000,
    )

@pytest.fixture
def controller(config):
    relay = FakeRelay()
    sensor = FakeSensor()
    logger = FakeLogger()
    timer = FakeTimer()
    return PumpController(relay, sensor, logger, timer, config), relay, sensor, logger, timer

def test_starts_irrigation_when_humidity_low(controller):
    ctrl, relay, sensor, logger, timer = controller
    sensor.humidity = 40.0  # Below threshold

    ctrl.check_and_toggle()

    assert relay.is_on is True
    assert ctrl.state.is_active is True
    assert "started" in logger.messages[-1][1]

def test_stops_irrigation_when_humidity_high(controller):
    ctrl, relay, sensor, logger, timer = controller
    sensor.humidity = 40.0
    ctrl.check_and_toggle()

    sensor.humidity = 80.0  # Above threshold
    ctrl.check_and_toggle()

    assert relay.is_on is False
    assert ctrl.state.is_active is False
    assert "stopped" in logger.messages[-1][1]

def test_debounce_prevents_rapid_toggle(controller):
    ctrl, relay, sensor, logger, timer = controller
    sensor.humidity = 40.0

    ctrl.check_and_toggle()
    first_on_count = relay.on_count

    # Immediate second call — should be debounced
    ctrl.check_and_toggle()
    assert relay.on_count == first_on_count

def test_safety_limit_stops_cycles(controller):
    ctrl, relay, sensor, logger, timer = controller
    sensor.humidity = 40.0

    # Exhaust daily limit
    for i in range(10):
        ctrl.check_and_toggle()
        timer.sleep_ms(MIN_TOGGLE_INTERVAL_MS + 1)
        ctrl.check_and_toggle()  # stop
        timer.sleep_ms(MIN_TOGGLE_INTERVAL_MS + 1)

    # Next attempt should be blocked
    ctrl.check_and_toggle()
    assert "limit" in logger.messages[-1][1].lower()
```

### Integration Tests (MicroPython)

Hardware-in-the-loop tests run on the device. These test real adapter behavior with actual GPIO, sensors, and timers.

```python
# tests/integration/test_relay_hardware.py
# Run on device: ampy --port /dev/tty.usbmodem* run tests/integration/test_relay_hardware.py
from adapters.esp32_relay_adapter import ESP32RelayAdapter
from adapters.serial_logger import SerialLogger
import time

def test_relay_turns_on_and_off():
    """Test real relay hardware — run on device only."""
    relay = ESP32RelayAdapter(pin_number=14)
    logger = SerialLogger()

    relay.turn_on()
    time.sleep(0.1)
    logger.info("Relay should be ON — verify with multimeter or LED")

    relay.turn_off()
    time.sleep(0.1)
    logger.info("Relay should be OFF — verify with multimeter or LED")

def test_sensor_reads_real_values():
    """Test real DHT sensor — run on device only."""
    from adapters.dht_sensor_adapter import DHTSensorAdapter

    sensor = DHTSensorAdapter(pin_number=4)
    temp = sensor.read_temperature()
    humidity = sensor.read_humidity()

    assert isinstance(temp, float), f"Temperature should be float, got {type(temp)}"
    assert isinstance(humidity, float), f"Humidity should be float, got {type(humidity)}"
    assert -40.0 <= temp <= 80.0, f"Temperature out of range: {temp}"
    assert 0.0 <= humidity <= 100.0, f"Humidity out of range: {humidity}"

def test_full_irrigation_cycle():
    """Integration test: sensor → controller → relay — run on device only."""
    from adapters.esp32_relay_adapter import ESP32RelayAdapter
    from adapters.dht_sensor_adapter import DHTSensorAdapter
    from adapters.hardware_timer_adapter import HardwareTimerAdapter
    from domain.workflows.pump_controller import PumpController
    from domain.constants import IrrigationConfig

    config = IrrigationConfig(
        relay_pin=14,
        sensor_pin=4,
        moisture_threshold=60.0,
        check_interval_ms=1000,
    )

    relay = ESP32RelayAdapter(config.relay_pin)
    sensor = DHTSensorAdapter(config.sensor_pin)
    logger = SerialLogger()
    timer = HardwareTimerAdapter()

    controller = PumpController(relay, sensor, logger, timer, config)

    # Run one check cycle
    controller.check_and_toggle()

    # Verify state was updated
    assert isinstance(controller.state.is_active, bool)
    logger.info(f"Integration test complete. Active: {controller.state.is_active}")
```

### Integration Tests (C++ / PlatformIO Native)

Native C++ tests run on the development machine, not on the device. Use PlatformIO's native test target.

```cpp
// tests/integration/test_pump_controller_integration.cpp
// Runs on development machine via: pio test -e native
#include <gtest/gtest.h>
#include <domain/workflows/pump_controller.h>
#include <domain/constants.h>

class FakeRelay : public RelayPort {
public:
    bool is_on = false;
    int on_count = 0;
    int off_count = 0;

    void turn_on() override { is_on = true; on_count++; }
    void turn_off() override { is_on = false; off_count++; }
};

class FakeSensor : public SensorPort {
public:
    float temperature = 25.0;
    float humidity = 70.0;

    SensorReading read() override {
        return {temperature, humidity};
    }
};

class FakeTimer : public TimerPort {
public:
    uint32_t current_ms = 0;

    uint32_t now_ms() override { return current_ms; }
    void delay_ms(uint32_t ms) override { current_ms += ms; }
};

class PumpControllerIntegrationTest : public ::testing::Test {
protected:
    void SetUp() override {
        config = {14, 4, 60.0f, 30000};
        controller = std::make_unique<PumpController>(relay, sensor, logger, timer, config);
    }

    FakeRelay relay;
    FakeSensor sensor;
    FakeLogger logger;
    FakeTimer timer;
    IrrigationConfig config;
    std::unique_ptr<PumpController> controller;
};

TEST_F(PumpControllerIntegrationTest, StartsIrrigationWhenHumidityLow) {
    sensor.humidity = 40.0;

    controller->check_and_toggle();

    EXPECT_TRUE(relay.is_on);
    EXPECT_TRUE(controller->state.is_active);
    EXPECT_GE(logger.info_count, 1);
}

TEST_F(PumpControllerIntegrationTest, StopsIrrigationWhenHumidityHigh) {
    sensor.humidity = 40.0;
    controller->check_and_toggle();

    sensor.humidity = 80.0;
    timer.current_ms = MIN_TOGGLE_INTERVAL_MS + 1;
    controller->check_and_toggle();

    EXPECT_FALSE(relay.is_on);
    EXPECT_FALSE(controller->state.is_active);
}

TEST_F(PumpControllerIntegrationTest, RespectsDebounceInterval) {
    sensor.humidity = 40.0;

    controller->check_and_toggle();
    int first_on_count = relay.on_count;

    // Immediate second call — should be debounced
    controller->check_and_toggle();
    EXPECT_EQ(relay.on_count, first_on_count);
}

TEST_F(PumpControllerIntegrationTest, RespectsSafetyLimit) {
    sensor.humidity = 40.0;

    // Exhaust daily limit
    for (int i = 0; i < 10; i++) {
        controller->check_and_toggle();
        timer.current_ms += MIN_TOGGLE_INTERVAL_MS + 1;
        controller->check_and_toggle(); // stop
        timer.current_ms += MIN_TOGGLE_INTERVAL_MS + 1;
    }

    // Next attempt should be blocked
    int count_before = relay.on_count;
    controller->check_and_toggle();
    EXPECT_EQ(relay.on_count, count_before);
}
```

## PlatformIO Configuration

```ini
; platformio.ini
[env:esp32]
platform = espressif32
board = esp32dev
framework = espidf
monitor_speed = 115200

[env:esp32test]
platform = espressif32
board = esp32dev
framework = espidf
test_framework = google_test
test_filter = test_pump_controller

[env:native]
platform = native
test_framework = google_test
build_flags = -std=c++20 -I.
test_filter = test_pump_controller_integration
```

## Justfile (Embedded Workspace)

```just
# embedded/justfile
set dotenv-load

PORT := env_var_or_default("PORT", "/dev/tty.usbmodem*")
BAUD := env_var_or_default("BAUD", "115200")

default:
    @just --list

logs:
    @echo "Connecting to serial port..."
    @echo "Press Ctrl+A then Ctrl+X to exit"
    picocom -b {{BAUD}} $(ls {{PORT}} 2>/dev/null | head -1)

upload file:
    ampy --port $(ls {{PORT}} 2>/dev/null | head -1) put {{file}}

upload-project:
    @for file in *.py; do \
        echo "Uploading $$file..."; \
        ampy --port $(ls {{PORT}} 2>/dev/null | head -1) put $$file; \
    done

run file:
    ampy --port $(ls {{PORT}} 2>/dev/null | head -1) run {{file}}

# Run domain unit tests on PC (not device)
test:
    uv run pytest tests/ -v

# Run unit tests only
test-unit:
    uv run pytest tests/unit/ -v

# Run integration tests on device (MicroPython)
test-integration-device:
    ampy --port $(ls {{PORT}} 2>/dev/null | head -1) run tests/integration/test_relay_hardware.py

# Build and flash C++ to device
build:
    pio run -e esp32

flash:
    pio run -e esp32 --target upload

# Run native C++ integration tests (on development machine)
test-native:
    pio test -e native

# Run C++ unit tests on device
test-device:
    pio test -e esp32test

lint:
    uv run ruff check .

format:
    uv run ruff format .

clean:
    uv run ruff clean
    pio run -t clean
```
