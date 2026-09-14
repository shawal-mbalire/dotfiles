# Project Structures

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
