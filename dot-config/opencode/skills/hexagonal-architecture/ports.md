# Ports

#### Port Taxonomy: When to Add a Port

A port is a boundary, not a badge. Create one only when it earns its place.

**Add a port when any is true:**

- There is a real side effect or external dependency the domain must stay ignorant of
- Behavior must be substitutable (real ↔ fake ↔ alternate vendor) or isolated in tests
- Two or more implementations exist now, or credibly soon
- A capability must be deterministic/mockable (time, randomness, ids) or is cross-cutting

**Do NOT add a port when:**

- It is pure logic — make it a function/module instead
- It is a pure transformation — make it a pure helper
- There is one implementation, it never changes, and tests do not need isolation (YAGNI)
- It is adapter-private: transactions, retries, serialization, HTTP details, connection state

**Archetypes** — every driven port is one of these shapes. Match the shape, not the vendor:

| Archetype | Shape | Add when | Example ports |
|-----------|-------|----------|---------------|
| Repository | aggregate CRUD | persisting domain entities | `DocumentRepository` |
| Gateway | request/response, one external system | calling a remote API (payments, auth, maps, shipping) | `PaymentGateway` |
| Event bus | async pub/sub, many consumers | side effects must decouple or fan out | `EventPublisherPort`, `EventConsumerPort` |
| Store | keyed data, no aggregate | caching, blobs, files, KV — not a domain entity | `CachePort`, `KeyValueStorePort`, `BlobStorePort` |
| Notifier | fire-and-forget outbound | user-facing messages across channels/templates | `NotifierPort` |
| Ambient capability | deterministic environment | timing, seeded randomness, id generation | `TimePort`, `RandomPort` |
| Observability | telemetry sink | structured logs, metrics, traces | `LoggerPort`, `MetricsPort`, `TracerPort` |
| Presentation | output rendering | CLI/UI output must swap (rich ↔ JSON ↔ plain) | `PresenterPort` |
| Release control | progressive delivery | ship dark, kill switches, experiments | `FeatureFlagPort` |

**Notes:**

- **Notifier vs Gateway** — one channel and request/response → a Gateway. A dedicated `NotifierPort` earns its keep only with multiple channels/templates plus retry/tracking.
- **Events vs Notifier** — an event is "something happened" (broadcast); a notification is "tell this recipient".
- **Auth, search, hardware** are usually a `*Gateway` (or a Repository for an index). Do not invent new archetypes for them.
- The concrete ports, methods, and tiers are in [Standard Ports for Any Language](#standard-ports-for-any-language).

#### Port Design for Pluggability

Ports define contracts that adapters must fulfill. Well-designed ports make swapping adapters trivial.

**Rules:**

- Ports accept and return only domain types (models, enums, primitives) — never external library types
- Port methods should be minimal — one responsibility per port
- Prefer multiple small ports over one large port
- Constructor-inject port dependencies, never import concrete adapters
- Avoid leaking adapter-specific concerns (pagination, caching headers, connection state) into port interfaces

```
# Good: minimal, domain-only types
Port: DocumentRepository
  find_by_id(document_id: string) -> Document | none
  save(document: Document) -> void

# Bad: exposes external types
Port: DocumentRepository
  find_by_id(document_id: string) -> QuerySnapshot  # leaks database type
  save(document: Document) -> WriteResult            # leaks database type
```

**Standard generic capability ports:** When a backend can serve more than one aggregate, target a **generic port** so a single adapter is reusable across entities. These contracts live in `domain/ports/` (they are part of the standard set) and are what portable adapters import. Domain-specific ports are thin aliases that read better at the call site:

```
# Generic — one adapter serves any entity
Port: Repository[T]
  save(entity: T) -> void
  find_by_id(id: str) -> T | none
  find_all() -> list[T]
  delete(id: str) -> void

# Domain-specific alias — optional, for readability
Port: DocumentRepository = Repository[Document]
```

**Mapping injection:** the adapter receives pure `to_row` / `from_row` functions (and the table/collection name) at construction — so it never imports an app model and stays aggregate-agnostic. Bind the concrete mappers only at the composition root:

```
repo = SqlRepository(connection, table="documents",
                     to_row=document_to_row, from_row=row_to_document)
```

#### Gateway Ports (External Services)

A **Gateway port** models access to one external system's API — payments, shipping, identity, email, maps, a third-party REST/gRPC/SOAP service, a hardware endpoint. It is the driven-port counterpart to `*Repository`: `Repository` is persistence, `Gateway` is a remote capability. One port per external system (`PaymentGateway`, `ShippingGateway`), never one generic "ApiClient".

**The protocol is a deployment detail, not a contract.** The port stays protocol-neutral; the injected **frozen config** declares the wire protocol. The same `PaymentGateway` runs over HTTP in dev and gRPC in prod without a domain or workflow change.

**Rules:**

- Port methods express **domain capabilities** (`charge`, `track_shipment`) and accept/return **domain types only** — never `HttpResponse`, a gRPC stub, a decoded frame, or a status code
- The transport belongs in the adapter's **config struct**, not the port: `protocol`, `base_url`/`endpoint`, `timeout_ms`, auth/credentials, retry policy
- Keep a small **`Transport` enum** (pure domain enum, part of the standard port vocabulary) naming supported protocols so config, diagnostics, and dev/prod wiring can reason about transport without importing a library. It carries no app logic, so portable gateway adapters may import it
- Implement one adapter per backend behind the port; translate vendor errors to port errors (`GatewayUnavailableError`, `GatewayTimeoutError`, `RateLimitedError`, `NotFoundError`)
- Map wire DTOs ↔ domain models with **pure functions** at the adapter boundary (injected `to_wire`/`from_wire` keep the adapter reusable)
- Own connection/channel/session lifecycle in the adapter and release it via `LifetimePort`
- Give each gateway port a **contract test suite**; a stub/in-memory gateway runs it in unit tests, the real client runs it against an ephemeral backend

```python
# domain/ports/transport.py — standard port vocabulary: pure enum, no library types
from enum import Enum

class Transport(str, Enum):
    HTTP = "http"
    GRPC = "grpc"
    GRAPHQL = "graphql"
    WEBSOCKET = "websocket"
    MQTT = "mqtt"
    TCP = "tcp"

# domain/ports/payment_gateway.py — protocol-neutral capability
from typing import Protocol
from domain.models.money import Money
from domain.models.payment import PaymentResult, RefundResult

class PaymentGateway(Protocol):
    def charge(self, amount: Money, token: str) -> PaymentResult: ...
    def refund(self, payment_id: str) -> RefundResult: ...
```

```python
# adapters/stripe/stripe_config.py — frozen, injected; declares the wire protocol
from dataclasses import dataclass
from domain.ports.transport import Transport

@dataclass(frozen=True)
class StripeGatewayConfig:
    base_url: str
    api_key: str
    protocol: Transport = Transport.HTTP
    timeout_ms: int = 5_000
    max_retries: int = 2
```

```python
# adapters/stripe/stripe_gateway.py (PORTABLE — driver + standard ports only)
# backend: Stripe | port: PaymentGateway | driver: httpx | config: StripeGatewayConfig
class StripeGateway:
    def __init__(self, config: StripeGatewayConfig, lifetime: LifetimePort,
                 to_wire, from_wire):
        self._config = config          # frozen struct — declares protocol
        self._to_wire = to_wire        # pure
        self._from_wire = from_wire    # pure
        self._client = self._connect(config)
        lifetime.register_cleanup(self.close)

    def charge(self, amount: Money, token: str) -> PaymentResult:
        try:
            raw = self._client.call(self._config.protocol, self._to_wire(amount, token))
        except DriverError as e:
            raise GatewayUnavailableError(
                cause=e, retryable=True,
                context={"operation": "charge", "adapter": "stripe", "protocol": self._config.protocol},
            ) from e
        return self._from_wire(raw)
```

```python
# main.py — same port; transport chosen by config per environment
gateway = StripeGateway(StripeGatewayConfig.from_environment(), lifetime,
                        to_wire=payment_to_wire, from_wire=wire_to_payment)
```

**Anti-patterns:** protocol leaking into the port (`charge(...) -> HttpResponse`), a `protocol` *method argument* instead of config, one `HttpClientGateway` shared by every external system, SDK response objects crossing the port, or env reads inside the adapter.

**Dev/prod transport swapping:**

| Port | Dev | Staging | Prod |
|------|-----|---------|------|
| `PaymentGateway` | In-memory stub (HTTP config) | Stripe HTTP adapter | Stripe gRPC adapter |
| `ShippingGateway` | Fake rates adapter | Carrier REST adapter | Carrier gRPC adapter |
| `SensorGateway` | Replay adapter | MQTT adapter | MQTT / TCP adapter |

The domain, port, and workflow are identical in every column — only `Transport` and the adapter wiring in the composition root differ.

#### Standard Ports for Any Language

These are the concrete ports and methods per archetype. **Tier** is the default posture, not a mandate: **Baseline** ports earn their place in almost every non-trivial process; **Conditional** ports are added only when their trigger fires (apply the [Port Taxonomy](#port-taxonomy-when-to-add-a-port) test). Embedded and other minimal targets may omit any of them.

#### Python: Protocol vs ABC for Ports

Python offers two mechanisms for defining port contracts: `typing.Protocol` (structural subtyping) and `abc.ABC` (nominal subtyping). Use `Protocol` unless you need runtime type checking.

| Mechanism | When to Use | Tradeoffs |
|-----------|-------------|-----------|
| `Protocol` (preferred) | Most ports — enables duck typing with type safety | No `__init_subclass__` hooks, no runtime enforcement |
| `ABC` | Ports requiring `__init_subclass__`, `__subclasshook__`, or explicit `register()` | Forces inheritance, breaks duck typing |

**Protocol (recommended for most ports):**

```python
from typing import Protocol, runtime_checkable

@runtime_checkable  # optional: enables isinstance() checks
class LoggerPort(Protocol):
    def info(self, message: str) -> None: ...
    def error(self, message: str) -> None: ...

# Any class with matching methods satisfies LoggerPort — no inheritance required
class ConsoleLogger:  # no "implements LoggerPort" needed
    def info(self, message: str) -> None:
        print(f"[INFO] {message}")
    def error(self, message: str) -> None:
        print(f"[ERROR] {message}")

def log_something(logger: LoggerPort) -> None:
    logger.info("hello")

log_something(ConsoleLogger())  # works — structural subtyping
```

**ABC (use when you need runtime features):**

```python
from abc import ABC, abstractmethod

class LoggerPort(ABC):
    @abstractmethod
    def info(self, message: str) -> None: ...

    @abstractmethod
    def error(self, message: str) -> None: ...

# Must explicitly inherit
class ConsoleLogger(LoggerPort):  # required: "implements LoggerPort"
    def info(self, message: str) -> None:
        print(f"[INFO] {message}")
    def error(self, message: str) -> None:
        print(f"[ERROR] {message}")
```

**MicroPython note:** MicroPython may lack `typing.Protocol`. Use ABC or plain classes with duck typing. The embedded guide in this skill uses ABC for this reason.

| Port | Tier | Add when | Required methods |
|------|------|----------|-----------------|
| `TimePort` | Baseline | measuring duration or driving poll loops | `nowMs()`, `elapsedMs(start)`, `sleepMs(ms)` |
| `LifetimePort` | Baseline | long-running process, or one that owns resources needing cleanup | `registerCleanup(handler)`, `onExit(handler)`, `getExitReason()`, `isShuttingDown()` |
| `LoggerPort` | Conditional | the system emits structured logs | `info(message, **fields)`, `error(message, **fields)` |
| `Repository[T, IdT]` | Conditional | persisting domain aggregates | `save(entity)`, `findById(id)`, `findAll()`, `delete(id)` |
| `*Gateway` | Conditional | calling an external service/API | domain-specific capabilities (`charge`, `trackShipment`); transport in adapter config |
| `*Checker` | Conditional | read-only external validation | domain-specific |
| `MetricsPort` | Conditional | emitting counters, gauges, timings | `counter(name, value, labels)`, `gauge(...)`, `timing(...)` |
| `EventPublisherPort` | Conditional | publishing domain events | `publish(topic, payload)` |
| `EventConsumerPort` | Conditional | consuming domain events | `subscribe(topic, handler)` |
| `TracerPort` | Conditional | span-based tracing | `startSpan(name)`, `endSpan(spanId)` |
| `RandomPort` | Conditional | seeded, reproducible randomness | `int(below)`, `bytes(n)` |
| `FeatureFlagPort` | Conditional | progressive delivery / kill switches | `isEnabled(flag, context)`, `variant(flag, context)` |
| `PresenterPort` | Conditional | rich, colored terminal/CLI output | `success/error/warn/info(message)`, `panel(title, body)`, `table(...)` |
| `KeyValueStorePort` | Conditional | generic key-value storage | `get(key)`, `set(key, value)`, `delete(key)` |
| `BlobStorePort` | Conditional | binary/object storage | `put(key, bytes)`, `get(key)`, `delete(key)` |
| `CachePort` | Conditional | cached reads with TTL | `get(key)`, `set(key, value, ttlMs)`, `invalidate(key)` |

`*Repository` ports are aliases of the generic `Repository[T, IdT]` (e.g. `DocumentRepository = Repository[Document, str]`). Adapters target the generic contract and receive pure mappers, so one adapter serves every aggregate. Domain-specific ports remain valid for readability.

`*Gateway` ports wrap one external system each and stay protocol-neutral — the wire transport (`HTTP`, `GRPC`, `GRAPHQL`, `WEBSOCKET`, `MQTT`, `TCP`) is declared by the adapter's injected config, never by the port signature (see [Gateway Ports](#gateway-ports-external-services)). A `*Checker` is a thin read-only gateway used purely for validation (e.g. stock, credit, address); promote it to a full `*Gateway` once it performs more than a single check.

The dev DuckDB hub supplies local implementations of `LoggerPort`, `MetricsPort`, `EventPublisherPort`, and `EventConsumerPort`; prod swaps them in the composition root (see [Local-First Backing Services](./duckdb-hub.md#local-first-backing-services-duckdb-hub)).
