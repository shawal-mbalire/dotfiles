# Adapters

## Adapter Design for Reusability and Transferability

Write each adapter so **only its file(s) move** to another project. It must work there unmodified — it targets standard ports and knows nothing about your app.

**Portability rules:**

- Import only: standard library, the third-party driver, and standard ports — which include `domain/result` and `domain/errors/app_error` (standard port vocabulary, identical in every project). **No other app-`domain` imports, no sibling-adapter imports.**
- Accept a frozen **config struct** via the constructor (URLs, credentials, table/collection names) — never read env vars.
- Take pure `to_row` / `from_row` mappers (and the entity/table name) via the constructor so the adapter is aggregate-agnostic.
- Translate vendor errors into `Failure(AppError)` (`ConflictError`, `StorageUnavailableError`); a miss is `Success(None)`, not an error; never leak SDK types or exceptions.
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

**Anti-patterns:** `os.getenv` inside the adapter; importing `domain.models`; returning SDK objects or raw rows; hardcoded table/collection names; module-level connections; swallowing errors; returning data that violates the port's postconditions.

## Discharging Port Postconditions

An adapter's job is not merely to call the vendor and return *something* — it must return data that satisfies the **port's postconditions and the model's invariants**. A vendor response that is empty, partial, or malformed is a contract violation, not a valid value.

**Rules:**

- Verify the postcondition before returning: the saved entity now has its generated id; the API payload has every required field; the balance matches the expected arithmetic.
- On violation, raise `ContractViolationError` (`AppError`) with the `cause` preserved — never return a partial object, a default, or `None`-because-broken.
- Build returned values through the domain model's factory (or a pure mapper plus an invariant check) so invariants hold at the boundary.
- Keep the check in a **pure function** (`assert_account_postcondition`) so it is testable without I/O.

```python
# adapters/postgres/account_repository.py (PORTABLE)
class AccountRepositoryAdapter:
    def save(self, account: Account) -> Result[None]:
        try:
            row = self._execute(self._config.upsert_sql, self._to_row(account))
        except DriverError as e:
            return Failure(StorageUnavailableError(cause=e, retryable=True,
                context={"operation": "save", "adapter": "postgres"}))   # expected: a value
        # Postcondition: the backend acknowledged a row carrying our id.
        if row is None or row["id"] != account.id:
            raise ContractViolationError(                                # defect: raise
                code="STO-002", message="save did not persist the entity",
                context={"operation": "save", "adapter": "postgres", "id": account.id},
            )
        return Success(None)

    def find_by_id(self, entity_id: str) -> Result[Account | None]:
        try:
            row = self._execute(self._config.select_sql, (entity_id,)).fetchone()
        except DriverError as e:
            return Failure(StorageUnavailableError(cause=e, retryable=True,
                context={"operation": "find_by_id", "adapter": "postgres"}))
        if row is None:
            return Success(None)                     # valid "not found" — not a failure
        account = self._from_row(row)                # pure mapper
        if not Account.is_balanced(account):         # invariant guard at the boundary
            raise ContractViolationError(code="STO-003", message="corrupt account row",
                context={"adapter": "postgres", "id": entity_id})
        return Success(account)
```

```typescript
// adapters/postgres/AccountRepository.ts
save(account: Account): Result<void> {
  let row: Row | undefined;
  try {
    row = this.execute(this.config.upsertSql, this.toRow(account));
  } catch (e) {
    if (!(e instanceof DriverError)) throw e;           // not ours to translate
    return fail(new StorageUnavailableError({           // expected: a value
      cause: e, retryable: true, context: { operation: "save", adapter: "postgres" },
    }));
  }
  if (!row || row.id !== account.id) {                  // defect: throw
    throw new ContractViolationError("STO-002", "save did not persist the entity", { id: account.id });
  }
  return ok(undefined);
}
```

```rust
// adapters/postgres/account_repository.rs
fn save(&self, account: &Account) -> Result<(), AppError> {
    let row = self.execute(&self.config.upsert_sql, self.to_row(account))
        .map_err(|e| AppError::storage_unavailable(e, "adapter.postgres.save", ""))?;  // one map_err at the boundary
    match row {
        Some(r) if r.id == account.id => Ok(()),
        _ => std::panic::panic_any(                                  // defect: panic, not Err
            ContractViolation::new("STO-002", "save did not persist the entity")
                .context("id", &account.id)),                       // structured for the panic hook
    }
}
```

**Boundary translation.** The driving adapter `match`es the workflow's `Result`: `Failure(ValidationError)` → a **caller** error (HTTP 4xx, non-zero CLI exit); an operational `Failure(AppError)` → rendered by class; a raised `ContractViolationError` (a defect) → an **internal** error (HTTP 5xx, alert). Never surface a raw stack trace, and never let a contract violation silently degrade into a default value. See [Railway-Oriented Workflows](./rop.md).

## Persistence (Adapter-as-ORM)

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

The shape is language-neutral: one `*Repository` port, SQL owned by the adapter, pure injected mappers, parameterized queries only.

## Reusable Adapters

The unit of reuse is **the adapter file**. If you can copy it into another project and it compiles/runs unmodified, it is reusable. Adapters in a personal collection are written to this standard.

**The portability contract:**

1. **Standard ports only** — import the generic port (`Repository[T, IdT]`, `CachePort`, …), its vocabulary (`domain/result`, `domain/errors/app_error`), and the driver. Never import the rest of the app's `domain/`, its models, or sibling adapters.
2. **Config struct injected** — a frozen config object (URL, credentials, table/collection) passed to the constructor. No env reads, ever.
3. **Mappers injected** — pure `to_row`/`from_row` functions (plus the entity/table name) passed in, so the adapter never names a domain model.
4. **Errors translated** — vendor exceptions become `Failure(AppError)` (`ConflictError`, `StorageUnavailableError`); a miss is `Success(None)`; SDK objects never cross the port.
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

    def save(self, entity: T) -> Result[None]:
        try:
            self._connection.execute(self._config.upsert_sql, self._to_row(entity))
        except DriverError as e:
            return Failure(StorageUnavailableError(cause=e, retryable=True,
                                                   context={"operation": "save"}))
        return Success(None)

    def find_by_id(self, entity_id: IdT) -> Result[T | None]:
        try:
            row = self._connection.execute(self._config.select_sql, (entity_id,)).fetchone()
        except DriverError as e:
            return Failure(StorageUnavailableError(cause=e, retryable=True,
                                                   context={"operation": "find_by_id"}))
        return Success(self._from_row(row) if row else None)

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

## Decorator / Middleware Pattern for Cross-Cutting Concerns

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
import time
from typing import Callable, Generic, TypeVar
from domain.ports.repository import Repository
from domain.result import Result, Success

T = TypeVar("T")
U = TypeVar("U")
IdT = TypeVar("IdT")

class RetryRepository(Generic[T, IdT], Repository[T, IdT]):
    """Decorator: retries Failures whose AppError is retryable, with exponential backoff."""

    def __init__(self, inner: Repository[T, IdT], max_retries: int = 3,
                 sleep: Callable[[float], None] = time.sleep):
        self._inner = inner
        self._max_retries = max_retries
        self._sleep = sleep

    def _with_retry(self, call: Callable[[], Result[U]]) -> Result[U]:
        result = call()
        for attempt in range(1, self._max_retries):
            if isinstance(result, Success) or not result.error.retryable:
                return result                   # success, or non-transient: return immediately
            self._sleep(2 ** (attempt - 1) * 0.1)   # exponential backoff
            result = call()
        return result                           # last Failure carries the real AppError

    def save(self, entity: T) -> Result[None]:
        return self._with_retry(lambda: self._inner.save(entity))

    def find_by_id(self, entity_id: IdT) -> Result[T | None]:
        return self._with_retry(lambda: self._inner.find_by_id(entity_id))

    def find_all(self) -> Result[list[T]]:
        return self._with_retry(self._inner.find_all)

    def delete(self, entity_id: IdT) -> Result[None]:
        return self._with_retry(lambda: self._inner.delete(entity_id))
```

```python
# adapters/decorators/cached_repository.py
from typing import Generic, TypeVar
from domain.ports.repository import Repository
from domain.ports.time_port import TimePort
from domain.result import Result, Success

T = TypeVar("T")
IdT = TypeVar("IdT")

class CachedRepository(Generic[T, IdT], Repository[T, IdT]):
    """Decorator: caches successful reads, invalidates on write. Failures are never cached."""

    def __init__(self, inner: Repository[T, IdT], time: TimePort, ttl_ms: int = 60_000):
        self._inner = inner
        self._time = time
        self._cache: dict[str, tuple[T, int]] = {}   # entry timestamp is monotonic
        self._ttl_ms = ttl_ms

    def save(self, entity: T) -> Result[None]:
        result = self._inner.save(entity)
        self._cache.pop(str(getattr(entity, 'id', '')), None)
        return result

    def find_by_id(self, entity_id: IdT) -> Result[T | None]:
        key = str(entity_id)
        if key in self._cache:
            value, ts = self._cache[key]
            if self._time.elapsed_ms(ts) < self._ttl_ms:   # TTL is a duration: monotonic clock
                return Success(value)
        result = self._inner.find_by_id(entity_id)
        if isinstance(result, Success) and result.value is not None:
            self._cache[key] = (result.value, self._time.monotonic_ms())
        return result                           # Failure passes through untouched

    def find_all(self) -> Result[list[T]]:
        return self._inner.find_all()

    def delete(self, entity_id: IdT) -> Result[None]:
        result = self._inner.delete(entity_id)
        self._cache.pop(str(entity_id), None)
        return result
```

```python
# adapters/decorators/metrics_repository.py
from typing import Callable, Generic, TypeVar
from domain.errors.app_error import ContractViolationError
from domain.ports.repository import Repository
from domain.ports.metrics import MetricsPort
from domain.result import Failure, Result

T = TypeVar("T")
U = TypeVar("U")
IdT = TypeVar("IdT")

class MetricsRepository(Generic[T, IdT], Repository[T, IdT]):
    """Decorator: records timing, failure, and defect metrics for every operation."""

    def __init__(self, inner: Repository[T, IdT], metrics: MetricsPort, time):
        self._inner = inner
        self._metrics = metrics
        self._time = time

    def _measured(self, op: str, call: Callable[[], Result[U]]) -> Result[U]:
        start = self._time.monotonic_ms()
        try:
            result = call()
        except ContractViolationError:
            self._metrics.counter(f"repository.{op}.defect", 1)
            raise                               # defects still halt
        self._metrics.timing(f"repository.{op}", self._time.elapsed_ms(start))
        if isinstance(result, Failure):
            self._metrics.counter(f"repository.{op}.failure", 1)
        return result

    def save(self, entity: T) -> Result[None]:
        return self._measured("save", lambda: self._inner.save(entity))

    def find_by_id(self, entity_id: IdT) -> Result[T | None]:
        return self._measured("find_by_id", lambda: self._inner.find_by_id(entity_id))

    # ... delegate remaining methods the same way
```

`MetricsRepository` is the repository-specific form; the generic `Instrumented` decorator in [Profiling](./profiling.md#port-timing-the-instrumented-decorator) wraps any port and adds spans and outcome labels.

**Decorators ride the railway.** A decorator implements the same `Result`-returning port, so it passes a `Failure` through unchanged (or retries it, or counts it). It never turns a `Failure` into an exception or `None`, never caches a `Failure`, and never catches a defect without re-raising. The lambdas here are adapter plumbing (deferred calls), not business logic.

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
    with_cache = CachedRepository(with_retry, time, ttl_ms=30_000)
    return with_cache
```

**Anti-patterns:** Putting retry/caching logic inside the base adapter (violates single responsibility), using decorators for concerns that belong in the domain (business rules), stacking too many decorators (performance overhead).

## Retry Anti-Pattern: When NOT to Retry

Retry is for **transient, infrastructure-level failures** only. Retrying non-transient errors delays the inevitable, wastes resources, and hides the real problem from the caller.

**Retryable vs non-retryable errors:**

| Error Class | Retryable? | Reason |
|-------------|------------|--------|
| `StorageUnavailableError(retryable=True)` | Yes | Backend temporarily down, connection pool exhausted |
| `GatewayTimeoutError` | Yes | Network blip, server overload |
| `RateLimitedError` | Yes (with backoff) | Temporary rate limit, will lift |
| `ConnectionRefusedError` | Yes | Server not ready yet |
| `ValidationError` | **No** | Client sent bad data — retrying won't fix it |
| `ContractViolationError` | **No** | Internal breach (bad postcondition/invariant) — alert and fix the bug, do not retry |
| `NotFoundError` | **No** | Entity doesn't exist — retrying won't create it |
| `AuthorizationError` | **No** | Credentials are wrong — retrying won't fix them |
| `ConflictError` | **No** | Optimistic lock conflict — retry the whole operation, not the same call |
| `AppError(retryable=False)` | **No** | Business rule violation — caller must fix input |

**Rule:** The `retryable` field on `AppError` is the contract. If `retryable=False`, the retry decorator must propagate immediately. Never retry errors that represent invalid input, missing resources, authorization failures, or contract violations. If a vendor can fail transiently, map that to a retryable gateway error *before* the postcondition check — a postcondition violation itself is not retryable.

## Event Consumer Fail Fast

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
                 max_retries: int = 3, dlq: DeadLetterPort = None,
                 sleep: Callable[[float], None] = time.sleep):
        self._bus = bus
        self._handler = handler
        self._max_attempts = max(1, max_retries)            # always at least one attempt
        self._dlq = dlq
        self._sleep = sleep                                 # injected: tests never really sleep

    def _process_with_fail_fast(self, message: EventMessage) -> Result[None]:
        for attempt in range(self._max_attempts):
            try:
                result = self._handler.handle(message)       # handler returns Result
            except ContractViolationError as e:
                self._dead_letter(message, reason=e.code)    # defect: DLQ, then halt
                raise
            if isinstance(result, Success):
                return result
            if not result.error.retryable or attempt == self._max_attempts - 1:
                self._dead_letter(message, reason=result.error.code)   # fail fast
                return result                                # bus nacks on Failure
            self._sleep(2 ** attempt * 0.1)                  # transient: back off, retry

    def _dead_letter(self, message: EventMessage, reason: str) -> None:
        if self._dlq:
            self._dlq.send(message, reason=reason)
```
