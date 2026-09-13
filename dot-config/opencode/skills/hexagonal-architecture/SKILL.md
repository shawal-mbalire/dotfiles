---
name: hexagonal-architecture
description: Implement Ports and Adapters (Hexagonal Architecture) where the domain owns application logic and adapters handle plumbing. Use when building maintainable, testable applications with clean domain boundaries across any platform. Covers domain modeling, ports/adapters pattern, dependency injection, cross-cutting concerns, lifecycle hooks, deployment artifacts, multi-stack implementations, testing strategies, and 12FA compliance.
references:
  - https://github.com/shawal-mbalire/shawal_stack/blob/main/hexagonal_architecture.md
  - https://github.com/shawal-mbalire/shawal_stack/blob/main/architecture-diagram.md
  - https://github.com/shawal-mbalire/shawal_stack/blob/main/shawal_multi_stack.md
languages:
  - python.md
  - typescript.md
  - flutter.md
  - rust.md
  - cpp.md
  - embedded.md
---

# Hexagonal Architecture (Ports and Adapters)

Domain owns the application logic. Adapters handle the plumbing. Separate the architecture from the implementation to swap anything without breaking the core.

## Core Principles

1. **Domain owns the application** — Pure application logic: main workflows, orchestration, core behavior. Zero knowledge of external libraries, frameworks, or infrastructure
2. **Dependencies point inward** — Adapters depend on Domain, never the reverse
3. **Ports define contracts** — Interfaces (Protocols/ABCs/Traits) that the Domain needs fulfilled
4. **Adapters are the plumbing** — Specific implementations of external libraries, services, databases, APIs
5. **Infrastructure is separate** — Logging, config, and cross-cutting concerns live in `infra/`, not domain
6. **Files over folders** — Prefer single files when a directory would contain fewer than 3 files. `domain/errors.py` beats `domain/errors/__init__.py` with one file inside
7. **Pure functions in domain** — Domain workflows are pure functions: same input → same output, no side effects. I/O happens in adapters only. Testing becomes trivial: call function, check result.
8. **Pure helpers in adapters** — Adapters handle I/O, but extract mapping/transformation logic into pure functions. Test pure helpers without mocks.
9. **Portable adapters** — Write each adapter so its file(s) copy to any project: depend only on standard ports + external libraries, hold zero app imports, constructor-inject a frozen config struct, translate vendor errors to port errors, and take row↔model mappers so the adapter is aggregate-agnostic.
10. **TimePort everywhere** — Every project includes a `TimePort` for measuring process duration. It makes performance visible and debugging easy across all layers.
11. **LifetimePort for graceful exits** — Every workflow gets a `LifetimePort` to detect exit reasons (crash, user exit, error, normal) and run cleanup. No resource left behind.

**The split:** Domain = what the app does (architecture). Adapters = how it connects (implementation).

## Architecture Layers

### 1. Domain (Inner Core)

Pure, isolated rules and decisions. Zero external dependencies.

**Small projects (single files):**

```
domain/
├── models       # Pure data structures representing business concepts
├── constants    # Named business constants (injected from config, never hardcoded)
├── errors       # Custom business-rule exceptions
├── ports        # Interfaces defining required I/O (Repositories, Gateways)
└── workflows    # Orchestrate flow using domain models and ports
```

**Larger projects (folders when 3+ files per module):**

```
domain/
├── models/      # 3+ model files → folder
├── constants    # Usually 1 file → stays as file
├── errors/      # 3+ error types → folder
├── ports/       # 3+ port files → folder
└── workflows/   # 3+ workflow files → folder
```

**Domain Constants Pattern:**

Domain code must never hardcode numeric values. There are two kinds of constants in the domain:

1. **Static constants** — pure business knowledge (mathematical, physical, or fixed rules). Defined directly in domain constants, never from env vars.
2. **Configurable constants** — deployment-specific values (timeouts, thresholds, pin numbers). Defined as a frozen/immutable struct in domain constants, values loaded from `infra/config`.

### 2. Infrastructure (Cross-Cutting Concerns)

`infra/` holds cross-cutting plumbing. It always holds **config**; it holds **Infrastructure as Code** only when the application provisions real resources.

**Single project:** `infra/` folder inside the project.

**Multi-project workspace:** Root-level `infra/` that all projects share.

**Always — config plumbing:**
- Env loading and settings management (`infra/config`)
- Typed config objects assembled once in the composition root

**Only when the app provisions infrastructure — Infrastructure as Code (tool-agnostic):**
If the application needs cloud resources, managed databases, queues, networks, containers, or DNS, declare them as code under `infra/` (e.g. `infra/iac/`) using any tool — Terraform/OpenTofu, Pulumi, Bicep, AWS CDK, Kubernetes/Helm manifests, Docker Compose, Ansible. If the app provisions nothing, keep `infra/` config-only.

- IaC declares provisioned resources; it never contains application logic, ports, or models
- Environment differences are variables/parameters, not code branches — one definition, many environments
- Commit the definitions; keep tool state out of version control (`.terraform/`, `*.tfstate`, Pulumi backends)
- Local backing services (e.g. the DuckDB dev hub) are dev tooling, not IaC — nothing is provisioned
- Config (what the app reads at runtime) and IaC (what is provisioned before the app runs) stay in separate files

**Rules for infra/ (all cases):**

- Contains ONLY config/settings plumbing and (optionally) IaC definitions
- Logging is an adapter (implements `LoggerPort`), not infra
- Presentation/output is an adapter, not infra
- Caching, metrics, events are adapters (shared or project-local)
- Never put application logic, ports, or models in infra

### 3. Adapters (Outer Ring)

- **Driven Adapters** (Implement Ports): Database clients, API clients, file systems, message queues
- **Driving Adapters** (Trigger Domain): HTTP routes, CLI handlers, UI controllers, event handlers

**Adapter transferability rules:**

- Accept all external configuration via constructor parameters — never read env vars directly in adapter code
- Map external types (DTOs, DB rows, wire formats) to domain types at the adapter boundary
- One adapter = one external system (Firestore adapter, not generic "storage adapter")
- Write adapters portable ([Reusable Adapters](#reusable-adapters)) so only the adapter file moves between projects — no `shared/` folder required

### State Management

Domain is stateless — pure functions and workflows that produce results from inputs. All mutable state lives in adapters or backing services.

- **Connection pools** — adapter concern, created at startup, released at shutdown
- **In-memory caches** — adapter concern, never accessed by domain
- **Request-scoped state** — passed as arguments, never stored on domain objects
- **Session/auth state** — decoded at the adapter boundary, injected as domain models

If multiple instances run concurrently, they share no in-process state. All shared state goes through backing services (databases, caches, message queues) via driven adapters.

### Port Design for Pluggability

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

### Adapter Design for Reusability and Transferability

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

### Persistence (Adapter-as-ORM)

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

### 4. Main Entry (Composition Root)

The composition root is where everything comes together. It reads config from `infra/config`, creates adapters, and plugs them into workflows. Keep it thin — it only wires, never contains logic.

**Composition root responsibilities:**
1. Read config from environment (only place env vars are read)
2. Create adapter instances with injected config
3. Pass adapters (via ports) to workflows
4. Start driving adapters (HTTP server, CLI, event loop)

**Composition root anti-patterns:**
- Putting business logic in the composition root
- Importing adapters in domain code
- Doing I/O before wiring is complete
- Creating a new root folder for the entry point

**Entry points are root-level files.** A project has exactly four root directories — `domain/`, `infra/`, `adapters/`, `tests/`. Wiring lives in the entry file or a root helper; config lives in `infra/config`:

```
main.py            # Entry point — wires adapters, starts the driving adapter
wire_adapters.py   # Optional root helper — creates adapters, maps ports to implementations
```

### 5. Deployment Artifacts

The composition root enables **build-once-run-anywhere**. The same artifact deploys to any environment by swapping adapter configs via env vars — no code changes, no rebuilds.

```
Build:    Compile/package the application (domain + adapters + composition root)
Release:  Tag the artifact with a version
Run:      Start the composition root with environment-specific config
```

**Adapter Swapping by Environment:**

| Port | Dev | Staging | Prod |
|------|-----|---------|------|
| `DocumentRepository` | DuckDB adapter (local hub) | Cloud SQL adapter | Firestore adapter |
| `LoggerPort` | DuckDB logger (local hub) | JSON adapter | Sentry adapter |
| `MetricsPort` | DuckDB metrics (local hub) | Prometheus adapter | Datadog adapter |
| `EventPublisherPort` | DuckDB event bus (local hub) | Kafka adapter | Kafka adapter |
| `CachePort` | In-memory adapter | Redis adapter | Redis cluster adapter |

The domain and ports never change. Only the composition root's adapter wiring differs per environment.

**Local-first default:** in dev, all three — logs, metrics, and events — point at the same local DuckDB hub (see [Local-First Backing Services](#local-first-backing-services-duckdb-hub)). Dev observation happens with SQL, not a SaaS dashboard, and prod swaps to managed services without touching the domain.

**Codebase:** One codebase tracked in version control. The same repo produces all deploy variants — the composition root plus environment-specific config is what differs, not the source.

### Build Folder Convention

All build artifacts go in a `build/` directory that is **not git tracked** and is **recreatable from code**.

```
.gitignore should contain:
build/
dist/
*.o
*.pyc
__pycache__/
node_modules/
```

**Rules:**
- `build/` is the only directory for compiled/derived artifacts
- `just clean` removes `build/` completely
- `just build` recreates `build/` from source — never commit build outputs
- Source code + Justfile/CMakeLists/Cargo.toml = everything needed to recreate `build/`

**Per-language build directories:**

| Language | Build Dir | Clean Command | Rebuild Command |
|----------|-----------|---------------|-----------------|
| Python | `build/` | `just clean` | `just build` |
| TypeScript | `dist/` | `just clean` | `just build` |
| Rust | `target/` | `cargo clean` | `cargo build` |
| C++ | `build/` | `just clean` | `just build` |
| Flutter | `build/` | `flutter clean` | `flutter build` |

### Scaling: Processes and Concurrency

The domain is pure — it scales by running more processes, not by adding threads inside the domain. Each process runs its own composition root with its own adapter wiring.

```
Process 1:  composition_root → domain + adapters → handle requests
Process 2:  composition root → domain + adapters → handle requests
Process N:  composition root → domain + adapters → handle requests
```

- **Stateless by design** — no shared in-process state between instances
- **Backing services handle coordination** — databases, queues, caches provide shared state
- **Adapter thread-safety** — adapters must be safe for concurrent use or use per-request instances
- **Horizontal scaling** — add more processes/containers, not more threads

## Request Flow

```
User → Driving Adapter → Convert DTO to Domain Model → Port → Workflow → Domain Logic → Port → Driven Adapter → External Service
                                                                                                                       ↓
User ← Driving Adapter ← Convert to DTO/Response ← Domain Model ← Result ← Adapter Response ←───────────────────────┘
```

## Cross-Cutting Concerns

| Concern   | Domain Port          | Infra Module   | Adapter Implementation                                      |
| --------- | -------------------- | -------------- | ----------------------------------------------------------- |
| Logging   | `LoggerPort`         | `infra/config` | DuckDB hub (dev), Console/Rich/JSON/Sentry (prod)           |
| Config    | Args to functions    | `infra/config` | Env loading centralized here — only place env vars are read |
| Caching   | Decorator pattern    | `infra/config` | Redis, IndexedDB, or in-memory adapter                      |
| Auth      | User model in domain | `infra/config` | JWT decode, OAuth adapter                                   |
| Persistence | `*Repository`      | `infra/` (IaC, optional) | SQL adapter owns queries + row↔domain mapping       |
| Telemetry | `MetricsPort`        | `infra/config` | DuckDB hub (dev), Prometheus/Datadog/OTel (prod)            |
| Events    | `EventPublisherPort` | `infra/config` | DuckDB hub (dev), Kafka/RabbitMQ/MQTT (prod)                |
| Events    | `EventConsumerPort`  | `infra/config` | DuckDB hub (dev), Kafka/RabbitMQ/MQTT (prod)                |
| Time      | `TimePort`           | `infra/config` | System clock, high-res timer, mock clock adapter            |
| Tracing   | `TracerPort`         | `infra/config` | DuckDB spans (dev), OpenTelemetry (prod)                    |
| Diagnostics | `AppError` + `ErrorReporterPort` | `infra/config` | DuckDB `diagnostics` table (dev), Sentry (prod) |
| Feature flags | `FeatureFlagPort` | `infra/config` | Local flags file (dev), LaunchDarkly/Unleash (prod) |
| Presentation | `PresenterPort` | `infra/config` | `rich` panels/tables (dev), plain/JSON (CI, non-TTY) |
| Lifetime  | `LifetimePort`       | `infra/config` | Signal handler, process observer, mock lifetime adapter     |

## Local-First Backing Services (DuckDB Hub)

**Principle:** In development, one local DuckDB database backs **logs, metrics, and events**. Ports never change — only the composition root swaps DuckDB dev adapters for managed prod services. Everything runs locally; production swaps in the real thing with zero code changes.

### Why a single hub process

DuckDB permits **one read-write process per database file** — multiple readers **or** one writer, never both. Multi-process writes require the beta Quack remote protocol or DuckLake with a Postgres catalog; neither is local-only.

A dev workspace runs several processes (`api`, `worker`, `frontend`, `device`), so exactly one process owns the file: the **dev hub**. Every other process — including the `insights` tool — talks to the hub over a local socket. Opening the file directly fails with `Could not set lock`.

### Hub Architecture

```
┌───────────┐   ┌───────────┐   ┌───────────┐
│ api       │   │ worker    │   │ frontend  │   each process constructs
└─────┬─────┘   └─────┬─────┘   └─────┬─────┘   DuckDB* adapters that
      │               │               │          speak the hub protocol
      └───────┬───────┴───────┬───────┘
              ▼               ▼
        local socket / localhost
              │
       ┌──────┴────────┐
       │ adapters/     │   single writer, owns the DuckDB file
       │ duckdb/hub    │   logs | metrics | events | insights views
       └──────┬────────┘
              ▲
       adapters/duckdb/insights   driving adapter — queries through the hub
```

The hub is **not** a new architectural layer. It is a composition root (the same wiring rules as `main`), plus a driven adapter set that talks to DuckDB. It lives at `adapters/duckdb/hub.py` — no new root folder.

### Dev / Prod Adapter Swapping

| Port | Dev (DuckDB hub) | Prod |
|------|------------------|------|
| `LoggerPort` | `DuckDbLoggerAdapter` | Sentry / JSON stdout adapter |
| `MetricsPort` | `DuckDbMetricsAdapter` | Prometheus / Datadog adapter |
| `EventPublisherPort` | `DuckDbEventBusAdapter` | Kafka / RabbitMQ adapter |
| `EventConsumerPort` | `DuckDbEventBusAdapter` | Kafka / RabbitMQ adapter |
| `*Repository` | `DuckDbRepositoryAdapter` | Firestore / Cloud SQL adapter |

The domain, ports, and workflows are identical in every column. Only the composition root's wiring differs.

### Buffered Writes + LifetimePort Flush

DuckDB is optimized for bulk operations; many tiny transactions are slow. Adapters **buffer and flush** on a size threshold, on an interval (via `TimePort.sleep_ms`), and on process exit via `LifetimePort.register_cleanup` — so logs, metrics, and events survive crashes and `SIGTERM`.

### Pubsub: Append + Cursor Poll

DuckDB has no `LISTEN`/`NOTIFY`, so the event bus is an **append-only `events` table plus a per-consumer cursor**:

1. `publish(topic, payload)` — `INSERT` a row with the next `seq` from a sequence.
2. `subscribe(topic, handler)` — poll `WHERE topic = ? AND seq > :cursor ORDER BY seq`, invoke `handler`, persist the cursor, and sleep `poll_interval` via `TimePort.sleep_ms` until `LifetimePort.is_shutting_down()`.

Semantics, documented not hidden: **at-least-once** (consumers must be idempotent), **retention** (trim old events), **latency** bounded by the poll interval, **fan-out** via one cursor row per consumer.

### Insights (Driving Adapter)

`adapters/duckdb/insights.py` answers dev questions by sending read queries **through the hub** (`query` op):

- error rate per service
- p50 / p95 / p99 latency per workflow
- throughput over time
- event lag per consumer cursor

Insights are a driving adapter (like a CLI or admin task), never domain logic.

### Managing Logs, Metrics, and Events Together

One database, three tables, one `ts`. Correlate across them by `request_id` and time — metrics find the *when*, logs/events find the *what*.

```sql
-- Metric spike -> time window -> the failing requests in logs
SELECT request_id, count(*) AS errors, approx_quantile(duration_ms, 0.95) AS p95_ms
FROM logs
WHERE ts > now() - INTERVAL '15 minutes' AND level = 'ERROR'
GROUP BY request_id
ORDER BY p95_ms DESC
LIMIT 20;
```

- **Correlate, don't duplicate** — every log and event carries `request_id` (and `trace_id` for spans); metrics carry **low-cardinality** labels only.
- **Retention** — keep raw rows for a window, not forever. An admin task deletes by `ts` (DuckDB rewrites affected data, so prune on a schedule with coarse windows):

```sql
DELETE FROM logs    WHERE ts < now() - INTERVAL '7 days';
DELETE FROM metrics WHERE ts < now() - INTERVAL '30 days';
DELETE FROM events  WHERE ts < now() - INTERVAL '7 days'
  AND seq <= (SELECT min(last_seq) FROM event_cursors);
```

- **Rollups** — materialize per-minute aggregates so insights read small tables, not raw rows:

```sql
CREATE OR REPLACE TABLE metrics_1m AS
SELECT date_trunc('minute', ts) AS minute, name,
       approx_quantile(value, 0.95) AS p95, count(*) AS n
FROM metrics
GROUP BY 1, 2;
```

- **Cardinality** — never put ids, paths, or user values in metric labels; that belongs in logs/events.
- **Sampling** — sample verbose DEBUG logs (1-in-N); always keep ERROR/WARN and all events.
- **Schema versioning** — version the observability tables separately (`obs_schema_version`) with migrations under `adapters/duckdb/migrations/`; the hub applies them at startup.
- **Size & compaction** — `CHECKPOINT`/`VACUUM`, cap temp size, and watch growth with `just db-size`. `build/` is untracked, so the dev DB is disposable.
- **Inspection** — the hub holds the write lock, so inspect through the hub (`just insights`, or the `query` op) or stop the hub before opening the file with the DuckDB CLI/UI. Never open a second read-write connection.

### Rules

1. **Four root folders only** — `domain/`, `infra/`, `adapters/`, `tests/`. Entry points and the hub are root files or live under an existing dir; never add a root folder for a capability.
2. **The hub is the only writer** — everyone else goes through the hub protocol; never open the file read-only while the hub runs.
3. **Ports are unchanged** — DuckDB types never leak into domain models.
4. **No direct DuckDB access in workflows** — always go through a port.
5. **Buffer and flush** — register the flush handler with `LifetimePort`.
6. **Events are at-least-once** — consumers must be idempotent.
7. **Prod uses real backing services** — the composition root decides; no code changes.
8. **DuckDB is dev/local insight, not prod shared state** — for prod multi-process coordination use Postgres or DuckLake, not a bare file.

Full schema, adapters, hub protocol, escape hatch, and tests: see [python.md](./python.md#local-first-backing-services-duckdb-hub-python).

## Lifecycle Hooks

Adapters own startup/shutdown. Domain never touches lifecycle.

**Startup (composition root):**

```
1. Read config from environment
2. Create adapters (open connections, allocate resources, validate config)
3. Wire adapters into domain via ports
4. Start driving adapter (listen on port, begin polling, register handlers)
```

**Shutdown (adapter cleanup):**

```
1. Stop accepting new requests (driving adapter stops)
2. Flush pending work (buffers, queues, in-flight writes)
3. Close connections (DB pools, sockets, file handles)
4. Release resources (hardware pins, timers, memory)
```

Domain workflows complete or abort during shutdown — they have no cleanup to do because they own no resources.

**Health checks:** Adapters expose readiness/liveness probes. The composition root wires them. Domain is always "healthy" if it can execute — adapter health depends on backing service connectivity.

## Workspace Log Streaming

Every workspace gets a `logs` command that streams all services in real-time with color-coded service identification.

### How It Works

1. Each service's `logs` command writes to stdout
2. A prefix helper tags each line with `[service-name]`
3. The central `logs` command pipes all services through parallel execution

### Color Assignments

| Service  | ANSI Color   | Example                                |
| -------- | ------------ | -------------------------------------- |
| api      | 34 (blue)    | `[api         ] GET /docs 200`         |
| worker   | 33 (yellow)  | `[worker      ] Processing job #123`   |
| frontend | 35 (magenta) | `[frontend    ] Hot reload complete`   |
| device   | 32 (green)   | `[device      ] Sensor reading: 23.5C` |
| shared   | 36 (cyan)    | `[shared      ] Cache invalidated`     |

## Multi-Stack Implementations

See language-specific guides for full code examples:

- [Python](./python.md) — Backend, FastAPI
- [TypeScript](./typescript.md) — React, Angular, Node.js
- [Flutter/Dart](./flutter.md) — Mobile apps
- [Rust](./rust.md) — Tauri desktop, systems programming
- [C++](./cpp.md) — Desktop, systems, game engines
- [Embedded](./embedded.md) — MicroPython + C++ on ESP32, STM32, Arduino

## Transfer Learning (Unsupported Languages)

Language not listed? Use Python as the reference and map to your language's idioms. The architecture is language-agnostic — only the syntax changes.

### Concept Mapping

| Python | Go | Java | C# | Kotlin | Swift | PHP |
|--------|-----|------|-----|--------|-------|-----|
| `class` | `struct` | `class` | `class` | `class` | `struct/class` | `class` |
| `Protocol` | `interface` | `interface` | `interface` | `interface` | `protocol` | `interface` |
| `ABC` | `interface` | `abstract class` | `abstract class` | `abstract class` | `protocol` | `abstract class` |
| `@dataclass(frozen=True)` | `struct` | `record` | `record` | `data class` | `struct` | readonly class |
| `typing.Protocol` | `interface` | `interface` | `interface` | `interface` | `protocol` | `interface` |
| `__init__` | constructor | constructor | constructor | constructor | `init` | `__construct` |
| `raise` | `return err` | `throw` | `throw` | `throw` | `throw` | `throw` |
| `try/except` | `if err != nil` | `try/catch` | `try/catch` | `try/catch` | `do/catch` | `try/catch` |
| `pytest` | `testing` | `JUnit` | `xUnit/NUnit` | `JUnit` | `XCTest` | `PHPUnit` |

### File Structure Mapping

```
Python                          →  Your Language
────────────────────────────────────────────────────
domain/models/document.py       →  domain/models/document.{ext}
domain/ports/repository.py      →  domain/ports/repository.{ext}
domain/workflows/create.py      →  domain/workflows/create.{ext}
domain/errors/empty_error.py    →  domain/errors/empty_error.{ext}
adapters/firestore_adapter.py   →  adapters/firestore_adapter.{ext}
adapters/firestore_mappings.py  →  adapters/firestore_mappings.{ext}
infra/config.py                 →  infra/config.{ext}
main.py                         →  main.{ext}
tests/unit/test_create.py       →  tests/unit/create_test.{ext}
```

### Port Translation Examples

**Python Protocol → Go Interface:**
```go
// domain/ports/repository.go
type DocumentRepository interface {
    Save(doc *Document) error
    FindByID(id string) (*Document, error)
}
```

**Python Protocol → Java Interface:**
```java
// domain/ports/DocumentRepository.java
public interface DocumentRepository {
    void save(Document document);
    Optional<Document> findById(String documentId);
}
```

**Python Protocol → C# Interface:**
```csharp
// domain/ports/IDocumentRepository.cs
public interface IDocumentRepository {
    void Save(Document document);
    Document? FindById(string documentId);
}
```

**Python Protocol → Swift Protocol:**
```swift
// domain/ports/DocumentRepository.swift
protocol DocumentRepository {
    func save(_ document: Document) throws
    func findById(_ id: String) throws -> Document?
}
```

### Workflow Translation

**Python → Go:**
```go
// domain/workflows/create_document.go
func CreateDocument(content string, repo DocumentRepository, logger Logger, time TimePort) (*Document, error) {
    start := time.NowMs()
    if strings.TrimSpace(content) == "" {
        return nil, ErrEmptyContent
    }
    doc := &Document{
        ID:      uuid.New().String(),
        Content: content,
    }
    if err := repo.Save(doc); err != nil {
        return nil, fmt.Errorf("save document: %w", err)
    }
    logger.Info(fmt.Sprintf("Document created %s in %dms", doc.ID, time.ElapsedMs(start)))
    return doc, nil
}
```

**Python → Java:**
```java
// domain/workflows/CreateDocument.java
public class CreateDocument {
    private final DocumentRepository repo;
    private final Logger logger;
    private final TimePort time;

    public CreateDocument(DocumentRepository repo, Logger logger, TimePort time) {
        this.repo = repo;
        this.logger = logger;
        this.time = time;
    }

    public Document execute(String content) {
        long start = time.nowMs();
        if (content == null || content.isBlank()) {
            throw new EmptyContentError();
        }
        Document doc = new Document(UUID.randomUUID().toString(), content);
        repo.save(doc);
        logger.info("Document created " + doc.getId() + " in " + time.elapsedMs(start) + "ms");
        return doc;
    }
}
```

### Adapter Translation

**Python → Go:**
```go
// adapters/firestore_adapter.go
type FirestoreDocumentAdapter struct {
    client     *firestore.Client
    collection string
}

func NewFirestoreDocumentAdapter(projectID, collection string) (*FirestoreDocumentAdapter, error) {
    client, err := firestorange.NewClient(context.Background(), projectID)
    if err != nil {
        return nil, fmt.Errorf("create firestore client: %w", err)
    }
    return &FirestoreDocumentAdapter{client: client, collection: collection}, nil
}

func (a *FirestoreDocumentAdapter) Save(doc *Document) error {
    _, err := a.client.Collection(a.collection).Doc(doc.ID).Set(context.Background(), map[string]interface{}{
        "content": doc.Content,
        "status":  doc.Status,
    })
    return err
}
```

### Testing Translation

**Python → Go:**
```go
// tests/unit/create_document_test.go
type FakeRepository struct {
    docs map[string]*Document
}

func (f *FakeRepository) Save(doc *Document) error {
    f.docs[doc.ID] = doc
    return nil
}

func TestCreateDocument(t *testing.T) {
    repo := &FakeRepository{docs: make(map[string]*Document)}
    logger := &FakeLogger{}
    time := &FakeTime{currentMs: 1000}

    doc, err := CreateDocument("Hello", repo, logger, time)

    assert.NoError(t, err)
    assert.Equal(t, "Hello", doc.Content)
}
```

### Standard Ports for Any Language

Every language implementation must include the **required** ports below. The **recommended** ports are added whenever the system logs structured data, emits metrics, or publishes/consumes events (embedded and other minimal targets may omit them).

| Port | Requirement | Purpose | Required Methods |
|------|-------------|---------|-----------------|
| `LoggerPort` | Required | Structured logging | `info(message, **fields)`, `error(message, **fields)` |
| `TimePort` | Required | Process timing + polling | `nowMs()`, `elapsedMs(start)`, `sleepMs(ms)` |
| `LifetimePort` | Required | Graceful exits | `registerCleanup(handler)`, `onExit(handler)`, `getExitReason()`, `isShuttingDown()` |
| `Repository[T, IdT]` | Required | Generic persistence contract | `save(entity)`, `findById(id)`, `findAll()`, `delete(id)` |
| `*Checker` | Required | External validation | domain-specific |
| `MetricsPort` | Recommended | Counters, gauges, timings | `counter(name, value, labels)`, `gauge(...)`, `timing(...)` |
| `EventPublisherPort` | Recommended | Publish domain events | `publish(topic, payload)` |
| `EventConsumerPort` | Recommended | Consume domain events | `subscribe(topic, handler)` |
| `TracerPort` | Recommended | Span-based tracing | `startSpan(name)`, `endSpan(spanId)` |
| `RandomPort` | Recommended | Seeded, reproducible randomness | `int(below)`, `bytes(n)` |
| `FeatureFlagPort` | Recommended | Progressive delivery / kill switches | `isEnabled(flag, context)`, `variant(flag, context)` |
| `PresenterPort` | Recommended | Rich, colored terminal output | `success/error/warn/info(message)`, `panel(title, body)`, `table(...)` |
| `KeyValueStorePort` | Recommended | Generic KV storage | `get(key)`, `set(key, value)`, `delete(key)` |
| `BlobStorePort` | Recommended | Binary/object storage | `put(key, bytes)`, `get(key)`, `delete(key)` |
| `CachePort` | Recommended | Cache with TTL | `get(key)`, `set(key, value, ttlMs)`, `invalidate(key)` |

`*Repository` ports are aliases of the generic `Repository[T, IdT]` (e.g. `DocumentRepository = Repository[Document, str]`). Adapters target the generic contract and receive pure mappers, so one adapter serves every aggregate. Domain-specific ports remain valid for readability.

The dev DuckDB hub supplies local implementations of `LoggerPort`, `MetricsPort`, `EventPublisherPort`, and `EventConsumerPort`; prod swaps them in the composition root (see [Local-First Backing Services](#local-first-backing-services-duckdb-hub)).

### Justfile for Any Language

```just
# Copy this justfile and replace tool commands for your language

# Path vars — root is this justfile's directory.
# Multi-project repos: add one var per project below root.
root := justfile_directory()

default:
    @just --list

run:
    # Replace with your language's run command
    # Go: go run .
    # Java: mvn exec:java
    # C#: dotnet run
    # Kotlin: ./gradlew run

test:
    # Go: go test ./...
    # Java: mvn test
    # C#: dotnet test
    # Kotlin: ./gradlew test

lint:
    # Go: golangci-lint run
    # Java: checkstyle
    # C#: dotnet format --verify-no-changes
    # Kotlin: ./gradlew ktlintCheck

format:
    # Go: gofmt -w .
    # Java: google-java-format -i **/*.java
    # C#: dotnet format
    # Kotlin: ./gradlew ktlintFormat

build:
    # Go: go build -o build/app .
    # Java: mvn package
    # C#: dotnet build -c Release
    # Kotlin: ./gradlew build

clean:
    rm -rf build/ target/ bin/ obj/
```

## Developer Experience & Debugging

Observability is only as good as the context attached to it. These make an incident debuggable in minutes.

### Version and Context Stamping

- Stamp build version, git SHA, environment, and service on startup **and on every log/metric record** (the adapter does it, not the caller) — you must know which code produced a record.
- Build the version once in `infra/config` (`GIT_SHA`, `APP_VERSION`, `ENVIRONMENT`) and inject it into the logger/metrics adapters.

### Correlation and Tracing

- Generate a `request_id` at the **driving adapter**, pass it through as a context value; log/event adapters attach it automatically.
- Add a `TracerPort` for spans; dev spans land in the DuckDB `spans` table, prod goes to OpenTelemetry. Spans expose cross-adapter latency.

```python
# domain/ports/tracer_port.py
from typing import Protocol

class TracerPort(Protocol):
    def start_span(self, name: str) -> str: ...
    def end_span(self, span_id: str) -> None: ...
```

### Observability Must Not Break the App

- A failed log/metric/event write is **swallowed** (last-resort `stderr`), never propagated into a workflow.
- Buffers are bounded with **drop-oldest**; expose a `dropped_records` counter so loss is visible.
- If the prod observability backend is down, the app keeps serving.

### Redaction and Privacy

- Redact or allowlist fields in the logger adapter **before** persisting; never log secrets, tokens, passwords, or full PII.
- Treat the dev DuckDB as real data — it may contain real payloads.

### Health, Readiness, and Prod Scrape

- Adapters expose readiness/liveness; the composition root wires `/healthz` and `/readyz`.
- Expose a `/metrics` endpoint in prod (Prometheus), independent of the dev adapter.

### Local DX Commands

| Command | Purpose |
| ------- | ------- |
| `just doctor` | Preflight: env vars, deps, ports, config valid, DB reachable |
| `just seed` | Load fixtures into the dev store |
| `just db-shell` | Inspect the dev DB (through the hub / read-only) |
| `just db-prune` | Apply retention to logs/metrics/events |
| `just db-size` | Dev DB size and row counts per table |
| `just debug` | Run with a debugger attached (`pdb`, `node --inspect`, `gdb`) |
| `just test-watch` | Re-run tests on change |
| `just logs [service]` | Tail streamed logs, filterable by service |

### Debug in Tests

- Fakes for `LoggerPort`/`MetricsPort`/`EventPublisherPort` capture records — assert events, metrics, and `duration_ms` in unit tests with no I/O.
- `MockTimeAdapter` makes durations and poll loops deterministic.
- Validate config and dependencies at startup — a clear startup error beats a mid-request failure.

## Diagnostics & Failure Localization

When something fails, the system must tell you **what failed, where, and why** — without a debugger and without guessing.

### Crash / Panic Handler

Install one process-level handler as part of the composition root. On an unhandled error or panic it must:

1. Capture the **backtrace**, build version/git SHA, and `correlation_id`.
2. Dump the **breadcrumb ring buffer** (the last N logs/events/spans) — see below.
3. Flush buffered logs/metrics/events via `LifetimePort` cleanup so nothing is lost.
4. Exit with a **distinct code per `ExitReason`** (normal / user_exit / crash / timeout / shutdown) so supervisors and scripts can react.

### Breadcrumbs

Keep a small fixed-size ring buffer of recent operations (logger adapter writes to it). On crash, the buffer is included in the report — this is the trail that shows *where* the process was before it died.

### Failure Capture

Every `AppError` crossing a driving-adapter boundary is written to a `diagnostics` table in the dev DuckDB (via the hub `execute` op) with: `ts`, `code`, `origin`, `correlation_id`, `context`, the redacted input, and the build version. Prod forwards the same record to the error backend (Sentry).

### Replay a Failure

Because domain workflows are pure and inputs are captured, a failure is reproducible:

```
# just replay <diagnostic-id> — reloads the captured input and re-runs the workflow
just replay doc-8f3a
```

This turns "works on my machine" into a deterministic, versioned reproduction.

### When It Fails — Capture Checklist

- [ ] `code` + `message` (what) and the full `cause` chain (why)
- [ ] `origin` (which layer/file/line) and `correlation_id` (which request)
- [ ] the redacted `context`/input, and the build version/git SHA
- [ ] breadcrumbs (what happened just before)
- [ ] whether it is `retryable`, and the runbook for that `code`
- [ ] a replay id, so it can be re-run against the exact input

If any item is missing, the fix is to add it — not to work around the failure.

## Testing Strategy

Tests prove the system works before it hits production. Every test should fail loudly with a clear message about what broke and why.

### Test Pyramid

| Layer    | Test Type         | Location             | Speed        | Dependencies  | Purpose |
| -------- | ----------------- | -------------------- | ------------ | ------------- | ------- |
| Domain   | Unit Tests        | `tests/unit/`        | Milliseconds | None (pure)   | Prove application logic is correct |
| Adapters | Integration Tests | `tests/integration/` | Seconds      | Real services | Prove adapters connect correctly |
| Main     | End-to-End Tests  | `tests/e2e/`         | Minutes      | Full stack    | Prove the whole system works |

### Verification Portfolio

No single test type proves correctness — stack independent layers. Each tier has a CI gate (see Confidence Gates).

| Tier | What it proves | Tooling |
| ---- | -------------- | ------- |
| Static hardening | Types and boundaries are sound; illegal states can't compile | strict typecheck, linters, `adapters-check` |
| Unit (pure domain) | Logic is correct for known cases | `pytest` / `vitest` / `cargo test` |
| Contract (per port) | Any adapter or fake honors the port | shared contract suites |
| Integration | Adapters talk to real backends | ephemeral DB / emulator / testcontainer |
| Fault injection | Failure paths behave and diagnostics are correct | failing and flaky fakes |
| E2E | The wired system works through driving adapters | HTTP / CLI / UI tests |
| Coverage | Nothing important is unexercised | branch coverage, domain-focused |
| Property-based | Invariants hold for *all* inputs, not just examples | `hypothesis` / `fast-check` / `proptest` |
| Mutation | The tests actually catch defects (verify the verifier) | `mutmut` / Stryker / `cargo-mutants` |
| Formal | The core algorithm/protocol is provably correct | TLA+ / Kani / CBMC / Dafny |

Examples are the floor, not the ceiling: every production bug becomes a regression test at the lowest tier that can catch it.

### Hard-Fail Patterns

**Fail fast, fail loud.** Never swallow errors silently. Every failure must produce a clear, actionable message.

```
# BAD: soft fail — hides the error, makes debugging impossible
try:
    result = create_document(content, repo, logger)
except Exception:
    return None  # What went wrong? Nobody knows.

# GOOD: hard fail — stops execution, clear error message
result = create_document(content, repo, logger)  # Raises if anything is wrong
assert result.id is not None, f"Document creation failed: {result}"
```

```
# BAD: generic assertion — test fails but you don't know why
assert result == expected

# GOOD: specific assertion — test fails with exact mismatch
assert result.status == DocumentStatus.PUBLISHED, (
    f"Expected PUBLISHED, got {result.status}. "
    f"Content: {result.content!r}"
)
```

### Diagnostic Error Contract

**One error type, used by domain and adapters.** Every failure carries enough to answer *what, where, and why*. Subclass it for named domain errors, but everything serializes to this shape.

```
# domain/errors/app_error.py
from dataclasses import dataclass, field

@dataclass(frozen=True)
class AppError(Exception):
    code: str                       # stable, registry-backed (e.g. "DOC-001")
    message: str
    context: dict = field(default_factory=dict)   # ids, operation, inputs (redacted)
    cause: Exception | None = None  # the original error — never discarded
    origin: str = ""                # layer + module.function:line, set at the boundary
    correlation_id: str = ""
    retryable: bool = False
    remediation: str = ""           # one-line hint on how to fix

class EmptyContentError(AppError):
    def __init__(self, message="Document content cannot be empty", **kw):
        super().__init__(code="DOC-001", message=message,
                         remediation="Provide non-empty content", **kw)
```

**Rules:**

- **Uniform across layers** — workflows raise `AppError` subclasses; adapters translate vendor errors into `AppError` at the boundary. Nothing returns a raw SDK error, a bare string, or `None`-on-failure.
- **Preserve causality** — always keep the original: Python `raise ... from e`, Rust `#[source]`, Go `%w`, TS `new AppError(msg, { cause })`. A lost cause is a bug.
- **`origin` is filled at the boundary** — the driving/driven adapter sets layer + `module.function:line` and the `correlation_id`; the domain never knows file locations.
- **Context is structured and redacted** — `{"document_id": ..., "operation": "save", "adapter": "postgres"}`; never secrets or PII.
- **One renderer** — `render(error)` for logs, CLI, and HTTP (map `code` → status). Log the full cause chain once, at the boundary.
- **Error-code registry** — every `code` maps to meaning, owner, retryable, and a runbook. `just errors-check` fails CI on unknown or duplicate codes.

```
# errors.toml
["DOC-001"]
meaning = "Document content is empty"
retryable = false
runbook = "docs/runbooks/DOC-001.md"

["STO-001"]
meaning = "Storage backend unavailable"
retryable = true
runbook = "docs/runbooks/STO-001.md"
```

```
# Adapter boundary — translate + enrich, never swallow
try:
    self._pool.execute(self._config.save_sql, params)
except DriverError as e:
    raise AppError(
        code="STO-001", message="Storage write failed", cause=e,
        context={"operation": "save", "adapter": "postgres"},
        origin=origin_here(), correlation_id=correlation_id, retryable=True,
    ) from e
```

### Test Directory Structure

**Small projects:**

```
tests/
├── fixtures           # Shared test data and factories
├── unit/
│   └── test_*
├── integration/
│   └── test_*
└── e2e/
    └── test_*
```

**Larger projects:**

```
tests/
├── fixtures/              # Shared test data and factories
│   ├── factories          # Domain model factories
│   ├── builders           # Test data builders
│   └── fakes/             # Fake implementations
│       ├── fake_repos
│       ├── fake_loggers
│       └── fake_adapters
├── unit/
│   └── test_*
├── integration/
│   └── test_*
└── e2e/
    └── test_*
```

### Testing Principles

- **Domain unit tests** use in-memory fakes — no I/O, no frameworks, milliseconds to run
- **Adapter integration tests** hit real services — databases, APIs, file systems
- **E2E tests** exercise the full stack through driving adapters (HTTP, CLI, UI)
- **Fakes implement ports** — same interface as real adapters, but with in-memory storage
- **Factories create test data** — avoid hardcoded test values scattered across tests
- **Every test has one reason to fail** — if a test fails, you know exactly what broke
- **Test names describe behavior** — `test_create_document_rejects_empty_content`, not `test_1`
- **Assert with context** — always include expected vs actual in assertion messages
- **Contract tests per port** — every adapter passes the port's shared contract suite, so drop-in adapters can't drift

### Contract Tests for Ports

Every standard port gets one **contract test suite** that any adapter must pass. It lives with the other integration tests (structure unchanged) and is parameterized over an adapter factory — so a local adapter, a copied-in collection adapter, and a fake all prove the same behavior.

```python
# tests/integration/test_repository_contract.py
import pytest

@pytest.fixture
def repository():
    raise NotImplementedError("override in the adapter's test module")

def test_save_then_find_round_trips(repository):
    entity = make_entity("id-1")
    repository.save(entity)
    assert repository.find_by_id("id-1") == entity

def test_find_missing_returns_none(repository):
    assert repository.find_by_id("missing") is None

def test_save_is_idempotent(repository):
    entity = make_entity("id-1")
    repository.save(entity)
    repository.save(entity)                      # upsert, not duplicate
    assert repository.find_all() == [entity]

def test_delete_removes(repository):
    repository.save(make_entity("id-1"))
    repository.delete("id-1")
    assert repository.find_by_id("id-1") is None
```

- **One suite per standard port** (`Repository`, `CachePort`, `KeyValueStorePort`, `BlobStorePort`, `EventPublisherPort`), kept once and run by every adapter.
- **Adapters run it against an ephemeral backend** (temp file, `:memory:`, emulator, testcontainer).
- **Fakes run it too** (minus persistence-specific cases) so fake and real behavior cannot drift.
- A copied-in adapter is only accepted once the contract suite passes in the target project.

### Fault Injection

Happy-path correctness is half the job; the other half is behaving correctly when a dependency fails. Inject failures through fakes and assert both the outcome and the diagnostic.

```python
# tests/unit/test_create_document_faults.py
def test_save_failure_surfaces_storage_error():
    repo = FailingRepo(fail_with=TimeoutError("backend timed out"))
    with pytest.raises(AppError) as exc:
        create_document("Hello", repo, FakeLogger(), FakeTime())
    err = exc.value
    assert err.code == "STO-001"                # right class
    assert err.retryable is True                # right policy
    assert isinstance(err.cause, TimeoutError)  # cause preserved
    assert err.context["operation"] == "save"

def test_observability_survives_sink_failure():
    # logging/metrics must not raise even when their sink is down
    create_document("Hello", FakeRepo(), FailingLogger(), FakeTime())  # must not raise
```

Standard fault set per driven adapter: connection refused, timeout, malformed payload, partial write, duplicate key, auth failure. Assert the `code`, `origin`, `retryable`, and that the failure was logged with the same `correlation_id`.

### Static & Runtime Hardening

Cheap, high-leverage guarantees that catch whole defect classes before tests run:

- **Strict types everywhere** — no implicit `any`/`Any`, exhaustive `match`/`switch`, non-null by default; turn warnings into errors.
- **No panics in production paths** — forbid `unwrap`/`expect` (Rust), `!`/non-null assertions (TS), bare `except` (Python); validate instead.
- **Boundary schema validation** — parse external input (config, HTTP bodies, rows) into typed values at the edge and reject with an `AppError` before it reaches the domain.
- **Invariants as assertions** — debug-only `assert` for pre/postconditions; enabled in dev/test, compiled out in prod.
- **Memory/UB safety** — Rust `Miri`, C++/Rust AddressSanitizer + UndefinedBehaviorSanitizer + ThreadSanitizer, valgrind; race detector for concurrent adapters.

### Reproducibility

A test or replay is only conclusive if the run is reproducible.

- **Seeded randomness** — inject a `RandomPort`; prod uses a secure source, dev/test a fixed seed. Never call the global RNG in domain or adapters.
- **Frozen time** — `MockTimeAdapter` in tests; `TimePort` everywhere else.
- **Pinned dependencies and toolchains** — lockfiles committed, toolchain versions pinned, build in a container/devcontainer.
- **Deterministic builds** — same inputs produce the same artifact; `build/` is always recreatable.

### Confidence Gates & Definition of Done

Nothing merges unless the gates pass. `just check` is the fast local loop; `just verify` is the full gate:

```just
verify: lint typecheck adapters-check errors-check test-unit test-contract test-integration test-fault test-e2e
    # Full gate — run before merge and in CI
verify-hard:
    just verify && just sanitizers   # memory/UB sanitation — nightly / pre-release
verify-plus:
    just verify && just test-property && just mutation   # verify the verifier — nightly
replay id:
    uv run python cli.py replay {{id}}   # re-run a captured failure deterministically
```

**Definition of done for a change:** it has a test at the lowest tier that can catch its failure, a regression test for any bug fixed, no new untriaged `code`, and `just verify` is green. 100% certainty is impossible — the goal is that every defect is either prevented by a gate or pinpointed by a diagnostic.

### Property-Based Testing

Instead of enumerating examples, state invariants and let the tool generate inputs (and shrink failures to minimal counterexamples). Properties live with the pure domain.

```python
from hypothesis import given, strategies as st

@given(st.lists(st.text()))
def test_encode_decode_round_trips(documents):
    assert [decode(encode(d)) for d in documents] == documents

@given(st.integers(min_value=0), st.integers(min_value=0))
def test_total_is_order_independent(price, qty):
    cart = Cart(items=[CartItem(price=price, quantity=qty)])
    assert calculate_total(cart) == calculate_total(cart.reversed())
```

A failing property prints the **minimal** counterexample — that is the "exactly how it failed" you want. Add each discovered counterexample as a regression example test.

### Mutation Testing (Verify the Verifier)

Coverage says code ran; mutation says the tests would *notice* if it broke. Tooling mutates the source (flip operators, drop calls, change constants); a mutant that survives means a missing or weak assertion.

- Python `mutmut` / `cosmic-ray`, TS `StrykerJS`, Rust `cargo-mutants`, C++ `mull`.
- Gate on a **mutation score threshold** for the domain package (not the whole repo); investigate survivors, don't blindly raise the number.
- Run nightly / pre-release, not on every commit (it is slow).

### Formal Methods (Highest Assurance)

For the small, high-risk core (a protocol, a scheduler, a financial calculation, a state machine), prove properties instead of sampling them:

- **Model checking** — TLA+/PlusCal (design) or Quint + Apalache for temporal/consensus properties.
- **Bounded verification of real code** — Kani (Rust), CBMC/ESBMC (C/C++): prove panics/overflow/assertions cannot occur within bounds.
- **Deductive verification** — Dafny / Frama-C / SPARK for functional correctness proofs.
- **Types as proofs** — push invariants into the type system (newtypes, typestate, exhaustive enums) so invalid states are unrepresentable.

Keep the pure domain small and side-effect-free so it is tractable to verify; the adapters around it stay conventional.

### Progressive Delivery (Fail Safe in Prod)

Confidence does not end at merge — assume something will slip through and bound the blast radius:

- **Feature flags** — a `FeatureFlagPort`; ship dark, enable per environment/tenant. Rollback = flip the flag.
- **Canary** — roll the new artifact to a small slice, watch error rate/latency/`code` distribution, then ramp.
- **Health and deep checks** — `/healthz` (process up) and `/readyz` (dependencies reachable); a failing deep check removes an instance from rotation instead of serving errors.
- **Automatic rollback** — alert on the same metrics/logs the DuckDB hub already captures; revert on threshold breach.
- **Blast-radius limits** — timeouts, circuit breakers, bulkheads, and idempotency keys so one failing dependency degrades instead of cascading.

## Logging Strategy

Logging is how you see inside the system at runtime. Good logs let you trace a request through every adapter and pinpoint exactly where something went wrong.

### Log at Adapter Boundaries

The domain doesn't log — adapters do. Log every point where the system crosses a boundary:

```
Driving Adapter receives request
  → Log: request received, request ID, parameters
Driven Adapter calls external service
  → Log: calling [service], request ID, what we're sending
Driven Adapter gets response
  → Log: [service] responded, request ID, status, duration
Driven Adapter gets error
  → Log: [service] failed, request ID, error, retry attempt
Workflow completes
  → Log: workflow [name] completed, request ID, result summary
```

### Structured Logging

Logs must be parseable and searchable. Use structured fields, not string concatenation. The **adapter stamps time** — callers never pass `ts`:

```
# BAD: string concat — impossible to search, impossible to grep
logger.info("User " + user_id + " created order " + order_id)

# GOOD: structured fields — searchable, filterable, aggregatable
logger.info("order_created", user_id=user_id, order_id=order_id, total=total)
```

### Timestamps and Delays

Every log and metric record carries a timestamp so you can see where time is spent. Adapters stamp time from the injected `TimePort` (never a raw `now()`), so it is mockable in tests:

- **Logger** — each record gets `ts`; log `duration_ms` for any operation that crosses a boundary (from `TimePort.elapsed_ms(start)`), so slow calls stand out.
- **Metrics** — every `counter`/`gauge`/`timing` sample gets `ts`; `timing(name, duration_ms)` captures latency directly.
- In dev the DuckDB hub stores `ts` on every row and the `slow_requests` view derives request latency from log timestamps — delays become a SQL query, not a guess.

```
# Adapter stamps ts + duration; the caller supplies only business fields
start = time.now_ms()
repo.save(document)
logger.info("document_saved", document_id=document.id,
            duration_ms=time.elapsed_ms(start))
```

### Request Tracing

Every request gets an ID that follows it through every adapter and layer:

```
[req-abc-123] POST /documents
[req-abc-123] FirestoreAdapter.save: saving document doc-456
[req-abc-123] ConsoleLogger: Document created doc-456
[req-abc-123] POST /documents → 201 Created (45ms)
```

### Log Levels (use them correctly)

| Level | When | Example |
|-------|------|---------|
| `ERROR` | Something failed and needs attention | `Database connection failed: timeout after 5s` |
| `WARN` | Something unexpected but recoverable | `Retrying Firestore call (attempt 2/3)` |
| `INFO` | Normal operations worth recording | `Document created doc-456` |
| `DEBUG` | Detailed troubleshooting info | `FirestoreAdapter.save: collection=docs, id=doc-456` |

**Rule:** Production should run at `INFO` or `WARN`. Drop to `DEBUG` only when investigating a specific issue.

## Architecture Rules

These refine the [Core Principles](#core-principles) with concrete, checkable rules:

1. **The DTO Boundary** — Adapters must translate external formats (JSON, SQL rows, raw bytes) into Pure Domain Models before passing them inward
2. **Never import external frameworks in Domain** — No framework imports in domain code
3. **Mocking is Universal** — All platforms use Interfaces/Traits/Protocols for Ports, enabling pure in-memory Mocks in any language
4. **Infrastructure Stays Separate** — Logging, config, caching go in `infra/`, never in domain
5. **Error Handling in Domain** — Business rule errors are domain exceptions; infrastructure errors are adapter concerns
6. **Composition Root is the Only Place** — Only the entry point reads config and creates concrete instances
7. **Fixtures Enable Reuse** — Shared test data, factories, and fakes live in `tests/fixtures/`, not scattered across tests
8. **Nested Hexagons Don't Import Each Other** — Bounded contexts communicate via ports/adapters, never direct imports
9. **No Magic Numbers in Domain** — All numeric values in domain code must be named constants; static business constants in domain, configurable values injected from infra
10. **Ports are Pluggable Contracts** — Port interfaces must be minimal, accept only domain types, and avoid exposing adapter-specific concerns
11. **Portable Adapters** — An adapter's file(s) must copy into any project unmodified: standard ports + driver only, zero app imports, frozen config struct injected, pure mappers injected, vendor errors translated to port errors
12. **Files Over Folders** — Prefer single files when a directory would contain fewer than 3 files. `domain/errors.py` beats `domain/errors/__init__.py` with one file inside
13. **TimePort Everywhere** — Every project includes a `TimePort` for measuring process duration. It makes performance visible and debugging easy across all layers.
14. **Pure Domain Functions** — Domain workflows are pure functions: same input → same output, no side effects. I/O happens in adapters only. Testing becomes trivial.
15. **Pure Adapter Helpers** — Extract mapping/transformation logic from adapter methods into pure functions. Test pure helpers without mocks; test I/O methods with integration tests.
16. **Light Justfile for DX** — The root justfile is a thin command index: each recipe is one line delegating to a program (e.g. `cli.py`), never inline logic. It defines `root := justfile_directory()`, and recipes `cd` into the project dir. All task output is colored and structured via `PresenterPort` (rich panels/tables), auto-degrading on non-TTY/`NO_COLOR`.
17. **LifetimePort for Graceful Exits** — Every workflow registers cleanup via LifetimePort. No resource left behind, no matter the exit reason (crash, user exit, normal, timeout).
18. **Infrastructure as Code Only When Needed** — `infra/` always holds config; it holds IaC (tool-agnostic) only when the app provisions real resources. Never mix runtime config and provisioning in one file.
19. **Adapter-as-ORM** — Persist through `*Repository` ports implemented by SQL adapters. The adapter owns its SQL and maps rows to domain models via pure functions; no ORM layer, and never leak a DB row through a port.
20. **Uniform Diagnostics** — Every failure is an `AppError` with a registry-backed `code`, structured `context`, a preserved `cause`, an `origin` (layer + location), and a `correlation_id`. Never swallow, never return a raw SDK error.
21. **Verifiable by Default** — Every behavior has a test at the lowest tier that can catch its failure; every failure path has a fault-injection test; nothing merges unless `just verify` is green.
22. **Reproducible Runs** — Inject `TimePort` and `RandomPort`; pin dependencies and toolchains. Any failure can be replayed deterministically from its captured input.
23. **Verify the Verifier** — Property tests cover all inputs; mutation testing proves the tests catch defects; the mutation score for `domain/` is a gate.
24. **Prove the Critical Core** — The small, high-risk algorithm/protocol gets a formal model (TLA+/Kani/CBMC/Dafny), not just tests.
25. **Fail Safe in Prod** — Ship behind `FeatureFlagPort`, canary the roll-out, and bound the blast radius with timeouts, circuit breakers, and automatic rollback.

## 12FA Compliance

This architecture satisfies the 12-Factor App methodology:

| # | Factor | How Hex Arch Addresses It |
|---|--------|---------------------------|
| 1 | **Codebase** | One codebase in VCS. Multiple deploys via composition root adapter swapping |
| 2 | **Dependencies** | Domain has zero external dependencies. Adapters declare their own |
| 3 | **Config** | `infra/config` reads env vars. Composition root injects into adapters. Domain receives config as function args. `infra/` also holds IaC when resources are provisioned |
| 4 | **Backing services** | Backing services (DBs, queues, APIs) are driven adapters behind ports — attached resources, not embedded dependencies. In dev the local DuckDB hub is that attached resource; in prod they are provisioned as code under `infra/` |
| 5 | **Build/release/run** | Build once. Release by tagging. Run by swapping adapter config per environment |
| 6 | **Stateless processes** | Domain is stateless. State lives in adapters or backing services. Process scaling adds composition roots |
| 7 | **Port binding** | Driving adapters export services via HTTP ports, CLI, or IPC. Self-contained entry points |
| 8 | **Concurrency** | Scale by adding processes (composition root instances), not threads inside domain |
| 9 | **Disposability** | Lifecycle hooks in adapters handle startup/shutdown. Domain has no cleanup |
| 10 | **Dev/prod parity** | Swapping adapters per environment (DuckDB hub→Firestore, DuckDB logger→Sentry, DuckDB bus→Kafka) keeps behavior identical |
| 11 | **Logs** | `LoggerPort` adapter pattern. Logs are event streams — domain doesn't write to files. Dev streams into the DuckDB hub where they stay queryable |
| 12 | **Admin processes** | Admin tasks are driving adapters reusing the same domain + adapters. Run as one-off root-level entry points |

## When to Use

- Complex application logic that needs isolation from frameworks
- Applications requiring multiple data sources or external services
- Systems where testability and maintainability are priorities
- Projects where you may swap infrastructure (databases, APIs, frameworks)
- Applications with relational persistence — write SQL in repository adapters and map rows to domain models
- Applications that provision cloud resources — declare them as code under `infra/`
- Multi-platform apps sharing domain logic across backend/frontend/mobile/embedded
- **Nested hexagon** — when 3+ bounded contexts exist with independent data models, teams, or evolution rates

## Decision Checklist

```
Building a new feature?
├─ Define Domain Models first (pure data, no imports)
├─ Create Ports for any external dependency (Protocol/Interface/Trait)
├─ Add TimePort for any process that needs duration tracking
├─ Use single files for modules with < 3 files (errors.py, not errors/__init__.py)
├─ Add capabilities as files under domain/, infra/, adapters/, tests/ — never a new root folder
├─ Implement Workflows as pure functions (same input → same output)
├─ Create infra/ modules for cross-cutting concerns
├─ Provisioning resources? Declare them as IaC under infra/; otherwise keep infra/ config-only
├─ Persist through a *Repository port whose adapter writes SQL and maps rows to domain models
├─ Point dev logging, metrics, and events at the local DuckDB hub
├─ Build Adapters for specific infrastructure
├─ Create tests/fixtures/ with factories, builders, and fakes
├─ Write unit tests with Fake Adapters using shared fixtures
├─ Write integration tests for real Adapters
├─ Wire everything in the entry point (main, app, index)
├─ Run the port's contract test against every adapter (local and copied-in)
├─ Return/raise AppError everywhere (code, context, cause, origin, correlation_id)
├─ Register each new code in the error registry (errors-check must pass)
├─ Install a crash/panic handler and breadcrumb buffer in the composition root
├─ Add a fault-injection test for every driven adapter's failure paths
├─ Inject TimePort and RandomPort; never use global time/RNG
├─ Add property tests for domain invariants; add a regression test per discovered counterexample
├─ Add mutation testing for domain/ and gate on a mutation-score threshold
├─ Model-check / bounded-verify the critical core (TLA+, Kani, CBMC, Dafny)
├─ Put risky behavior behind a FeatureFlagPort; plan canary + rollback
├─ Run just verify (lint, typecheck, adapters-check, errors-check, all test tiers)

Multiple languages?
├─ Each language gets its own folder with full hexagonal arch
├─ Shared contracts via proto/openapi in shared/
├─ Workspace-level justfile for cross-service commands
│  └─ defines root := justfile_directory() + one path var per project; commands cd into project dirs
└─ No direct imports between languages — communicate via ports

Multiple bounded contexts?
├─ Use nested hexagonal architecture
├─ Create domain/shared/ for cross-context models only
├─ Each context gets its own models/, ports/, workflows/, errors/
├─ Contexts communicate via ports/adapters, never direct imports
├─ Adapters organized by context: adapters/<context>/
└─ Tests organized by context: tests/unit/<context>/
```

## Entry Point Naming

The composition root can be named based on project role:

| Project Type      | Entry Point          |
| ----------------- | -------------------- |
| API/Web           | `main`, `api`, `app` |
| Worker/Background | `worker`, `consumer` |
| CLI               | `cli`, `main`        |
| Engine/Core       | `engine`, `core`     |
| Scheduler         | `scheduler`, `cron`  |
| Admin/Migration   | `admin`, `migrate`, `manage` |

Admin tasks are just another driving adapter — they reuse the same domain + adapters as the main app. Admin entry points are **root-level files** (`migrate.py`, `manage.py`), never an `admin/` folder.

```
# migrate.py (root) — same wiring as main, different driving adapter
from adapters.firestore_adapter import FirestoreDocumentAdapter
from infra.config import FirestoreConfiguration

config = FirestoreConfiguration.from_environment()
repo = FirestoreDocumentAdapter(config.project_id, config.collection_name)

# Run migration logic using the same domain workflows
```

## Root Justfile Requirements

Every project has a root `justfile` (or `Justfile`) that acts as a **light command index** — it names tasks and delegates; it never contains logic.

**Rules for a light justfile:**

- **One task, one command.** A recipe is a single line calling a program (`uv run python cli.py <task>`, `cargo run --bin <task>`, `npm run <task>`). No inline loops, `awk`, `sed`, or pipelines.
- **Logic lives in code**, in a root entry file (e.g. `cli.py`) or an adapter, where it is typed, tested, and reusable.
- **Doc-comment every recipe** so `just --list` is the menu.
- **`cd {{root}}` first** so recipes are cwd-independent.
- **Output is colored and structured** (see Terminal Output) — never raw `echo`.
- **Compose, don't duplicate:** combined gates depend on other recipes (`verify: check ...`).

```just
set shell := ["bash", "-uc"]
set dotenv-load

root := justfile_directory()

default:
    @just --list

# Develop
run:
    uv run python main.py
dev:
    uv run python cli.py dev
logs:
    uv run python cli.py logs

# Debug & DX
doctor:
    uv run python cli.py doctor
seed:
    uv run python cli.py seed
replay id:
    uv run python cli.py replay {{id}}

# Local-first backing services (only when using the DuckDB hub)
hub:
    uv run python cli.py hub
insights:
    uv run python cli.py insights
db-prune:
    uv run python cli.py db-prune
db-size:
    uv run python cli.py db-size
db-shell:
    uv run python cli.py db-shell

# Test
test:
    uv run pytest
test-unit:
    uv run pytest tests/unit
test-contract:
    uv run pytest tests/integration -k contract
test-integration:
    uv run pytest tests/integration
test-fault:
    uv run pytest tests -k fault
test-property:
    uv run pytest tests/property
test-e2e:
    uv run pytest tests/e2e

# Quality
lint:
    uv run ruff check .
format:
    uv run ruff format .
typecheck:
    uv run pyright
adapters-check:
    uv run lint-imports
errors-check:
    uv run python cli.py check-errors
sanitizers:
    uv run python cli.py sanitizers
mutation:
    uv run mutmut run

# Build
build:
    uv run python cli.py build
clean:
    rm -rf build/

# Dependencies
install:
    uv sync
update:
    uv lock --upgrade && uv sync

# Combined gates
check: lint typecheck adapters-check errors-check test
verify: check test-contract test-fault test-e2e
verify-hard: verify sanitizers
verify-plus: verify test-property mutation
```

### Terminal Output (Rich)

Terminal output is part of the DX: colored, aligned, and structured. It is a **presentation adapter** (`PresenterPort`), never ad-hoc `print`/`echo`.

- **Color with meaning:** green success, red error, yellow warning, cyan info, magenta headings, dim context.
- **Rich panels** for summaries, errors, and check results; **tables** for lists (adapters, insights, coverage); **spinners/progress** for long tasks.
- **Auto-degrade:** respect `NO_COLOR`, `--no-color`, `TERM=dumb`, and non-TTY → plain text. Never hardcode ANSI in domain or driven adapters.
- **Errors use the diagnostic contract:** render `code` + `origin` + `correlation_id` + cause chain in one panel.

```python
# domain/ports/presenter.py
from typing import Protocol, Sequence

class PresenterPort(Protocol):
    def success(self, message: str) -> None: ...
    def error(self, message: str) -> None: ...
    def warn(self, message: str) -> None: ...
    def info(self, message: str) -> None: ...
    def panel(self, title: str, body: str, style: str = "cyan") -> None: ...
    def table(self, title: str, headers: Sequence[str],
              rows: Sequence[Sequence[str]]) -> None: ...

# adapters/console/rich_presenter.py (dev/default) — `rich` panels + tables
from rich.console import Console
from rich.panel import Panel
from rich.table import Table

class RichPresenter(PresenterPort):
    def __init__(self, no_color: bool = False):
        self._console = Console(no_color=no_color)   # honors NO_COLOR / non-TTY
    def success(self, message): self._console.print(f"[green]OK[/green] {message}")
    def error(self, message):   self._console.print(f"[red]FAIL[/red] {message}")
    def warn(self, message):    self._console.print(f"[yellow]WARN[/yellow] {message}")
    def info(self, message):    self._console.print(f"[cyan]INFO[/cyan] {message}")
    def panel(self, title, body, style="cyan"):
        self._console.print(Panel(body, title=title, border_style=style, expand=False))
    def table(self, title, headers, rows):
        table = Table(title=title, show_lines=True)
        for header in headers:
            table.add_column(header, style="bold")
        for row in rows:
            table.add_row(*row)
        self._console.print(table)
```

```python
# rendering a failure as one panel
presenter.panel(
    f"[red]{err.code}[/red] {err.message}",
    f"origin: {err.origin}\ncorrelation: {err.correlation_id}\ncause: {err.cause}",
    style="red",
)
```

| Language | Presenter library |
| -------- | ----------------- |
| Python | `rich` (panels, tables, progress) |
| TypeScript/Node | `boxen` + `chalk` (+ `ora`, `listr2`) |
| Rust | `comfy-table` + `owo-colors` (+ `indicatif`) |
| Dart/Flutter | `ansicolor` (+ a small panel helper) |
| C++ | `fmt` + a small color/panel helper |

**Path variables:** Every justfile defines `root := justfile_directory()` at the top — the directory the justfile lives in. Multi-project repos define one path variable per project below it. Recipes `cd` into their target working directory before running commands, so a command never depends on the caller's cwd:

```just
# Single project — root is this project's directory
root := justfile_directory()

test:
    cd {{root}} && uv run pytest

build:
    cd {{root}}/infra && docker compose build
```

```just
# Multi-project workspace — one path var per project
root := justfile_directory()
backend_dir := root / "backend"
frontend_dir := root / "frontend"

test-backend:
    cd {{backend_dir}} && just test

test-frontend:
    cd {{frontend_dir}} && just test
```

**Why these commands matter:**
- `lint` + `format` + `typecheck` catch errors before they reach tests
- `adapters-check` keeps adapters portable (no app imports, no env reads)
- `test-unit` gives fast feedback during development
- `build` + `clean` ensure reproducible builds from source
- `check` is the single command to run before committing

## Directory Structure

Every project has exactly **four root directories** — `domain/`, `infra/`, `adapters/`, `tests/`. Entry points (`main.py`, `migrate.py`, …) are root-level files. Never add a root folder for a new capability; put it under an existing dir (e.g. a DuckDB hub at `adapters/duckdb/hub.py`).

**Small projects:**

```
project/
├── domain/
│   ├── models
│   ├── constants
│   ├── errors
│   ├── ports
│   └── workflows
├── infra/
│   ├── config
│   └── iac/               # optional Infrastructure as Code (tool-agnostic)
├── adapters/
│   ├── duckdb/            # optional local-first backing services
│   └── <adapter_files>
├── tests/
│   ├── fixtures/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── <entry_point>
└── <config_files>
```

**Larger projects:**

```
project/
├── domain/
│   ├── models/
│   ├── constants
│   ├── errors/
│   ├── ports/
│   └── workflows/
├── infra/
│   ├── config
│   └── iac/               # optional Infrastructure as Code (tool-agnostic)
├── adapters/
│   ├── duckdb/            # optional local-first backing services
│   └── <adapter_files>
├── tests/
│   ├── fixtures/
│   │   ├── factories
│   │   ├── builders
│   │   └── fakes/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── <entry_point>
└── <config_files>
```

## Nested Hexagonal Architecture (Extremely Large Projects)

For large systems with **multiple bounded contexts** (e.g., `billing`, `inventory`, `users`), apply hexagonal architecture **recursively** — each bounded context is its own hexagon inside the outer hexagon.

### When to Use

- 3+ bounded contexts with independent data models
- Different teams own different contexts
- Contexts evolve at different rates
- Each context may have its own persistence, API, or messaging

### Nested Structure

```
project/
├── domain/
│   ├── shared/                      # Shared kernel (cross-context models, ports)
│   │   ├── models/
│   │   ├── constants                # Shared business constants across contexts
│   │   ├── ports/
│   │   └── errors
│   ├── billing/                     # Bounded context #1
│   │   ├── models/
│   │   ├── constants                # Billing-specific constants
│   │   ├── ports/
│   │   ├── errors
│   │   └── workflows/
│   ├── inventory/                   # Bounded context #2
│   │   ├── models/
│   │   ├── constants                # Inventory-specific constants
│   │   ├── ports/
│   │   ├── errors
│   │   └── workflows/
│   └── users/                       # Bounded context #3
│       ├── models/
│       ├── constants                # User-specific constants
│       ├── ports/
│       ├── errors
│       └── workflows/
├── infra/
│   ├── config
│   └── iac/               # optional Infrastructure as Code (tool-agnostic)
├── adapters/
│   ├── billing/
│   ├── inventory/
│   └── users/
├── tests/
│   ├── unit/
│   │   ├── billing/
│   │   ├── inventory/
│   │   └── users/
│   ├── integration/
│   │   ├── billing/
│   │   ├── inventory/
│   │   └── users/
│   └── e2e/
│       └── test_checkout_flow       # Cross-context E2E
├── <entry_points>
└── <config_files>
```

### Rules for Nested Hexagons

1. **Shared kernel is small** — Only truly cross-cutting models (`Money`, `AuditStamp`, `EventBus` port) go in `domain/shared/`. Keep it minimal.
2. **Contexts cannot import each other directly** — If billing needs user info, define a port in billing (`UserLookupPort`) and implement an adapter that queries users context.
3. **Cross-context communication via ports** — Use `EventBus` port for async, or define explicit port+adapter for sync queries.
4. **Each context has its own ports/adapters** — `adapters/billing/` only implements `domain/billing/ports/`.
5. **Workflows are context-scoped** — `billing/workflows/` only imports from `billing/models/`, `billing/ports/`, and `domain/shared/`.
6. **Entry point wires contexts together** — The composition root creates adapters and maps ports to implementations for all contexts.

### Cross-Context Interaction Pattern

```
# domain/billing/ports/user_lookup (billing defines what it needs)
Port: UserLookupPort
  get_user_credit_limit(user_id: string) -> Money

# domain/users/ports/user_repository (users context exposes its own port)
Port: UserRepository
  get_user(user_id: string) -> User

# adapters/billing/user_lookup_adapter (adapter bridges contexts via injected port)
class UserLookupAdapter implements UserLookupPort:
  __init__(user_repository: UserRepository)
  get_user_credit_limit(user_id: string) -> Money:
    user = user_repository.get_user(user_id)
    return user.credit_limit
```

## Multi-Language Projects

When a project spans multiple languages (e.g., Python backend + TypeScript frontend + Flutter mobile), each language gets its own folder with a complete hexagonal architecture. They share infrastructure at the root level.

### Multi-Language Structure

```
project/
├── shared/                          # Cross-language contracts
│   ├── proto/                       # Protobuf / gRPC definitions
│   ├── openapi/                     # API specifications
│   └── constants                    # Shared business constants
├── backend/                         # Python hexagonal arch
│   ├── domain/
│   │   ├── models/
│   │   ├── ports/
│   │   └── workflows/
│   ├── infra/
│   ├── adapters/
│   ├── tests/
│   └── main.py
├── frontend/                        # TypeScript hexagonal arch
│   ├── domain/
│   │   ├── models/
│   │   ├── ports/
│   │   └── workflows/
│   ├── infra/
│   ├── adapters/
│   ├── tests/
│   └── main.ts
├── mobile/                          # Flutter hexagonal arch
│   ├── lib/domain/
│   │   ├── models/
│   │   ├── ports/
│   │   └── workflows/
│   ├── lib/infra/
│   ├── lib/adapters/
│   ├── test/
│   └── main.dart
├── infra/                           # Shared infrastructure
│   ├── docker-compose.yml           # local backing services
│   ├── shared_config/
│   └── iac/                         # optional Infrastructure as Code (tool-agnostic)
├── justfile                         # Workspace-level commands
└── README.md
```

### Rules for Multi-Language Projects

1. **Each language is a self-contained hexagon** — full domain/ports/adapters/tests in its own folder
2. **Shared contracts via proto/openapi** — cross-language interfaces defined in `shared/`, not duplicated
3. **Shared infra at root** — Docker, shared config, workspace commands live at workspace root
4. **No direct imports across languages** — communicate via ports (HTTP, gRPC, message queues)
5. **Workspace logs** — each service gets a color-coded log stream (see Workspace Log Streaming)
6. **Workspace justfile owns paths** — define `root := justfile_directory()` plus one path variable per project (`backend_dir`, `frontend_dir`, ...). Every recipe `cd`s into the target project directory before running its commands — never rely on the caller's working directory

### Workspace Justfile

```just
# project/justfile
set dotenv-load

# Path variables — workspace root plus one per project
root := justfile_directory()
backend_dir := root / "backend"
frontend_dir := root / "frontend"
mobile_dir := root / "mobile"

default:
    @just --list

# Run all services
up:
    cd {{backend_dir}} && just run &
    cd {{frontend_dir}} && just run &
    cd {{mobile_dir}} && just run &

# Stop all services
down:
    pkill -f "backend" || true
    pkill -f "frontend" || true

# Stream logs from all services
logs:
    @echo "Starting log streams..."
    cd {{backend_dir}} && just logs &
    cd {{frontend_dir}} && just logs &

# Run all tests
test:
    cd {{backend_dir}} && just test &
    cd {{frontend_dir}} && just test &
    cd {{mobile_dir}} && just test

# Lint all services
lint:
    cd {{backend_dir}} && just lint &
    cd {{frontend_dir}} && just lint &
    cd {{mobile_dir}} && just lint
```

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

## Pure Functions in Domain

Domain workflows should be pure functions wherever possible. This makes testing trivial, eliminates code duplication, and makes the system predictable.

### What is a Pure Function?

A pure function has two properties:
1. **Same input → same output** — no hidden state, no randomness
2. **No side effects** — doesn't modify external state (files, databases, network)

```python
# BAD: impure — depends on external state
def calculate_total(cart):
    tax_rate = get_tax_rate_from_db()  # Hidden dependency!
    return cart.subtotal * (1 + tax_rate)

# GOOD: pure — all dependencies injected
def calculate_total(cart: Cart, tax_rate: float) -> float:
    return cart.subtotal * (1 + tax_rate)
```

### Pure Functions in Domain Workflows

```python
# BAD: impure workflow — I/O mixed with logic
def create_document(content: str, db_connection) -> Document:
    document = Document.create(content=content)
    db_connection.execute("INSERT INTO docs ...")  # Side effect!
    send_notification("Document created")           # Side effect!
    return document

# GOOD: pure workflow — logic only, I/O in adapters
def create_document(
    content: str,
    repo: DocumentRepository,
    logger: LoggerPort,
    time: TimePort,
) -> Document:
    # Pure logic: validation
    if not content.strip():
        raise EmptyContentError()

    # Pure logic: create model
    document = Document.create(content=content)

    # Adapter calls: all I/O happens here
    repo.save(document)
    logger.info(f"Document created {document.id} in {time.elapsed_ms(start)}ms")
    return document
```

### Pure Function Benefits

| Aspect | Impure | Pure |
|--------|--------|------|
| **Testing** | Mock everything, setup/teardown | Call function, check result |
| **Duplication** | Logic scattered across I/O | Logic concentrated in one place |
| **Debugging** | Trace through layers | Test function in isolation |
| **Refactoring** | Fear of breaking side effects | Safe to rearrange pure logic |

### Pure Function Testing Pattern

```python
# Domain unit tests: pure functions are trivial to test
def test_calculate_total():
    cart = Cart(items=[CartItem(price=10, quantity=2)])
    assert calculate_total(cart, tax_rate=0.08) == 21.6

def test_calculate_total_zero_tax():
    cart = Cart(items=[CartItem(price=10, quantity=2)])
    assert calculate_total(cart, tax_rate=0.0) == 20.0

# No mocks, no setup, no database — just input → output
```

### Adapter Impurity is Fine — But Use Pure Functions Inside

Adapters handle I/O, but the logic *inside* adapters should still be pure where possible. Separate the I/O from the transformation.

```python
# BAD: I/O and transformation mixed
class FirestoreAdapter:
    def find_user(self, user_id):
        doc = self.collection.document(user_id).get()  # I/O
        data = doc.to_dict()
        return User(id=data["id"], name=data["name"], email=data["email"])  # Transformation

# GOOD: pure mapping function extracted
def map_firestore_doc_to_user(data: dict) -> User:
    """Pure function — no I/O, trivial to test."""
    return User(id=data["id"], name=data["name"], email=data["email"])

class FirestoreAdapter:
    def find_user(self, user_id):
        doc = self.collection.document(user_id).get()  # I/O
        return map_firestore_doc_to_user(doc.to_dict())  # Pure call
```

**Rule:** Adapter files contain two kinds of code:
1. **I/O code** — thin methods that call external services (impure, hard to unit test)
2. **Pure helpers** — mapping, validation, transformation functions (easy to unit test)

Extract pure helpers into standalone functions or a separate `mapping.py` / `transforms.ts` file. Test them without mocks.

### Reusable Adapters

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
