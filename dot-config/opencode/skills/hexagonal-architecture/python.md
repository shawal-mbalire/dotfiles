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
# justfile - Project commands

set dotenv-load

default:
    @just --list

run:
    uv run python main.py  # or api.py, worker.py, engine.py, cli.py

logs *args:
    @echo "Configure the logs command in your project's justfile"

prefix name color:
    @while IFS= read -r line; do printf "\033[3%sm[%-12s]\033[0m %s\n" "{{color}}" "{{name}}" "$$line"; done

test:
    uv run pytest tests/ -v

test-unit:
    uv run pytest tests/unit/ -v

test-integration:
    uv run pytest tests/integration/ -v

test-e2e:
    uv run pytest tests/e2e/ -v

test-coverage:
    uv run pytest tests/ --cov=domain --cov=infra --cov=adapters --cov-report=term-missing

lint:
    uv run ruff check .

format:
    uv run ruff format .

typecheck:
    uv run pyright

check: lint typecheck test

clean:
    find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
    find . -type f -name "*.pyc" -delete 2>/dev/null || true
    rm -rf .pytest_cache .ruff_cache .mypy_cache htmlcov .coverage

add *args:
    uv add {{ args }}

dev-add *args:
    uv add --dev {{ args }}

sync:
    uv sync

update:
    uv lock --upgrade
    uv sync
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

# domain/errors/document_errors.py
from dataclasses import dataclass

@dataclass(frozen=True)
class EmptyContentError(Exception):
    message: str = "Document content cannot be empty"

@dataclass(frozen=True)
class DocumentNotFoundError(Exception):
    document_id: str
    message: str = "Document not found"

# domain/ports/repository.py
from typing import Protocol

class DocumentRepository(Protocol):
    def save(self, document: Document) -> None: ...
    def find_by_id(self, document_id: str) -> Document | None: ...

# domain/ports/logger.py
from typing import Protocol

class LoggerPort(Protocol):
    def info(self, message: str) -> None: ...
    def error(self, message: str) -> None: ...

# domain/workflows/create_document.py
from domain.models.document import Document
from domain.ports.repository import DocumentRepository
from domain.ports.logger import LoggerPort
from domain.errors.document_errors import EmptyContentError

def create_document(
    content: str,
    document_repository: DocumentRepository,
    logger: LoggerPort,
) -> Document:
    if not content.strip():
        raise EmptyContentError()

    document = Document.create(content=content)
    document_repository.save(document)
    logger.info(f"Document created with identifier {document.id}")
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

# adapters/firestore_adapter.py
from google.cloud import firestore
from domain.ports.repository import DocumentRepository
from domain.models.document import Document

class FirestoreDocumentAdapter(DocumentRepository):
    def __init__(self, project_id: str, collection_name: str) -> None:
        self.firestore_client = firestore.Client(project=project_id)
        self.collection = self.firestore_client.collection(collection_name)

    def save(self, document: Document) -> None:
        self.collection.document(document.id).set({
            "content": document.content,
            "status": document.status.value,
        })

    def find_by_id(self, document_id: str) -> Document | None:
        document_reference = self.collection.document(document_id).get()
        if document_reference.exists:
            document_data = document_reference.to_dict()
            return Document(
                id=document_id,
                content=document_data["content"],
                status=DocumentStatus(document_data["status"]),
            )
        return None

# main.py (Composition Root)
from adapters.firestore_adapter import FirestoreDocumentAdapter
from adapters.console_logger import ConsoleLogger
from infra.config import FirestoreConfiguration, LoggingConfiguration
from domain.workflows.create_document import create_document

def main() -> None:
    firestore_configuration = FirestoreConfiguration.from_environment()
    document_repository = FirestoreDocumentAdapter(
        project_id=firestore_configuration.project_id,
        collection_name=firestore_configuration.collection_name,
    )
    logger = ConsoleLogger()

    @app.post("/documents/{document_id}")
    def api_create_document(document_id: str, request_body: dict) -> dict:
        document = create_document(
            content=request_body["content"],
            document_repository=document_repository,
            logger=logger,
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

## Structured Logging

```python
# adapters/structured_logger.py
import logging
import uuid
from domain.ports.logger import LoggerPort

class StructuredLogger(LoggerPort):
    def __init__(self, service_name: str, log_level: str = "INFO"):
        self.logger = logging.getLogger(service_name)
        self.logger.setLevel(getattr(logging, log_level.upper()))
        self.request_id = None

    def set_request_id(self, request_id: str):
        self.request_id = request_id

    def _log(self, level: str, event: str, **kwargs):
        message = {
            "request_id": self.request_id,
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
```

## Testing

### Shared Fixtures

```python
# tests/fixtures/__init__.py
from .fakes import FakeDocumentRepo, FakeLogger, FakeEventPublisher
from .factories import DocumentFactory

# tests/fixtures/fakes.py
from domain.models.document import Document
from domain.ports.repository import DocumentRepository
from domain.ports.logger import LoggerPort
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

    def info(self, message: str) -> None:
        self.messages.append(("info", message))
        self.info_count += 1

    def error(self, message: str) -> None:
        self.messages.append(("error", message))
        self.error_count += 1

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
from tests.fixtures import DocumentFactory, FakeDocumentRepo, FakeLogger

@pytest.fixture
def repo():
    return FakeDocumentRepo()

@pytest.fixture
def logger():
    return FakeLogger()

def test_create_document_success(repo, logger):
    result = create_document("Hello World", repo, logger)

    assert result.id is not None
    assert result.content == "Hello World"
    assert logger.info_count == 1

def test_create_document_empty_content_raises(repo, logger):
    with pytest.raises(EmptyContentError):
        create_document("", repo, logger)

def test_create_document_saves_to_repo(repo, logger):
    create_document("Test content", repo, logger)
    assert repo.save_count == 1
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
