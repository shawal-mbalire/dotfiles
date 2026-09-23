# Adapters

#### Adapter Design for Reusability and Transferability

Write each adapter so **only its file(s) move** to another project. It must work there unmodified — it targets standard ports and knows nothing about your app.

**Portability rules:**

- Import only: standard library, the third-party driver, and standard ports. **No app-`domain` imports, no sibling-adapter imports.**
- Accept a frozen **config struct** via the constructor (URLs, credentials, table/collection names) — never read env vars.
- Take pure `to_row` / `from_row` mappers (and the entity/table name) via the constructor so the adapter is aggregate-agnostic.
- Translate vendor errors into port errors (`NotFoundError`, `ConflictError`, `StorageUnavailableError`); never leak SDK types or exceptions.
- Keep mapping/validation in **pure functions** testable without I/O; the I/O method stays thin.
- Register cleanup via `LifetimePort` — no module-level connections, no global state read at import time.
- Header the file with: backend, port(s) implemented, required driver, config fields, backend assumptions.

**File anatomy of a portable adapter:**

```
adapters/<backend>/
├── <backend>_adapter.py     # I/O: implements the standard port(s)
├── <backend>_mappings.py    # pure: row <-> domain conversions (injectable)
└── <backend>_config.py      # frozen config struct (constructor-injected)
```

**Anti-patterns:** `os.getenv` inside the adapter; importing `domain.models`; returning SDK objects or raw rows; hardcoded table/collection names; module-level connections; swallowing errors.

#### Persistence (Adapter-as-ORM)

Relational persistence goes through a **`*Repository` port** implemented by a **SQL adapter**. There is no ORM layer: the adapter owns its SQL and its row → domain mapping, so the adapter *is* the ORM. Use the database driver directly (or a thin query builder) — never an ORM.

**Rules:**

- Write SQL in the adapter; map rows ↔ domain models with **pure functions** (`*_mappings`) at the boundary
- Rows/DB records live in `adapters/`, never in `domain/` — the domain stays framework-free and SQL-free
- Never return a driver/DB row from a port; return domain models
- The repository adapter owns the connection/transaction lifecycle (open, commit, rollback, close) and registers cleanup via `LifetimePort`
- Use parameterized queries only — never string-interpolate user input
- Migrations live with the adapter or in `infra/` and are applied by a root-level admin entry point (`migrate.py`), not at app startup by default
- One repository per aggregate; keep SQL behind the port, never spread through workflows
- Document stores (Firestore, DynamoDB, Mongo) follow the same shape: driver + pure mappings

| Language | SQL access |
| -------- | ---------- |
| Python | `sqlite3` / `duckdb` / `psycopg` (DB-API), optional SQLAlchemy Core (SQL toolkit, not the ORM) |
| TypeScript/Node | `pg` / `better-sqlite3` / `@duckdb/node-api` |
| Rust | `sqlx` / `rusqlite` / `duckdb` crate |
| Dart/Flutter | `sqlite3` / `sqflite` |
| C++ | `sqlite3` / `duckdb` C++ API |

Full example: [Python, SQL repository adapter](./python.md#sql-repository-adapter-python).

#### Reusable Adapters

The unit of reuse is **the adapter file**. If you can copy it into another project and it compiles/runs unmodified, it is reusable. Adapters in a personal collection are written to this standard.

**The portability contract:**

1. **Standard ports only** — import the generic port (`Repository[T, IdT]`, `CachePort`, …) and the driver. Never import the app's `domain/`, its models, or sibling adapters.
2. **Config struct injected** — a frozen config object (URL, credentials, table/collection) passed to the constructor. No env reads, ever.
3. **Mappers injected** — pure `to_row`/`from_row` functions (plus the entity/table name) passed in, so the adapter never names a domain model.
4. **Errors translated** — vendor exceptions/rows become port errors (`NotFoundError`, `ConflictError`, `StorageUnavailableError`); SDK objects never cross the port.
5. **Lifecycle via port** — connections/clients are created from injected config and closed through `LifetimePort`; nothing global, nothing at import time.

```
# Portable — copy the file, inject config + mappers, done
class SqlRepository(Repository[T, IdT]):
    def __init__(self, connection, config: SqlConfig,
                 to_row, from_row, id_of):
        self._connection = connection
        self._config = config          # frozen: table name, etc.
        self._to_row = to_row          # pure
        self._from_row = from_row      # pure
        self._id_of = id_of

    def save(self, entity: T) -> None:
        self._connection.execute(self._config.upsert_sql, self._to_row(entity))

    def find_by_id(self, entity_id: IdT) -> T | None:
        row = self._connection.execute(self._config.select_sql, (entity_id,)).fetchone()
        return self._from_row(row) if row else None

# NOT portable — app imports, env reads, hardcoded names, SDK types
class BadRepository:
    def __init__(self):
        from domain.models.document import Document   # imports the app
        self.table = "documents"                        # hardcoded
        self.dsn = os.getenv("DATABASE_URL")            # env read
    def find(self, id):
        return self.client.query(...)                   # returns an SDK object
```

**Before adding an adapter from your collection, verify:** it imports no app code, reads no env vars, names no domain model, and passes the port's contract test (below). If any check fails, fix the adapter — not the target project.

#### Decorator / Middleware Pattern for Cross-Cutting Concerns

When multiple adapters need the same behavior (retry, caching, circuit breaking, metrics, logging), use the **Decorator pattern** — wrap a port implementation with another that implements the same port. Each decorator adds one concern and delegates to the wrapped adapter.

**When to use:**
- Retry with backoff on transient failures
- Caching reads (with TTL invalidation)
- Circuit breaker (stop calling a failing service)
- Metrics/timing around adapter calls
- Authorization checks before persistence
- Rate limiting

**Rules:**
- The decorator implements the **same port** as the wrapped adapter
- The decorator is injected with the inner adapter via constructor
- Decorators compose — stack them in the composition root
- Keep each decorator focused on one concern

```python
# adapters/decorators/retry_repository.py
from typing import TypeVar, Generic
from domain.ports.repository import Repository
from domain.errors import StorageUnavailableError

T = TypeVar("T")
IdT = TypeVar("IdT")

class RetryRepository(Generic[T, IdT], Repository[T, IdT]):
    """Decorator: retries transient failures with exponential backoff."""

    def __init__(
        self,
        inner: Repository[T, IdT],
        max_retries: int = 3,
        retryable_checker=lambda e: isinstance(e, StorageUnavailableError) and e.retryable,
    ):
        self._inner = inner
        self._max_retries = max_retries
        self._is_retryable = retryable_checker

    def save(self, entity: T) -> None:
        last_error = None
        for attempt in range(self._max_retries):
            try:
                self._inner.save(entity)
                return
            except Exception as e:
                last_error = e
                if not self._is_retryable(e) or attempt == self._max_retries - 1:
                    raise
                time.sleep(2 ** attempt * 0.1)  # exponential backoff
        raise last_error  # unreachable, but satisfies type checker

    def find_by_id(self, entity_id: IdT) -> T | None:
        return self._inner.find_by_id(entity_id)

    def find_all(self) -> list[T]:
        return self._inner.find_all()

    def delete(self, entity_id: IdT) -> None:
        self._inner.delete(entity_id)
```

```python
# adapters/decorators/cached_repository.py
from typing import TypeVar, Generic
from domain.ports.repository import Repository

T = TypeVar("T")
IdT = TypeVar("IdT")

class CachedRepository(Generic[T, IdT], Repository[T, IdT]):
    """Decorator: caches reads, invalidates on write."""

    def __init__(self, inner: Repository[T, IdT], ttl_ms: int = 60_000):
        self._inner = inner
        self._cache: dict[str, tuple[T, float]] = {}
        self._ttl_ms = ttl_ms

    def save(self, entity: T) -> None:
        self._inner.save(entity)
        # Invalidate cache for this entity
        self._cache.pop(str(getattr(entity, 'id', '')), None)

    def find_by_id(self, entity_id: IdT) -> T | None:
        key = str(entity_id)
        if key in self._cache:
            value, ts = self._cache[key]
            if (time.time() * 1000 - ts) < self._ttl_ms:
                return value
        result = self._inner.find_by_id(entity_id)
        if result is not None:
            self._cache[key] = (result, time.time() * 1000)
        return result

    def find_all(self) -> list[T]:
        return self._inner.find_all()

    def delete(self, entity_id: IdT) -> None:
        self._inner.delete(entity_id)
        self._cache.pop(str(entity_id), None)
```

```python
# adapters/decorators/metrics_repository.py
from typing import TypeVar, Generic
from domain.ports.repository import Repository
from domain.ports.metrics import MetricsPort

T = TypeVar("T")
IdT = TypeVar("IdT")

class MetricsRepository(Generic[T, IdT], Repository[T, IdT]):
    """Decorator: records timing and error metrics for every operation."""

    def __init__(self, inner: Repository[T, IdT], metrics: MetricsPort, time):
        self._inner = inner
        self._metrics = metrics
        self._time = time

    def save(self, entity: T) -> None:
        start = self._time.now_ms()
        try:
            self._inner.save(entity)
            self._metrics.timing("repository.save", self._time.elapsed_ms(start))
        except Exception as e:
            self._metrics.counter("repository.save.error", 1)
            raise

    def find_by_id(self, entity_id: IdT) -> T | None:
        start = self._time.now_ms()
        try:
            result = self._inner.find_by_id(entity_id)
            self._metrics.timing("repository.find_by_id", self._time.elapsed_ms(start))
            return result
        except Exception as e:
            self._metrics.counter("repository.find_by_id.error", 1)
            raise

    # ... delegate remaining methods
```

**Composition root — stack decorators:**

```python
# wire_adapters.py
def make_document_repository(connection, config, time, metrics) -> Repository[Document, str]:
    base = SqlRepository(connection, config,
                         to_params=lambda d: (d.id, d.content, d.status.value),
                         from_row=lambda r: Document(id=r[0], content=r[1],
                                                     status=DocumentStatus(r[2])))
    # Stack: base → metrics → retry → cached
    with_metrics = MetricsRepository(base, metrics, time)
    with_retry = RetryRepository(with_metrics, max_retries=3)
    with_cache = CachedRepository(with_retry, ttl_ms=30_000)
    return with_cache
```

**Anti-patterns:** Putting retry/caching logic inside the base adapter (violates single responsibility), using decorators for concerns that belong in the domain (business rules), stacking too many decorators (performance overhead).

#### Retry Anti-Pattern: When NOT to Retry

Retry is for **transient, infrastructure-level failures** only. Retrying non-transient errors delays the inevitable, wastes resources, and hides the real problem from the caller.

**Retryable vs non-retryable errors:**

| Error Class | Retryable? | Reason |
|-------------|------------|--------|
| `StorageUnavailableError(retryable=True)` | Yes | Backend temporarily down, connection pool exhausted |
| `GatewayTimeoutError` | Yes | Network blip, server overload |
| `RateLimitedError` | Yes (with backoff) | Temporary rate limit, will lift |
| `ConnectionRefusedError` | Yes | Server not ready yet |
| `ValidationError` | **No** | Client sent bad data — retrying won't fix it |
| `NotFoundError` | **No** | Entity doesn't exist — retrying won't create it |
| `AuthorizationError` | **No** | Credentials are wrong — retrying won't fix them |
| `ConflictError` | **No** | Optimistic lock conflict — retry the whole operation, not the same call |
| `AppError(retryable=False)` | **No** | Business rule violation — caller must fix input |

**Rule:** The `retryable` field on `AppError` is the contract. If `retryable=False`, the retry decorator must propagate immediately. Never retry errors that represent invalid input, missing resources, or authorization failures.

#### Event Consumer Fail Fast

Event consumers must handle poison pills (messages that always fail processing) without infinite retries or silent drops.

**Rules:**
- Each message gets a **maximum retry count** (e.g., 3 attempts)
- After exhausting retries, move the message to a **dead letter queue (DLQ)** and alert
- Never silently drop messages — a dropped message is a silent data loss
- Log every retry attempt with the failure reason and attempt number
- Track DLQ depth as a metric — a growing DLQ means a systemic problem

```python
# adapters/event_consumer.py
class EventConsumer:
    def __init__(self, bus: EventConsumerPort, handler: EventHandler,
                 max_retries: int = 3, dlq: DeadLetterPort = None):
        self._bus = bus
        self._handler = handler
        self._max_retries = max_retries
        self._dlq = dlq

    def _process_with_fail_fast(self, message: EventMessage):
        for attempt in range(self._max_retries):
            try:
                self._handler.handle(message)
                return
            except Exception as e:
                if attempt == self._max_retries - 1:
                    # Fail fast: move to DLQ, don't retry further
                    if self._dlq:
                        self._dlq.send(message, reason=str(e))
                    raise  # Re-raise so the bus can ack/nack
                time.sleep(2 ** attempt * 0.1)
```
