# Lifecycle, TimePort, and LifetimePort

## Lifecycle Hooks

Adapters own startup/shutdown. Domain never touches lifecycle.

**Startup (composition root):**

```
1. Read config from environment
2. Create adapters (open connections, allocate resources, validate config)
3. Validate all adapters — probe connections, check config, confirm readiness
4. Wire adapters into domain via ports
5. Start driving adapter (listen on port, begin polling, register handlers)
```

**Fail-fast startup validation:** Before the driving adapter starts accepting requests, the composition root must validate that every adapter is operational. A missing database, an invalid API key, or a broken connection is a startup crash — not a runtime surprise. The process must exit immediately with a clear `AppError` identifying which adapter failed and why.

```python
# main.py — composition root with startup validation
import sys
from domain.errors import StartupError

def main():
    config = load_config()

    # Create adapters
    repo = create_document_repository(config)
    logger = create_logger(config)
    gateway = create_payment_gateway(config)

    # Validate all adapters before starting
    errors = []
    if not repo.health_check():
        errors.append(StartupError(
            code="STARTUP-001",
            message="Document repository unreachable",
            context={"adapter": "postgres", "operation": "health_check"},
        ))
    if not gateway.health_check():
        errors.append(StartupError(
            code="STARTUP-002",
            message="Payment gateway unreachable",
            context={"adapter": "stripe", "operation": "health_check"},
        ))

    if errors:
        # Fail fast — crash immediately with diagnostic info
        for err in errors:
            logger.error(err.message, code=err.code, context=err.context)
        sys.exit(1)

    # All adapters validated — safe to start
    wire_adapters(repo, logger, gateway)
    start_driving_adapter()
```

**When startup validation fails:**

1. Log every failing adapter with its `code`, `context`, and `cause`
2. Exit with a distinct code (e.g., `1` for startup failure)
3. Do not start the driving adapter — no requests should reach unvalidated adapters
4. In containerized environments, let the orchestrator (Docker, Kubernetes) restart the process

**Shutdown (adapter cleanup):**

```
1. Stop accepting new requests (driving adapter stops)
2. Flush pending work (buffers, queues, in-flight writes)
3. Close connections (DB pools, sockets, file handles)
4. Release resources (hardware pins, timers, memory)
```

Domain workflows complete or abort during shutdown — they have no cleanup to do because they own no resources.

**Health checks:** Adapters expose readiness/liveness probes. The composition root wires them. Domain is always "healthy" if it can execute — adapter health depends on backing service connectivity.

## TimePort

Every project includes a `TimePort` for measuring process duration and driving poll loops. This makes performance visible and debugging easy across all layers.

### Domain Port

```python
# domain/ports/time_port.py (Python)
from typing import Protocol

class TimePort(Protocol):
    def now_ms(self) -> int: ...
    def elapsed_ms(self, start_ms: int) -> int: ...
    def sleep_ms(self, ms: int) -> None: ...
```

```typescript
// domain/ports/TimePort.ts (TypeScript)
export interface TimePort {
  nowMs(): number;
  elapsedMs(startMs: number): number;
  sleepMs(ms: number): Promise<void>;
}
```

```rust
// domain/src/ports/time_port.rs (Rust)
pub trait TimePort: Send + Sync {
    fn now_ms(&self) -> u64;
    fn elapsed_ms(&self, start_ms: u64) -> u64;
    fn sleep_ms(&self, ms: u64);
}
```

### Adapter Implementations

```python
# adapters/system_time.py (Python)
import time

class SystemTimeAdapter:
    def now_ms(self) -> int:
        return int(time.time() * 1000)

    def elapsed_ms(self, start_ms: int) -> int:
        return self.now_ms() - start_ms

    def sleep_ms(self, ms: int) -> None:
        time.sleep(ms / 1000.0)

# adapters/mock_time.py (Python - for testing)
class MockTimeAdapter:
    def __init__(self):
        self._current_ms = 0
        self._slept_ms = 0

    def now_ms(self) -> int:
        return self._current_ms

    def elapsed_ms(self, start_ms: int) -> int:
        return self._current_ms - start_ms

    def sleep_ms(self, ms: int) -> None:
        self._slept_ms += ms   # deterministic — no real waiting in tests

    def advance_ms(self, ms: int):
        self._current_ms += ms
```

### Usage in Workflows

```python
# domain/workflows/create_document.py
from domain.ports.time_port import TimePort
from domain.ports.logger import LoggerPort

def create_document(
    content: str,
    repo: DocumentRepository,
    logger: LoggerPort,
    time: TimePort,  # Inject time port
) -> Document:
    start = time.now_ms()

    document = Document.create(content=content)
    repo.save(document)

    elapsed = time.elapsed_ms(start)
    logger.info(f"Document created in {elapsed}ms: {document.id}")
    return document
```

### TimePort Adapter Swapping

| Environment | TimePort Adapter | Behavior |
|-------------|------------------|----------|
| Dev | `SystemTimeAdapter` | Real wall-clock time |
| Test | `MockTimeAdapter` | Deterministic, fast, controllable |
| Profile | `HighResTimeAdapter` | Nanosecond precision |

## LifetimePort

Every workflow gets a `LifetimePort` so it can detect why it's ending and clean up properly. No resource left behind, no matter the exit reason.

### Exit Reasons

```python
class ExitReason:
    NORMAL = "normal"           # Workflow completed successfully
    USER_EXIT = "user_exit"     # User pressed Ctrl+C or closed app
    CRASH = "crash"             # Unhandled exception or signal
    TIMEOUT = "timeout"         # Exceeded deadline
    SHUTDOWN = "shutdown"       # Graceful shutdown requested
```

### Domain Port

```python
# domain/ports/lifetime_port.py (Python)
from typing import Protocol, Callable

class LifetimePort(Protocol):
    def register_cleanup(self, handler: Callable[[], None]) -> None: ...
    def on_exit(self, handler: Callable[[str], None]) -> None: ...
    def get_exit_reason(self) -> str: ...
    def is_shutting_down(self) -> bool: ...
```

```typescript
// domain/ports/LifetimePort.ts (TypeScript)
export type ExitReason = "normal" | "user_exit" | "crash" | "timeout" | "shutdown";

export interface LifetimePort {
  registerCleanup(handler: () => void): void;
  onExit(handler: (reason: ExitReason) => void): void;
  getExitReason(): ExitReason;
  isShuttingDown(): boolean;
}
```

```rust
// domain/src/ports/lifetime_port.rs (Rust)
pub enum ExitReason {
    Normal,
    UserExit,
    Crash,
    Timeout,
    Shutdown,
}

pub trait LifetimePort: Send + Sync {
    fn register_cleanup(&self, handler: Box<dyn FnOnce() + Send>);
    fn on_exit(&self, handler: Box<dyn FnOnce(&ExitReason) + Send>);
    fn get_exit_reason(&self) -> ExitReason;
    fn is_shutting_down(&self) -> bool;
}
```

### Usage in Workflows

```python
# domain/workflows/data_collector.py
from domain.ports.lifetime_port import LifetimePort
from domain.ports.time_port import TimePort
from domain.ports.logger import LoggerPort

class DataCollector:
    def __init__(
        self,
        sensor: SensorPort,
        storage: StoragePort,
        lifetime: LifetimePort,
        time: TimePort,
        logger: LoggerPort,
    ):
        self.sensor = sensor
        self.storage = storage
        self.lifetime = lifetime
        self.time = time
        self.logger = logger
        self.buffer = []

        # Register cleanup — runs on ANY exit reason
        self.lifetime.register_cleanup(self._flush_buffer)

        # Register exit handler — knows WHY we're exiting
        self.lifetime.on_exit(self._handle_exit)

    def _flush_buffer(self):
        """Flush any buffered data before exit."""
        if self.buffer:
            self.storage.save_batch(self.buffer)
            self.buffer.clear()

    def _handle_exit(self, reason: str):
        """Log exit reason and handle gracefully."""
        if reason == "crash":
            self.logger.error(f"Crash detected — flushing {len(self.buffer)} items")
        elif reason == "user_exit":
            self.logger.info(f"User exit — {len(self.buffer)} items pending")
        elif reason == "timeout":
            self.logger.error("Timeout — partial data saved")

    def collect(self):
        reading = self.sensor.read()
        self.buffer.append(reading)

        # Periodic flush
        if len(self.buffer) >= 100:
            self._flush_buffer()
```

### Adapter Implementation

```python
# adapters/signal_lifetime.py (System-level exit detection)
import signal
from domain.ports.lifetime_port import LifetimePort

class SignalLifetimeAdapter(LifetimePort):
    def __init__(self):
        self._cleanup_handlers = []
        self._exit_handlers = []
        self._exit_reason = "normal"
        self._shutting_down = False

    def register_cleanup(self, handler):
        self._cleanup_handlers.append(handler)

    def on_exit(self, handler):
        self._exit_handlers.append(handler)

    def get_exit_reason(self):
        return self._exit_reason

    def is_shutting_down(self):
        return self._shutting_down

    def _handle_signal(self, signum, frame):
        self._shutting_down = True
        if signum == signal.SIGTERM:
            self._exit_reason = "shutdown"
        elif signum == signal.SIGINT:
            self._exit_reason = "user_exit"
        else:
            self._exit_reason = "crash"

        # Run exit handlers
        for handler in self._exit_handlers:
            handler(self._exit_reason)

        # Run cleanup handlers
        for handler in self._cleanup_handlers:
            handler()

    def install(self):
        signal.signal(signal.SIGTERM, self._handle_signal)
        signal.signal(signal.SIGINT, self._handle_signal)

# adapters/mock_lifetime.py (for testing)
from domain.ports.lifetime_port import LifetimePort

class MockLifetimeAdapter(LifetimePort):
    def __init__(self):
        self._cleanup_handlers = []
        self._exit_handlers = []
        self._exit_reason = "normal"
        self._shutting_down = False

    def register_cleanup(self, handler):
        self._cleanup_handlers.append(handler)

    def on_exit(self, handler):
        self._exit_handlers.append(handler)

    def get_exit_reason(self):
        return self._exit_reason

    def is_shutting_down(self):
        return self._shutting_down

    def trigger_exit(self, reason: str):
        """Simulate exit for testing."""
        self._shutting_down = True
        self._exit_reason = reason
        for handler in self._exit_handlers:
            handler(reason)
        for handler in self._cleanup_handlers:
            handler()
```

### LifetimePort Adapter Swapping

| Environment | LifetimePort Adapter | Behavior |
|-------------|---------------------|----------|
| Production | `SignalLifetimeAdapter` | Catches SIGTERM/SIGINT, runs cleanup |
| Test | `MockLifetimeAdapter` | Simulates exits, verifies cleanup |
| Embedded | `WatchdogLifetimeAdapter` | Hardware watchdog, deep sleep |
| Web | `RequestLifetimeAdapter` | Per-request lifecycle, connection pooling |
