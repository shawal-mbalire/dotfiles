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

## Where Does a New File Go?

Every new file in a project must land in one of the four root directories or at the root as an entry point. No fifth root directory, ever. Use this decision tree to place any new file.

### Decision Tree

```
I just created a new file. Where does it go?
│
├─ Is it an entry point? (CLI command, API server, worker, admin task)
│  └─ YES → Root-level file: main.py, cli.py, worker.py, migrate.py
│
├─ Is it a port (interface/contract the domain needs)?
│  └─ YES → domain/ports/<name>.py
│     Examples: payment_gateway.py, time_port.py, logger.py
│
├─ Is it a domain model (data structure representing a business concept)?
│  └─ YES → domain/models/<name>.py
│     Examples: document.py, user.py, money.py, cart.py
│
├─ Is it a domain workflow (orchestrates models + ports)?
│  └─ YES → domain/workflows/<name>.py
│     Examples: create_document.py, process_payment.py
│
├─ Is it a domain error (business rule violation)?
│  └─ YES → domain/errors/<name>.py
│     Examples: empty_content_error.py, insufficient_funds_error.py
│
├─ Is it a domain constant (named business value)?
│  └─ YES → domain/constants.py (single file) or domain/constants/<name>.py
│     Examples: tax_rates.py, max_upload_size.py
│
├─ Is it a portable adapter (implements a port, depends on a driver)?
│  └─ YES → adapters/<backend>/<name>.py
│     Examples: adapters/stripe/stripe_gateway.py, adapters/postgres/document_repo.py
│
├─ Is it an adapter decorator (wraps a port for retry, cache, metrics)?
│  └─ YES → adapters/decorators/<name>.py
│     Examples: retry_repository.py, cached_repository.py
│
├─ Is it an adapter mapping (pure row ↔ domain conversions)?
│  └─ YES → adapters/<backend>/<backend>_mappings.py
│     Examples: adapters/postgres/postgres_mappings.py
│
├─ Is it an adapter config (frozen struct, constructor-injected)?
│  └─ YES → adapters/<backend>/<backend>_config.py
│     Examples: adapters/stripe/stripe_config.py
│
├─ Is it cross-cutting config (env loading, settings)?
│  └─ YES → infra/config.py or infra/config/<name>.py
│     Examples: infra/config.py, infra/config/settings.py
│
├─ Is it infrastructure-as-code (Terraform, Docker, K8s)?
│  └─ YES → infra/iac/<tool>/<name>
│     Examples: infra/iac/docker/docker-compose.yml
│
├─ Is it a shared test fixture (factory, builder, fake)?
│  └─ YES → tests/fixtures/<name>.py
│     Examples: tests/fixtures/factories.py, tests/fixtures/fakes/
│
├─ Is it a unit test?
│  └─ YES → tests/unit/test_<name>.py
│     Examples: tests/unit/test_create_document.py
│
├─ Is it an integration test?
│  └─ YES → tests/integration/test_<name>.py or tests/integration/test_<port>_contract.py
│     Examples: tests/integration/test_postgres_repository.py
│
├─ Is it an E2E test?
│  └─ YES → tests/e2e/test_<flow>.py
│     Examples: tests/e2e/test_document_crud_flow.py
│
└─ NONE of the above
   └─ STOP. It doesn't need a new file. Put it inside an existing one.
      If you truly can't, ask: does it belong to domain, adapters, infra, or tests?
      If it crosses layers, it's probably a workflow (domain) or a decorator (adapters).
```

### Common New Files and Their Homes

| You're adding... | It goes in... | Example |
|------------------|---------------|---------|
| A new API endpoint (driving adapter) | Root-level file or `adapters/http/` | `api.py` or `adapters/http/routes.py` |
| A new CLI command | Root-level entry point | `cli.py` (add subcommand) |
| A new background worker | Root-level entry point | `worker.py` |
| A new database table + repo | `domain/models/` + `domain/ports/` + `adapters/<db>/` | `document.py` + `document_repo.py` + `adapters/postgres/document_repo.py` |
| A new external API client | `domain/ports/` + `adapters/<service>/` | `payment_gateway.py` + `adapters/stripe/` |
| A new cross-cutting concern (retry, cache) | `adapters/decorators/` | `retry_repository.py` |
| A new error code | `domain/errors/` + `errors.toml` | `insufficient_funds.py` |
| A new config value | `infra/config.py` | Add field to config class |
| A new port archetype | `domain/ports/` | `cache_port.py` |
| A new fake for testing | `tests/fixtures/fakes/` | `fake_repo.py` |
| A migration script | Root-level entry point | `migrate.py` |
| A one-off data fix | Root-level entry point | `fix_data.py` (delete after use) |
| A new bounded context | `domain/<context>/` + `adapters/<context>/` | `domain/billing/` + `adapters/billing/` |

### Anti-patterns

- **New root directory for a capability** — never. Put it under an existing dir.
- **New `shared/` folder for adapter code** — adapters are portable by file, not by shared folder.
- **New `utils/` or `helpers/` directory** — put utilities in the module that uses them.
- **New `models/` directory at root** — models belong in `domain/models/`, not at project root.
- **New `config/` directory at root** — config belongs in `infra/config`, not at project root.

## Domain, Port, or Adapter?

Every piece of code in the system is one of three things. This is the fundamental classification — know which one you're writing before you write it.

### The One-Line Answer

| Has side effects? | Is it an interface the domain defines? | It's... |
|-------------------|----------------------------------------|---------|
| No | No | **Domain** — pure business logic |
| No | Yes | **Port** — interface the domain declares |
| Yes | No | **Adapter** — implementation that talks to the world |

### Decision Tree

```
What am I writing?
│
├─ Does it import from external libraries, frameworks, drivers, or OS?
│  └─ YES → It's an ADAPTER (or belongs in infra/)
│
├─ Does it do I/O? (read/write files, DB, network, stdin/stdout, time)
│  └─ YES → It's an ADAPTER
│
├─ Is it an interface/protocol/trait that the domain defines?
│  └─ YES → It's a PORT
│     The domain says "I need this capability." The adapter provides it.
│
├─ Is it a data structure representing a business concept?
│  └─ YES → It's DOMAIN (model)
│     Examples: User, Document, Cart, Money, OrderStatus
│
├─ Is it a business rule or validation?
│  └─ YES → It's DOMAIN (workflow or model invariant)
│     Examples: "cart total must be positive", "user must have email"
│
├─ Is it orchestration that coordinates models and ports?
│  └─ YES → It's DOMAIN (workflow)
│     Examples: create_document(), process_payment(), calculate_total()
│
├─ Is it a business constant (named value, not hardcoded)?
│  └─ YES → It's DOMAIN (constant)
│     Examples: MAX_RETRY_COUNT = 3, TAX_RATE = 0.08
│
├─ Is it a business error (rule violation)?
│  └─ YES → It's DOMAIN (error)
│     Examples: EmptyContentError, InsufficientFundsError
│
├─ Is it a pure transform/mapping with no side effects?
│  └─ YES → It's DOMAIN (pure helper) or ADAPTER (pure helper inside adapter)
│     If it maps domain types → domain. If it maps DTOs/rows → adapter.
│
└─ Is it cross-cutting plumbing (config, env loading, logging setup)?
   └─ YES → It's INFRA
```

### Classification Examples

| Code | Domain, Port, or Adapter? | Why |
|------|---------------------------|-----|
| `class User: name, email` | **Domain** (model) | Business concept, no side effects |
| `def create_document(content, repo, logger)` | **Domain** (workflow) | Orchestration, calls ports, no direct I/O |
| `if not content.strip(): raise EmptyContentError()` | **Domain** (validation) | Business rule, no side effects |
| `class DocumentRepository(Protocol): def save(...)` | **Port** | Interface the domain defines, no implementation |
| `class TimePort(Protocol): def now_ms(...)` | **Port** | Interface the domain declares |
| `class PaymentGateway(Protocol): def charge(...)` | **Port** | Interface the domain declares |
| `class SqlRepository: def save(self, entity)` | **Adapter** | Implements Repository port, does DB I/O |
| `class StripeGateway: def charge(self, amount, token)` | **Adapter** | Implements PaymentGateway port, does HTTP I/O |
| `class SystemTimeAdapter: def now_ms(self)` | **Adapter** | Implements TimePort, reads system clock |
| `class RetryRepository: def save(self, entity)` | **Adapter** (decorator) | Wraps a port, adds retry logic |
| `config = Config.from_environment()` | **Infra** | Env loading, cross-cutting plumbing |
| `GIT_SHA = "abc123"` | **Infra** | Build metadata, not business logic |
| `def test_create_document_rejects_empty()` | **Test** | Test code, lives in tests/ |

### The Key Test: Does It Import Outside?

The simplest way to classify anything:

```
Does the file import from:
  - domain/         → it's NOT domain (port or adapter)
  - adapters/       → it's NOT adapter (could be domain or test)
  - stdlib only     → could be domain (if pure) or adapter (if does I/O)
  - third-party lib → it's an adapter (or infra)
```

**Domain imports nothing** (except its own modules). That's the rule. If it imports a third-party library, it's an adapter. If it imports from `adapters/`, it's not a domain file. If it imports from `domain/`, it could be an adapter, a port, or a workflow.

### Ports vs Adapters: The Boundary

A port is a **contract**. An adapter is a **fulfillment** of that contract. The domain defines what it needs; the adapter provides it. The domain never knows which adapter it's using.

**Concrete example — logging:**

```
Domain says:          "I need to log things"
                      ↓
Port defines:         LoggerPort
                        ├── info(message)
                        └── error(message)
                      ↓
Adapters provide:     GCloudLogger    → writes to Google Cloud Logging
                      JsonLogger      → writes structured JSON to stdout
                      ConsoleLogger   → writes plain text to console
                      DuckDBLogger    → writes to local DuckDB (dev)
                      SentryLogger    → sends to Sentry (prod)
                      ↓
Composition root:     picks which adapter to wire based on environment
                      ↓
Domain workflow:      logger.info("document created")  ← doesn't know/care which one
```

**The domain never imports an adapter.** It only knows the port:

```python
# domain/workflows/create_document.py
from domain.ports.logger import LoggerPort  # only knows the port

def create_document(content: str, repo: DocumentRepository,
                    logger: LoggerPort) -> Document:  # depends on port, not adapter
    ...
    logger.info(f"Document {doc.id} created")  # calls the port
    return doc
```

**Each adapter implements the same port:**

```python
# adapters/gcloud/gcloud_logger.py
class GCloudLogger:
    def info(self, message: str) -> None:
        self._client.log_text(message, severity="INFO")  # GCloud API

# adapters/json/json_logger.py
class JsonLogger:
    def info(self, message: str) -> None:
        print(json.dumps({"level": "info", "message": message}))  # stdout

# adapters/console/console_logger.py
class ConsoleLogger:
    def info(self, message: str) -> None:
        print(f"[INFO] {message}")  # plain text
```

**The composition root picks the adapter:**

```python
# main.py — swaps per environment
if ENV == "prod":
    logger = GCloudLogger(project_id=config.gcloud_project)
elif ENV == "dev":
    logger = DuckDBLogger(hub=config.duckdb_path)
else:
    logger = JsonLogger()

doc = create_document("Hello", repo, logger)  # workflow doesn't know which one
```

**Swap adapters without changing domain code.** That's the entire point. The same workflow runs with GCloud in prod, DuckDB in dev, and JSON in tests — because it only depends on the port.

## Workflows vs Entry Points

These are two different things that are often confused. Know which one you're writing.

### The Distinction

| | Workflow | Entry Point |
|---|----------|-------------|
| **What it is** | A business operation | The app's startup wiring |
| **Lives in** | `domain/workflows/` | Root-level file (`main.py`, `cli.py`, `api.py`) |
| **Takes as args** | Ports (Protocol/ABC) | Nothing — it creates everything |
| **Does** | Orchestrates pure functions + port calls | Reads config, creates adapters, wires ports, starts driving adapter |
| **Imports from** | `domain/` only | `domain/`, `adapters/`, `infra/` |
| **Contains business logic** | Yes | Never |
| **Contains adapter wiring** | Never | Always |
| **Testable by** | Faking ports | Integration/E2E tests |

### A Workflow: The Business Operation

A workflow is a pure orchestrator that lives in the domain. It knows nothing about databases, APIs, or frameworks. It only knows ports.

```python
# domain/workflows/authenticate_user.py
from domain.ports.user_repository import UserRepository
from domain.ports.password_hasher import PasswordHasher
from domain.ports.token_service import TokenService

def authenticate_user(
    email: str,
    password: str,
    user_repo: UserRepository,    # port — workflow doesn't know which adapter
    hasher: PasswordHasher,       # port — could be bcrypt, argon2, scrypt
    token_service: TokenService,  # port — could be JWT, OAuth, session
) -> str:
    """Authenticate a user and return a token."""
    # 1. Look up user (port call)
    user = user_repo.find_by_email(email)
    if user is None:
        raise AuthenticationError("Invalid credentials")

    # 2. Verify password (port call)
    if not hasher.verify(password, user.password_hash):
        raise AuthenticationError("Invalid credentials")

    # 3. Generate token (port call)
    token = token_service.generate(user.id)

    return token
```

**What this workflow does NOT know:**
- Which database stores users (Postgres? Firestore? In-memory?)
- Which hashing algorithm is used (bcrypt? argon2?)
- Which token format is used (JWT? OAuth? Session ID?)
- Which web framework is handling the request (FastAPI? Express? Rocket?)

**It only knows the ports.** The entry point wires the right adapters.

### An Entry Point: The Startup Wiring

An entry point is a root-level file that creates everything and starts the app. It knows about adapters, config, and frameworks. It never contains business logic.

```python
# main.py — entry point (root-level file)
from infra.config import load_config
from adapters.postgres.user_repository import PostgresUserRepository
from adapters.bcrypt.password_hasher import BcryptPasswordHasher
from adapters.jwt.token_service import JwtTokenService
from adapters.fastapi.driving_adapter import FastApiApp

def main():
    # 1. Read config
    config = load_config()

    # 2. Create adapters (the plumbing)
    user_repo = PostgresUserRepository(config.database_url)
    hasher = BcryptPasswordHasher(rounds=config.bcrypt_rounds)
    token_service = JwtTokenService(secret=config.jwt_secret)

    # 3. Start the driving adapter (the thing that accepts requests)
    app = FastApiApp(
        user_repo=user_repo,
        hasher=hasher,
        token_service=token_service,
    )
    app.run(port=config.port)
```

**What this entry point does NOT know:**
- How authentication works (that's the workflow's job)
- How password hashing works (that's the hasher adapter's job)
- How token generation works (that's the token service adapter's job)

**It only knows how to create adapters and wire them.** That's its job.

### The Flow

```
Request comes in (driving adapter: FastAPI route)
  ↓
Driving adapter calls workflow: authenticate_user(email, password, user_repo, hasher, token_service)
  ↓
Workflow orchestrates: look up user → verify password → generate token
  ↓
Workflow returns result to driving adapter
  ↓
Driving adapter formats response and sends it back
```

The driving adapter (entry point) and the workflow never mix responsibilities. The driving adapter handles HTTP. The workflow handles business logic.

### Common Mistakes

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| Business logic in `main.py` | Entry points are for wiring, not logic | Move logic to `domain/workflows/` |
| Importing adapters in a workflow | Workflow becomes coupled to specific infrastructure | Use ports only — let the entry point wire adapters |
| Wiring adapters in a workflow | Workflow becomes untestable (can't swap adapters) | Wire in the entry point, pass via constructor |
| Putting workflow in `adapters/` | Business logic shouldn't live with infrastructure | Move to `domain/workflows/` |
| Putting entry point in `domain/` | Domain must not know about adapters or config | Move to root-level file |

### Decision Rule

```
Am I writing code that does a business thing?
│
├─ Does it orchestrate pure functions + ports to achieve a goal?
│  └─ YES → It's a WORKFLOW. Put it in domain/workflows/.
│     Examples: authenticate_user, create_document, process_payment, calculate_tax
│
├─ Does it read config, create adapters, wire them, start the app?
│  └─ YES → It's an ENTRY POINT. Put it at root level.
│     Examples: main.py, cli.py, api.py, worker.py, migrate.py
│
├─ Does it handle HTTP/CLI/IPC requests and call a workflow?
│  └─ YES → It's a DRIVING ADAPTER. Put it in adapters/<driving>/.
│     Examples: adapters/fastapi/routes.py, adapters/cli/handlers.py
│
└─ Does it implement a port (DB, API, file, clock)?
   └─ YES → It's a DRIVEN ADAPTER. Put it in adapters/<backend>/.
      Examples: adapters/postgres/user_repo.py, adapters/stripe/gateway.py
```

## Transferable Ports and Adapters

Every port and adapter must be **copy-pasteable** into another project with zero modifications. If you can't copy a file and have it work in a new project, it's not portable — fix it.

### What Makes a Port Transferable

A port defines a contract using only domain primitives and standard vocabulary — never app-specific types.

```python
# NOT transferable — uses app-specific type
class OrderRepository(Protocol):
    def save(self, order: Order) -> None: ...  # Order is app-specific

# Transferable — uses generic type parameter
class Repository[T, IdT](Protocol):
    def save(self, entity: T) -> None: ...
    def find_by_id(self, entity_id: IdT) -> T | None: ...

# Domain-specific alias — optional, for readability
OrderRepository = Repository[Order, str]
```

**Port transferability rules:**
- Accept and return only domain primitives, generics, or standard port vocabulary types
- Never import app models — use `T` (generics) instead
- Never import adapters, drivers, or third-party libraries
- The port lives in `domain/ports/` and depends on nothing outside `domain/`

### What Makes an Adapter Transferable

An adapter depends on **three things only**: standard ports, its driver, and injected config/mappers. Nothing else.

```python
# adapters/postgres/postgres_repository.py — PORTABLE
from domain.ports.repository import Repository  # standard port only
import psycopg  # driver only

class PostgresRepository(Repository[T, IdT]):
    def __init__(self, connection, config: PostgresConfig,
                 to_row, from_row, id_of):
        self._conn = connection
        self._config = config      # frozen struct — injected
        self._to_row = to_row      # pure mapper — injected
        self._from_row = from_row  # pure mapper — injected
        self._id_of = id_of

    def save(self, entity: T) -> None:
        self._conn.execute(self._config.upsert_sql, self._to_row(entity))

    def find_by_id(self, entity_id: IdT) -> T | None:
        row = self._conn.execute(self._config.select_sql, (entity_id,)).fetchone()
        return self._from_row(row) if row else None
```

```python
# NOT portable — imports app model, reads env, hardcodes table name
class BadRepository:
    def __init__(self):
        from domain.models.order import Order  # app import
        self.table = "orders"                    # hardcoded
        self.dsn = os.getenv("DATABASE_URL")    # env read
```

**Adapter transferability checklist:**
- [ ] Imports only: standard library, driver, standard ports — zero app imports
- [ ] Config injected via constructor — never reads env vars directly
- [ ] Mappers (`to_row`/`from_row`) injected — never imports domain models
- [ ] Translates vendor errors to port errors — never leaks SDK exceptions
- [ ] Passes the port's contract test — in the original project AND the target project
- [ ] No module-level connections or global state
- [ ] Header file with: backend, port(s) implemented, driver, config fields

### Copy-Paste Test

Before accepting a port or adapter into a collection, run this test:

```
1. Copy the file(s) to a blank project
2. Add the required driver dependency
3. Does it compile/run?
4. Does it pass the port's contract test?
```

If any step fails, fix the port or adapter — not the target project.

## Pure Functions and Pure Orchestrators

Every function in the system is one of two kinds. Knowing which kind determines how you test it.

### Pure Functions

A pure function takes input, returns output, and does nothing else. No side effects, no port calls, no I/O.

```python
# Pure function — trivial to test
def calculate_total(cart: Cart, tax_rate: float) -> float:
    return sum(item.price * item.quantity for item in cart.items) * (1 + tax_rate)

def validate_email(email: str) -> bool:
    return bool(re.match(r'^[^@]+@[^@]+\.[^@]+$', email))

def format_currency(amount: float, currency: str) -> str:
    return f"{currency} {amount:,.2f}"
```

**How to test pure functions:**
```python
def test_calculate_total():
    cart = Cart(items=[CartItem(price=10, quantity=2), CartItem(price=5, quantity=3)])
    assert calculate_total(cart, tax_rate=0.1) == 38.5  # (20 + 15) * 1.1

# No mocks. No setup. No database. Just input → output.
```

### Pure Orchestrators

A pure orchestrator coordinates pure functions and port calls. It has no business logic inline — it delegates to pure functions for logic and to ports for I/O.

```python
# Pure orchestrator — testable by faking ports
def create_document(
    content: str,           # input
    repo: DocumentRepository,  # port (faked in tests)
    logger: LoggerPort,     # port (faked in tests)
    time: TimePort,         # port (faked in tests)
) -> Document:
    # 1. Validate (pure function call)
    validate_content(content)

    # 2. Create model (pure function call)
    doc = Document.create(content=content)

    # 3. Persist (port call)
    repo.save(doc)

    # 4. Log (port call)
    logger.info(f"Created {doc.id}")

    return doc
```

**How to test pure orchestrators:**
```python
def test_create_document():
    repo = FakeDocumentRepo()    # fake port
    logger = FakeLogger()        # fake port
    time = FakeTime()            # fake port

    doc = create_document("Hello", repo, logger, time)

    assert doc.content == "Hello"
    assert repo.saved == [doc]        # verify port was called
    assert logger.last_message contains "Created"  # verify port was called
```

### The God Function Anti-Pattern

A god function does everything: validation, logic, I/O, logging, error handling — all in one. It's hard to test because you need to mock everything, and hard to change because every change risks breaking unrelated behavior.

```python
# GOD FUNCTION — hard to test, hard to change
def process_order(order_data: dict):
    # validation mixed with logic mixed with I/O
    if not order_data.get("items"):
        raise ValueError("no items")                    # validation
    total = sum(i["price"] * i["qty"] for i in order_data["items"])  # logic
    if total > 1000:
        discount = total * 0.1                          # logic
        total -= discount                               # logic
    db = get_db_connection()                            # I/O
    db.execute("INSERT INTO orders ...", total)         # I/O
    send_confirmation_email(order_data["email"])        # I/O
    logger.info(f"Order processed: {total}")            # I/O
    return {"total": total, "status": "ok"}
```

```python
# SPLIT — pure functions + pure orchestrator

# Pure functions — trivial to test
def validate_order_items(items: list[dict]) -> None:
    if not items:
        raise EmptyOrderError()

def calculate_order_total(items: list[dict]) -> float:
    return sum(i["price"] * i["qty"] for i in items)

def apply_discount(total: float) -> float:
    if total > 1000:
        return total * 0.9
    return total

# Pure orchestrator — testable by faking ports
def process_order(
    order_data: dict,
    repo: OrderRepository,
    notifier: NotifierPort,
    logger: LoggerPort,
) -> Order:
    validate_order_items(order_data["items"])
    total = calculate_order_total(order_data["items"])
    total = apply_discount(total)

    order = Order.create(items=order_data["items"], total=total)
    repo.save(order)
    notifier.send(order_data["email"], f"Order {order.id} confirmed")
    logger.info("order_processed", order_id=order.id, total=total)

    return order
```

### When to Split a Function

| Symptom | Action |
|---------|--------|
| Function does validation + logic + I/O | Extract validation and logic into pure functions |
| Function is longer than ~30 lines | Extract logical blocks into named pure functions |
| Function needs 3+ mocks to test | It's doing too much — split the I/O from the logic |
| Function has an `if` that branches on I/O result | Extract the I/O into a port, keep the branch logic pure |
| Same logic appears in two workflows | Extract into a shared pure function in `domain/` |

### Decision Rule

```
Am I writing a new function?
│
├─ Does it do ONLY pure logic (math, validation, transform)?
│  └─ YES → Pure function. Test: call it, check the return value.
│
├─ Does it coordinate pure functions + port calls, with no inline logic?
│  └─ YES → Pure orchestrator. Test: fake the ports, verify calls.
│
├─ Does it do BOTH logic AND side effects?
│  └─ SPLIT IT.
│     Extract the logic into a pure function.
│     Keep the orchestration (port calls) in the orchestrator.
│
└─ Is it too large (>30 lines)?
   └─ EXTRACT. Pull named blocks into pure functions.
      The orchestrator becomes a thin coordinator.
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
