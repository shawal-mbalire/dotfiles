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

**Larger projects (folders):**

```
domain/
├── models/
├── constants    # Named business constants (injected from config, never hardcoded)
├── errors/
├── ports/
└── workflows/
```

**Domain Constants Pattern:**

Domain code must never hardcode numeric values. There are two kinds of constants in the domain:

1. **Static constants** — pure business knowledge (mathematical, physical, or fixed rules). Defined directly in domain constants, never from env vars.
2. **Configurable constants** — deployment-specific values (timeouts, thresholds, pin numbers). Defined as a frozen/immutable struct in domain constants, values loaded from `infra/config`.

### 2. Infrastructure (Cross-Cutting Concerns)

**Single project:** `infra/` folder inside the project.

**Multi-project workspace:** Root-level `infra/` that all projects share. Contains only plumbing (config, env loading). Logging, presentation, and other I/O are adapters of their respective ports.

**Rules for infra/:**

- Contains ONLY config/settings plumbing (env loading, settings management)
- Logging is an adapter (implements `LoggerPort`), not infra
- Presentation/output is an adapter, not infra
- Caching, metrics, events are adapters (shared or project-local)
- Never put application logic, ports, or models in infra

### 3. Adapters (Outer Ring)

- **Driven Adapters** (Implement Ports): Database clients, API clients, file systems, message queues
- **Driving Adapters** (Trigger Domain): HTTP routes, CLI handlers, UI controllers, event handlers

**Adapter transferability rules:**

- Accept all external configuration via constructor parameters — never read env vars directly in adapter code
- Map external types (DTOs, ORM models, wire formats) to domain types at the adapter boundary
- One adapter = one external system (Firestore adapter, not generic "storage adapter")
- Adapters may live in `shared/adapters/` when reused across projects, or project-local `adapters/` when specific to one project

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

### Adapter Design for Transferability

Adapters translate between external systems and domain ports. Well-designed adapters can be moved to another project with minimal changes.

**Rules:**

- Accept all external configuration via constructor parameters (connection strings, API keys, collection names)
- Never read environment variables directly in adapter code — the composition root handles that
- Map external types to domain types at the adapter boundary (DTO → Model, ORM Row → Model)
- One adapter = one external system
- Adapters in `shared/adapters/` are reusable across projects; project-local `adapters/` are specific

### 4. Main Entry (Composition Root)

The wiring layer where everything comes together. Reads config from `infra/config`, creates adapters, injects dependencies.

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
| `DocumentRepository` | SQLite adapter | Cloud SQL adapter | Firestore adapter |
| `LoggerPort` | Console adapter | JSON adapter | Sentry adapter |
| `CachePort` | In-memory adapter | Redis adapter | Redis cluster adapter |
| `MetricsPort` | No-op adapter | Prometheus adapter | Datadog adapter |

The domain and ports never change. Only the composition root's adapter wiring differs per environment.

**Codebase:** One codebase tracked in version control. The same repo produces all deploy variants — the composition root plus environment-specific config is what differs, not the source.

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
| Logging   | `LoggerPort`         | `infra/config` | Console, Rich, Sentry, JSON, or structured logger adapter   |
| Config    | Args to functions    | `infra/config` | Env loading centralized here — only place env vars are read |
| Caching   | Decorator pattern    | `infra/config` | Redis, IndexedDB, or in-memory adapter                      |
| Auth      | User model in domain | `infra/config` | JWT decode, OAuth adapter                                   |
| Telemetry | `MetricsPort`        | `infra/config` | Prometheus, Datadog, or OpenTelemetry adapter               |
| Events    | `EventPublisherPort` | `infra/config` | Kafka, RabbitMQ, MQTT, or in-process event bus adapter      |

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

## Testing Strategy

Tests prove the system works before it hits production. Every test should fail loudly with a clear message about what broke and why.

### Test Pyramid

| Layer    | Test Type         | Location             | Speed        | Dependencies  | Purpose |
| -------- | ----------------- | -------------------- | ------------ | ------------- | ------- |
| Domain   | Unit Tests        | `tests/unit/`        | Milliseconds | None (pure)   | Prove application logic is correct |
| Adapters | Integration Tests | `tests/integration/` | Seconds      | Real services | Prove adapters connect correctly |
| Main     | End-to-End Tests  | `tests/e2e/`         | Minutes      | Full stack    | Prove the whole system works |

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

### Error Identification Patterns

**Domain errors** — specific, named, self-documenting:

```
# BAD: generic exception — what content? what constraint?
raise ValueError("Invalid input")

# GOOD: specific error — tells you exactly what happened
raise EmptyContentError("Document content cannot be empty")
raise DocumentNotFoundError(document_id="abc-123")
raise DuplicateDocumentError(document_id="abc-123", existing_title="My Doc")
```

**Adapter errors** — wrap infrastructure errors with context:

```
# BAD: raw infrastructure error — no context
firestore.Client().collection("docs").document(id).get()

# GOOD: wrapped error with context
try:
    doc = self.collection.document(document_id).get()
except Exception as e:
    raise StorageError(f"Failed to read document {document_id}: {e}") from e
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

Logs must be parseable and searchable. Use structured fields, not string concatenation:

```
# BAD: string concat — impossible to search, impossible to grep
logger.info("User " + user_id + " created order " + order_id)

# GOOD: structured fields — searchable, filterable, aggregatable
logger.info("order_created", user_id=user_id, order_id=order_id, total=total)
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

### Cross-Cutting Concerns

| Concern   | Domain Port          | Infra Module   | Adapter Implementation                                      |
| --------- | -------------------- | -------------- | ----------------------------------------------------------- |
| Logging   | `LoggerPort`         | `infra/config` | Console, Rich, Sentry, JSON, or structured logger adapter   |
| Config    | Args to functions    | `infra/config` | Env loading centralized here — only place env vars are read |
| Caching   | Decorator pattern    | `infra/config` | Redis, IndexedDB, or in-memory adapter                      |
| Auth      | User model in domain | `infra/config` | JWT decode, OAuth adapter                                   |
| Telemetry | `MetricsPort`        | `infra/config` | Prometheus, Datadog, or OpenTelemetry adapter               |
| Events    | `EventPublisherPort` | `infra/config` | Kafka, RabbitMQ, MQTT, or in-process event bus adapter      |

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
11. **Adapters are Transferable** — Adapters depend only on ports and external libraries; they must accept config via constructor injection and be movable to another project by swapping the port interface

## 12FA Compliance

This architecture satisfies the 12-Factor App methodology:

| # | Factor | How Hex Arch Addresses It |
|---|--------|---------------------------|
| 1 | **Codebase** | One codebase in VCS. Multiple deploys via composition root adapter swapping |
| 2 | **Dependencies** | Domain has zero external dependencies. Adapters declare their own |
| 3 | **Config** | `infra/config` reads env vars. Composition root injects into adapters. Domain receives config as function args |
| 4 | **Backing services** | Backing services (DBs, queues, APIs) are driven adapters behind ports — attached resources, not embedded dependencies |
| 5 | **Build/release/run** | Build once. Release by tagging. Run by swapping adapter config per environment |
| 6 | **Stateless processes** | Domain is stateless. State lives in adapters or backing services. Process scaling adds composition roots |
| 7 | **Port binding** | Driving adapters export services via HTTP ports, CLI, or IPC. Self-contained entry points |
| 8 | **Concurrency** | Scale by adding processes (composition root instances), not threads inside domain |
| 9 | **Disposability** | Lifecycle hooks in adapters handle startup/shutdown. Domain has no cleanup |
| 10 | **Dev/prod parity** | Swapping adapters per environment (SQLite→Firestore, Console→Sentry) keeps behavior identical |
| 11 | **Logs** | `LoggerPort` adapter pattern. Logs are event streams — domain doesn't write to files |
| 12 | **Admin processes** | Admin tasks are driving adapters reusing the same domain + adapters. Run as one-off entry points |

## When to Use

- Complex application logic that needs isolation from frameworks
- Applications requiring multiple data sources or external services
- Systems where testability and maintainability are priorities
- Projects where you may swap infrastructure (databases, APIs, frameworks)
- Multi-platform apps sharing domain logic across backend/frontend/mobile/embedded
- **Nested hexagon** — when 3+ bounded contexts exist with independent data models, teams, or evolution rates

## Decision Checklist

```
Building a new feature?
├─ Define Domain Models first (pure data, no imports)
├─ Create Ports for any external dependency (Protocol/Interface/Trait)
├─ Implement Workflows using only Ports (zero infra imports)
├─ Create infra/ modules for cross-cutting concerns
├─ Build Adapters for specific infrastructure
├─ Create tests/fixtures/ with factories, builders, and fakes
├─ Write unit tests with Fake Adapters using shared fixtures
├─ Write integration tests for real Adapters
├─ Wire everything in the entry point (main, app, index)

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

Admin tasks are just another driving adapter — they reuse the same domain + adapters as the main app. Keep admin entry points as separate files or in an `admin/` directory.

```
# admin/migrate.py — same wiring as main, different driving adapter
from adapters.firestore_adapter import FirestoreDocumentAdapter
from infra.config import FirestoreConfiguration

config = FirestoreConfiguration.from_environment()
repo = FirestoreDocumentAdapter(config.project_id, config.collection_name)

# Run migration logic using the same domain workflows
```

## Directory Structure

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
│   └── config
├── adapters/
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
│   └── config
├── adapters/
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
│   └── config
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
