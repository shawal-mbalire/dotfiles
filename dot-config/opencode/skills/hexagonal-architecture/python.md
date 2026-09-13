# Python — Hexagonal Architecture Guide

Python-specific setup, tooling, code examples, and testing patterns for hexagonal architecture. See [SKILL.md](./SKILL.md) for core architecture principles.

## Project Setup

### Initialize with uv

```bash
mkdir my-project && cd my-project
uv init --no-package

mkdir -p domain/models domain/errors domain/ports domain/workflows
mkdir -p infra adapters tests/unit tests/integration tests/e2e tests/fixtures/fakes
touch domain/__init__.py domain/models/__init__.py domain/errors/__init__.py
touch domain/ports/__init__.py domain/workflows/__init__.py
touch infra/__init__.py adapters/__init__.py tests/__init__.py
touch main.py  # Rename to api.py, worker.py, engine.py, cli.py based on project role
```

### pyproject.toml

```toml
[project]
name = "my-project"
version = "0.1.0"
description = "Hexagonal architecture project"
requires-python = ">=3.11"
dependencies = [
    "rich>=13.0",
]

[tool.uv]
dev-dependencies = [
    "pytest>=8.0",
    "pytest-cov>=5.0",
    "ruff>=0.5",
    "pyright>=1.1",
]

[tool.ruff]
target-version = "py311"
line-length = 88

[tool.ruff.lint]
select = ["E", "F", "I", "N", "UP", "B", "A", "C4", "SIM", "TCH"]

[tool.pyright]
typeCheckingMode = "strict"
pythonVersion = "3.11"

[tool.pytest.ini_options]
testpaths = ["tests"]
```

### Justfile

```just
# justfile — a light command index; all logic lives in cli.py / entry files
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
logs *args:
    uv run python cli.py logs {{args}}

# Debug & DX
doctor:
    uv run python cli.py doctor
seed:
    uv run python cli.py seed
replay id:
    uv run python cli.py replay {{id}}
debug:
    uv run python cli.py debug

# Local-first backing services (only when using the DuckDB hub)
hub:
    uv run python -m adapters.duckdb.hub
insights:
    uv run python cli.py insights
db-prune:
    uv run python -m adapters.duckdb.maintenance
db-size:
    uv run python cli.py db-size
db-shell:
    uv run python cli.py db-shell

# Test
test:
    uv run pytest tests/ -v
test-unit:
    uv run pytest tests/unit/ -v
test-contract:
    uv run pytest tests/integration -k contract -v
test-integration:
    uv run pytest tests/integration/ -v
test-fault:
    uv run pytest tests -k fault -v
test-property:
    uv run pytest tests/property -v
test-e2e:
    uv run pytest tests/e2e/ -v
test-coverage:
    uv run pytest tests/ --cov=domain --cov=infra --cov=adapters --cov-report=term-missing

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
    uv run python cli.py clean

# Dependencies
install:
    uv sync
add *args:
    uv add {{args}}
dev-add *args:
    uv add --dev {{args}}
update:
    uv lock --upgrade && uv sync

# Combined gates
check: lint typecheck adapters-check errors-check test
verify: check test-contract test-fault test-e2e
verify-hard: verify sanitizers
verify-plus: verify test-property mutation
```

### Platform-Specific Justfiles

**FastAPI/Web:**

```just
# api/justfile
set dotenv-load

run:
    uv run uvicorn main:app --reload --host 0.0.0.0 --port 8000

logs:
    uv run uvicorn main:app --host 0.0.0.0 --port 8000 --log-level debug

test:
    uv run pytest tests/ -v

test-watch:
    uv run pytest tests/ -v --tb=short -q

test-coverage:
    uv run pytest tests/ --cov=domain --cov=infra --cov=adapters --cov-report=term-missing --cov-report=html

lint:
    uv run ruff check .

format:
    uv run ruff format .

typecheck:
    uv run pyright

migrate:
    uv run alembic upgrade head

migration message:
    uv run alembic revision --autogenerate -m "{{message}}"

docs:
    open http://localhost:8000/docs
```

**Worker/Background Jobs:**

```just
# worker/justfile
set dotenv-load

run:
    uv run watchfiles 'uv run python worker.py' .

logs:
    uv run python worker.py --verbose

test:
    uv run pytest tests/ -v

lint:
    uv run ruff check .

format:
    uv run ruff format .
```

**Embedded/MicroPython:**

```just
# embedded/justfile
set dotenv-load

PORT := env_var_or_default("PORT", "/dev/tty.usbmodem*")
BAUD := env_var_or_default("BAUD", "115200")

logs:
    @echo "Connecting to serial port..."
    @echo "Press Ctrl+A then Ctrl+X to exit"
    picocom -b {{BAUD}} $(ls {{PORT}} 2>/dev/null | head -1)

logs-miniterm:
    python -m serial.tools.miniterm $(ls {{PORT}} 2>/dev/null | head -1) {{BAUD}}

logs-screen:
    screen $(ls {{PORT}} 2>/dev/null | head -1) {{BAUD}}

upload file:
    ampy --port $(ls {{PORT}} 2>/dev/null | head -1) put {{file}}

upload-project:
    @for file in *.py; do \
        echo "Uploading $$file..."; \
        ampy --port $(ls {{PORT}} 2>/dev/null | head -1) put $$file; \
    done

run file:
    ampy --port $(ls {{PORT}} 2>/dev/null | head -1) run {{file}}

clear:
    ampy --port $(ls {{PORT}} 2>/dev/null | head -1) remove main.py 2>/dev/null || true
    ampy --port $(ls {{PORT}} 2>/dev/null | head -1) remove boot.py 2>/dev/null || true

test:
    uv run pytest tests/ -v

lint:
    uv run ruff check .

format:
    uv run ruff format .
```

## Code Example (Document Management)

```python
# domain/models/document.py
from dataclasses import dataclass
from enum import StrEnum

class DocumentStatus(StrEnum):
    DRAFT = "draft"
    PUBLISHED = "published"
    ARCHIVED = "archived"

@dataclass(frozen=True)
class Document:
    id: str
    content: str
    status: DocumentStatus = DocumentStatus.DRAFT

    @classmethod
    def create(cls, content: str) -> "Document":
        import uuid
        return cls(
            id=str(uuid.uuid4()),
            content=content,
            status=DocumentStatus.DRAFT,
        )

# domain/errors/app_error.py (uniform diagnostic error — every layer uses this shape)
from dataclasses import dataclass, field

@dataclass(frozen=True)
class AppError(Exception):
    code: str                       # registry-backed, e.g. "DOC-001"
    message: str
    context: dict = field(default_factory=dict)   # ids, operation, inputs (redacted)
    cause: Exception | None = None  # original error — never discarded
    origin: str = ""                # layer + module.function:line, set at the boundary
    correlation_id: str = ""
    retryable: bool = False
    remediation: str = ""

# domain/errors/document_errors.py
from domain.errors.app_error import AppError

class EmptyContentError(AppError):
    def __init__(self, message: str = "Document content cannot be empty", **kw):
        super().__init__(code="DOC-001", message=message,
                         remediation="Provide non-empty content", **kw)

class DocumentNotFoundError(AppError):
    def __init__(self, document_id: str, **kw):
        super().__init__(code="DOC-002", message="Document not found",
                         context={"document_id": document_id}, **kw)

# domain/ports/repository.py
from typing import Protocol

class DocumentRepository(Protocol):
    def save(self, document: Document) -> None: ...
    def find_by_id(self, document_id: str) -> Document | None: ...

# domain/ports/logger.py
from typing import Protocol

class LoggerPort(Protocol):
    def info(self, message: str, **fields) -> None: ...
    def error(self, message: str, **fields) -> None: ...

# domain/ports/time_port.py
from typing import Protocol

class TimePort(Protocol):
    def now_ms(self) -> int: ...
    def elapsed_ms(self, start_ms: int) -> int: ...
    def sleep_ms(self, ms: int) -> None: ...

# domain/ports/lifetime_port.py
from typing import Protocol, Callable

class LifetimePort(Protocol):
    def register_cleanup(self, handler: Callable[[], None]) -> None: ...
    def on_exit(self, handler: Callable[[str], None]) -> None: ...
    def get_exit_reason(self) -> str: ...
    def is_shutting_down(self) -> bool: ...

# domain/workflows/create_document.py
from domain.models.document import Document
from domain.ports.repository import DocumentRepository
from domain.ports.logger import LoggerPort
from domain.ports.time_port import TimePort
from domain.errors.document_errors import EmptyContentError

def create_document(
    content: str,
    document_repository: DocumentRepository,
    logger: LoggerPort,
    time: TimePort,
) -> Document:
    start = time.now_ms()
    if not content.strip():
        raise EmptyContentError()

    document = Document.create(content=content)
    document_repository.save(document)
    elapsed = time.elapsed_ms(start)
    logger.info(f"Document created with identifier {document.id} in {elapsed}ms")
    return document

# infra/config.py
import os
from dataclasses import dataclass

@dataclass(frozen=True)
class FirestoreConfiguration:
    project_id: str = ""
    collection_name: str = "documents"

    @classmethod
    def from_environment(cls) -> "FirestoreConfiguration":
        return cls(
            project_id=os.getenv("GCP_PROJECT_ID", ""),
            collection_name=os.getenv("FIRESTORE_COLLECTION", "documents"),
        )

@dataclass(frozen=True)
class LoggingConfiguration:
    log_level: str = "INFO"

    @classmethod
    def from_environment(cls) -> "LoggingConfiguration":
        return cls(
            log_level=os.getenv("LOG_LEVEL", "INFO"),
        )

# adapters/console_logger.py
import logging
from domain.ports.logger import LoggerPort

class ConsoleLogger(LoggerPort):
    def __init__(self) -> None:
        self.logger = logging.getLogger(__name__)
        # Every line is timestamped so delays are visible in the stream
        handler = logging.StreamHandler()
        handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
        self.logger.addHandler(handler)
        self.logger.propagate = False

    def info(self, message: str) -> None:
        self.logger.info(message)

    def error(self, message: str) -> None:
        self.logger.error(message)

# adapters/rich_logger.py
import logging
from rich.console import Console
from rich.logging import RichHandler
from domain.ports.logger import LoggerPort

class RichLogger(LoggerPort):
    def __init__(self, service_name: str, log_level: str = "INFO") -> None:
        self._console = Console()
        self._logger = logging.getLogger(service_name)
        self._logger.setLevel(getattr(logging, log_level.upper()))
        handler = RichHandler(
            console=self._console,
            show_path=False,
            show_time=True,
            rich_tracebacks=True,
        )
        handler.setFormatter(logging.Formatter("%(message)s"))
        self._logger.addHandler(handler)

    def info(self, message: str) -> None:
        self._logger.info(message)

    def error(self, message: str) -> None:
        self._logger.error(message)

# adapters/system_time.py
import time
from domain.ports.time_port import TimePort

class SystemTimeAdapter(TimePort):
    def now_ms(self) -> int:
        return int(time.time() * 1000)

    def elapsed_ms(self, start_ms: int) -> int:
        return self.now_ms() - start_ms

# adapters/mock_time.py (for testing)
from domain.ports.time_port import TimePort

class MockTimeAdapter(TimePort):
    def __init__(self) -> None:
        self._current_ms = 0

    def now_ms(self) -> int:
        return self._current_ms

    def elapsed_ms(self, start_ms: int) -> int:
        return self._current_ms - start_ms

    def advance_ms(self, ms: int) -> None:
        self._current_ms += ms

# adapters/signal_lifetime.py (System-level exit detection)
import signal
from typing import Callable
from domain.ports.lifetime_port import LifetimePort

class SignalLifetimeAdapter(LifetimePort):
    def __init__(self) -> None:
        self._cleanup_handlers: list[Callable[[], None]] = []
        self._exit_handlers: list[Callable[[str], None]] = []
        self._exit_reason = "normal"
        self._shutting_down = False

    def register_cleanup(self, handler: Callable[[], None]) -> None:
        self._cleanup_handlers.append(handler)

    def on_exit(self, handler: Callable[[str], None]) -> None:
        self._exit_handlers.append(handler)

    def get_exit_reason(self) -> str:
        return self._exit_reason

    def is_shutting_down(self) -> bool:
        return self._shutting_down

    def _handle_signal(self, signum: int, frame) -> None:
        self._shutting_down = True
        if signum == signal.SIGTERM:
            self._exit_reason = "shutdown"
        elif signum == signal.SIGINT:
            self._exit_reason = "user_exit"
        else:
            self._exit_reason = "crash"

        for handler in self._exit_handlers:
            handler(self._exit_reason)
        for handler in self._cleanup_handlers:
            handler()

    def install(self) -> None:
        signal.signal(signal.SIGTERM, self._handle_signal)
        signal.signal(signal.SIGINT, self._handle_signal)

# adapters/mock_lifetime.py (for testing)
from domain.ports.lifetime_port import LifetimePort
from typing import Callable

class MockLifetimeAdapter(LifetimePort):
    def __init__(self) -> None:
        self._cleanup_handlers: list[Callable[[], None]] = []
        self._exit_handlers: list[Callable[[str], None]] = []
        self._exit_reason = "normal"
        self._shutting_down = False
        self.cleanup_count = 0

    def register_cleanup(self, handler: Callable[[], None]) -> None:
        self._cleanup_handlers.append(handler)

    def on_exit(self, handler: Callable[[str], None]) -> None:
        self._exit_handlers.append(handler)

    def get_exit_reason(self) -> str:
        return self._exit_reason

    def is_shutting_down(self) -> bool:
        return self._shutting_down

    def trigger_exit(self, reason: str) -> None:
        """Simulate exit for testing."""
        self._shutting_down = True
        self._exit_reason = reason
        for handler in self._exit_handlers:
            handler(reason)
        for handler in self._cleanup_handlers:
            handler()
            self.cleanup_count += 1

# adapters/firestore_mappings.py (Pure helpers — no I/O, trivial to test)
from domain.models.document import Document, DocumentStatus

def document_to_firestore_dict(document: Document) -> dict:
    """Convert domain model to Firestore document. Pure function."""
    return {
        "content": document.content,
        "status": document.status.value,
    }

def firestore_dict_to_document(doc_id: str, data: dict) -> Document:
    """Convert Firestore document to domain model. Pure function."""
    return Document(
        id=doc_id,
        content=data["content"],
        status=DocumentStatus(data["status"]),
    )

# adapters/firestore_adapter.py (Thin I/O — calls pure helpers)
from google.cloud import firestore
from domain.ports.repository import DocumentRepository
from domain.models.document import Document
from adapters.firestore_mappings import document_to_firestore_dict, firestore_dict_to_document

class FirestoreDocumentAdapter(DocumentRepository):
    def __init__(self, project_id: str, collection_name: str) -> None:
        self.firestore_client = firestore.Client(project=project_id)
        self.collection = self.firestore_client.collection(collection_name)

    def save(self, document: Document) -> None:
        self.collection.document(document.id).set(document_to_firestore_dict(document))

    def find_by_id(self, document_id: str) -> Document | None:
        doc_ref = self.collection.document(document_id).get()
        if doc_ref.exists:
            return firestore_dict_to_document(document_id, doc_ref.to_dict())
        return None

# tests/unit/test_firestore_mappings.py (Test pure helpers — no mocks needed)
from adapters.firestore_mappings import document_to_firestore_dict, firestore_dict_to_document
from domain.models.document import Document, DocumentStatus

def test_document_to_firestore_dict():
    doc = Document(id="123", content="Hello", status=DocumentStatus.DRAFT)
    result = document_to_firestore_dict(doc)
    assert result == {"content": "Hello", "status": "draft"}

def test_firestore_dict_to_document():
    data = {"content": "Hello", "status": "published"}
    result = firestore_dict_to_document("123", data)
    assert result.id == "123"
    assert result.content == "Hello"
    assert result.status == DocumentStatus.PUBLISHED

# No mocks, no Firestore emulator — just input → output

# wire_adapters.py (root — creates adapters, maps ports to implementations)
from adapters.firestore_adapter import FirestoreDocumentAdapter
from adapters.console_logger import ConsoleLogger
from adapters.system_time import SystemTimeAdapter
from infra.config import FirestoreConfiguration, LoggingConfiguration

def create_document_repository() -> FirestoreDocumentAdapter:
    config = FirestoreConfiguration.from_environment()
    return FirestoreDocumentAdapter(
        project_id=config.project_id,
        collection_name=config.collection_name,
    )

def create_logger() -> ConsoleLogger:
    return ConsoleLogger()

def create_time() -> SystemTimeAdapter:
    return SystemTimeAdapter()

# main.py (Orchestrator — thin, only wires and starts)
from wire_adapters import create_document_repository, create_logger, create_time
from domain.workflows.create_document import create_document

def main() -> None:
    # Wire adapters
    repo = create_document_repository()
    logger = create_logger()
    time = create_time()

    # Start driving adapter (e.g., FastAPI routes)
    @app.post("/documents/{document_id}")
    def api_create_document(document_id: str, request_body: dict) -> dict:
        document = create_document(
            content=request_body["content"],
            document_repository=repo,
            logger=logger,
            time=time,
        )
        return {
            "id": document.id,
            "content": document.content,
            "status": document.status.value,
        }
```

### Domain Constants Pattern (Python)

```python
# domain/constants.py
from dataclasses import dataclass

# Static constants: fixed business knowledge, never change per deployment
DEGREES_TO_RADIANS: float = 0.017453292519943295
MAX_COORDINATE_LAT: float = 90.0
MAX_COORDINATE_LNG: float = 180.0
INVALID_COORDINATE_SENTINEL: float = 0.0
EMPTY_CART_TOTAL: float = 0.0

# Configurable constants: injected from infra/config.py
@dataclass(frozen=True)
class DomainConstants:
    max_retry_count: int
    request_timeout_seconds: int
    max_content_length: int
    relay_pin: int

# domain/workflows/track_location.py
from domain.constants import DomainConstants, INVALID_COORDINATE_SENTINEL

class TrackLocationWorkflow:
    def __init__(self, location_port: LocationPort, constants: DomainConstants):
        self._location_port = location_port
        self._constants = constants

    async def execute(self) -> Coordinates:
        coords = await self._location_port.get_current()
        if (coords.lat == INVALID_COORDINATE_SENTINEL
                and coords.lng == INVALID_COORDINATE_SENTINEL):
            raise InvalidCoordinatesError()
        if self._constants.max_content_length < 0:
            raise ValueError("Invalid configuration")
        return coords

# infra/config.py
import os
from domain.constants import DomainConstants

def load_domain_constants() -> DomainConstants:
    return DomainConstants(
        max_retry_count=int(os.getenv("MAX_RETRY_COUNT", "3")),
        request_timeout_seconds=int(os.getenv("REQUEST_TIMEOUT_SECONDS", "30")),
        max_content_length=int(os.getenv("MAX_CONTENT_LENGTH", "10000")),
        relay_pin=int(os.getenv("RELAY_PIN", "14")),
    )
```

### SQL Repository Adapter (Python)

Persistence goes through a `*Repository` port implemented by a SQL adapter. There is no ORM — the adapter owns its SQL and its row → domain mapping. Write it against the **generic** `Repository[T, IdT]` port with injected mappers so the file copies to any project.

```python
# domain/models/document.py (pure — no DB imports)
from dataclasses import dataclass
from enum import Enum

class DocumentStatus(str, Enum):
    DRAFT = "draft"
    PUBLISHED = "published"

@dataclass(frozen=True)
class Document:
    id: str
    content: str
    status: DocumentStatus = DocumentStatus.DRAFT

# domain/ports/repository.py (standard, generic)
from typing import Protocol, TypeVar

IdT = TypeVar("IdT")
T = TypeVar("T")

class Repository(Protocol[T, IdT]):
    def save(self, entity: T) -> None: ...
    def find_by_id(self, entity_id: IdT) -> T | None: ...
    def find_all(self) -> list[T]: ...
    def delete(self, entity_id: IdT) -> None: ...

# Domain-specific alias — optional, reads better at call sites
DocumentRepository = Repository[Document, str]

# adapters/sql/sql_repository.py (PORTABLE — copy to any project, unmodified)
# backend: any DB-API driver (sqlite3, duckdb, psycopg)
# implements: Repository[T, IdT]
# config: SqlConfig(table, save_sql, select_sql, select_all_sql, delete_sql)
# deps: the driver only
from dataclasses import dataclass
from typing import Callable, Generic, TypeVar

from domain.errors import StorageUnavailableError

IdT = TypeVar("IdT")
T = TypeVar("T")

@dataclass(frozen=True)
class SqlConfig:
    table: str
    save_sql: str
    select_sql: str
    select_all_sql: str
    delete_sql: str

class SqlRepository(Generic[T, IdT]):
    def __init__(self, connection, config: SqlConfig,
                 to_params: Callable[[T], tuple],
                 from_row: Callable[[tuple], T]) -> None:
        self._connection = connection      # injected — never created here
        self._config = config              # frozen config, no env reads
        self._to_params = to_params        # pure mapper
        self._from_row = from_row          # pure mapper

    def save(self, entity: T) -> None:
        try:
            self._connection.execute(self._config.save_sql, self._to_params(entity))
            self._connection.commit()
        except Exception as e:             # translate vendor errors to port errors
            raise StorageUnavailableError(str(e)) from e

    def find_by_id(self, entity_id: IdT) -> T | None:
        row = self._connection.execute(self._config.select_sql, (entity_id,)).fetchone()
        return self._from_row(row) if row else None

    def find_all(self) -> list[T]:
        return [self._from_row(r) for r in self._connection.execute(self._config.select_all_sql)]

    def delete(self, entity_id: IdT) -> None:
        self._connection.execute(self._config.delete_sql, (entity_id,))
        self._connection.commit()
```

Only the composition root knows the aggregate — the adapter never names `Document`:

```python
# wire_adapters.py (root) — bind the adapter to Document here, not inside the adapter
def make_document_repository(connection) -> Repository[Document, str]:
    return SqlRepository(
        connection,
        config=SqlConfig(
            table="documents",
            save_sql=("INSERT INTO documents (id, content, status) VALUES (?, ?, ?) "
                      "ON CONFLICT(id) DO UPDATE SET content = excluded.content, "
                      "status = excluded.status"),
            select_sql="SELECT id, content, status FROM documents WHERE id = ?",
            select_all_sql="SELECT id, content, status FROM documents",
            delete_sql="DELETE FROM documents WHERE id = ?",
        ),
        to_params=lambda d: (d.id, d.content, d.status.value),
        from_row=lambda r: Document(id=r[0], content=r[1], status=DocumentStatus(r[2])),
    )
```

The same `sql_repository.py` drops into another project unchanged — only the `SqlConfig` and mappers change. The connection is opened by the composition root (SQLite/DuckDB in dev, Postgres in prod) and closed via `lifetime.register_cleanup(connection.close)`.

Migrations are `.sql` files (or Alembic) applied by a root-level admin entry point, not at app startup:

```python
# migrate.py (root)
import sqlite3
from pathlib import Path

from infra.config import DatabaseConfiguration

def main() -> None:
    connection = sqlite3.connect(DatabaseConfiguration.from_environment().url)
    for migration in sorted(Path("adapters/sql/migrations").glob("*.sql")):
        connection.executescript(migration.read_text())
    connection.commit()
```

The adapter proves itself against the shared `Repository` contract suite — the same suite any copied-in adapter must pass:

```python
# tests/integration/test_sql_repository_contract.py
import sqlite3

import pytest

from adapters.sql.sql_repository import SqlConfig, SqlRepository
from domain.models.document import Document, DocumentStatus

# tests/integration/test_repository_contract.py holds the port suite and consumes this fixture
@pytest.fixture
def repository():
    connection = sqlite3.connect(":memory:")          # ephemeral backend
    connection.execute(
        "CREATE TABLE documents (id TEXT PRIMARY KEY, content TEXT NOT NULL, status TEXT NOT NULL)"
    )
    return SqlRepository(
        connection,
        config=SqlConfig(
            table="documents",
            save_sql=("INSERT INTO documents (id, content, status) VALUES (?, ?, ?) "
                      "ON CONFLICT(id) DO UPDATE SET content = excluded.content, "
                      "status = excluded.status"),
            select_sql="SELECT id, content, status FROM documents WHERE id = ?",
            select_all_sql="SELECT id, content, status FROM documents",
            delete_sql="DELETE FROM documents WHERE id = ?",
        ),
        to_params=lambda d: (d.id, d.content, d.status.value),
        from_row=lambda r: Document(id=r[0], content=r[1], status=DocumentStatus(r[2])),
    )
```

### Local-First Backing Services (DuckDB Hub, Python)

Dev defaults to one local DuckDB database for **logs, metrics, and events**, owned by a single hub process. Ports never change; only the composition root swaps DuckDB adapters for prod services.

```python
# domain/ports/metrics.py
from typing import Mapping, Protocol

class MetricsPort(Protocol):
    """Counters, gauges, and timings. Adapters stamp `ts` from TimePort on write."""
    def counter(self, name: str, value: float = 1.0, labels: Mapping[str, str] | None = None) -> None: ...
    def gauge(self, name: str, value: float, labels: Mapping[str, str] | None = None) -> None: ...
    def timing(self, name: str, duration_ms: float, labels: Mapping[str, str] | None = None) -> None: ...

# domain/ports/event_bus.py
from typing import Any, Callable, Protocol

class EventPublisherPort(Protocol):
    def publish(self, topic: str, payload: dict[str, Any]) -> None: ...

class EventConsumerPort(Protocol):
    def subscribe(self, topic: str, consumer: str, handler: Callable[[dict[str, Any]], None]) -> None: ...

# infra/config.py (add to the existing config module)
import os
from dataclasses import dataclass

@dataclass(frozen=True)
class DuckDbConfiguration:
    mode: str = "hub"                           # "hub" (multi-process) or "inprocess" (single process)
    database_path: str = "build/dev.duckdb"     # build/ is untracked and recreatable
    socket_path: str = "build/dev.duckdb.sock"
    poll_interval_ms: int = 250
    batch_size: int = 100

    @classmethod
    def from_environment(cls) -> "DuckDbConfiguration":
        return cls(
            mode=os.getenv("DUCKDB_MODE", "hub"),
            database_path=os.getenv("DUCKDB_PATH", "build/dev.duckdb"),
            socket_path=os.getenv("DUCKDB_SOCKET", "build/dev.duckdb.sock"),
            poll_interval_ms=int(os.getenv("DUCKDB_POLL_INTERVAL_MS", "250")),
            batch_size=int(os.getenv("DUCKDB_BATCH_SIZE", "100")),
        )
```

```sql
-- adapters/duckdb/schema.sql — applied once by the hub at startup
CREATE SEQUENCE IF NOT EXISTS event_seq;

CREATE TABLE IF NOT EXISTS logs (
    ts          TIMESTAMP NOT NULL,
    level       TEXT      NOT NULL,
    service     TEXT      NOT NULL,
    request_id  TEXT,
    message     TEXT      NOT NULL,
    fields      JSON
);

CREATE TABLE IF NOT EXISTS metrics (
    ts     TIMESTAMP NOT NULL,
    name   TEXT      NOT NULL,
    value  DOUBLE    NOT NULL,
    labels JSON
);

CREATE TABLE IF NOT EXISTS events (
    seq      BIGINT    NOT NULL,   -- monotonic cursor
    ts       TIMESTAMP NOT NULL,
    topic    TEXT      NOT NULL,
    payload  JSON      NOT NULL
);

CREATE TABLE IF NOT EXISTS event_cursors (
    topic    TEXT   NOT NULL,
    consumer TEXT   NOT NULL,
    last_seq BIGINT NOT NULL DEFAULT 0,
    PRIMARY KEY (topic, consumer)
);

CREATE OR REPLACE VIEW slow_requests AS
SELECT service, request_id,
       date_diff('millisecond', min(ts), max(ts)) AS duration_ms
FROM logs
WHERE level = 'INFO'
GROUP BY service, request_id;
```

```python
# adapters/duckdb/duckdb_mappings.py (Pure — no I/O, trivial to test)
import json
from datetime import datetime, timezone

def _ts(ms: int) -> datetime:
    return datetime.fromtimestamp(ms / 1000.0, tz=timezone.utc)

def log_params(row: dict) -> tuple:
    return (_ts(row["ts"]), row["level"], row["service"],
            row.get("request_id"), row["message"], json.dumps(row.get("fields", {})))

def metric_params(row: dict) -> tuple:
    return (_ts(row["ts"]), row["name"], row["value"], json.dumps(row.get("labels", {})))

def event_params(row: dict) -> tuple:
    return (_ts(row["ts"]), row["topic"], json.dumps(row["payload"]))

def event_payload(row: tuple) -> dict:
    seq, _ts_value, topic, payload = row
    return {"seq": seq, "topic": topic, "payload": json.loads(payload)}

# adapters/duckdb/duckdb_connection.py (Thin I/O — client to the single-writer hub)
import socket
from typing import Any
from domain.errors import StorageError
from adapters.duckdb.hub_protocol import decode, encode

class HubConnection:
    def __init__(self, socket_path: str, timeout_seconds: float = 2.0) -> None:
        self._socket_path = socket_path
        self._timeout = timeout_seconds
        self._sock: socket.socket | None = None

    def connect(self) -> None:
        self._sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self._sock.settimeout(self._timeout)
        self._sock.connect(self._socket_path)

    def request(self, payload: dict[str, Any]) -> dict[str, Any]:
        if self._sock is None:
            raise StorageError("HubConnection used before connect()")
        self._sock.sendall(encode(payload))
        line = b""
        while not line.endswith(b"\n"):
            chunk = self._sock.recv(65536)
            if not chunk:
                raise StorageError("DuckDB hub closed the connection")
            line += chunk
        return decode(line)

    def close(self) -> None:
        if self._sock is not None:
            self._sock.close()
            self._sock = None
```

```python
# adapters/duckdb/duckdb_logger.py (LoggerPort — buffered, flushed by LifetimePort)
from domain.ports.logger import LoggerPort
from domain.ports.time_port import TimePort
from adapters.duckdb.duckdb_connection import HubConnection

class DuckDbLoggerAdapter(LoggerPort):
    def __init__(self, connection: HubConnection, service: str,
                 time: TimePort, batch_size: int = 100) -> None:
        self._connection = connection
        self._service = service
        self._time = time
        self._batch_size = batch_size
        self._buffer: list[dict] = []

    def info(self, message: str, request_id: str | None = None, **fields) -> None:
        self._append("INFO", message, request_id, fields)

    def error(self, message: str, request_id: str | None = None, **fields) -> None:
        self._append("ERROR", message, request_id, fields)

    def _append(self, level: str, message: str, request_id: str | None, fields: dict) -> None:
        self._buffer.append({
            "ts": self._time.now_ms(), "level": level, "service": self._service,
            "request_id": request_id, "message": message, "fields": fields,
        })
        if len(self._buffer) >= self._batch_size:
            self.flush()

    def flush(self) -> None:
        if not self._buffer:
            return
        self._connection.request({"op": "append_logs", "rows": self._buffer})
        self._buffer.clear()

# adapters/duckdb/duckdb_metrics.py (MetricsPort)
from domain.ports.metrics import MetricsPort
from domain.ports.time_port import TimePort
from adapters.duckdb.duckdb_connection import HubConnection

class DuckDbMetricsAdapter(MetricsPort):
    def __init__(self, connection: HubConnection, time: TimePort, batch_size: int = 100) -> None:
        self._connection = connection
        self._time = time
        self._batch_size = batch_size
        self._buffer: list[dict] = []

    def counter(self, name: str, value: float = 1.0, labels=None) -> None:
        self._append(name, value, labels)

    def gauge(self, name: str, value: float, labels=None) -> None:
        self._append(name, value, labels)

    def timing(self, name: str, duration_ms: float, labels=None) -> None:
        self._append(name, duration_ms, labels)

    def _append(self, name: str, value: float, labels) -> None:
        self._buffer.append({
            "ts": self._time.now_ms(), "name": name,
            "value": float(value), "labels": labels or {},
        })
        if len(self._buffer) >= self._batch_size:
            self.flush()

    def flush(self) -> None:
        if not self._buffer:
            return
        self._connection.request({"op": "append_metrics", "rows": self._buffer})
        self._buffer.clear()

# adapters/duckdb/duckdb_event_bus.py (EventPublisherPort + EventConsumerPort)
from typing import Any, Callable
from domain.ports.event_bus import EventConsumerPort, EventPublisherPort
from domain.ports.lifetime_port import LifetimePort
from domain.ports.time_port import TimePort
from adapters.duckdb.duckdb_connection import HubConnection

class DuckDbEventBusAdapter(EventPublisherPort, EventConsumerPort):
    def __init__(self, connection: HubConnection, time: TimePort,
                 lifetime: LifetimePort, poll_interval_ms: int = 250,
                 batch_size: int = 100) -> None:
        self._connection = connection
        self._time = time
        self._lifetime = lifetime
        self._poll_interval_ms = poll_interval_ms
        self._batch_size = batch_size
        self._buffer: list[dict] = []

    def publish(self, topic: str, payload: dict[str, Any]) -> None:
        self._buffer.append({"ts": self._time.now_ms(), "topic": topic, "payload": payload})
        if len(self._buffer) >= self._batch_size:
            self.flush()

    def flush(self) -> None:
        if not self._buffer:
            return
        self._connection.request({"op": "append_events", "rows": self._buffer})
        self._buffer.clear()

    def subscribe(self, topic: str, consumer: str,
                  handler: Callable[[dict[str, Any]], None]) -> None:
        # Load the durable cursor from the hub; 0 on first run
        cursor = self._connection.request(
            {"op": "load_cursor", "topic": topic, "consumer": consumer}
        )["last_seq"]
        while not self._lifetime.is_shutting_down():
            response = self._connection.request(
                {"op": "poll_events", "topic": topic, "after_seq": cursor}
            )
            for row in response["rows"]:
                handler(row["payload"])          # at-least-once: make handlers idempotent
                cursor = row["seq"]
            if response["rows"]:
                # Persist progress so a crash replays at most the in-flight batch
                self._connection.request(
                    {"op": "save_cursor", "topic": topic,
                     "consumer": consumer, "last_seq": cursor}
                )
            self._time.sleep_ms(self._poll_interval_ms)   # deterministic under MockTimeAdapter
```

```python
# adapters/duckdb/hub_protocol.py (Pure — encode/decode hub wire format)
import json
from typing import Any

def encode(message: dict[str, Any]) -> bytes:
    return (json.dumps(message, separators=(",", ":")) + "\n").encode()

def decode(line: bytes) -> dict[str, Any]:
    return json.loads(line.decode())

# adapters/duckdb/hub.py (Composition root for the hub — the ONLY writer)
import socketserver
import threading
from pathlib import Path

import duckdb

from adapters.duckdb.duckdb_mappings import event_params, event_payload, log_params, metric_params
from adapters.duckdb.hub_protocol import decode, encode

_SCHEMA = Path(__file__).with_name("schema.sql").read_text()

class _Handler(socketserver.StreamRequestHandler):
    def handle(self) -> None:
        for raw in self.rfile:
            self.wfile.write(encode(self.server.dispatch(decode(raw))))

class DuckDbHub(socketserver.ThreadingUnixStreamServer):
    def __init__(self, socket_path: str, database_path: str) -> None:
        Path(socket_path).unlink(missing_ok=True)
        super().__init__(socket_path, _Handler)
        Path(database_path).parent.mkdir(parents=True, exist_ok=True)
        self._db = duckdb.connect(database_path)      # single read-write connection
        self._db.execute(_SCHEMA)
        self._lock = threading.Lock()                 # serialize handler threads

    def dispatch(self, request: dict) -> dict:
        op = request["op"]
        with self._lock:
            if op == "append_logs":
                self._db.executemany("INSERT INTO logs VALUES (?, ?, ?, ?, ?, ?)",
                                     [log_params(r) for r in request["rows"]])
                return {"ok": True}
            if op == "append_metrics":
                self._db.executemany("INSERT INTO metrics VALUES (?, ?, ?, ?)",
                                     [metric_params(r) for r in request["rows"]])
                return {"ok": True}
            if op == "append_events":
                self._db.executemany(
                    "INSERT INTO events VALUES (nextval('event_seq'), ?, ?, ?)",
                    [event_params(r) for r in request["rows"]],
                )
                return {"ok": True}
            if op == "poll_events":
                rows = self._db.execute(
                    "SELECT seq, ts, topic, payload FROM events "
                    "WHERE topic = ? AND seq > ? ORDER BY seq",
                    [request["topic"], request["after_seq"]],
                ).fetchall()
                return {"ok": True, "rows": [event_payload(r) for r in rows]}
            if op == "load_cursor":
                row = self._db.execute(
                    "SELECT last_seq FROM event_cursors WHERE topic = ? AND consumer = ?",
                    [request["topic"], request["consumer"]],
                ).fetchone()
                return {"ok": True, "last_seq": row[0] if row else 0}
            if op == "save_cursor":
                self._db.execute(
                    "INSERT INTO event_cursors (topic, consumer, last_seq) VALUES (?, ?, ?) "
                    "ON CONFLICT (topic, consumer) DO UPDATE SET last_seq = excluded.last_seq",
                    [request["topic"], request["consumer"], request["last_seq"]],
                )
                return {"ok": True}
            if op == "query":
                # Insights and admin tools read THROUGH the hub — never open the file
                result = self._db.execute(request["sql"], request.get("params", []))
                return {
                    "ok": True,
                    "columns": [c[0] for c in result.description],
                    "rows": result.fetchall(),
                }
            if op == "execute":
                # Admin-only writes (retention, rollups). Still the single writer.
                self._db.execute(request["sql"], request.get("params", []))
                return {"ok": True}
        raise ValueError(f"Unknown hub op: {op}")

def serve(socket_path: str, database_path: str) -> None:
    DuckDbHub(socket_path, database_path).serve_forever()

# main entry: python -m adapters.duckdb.hub
if __name__ == "__main__":
    from infra.config import DuckDbConfiguration
    config = DuckDbConfiguration.from_environment()
    serve(config.socket_path, config.database_path)
```

```python
# adapters/duckdb/insights.py (Driving adapter — read queries THROUGH the hub)
from dataclasses import dataclass

from adapters.duckdb.duckdb_connection import HubConnection

@dataclass(frozen=True)
class InsightsReport:
    errors_per_service: list[tuple]
    p95_latency_ms: list[tuple]
    throughput_per_minute: list[tuple]

def collect(connection: HubConnection) -> InsightsReport:
    def query(sql: str) -> list[tuple]:
        return connection.request({"op": "query", "sql": sql})["rows"]

    return InsightsReport(
        errors_per_service=query(
            "SELECT service, count(*) FROM logs WHERE level = 'ERROR' GROUP BY service ORDER BY 2 DESC"
        ),
        p95_latency_ms=query(
            "SELECT service, approx_quantile(duration_ms, 0.95) FROM slow_requests GROUP BY service"
        ),
        throughput_per_minute=query(
            "SELECT CAST(date_trunc('minute', ts) AS VARCHAR) AS minute, count(*) "
            "FROM logs GROUP BY 1 ORDER BY 1"
        ),
    )

if __name__ == "__main__":
    from infra.config import DuckDbConfiguration
    config = DuckDbConfiguration.from_environment()
    connection = HubConnection(config.socket_path)
    connection.connect()   # talks to the running hub — never opens the file directly
    report = collect(connection)
    print("Errors per service:", report.errors_per_service)
    print("p95 latency (ms):", report.p95_latency_ms)
```

```python
# adapters/duckdb/maintenance.py (Admin task — retention + rollups, via the hub)
from adapters.duckdb.duckdb_connection import HubConnection

def prune(connection: HubConnection, log_days: int, metric_days: int, event_days: int) -> None:
    """Apply retention. Writes go through the hub's `execute` op — single writer."""
    connection.request({"op": "execute", "sql": f"DELETE FROM logs WHERE ts < now() - INTERVAL '{log_days} days'"})
    connection.request({"op": "execute", "sql": f"DELETE FROM metrics WHERE ts < now() - INTERVAL '{metric_days} days'"})
    connection.request({"op": "execute", "sql": (
        f"DELETE FROM events WHERE ts < now() - INTERVAL '{event_days} days' "
        "AND seq <= (SELECT min(last_seq) FROM event_cursors)"
    )})
    connection.request({"op": "execute", "sql": "CHECKPOINT"})   # compact after deletes

def rollup_metrics(connection: HubConnection) -> None:
    """Materialize per-minute aggregates so insights never scan raw rows."""
    connection.request({"op": "execute", "sql": (
        "CREATE OR REPLACE TABLE metrics_1m AS "
        "SELECT date_trunc('minute', ts) AS minute, name, "
        "approx_quantile(value, 0.95) AS p95, count(*) AS n "
        "FROM metrics GROUP BY 1, 2"
    )})

if __name__ == "__main__":
    from infra.config import DuckDbConfiguration
    config = DuckDbConfiguration.from_environment()
    connection = HubConnection(config.socket_path)
    connection.connect()
    prune(connection, log_days=7, metric_days=30, event_days=7)
    rollup_metrics(connection)
```

```python
# wire_adapters.py (root; Dev vs prod — only this file changes)
from adapters.duckdb.duckdb_connection import HubConnection
from adapters.duckdb.duckdb_event_bus import DuckDbEventBusAdapter
from adapters.duckdb.duckdb_logger import DuckDbLoggerAdapter
from adapters.duckdb.duckdb_metrics import DuckDbMetricsAdapter

def create_backing_services(config, time, lifetime):
    if config.environment != "dev":
        # Sentry / Prometheus-Datadog / Kafka adapters — same ports
        return ProdBackingServices(...)

    if config.duckdb.mode == "inprocess":
        # Single-process dev: this process is the only writer, so skip the hub
        # and hand the adapters a direct in-process connection (same ops).
        connection = InProcessConnection(config.duckdb.database_path)
    else:
        # Multi-process dev: connect to the single-writer hub over its socket.
        connection = HubConnection(config.duckdb.socket_path)
        connection.connect()

    logger = DuckDbLoggerAdapter(connection, service=config.service_name,
                                 time=time, batch_size=config.duckdb.batch_size)
    metrics = DuckDbMetricsAdapter(connection, time=time, batch_size=config.duckdb.batch_size)
    bus = DuckDbEventBusAdapter(connection, time=time, lifetime=lifetime,
                                poll_interval_ms=config.duckdb.poll_interval_ms,
                                batch_size=config.duckdb.batch_size)

    # Flush buffered writes on ANY exit; never lose logs/metrics/events
    lifetime.register_cleanup(logger.flush)
    lifetime.register_cleanup(metrics.flush)
    lifetime.register_cleanup(bus.flush)
    lifetime.register_cleanup(connection.close)
    return DevBackingServices(logger=logger, metrics=metrics, events=bus)
```

```python
# tests/unit/test_duckdb_mappings.py (Pure helpers — no DuckDB, no mocks)
from adapters.duckdb.duckdb_mappings import event_payload, log_params

def test_log_params_serializes_fields():
    row = {"ts": 1000, "level": "INFO", "service": "api", "request_id": "r1",
           "message": "created", "fields": {"user": "u1"}}
    _ts, level, service, request_id, message, fields = log_params(row)
    assert (level, service, request_id, message) == ("INFO", "api", "r1", "created")
    assert fields == '{"user": "u1"}'

def test_event_payload_roundtrip():
    assert event_payload((7, None, "orders", '{"id": 1}')) == {
        "seq": 7, "topic": "orders", "payload": {"id": 1},
    }

# tests/integration/test_duckdb_hub.py (Real DuckDB + real socket)
import threading

from adapters.duckdb.duckdb_connection import HubConnection
from adapters.duckdb.hub import DuckDbHub

def test_hub_appends_polls_and_queries(tmp_path):
    socket_path = str(tmp_path / "hub.sock")
    database_path = str(tmp_path / "dev.duckdb")
    server = DuckDbHub(socket_path, database_path)
    threading.Thread(target=server.serve_forever, daemon=True).start()

    connection = HubConnection(socket_path)
    connection.connect()
    connection.request({"op": "append_logs", "rows": [{
        "ts": 1000, "level": "ERROR", "service": "api",
        "request_id": "r1", "message": "boom", "fields": {},
    }]})
    connection.request({"op": "append_events", "rows": [
        {"ts": 1000, "topic": "orders", "payload": {"id": 1}},
    ]})

    polled = connection.request({"op": "poll_events", "topic": "orders", "after_seq": 0})
    assert polled["rows"] == [{"seq": 1, "topic": "orders", "payload": {"id": 1}}]

    # Reads go through the hub too — no second process opens the file
    counts = connection.request({"op": "query", "sql": "SELECT count(*) FROM logs"})
    assert counts["rows"] == [[1]]

    server.shutdown()
```

### MicroPython Example

```python
# domain/ports/relay_port.py
from abc import ABC, abstractmethod

class RelayPort(ABC):
    @abstractmethod
    def turn_on(self) -> None: ...

    @abstractmethod
    def turn_off(self) -> None: ...

# domain/ports/logger_port.py
from abc import ABC, abstractmethod

class LoggerPort(ABC):
    @abstractmethod
    def info(self, message: str) -> None: ...

    @abstractmethod
    def error(self, message: str) -> None: ...

# domain/models/irrigation_state.py
class IrrigationState:
    def __init__(self):
        self.is_active = False

# domain/workflows/pump_controller.py
from domain.ports.relay_port import RelayPort
from domain.ports.logger_port import LoggerPort
from domain.models.irrigation_state import IrrigationState

class PumpController:
    def __init__(self, pump_relay: RelayPort, logger: LoggerPort):
        self.pump = pump_relay
        self.logger = logger
        self.state = IrrigationState()

    def toggle_irrigation(self):
        if self.state.is_active:
            self.pump.turn_off()
            self.logger.info("Irrigation stopped")
        else:
            self.pump.turn_on()
            self.logger.info("Irrigation started")
        self.state.is_active = not self.state.is_active

# infra/config.py
import os

class EmbeddedConfig:
    RELAY_PIN = int(os.getenv("RELAY_PIN", "14"))
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

# adapters/serial_logger.py
from domain.ports.logger_port import LoggerPort

class SerialLogger(LoggerPort):
    def info(self, message: str) -> None:
        print(f"[INFO] {message}")

    def error(self, message: str) -> None:
        print(f"[ERROR] {message}")

# adapters/esp32_relay_adapter.py (Driven Adapter)
from machine import Pin
from domain.ports.relay_port import RelayPort

class ESP32RelayAdapter(RelayPort):
    def __init__(self, pin_number: int):
        self.pin = Pin(pin_number, Pin.OUT)

    def turn_on(self) -> None:
        self.pin.value(1)

    def turn_off(self) -> None:
        self.pin.value(0)

# main.py (Composition Root + Driving Adapter)
from adapters.esp32_relay_adapter import ESP32RelayAdapter
from adapters.serial_logger import SerialLogger
from infra.config import EmbeddedConfig
from domain.workflows.pump_controller import PumpController

def main():
    water_pump = ESP32RelayAdapter(pin_number=EmbeddedConfig.RELAY_PIN)
    logger = SerialLogger()
    controller = PumpController(pump_relay=water_pump, logger=logger)

    button = Pin(0, Pin.IN, Pin.PULL_UP)
    button.irq(trigger=Pin.IRQ_FALLING, handler=lambda p: controller.toggle_irrigation())

if __name__ == "__main__":
    main()
```

## Lifecycle Hooks

### Startup

```python
# main.py (Composition Root)
import atexit
import signal
import sys

def create_app():
    config = FirestoreConfiguration.from_environment()
    repo = FirestoreDocumentAdapter(config.project_id, config.collection_name)
    logger = ConsoleLogger()
    return repo, logger

def shutdown_handler(signum, frame):
    print("Shutting down gracefully...")
    # Flush buffers, close connections
    sys.exit(0)

signal.signal(signal.SIGTERM, shutdown_handler)
signal.signal(signal.SIGINT, shutdown_handler)

repo, logger = create_app()
atexit.register(lambda: print("Cleanup complete"))
```

### FastAPI Lifecycle

```python
# main.py
from contextlib import asynccontextmanager
from fastapi import FastAPI

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: create adapters, open connections
    config = FirestoreConfiguration.from_environment()
    app.state.repo = FirestoreDocumentAdapter(config.project_id, config.collection_name)
    yield
    # Shutdown: flush buffers, close connections
    print("Flushing pending writes...")

app = FastAPI(lifespan=lifespan)
```

## Hard-Fail Patterns

```python
# BAD: soft fail — hides the error
try:
    result = create_document(content, repo, logger)
except Exception:
    return None

# GOOD: hard fail — stops execution, clear error
result = create_document(content, repo, logger)  # Raises on any error

# BAD: generic assertion
assert result == expected

# GOOD: specific assertion with context
assert result.status == DocumentStatus.PUBLISHED, (
    f"Expected PUBLISHED, got {result.status}. "
    f"Content: {result.content!r}"
)

# BAD: generic exception
raise ValueError("Invalid input")

# GOOD: specific, self-documenting error
raise EmptyContentError("Document content cannot be empty")
```

## Pure Functions in Domain

Domain workflows should be pure functions: same input → same output, no side effects. I/O happens in adapters only.

```python
# BAD: impure — depends on external state
def calculate_total(cart):
    tax_rate = get_tax_rate_from_db()  # Hidden dependency!
    return cart.subtotal * (1 + tax_rate)

# GOOD: pure — all dependencies injected
def calculate_total(cart: Cart, tax_rate: float) -> float:
    return cart.subtotal * (1 + tax_rate)

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
    start = time.now_ms()

    # Pure logic: validation
    if not content.strip():
        raise EmptyContentError()

    # Pure logic: create model
    document = Document.create(content=content)

    # Adapter calls: all I/O happens here
    repo.save(document)
    elapsed = time.elapsed_ms(start)
    logger.info(f"Document created {document.id} in {elapsed}ms")
    return document
```

**Testing pure functions is trivial:**

```python
def test_calculate_total():
    cart = Cart(items=[CartItem(price=10, quantity=2)])
    assert calculate_total(cart, tax_rate=0.08) == 21.6

def test_calculate_total_zero_tax():
    cart = Cart(items=[CartItem(price=10, quantity=2)])
    assert calculate_total(cart, tax_rate=0.0) == 20.0

# No mocks, no setup, no database — just input → output
```

## Structured Logging

```python
# adapters/structured_logger.py
import logging
import uuid
from domain.ports.logger import LoggerPort

class StructuredLogger(LoggerPort):
    def __init__(self, service_name: str, time: TimePort,
                 version: str = "dev", log_level: str = "INFO"):
        self.logger = logging.getLogger(service_name)
        self.logger.setLevel(getattr(logging, log_level.upper()))
        self.time = time
        self.version = version
        self.request_id = None

    def set_request_id(self, request_id: str):
        self.request_id = request_id

    def _log(self, level: str, event: str, **kwargs):
        message = {
            "ts": self.time.now_ms(),        # adapter stamps time — delays visible per record
            "version": self.version,         # which code produced this record
            "request_id": self.request_id,   # correlate logs <-> events <-> metrics
            "event": event,
            **kwargs,
        }
        getattr(self.logger, level)(message)

    def info(self, event: str, **kwargs):
        self._log("info", event, **kwargs)

    def error(self, event: str, **kwargs):
        self._log("error", event, **kwargs)

# Usage in adapters
logger.info("document_saved", document_id=doc.id, collection="documents")
logger.error("firestore_save_failed", document_id=doc.id, error=str(e), retry=1)
logger.info("document_committed", document_id=doc.id, duration_ms=time.elapsed_ms(start))
```

## Diagnostics & Failure Localization (Python)

### Error Registry and CI Check

Every `code` maps to meaning, owner, retryable, and a runbook. A script fails CI when a code is unknown or duplicated.

```toml
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

```python
# cli.py — check-errors subcommand (registry: no unknown or duplicate codes)
import re
import sys
import tomllib
from pathlib import Path

registry = tomllib.loads(Path("errors.toml").read_text())
known = set(registry)
used = set()
for path in Path(".").rglob("*.py"):
    used |= set(re.findall(r'code="([A-Z]+-\d+)"', path.read_text()))

if unknown := used - known:
    sys.exit(f"Unregistered error codes: {sorted(unknown)}")
# Duplicate codes are already a TOML parse error (same table key twice).
print(f"OK: {len(used)} codes used, all registered")
```

### Origin and Correlation at the Boundary

```python
# adapters/sql/sql_repository.py — translate + enrich, never swallow
import traceback

def origin_here() -> str:
    frame = traceback.extract_stack()[-2]
    return f"adapter.{Path(frame.filename).stem}.{frame.name}:{frame.lineno}"

def save(self, entity) -> None:
    try:
        self._connection.execute(self._config.save_sql, self._to_params(entity))
        self._connection.commit()
    except Exception as e:
        raise AppError(
            code="STO-001", message="Storage write failed", cause=e,
            context={"operation": "save", "adapter": self._config.table},
            origin=origin_here(), retryable=True,
        ) from e            # cause preserved
```

### Crash Handler + Breadcrumbs

```python
# wire_adapters.py (root) — install once in the composition root
import atexit
import sys
import traceback
from collections import deque

BREADCRUMBS: deque[str] = deque(maxlen=50)   # ring buffer; logger adapter appends here

def install_crash_handler(lifetime, flush_observability) -> None:
    def _excepthook(exc_type, exc, tb):
        print("".join(traceback.format_exception(exc_type, exc, tb)), file=sys.stderr)
        print("breadcrumbs:", list(BREADCRUMBS), file=sys.stderr)
        flush_observability()                 # never lose buffered logs/metrics/events
        sys.exit(70)                          # EX_SOFTWARE — distinct exit code
    sys.excepthook = _excepthook
    atexit.register(flush_observability)
```

### Fault Injection

```python
# tests/fault/test_document_faults.py
import pytest
from domain.errors.app_error import AppError

class FailingRepo:
    def __init__(self, error): self._error = error
    def save(self, document): raise self._error
    def find_by_id(self, document_id): return None

def test_save_failure_surfaces_storage_error():
    with pytest.raises(AppError) as exc:
        create_document("Hello", FailingRepo(TimeoutError("timed out")), FakeLogger(), FakeTime())
    err = exc.value
    assert err.code == "STO-001" and err.retryable is True
    assert isinstance(err.cause, TimeoutError)          # cause preserved
    assert err.origin.startswith("adapter.")            # location filled at the boundary

def test_observability_survives_sink_failure():
    # a failing logger must never break the workflow
    create_document("Hello", FakeDocumentRepo(), FailingLogger(), FakeTime())
```

## Terminal Output (Python, Rich)

Terminal output is a presentation adapter (`PresenterPort`) — colored, structured, and auto-degrading. Never `print` raw text from domain or driven adapters.

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

# adapters/console/rich_presenter.py
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

# A PlainPresenter (no rich import) is used in CI / non-TTY so logs stay clean.
```

```python
# cli.py (root, driving adapter) — render a failure as one panel
presenter.panel(
    f"[red]{err.code}[/red] {err.message}",
    f"origin: {err.origin}\ncorrelation: {err.correlation_id}\ncause: {err.cause}",
    style="red",
)
presenter.table("Adapters", ["port", "impl", "status"], [
    ["Repository", "SqlRepository", "pass"],
    ["LoggerPort", "DuckDbLogger", "pass"],
])
```

```just
# justfile — light index; each line delegates to cli.py
doctor:
    uv run python cli.py doctor
seed:
    uv run python cli.py seed
replay id:
    uv run python cli.py replay {{id}}
```

## Property, Mutation & Formal Verification (Python)

```python
# tests/property/test_document_properties.py (hypothesis)
from hypothesis import given, strategies as st

@given(st.text(min_size=1), st.sampled_from(list(DocumentStatus)))
def test_create_then_read_round_trips(content, status):
    repo = FakeDocumentRepo()
    doc = create_document(content, repo, FakeLogger(), FakeTime())
    assert repo.find_by_id(doc.id) == doc

@given(st.lists(st.text()))
def test_encode_decode_round_trips(documents):
    assert [decode(encode(d)) for d in documents] == documents
```

```just
test-property:
    uv run pytest tests/property -v

mutation:
    uv run mutmut run      # config-driven; enforce the score threshold in CI
    uv run mutmut results
```

```toml
# pyproject.toml — mutmut 3 config (verified against mutmut 3.8)
[tool.mutmut]
source_paths = ["domain"]
pytest_add_cli_args_test_selection = ["tests"]
```

- **Mutation**: `mutmut` (or `cosmic-ray`) mutates `domain/`; a surviving mutant means a weak or missing assertion. Gate on a score threshold for `domain/` only.
- **Formal**: `CrossHair` symbolically verifies Python contracts for pure functions; larger protocol/state-machine cores go to **TLA+**.
- Every counterexample Hypothesis finds becomes a fixed regression test.

## Testing

### Shared Fixtures

```python
# tests/fixtures/__init__.py
from .fakes import FakeDocumentRepo, FakeLogger, FakeMetrics, FakeEventPublisher, FakeTime
from .factories import DocumentFactory

# tests/fixtures/fakes.py
from domain.models.document import Document
from domain.ports.repository import DocumentRepository
from domain.ports.logger import LoggerPort
from domain.ports.time_port import TimePort
from typing import Optional

class FakeDocumentRepo(DocumentRepository):
    def __init__(self):
        self.db: dict[str, Document] = {}
        self.save_count = 0

    def save(self, doc: Document) -> None:
        self.db[doc.id] = doc
        self.save_count += 1

    def find_by_id(self, doc_id: str) -> Optional[Document]:
        return self.db.get(doc_id)

class FakeLogger(LoggerPort):
    def __init__(self):
        self.messages: list[tuple[str, str]] = []
        self.info_count = 0
        self.error_count = 0

    def info(self, message: str, **fields) -> None:
        self.messages.append(("info", message))
        self.info_count += 1

    def error(self, message: str, **fields) -> None:
        self.messages.append(("error", message))
        self.error_count += 1

class FakeMetrics:
    def __init__(self):
        self.samples: list[tuple[str, float, dict]] = []

    def counter(self, name: str, value: float = 1.0, labels=None) -> None:
        self.samples.append((name, value, labels or {}))

    def gauge(self, name: str, value: float, labels=None) -> None:
        self.samples.append((name, value, labels or {}))

    def timing(self, name: str, duration_ms: float, labels=None) -> None:
        self.samples.append((name, duration_ms, labels or {}))

class FakeTime(TimePort):
    def __init__(self):
        self._current_ms = 1000

    def now_ms(self) -> int:
        return self._current_ms

    def elapsed_ms(self, start_ms: int) -> int:
        return self._current_ms - start_ms

    def sleep_ms(self, ms: int) -> None:
        self._current_ms += ms   # deterministic — no real waiting in tests

    def advance_ms(self, ms: int) -> None:
        self._current_ms += ms

class FakeEventPublisher:
    def __init__(self):
        self.events: list[dict[str, Any]] = []
        self.publish_count = 0

    def publish(self, event_type: str, payload: dict[str, Any]) -> None:
        self.events.append({"type": event_type, "payload": payload})
        self.publish_count += 1

    def get_events_by_type(self, event_type: str) -> list[dict[str, Any]]:
        return [e for e in self.events if e["type"] == event_type]

    def clear(self) -> None:
        self.events.clear()
        self.publish_count = 0

# tests/fixtures/factories.py
import uuid
from domain.models.document import Document, DocumentStatus

class DocumentFactory:
    @staticmethod
    def create(
        doc_id: str | None = None,
        content: str = "Test content",
        status: DocumentStatus = DocumentStatus.DRAFT,
    ) -> Document:
        return Document(
            id=doc_id or str(uuid.uuid4()),
            content=content,
            status=status,
        )

    @staticmethod
    def create_batch(count: int) -> list[Document]:
        return [DocumentFactory.create(content=f"Document {i}") for i in range(count)]
```

### Unit Tests

```python
# tests/unit/test_create_document.py
import pytest
from domain.workflows.create_document import create_document
from domain.errors.document_errors import EmptyContentError
from tests.fixtures import DocumentFactory, FakeDocumentRepo, FakeLogger, FakeTime

@pytest.fixture
def repo():
    return FakeDocumentRepo()

@pytest.fixture
def logger():
    return FakeLogger()

@pytest.fixture
def time():
    return FakeTime()

def test_create_document_success(repo, logger, time):
    result = create_document("Hello World", repo, logger, time)

    assert result.id is not None
    assert result.content == "Hello World"
    assert logger.info_count == 1
    assert "ms" in logger.messages[0][1]  # Duration logged

def test_create_document_empty_content_raises(repo, logger, time):
    with pytest.raises(EmptyContentError):
        create_document("", repo, logger, time)

def test_create_document_saves_to_repo(repo, logger, time):
    create_document("Test content", repo, logger, time)
    assert repo.save_count == 1

def test_create_document_logs_duration(repo, logger, time):
    time.advance_ms(42)  # Simulate 42ms of work
    create_document("Test content", repo, logger, time)
    assert "42ms" in logger.messages[0][1]
```

```python
# tests/unit/test_observability.py (assert on metrics — fake captures samples, no I/O)
from tests.fixtures import FakeMetrics, FakeTime

def test_metrics_capture_timing_for_latency():
    time = FakeTime()
    metrics = FakeMetrics()
    start = time.now_ms()
    time.advance_ms(37)                       # simulate work

    metrics.timing("document.commit", time.elapsed_ms(start))

    name, duration_ms, labels = metrics.samples[0]
    assert (name, duration_ms) == ("document.commit", 37)
    assert labels == {}
```

```python
# tests/unit/test_pump_controller.py
import pytest
from domain.workflows.pump_controller import PumpController
from tests.fixtures.fakes import FakeRelayPort, FakeLoggerPort

@pytest.fixture
def relay():
    return FakeRelayPort()

@pytest.fixture
def logger():
    return FakeLoggerPort()

@pytest.fixture
def controller(relay, logger):
    return PumpController(relay, logger)

def test_toggle_irrigation_starts(controller, relay, logger):
    controller.toggle_irrigation()

    assert relay.is_on is True
    assert controller.state.is_active is True
    assert logger.info_count == 1
    assert "started" in logger.messages[0][1]

def test_toggle_irrigation_stops(controller, relay, logger):
    controller.toggle_irrigation()
    controller.toggle_irrigation()

    assert relay.is_on is False
    assert controller.state.is_active is False
    assert "stopped" in logger.messages[1][1]

def test_toggle_irrigation_logs_both_states(controller, logger):
    controller.toggle_irrigation()
    controller.toggle_irrigation()

    assert logger.info_count == 2
    assert "started" in logger.messages[0][1]
    assert "stopped" in logger.messages[1][1]
```

### Integration Tests

```python
# tests/integration/conftest.py
import pytest
from adapters.firestore_adapter import FirestoreDocumentAdapter

@pytest.fixture(scope="session")
def firestore_adapter():
    adapter = FirestoreDocumentAdapter("test_documents")
    yield adapter

# tests/integration/test_firestore_adapter.py
from domain.models.document import Document

def test_firestore_save_and_retrieve(firestore_adapter):
    doc = Document(id="test-123", content="Integration test content")
    firestore_adapter.save(doc)
    retrieved = firestore_adapter.find_by_id("test-123")
    assert retrieved is not None
    assert retrieved.content == doc.content
```

### E2E Tests

```python
# tests/e2e/conftest.py
import pytest
from fastapi.testclient import TestClient
from main import app
from tests.fixtures import DocumentFactory

@pytest.fixture
def client():
    return TestClient(app)

@pytest.fixture
def sample_document():
    return DocumentFactory.create(doc_id="e2e-test-123", content="E2E test content")

# tests/e2e/test_api.py
def test_create_document_endpoint(client, sample_document):
    response = client.post(
        f"/docs/{sample_document.id}",
        json={"text": sample_document.content}
    )
    assert response.status_code == 200
    assert response.json()["id"] == sample_document.id

def test_create_multiple_documents(client):
    from tests.fixtures import DocumentFactory
    docs = DocumentFactory.create_batch(3)

    for doc in docs:
        response = client.post(f"/docs/{doc.id}", json={"text": doc.content})
        assert response.status_code == 200
```
