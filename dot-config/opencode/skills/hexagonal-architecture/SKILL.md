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
9. **Reusable adapters** — Adapters depend only on ports and external libraries. Constructor-inject all config. Move to another project by swapping the port interface.
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

### Adapter Design for Reusability and Transferability

Adapters translate between external systems and domain ports. Well-designed adapters are **reusable across projects** — pick up the file, drop it in another project, implement the port interface, done.

**Transferability rules:**

- Accept all external configuration via constructor parameters (connection strings, API keys, collection names)
- Never read environment variables directly in adapter code — the composition root handles that
- Map external types to domain types at the adapter boundary (DTO → Model, ORM Row → Model)
- One adapter = one external system
- Extract pure mapping/validation functions from adapter methods for independent testing
- Adapters in `shared/adapters/` are reusable across projects; project-local `adapters/` are specific

**Structure of a reusable adapter:**

```
adapters/
├── firestore_user_adapter.py      # I/O: calls Firestore API
├── firestore_user_adapter_test.py # Tests the adapter with real/emulated Firestore
└── firestore_mappings.py          # Pure: DTO → Domain model conversions
```

The mapping file is pure and trivially testable. The adapter file is thin I/O that calls the mapping functions.

### 4. Main Entry (Orchestrator)

The orchestrator is where everything comes together. It reads config from `infra/config`, creates adapters, and plugs them into workflows. Keep it thin — it only wires, never contains logic.

**Orchestrator responsibilities:**
1. Read config from environment (only place env vars are read)
2. Create adapter instances with injected config
3. Pass adapters (via ports) to workflows
4. Start driving adapters (HTTP server, CLI, event loop)

**Orchestrator anti-patterns:**
- Putting business logic in the orchestrator
- Importing adapters in domain code
- Doing I/O before wiring is complete

```
orchestrator/
├── main.py              # Entry point — calls orchestrator functions
├── wire_adapters.py     # Creates adapters, maps ports to implementations
└── config.py            # Reads env vars, returns typed config objects
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
| `DocumentRepository` | SQLite adapter | Cloud SQL adapter | Firestore adapter |
| `LoggerPort` | Console adapter | JSON adapter | Sentry adapter |
| `CachePort` | In-memory adapter | Redis adapter | Redis cluster adapter |
| `MetricsPort` | No-op adapter | Prometheus adapter | Datadog adapter |

The domain and ports never change. Only the composition root's adapter wiring differs per environment.

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
| Logging   | `LoggerPort`         | `infra/config` | Console, Rich, Sentry, JSON, or structured logger adapter   |
| Config    | Args to functions    | `infra/config` | Env loading centralized here — only place env vars are read |
| Caching   | Decorator pattern    | `infra/config` | Redis, IndexedDB, or in-memory adapter                      |
| Auth      | User model in domain | `infra/config` | JWT decode, OAuth adapter                                   |
| Telemetry | `MetricsPort`        | `infra/config` | Prometheus, Datadog, or OpenTelemetry adapter               |
| Events    | `EventPublisherPort` | `infra/config` | Kafka, RabbitMQ, MQTT, or in-process event bus adapter      |
| Time      | `TimePort`           | `infra/config` | System clock, high-res timer, mock clock adapter            |
| Lifetime  | `LifetimePort`       | `infra/config` | Signal handler, process observer, mock lifetime adapter     |

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

Every language implementation must include these ports:

| Port | Purpose | Required Methods |
|------|---------|-----------------|
| `LoggerPort` | Structured logging | `info(message)`, `error(message)` |
| `TimePort` | Process timing | `nowMs()`, `elapsedMs(start)` |
| `LifetimePort` | Graceful exits | `registerCleanup(handler)`, `onExit(handler)`, `getExitReason()`, `isShuttingDown()` |
| `*Repository` | Data persistence | `save(entity)`, `findById(id)` |
| `*Checker` | External validation | domain-specific |

### Justfile for Any Language

```just
# Copy this justfile and replace tool commands for your language

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
| Time      | `TimePort`           | `infra/config` | System clock, high-res timer, mock clock adapter            |

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
11. **Adapters are Reusable** — Adapters depend only on ports and external libraries; they must accept config via constructor injection and be movable to another project by swapping the port interface
12. **Files Over Folders** — Prefer single files when a directory would contain fewer than 3 files. `domain/errors.py` beats `domain/errors/__init__.py` with one file inside
13. **TimePort Everywhere** — Every project includes a `TimePort` for measuring process duration. It makes performance visible and debugging easy across all layers.
14. **Pure Domain Functions** — Domain workflows are pure functions: same input → same output, no side effects. I/O happens in adapters only. Testing becomes trivial.
15. **Pure Adapter Helpers** — Extract mapping/transformation logic from adapter methods into pure functions. Test pure helpers without mocks; test I/O methods with integration tests.
16. **Root Justfile for DX** — Every project has a root justfile with: run, dev, test, lint, format, typecheck, build, clean, check.
17. **LifetimePort for Graceful Exits** — Every workflow registers cleanup via LifetimePort. No resource left behind, no matter the exit reason (crash, user exit, normal, timeout).

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
├─ Add TimePort for any process that needs duration tracking
├─ Use single files for modules with < 3 files (errors.py, not errors/__init__.py)
├─ Implement Workflows as pure functions (same input → same output)
├─ Create infra/ modules for cross-cutting concerns
├─ Build Adapters for specific infrastructure
├─ Create tests/fixtures/ with factories, builders, and fakes
├─ Write unit tests with Fake Adapters using shared fixtures
├─ Write integration tests for real Adapters
├─ Wire everything in the entry point (main, app, index)

Multiple languages?
├─ Each language gets its own folder with full hexagonal arch
├─ Shared contracts via proto/openapi in shared/
├─ Workspace-level justfile for cross-service commands
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

Admin tasks are just another driving adapter — they reuse the same domain + adapters as the main app. Keep admin entry points as separate files or in an `admin/` directory.

```
# admin/migrate.py — same wiring as main, different driving adapter
from adapters.firestore_adapter import FirestoreDocumentAdapter
from infra.config import FirestoreConfiguration

config = FirestoreConfiguration.from_environment()
repo = FirestoreDocumentAdapter(config.project_id, config.collection_name)

# Run migration logic using the same domain workflows
```

## Root Justfile Requirements

Every project must have a root `justfile` (or `Justfile`) with these standard commands for good DX:

```just
# Required commands — every project must have these
default:
    @just --list

# Development
run:                # Start the application
dev:                # Start with hot-reload / watch mode
logs:               # Stream logs from running services

# Testing
test:               # Run all tests
test-unit:          # Run unit tests only
test-integration:   # Run integration tests only
test-e2e:           # Run end-to-end tests only

# Code Quality
lint:               # Check code for issues (ruff, eslint, clippy, clang-tidy)
format:             # Auto-fix code formatting (ruff format, prettier, cargo fmt)
typecheck:          # Static type analysis (pyright, tsc --noEmit, cargo check)

# Build
build:              # Compile/package the application
clean:              # Remove build/ directory entirely

# Dependency Management
install:            # Install dependencies (uv sync, npm install, cargo fetch)
update:             # Update dependencies to latest versions

# Combined
check: lint typecheck test    # Full pre-commit check
```

**Why these commands matter:**
- `lint` + `format` + `typecheck` catch errors before they reach tests
- `test-unit` gives fast feedback during development
- `build` + `clean` ensure reproducible builds from source
- `check` is the single command to run before committing

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
│   ├── docker-compose.yml
│   └── shared_config/
├── justfile                         # Workspace-level commands
└── README.md
```

### Rules for Multi-Language Projects

1. **Each language is a self-contained hexagon** — full domain/ports/adapters/tests in its own folder
2. **Shared contracts via proto/openapi** — cross-language interfaces defined in `shared/`, not duplicated
3. **Shared infra at root** — Docker, shared config, workspace commands live at workspace root
4. **No direct imports across languages** — communicate via ports (HTTP, gRPC, message queues)
5. **Workspace logs** — each service gets a color-coded log stream (see Workspace Log Streaming)

### Workspace Justfile

```just
# project/justfile
set dotenv-load

default:
    @just --list

# Run all services
up:
    just backend/up &
    just frontend/up &
    just mobile/run &

# Stop all services
down:
    pkill -f "backend" || true
    pkill -f "frontend" || true

# Stream logs from all services
logs:
    @echo "Starting log streams..."
    just backend/logs &
    just frontend/logs &

# Run all tests
test:
    just backend/test &
    just frontend/test &
    just mobile/test

# Lint all services
lint:
    just backend/lint &
    just frontend/lint &
    just mobile/lint
```

## TimePort

Every project includes a `TimePort` for measuring process duration. This makes performance visible and debugging easy across all layers.

### Domain Port

```python
# domain/ports/time_port.py (Python)
from typing import Protocol

class TimePort(Protocol):
    def now_ms(self) -> int: ...
    def elapsed_ms(self, start_ms: int) -> int: ...
```

```typescript
// domain/ports/TimePort.ts (TypeScript)
export interface TimePort {
  nowMs(): number;
  elapsedMs(startMs: number): number;
}
```

```rust
// domain/src/ports/time_port.rs (Rust)
pub trait TimePort: Send + Sync {
    fn now_ms(&self) -> u64;
    fn elapsed_ms(&self, start_ms: u64) -> u64;
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

# adapters/mock_time.py (Python - for testing)
class MockTimeAdapter:
    def __init__(self):
        self._current_ms = 0

    def now_ms(self) -> int:
        return self._current_ms

    def elapsed_ms(self, start_ms: int) -> int:
        return self._current_ms - start_ms

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

Adapters must be transferable to other projects without modification. To achieve this:

1. **Depend only on ports** — adapter imports the port interface, never the concrete domain
2. **Constructor-inject all config** — connection strings, API keys, collection names come from outside
3. **No env var reads** — the composition root reads env vars and passes values to the adapter
4. **One adapter = one external system** — Firestore adapter, not generic "storage adapter"
5. **Map at the boundary** — external types (DTOs, ORM models) are converted to domain types at the adapter edge

```
# Reusable adapter — can move to any project
class FirestoreUserAdapter:
    def __init__(self, project_id: str, collection: str):  # Config from outside
        self.client = firestore.Client(project=project_id)
        self.collection = self.client.collection(collection)

    def find(self, user_id: str) -> User:  # Returns domain type
        doc = self.collection.document(user_id).get()
        return map_firestore_doc_to_user(doc.to_dict())  # Pure mapping

# NOT reusable — hard-coded config, env var reads
class BadFirestoreAdapter:
    def __init__(self):
        self.client = firestore.Client(project=os.getenv("PROJECT_ID"))  # BAD
        self.collection = self.client.collection("users")  # BAD
```
