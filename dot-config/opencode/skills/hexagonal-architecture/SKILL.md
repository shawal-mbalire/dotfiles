---
name: hexagonal-architecture
description: Implement Ports and Adapters (Hexagonal Architecture) where the domain owns application logic and adapters handle plumbing. Use when building maintainable, testable applications with clean domain boundaries across any platform. Covers domain modeling, ports/adapters pattern, dependency injection, cross-cutting concerns, lifecycle hooks, deployment artifacts, multi-stack implementations, testing strategies, and 12FA compliance.
---

# Hexagonal Architecture (Ports and Adapters)

Domain owns the application logic. Adapters handle the plumbing. Separate the architecture from the implementation to swap anything without breaking the core.


## Reference Files

`SKILL.md` is the map. Open a file below only when you need its depth.

| Topic | File |
|-------|------|
| Port taxonomy, port design, gateway ports, standard ports | [ports.md](./ports.md) |
| Adapter portability and persistence (adapter-as-ORM) | [adapters.md](./adapters.md) |
| Pure domain functions | [domain.md](./domain.md) |
| Lifecycle, TimePort, LifetimePort | [lifecycle.md](./lifecycle.md) |
| Logging, diagnostics, developer debugging | [observability.md](./observability.md) |
| Local-first DuckDB hub (dev backing services) | [duckdb-hub.md](./duckdb-hub.md) |
| Testing strategy and confidence gates | [testing.md](./testing.md) |
| Entry points, justfile, workspace logs, terminal output | [dx.md](./dx.md) |
| Directory structure, nested hexagons, multi-language | [structures.md](./structures.md) |
| Porting to unsupported languages | [transfer-learning.md](./transfer-learning.md) |
| Language guides | [python.md](./python.md), [typescript.md](./typescript.md), [flutter.md](./flutter.md), [rust.md](./rust.md), [cpp.md](./cpp.md), [embedded.md](./embedded.md) |

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
12. **Ports only when they make sense** — A port is a boundary, not a badge. Add one only when it earns its place (see [Port Taxonomy](./ports.md#port-taxonomy-when-to-add-a-port)); pure logic, pure transforms, and adapter-private concerns stay out.
13. **Fail Fast** — When a system encounters an invalid state, missing dependency, or unrecoverable error, halt immediately and report. Never swallow, never silently degrade, never continue execution in a corrupt state. In dev, fail fast to surface wiring and logic bugs instantly. In prod, fail safe (resilience) but never fail silent.

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
├── ports        # Interfaces defining required I/O (see Port Taxonomy)
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
- Write adapters portable ([Reusable Adapters](./adapters.md#reusable-adapters)) so only the adapter file moves between projects — no `shared/` folder required

### State Management

Domain is stateless — pure functions and workflows that produce results from inputs. All mutable state lives in adapters or backing services.

- **Connection pools** — adapter concern, created at startup, released at shutdown
- **In-memory caches** — adapter concern, never accessed by domain
- **Request-scoped state** — passed as arguments, never stored on domain objects
- **Session/auth state** — decoded at the adapter boundary, injected as domain models

If multiple instances run concurrently, they share no in-process state. All shared state goes through backing services (databases, caches, message queues) via driven adapters.

**Deep dives:** [Port taxonomy, port design, and gateway ports](./ports.md) · [Adapter portability and persistence](./adapters.md) · [Pure domain functions](./domain.md)

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

**Local-first default:** in dev, all three — logs, metrics, and events — point at the same local DuckDB hub (see [Local-First Backing Services](./duckdb-hub.md#local-first-backing-services-duckdb-hub)). Dev observation happens with SQL, not a SaaS dashboard, and prod swaps to managed services without touching the domain.

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
| External APIs | `*Gateway`        | `infra/config` | HTTP/gRPC/MQTT/SOAP client adapter; protocol declared in injected config |
| Telemetry | `MetricsPort`        | `infra/config` | DuckDB hub (dev), Prometheus/Datadog/OTel (prod)            |
| Events    | `EventPublisherPort` | `infra/config` | DuckDB hub (dev), Kafka/RabbitMQ/MQTT (prod)                |
| Events    | `EventConsumerPort`  | `infra/config` | DuckDB hub (dev), Kafka/RabbitMQ/MQTT (prod)                |
| Time      | `TimePort`           | `infra/config` | System clock, high-res timer, mock clock adapter            |
| Tracing   | `TracerPort`         | `infra/config` | DuckDB spans (dev), OpenTelemetry (prod)                    |
| Diagnostics | `AppError` + `ErrorReporterPort` | `infra/config` | DuckDB `diagnostics` table (dev), Sentry (prod) |
| Feature flags | `FeatureFlagPort` | `infra/config` | Local flags file (dev), LaunchDarkly/Unleash (prod) |
| Presentation | `PresenterPort` | `infra/config` | `rich` panels/tables (dev), plain/JSON (CI, non-TTY) |
| Lifetime  | `LifetimePort`       | `infra/config` | Signal handler, process observer, mock lifetime adapter     |

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
26. **Gateway Ports for External Services** — Wrap each external system behind a `*Gateway` port that exposes domain capabilities only. The networking protocol lives in the adapter's frozen config, never in the port signature; swap transports per environment without touching the domain or workflows.
27. **Ports Only When They Make Sense** — Add a port only when the [Port Taxonomy](./ports.md#port-taxonomy-when-to-add-a-port) test fires (real external dependency, substitution/test need, ≥2 implementations, or required determinism). Never create a port for pure logic, a pure transform, or an adapter-private concern.
28. **Fail Fast at Every Boundary** — Invalid state must never propagate. Domain workflows validate inputs as their first action. The composition root validates all adapters before starting the driving adapter. Adapters translate vendor errors to `AppError` at the boundary — never return `None`-on-failure, raw SDK errors, or bare strings. Retry only transient errors; non-transient failures (validation, auth, not-found) fail immediately. In dev/test, observability failures panic. In prod, they fall back to stderr. Event consumers have a maximum retry count per message — after exhausting retries, move to a dead letter queue and alert.
29. **File Placement** — A project has exactly four root directories (`domain/`, `infra/`, `adapters/`, `tests/`) plus root-level entry points. Every new file goes into one of these. No fifth root directory, ever. The decision tree: Is it an entry point? → root file. Is it a port/interface? → `domain/ports/`. Is it a model? → `domain/models/`. Is it workflow orchestration? → `domain/workflows/`. Is it an error type? → `domain/errors/`. Is it a portable adapter implementing a port? → `adapters/<backend>/`. Is it a decorator wrapping a port? → `adapters/decorators/`. Is it config or infra-as-code? → `infra/`. Is it a test? → `tests/`. If it doesn't fit, it's not a new file — it belongs inside an existing one. See [File Placement](./structures.md#where-does-a-new-file-go).
30. **Domain, Port, or Adapter** — Every piece of code is one of three things. Domain = pure business logic, no side effects, imports nothing outside itself. Port = an interface (Protocol/ABC/Trait) the domain defines to declare what it needs (e.g., "I need a logger"). Adapter = an implementation of a port that talks to the outside world (e.g., GCloudLogger, JsonLogger — both implement LoggerPort). The domain never knows which adapter it's using; the composition root wires the right one. If it has side effects, it's an adapter. If it's an interface the domain defines, it's a port. If it's pure logic with no external dependency, it's domain. See [Domain, Port, or Adapter?](./structures.md#domain-port-or-adapter).
31. **Transferable Ports and Adapters** — Every port and adapter must be copy-pasteable into another project unmodified. Ports contain no app-specific types — only domain primitives and standard port vocabulary. Adapters depend only on standard ports + their driver — never on app models, sibling adapters, or project-specific code. Before adding a port or adapter from a collection, verify it compiles and passes its contract test in the target project with zero changes.
32. **Two Kinds of Functions** — Every function in the system is one of two kinds. Pure functions: same input → same output, no side effects, no port calls — trivial to test by calling and checking. Pure orchestrators: coordinate pure functions and port calls, no business logic inline — testable by faking ports. If a function does both (logic + side effects), split it. If a function is too large, extract the logic into pure functions and keep the orchestration thin. This prevents god functions and keeps every function testable at the lowest tier. See [Pure Functions and Pure Orchestrators](./structures.md#pure-functions-and-pure-orchestrators).
33. **Workflows Are the App; Entry Points Are the Wiring** — A workflow is a domain operation that orchestrates pure functions and ports to achieve a business goal (authenticate user, create document, process payment). It lives in `domain/workflows/`, takes ports as arguments, and contains zero imports from adapters or infra. An entry point is a root-level file (main.py, cli.py, api.py) that reads config, creates adapters, wires them to ports, and starts the driving adapter. Workflows define what the app does. Entry points define how it starts. Never put business logic in an entry point. Never wire adapters in a workflow. See [Workflows vs Entry Points](./structures.md#workflows-vs-entry-points).

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

## When NOT to Use

- **Simple CRUD applications** — a traditional layered architecture (controller → service → repository) is simpler and faster to build. Hexagonal adds ceremony that doesn't pay off when there's one database and no external services.
- **Prototypes and MVPs** — when you're validating an idea, skip the architecture. Add it later when the domain logic stabilizes.
- **Single-developer projects with no external dependencies** — if you're the only developer and your app talks to one database, the port/adapter abstraction adds complexity without benefit.
- **Scripts and CLI tools** — one-off scripts, build tools, and data pipelines rarely need swappable adapters or complex test harnesses.
- **Applications with trivial domain logic** — if your app is mostly UI + database with no business rules, hexagonal architecture is over-engineering.
- **Tight deadline prototypes** — when shipping in days matters more than long-term maintainability, use a simpler architecture. Refactor to hexagonal when the deadline passes and the codebase survives.
- **Libraries and frameworks** — hexagonal is for applications, not reusable libraries. Libraries expose APIs, not adapters.

**Rule of thumb:** Start with the simplest architecture that works. Adopt hexagonal when you feel the pain of tight coupling (hard to test, hard to swap databases, hard to add a second data source).

## Performance Considerations

Hexagonal architecture adds indirection layers. Here's what to know about performance:

### Overhead Sources

| Source | Impact | Mitigation |
|--------|--------|------------|
| **Dynamic dispatch** (virtual functions, trait objects) | ~1-5 ns per call (inlining barrier) | Acceptable for I/O-bound apps; use generics/static dispatch for hot paths |
| **Decorator stacking** (retry, cache, metrics) | Each decorator adds a function call | Stack only necessary decorators; profile before adding |
| **Marshaling** (row ↔ domain model mapping) | O(n) per entity, involves allocations | Keep mappings simple; reuse buffers where possible |
| **Buffer flushing** (DuckDB hub, event bus) | Latency spike on flush | Tune batch_size; flush on `LifetimePort` cleanup, not per request |

### Language-Specific Notes

**Python:**
- `Protocol` has zero runtime cost — it's a type-checking hint only
- Avoid `ABC` for hot paths — `@abstractmethod` adds overhead
- Use `__slots__` on domain models for memory-constrained environments

**TypeScript:**
- Interfaces are erased at runtime — zero overhead
- `async/await` adds microtask queue overhead; prefer synchronous ports where possible
- Consider `Map` over `Object` for frequent key lookups

**Rust:**
- `dyn Trait` (trait objects) uses vtable dispatch — ~1 ns overhead per call
- Monomorphization (generics) gives zero-cost abstraction — prefer over `dyn` for performance-critical paths
- `Send + Sync` bounds add no runtime cost — they're compile-time checks only

**C++:**
- Virtual functions add vtable indirection (~1-2 ns)
- Templates are monomorphized — zero overhead, but increase binary size
- RAII destructors are free when inlined; register `LifetimePort` cleanup only when needed

### When to Optimize

1. **Profile first** — hexagonal indirection is rarely the bottleneck; I/O is
2. **Hot paths** — use generics/static dispatch for code called millions of times
3. **Cold paths** — configuration, startup, shutdown — indirection is fine
4. **Decorator overhead** — stack only what you need; each decorator adds a function call
5. **Batching** — buffer writes and flush periodically, not per request

### What NOT to Worry About

- Port method call overhead (nanoseconds) vs database/network latency (milliseconds)
- Domain model field access vs I/O time
- Composition root startup time (runs once)
- Decorator dispatch in non-hot paths

## Decision Checklist

```
Building a new feature?
├─ Define Domain Models first (pure data, no imports)
├─ Create Ports for any external dependency (Protocol/Interface/Trait)
├─ Wrap each external service behind a *Gateway port; declare its transport in the injected config
├─ Add a port only when a Port Taxonomy trigger fires — no speculative ports
├─ Add TimePort for any process that needs duration tracking
├─ Use single files for modules with < 3 files (errors.py, not errors/__init__.py)
├─ Add capabilities as files under domain/, infra/, adapters/, tests/ — never a new root folder
│  └─ Use the [File Placement](./structures.md#where-does-a-new-file-go) decision tree
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
├─ Validate all adapters at startup — crash immediately if any fail
├─ Domain workflows validate inputs as their first action — no invalid state propagates
├─ Retry only transient errors; non-transient failures fail fast
├─ Event consumers have max retry count — poison pills go to dead letter queue
├─ In dev/test, observability failures panic; in prod, fall back to stderr
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

## Multi-Stack Implementations

See language-specific guides for full code examples:

- [Python](./python.md) — Backend, FastAPI
- [TypeScript](./typescript.md) — React, Angular, Node.js
- [Flutter/Dart](./flutter.md) — Mobile apps
- [Rust](./rust.md) — Tauri desktop, systems programming
- [C++](./cpp.md) — Desktop, systems, game engines
- [Embedded](./embedded.md) — MicroPython + C++ on ESP32, STM32, Arduino

## External References

- <https://github.com/shawal-mbalire/shawal_stack/blob/main/hexagonal_architecture.md>
- <https://github.com/shawal-mbalire/shawal_stack/blob/main/architecture-diagram.md>
- <https://github.com/shawal-mbalire/shawal_stack/blob/main/shawal_multi_stack.md>
