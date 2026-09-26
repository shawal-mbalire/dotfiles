# Project Structures

## Directory Structure

Every project has exactly **four root directories** — `domain/`, `infra/`, `adapters/`, `tests/`. Entry points (`main.py`, `migrate.py`, …) are root-level files. Never add a root folder for a new capability; put it under an existing dir.

```
project/
├── domain/
│   ├── models          # Pure data structures representing business concepts
│   ├── constants       # Named business constants (injected from config, never hardcoded)
│   ├── errors          # Custom business-rule exceptions
│   ├── ports           # Interfaces defining required I/O (see Port Taxonomy)
│   └── workflows       # Orchestrate flow using domain models and ports
├── infra/
│   ├── config          # Env loading and settings management
│   └── iac/            # optional Infrastructure as Code (tool-agnostic)
├── adapters/
│   ├── duckdb/         # optional local-first backing services
│   └── <backend>/      # one folder per external system
├── tests/
│   ├── fixtures/       # factories, builders, fakes
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── <entry_point>       # main.py, cli.py, api.py, worker.py
└── <config_files>      # justfile, pyproject.toml, etc.
```

## Where Does a New File Go?

Every new file must land in one of the four root directories or at the root as an entry point. No fifth root directory, ever.

| You're adding... | It goes in... | Example |
|------------------|---------------|---------|
| Entry point (CLI, API, worker, admin) | Root-level file | `main.py`, `cli.py`, `worker.py` |
| Port (interface/contract) | `domain/ports/` | `payment_gateway.py`, `time_port.py` |
| Domain model | `domain/models/` | `document.py`, `user.py`, `money.py` |
| Workflow (orchestration) | `domain/workflows/` | `create_document.py`, `process_payment.py` |
| Business error | `domain/errors/` | `empty_content_error.py` |
| Business constant | `domain/constants.py` | `tax_rates.py` |
| Adapter (implements a port) | `adapters/<backend>/` | `adapters/stripe/gateway.py` |
| Adapter decorator (retry, cache) | `adapters/decorators/` | `retry_repository.py` |
| Adapter mapping (row ↔ domain) | `adapters/<backend>/` | `postgres_mappings.py` |
| Adapter config (frozen struct) | `adapters/<backend>/` | `stripe_config.py` |
| Cross-cutting config | `infra/config.py` | `settings.py` |
| Infrastructure-as-code | `infra/iac/<tool>/` | `docker-compose.yml` |
| Test fixture | `tests/fixtures/` | `factories.py`, `fakes/` |
| Unit test | `tests/unit/` | `test_create_document.py` |
| Integration test | `tests/integration/` | `test_postgres_repository.py` |
| E2E test | `tests/e2e/` | `test_document_crud_flow.py` |

**Anti-patterns:**
- New root directory for a capability — never. Put it under an existing dir.
- New `shared/` folder for adapter code — adapters are portable by file.
- New `utils/` or `helpers/` directory — put utilities in the module that uses them.
- New `models/` or `config/` at root — belongs in `domain/models/` or `infra/config`.

## Domain, Port, or Adapter?

Every piece of code is one of three things:

| Has side effects? | Is it an interface the domain defines? | It's... |
|-------------------|----------------------------------------|---------|
| No | No | **Domain** — pure business logic |
| No | Yes | **Port** — interface the domain declares |
| Yes | No | **Adapter** — implementation that talks to the world |

**The key test — does it import outside?**

```
Does the file import from:
  - domain/         → it's NOT domain (port or adapter)
  - adapters/       → it's NOT adapter (could be domain or test)
  - stdlib only     → could be domain (if pure) or adapter (if does I/O)
  - third-party lib → it's an adapter (or infra)
```

Domain imports nothing (except its own modules). That's the rule.

| Code | Classification | Why |
|------|---------------|-----|
| `class User: name, email` | **Domain** (model) | Business concept, no side effects |
| `def create_document(content, repo, logger)` | **Domain** (workflow) | Orchestration, calls ports, no direct I/O |
| `class DocumentRepository(Protocol): def save(...)` | **Port** | Interface the domain defines |
| `class SqlRepository: def save(self, entity)` | **Adapter** | Implements port, does DB I/O |
| `class RetryRepository: def save(self, entity)` | **Adapter** (decorator) | Wraps a port, adds retry logic |
| `config = Config.from_environment()` | **Infra** | Env loading, cross-cutting plumbing |
| `def test_create_document_rejects_empty()` | **Test** | Test code, lives in tests/ |

## Workflows vs Entry Points

| | Workflow | Entry Point |
|---|----------|-------------|
| **What it is** | A business operation | The app's startup wiring |
| **Lives in** | `domain/workflows/` | Root-level file (`main.py`, `cli.py`) |
| **Takes as args** | Ports (Protocol/ABC) | Nothing — it creates everything |
| **Does** | Orchestrates pure functions + port calls | Reads config, creates adapters, wires ports, starts driving adapter |
| **Imports from** | `domain/` only | `domain/`, `adapters/`, `infra/` |
| **Contains business logic** | Yes | Never |
| **Testable by** | Faking ports | Integration/E2E tests |

```
Am I writing code that does a business thing?
│
├─ Does it orchestrate pure functions + ports to achieve a goal?
│  └─ YES → WORKFLOW. Put it in domain/workflows/.
│
├─ Does it read config, create adapters, wire them, start the app?
│  └─ YES → ENTRY POINT. Put it at root level.
│
├─ Does it handle HTTP/CLI/IPC requests and call a workflow?
│  └─ YES → DRIVING ADAPTER. Put it in adapters/<driving>/.
│
└─ Does it implement a port (DB, API, file, clock)?
   └─ YES → DRIVEN ADAPTER. Put it in adapters/<backend>/.
```

**Common mistakes:**
- Business logic in `main.py` → move to `domain/workflows/`
- Importing adapters in a workflow → use ports only
- Wiring adapters in a workflow → wire in the entry point
- Putting workflow in `adapters/` → move to `domain/workflows/`

## Transferable Ports and Adapters

Every port and adapter must be **copy-pasteable** into another project with zero modifications.

**Port rules:**
- Accept and return only domain primitives, generics, or standard port vocabulary types
- Never import app models — use `T` (generics) instead
- Never import adapters, drivers, or third-party libraries
- Lives in `domain/ports/`, depends on nothing outside `domain/`

**Adapter rules:**
- Imports only: standard library, driver, standard ports — zero app imports
- Config injected via constructor — never reads env vars directly
- Mappers (`to_row`/`from_row`) injected — never imports domain models
- Translates vendor errors to port errors — never leaks SDK exceptions
- Passes the port's contract test — in the original project AND the target project
- No module-level connections or global state

**Copy-paste test:**
1. Copy the file(s) to a blank project
2. Add the required driver dependency
3. Does it compile/run?
4. Does it pass the port's contract test?

If any step fails, fix the port or adapter — not the target project.

## Pure Functions and Pure Orchestrators

Every function in the system is one of two kinds:

| Kind | What it does | How to test |
|------|-------------|-------------|
| **Pure function** | Same input → same output, no side effects, no port calls | Call it, check the return value |
| **Pure orchestrator** | Coordinates pure functions and port calls, no inline logic | Fake the ports, verify calls |

If a function does both (logic + side effects), split it. If it's too large (>30 lines), extract the logic into pure functions.

### When to Split a Function

| Symptom | Action |
|---------|--------|
| Function does validation + logic + I/O | Extract validation and logic into pure functions |
| Function is longer than ~30 lines | Extract logical blocks into named pure functions |
| Function needs 3+ mocks to test | Split the I/O from the logic |
| Function has an `if` that branches on I/O result | Extract the I/O into a port, keep the branch logic pure |
| Same logic appears in two workflows | Extract into a shared pure function in `domain/` |

### Reads Like Pseudocode

Workflows and entry points must read like pseudocode. Each line expresses one intent. No implementation details leak through.

```python
# GOOD — each line is one intent
def create_document(content: str, repo: DocumentRepository, logger: LoggerPort) -> Document:
    validate_content(content)
    doc = Document.create(content=content)
    repo.save(doc)
    logger.info(f"Created {doc.id}")
    return doc

# BAD — implementation details leak through
def create_document(content: str, repo: DocumentRepository, logger: LoggerPort) -> Document:
    if not content.strip():
        raise EmptyContentError()
    doc_id = str(uuid4())
    doc = Document(id=doc_id, content=content, created_at=datetime.now(), version=1)
    sql = f"INSERT INTO documents (id, content, created_at, version) VALUES ('{doc_id}', '{content}', '{doc.created_at}', {doc.version})"
    repo._connection.execute(sql)
    logger._sink.write(json.dumps({"event": "document_created", "id": doc_id}))
    return doc
```

**The test:** Read the function aloud. If you stumble on implementation details (SQL, JSON, connection strings), those details belong in a pure function or an adapter — not in the workflow or entry point.

## Nested Hexagonal Architecture

For large systems with **multiple bounded contexts** (e.g., `billing`, `inventory`, `users`), apply hexagonal architecture recursively — each bounded context is its own hexagon.

**When to use:** 3+ bounded contexts with independent data models, teams, or evolution rates.

```
project/
├── domain/
│   ├── shared/                # Cross-context models only (Money, AuditStamp, EventBus)
│   ├── billing/               # Bounded context #1
│   │   ├── models/
│   │   ├── ports/
│   │   ├── errors/
│   │   └── workflows/
│   ├── inventory/             # Bounded context #2
│   └── users/                 # Bounded context #3
├── adapters/
│   ├── billing/
│   ├── inventory/
│   └── users/
├── tests/
│   ├── unit/<context>/
│   ├── integration/<context>/
│   └── e2e/
└── <entry_points>
```

**Rules:**
1. **Shared kernel is small** — only truly cross-cutting models go in `domain/shared/`
2. **Contexts cannot import each other** — define a port in the consuming context, implement an adapter that queries the other
3. **Cross-context communication via ports** — `EventBus` for async, explicit port+adapter for sync
4. **Each context has its own ports/adapters** — `adapters/billing/` only implements `domain/billing/ports/`
5. **Workflows are context-scoped** — `billing/workflows/` only imports from `billing/` and `domain/shared/`
6. **Entry point wires contexts together** — composition root maps ports to implementations for all contexts

## Multi-Language Projects

When a project spans multiple languages (e.g., Python backend + TypeScript frontend + Flutter mobile), each language gets its own folder with a complete hexagonal architecture. They share infrastructure at the root level.

```
project/
├── shared/                    # Cross-language contracts (proto, openapi)
├── backend/                   # Python hexagonal arch
│   ├── domain/
│   ├── infra/
│   ├── adapters/
│   ├── tests/
│   └── main.py
├── frontend/                  # TypeScript hexagonal arch
│   ├── domain/
│   ├── infra/
│   ├── adapters/
│   ├── tests/
│   └── main.ts
├── mobile/                    # Flutter hexagonal arch
│   ├── lib/domain/
│   ├── lib/infra/
│   ├── lib/adapters/
│   ├── test/
│   └── main.dart
├── infra/                     # Shared infra (docker-compose, shared config)
├── justfile                   # Workspace-level commands
└── README.md
```

**Rules:**
1. Each language is a self-contained hexagon — full domain/ports/adapters/tests
2. Shared contracts via proto/openapi in `shared/` — not duplicated
3. Shared infra at root — Docker, shared config, workspace commands
4. No direct imports across languages — communicate via ports (HTTP, gRPC, queues)
5. Workspace justfile owns paths — define `root := justfile_directory()` plus one path var per project; recipes `cd` into project dirs
