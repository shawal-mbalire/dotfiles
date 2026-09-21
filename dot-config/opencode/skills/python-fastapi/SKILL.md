---
name: python-fastapi
description: Build production-grade Python REST APIs with FastAPI and hexagonal architecture. Use when creating FastAPI projects, designing API endpoints, implementing dependency injection, middleware, background tasks, async patterns, OpenAPI schemas, or structuring a maintainable backend with clean domain boundaries.
---

# Python FastAPI — Hexagonal Architecture Guide

Production-grade REST APIs with FastAPI as the driving adapter, clean domain logic, and pluggable infrastructure. Combines [hexagonal architecture](https://opencode.ai/skills/hexagonal-architecture/SKILL.md) principles with advanced FastAPI features.

## Quick Reference

| Section | What's Here |
|---------|-------------|
| [Repository vs Gateway](#repository-vs-gateway--pattern-guide) | Pattern decision matrix |
| [Core](#core-principles) | Domain, ports, adapters, composition root |
| [Auth](#authentication--authorization-jwt--oauth2) | JWT/OAuth2 with minimal deps |
| [Database](#repository-adapters-specific-implementations) | PostgreSQL, SQLite, in-memory repositories |
| [Gateways](#gateway-adapters-specific-implementations) | Stripe, SendGrid, S3 adapters |
| [Logging](#stdlib-logging-adapter) | Structured JSON via stdlib |
| [Pagination](#pagination-lightweight) | Offset/cursor patterns |
| [Rate Limiting](#rate-limiting-lightweight-in-memory) | Sliding window + token bucket |
| [Caching](#caching-lightweight-in-memory) | TTL cache + response caching |
| [File Uploads](#file-uploads-lightweight) | Local storage adapter |
| [WebSocket](#websocket-adapter-real-time) | Real-time bidirectional |
| [gRPC](#grpc-adapter-high-performance-services) | High-perf service-to-service |
| [GraphQL](#graphql-schema-first-apis) | Schema-first with Strawberry |
| [Message Queues](#message-queues-async-processing) | RabbitMQ, Kafka, Redis, ZeroMQ |
| [IoT](#mqtt-iot--lightweight-pubsub) | MQTT, CoAP for constrained devices |
| [IPC](#unix-domain-sockets-ipc) | Unix sockets, named pipes |
| [Event Sourcing](#event-sourcing--cqrs-pattern) | CQRS + event store |
| [Decision Matrix](#when-to-use-decision-matrix) | Protocol comparison + flowchart |

## Project Structure

```
my-api/
├── main.py                     # Composition root — wires adapters, creates app
├── wire_adapters.py            # Factory functions for all adapters
├── pyproject.toml
├── justfile
├── .env
│
├── domain/
│   ├── models/                 # Pure data structures (dataclasses, frozen)
│   │   ├── user.py
│   │   ├── order.py
│   │   ├── payment.py
│   │   ├── notification.py
│   │   ├── auth.py
│   │   ├── file.py
│   │   └── pagination.py
│   ├── errors/                 # Business exceptions inheriting AppError
│   │   ├── app_error.py
│   │   ├── user_errors.py
│   │   ├── order_errors.py
│   │   └── payment_errors.py
│   ├── events/                 # Domain events
│   │   └── events.py
│   ├── ports/
│   │   ├── repositories/       # GENERIC interfaces for YOUR data stores
│   │   │   ├── user_repository.py    # Protocol: UserRepository
│   │   │   ├── order_repository.py   # Protocol: OrderRepository
│   │   │   └── product_repository.py # Protocol: ProductRepository
│   │   ├── gateways/           # GENERIC interfaces for external services
│   │   │   ├── payment_gateway.py    # Protocol: PaymentGateway
│   │   │   ├── notification_gateway.py # Protocol: NotificationGateway
│   │   │   ├── storage_gateway.py    # Protocol: StorageGateway
│   │   │   └── identity_gateway.py   # Protocol: IdentityGateway
│   │   ├── services/           # Domain services (cross-aggregate)
│   │   │   ├── auth_service.py       # Protocol: AuthService
│   │   │   ├── event_publisher.py    # Protocol: EventPublisher
│   │   │   └── password_hasher.py    # Protocol: PasswordHasher
│   │   └── infrastructure/     # Cross-cutting concerns
│   │       ├── logger.py             # Protocol: LoggerPort
│   │       ├── cache.py              # Protocol: CachePort
│   │       └── time_port.py          # Protocol: TimePort
│   └── workflows/              # Pure orchestrations (functions or classes)
│       ├── create_user.py
│       ├── create_order.py
│       └── get_user.py
│
├── infra/
│   └── config.py               # Env loading, typed config dataclasses
│
├── adapters/
│   ├── http/                   # Driving adapter: FastAPI routes, middleware, schemas
│   │   ├── routes/
│   │   │   ├── users.py
│   │   │   ├── orders.py
│   │   │   ├── auth.py
│   │   │   ├── files.py
│   │   │   └── webhooks.py
│   │   ├── schemas/
│   │   │   ├── user.py
│   │   │   ├── order.py
│   │   │   ├── auth.py
│   │   │   └── pagination.py
│   │   ├── middleware.py
│   │   ├── dependencies.py
│   │   ├── error_handlers.py
│   │   └── health.py
│   ├── persistence/            # SPECIFIC repository implementations
│   │   ├── postgres/           # PostgreSQL adapters
│   │   │   ├── user_repository.py    # implements UserRepository
│   │   │   ├── order_repository.py   # implements OrderRepository
│   │   │   └── pool.py               # Connection pool
│   │   ├── sqlite/             # SQLite adapters
│   │   │   └── user_repository.py    # implements UserRepository
│   │   ├── in_memory/          # In-memory adapters (testing)
│   │   │   ├── user_repository.py    # implements UserRepository
│   │   │   └── order_repository.py   # implements OrderRepository
│   │   └── query_builder.py    # SQL query builder utility
│   ├── external/               # SPECIFIC gateway implementations
│   │   ├── stripe_gateway.py           # implements PaymentGateway
│   │   ├── adyen_gateway.py            # implements PaymentGateway (alt)
│   │   ├── sendgrid_gateway.py         # implements NotificationGateway (email)
│   │   ├── twilio_gateway.py           # implements NotificationGateway (SMS)
│   │   ├── fcm_gateway.py              # implements NotificationGateway (push)
│   │   ├── s3_gateway.py               # implements StorageGateway
│   │   ├── gcs_gateway.py              # implements StorageGateway (alt)
│   │   └── auth0_gateway.py            # implements IdentityGateway
│   ├── auth/                   # Auth adapters
│   │   ├── jwt_service.py
│   │   └── password_hasher.py
│   ├── cache/                  # Cache adapters
│   │   ├── memory_cache.py            # implements CachePort (in-memory)
│   │   └── redis_cache.py             # implements CachePort (Redis)
│   ├── logging/                # Logging adapters
│   │   └── logger_adapter.py          # implements LoggerPort
│   ├── resilience/             # Resilience patterns
│   │   ├── circuit_breaker.py
│   │   ├── retry.py
│   │   └── bulkhead.py
│   └── messaging/              # Message queue adapters
│       ├── rabbitmq.py
│       ├── kafka.py
│       └── redis_streams.py
│
├── tests/
│   ├── unit/                   # Pure domain + pure adapter helpers
│   ├── integration/            # Real adapter tests (DB, HTTP)
│   ├── e2e/                    # Full API tests via httpx AsyncClient
│   └── fixtures/               # Shared fakes, factories, test data
│
└── alembic/                    # DB migrations
```

## pyproject.toml

```toml
[project]
name = "my-api"
version = "0.1.0"
description = "FastAPI + hexagonal architecture"
requires-python = ">=3.12"
dependencies = [
    "fastapi>=0.115",
    "uvicorn[standard]>=0.30",
    "pydantic>=2.9",
    "pydantic-settings>=2.5",
    "httpx>=0.27",
    "asyncpg>=0.30",              # PostgreSQL async driver
    # Message queues (uncomment as needed)
    # "aio-pika>=9.0",            # RabbitMQ
    # "aiokafka>=0.10",           # Kafka
    # "redis>=5.0",               # Redis Streams/Pub-Sub
    # "nats-py>=2.0",             # NATS
    # gRPC (uncomment as needed)
    # "grpcio>=1.60",
    # "grpcio-tools>=1.60",
    # IoT (uncomment as needed)
    # "paho-mqtt>=1.6",           # MQTT
    # "aiocoap>=0.4",             # CoAP
    # GraphQL (uncomment as needed)
    # "strawberry-graphql>=0.200", # GraphQL
]

[tool.uv]
dev-dependencies = [
    "pytest>=8.0",
    "pytest-asyncio>=0.24",
    "httpx>=0.27",
    "ruff>=0.5",
    "pyright>=1.1",
    "testcontainers[postgres]>=4.0",  # Integration tests
    # gRPC testing (uncomment as needed)
    # "grpcio-testing>=1.60",
]

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]

[tool.ruff]
target-version = "py312"
line-length = 88

[tool.ruff.lint]
select = ["E", "F", "I", "N", "UP", "B", "A", "C4", "SIM", "TCH"]

[tool.pyright]
typeCheckingMode = "strict"
pythonVersion = "3.12"
```

## Core Principles

1. **Domain owns logic** — Pure functions and frozen dataclasses. No FastAPI/Pydantic imports in domain.
2. **Ports define contracts** — `Protocol` classes in `domain/ports/`. Domain never imports adapters.
3. **Adapters translate** — FastAPI routes convert HTTP → domain models → call workflows → convert back to HTTP.
4. **Composition root wires** — `main.py` creates FastAPI app, injects adapters, registers routes.
5. **DTOs stay in adapters** — Pydantic schemas live in `adapters/http/schemas/`, never in domain.
6. **Error boundary** — Every exception is an `AppError` with code, context, cause, origin, correlation_id.

## Repository vs Gateway — Pattern Guide

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                     REPOSITORY vs GATEWAY                                        │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  REPOSITORY (Domain-Driven)                                                     │
│  ───────────────────────────                                                    │
│  • Domain port defines GENERIC interface (UserRepository)                       │
│  • Adapters implement SPECIFIC backends (PostgresUserRepo, SqliteUserRepo)      │
│  • Works with DOMAIN models (User, Order, Product)                              │
│  • Hides SQL/NoSQL details behind domain-friendly interface                     │
│                                                                                 │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │  GENERIC PORT (domain)          SPECIFIC ADAPTER (adapters/)            │  │
│  │  ─────────────────────          ────────────────────────────            │  │
│  │  UserRepository                 PostgresUserRepository                  │  │
│  │                                 SqliteUserRepository                    │  │
│  │                                 InMemoryUserRepository                  │  │
│  │  OrderRepository                PostgresOrderRepository                 │  │
│  │                                 MongoOrderRepository                    │  │
│  └──────────────────────────────────────────────────────────────────────────┘  │
│                                                                                 │
│  GATEWAY (Anti-Corruption Layer)                                                │
│  ───────────────────────────────                                                │
│  • Domain port defines GENERIC interface (PaymentGateway)                       │
│  • Adapters implement SPECIFIC services (StripeGateway, AdyenGateway)           │
│  • Translates between domain models and external API shapes                     │
│  • Protects domain from vendor lock-in                                          │
│                                                                                 │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │  GENERIC PORT (domain)          SPECIFIC ADAPTER (adapters/)            │  │
│  │  ─────────────────────          ────────────────────────────            │  │
│  │  PaymentGateway                 StripeGateway                           │  │
│  │                                 AdyenGateway                            │  │
│  │                                 PayPalGateway                           │  │
│  │  NotificationGateway            SendGridGateway (email)                 │  │
│  │                                 TwilioGateway (SMS)                     │  │
│  │                                 FCMGateway (push)                       │  │
│  │  StorageGateway                 S3Gateway                               │  │
│  │                                 GCSGateway                              │  │
│  │                                 AzureBlobGateway                        │  │
│  │  IdentityGateway                Auth0Gateway                            │  │
│  │                                 FirebaseGateway                         │  │
│  └──────────────────────────────────────────────────────────────────────────┘  │
│                                                                                 │
│  SWAP ADAPTERS WITHOUT CHANGING DOMAIN:                                         │
│                                                                                 │
│  # Composition root — swap Stripe for Adyen with one line change:              │
│  payment_gateway = AdyenGateway(api_key=settings.adyen_key)  # was Stripe      │
│                                                                                 │
│  # Composition root — swap PostgreSQL for SQLite in tests:                     │
│  user_repo = SqliteUserRepository(db_path=":memory:")  # was Postgres         │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Domain Layer

### Models (Pure — No Framework Imports)

```python
# domain/models/user.py
from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum

class UserRole(StrEnum):
    ADMIN = "admin"
    MEMBER = "member"
    VIEWER = "viewer"

@dataclass(frozen=True)
class User:
    id: str
    email: str
    name: str
    role: UserRole = UserRole.MEMBER
    created_at: datetime | None = None

    @classmethod
    def create(cls, email: str, name: str) -> "User":
        import uuid
        from datetime import datetime, timezone
        return cls(
            id=str(uuid.uuid4()),
            email=email,
            name=name,
            created_at=datetime.now(timezone.utc),
        )

# domain/models/order.py
from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum

class OrderStatus(StrEnum):
    PENDING = "pending"
    PAID = "paid"
    SHIPPED = "shipped"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"

@dataclass(frozen=True)
class OrderItem:
    product_id: str
    quantity: int
    price: int  # cents

@dataclass
class Order:
    id: str
    user_id: str
    items: list[OrderItem]
    status: OrderStatus = OrderStatus.PENDING
    payment_id: str | None = None
    total_amount: int = 0
    created_at: datetime | None = None

    def __post_init__(self) -> None:
        if not self.total_amount:
            self.total_amount = sum(item.price * item.quantity for item in self.items)

    def mark_paid(self, payment_id: str) -> "Order":
        self.status = OrderStatus.PAID
        self.payment_id = payment_id
        return self

    @classmethod
    def create(cls, user_id: str, items: list[dict]) -> "Order":
        import uuid
        from datetime import datetime, timezone
        order_items = [OrderItem(**item) for item in items]
        return cls(
            id=str(uuid.uuid4()),
            user_id=user_id,
            items=order_items,
            created_at=datetime.now(timezone.utc),
        )

# domain/models/payment.py
from dataclasses import dataclass
from enum import StrEnum

class PaymentStatus(StrEnum):
    SUCCESS = "success"
    FAILED = "failed"
    PENDING = "pending"

@dataclass(frozen=True)
class PaymentRequest:
    user_id: str
    amount: int  # cents
    currency: str = "USD"
    metadata: dict = {}

@dataclass(frozen=True)
class PaymentResult:
    success: bool
    payment_id: str | None = None
    status: PaymentStatus = PaymentStatus.PENDING
    error: str | None = None
    metadata: dict = {}

# domain/models/notification.py
from dataclasses import dataclass
from enum import StrEnum

class NotificationChannel(StrEnum):
    EMAIL = "email"
    SMS = "sms"
    PUSH = "push"

@dataclass(frozen=True)
class Notification:
    id: str
    channel: NotificationChannel
    recipient: str
    subject: str
    body: str
    metadata: dict = {}

# domain/events.py
from dataclasses import dataclass
from datetime import datetime, timezone
from enum import StrEnum

class EventType(StrEnum):
    USER_CREATED = "user.created"
    USER_UPDATED = "user.updated"
    ORDER_CREATED = "order.created"
    ORDER_PAID = "order.paid"
    PAYMENT_FAILED = "payment.failed"

@dataclass(frozen=True)
class DomainEvent:
    event_type: EventType
    aggregate_id: str
    payload: dict
    timestamp: datetime = None
    metadata: dict = {}

    def __post_init__(self):
        if self.timestamp is None:
            object.__setattr__(self, 'timestamp', datetime.now(timezone.utc))

# Convenience event constructors
@dataclass(frozen=True)
class UserCreated(DomainEvent):
    event_type: EventType = EventType.USER_CREATED
    user_id: str = ""
    email: str = ""

    def __post_init__(self):
        if not self.aggregate_id:
            object.__setattr__(self, 'aggregate_id', self.user_id)
        if not self.payload:
            object.__setattr__(self, 'payload', {"user_id": self.user_id, "email": self.email})

@dataclass(frozen=True)
class OrderCreated(DomainEvent):
    event_type: EventType = EventType.ORDER_CREATED
    order_id: str = ""
    user_id: str = ""

    def __post_init__(self):
        if not self.aggregate_id:
            object.__setattr__(self, 'aggregate_id', self.order_id)
        if not self.payload:
            object.__setattr__(self, 'payload', {"order_id": self.order_id, "user_id": self.user_id})
```

### Errors (AppError Shape)

```python
# domain/errors/app_error.py
from dataclasses import dataclass, field

@dataclass(frozen=True)
class AppError(Exception):
    code: str
    message: str
    context: dict = field(default_factory=dict)
    cause: Exception | None = None
    origin: str = ""
    correlation_id: str = ""
    retryable: bool = False
    remediation: str = ""

# domain/errors/user_errors.py
from domain.errors.app_error import AppError

class UserNotFoundError(AppError):
    def __init__(self, user_id: str, **kw):
        super().__init__(
            code="USR-001",
            message=f"User {user_id} not found",
            context={"user_id": user_id},
            remediation="Check the user ID or create a new user",
            **kw,
        )

class DuplicateEmailError(AppError):
    def __init__(self, email: str, **kw):
        super().__init__(
            code="USR-002",
            message=f"Email {email} is already registered",
            context={"email": email},
            remediation="Use a different email address",
            **kw,
        )
```

### Ports (Generic Protocol Interfaces)

```python
# domain/ports/repositories/user_repository.py
from typing import Protocol
from domain.models.user import User

class UserRepository(Protocol):
    """GENERIC interface — any backend can implement this."""
    async def find_by_id(self, user_id: str) -> User | None: ...
    async def find_by_email(self, email: str) -> User | None: ...
    async def find_all(self) -> list[User]: ...
    async def save(self, user: User) -> None: ...
    async def delete(self, user_id: str) -> None: ...
    async def exists(self, user_id: str) -> bool: ...
    async def count(self) -> int: ...

# domain/ports/repositories/order_repository.py
from typing import Protocol
from domain.models.order import Order
from domain.models.pagination import PageParams, PaginatedResult

class OrderRepository(Protocol):
    """GENERIC interface — any backend can implement this."""
    async def find_by_id(self, order_id: str) -> Order | None: ...
    async def find_by_user(self, user_id: str) -> list[Order]: ...
    async def find_paginated(self, page: PageParams) -> PaginatedResult[Order]: ...
    async def save(self, order: Order) -> None: ...
    async def delete(self, order_id: str) -> None: ...

# domain/ports/gateways/payment_gateway.py
from typing import Protocol
from domain.models.payment import PaymentRequest, PaymentResult

class PaymentGateway(Protocol):
    """GENERIC interface — Stripe, Adyen, PayPal can implement this."""
    async def charge(self, request: PaymentRequest) -> PaymentResult: ...
    async def refund(self, payment_id: str, amount: int) -> PaymentResult: ...
    async def get_status(self, payment_id: str) -> str: ...

# domain/ports/gateways/notification_gateway.py
from typing import Protocol

class NotificationGateway(Protocol):
    """GENERIC interface — SendGrid, Twilio, FCM can implement this."""
    async def send_email(self, to: str, subject: str, body: str) -> bool: ...
    async def send_sms(self, phone: str, message: str) -> bool: ...
    async def send_push(self, user_id: str, title: str, body: str) -> bool: ...

# domain/ports/gateways/storage_gateway.py
from typing import Protocol

class StorageGateway(Protocol):
    """GENERIC interface — S3, GCS, Azure Blob can implement this."""
    async def upload(self, key: str, data: bytes, content_type: str) -> str: ...
    async def download(self, key: str) -> bytes: ...
    async def delete(self, key: str) -> bool: ...
    async def get_url(self, key: str, expires_in: int = 3600) -> str: ...

# domain/ports/gateways/identity_gateway.py
from typing import Protocol
from domain.models.auth import TokenPayload

class IdentityGateway(Protocol):
    """GENERIC interface — Auth0, Firebase, Keycloak can implement this."""
    async def verify_token(self, token: str) -> TokenPayload: ...
    async def create_user(self, email: str, password: str) -> str: ...
    async def get_user(self, user_id: str) -> dict: ...
    async def delete_user(self, user_id: str) -> bool: ...

# domain/ports/services/auth_service.py
from typing import Protocol
from domain.models.auth import TokenPayload

class AuthService(Protocol):
    """GENERIC interface for authentication logic."""
    def create_token(self, user_id: str, scopes: list[str] | None = None) -> str: ...
    def verify_token(self, token: str) -> TokenPayload: ...
    def hash_password(self, password: str) -> str: ...
    def verify_password(self, password: str, hashed: str) -> bool: ...

# domain/ports/services/event_publisher.py
from typing import Protocol
from domain.events import DomainEvent

class EventPublisher(Protocol):
    """GENERIC interface — Kafka, Redis, NATS can implement this."""
    async def publish(self, event: DomainEvent) -> None: ...
    async def publish_batch(self, events: list[DomainEvent]) -> None: ...

# domain/ports/infrastructure/logger.py
from typing import Protocol

class LoggerPort(Protocol):
    def info(self, message: str, **fields) -> None: ...
    def error(self, message: str, **fields) -> None: ...
    def warning(self, message: str, **fields) -> None: ...
    def debug(self, message: str, **fields) -> None: ...

# domain/ports/infrastructure/cache.py
from typing import Protocol, TypeVar

T = TypeVar("T")

class CachePort(Protocol[T]):
    """GENERIC interface — memory, Redis, Memcached can implement this."""
    def get(self, key: str) -> T | None: ...
    def set(self, key: str, value: T, ttl_seconds: int = 300) -> None: ...
    def delete(self, key: str) -> None: ...
```

### Workflows (Pure Functions)

```python
# domain/workflows/create_user.py
from domain.models.user import User
from domain.ports.repositories.user_repository import UserRepository
from domain.ports.gateways.notification_gateway import NotificationGateway
from domain.ports.services.event_publisher import EventPublisher
from domain.ports.logger import LoggerPort
from domain.errors.user_errors import DuplicateEmailError
from domain.events import UserCreated

def create_user(
    email: str,
    name: str,
    user_repository: UserRepository,
    notification_gateway: NotificationGateway,
    event_publisher: EventPublisher,
    logger: LoggerPort,
) -> User:
    """Create user workflow — orchestrates repositories and gateways."""
    if user_repository.find_by_email(email) is not None:
        raise DuplicateEmailError(email)
    
    user = User.create(email=email, name=name)
    user_repository.save(user)
    
    # Side effects via gateways
    notification_gateway.send_email(
        to=email,
        subject="Welcome!",
        body=f"Hi {name}, welcome to our platform!",
    )
    
    event_publisher.publish(UserCreated(user_id=user.id, email=email))
    
    logger.info("user created", user_id=user.id, email=email)
    return user

# domain/workflows/create_order.py
from domain.models.order import Order
from domain.ports.repositories.order_repository import OrderRepository
from domain.ports.repositories.user_repository import UserRepository
from domain.ports.gateways.payment_gateway import PaymentGateway
from domain.ports.services.event_publisher import EventPublisher
from domain.errors.order_errors import UserNotFoundError, PaymentFailedError

def create_order(
    user_id: str,
    items: list[dict],
    order_repository: OrderRepository,
    user_repository: UserRepository,
    payment_gateway: PaymentGateway,
    event_publisher: EventPublisher,
) -> Order:
    """Create order — validates user, processes payment, saves order."""
    # Verify user exists (repository)
    user = user_repository.find_by_id(user_id)
    if user is None:
        raise UserNotFoundError(user_id)
    
    # Create order
    order = Order.create(user_id=user_id, items=items)
    
    # Process payment (gateway — external service)
    from domain.models.payment import PaymentRequest
    payment_result = payment_gateway.charge(
        PaymentRequest(
            user_id=user_id,
            amount=order.total_amount,
            currency="USD",
        )
    )
    
    if not payment_result.success:
        raise PaymentFailedError(order.id, payment_result.error)
    
    # Mark order as paid
    order = order.mark_paid(payment_result.payment_id)
    order_repository.save(order)
    
    # Publish event
    event_publisher.publish(OrderCreated(order_id=order.id, user_id=user_id))
    
    return order
```

## Adapters Layer

### FastAPI Schemas (DTOs — Pydantic)

```python
# adapters/http/schemas/user.py
from pydantic import BaseModel, EmailStr, ConfigDict

class CreateUserRequest(BaseModel):
    email: EmailStr
    name: str

class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    email: str
    name: str
    role: str

class ErrorResponse(BaseModel):
    code: str
    message: str
    context: dict = {}
    remediation: str = ""
```

### FastAPI Routes (Driving Adapter)

```python
# adapters/http/routes/users.py
from fastapi import APIRouter, Depends, HTTPException, Request

from adapters.http.schemas.user import CreateUserRequest, UserResponse
from adapters.http.dependencies import get_create_user, get_get_user
from domain.errors.app_error import AppError

router = APIRouter(prefix="/users", tags=["users"])

@router.post("/", response_model=UserResponse, status_code=201)
async def create_user(
    body: CreateUserRequest,
    create_user_fn: callable = Depends(get_create_user),
    request: Request = None,
) -> UserResponse:
    try:
        user = await create_user_fn(
            email=body.email,
            name=body.name,
            correlation_id=request.state.correlation_id,
        )
        return UserResponse.model_validate(user)
    except AppError as e:
        raise HTTPException(status_code=409, detail={
            "code": e.code, "message": e.message, "remediation": e.remediation,
        })

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: str,
    get_user_fn: callable = Depends(get_get_user),
) -> UserResponse:
    try:
        user = await get_user_fn(user_id=user_id)
        return UserResponse.model_validate(user)
    except AppError as e:
        raise HTTPException(status_code=404, detail={
            "code": e.code, "message": e.message,
        })
```

### FastAPI Dependencies (Wiring)

```python
# adapters/http/dependencies.py
from fastapi import Depends

from adapters.persistence.in_memory_user_repository import InMemoryUserRepository
from adapters.console_logger import ConsoleLogger
from adapters.system_time import SystemTimeAdapter

_repo_singleton = InMemoryUserRepository()
_logger_singleton = ConsoleLogger()
_time_singleton = SystemTimeAdapter()

def get_create_user():
    from domain.workflows.create_user import create_user
    def wrapper(email: str, name: str, correlation_id: str = "") -> "User":
        return create_user(
            email=email, name=name,
            user_repository=_repo_singleton,
            logger=_logger_singleton,
        )
    return wrapper

def get_get_user():
    from domain.workflows.get_user import get_user
    return get_user
```

### In-Memory Repository (Dev Adapter)

```python
# adapters/persistence/in_memory_user_repository.py
from domain.models.user import User

class InMemoryUserRepository:
    def __init__(self) -> None:
        self._users: dict[str, User] = {}

    def save(self, user: User) -> None:
        self._users[user.id] = user

    def find_by_id(self, user_id: str) -> User | None:
        return self._users.get(user_id)

    def find_all(self) -> list[User]:
        return list(self._users.values())

    def find_by_email(self, email: str) -> User | None:
        return next((u for u in self._users.values() if u.email == email), None)

    def delete(self, user_id: str) -> None:
        self._users.pop(user_id, None)
```

### Middleware (Error Handling + Request ID)

```python
# adapters/http/middleware.py
import uuid
import time
from fastapi import Request
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware

from domain.errors.app_error import AppError

class CorrelationIdMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        request.state.correlation_id = request.headers.get(
            "X-Request-ID", str(uuid.uuid4())
        )
        response = await call_next(request)
        response.headers["X-Request-ID"] = request.state.correlation_id
        return response

class AppErrorMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        try:
            return await call_next(request)
        except AppError as e:
            status_map = {
                "NOT_FOUND": 404,
                "CONFLICT": 409,
                "VALIDATION": 422,
                "UNAUTHORIZED": 401,
                "FORBIDDEN": 403,
            }
            status = 500
            for keyword, code in status_map.items():
                if keyword in e.code.upper():
                    status = code
                    break
            return JSONResponse(
                status_code=status,
                content={
                    "code": e.code,
                    "message": e.message,
                    "context": e.context,
                    "remediation": e.remediation,
                },
                headers={"X-Request-ID": e.correlation_id} if e.correlation_id else {},
            )

class TimingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start = time.perf_counter()
        response = await call_next(request)
        duration_ms = (time.perf_counter() - start) * 1000
        response.headers["X-Response-Time"] = f"{duration_ms:.1f}ms"
        return response
```

### Background Tasks (Adapter Pattern)

```python
# adapters/background/task_runner.py
from typing import Any, Callable
from domain.ports.time_port import TimePort

class BackgroundTaskRunner:
    def __init__(self, time: TimePort) -> None:
        self._time = time
        self._tasks: list[Callable[[], Any]] = []

    def submit(self, task: Callable[[], Any]) -> None:
        self._tasks.append(task)

    def run_pending(self) -> None:
        for task in self._tasks:
            try:
                task()
            except Exception:
                pass
        self._tasks.clear()

# Using in a route:
@router.post("/", status_code=202)
async def create_with_background(
    body: CreateUserRequest,
    background_tasks: BackgroundTasks,
):
    user = create_user_fn(...)
    background_tasks.add_task(send_welcome_email, user.email)
    return {"status": "processing", "user_id": user.id}
```

### Repository Adapters (Specific Implementations)

#### PostgreSQL (Production)

```python
# adapters/persistence/postgres/user_repository.py
import asyncpg
from domain.models.user import User, UserRole
from domain.ports.repositories.user_repository import UserRepository

class PostgresUserRepository:
    """SPECIFIC adapter — implements generic UserRepository for PostgreSQL."""
    
    def __init__(self, pool: asyncpg.Pool) -> None:
        self._pool = pool

    async def find_by_id(self, user_id: str) -> User | None:
        row = await self._pool.fetchrow("SELECT * FROM users WHERE id = $1", user_id)
        return self._row_to_user(row) if row else None

    async def find_by_email(self, email: str) -> User | None:
        row = await self._pool.fetchrow("SELECT * FROM users WHERE email = $1", email)
        return self._row_to_user(row) if row else None

    async def find_all(self) -> list[User]:
        rows = await self._pool.fetch("SELECT * FROM users ORDER BY created_at DESC")
        return [self._row_to_user(r) for r in rows]

    async def save(self, user: User) -> None:
        await self._pool.execute(
            """INSERT INTO users (id, email, name, role, created_at)
               VALUES ($1, $2, $3, $4, NOW())
               ON CONFLICT (id) DO UPDATE SET
                   email = EXCLUDED.email, name = EXCLUDED.name, role = EXCLUDED.role""",
            user.id, user.email, user.name, user.role.value,
        )

    async def delete(self, user_id: str) -> None:
        await self._pool.execute("DELETE FROM users WHERE id = $1", user_id)

    async def exists(self, user_id: str) -> bool:
        return await self._pool.fetchval("SELECT EXISTS(SELECT 1 FROM users WHERE id = $1)", user_id)

    async def count(self) -> int:
        return await self._pool.fetchval("SELECT COUNT(*) FROM users")

    def _row_to_user(self, row: asyncpg.Record) -> User:
        return User(id=row["id"], email=row["email"], name=row["name"], role=UserRole(row["role"]))
```

#### SQLite (Lightweight/Testing)

```python
# adapters/persistence/sqlite/user_repository.py
import aiosqlite
from domain.models.user import User, UserRole
from domain.ports.repositories.user_repository import UserRepository

class SqliteUserRepository:
    """SPECIFIC adapter — implements generic UserRepository for SQLite."""
    
    def __init__(self, db_path: str = "app.db") -> None:
        self._db_path = db_path

    async def find_by_id(self, user_id: str) -> User | None:
        async with aiosqlite.connect(self._db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute("SELECT * FROM users WHERE id = ?", (user_id,)) as cursor:
                row = await cursor.fetchone()
                return self._row_to_user(row) if row else None

    async def find_by_email(self, email: str) -> User | None:
        async with aiosqlite.connect(self._db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute("SELECT * FROM users WHERE email = ?", (email,)) as cursor:
                row = await cursor.fetchone()
                return self._row_to_user(row) if row else None

    async def find_all(self) -> list[User]:
        async with aiosqlite.connect(self._db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute("SELECT * FROM users") as cursor:
                rows = await cursor.fetchall()
                return [self._row_to_user(r) for r in rows]

    async def save(self, user: User) -> None:
        async with aiosqlite.connect(self._db_path) as db:
            await db.execute(
                "INSERT OR REPLACE INTO users (id, email, name, role) VALUES (?, ?, ?, ?)",
                (user.id, user.email, user.name, user.role.value),
            )
            await db.commit()

    async def delete(self, user_id: str) -> None:
        async with aiosqlite.connect(self._db_path) as db:
            await db.execute("DELETE FROM users WHERE id = ?", (user_id,))
            await db.commit()

    async def exists(self, user_id: str) -> bool:
        async with aiosqlite.connect(self._db_path) as db:
            async with db.execute("SELECT 1 FROM users WHERE id = ?", (user_id,)) as cursor:
                return await cursor.fetchone() is not None

    async def count(self) -> int:
        async with aiosqlite.connect(self._db_path) as db:
            async with db.execute("SELECT COUNT(*) FROM users") as cursor:
                return (await cursor.fetchone())[0]

    def _row_to_user(self, row) -> User:
        return User(id=row["id"], email=row["email"], name=row["name"], role=UserRole(row["role"]))
```

#### In-Memory (Unit Testing)

```python
# adapters/persistence/in_memory/user_repository.py
from domain.models.user import User, UserRole
from domain.ports.repositories.user_repository import UserRepository

class InMemoryUserRepository:
    """SPECIFIC adapter — implements generic UserRepository for testing."""
    
    def __init__(self) -> None:
        self._users: dict[str, User] = {}

    async def find_by_id(self, user_id: str) -> User | None:
        return self._users.get(user_id)

    async def find_by_email(self, email: str) -> User | None:
        return next((u for u in self._users.values() if u.email == email), None)

    async def find_all(self) -> list[User]:
        return list(self._users.values())

    async def save(self, user: User) -> None:
        self._users[user.id] = user

    async def delete(self, user_id: str) -> None:
        self._users.pop(user_id, None)

    async def exists(self, user_id: str) -> bool:
        return user_id in self._users

    async def count(self) -> int:
        return len(self._users)
```

### Gateway Adapters (Specific Implementations)

#### Stripe (Payments)

```python
# adapters/external/stripe_gateway.py
import httpx
from domain.models.payment import PaymentRequest, PaymentResult, PaymentStatus
from domain.ports.gateways.payment_gateway import PaymentGateway
from infra.config import settings

class StripeGateway:
    """SPECIFIC adapter — implements generic PaymentGateway for Stripe."""
    
    def __init__(self, api_key: str | None = None) -> None:
        self._api_key = api_key or settings.stripe_api_key
        self._client = httpx.AsyncClient(
            base_url="https://api.stripe.com/v1",
            headers={"Authorization": f"Bearer {self._api_key}"},
        )

    async def charge(self, request: PaymentRequest) -> PaymentResult:
        try:
            response = await self._client.post("/payment_intents", data={
                "amount": request.amount,
                "currency": request.currency.lower(),
                "metadata[user_id]": request.user_id,
            })
            data = response.json()
            
            if response.status_code == 200:
                return PaymentResult(success=True, payment_id=data["id"], status=PaymentStatus.SUCCESS)
            else:
                return PaymentResult(success=False, status=PaymentStatus.FAILED, error=data.get("error", {}).get("message"))
        except Exception as e:
            return PaymentResult(success=False, status=PaymentStatus.FAILED, error=str(e))

    async def refund(self, payment_id: str, amount: int) -> PaymentResult:
        try:
            response = await self._client.post("/refunds", data={"payment_intent": payment_id, "amount": amount})
            return PaymentResult(success=response.status_code == 200, payment_id=response.json().get("id"))
        except Exception as e:
            return PaymentResult(success=False, error=str(e))

    async def get_status(self, payment_id: str) -> str:
        try:
            response = await self._client.get(f"/payment_intents/{payment_id}")
            return response.json().get("status", "unknown")
        except Exception:
            return "unknown"

    async def close(self) -> None:
        await self._client.aclose()
```

#### SendGrid (Email)

```python
# adapters/external/sendgrid_gateway.py
import httpx
from domain.ports.gateways.notification_gateway import NotificationGateway
from infra.config import settings

class SendGridGateway:
    """SPECIFIC adapter — implements generic NotificationGateway for SendGrid email."""
    
    def __init__(self, api_key: str | None = None) -> None:
        self._api_key = api_key or settings.sendgrid_api_key
        self._client = httpx.AsyncClient(
            base_url="https://api.sendgrid.com/v3",
            headers={"Authorization": f"Bearer {self._api_key}", "Content-Type": "application/json"},
        )

    async def send_email(self, to: str, subject: str, body: str) -> bool:
        try:
            response = await self._client.post("/mail/send", json={
                "personalizations": [{"to": [{"email": to}]}],
                "from": {"email": settings.from_email},
                "subject": subject,
                "content": [{"type": "text/plain", "value": body}],
            })
            return response.status_code in (200, 202)
        except Exception:
            return False

    async def send_sms(self, phone: str, message: str) -> bool:
        raise NotImplementedError("Use TwilioGateway for SMS")

    async def send_push(self, user_id: str, title: str, body: str) -> bool:
        raise NotImplementedError("Use FCMGateway for push")

    async def close(self) -> None:
        await self._client.aclose()
```

#### S3 (Storage)

```python
# adapters/external/s3_gateway.py
import boto3
from domain.ports.gateways.storage_gateway import StorageGateway
from infra.config import settings

class S3Gateway:
    """SPECIFIC adapter — implements generic StorageGateway for AWS S3."""
    
    def __init__(self) -> None:
        self._client = boto3.client(
            "s3",
            aws_access_key_id=settings.aws_access_key_id,
            aws_secret_access_key=settings.aws_secret_access_key,
            region_name=settings.aws_region,
        )
        self._bucket = settings.s3_bucket_name

    async def upload(self, key: str, data: bytes, content_type: str) -> str:
        self._client.put_object(Bucket=self._bucket, Key=key, Body=data, ContentType=content_type)
        return f"s3://{self._bucket}/{key}"

    async def download(self, key: str) -> bytes:
        return self._client.get_object(Bucket=self._bucket, Key=key)["Body"].read()

    async def delete(self, key: str) -> bool:
        try:
            self._client.delete_object(Bucket=self._bucket, Key=key)
            return True
        except Exception:
            return False

    async def get_url(self, key: str, expires_in: int = 3600) -> str:
        return self._client.generate_presigned_url("get_object", Params={"Bucket": self._bucket, "Key": key}, ExpiresIn=expires_in)
```

## Composition Root (main.py)

```python
# main.py
from contextlib import asynccontextmanager
from fastapi import FastAPI

from adapters.http.middleware import (
    AppErrorMiddleware,
    CorrelationIdMiddleware,
    TimingMiddleware,
)
from adapters.http.routes import users
from adapters.persistence.in_memory_user_repository import InMemoryUserRepository
from adapters.console_logger import ConsoleLogger
from adapters.system_time import SystemTimeAdapter
from adapters.signal_lifetime import SignalLifetimeAdapter

@asynccontextmanager
async def lifespan(app: FastAPI):
    lifetime = SignalLifetimeAdapter()
    lifetime.install()

    repo = InMemoryUserRepository()
    logger = ConsoleLogger()
    time = SystemTimeAdapter()

    app.state.repo = repo
    app.state.logger = logger
    app.state.time = time
    app.state.lifetime = lifetime

    yield

    lifetime._handle_signal(0, None)

app = FastAPI(
    title="My API",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(CorrelationIdMiddleware)
app.add_middleware(TimingMiddleware)
app.add_middleware(AppErrorMiddleware)

app.include_router(users.router, prefix="/api/v1")
```

## Infrastructure Config

```python
# infra/config.py
import os
from dataclasses import dataclass
from pydantic_settings import BaseSettings

@dataclass(frozen=True)
class AppConfig:
    environment: str
    host: str
    port: int
    log_level: str

    @classmethod
    def from_environment(cls) -> "AppConfig":
        return cls(
            environment=os.getenv("ENVIRONMENT", "development"),
            host=os.getenv("HOST", "0.0.0.0"),
            port=int(os.getenv("PORT", "8000")),
            log_level=os.getenv("LOG_LEVEL", "INFO"),
        )

# Alternative: Pydantic Settings (auto-validates)
class Settings(BaseSettings):
    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}

    environment: str = "development"
    host: str = "0.0.0.0"
    port: int = 8000
    database_url: str = "sqlite+aiosqlite:///./dev.db"
    cors_origins: list[str] = ["http://localhost:3000"]
    api_key: str = ""

settings = Settings()
```

## Justfile

```just
set shell := ["bash", "-uc"]
set dotenv-load

root := justfile_directory()

default:
    @just --list

run:
    uv run uvicorn main:app --reload --host 0.0.0.0 --port 8000

run-prod:
    uv run uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4

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

db-migrate:
    uv run alembic upgrade head

db-migration msg="auto":
    uv run alembic revision --autogenerate -m "$(msg)"

proto-compile:
    python -m grpc_tools.protoc -I proto --python_out=. --grpc_python_out=. proto/*.proto

grpc-run:
    uv run python -m adapters.grpc.server

docs:
    open http://localhost:8000/docs

check: lint typecheck test
verify: check test-e2e
```

## Testing Patterns

### Unit Tests (No Mocks — Pure Functions)

```python
# tests/unit/test_create_user.py
from adapters.persistence.in_memory_user_repository import InMemoryUserRepository
from adapters.console_logger import ConsoleLogger
from domain.workflows.create_user import create_user
from domain.errors.user_errors import DuplicateEmailError
import pytest

def test_create_user_success():
    repo = InMemoryUserRepository()
    logger = ConsoleLogger()
    user = create_user(email="a@b.com", name="Alice", user_repository=repo, logger=logger)
    assert user.email == "a@b.com"
    assert repo.find_by_id(user.id) == user

def test_create_user_duplicate_email():
    repo = InMemoryUserRepository()
    logger = ConsoleLogger()
    create_user(email="a@b.com", name="Alice", user_repository=repo, logger=logger)
    with pytest.raises(DuplicateEmailError):
        create_user(email="a@b.com", name="Bob", user_repository=repo, logger=logger)
```

### E2E Tests (Full API via httpx AsyncClient)

```python
# tests/e2e/test_users_api.py
import pytest
from httpx import AsyncClient, ASGITransport
from main import app

@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

async def test_create_and_get_user(client: AsyncClient):
    create_resp = await client.post("/api/v1/users/", json={
        "email": "alice@example.com", "name": "Alice",
    })
    assert create_resp.status_code == 201
    user_id = create_resp.json()["id"]

    get_resp = await client.get(f"/api/v1/users/{user_id}")
    assert get_resp.status_code == 200
    assert get_resp.json()["email"] == "alice@example.com"

async def test_get_nonexistent_user_returns_404(client: AsyncClient):
    resp = await client.get("/api/v1/users/nonexistent")
    assert resp.status_code == 404
    assert resp.json()["code"] == "USR-001"
```

### Fault Injection Tests

```python
# tests/integration/test_user_repository_fault.py
import pytest
from adapters.persistence.postgres_user_repository import PostgresUserRepository
from domain.models.user import User, UserRole
from domain.errors.app_error import AppError

class FailingPool:
    """Simulates database failure."""
    async def fetchrow(self, *a, **kw):
        raise ConnectionError("DB unreachable")

async def test_repository_translates_connection_error():
    repo = PostgresUserRepository(FailingPool())
    with pytest.raises(AppError) as exc_info:
        await repo.find_by_id("any-id")
    assert "STORAGE" in exc_info.value.code or "DB" in exc_info.value.code
```

## FastAPI Advanced Patterns

### Custom Exception Handlers

```python
# adapters/http/error_handlers.py
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from domain.errors.app_error import AppError

def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppError)
    async def app_error_handler(request: Request, exc: AppError):
        status = 500
        if "NOT_FOUND" in exc.code:
            status = 404
        elif "CONFLICT" in exc.code:
            status = 409
        elif "VALIDATION" in exc.code:
            status = 422
        return JSONResponse(
            status_code=status,
            content={
                "code": exc.code,
                "message": exc.message,
                "context": exc.context,
                "remediation": exc.remediation,
            },
        )
```

### Lifespan with Adapter Lifecycle

```python
# main.py
from contextlib import asynccontextmanager
from fastapi import FastAPI

@asynccontextmanager
async def lifespan(app: FastAPI):
    # --- Startup ---
    from adapters.persistence.postgres_user_repository import PostgresUserRepository
    from adapters.external.stripe_client import StripeGateway
    import asyncpg

    pool = await asyncpg.create_pool(dsn=settings.database_url)
    repo = PostgresUserRepository(pool)
    stripe = StripeGateway(api_key=settings.api_key)
    lifetime = SignalLifetimeAdapter()
    lifetime.install()

    app.state.repo = repo
    app.state.stripe = stripe
    app.state.lifetime = lifetime
    app.state.pool = pool

    yield

    # --- Shutdown ---
    await pool.close()
```

### Streaming Responses

```python
# adapters/http/routes/stream.py
from fastapi import APIRouter
from fastapi.responses import StreamingResponse
import json

router = APIRouter()

@router.get("/events")
async def stream_events():
    async def event_generator():
        for i in range(10):
            yield f"data: {json.dumps({'count': i})}\n\n"
    return StreamingResponse(event_generator(), media_type="text/event-stream")
```

### OpenAPI Customization

```python
# main.py
app = FastAPI(
    title="My API",
    description="Production-grade API with hexagonal architecture",
    version="0.1.0",
    docs_url="/docs" if settings.environment == "development" else None,
    redoc_url="/redoc" if settings.environment == "development" else None,
    openapi_tags=[
        {"name": "users", "description": "User management"},
        {"name": "health", "description": "Health checks"},
    ],
)

@app.get("/health", tags=["health"])
async def health_check():
    return {"status": "healthy"}
```

## WebSocket Adapter (Real-time)

### Domain Models & Ports

```python
# domain/models/events.py
from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum

class EventType(StrEnum):
    CONNECT = "connect"
    MESSAGE = "message"
    DISCONNECT = "disconnect"
    ERROR = "error"

@dataclass(frozen=True)
class WebSocketMessage:
    event: EventType
    payload: dict
    timestamp: datetime
    client_id: str | None = None

# domain/ports/websocket.py
from typing import Protocol, Callable, Any

class WebSocketPort(Protocol):
    async def send_json(self, client_id: str, data: dict) -> None: ...
    async def broadcast(self, data: dict) -> None: ...
    async def disconnect(self, client_id: str) -> None: ...
    def on_message(self, handler: Callable[[WebSocketMessage], Any]) -> None: ...

# domain/workflows/chat.py
def handle_chat_message(
    msg: WebSocketMessage,
    broadcast: WebSocketPort,
) -> dict:
    """Pure workflow — no WebSocket imports."""
    if msg.event == EventType.MESSAGE:
        return {"echo": msg.payload.get("text", "")}
    return {}
```

### WebSocket Adapter (FastAPI)

```python
# adapters/http/websocket.py
import json
import uuid
from datetime import datetime, timezone
from fastapi import WebSocket, WebSocketDisconnect
from domain.models.events import WebSocketMessage, EventType

class WebSocketManager:
    """Manages WebSocket connections — driven adapter."""
    
    def __init__(self) -> None:
        self._connections: dict[str, WebSocket] = {}
        self._handlers: list = []

    async def connect(self, websocket: WebSocket, client_id: str | None = None) -> str:
        await websocket.accept()
        cid = client_id or str(uuid.uuid4())
        self._connections[cid] = websocket
        return cid

    async def disconnect(self, client_id: str) -> None:
        self._connections.pop(client_id, None)

    async def send_json(self, client_id: str, data: dict) -> None:
        ws = self._connections.get(client_id)
        if ws:
            await ws.send_json(data)

    async def broadcast(self, data: dict) -> None:
        for ws in self._connections.values():
            try:
                await ws.send_json(data)
            except Exception:
                pass  # Remove dead connections

    def on_message(self, handler) -> None:
        self._handlers.append(handler)

    async def handle_connection(self, websocket: WebSocket, client_id: str | None = None) -> None:
        cid = await self.connect(websocket, client_id)
        try:
            while True:
                data = await websocket.receive_json()
                msg = WebSocketMessage(
                    event=EventType(data.get("event", "message")),
                    payload=data.get("payload", {}),
                    timestamp=datetime.now(timezone.utc),
                    client_id=cid,
                )
                # Call registered handlers
                for handler in self._handlers:
                    result = handler(msg)
                    if result:
                        await self.send_json(cid, result)
        except WebSocketDisconnect:
            await self.disconnect(cid)
        except Exception as e:
            await self.send_json(cid, {
                "event": EventType.ERROR,
                "payload": {"error": str(e)},
            })
            await self.disconnect(cid)

# Singleton for app
ws_manager = WebSocketManager()
```

### WebSocket Route

```python
# adapters/http/routes/websocket.py
from fastapi import APIRouter, WebSocket
from adapters.http.websocket import ws_manager

router = APIRouter()

@router.websocket("/ws/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: str):
    await ws_manager.handle_connection(websocket, client_id)

@router.websocket("/ws")
async def websocket_anonymous(websocket: WebSocket):
    await ws_manager.handle_connection(websocket)
```

### Integration with main.py

```python
# main.py — add WebSocket route
from adapters.http.routes import websocket

app.include_router(websocket.router)
```

---

## gRPC Adapter (High-Performance Services)

### Domain Port

```python
# domain/ports/grpc_service.py
from typing import Protocol

class UserServicePort(Protocol):
    async def get_user(self, user_id: str) -> dict: ...
    async def create_user(self, data: dict) -> dict: ...
    async def list_users(self, offset: int, limit: int) -> list[dict]: ...
```

### Proto Definition

```protobuf
// proto/user.proto
syntax = "proto3";

package user;

service UserService {
    rpc GetUser (GetUserRequest) returns (UserResponse);
    rpc CreateUser (CreateUserRequest) returns (UserResponse);
    rpc ListUsers (ListUsersRequest) returns (ListUsersResponse);
    rpc StreamUsers (StreamUsersRequest) returns (stream UserResponse);
}

message GetUserRequest {
    string user_id = 1;
}

message CreateUserRequest {
    string email = 1;
    string name = 2;
}

message UserResponse {
    string id = 1;
    string email = 2;
    string name = 3;
    string role = 4;
}

message ListUsersRequest {
    int32 offset = 1;
    int32 limit = 2;
}

message ListUsersResponse {
    repeated UserResponse users = 1;
    int32 total = 2;
}

message StreamUsersRequest {
    int32 batch_size = 1;
}
```

### gRPC Server Adapter (driven adapter)

```python
# adapters/grpc/user_service.py
import grpc
from concurrent import futures
from domain.workflows.create_user import create_user
from domain.workflows.get_user import get_user
from adapters.persistence.postgres_user_repository import PostgresUserRepository
from adapters.logging.logger_adapter import StdlibJSONLogger

# Generated from proto (run: python -m grpc_tools.protoc -I proto --python_out=. --grpc_python_out=. proto/user.proto)
import user_pb2
import user_pb2_grpc

class UserGrpcService(user_pb2_grpc.UserServiceServicer):
    """gRPC driven adapter — wraps domain workflows."""
    
    def __init__(self, repo: PostgresUserRepository, logger: StdlibJSONLogger) -> None:
        self._repo = repo
        self._logger = logger

    async def GetUser(self, request, context):
        try:
            user = get_user(request.user_id, self._repo)
            return user_pb2.UserResponse(
                id=user.id, email=user.email,
                name=user.name, role=user.role.value,
            )
        except Exception as e:
            context.abort(grpc.StatusCode.NOT_FOUND, str(e))

    async def CreateUser(self, request, context):
        try:
            user = create_user(
                email=request.email, name=request.name,
                user_repository=self._repo, logger=self._logger,
            )
            return user_pb2.UserResponse(
                id=user.id, email=user.email,
                name=user.name, role=user.role.value,
            )
        except Exception as e:
            context.abort(grpc.StatusCode.ALREADY_EXISTS, str(e))

    async def ListUsers(self, request, context):
        from domain.models.pagination import PageParams
        page = PageParams(offset=request.offset, limit=request.limit)
        result = await self._repo.find_paginated(page)
        users = [
            user_pb2.UserResponse(id=u.id, email=u.email,
                                   name=u.name, role=u.role.value)
            for u in result.items
        ]
        return user_pb2.ListUsersResponse(users=users, total=result.total)

    async def StreamUsers(self, request, context):
        """Server streaming example."""
        page = PageParams(offset=0, limit=request.batch_size)
        while True:
            result = await self._repo.find_paginated(page)
            for user in result.items:
                yield user_pb2.UserResponse(
                    id=user.id, email=user.email,
                    name=user.name, role=user.role.value,
                )
            if not result.has_more:
                break
            page = PageParams(offset=page.offset + page.limit, limit=page.limit)
```

### gRPC Server Runner (lifespan integration)

```python
# adapters/grpc/server.py
import asyncio
import grpc
from grpc import aio
import user_pb2_grpc

class GrpcServerRunner:
    """Manages gRPC server lifecycle — driven adapter."""
    
    def __init__(self, port: int = 50051) -> None:
        self._port = port
        self._server: aio.Server | None = None

    async def start(self, service) -> None:
        self._server = aio.server()
        user_pb2_grpc.add_UserServiceServicer_to_server(service, self._server)
        self._server.add_insecure_port(f"[::]:{self._port}")
        await self._server.start()
        print(f"gRPC server listening on port {self._port}")

    async def stop(self) -> None:
        if self._server:
            await self._server.stop(grace=5)

# main.py lifespan update
@asynccontextmanager
async def lifespan(app: FastAPI):
    # ... existing setup ...
    
    # gRPC server
    from adapters.grpc.user_service import UserGrpcService
    from adapters.grpc.server import GrpcServerRunner
    
    grpc_service = UserGrpcService(repo=repo, logger=logger)
    grpc_runner = GrpcServerRunner(port=50051)
    await grpc_runner.start(grpc_service)
    
    yield
    
    # Shutdown
    await grpc_runner.stop()
    await pool.close()
```

### gRPC Client Adapter (calling external gRPC services)

```python
# adapters/external/grpc_client.py
import grpc
import user_pb2
import user_pb2_grpc

class ExternalUserGrpcClient:
    """gRPC client adapter for calling external services."""
    
    def __init__(self, target: str = "localhost:50051") -> None:
        self._target = target
        self._channel: grpc.aio.Channel | None = None
        self._stub: user_pb2_grpc.UserServiceStub | None = None

    async def connect(self) -> None:
        self._channel = grpc.aio.insecure_channel(self._target)
        self._stub = user_pb2_grpc.UserServiceStub(self._channel)

    async def get_user(self, user_id: str) -> dict:
        request = user_pb2.GetUserRequest(user_id=user_id)
        response = await self._stub.GetUser(request)
        return {"id": response.id, "email": response.email, "name": response.name}

    async def disconnect(self) -> None:
        if self._channel:
            await self._channel.close()
```

### pyproject.toml (gRPC deps)

```toml
dependencies = [
    # ... existing ...
    "grpcio>=1.60",
    "grpcio-tools>=1.60",  # For proto compilation
]

[tool.uv]
dev-dependencies = [
    # ... existing ...
    "grpcio-testing>=1.60",
]
```

### Justfile (gRPC commands)

```just
# add to justfile
proto-compile:
    python -m grpc_tools.protoc -I proto --python_out=. --grpc_python_out=. proto/*.proto

grpc-run:
    uv run python -m adapters.grpc.server
```

---

## When to Use: Decision Matrix

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         CONCERN DECISION MATRIX                                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  USE REST (FastAPI) WHEN:                                                       │
│  ✓ Simple CRUD operations                                                      │
│  ✓ Public-facing APIs (browsers, mobile apps)                                  │
│  ✓ Resource-oriented (noun-based URLs)                                         │
│  ✓ Need OpenAPI/Swagger docs automatically                                     │
│  ✓ Caching via HTTP headers matters                                            │
│  ✓ Team is less familiar with gRPC                                              │
│                                                                                 │
│  USE gRPC WHEN:                                                                │
│  ✓ Service-to-service communication (microservices)                            │
│  ✓ High throughput / low latency required                                      │
│  ✓ Streaming (server, client, or bidirectional)                                │
│  ✓ Strict contract enforcement (protobuf)                                      │
│  ✓ Polyglot services (Go, Java, Rust clients)                                 │
│  ✓ Internal APIs not exposed to public                                         │
│                                                                                 │
│  USE WEBSOCKETS WHEN:                                                          │
│  ✓ Real-time bidirectional communication                                       │
│  ✓ Chat, notifications, live updates                                           │
│  ✓ Gaming, collaborative editing                                               │
│  ✓ Low-latency pub/sub (vs polling)                                            │
│  ✓ Connection state matters (online/offline)                                   │
│                                                                                 │
│  USE SERVER-SENT EVENTS (SSE) WHEN:                                            │
│  ✓ Server→client streaming only                                                │
│  ✓ Simpler than WebSocket (auto-reconnect)                                     │
│  ✓ Browser-native (EventSource API)                                            │
│  ✓ Notifications, progress updates                                             │
│                                                                                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  COMBINATION EXAMPLES:                                                          │
│                                                                                 │
│  ┌─────────────────┬─────────────────────────────────────────────────────────┐  │
│  │ Scenario        │ Stack                                                   │  │
│  ├─────────────────┼─────────────────────────────────────────────────────────┤  │
│  │ SaaS API        │ REST (public) + WebSocket (real-time) + PostgreSQL     │  │
│  │ Microservices   │ gRPC (internal) + REST (gateway) + Redis (cache)       │  │
│  │ Chat app        │ WebSocket (primary) + REST (auth/history) + PostgreSQL │  │
│  │ IoT platform    │ gRPC (device→cloud) + WebSocket (dashboard) + TSDB     │  │
│  │ E-commerce      │ REST (API) + SSE (order updates) + PostgreSQL          │  │
│  │ Gaming backend  │ WebSocket (game state) + gRPC (matchmaking) + Redis    │  │
│  └─────────────────┴─────────────────────────────────────────────────────────┘  │
│                                                                                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  PERFORMANCE COMPARISON:                                                        │
│                                                                                 │
│  Protocol    Latency     Throughput    Contract    Browser    Complexity        │
│  ──────────  ──────────  ────────────  ──────────  ─────────  ──────────        │
│  REST        ~10-50ms    Moderate      OpenAPI     ✓ Native   Low              │
│  gRPC        ~1-5ms      High          Protobuf    ✗ (proxy)  Medium           │
│  WebSocket   ~1-10ms     High          None        ✓ Native   Medium           │
│  SSE         ~10-50ms    Low           None        ✓ Native   Low              │
│                                                                                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  HYBRID APPROACH (RECOMMENDED):                                                 │
│                                                                                 │
│  For most projects, use ALL THREE:                                              │
│                                                                                 │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │  External Clients                                                       │  │
│  │      │                                                                  │  │
│  │      ├── REST API (port 8000) ──── CRUD, auth, public endpoints        │  │
│  │      │                                                                  │  │
│  │      ├── WebSocket (port 8000/ws) ── Real-time updates                 │  │
│  │      │                                                                  │  │
│  │      └── SSE (port 8000/events) ──── Notifications                     │  │
│  │                                                                          │  │
│  │  Internal Services                                                      │  │
│  │      │                                                                  │  │
│  │      └── gRPC (port 50051) ──── Service-to-service, streaming          │  │
│  │                                                                          │  │
│  └──────────────────────────────────────────────────────────────────────────┘  │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Anti-Patterns to Avoid

| Anti-Pattern | Why | Better |
|--------------|-----|--------|
| REST for streaming | HTTP overhead, no real-time | WebSocket or SSE |
| gRPC for public API | Browser needs proxy, harder to debug | REST with OpenAPI |
| WebSocket for CRUD | Complexity without benefit | REST |
| Polling for real-time | Wasteful, high latency | WebSocket or SSE |
| gRPC for simple services | Overhead of proto compilation | REST if no streaming needed |
| REST for polyglot microservices | Schema drift, no contract | gRPC with proto |

---

## Communication Patterns — Full Spectrum

### Pattern Categories

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                     COMMUNICATION PATTERN TAXONOMY                              │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  SYNCHRONOUS (Request-Response)                                                │
│  ├── REST/HTTP                                                                  │
│  ├── gRPC                                                                       │
│  ├── GraphQL                                                                    │
│  ├── JSON-RPC                                                                   │
│  ├── Apache Thrift                                                              │
│  ├── Cap'n Proto RPC                                                            │
│  └── Custom TCP/UDP                                                             │
│                                                                                 │
│  ASYNCHRONOUS (Fire-and-Forget / Event-Driven)                                 │
│  ├── Message Queues                                                             │
│  │   ├── RabbitMQ (AMQP)                                                        │
│  │   ├── Apache Kafka                                                           │
│  │   ├── Redis Streams                                                          │
│  │   ├── NATS                                                                   │
│  │   ├── Amazon SQS                                                             │
│  │   └── ZeroMQ                                                                 │
│  ├── Pub/Sub (Topic-based)                                                      │
│  │   ├── Redis Pub/Sub                                                          │
│  │   ├── NATS Pub/Sub                                                           │
│  │   ├── Google Pub/Sub                                                         │
│  │   └── Apache Pulsar                                                          │
│  └── Event Sourcing / CQRS                                                      │
│                                                                                 │
│  REAL-TIME (Bidirectional)                                                      │
│  ├── WebSocket                                                                  │
│  ├── Server-Sent Events (SSE)                                                   │
│  ├── Socket.IO                                                                  │
│  ├── WebRTC (P2P)                                                               │
│  ├── WebTransport                                                               │
│  └── SignalR                                                                    │
│                                                                                 │
│  IoT / MESH                                                                     │
│  ├── MQTT (lightweight pub/sub)                                                 │
│  ├── CoAP (constrained devices)                                                 │
│  ├── LoRaWAN (long-range IoT)                                                   │
│  └── Zigbee / Z-Wave (home automation)                                          │
│                                                                                 │
│  LOCAL / IPC                                                                    │
│  ├── Unix Domain Sockets                                                        │
│  ├── Named Pipes                                                                │
│  ├── Shared Memory                                                              │
│  └── Unix Signals                                                               │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

### GraphQL (Schema-First APIs)

**When to use:**
- Complex data relationships (nested objects)
- Multiple clients with different data needs
- Mobile apps needing minimal data transfer
- API gateway aggregating multiple services

**When NOT to use:**
- Simple CRUD (REST is simpler)
- File-heavy APIs
- Real-time streaming (use subscriptions + WebSocket)
- Team unfamiliar with GraphQL

```python
# Domain Port
# domain/ports/graphql_service.py
from typing import Protocol, Any

class GraphQLPort(Protocol):
    async def execute(self, query: str, variables: dict | None = None) -> dict: ...
    async def introspect(self) -> dict: ...

# Adapters
# adapters/http/graphql.py
import strawberry
from strawberry.fastapi import GraphQLRouter

@strawberry.type
class User:
    id: str
    email: str
    name: str
    role: str

@strawberry.type
class Query:
    @strawberry.field
    async def user(self, id: str) -> User:
        # Call domain workflow
        ...

    @strawberry.field
    async def users(self, offset: int = 0, limit: int = 20) -> list[User]:
        # Call domain workflow
        ...

schema = strawberry.Schema(query=Query)
graphql_app = GraphQLRouter(schema)

# main.py
app.include_router(graphql_app, prefix="/graphql")
```

---

### Message Queues (Async Processing)

**When to use:**
- Background jobs (emails, reports, notifications)
- Decoupling services (producer/consumer)
- Workload spikes (buffering)
- Reliable delivery (at-least-once, exactly-once)
- Cross-service communication without coupling

**When NOT to use:**
- Simple request-response (use REST)
- Real-time (use WebSocket)
- Low-latency requirements (< 100ms)

#### RabbitMQ (AMQP)

```python
# adapters/messaging/rabbitmq.py
import aio_pika
from domain.ports.message_queue import MessageQueuePort

class RabbitMQAdapter:
    def __init__(self, url: str) -> None:
        self._url = url
        self._connection: aio_pika.Connection | None = None
        self._channel: aio_pika.Channel | None = None

    async def connect(self) -> None:
        self._connection = await aio_pika.connect_robust(self._url)
        self._channel = await self._connection.channel()

    async def publish(self, queue: str, message: dict, delay_ms: int = 0) -> None:
        await self._channel.default_exchange.publish(
            aio_pika.Message(body=str(message).encode()),
            routing_key=queue,
        )

    async def consume(self, queue: str, handler) -> None:
        q = await self._channel.declare_queue(queue, durable=True)
        async with q.iterator() as q_iter:
            async for message in q_iter:
                async with message.process():
                    await handler(message.body.decode())

    async def close(self) -> None:
        if self._connection:
            await self._connection.close()

# Domain Port
# domain/ports/message_queue.py
from typing import Protocol, Callable, Any

class MessageQueuePort(Protocol):
    async def publish(self, queue: str, message: dict, delay_ms: int = 0) -> None: ...
    async def consume(self, queue: str, handler: Callable[[str], Any]) -> None: ...
```

#### Kafka (Event Streaming)

```python
# adapters/messaging/kafka.py
from aiokafka import AIOKafkaProducer, AIOKafkaConsumer
from domain.ports.event_stream import EventStreamPort

class KafkaAdapter:
    def __init__(self, bootstrap_servers: str, group_id: str) -> None:
        self._servers = bootstrap_servers
        self._group_id = group_id
        self._producer: AIOKafkaProducer | None = None

    async def connect(self) -> None:
        self._producer = AIOKafkaProducer(bootstrap_servers=self._servers)
        await self._producer.start()

    async def publish(self, topic: str, key: str, value: dict) -> None:
        await self._producer.send_and_wait(
            topic, key=key.encode(), value=str(value).encode(),
        )

    async def subscribe(self, topic: str, handler) -> None:
        consumer = AIOKafkaConsumer(
            topic, bootstrap_servers=self._servers,
            group_id=self._group_id,
        )
        await consumer.start()
        async for msg in consumer:
            await handler(msg.key.decode(), msg.value.decode())

    async def close(self) -> None:
        if self._producer:
            await self._producer.stop()

# Domain Port
# domain/ports/event_stream.py
from typing import Protocol, Callable, Any

class EventStreamPort(Protocol):
    async def publish(self, topic: str, key: str, value: dict) -> None: ...
    async def subscribe(self, topic: str, handler: Callable[[str, str], Any]) -> None: ...
```

#### Redis Streams (Lightweight Event Sourcing)

```python
# adapters/messaging/redis_streams.py
import json
import redis.asyncio as redis
from domain.ports.event_store import EventStorePort

class RedisStreamsAdapter:
    def __init__(self, url: str = "redis://localhost") -> None:
        self._redis = redis.from_url(url)

    async def publish(self, stream: str, event: dict, id: str = "*") -> str:
        return await self._redis.xadd(stream, {"data": json.dumps(event)}, id=id)

    async def read(self, stream: str, count: int = 10) -> list[dict]:
        messages = await self._redis.xread({stream: "0"}, count=count)
        return [
            {"id": msg_id, "data": json.loads(data["data"])}
            for stream_name, msgs in messages
            for msg_id, data in msgs
        ]

    async def read_group(self, stream: str, group: str, consumer: str) -> list[dict]:
        try:
            await self._redis.xgroup_create(stream, group, id="0", mkstream=True)
        except redis.ResponseError:
            pass
        messages = await self._redis.xreadgroup(group, consumer, {stream: ">"}, count=1)
        return [
            {"id": msg_id, "data": json.loads(data["data"])}
            for stream_name, msgs in messages
            for msg_id, data in msgs
        ]

# Domain Port
# domain/ports/event_store.py
from typing import Protocol

class EventStorePort(Protocol):
    async def publish(self, stream: str, event: dict) -> str: ...
    async def read(self, stream: str, count: int = 10) -> list[dict]: ...
    async def read_group(self, stream: str, group: str, consumer: str) -> list[dict]: ...
```

#### ZeroMQ (High-Performance Messaging Library)

```python
# adapters/messaging/zeromq.py
import zmq
import zmq.asyncio
import json
from domain.ports.message_bus import MessageBusPort

class ZeroMQAdapter:
    """ZeroMQ patterns: PUB/SUB, REQ/REP, PUSH/PULL."""
    
    def __init__(self) -> None:
        self._context = zmq.asyncio.Context()

    # PUB/SUB Pattern (broadcasting)
    async def pub_bind(self, address: str) -> None:
        socket = self._context.socket(zmq.PUB)
        socket.bind(address)
        return socket

    async def sub_connect(self, address: str, topics: list[str] = None) -> None:
        socket = self._context.socket(zmq.SUB)
        socket.connect(address)
        for topic in topics or [""]:
            socket.subscribe(topic.encode())
        return socket

    # REQ/REP Pattern (request-reply)
    async def req_rep(self, address: str, request: dict) -> dict:
        socket = self._context.socket(zmq.REQ)
        socket.connect(address)
        await socket.send_json(request)
        response = await socket.recv_json()
        socket.close()
        return response

    # PUSH/PULL Pattern (work distribution)
    async def push_bind(self, address: str) -> None:
        socket = self._context.socket(zmq.PUSH)
        socket.bind(address)
        return socket

    async def pull_connect(self, address: str, handler) -> None:
        socket = self._context.socket(zmq.PULL)
        socket.connect(address)
        while True:
            msg = await socket.recv_json()
            await handler(msg)

    async def close(self) -> None:
        self._context.term()

# Domain Port
# domain/ports/message_bus.py
from typing import Protocol, Callable, Any

class MessageBusPort(Protocol):
    async def publish(self, topic: str, message: dict) -> None: ...
    async def subscribe(self, topic: str, handler: Callable[[dict], Any]) -> None: ...
    async def request(self, service: str, message: dict) -> dict: ...
```

---

### WebRTC (Peer-to-Peer)

**When to use:**
- Video/audio calling
- File sharing between peers
- Low-latency P2P data
- Gaming (real-time state sync)

**When NOT to use:**
- Server-client communication (use WebSocket)
- Simple messaging (use REST)
- Broadcast to many (use SSE)

```python
# adapters/webrtc/signaling.py
from fastapi import WebSocket
from aiortc import RTCPeerConnection, RTCSessionMessage
import json

class WebRTCSignalingServer:
    """WebRTC signaling server via WebSocket."""
    
    def __init__(self) -> None:
        self._peers: dict[str, WebSocket] = {}
        self._pcs: dict[str, RTCPeerConnection] = {}

    async def handle_signaling(self, ws: WebSocket, peer_id: str):
        await ws.accept()
        self._peers[peer_id] = ws
        
        try:
            while True:
                data = await ws.receive_json()
                
                if data["type"] == "offer":
                    # Create peer connection
                    pc = RTCPeerConnection()
                    self._pcs[peer_id] = pc
                    
                    offer = RTCSessionDescription(
                        sdp=data["sdp"], type=data["type"]
                    )
                    await pc.setRemoteDescription(offer)
                    
                    # Create answer
                    answer = await pc.createAnswer()
                    await pc.setLocalDescription(answer)
                    
                    await ws.send_json({
                        "type": "answer",
                        "sdp": pc.localDescription.sdp,
                    })
                
                elif data["type"] == "answer":
                    pc = self._pcs.get(peer_id)
                    if pc:
                        answer = RTCSessionDescription(
                            sdp=data["sdp"], type=data["type"]
                        )
                        await pc.setRemoteDescription(answer)
                
                elif data["type"] == "candidate":
                    pc = self._pcs.get(peer_id)
                    if pc:
                        candidate = RTCIceCandidate(
                            component=data["candidate"]["component"],
                            foundation=data["candidate"]["foundation"],
                            ip=data["candidate"]["ip"],
                            port=data["candidate"]["port"],
                            priority=data["candidate"]["priority"],
                            protocol=data["candidate"]["protocol"],
                            type=data["candidate"]["type"],
                        )
                        await pc.addIceCandidate(candidate)
        
        except Exception:
            await self._cleanup(peer_id)

    async def _cleanup(self, peer_id: str):
        self._peers.pop(peer_id, None)
        pc = self._pcs.pop(peer_id, None)
        if pc:
            await pc.close()
```

---

### MQTT (IoT / Lightweight Pub/Sub)

**When to use:**
- IoT devices (sensors, actuators)
- Low-bandwidth networks
- Battery-constrained devices
- Home automation
- Telemetry collection

**When NOT to use:**
- High-throughput data (use Kafka)
- Complex routing (use RabbitMQ)
- Web browsers (use WebSocket)

```python
# adapters/iot/mqtt_client.py
import asyncio
import json
from typing import Callable
import paho.mqtt.client as mqtt
from domain.ports.iot_gateway import IoTGatewayPort

class MQTTAdapter:
    def __init__(self, broker: str, port: int = 1883, client_id: str = "") -> None:
        self._client = mqtt.Client(client_id=client_id)
        self._broker = broker
        self._port = port
        self._handlers: dict[str, Callable] = {}

    def on_connect(self, client, userdata, flags, rc):
        print(f"Connected to MQTT broker with code {rc}")
        # Resubscribe on reconnect
        for topic in self._handlers:
            client.subscribe(topic)

    def on_message(self, client, userdata, msg):
        handler = self._handlers.get(msg.topic)
        if handler:
            payload = json.loads(msg.payload.decode())
            handler(msg.topic, payload)

    async def connect(self) -> None:
        self._client.on_connect = self.on_connect
        self._client.on_message = self.on_message
        self._client.connect(self._broker, self._port)
        self._client.loop_start()

    async def subscribe(self, topic: str, handler: Callable) -> None:
        self._handlers[topic] = handler
        self._client.subscribe(topic)

    async def publish(self, topic: str, payload: dict) -> None:
        self._client.publish(topic, json.dumps(payload))

    async def close(self) -> None:
        self._client.loop_stop()
        self._client.disconnect()

# Domain Port
# domain/ports/iot_gateway.py
from typing import Protocol, Callable

class IoTGatewayPort(Protocol):
    async def subscribe(self, topic: str, handler: Callable) -> None: ...
    async def publish(self, topic: str, payload: dict) -> None: ...
```

---

### CoAP (Constrained Devices)

```python
# adapters/iot/coap_server.py
from aiocoap import Context, Message, GET, POST
import json

class CoAPServerAdapter:
    """CoAP for constrained IoT devices (RFC 7252)."""
    
    def __init__(self) -> None:
        self._context: Context | None = None

    async def start(self, port: int = 5683) -> None:
        self._context = await Context.create_server_context(port=port)

    async def add_resource(self, path: str, handler) -> None:
        resource = CoAPResource(handler)
        self._context.add_resource((path,), resource)

    async def close(self) -> None:
        if self._context:
            self._context.shutdown()

class CoAPResource:
    def __init__(self, handler) -> None:
        self._handler = handler

    async def render_get(self, request: Message) -> Message:
        data = await self._handler("GET", {})
        return Message(
            content_format=50,  # application/json
            payload=json.dumps(data).encode(),
        )

    async def render_post(self, request: Message) -> Message:
        payload = json.loads(request.payload.decode())
        data = await self._handler("POST", payload)
        return Message(
            content_format=50,
            payload=json.dumps(data).encode(),
            code="2.01",
        )
```

---

### Unix Domain Sockets (IPC)

```python
# adapters/ipc/unix_socket.py
import asyncio
import json
from pathlib import Path
from domain.ports.ipc_channel import IPCPort

class UnixSocketAdapter:
    """Inter-process communication via Unix domain sockets."""
    
    def __init__(self, socket_path: str) -> None:
        self._path = Path(socket_path)
        self._server: asyncio.AbstractServer | None = None

    async def start_server(self, handler) -> None:
        self._server = await asyncio.start_unix_server(
            handler, path=str(self._path)
        )

    async def send(self, message: dict) -> dict:
        reader, writer = await asyncio.open_unix_connection(path=str(self._path))
        writer.write(json.dumps(message).encode())
        await writer.drain()
        
        data = await reader.read(1024 * 1024)  # 1MB max
        writer.close()
        return json.loads(data.decode())

    async def close(self) -> None:
        if self._server:
            self._server.close()
            await self._server.wait_closed()
        self._path.unlink(missing_ok=True)

# Domain Port
# domain/ports/ipc_channel.py
from typing import Protocol, Callable, Any

class IPCPort(Protocol):
    async def send(self, message: dict) -> dict: ...
    async def receive(self, handler: Callable[[dict], dict]) -> None: ...
```

---

### Named Pipes (Windows/POSIX)

```python
# adapters/ipc/named_pipe.py
import os
import asyncio
from pathlib import Path
from domain.ports.ipc_channel import IPCPort

class NamedPipeAdapter:
    """Named pipe IPC for cross-platform local communication."""
    
    def __init__(self, pipe_name: str) -> None:
        self._pipe_path = f"/tmp/{pipe_name}" if os.name != "nt" else f"\\\\.\\pipe\\{pipe_name}"

    async def create_server(self, handler) -> None:
        os.mkfifo(self._pipe_path, 0o666)
        
        while True:
            with open(self._pipe_path, "r") as pipe:
                data = pipe.read()
                if data:
                    response = await handler(data)
                    with open(self._pipe_path, "w") as out:
                        out.write(response)

    async def send(self, message: str) -> str:
        with open(self._pipe_path, "w") as pipe:
            pipe.write(message)
        
        with open(self._pipe_path, "r") as pipe:
            return pipe.read()
```

---

### Socket.IO (Fallback + Auto-Reconnect)

```python
# adapters/http/socketio.py
import socketio
from domain.ports.realtime import RealtimePort

class SocketIOAdapter:
    def __init__(self) -> None:
        self._sio = socketio.AsyncServer(
            async_mode="asgi",
            cors_allowed_origins="*",
        )
        self._app = socketio.ASGIApp(self._sio)

    def on(self, event: str, handler):
        self._sio.on(event, handler)

    async def emit(self, event: str, data: dict, room: str | None = None) -> None:
        await self._sio.emit(event, data, room=room)

    async def enter_room(self, sid: str, room: str) -> None:
        await self._sio.enter_room(sid, room)

    def get_app(self):
        return self._app

# Usage
sio_adapter = SocketIOAdapter()

@sio_adapter.on("connect")
async def handle_connect(sid, environ):
    print(f"Client {sid} connected")

@sio_adapter.on("message")
async def handle_message(sid, data):
    await sio_adapter.emit("message", {"text": data["text"]}, room=sid)

# main.py
app = FastAPI()
app.mount("/socket.io", sio_adapter.get_app())
```

---

### Event Sourcing + CQRS Pattern

```python
# domain/models/events.py
from dataclasses import dataclass
from datetime import datetime
from typing import Any
from enum import StrEnum

class EventType(StrEnum):
    USER_CREATED = "user.created"
    USER_UPDATED = "user.updated"
    USER_DELETED = "user.deleted"
    ORDER_PLACED = "order.placed"
    ORDER_SHIPPED = "order.shipped"

@dataclass(frozen=True)
class DomainEvent:
    event_type: EventType
    aggregate_id: str
    payload: dict
    timestamp: datetime
    version: int
    metadata: dict = {}

# domain/ports/event_store.py
from typing import Protocol

class EventStorePort(Protocol):
    async def append(self, event: DomainEvent) -> None: ...
    async def get_events(self, aggregate_id: str, from_version: int = 0) -> list[DomainEvent]: ...
    async def get_all_events(self, from_offset: int = 0, limit: int = 100) -> list[DomainEvent]: ...
    async def subscribe(self, event_type: EventType, handler) -> None: ...

# adapters/event_store/postgres_event_store.py
class PostgresEventStore:
    async def append(self, event: DomainEvent) -> None:
        await self._pool.execute(
            """INSERT INTO events (event_type, aggregate_id, payload, timestamp, version, metadata)
               VALUES ($1, $2, $3, $4, $5, $6)""",
            event.event_type, event.aggregate_id,
            json.dumps(event.payload), event.timestamp,
            event.version, json.dumps(event.metadata),
        )

    async def get_events(self, aggregate_id: str, from_version: int = 0) -> list[DomainEvent]:
        rows = await self._pool.fetch(
            "SELECT * FROM events WHERE aggregate_id = $1 AND version > $2 ORDER BY version",
            aggregate_id, from_version,
        )
        return [DomainEvent(**dict(r)) for r in rows]

# domain/workflows/rebuild_state.py
def rebuild_user_state(events: list[DomainEvent]) -> dict:
    """Pure function — rebuild aggregate state from events."""
    state = {}
    for event in events:
        if event.event_type == EventType.USER_CREATED:
            state = event.payload
        elif event.event_type == EventType.USER_UPDATED:
            state.update(event.payload)
        elif event.event_type == EventType.USER_DELETED:
            state = None
    return state

# Read Model (CQRS)
# adapters/read_model/user_read_model.py
class UserReadModel:
    """Denormalized read model for queries."""
    
    async def get_user(self, user_id: str) -> dict | None:
        row = await self._pool.fetchrow(
            "SELECT * FROM user_read WHERE id = $1", user_id,
        )
        return dict(row) if row else None

    async def update_from_event(self, event: DomainEvent) -> None:
        if event.event_type == EventType.USER_CREATED:
            await self._pool.execute(
                "INSERT INTO user_read (id, email, name) VALUES ($1, $2, $3)",
                event.aggregate_id, event.payload["email"], event.payload["name"],
            )
        elif event.event_type == EventType.USER_UPDATED:
            await self._pool.execute(
                "UPDATE user_read SET email = $1, name = $2 WHERE id = $3",
                event.payload.get("email"), event.payload.get("name"), event.aggregate_id,
            )
```

---

### WebTransport (HTTP/3 Based)

```python
# adapters/transport/webtransport.py
from webtransport import WebTransportSession
import json

class WebTransportAdapter:
    """WebTransport for low-latency, multiplexed streams."""
    
    def __init__(self) -> None:
        self._sessions: dict[str, WebTransportSession] = {}

    async def handle_session(self, session: WebTransportSession, session_id: str):
        self._sessions[session_id] = session
        try:
            async for datagram in session.datagrams:
                data = json.loads(datagram)
                await self.handle_message(session_id, data)
        except Exception:
            self._sessions.pop(session_id, None)

    async def send_datagram(self, session_id: str, data: dict) -> None:
        session = self._sessions.get(session_id)
        if session:
            await session.send_datagram(json.dumps(data).encode())

    async def open_stream(self, session_id: str):
        session = self._sessions.get(session_id)
        if session:
            return await session.open_stream()
        return None
```

---

### Comparison Matrix (Updated)

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                    PROTOCOL COMPARISON — FULL SPECTRUM                              │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  Protocol        Latency      Throughput   Contract    Browser   Complexity  Use    │
│  ──────────────  ───────────  ───────────  ──────────  ────────  ──────────  ────   │
│  REST            ~10-50ms     Moderate     OpenAPI     ✓         Low         CRUD   │
│  gRPC            ~1-5ms       High         Protobuf    ✗(proxy)  Medium      RPC    │
│  GraphQL         ~10-50ms     Moderate     Schema      ✓         Medium      Query  │
│  WebSocket       ~1-10ms      High         None        ✓         Medium      RT     │
│  SSE             ~10-50ms     Low          None        ✓         Low         Stream │
│  Socket.IO       ~1-10ms      High         None        ✓         Low         RT     │
│  WebRTC          ~0.5-5ms     High         None        ✓         High        P2P    │
│  WebTransport    ~1-5ms       High         None        ✓         High        RT     │
│  MQTT            ~5-50ms      Low          Topic       ✗         Low         IoT    │
│  CoAP            ~10-100ms    Very Low     None        ✗         Low         IoT    │
│  RabbitMQ        ~5-50ms      High         Schema      ✗         Medium      Async  │
│  Kafka           ~5-20ms      Very High    Schema      ✗         Medium      Stream │
│  Redis Streams   ~1-5ms       High         None        ✗         Low         Event  │
│  ZeroMQ          ~0.1-1ms     Very High    None        ✗         Medium      IPC    │
│  NATS            ~1-5ms       Very High    None        ✗         Low         Async  │
│  Unix Sockets    ~0.01ms      Very High    None        ✗         Low         IPC    │
│  Named Pipes     ~0.01ms      Very High    None        ✗         Low         IPC    │
│                                                                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  ARCHITECTURE PATTERNS:                                                             │
│                                                                                     │
│  ┌──────────────────────┬─────────────────────────────────────────────────────────┐ │
│  │ Pattern              │ Description                                             │ │
│  ├──────────────────────┼─────────────────────────────────────────────────────────┤ │
│  │ Request-Response     │ Client sends request, waits for response                │ │
│  │ Pub/Sub              │ Decoupled publishers/subscribers via topics             │ │
│  │ Event Streaming      │ Ordered, durable event log (Kafka, Redis Streams)      │ │
│  │ Message Queue        │ Point-to-point, reliable delivery                       │ │
│  │ Event Sourcing       │ State rebuilt from event history                        │ │
│  │ CQRS                 │ Separate read/write models                              │ │
│  │ Saga                 │ Distributed transactions via events                     │ │
│  │ Outbox               │ Reliable event publishing with DB                      │ │
│  │ Circuit Breaker      │ Fault tolerance for external services                  │ │
│  │ Sidecar              │ Co-located helper process (service mesh)               │ │
│  └──────────────────────┴─────────────────────────────────────────────────────────┘ │
│                                                                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  DECISION FLOWCHART:                                                                │
│                                                                                     │
│                          ┌─────────────────────┐                                   │
│                          │ Need communication? │                                   │
│                          └──────────┬──────────┘                                   │
│                                     │                                               │
│                    ┌────────────────┼────────────────┐                              │
│                    ▼                ▼                ▼                              │
│            ┌──────────┐      ┌──────────┐      ┌──────────┐                        │
│            │ Sync?    │      │ Async?   │      │ Real-time?│                        │
│            └────┬─────┘      └────┬─────┘      └────┬─────┘                        │
│                 │                 │                  │                              │
│        ┌────────┴────────┐   ┌────┴────┐      ┌────┴────┐                         │
│        ▼                 ▼   ▼         ▼      ▼         ▼                         │
│   ┌─────────┐     ┌────────┐ ┌──────┐ ┌──────┐ ┌──────────┐                      │
│   │Simple?  │     │Complex?│ │Queue?│ │Event?│ │Browser?  │                      │
│   └────┬────┘     └───┬────┘ └──┬───┘ └──┬───┘ └────┬─────┘                      │
│        │              │         │        │           │                              │
│        ▼              ▼         ▼        ▼           ▼                              │
│    ┌──────┐     ┌──────────┐ ┌──────┐ ┌───────┐ ┌────────┐                        │
│    │ REST │     │ gRPC     │ │Rabbit│ │Kafka  │ │WS/SSE  │                        │
│    └──────┘     └──────────┘ │MQ    │ └───────┘ └────────┘                        │
│                              └──────┘                                               │
│                                                                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  COMBINATION ARCHITECTURES:                                                         │
│                                                                                     │
│  ┌─────────────────┬───────────────────────────────────────────────────────────┐   │
│  │ Scenario        │ Architecture                                             │   │
│  ├─────────────────┼───────────────────────────────────────────────────────────┤   │
│  │ SaaS API        │ REST + WebSocket + SSE + PostgreSQL                      │   │
│  │ Microservices   │ gRPC (internal) + REST (gateway) + Kafka + Redis        │   │
│  │ Chat App        │ WebSocket + Redis Pub/Sub + PostgreSQL + S3             │   │
│  │ IoT Platform    │ MQTT + Kafka + PostgreSQL + WebSocket (dashboard)       │   │
│  │ E-commerce      │ REST + RabbitMQ (orders) + SSE (updates) + PostgreSQL   │   │
│  │ Gaming          │ WebSocket (state) + gRPC (matchmaking) + Redis          │   │
│  │ Financial       │ gRPC (low latency) + Kafka (events) + PostgreSQL        │   │
│  │ Analytics       │ REST (ingest) + Kafka (buffer) + ClickHouse (storage)   │   │
│  │ Social Feed     │ GraphQL (API) + WebSocket (notifications) + Redis       │   │
│  └─────────────────┴───────────────────────────────────────────────────────────┘   │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

### Anti-Patterns (Expanded)

| Anti-Pattern | Why Bad | Better Approach |
|--------------|---------|-----------------|
| REST for streaming | HTTP overhead, no real-time | WebSocket, SSE, or gRPC streams |
| gRPC for public API | Browser needs proxy, harder to debug | REST with OpenAPI |
| WebSocket for CRUD | Complexity without benefit | REST |
| Polling for real-time | Wasteful, high latency | WebSocket, SSE, or MQTT |
| Kafka for simple tasks | Overkill, operational overhead | RabbitMQ or Redis Streams |
| RabbitMQ for event sourcing | No ordering guarantees | Kafka or Redis Streams |
| MQTT for high-throughput | Low bandwidth, not designed for it | Kafka or NATS |
| Shared DB for microservices | Tight coupling, single point of failure | Events via message queue |
| Sync calls in sagas | Cascading failures, latency | Async with compensation |
| Missing dead letter queue | Failed messages lost | Always add DLQ for queues |
| No idempotency on consumers | Duplicate processing | Idempotent handlers |
| No backpressure handling | System overload | Queue limits, rate limiting |

---

## Request Flow Diagram

```
HTTP Request
  │
  ▼
FastAPI Route (driving adapter)
  │  ├─ Extract correlation ID
  │  ├─ Validate via Pydantic schema (DTO)
  │  ├─ Resolve dependencies (port implementations)
  │  │
  ▼
Workflow (pure function)
  │  ├─ Business validation
  │  ├─ Call driven adapter via port
  │  │
  ▼
Driven Adapter (repository, API client)
  │  ├─ Execute I/O
  │  ├─ Map to domain model
  │  │
  ▼
Workflow returns domain model
  │
  ▼
FastAPI Route converts to Pydantic response (DTO)
  │
  ▼
HTTP Response (JSON + correlation ID header)
```

## Key Rules

| Rule | How |
|------|-----|
| Domain imports zero frameworks | No `fastapi`, `pydantic`, `sqlalchemy` in `domain/` |
| DTOs stay in adapters | Pydantic schemas in `adapters/http/schemas/`, not in domain |
| All errors are AppError | Every exception carries code, message, context, cause, origin |
| Composition root is thin | Only wiring — no business logic in `main.py` or `wire_adapters.py` |
| Async ports when needed | `AsyncProtocol` for I/O-bound driven adapters (Postgres, Redis) |
| Sync workflows preferred | Keep domain workflows synchronous; async only at adapter boundary |
| Lifespan manages lifecycle | Startup creates adapters, shutdown cleans up — no global state |
| Correlation ID everywhere | Every request gets an ID, threaded through logs and errors |
| Test at the lowest tier | Unit tests for domain + pure helpers, e2e for full API surface |
| Portable adapters | Adapter files copy to any project — only port contracts and config change |

## Authentication & Authorization (JWT + OAuth2)

### Domain Models & Ports

```python
# domain/models/auth.py
from dataclasses import dataclass
from datetime import datetime

@dataclass(frozen=True)
class TokenPayload:
    sub: str  # user_id
    exp: datetime
    scopes: list[str] = []

@dataclass(frozen=True)
class AuthResult:
    user_id: str
    scopes: list[str]

# domain/ports/auth_service.py
from typing import Protocol
from domain.models.auth import TokenPayload

class AuthServicePort(Protocol):
    def create_access_token(self, user_id: str, scopes: list[str] | None = None) -> str: ...
    def decode_token(self, token: str) -> TokenPayload: ...

# domain/ports/password_hasher.py
from typing import Protocol

class PasswordHasherPort(Protocol):
    def hash(self, password: str) -> str: ...
    def verify(self, password: str, hashed: str) -> bool: ...
```

### JWT Adapter (Minimal — No Extra Libs)

```python
# adapters/auth/jwt_service.py
import json
import hmac
import hashlib
import time
import base64
from domain.models.auth import TokenPayload
from infra.config import settings

class MinimalJWTService:
    """Lightweight JWT implementation using stdlib only."""
    
    def __init__(self, secret: str, algorithm: str = "HS256") -> None:
        self._secret = secret.encode()
        self._algorithm = algorithm

    def create_access_token(self, user_id: str, scopes: list[str] | None = None) -> str:
        payload = TokenPayload(
            sub=user_id,
            exp=time.time() + settings.jwt_expiration_seconds,
            scopes=scopes or [],
        )
        return self._encode(payload)

    def decode_token(self, token: str) -> TokenPayload:
        header, payload_b64, signature = token.split(".")
        
        # Verify signature
        expected_sig = self._sign(f"{header}.{payload_b64}")
        if not hmac.compare_digest(signature, expected_sig):
            raise ValueError("Invalid token signature")
        
        # Decode payload
        payload_json = base64.urlsafe_b64decode(payload_b64 + "==")
        data = json.loads(payload_json)
        
        # Check expiration
        if data["exp"] < time.time():
            raise ValueError("Token expired")
        
        return TokenPayload(**data)

    def _encode(self, payload: TokenPayload) -> str:
        header = base64.urlsafe_b64encode(
            json.dumps({"alg": self._algorithm, "typ": "JWT"}).encode()
        ).rstrip(b"=").decode()
        
        payload_b64 = base64.urlsafe_b64encode(
            json.dumps({
                "sub": payload.sub,
                "exp": payload.exp,
                "scopes": payload.scopes,
            }).encode()
        ).rstrip(b"=").decode()
        
        signature = self._sign(f"{header}.{payload_b64}")
        return f"{header}.{payload_b64}.{signature}"

    def _sign(self, data: str) -> str:
        return base64.urlsafe_b64encode(
            hmac.new(self._secret, data.encode(), hashlib.sha256).digest()
        ).rstrip(b"=").decode()
```

### Password Hashing (Minimal — stdlib)

```python
# adapters/auth/password_hasher.py
import hashlib
import secrets
from domain.ports.password_hasher import PasswordHasherPort

class MinimalPasswordHasher:
    """PBKDF2-based password hashing using stdlib."""
    
    def __init__(self, iterations: int = 260000) -> None:
        self._iterations = iterations

    def hash(self, password: str) -> str:
        salt = secrets.token_hex(16)
        dk = hashlib.pbkdf2_hmac(
            "sha256", password.encode(), salt.encode(), self._iterations
        )
        return f"{salt}${dk.hex()}"

    def verify(self, password: str, hashed: str) -> bool:
        salt, stored_hash = hashed.split("$")
        dk = hashlib.pbkdf2_hmac(
            "sha256", password.encode(), salt.encode(), self._iterations
        )
        return hmac.compare_digest(dk.hex(), stored_hash)
```

### FastAPI Auth Dependencies

```python
# adapters/http/dependencies_auth.py
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

from adapters.auth.jwt_service import MinimalJWTService
from adapters.auth.password_hasher import MinimalPasswordHasher
from domain.models.auth import TokenPayload
from infra.config import settings

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/token")

_jwt_service = MinimalJWTService(secret=settings.jwt_secret)
_password_hasher = MinimalPasswordHasher()

def get_jwt_service() -> MinimalJWTService:
    return _jwt_service

def get_password_hasher() -> MinimalPasswordHasher:
    return _password_hasher

async def get_current_user(
    token: str = Depends(oauth2_scheme),
) -> TokenPayload:
    try:
        payload = _jwt_service.decode_token(token)
        return payload
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "AUTH-001", "message": str(e)},
            headers={"WWW-Authenticate": "Bearer"},
        )

def require_scopes(*required_scopes: str):
    """Dependency factory: require specific OAuth2 scopes."""
    async def scope_checker(
        user: TokenPayload = Depends(get_current_user),
    ) -> TokenPayload:
        if not all(scope in user.scopes for scope in required_scopes):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={"code": "AUTH-002", "message": "Insufficient permissions"},
            )
        return user
    return scope_checker
```

### Auth Routes

```python
# adapters/http/routes/auth.py
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm

from adapters.http.dependencies_auth import get_jwt_service, get_password_hasher
from adapters.http.schemas.auth import TokenResponse, RegisterRequest

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/token", response_model=TokenResponse)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    jwt_service = Depends(get_jwt_service),
    password_hasher = Depends(get_password_hasher),
):
    # In real app: fetch user from repository
    # user = user_repo.find_by_email(form_data.username)
    # if not user or not password_hasher.verify(form_data.password, user.password_hash):
    #     raise HTTPException(status_code=401, detail="Invalid credentials")
    
    token = jwt_service.create_access_token(
        user_id="user-123",  # user.id
        scopes=["read", "write"],
    )
    return TokenResponse(access_token=token, token_type="bearer")

@router.post("/register", status_code=201)
async def register(
    body: RegisterRequest,
    password_hasher = Depends(get_password_hasher),
    jwt_service = Depends(get_jwt_service),
):
    # In real app: check for duplicate, save user
    hashed = password_hasher.hash(body.password)
    token = jwt_service.create_access_token(user_id="new-user", scopes=["read"])
    return TokenResponse(access_token=token, token_type="bearer")
```

### Protected Route Example

```python
# adapters/http/routes/users.py
from adapters.http.dependencies_auth import get_current_user, require_scopes
from domain.models.auth import TokenPayload

@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(
    user: TokenPayload = Depends(get_current_user),
):
    """Requires valid JWT token."""
    # Use user.sub (user_id) to fetch from repository
    return UserResponse(id=user.sub, email="...", name="...")

@router.delete("/{user_id}", status_code=204)
async def delete_user(
    user_id: str,
    user: TokenPayload = Depends(require_scopes("admin")),
):
    """Requires 'admin' scope."""
    # Delete user logic here
    pass
```

### Pydantic Schemas for Auth

```python
# adapters/http/schemas/auth.py
from pydantic import BaseModel, EmailStr

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    name: str
```

### Config for Auth

```python
# infra/config.py (add these fields)
class Settings(BaseSettings):
    # ... existing fields ...
    jwt_secret: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    jwt_expiration_seconds: int = 3600  # 1 hour
```

---

## stdlib Logging Adapter

```python
# adapters/logging/logger_adapter.py
import logging
import json
import sys
from datetime import datetime, timezone
from domain.ports.logger import LoggerPort

class StdlibJSONLogger:
    """Structured JSON logging using stdlib."""
    
    def __init__(self, name: str = "app", level: str = "INFO") -> None:
        self._logger = logging.getLogger(name)
        self._logger.setLevel(getattr(logging, level.upper()))
        
        if not self._logger.handlers:
            handler = logging.StreamHandler(sys.stdout)
            handler.setFormatter(self._JsonFormatter())
            self._logger.addHandler(handler)

    def info(self, message: str, **fields) -> None:
        self._logger.info(message, extra={"structured": fields})

    def error(self, message: str, **fields) -> None:
        self._logger.error(message, extra={"structured": fields})

    def warning(self, message: str, **fields) -> None:
        self._logger.warning(message, extra={"structured": fields})

    def debug(self, message: str, **fields) -> None:
        self._logger.debug(message, extra={"structured": fields})

    class _JsonFormatter(logging.Formatter):
        def format(self, record: logging.LogRecord) -> str:
            log_entry = {
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "level": record.levelname,
                "logger": record.name,
                "message": record.getMessage(),
            }
            if hasattr(record, "structured"):
                log_entry["fields"] = record.structured
            if record.exc_info:
                log_entry["exception"] = self.formatException(record.exc_info)
            return json.dumps(log_entry)
```

### Domain Port Update

```python
# domain/ports/logger.py
from typing import Protocol

class LoggerPort(Protocol):
    def info(self, message: str, **fields) -> None: ...
    def error(self, message: str, **fields) -> None: ...
    def warning(self, message: str, **fields) -> None: ...
    def debug(self, message: str, **fields) -> None: ...
```

### Middleware Integration

```python
# adapters/http/middleware.py (add logging middleware)
class RequestLoggingMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, logger: LoggerPort) -> None:
        super().__init__(app)
        self._logger = logger

    async def dispatch(self, request: Request, call_next):
        start = time.perf_counter()
        response = await call_next(request)
        duration_ms = (time.perf_counter() - start) * 1000
        
        self._logger.info(
            "request completed",
            method=request.method,
            path=request.url.path,
            status=response.status_code,
            duration_ms=round(duration_ms, 1),
            correlation_id=getattr(request.state, "correlation_id", ""),
        )
        return response
```

---

## Pagination (Lightweight)

### Domain Models

```python
# domain/models/pagination.py
from dataclasses import dataclass, field
from typing import TypeVar, Generic

T = TypeVar("T")

@dataclass(frozen=True)
class PageParams:
    offset: int = 0
    limit: int = 20
    max_limit: int = 100

    def __post_init__(self) -> None:
        object.__setattr__(self, "limit", min(self.limit, self.max_limit))

@dataclass(frozen=True)
class PaginatedResult(Generic[T]):
    items: list[T]
    total: int
    offset: int
    limit: int
    has_more: bool
```

### Repository Port Update

```python
# domain/ports/repository.py
from typing import Protocol, TypeVar
from domain.models.pagination import PageParams, PaginatedResult

T = TypeVar("T")

class Repository(Protocol[T]):
    def save(self, entity: T) -> None: ...
    def find_by_id(self, entity_id: str) -> T | None: ...
    def find_all(self) -> list[T]: ...
    def find_paginated(self, page: PageParams) -> PaginatedResult[T]: ...
    def delete(self, entity_id: str) -> None: ...
```

### PostgreSQL Repository with Pagination

```python
# adapters/persistence/postgres_user_repository.py
from domain.models.pagination import PageParams, PaginatedResult

class PostgresUserRepository:
    async def find_paginated(self, page: PageParams) -> PaginatedResult[User]:
        # Count total
        total = await self._pool.fetchval("SELECT COUNT(*) FROM users")
        
        # Fetch page
        rows = await self._pool.fetch(
            "SELECT * FROM users ORDER BY id LIMIT $1 OFFSET $2",
            page.limit, page.offset,
        )
        
        items = [User(id=r["id"], email=r["email"], name=r["name"],
                       role=r["role"]) for r in rows]
        
        return PaginatedResult(
            items=items,
            total=total,
            offset=page.offset,
            limit=page.limit,
            has_more=(page.offset + page.limit) < total,
        )
```

### Pydantic Schema & Route

```python
# adapters/http/schemas/pagination.py
from pydantic import BaseModel, Field

class PaginationQuery(BaseModel):
    offset: int = Field(0, ge=0, description="Number of items to skip")
    limit: int = Field(20, ge=1, le=100, description="Max items per page")

class PaginatedResponse(BaseModel):
    items: list[dict]
    total: int
    offset: int
    limit: int
    has_more: bool

# adapters/http/routes/users.py
@router.get("/", response_model=PaginatedResponse)
async def list_users(
    offset: int = 0,
    limit: int = 20,
    user_repository = Depends(get_user_repository),
):
    page = PageParams(offset=offset, limit=limit)
    result = await user_repository.find_paginated(page)
    return PaginatedResponse(
        items=[UserResponse.model_validate(u).model_dump() for u in result.items],
        total=result.total,
        offset=result.offset,
        limit=result.limit,
        has_more=result.has_more,
    )
```

---

## Rate Limiting (Lightweight In-Memory)

```python
# adapters/http/rate_limit.py
import time
from collections import defaultdict
from dataclasses import dataclass, field
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse

@dataclass
class RateLimitConfig:
    requests_per_minute: int = 60
    burst: int = 10  # max burst before limiting

@dataclass
class ClientRateInfo:
    timestamps: list[float] = field(default_factory=list)
    
    def is_allowed(self, config: RateLimitConfig) -> bool:
        now = time.time()
        cutoff = now - 60.0
        
        # Remove old timestamps
        self.timestamps = [t for t in self.timestamps if t > cutoff]
        
        if len(self.timestamps) >= config.requests_per_minute:
            return False
        
        self.timestamps.append(now)
        return True

class RateLimitMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, config: RateLimitConfig | None = None) -> None:
        super().__init__(app)
        self._config = config or RateLimitConfig()
        self._clients: dict[str, ClientRateInfo] = defaultdict(ClientRateInfo)
    
    async def dispatch(self, request: Request, call_next):
        client_ip = request.client.host if request.client else "unknown"
        client_info = self._clients[client_ip]
        
        if not client_info.is_allowed(self._config):
            return JSONResponse(
                status_code=429,
                content={
                    "code": "RATE-001",
                    "message": "Rate limit exceeded",
                    "remediation": "Slow down your requests",
                },
                headers={"Retry-After": "60"},
            )
        
        return await call_next(request)
```

### Alternative: Token Bucket (for Burst Handling)

```python
# adapters/http/token_bucket.py
import time
from collections import defaultdict

class TokenBucket:
    """Token bucket algorithm for rate limiting with burst support."""
    
    def __init__(self, rate: float, capacity: int) -> None:
        self._rate = rate  # tokens per second
        self._capacity = capacity
        self._buckets: dict[str, dict] = defaultdict(
            lambda: {"tokens": capacity, "last_refill": time.time()}
        )
    
    def allow(self, key: str, tokens: int = 1) -> bool:
        bucket = self._buckets[key]
        now = time.time()
        
        # Refill tokens
        elapsed = now - bucket["last_refill"]
        bucket["tokens"] = min(
            self._capacity,
            bucket["tokens"] + elapsed * self._rate,
        )
        bucket["last_refill"] = now
        
        if bucket["tokens"] >= tokens:
            bucket["tokens"] -= tokens
            return True
        return False

# Usage in middleware:
# _bucket = TokenBucket(rate=1.0, capacity=10)  # 1 req/sec, burst of 10
```

---

## Caching (Lightweight In-Memory)

```python
# adapters/cache/memory_cache.py
import time
from dataclasses import dataclass
from typing import Any, Callable, TypeVar

T = TypeVar("T")

@dataclass
class CacheEntry:
    value: Any
    expires_at: float

class MemoryCache:
    """Simple in-memory cache with TTL."""
    
    def __init__(self) -> None:
        self._cache: dict[str, CacheEntry] = {}
    
    def get(self, key: str) -> Any | None:
        entry = self._cache.get(key)
        if entry is None:
            return None
        if time.time() > entry.expires_at:
            del self._cache[key]
            return None
        return entry.value
    
    def set(self, key: str, value: Any, ttl_seconds: int = 300) -> None:
        self._cache[key] = CacheEntry(
            value=value,
            expires_at=time.time() + ttl_seconds,
        )
    
    def delete(self, key: str) -> None:
        self._cache.pop(key, None)
    
    def clear(self) -> None:
        self._cache.clear()

# Cache port for domain
# domain/ports/cache.py
from typing import Protocol, TypeVar, Callable

T = TypeVar("T")

class CachePort(Protocol[T]):
    def get(self, key: str) -> T | None: ...
    def set(self, key: str, value: T, ttl_seconds: int = 300) -> None: ...
    def delete(self, key: str) -> None: ...

# Usage decorator pattern
def cached(ttl_seconds: int = 300, key_prefix: str = ""):
    """Decorator for caching workflow results."""
    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        def wrapper(*args, cache: CachePort | None = None, **kwargs) -> T:
            if cache is None:
                return func(*args, **kwargs)
            
            cache_key = f"{key_prefix}:{hash((args, tuple(kwargs.items())))}"
            result = cache.get(cache_key)
            if result is not None:
                return result
            
            result = func(*args, **kwargs)
            cache.set(cache_key, result, ttl_seconds)
            return result
        return wrapper
    return decorator
```

### Cache Middleware (Response Caching)

```python
# adapters/http/middleware.py (add caching)
class ResponseCacheMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, cache: MemoryCache) -> None:
        super().__init__(app)
        self._cache = cache
    
    async def dispatch(self, request: Request, call_next):
        # Only cache GET requests
        if request.method != "GET":
            return await call_next(request)
        
        cache_key = f"response:{request.url.path}:{request.url.query}"
        cached_response = self._cache.get(cache_key)
        
        if cached_response:
            return JSONResponse(
                content=cached_response["content"],
                status_code=cached_response["status"],
                headers={**cached_response.get("headers", {}), "X-Cache": "HIT"},
            )
        
        response = await call_next(request)
        
        # Cache successful responses
        if response.status_code == 200:
            body = b""
            async for chunk in response.body_iterator:
                body += chunk
            self._cache.set(cache_key, {
                "content": body.decode(),
                "status": response.status_code,
            }, ttl_seconds=60)
        
        return response
```

---

## File Uploads (Lightweight)

### Domain Models

```python
# domain/models/file.py
from dataclasses import dataclass
from enum import StrEnum

class FileType(StrEnum):
    IMAGE = "image"
    DOCUMENT = "document"
    DATA = "data"

@dataclass(frozen=True)
class UploadedFile:
    id: str
    filename: str
    content_type: str
    size_bytes: int
    user_id: str
    file_type: FileType

# domain/ports/file_storage.py
from typing import Protocol
from domain.models.file import UploadedFile

class FileStoragePort(Protocol):
    async def save(self, file_id: str, content: bytes, content_type: str) -> str: ...
    async def get_url(self, file_id: str) -> str: ...
    async def delete(self, file_id: str) -> None: ...
```

### Local File Storage Adapter

```python
# adapters/persistence/local_file_storage.py
import os
import uuid
from pathlib import Path
from domain.models.file import UploadedFile, FileType

class LocalFileStorage:
    def __init__(self, base_path: str = "./uploads") -> None:
        self._base_path = Path(base_path)
        self._base_path.mkdir(parents=True, exist_ok=True)

    async def save(self, file_id: str, content: bytes, content_type: str) -> str:
        ext = self._get_extension(content_type)
        file_path = self._base_path / f"{file_id}{ext}"
        file_path.write_bytes(content)
        return str(file_path)

    async def get_url(self, file_id: str) -> str:
        return f"/files/{file_id}"

    async def delete(self, file_id: str) -> None:
        for ext in [".jpg", ".png", ".pdf", ".txt", ".json"]:
            path = self._base_path / f"{file_id}{ext}"
            if path.exists():
                path.unlink()
                break

    def _get_extension(self, content_type: str) -> str:
        mime_map = {
            "image/jpeg": ".jpg",
            "image/png": ".png",
            "application/pdf": ".pdf",
            "text/plain": ".txt",
            "application/json": ".json",
        }
        return mime_map.get(content_type, ".bin")
```

### Upload Route

```python
# adapters/http/routes/files.py
from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from adapters.http.schemas.file import FileUploadResponse
from adapters.http.dependencies import get_file_storage
from domain.models.file import UploadedFile, FileType
import uuid

router = APIRouter(prefix="/files", tags=["files"])

@router.post("/upload", response_model=FileUploadResponse, status_code=201)
async def upload_file(
    file: UploadFile = File(...),
    file_storage = Depends(get_file_storage),
    user = Depends(get_current_user),  # from auth dependencies
):
    # Validate file type
    content = await file.read()
    
    # Determine file type from content_type
    file_type = FileType.DATA
    if file.content_type and file.content_type.startswith("image/"):
        file_type = FileType.IMAGE
    elif file.content_type == "application/pdf":
        file_type = FileType.DOCUMENT
    
    # Create file record
    file_id = str(uuid.uuid4())
    uploaded = UploadedFile(
        id=file_id,
        filename=file.filename or "unknown",
        content_type=file.content_type or "application/octet-stream",
        size_bytes=len(content),
        user_id=user.sub,
        file_type=file_type,
    )
    
    # Save to storage
    await file_storage.save(file_id, content, uploaded.content_type)
    
    return FileUploadResponse(
        id=uploaded.id,
        filename=uploaded.filename,
        size_bytes=uploaded.size_bytes,
        url=f"/files/{uploaded.id}",
    )

# adapters/http/schemas/file.py
from pydantic import BaseModel

class FileUploadResponse(BaseModel):
    id: str
    filename: str
    size_bytes: int
    url: str
```

---

## Production Patterns

### Circuit Breaker (Fault Tolerance)

```python
# adapters/resilience/circuit_breaker.py
import time
from enum import StrEnum
from dataclasses import dataclass, field

class CircuitState(StrEnum):
    CLOSED = "closed"      # Normal operation
    OPEN = "open"          # Failing, reject calls
    HALF_OPEN = "half_open" # Testing if service recovered

@dataclass
class CircuitBreaker:
    failure_threshold: int = 5
    recovery_timeout: float = 30.0
    success_threshold: int = 2
    
    _state: CircuitState = field(default=CircuitState.CLOSED, init=False)
    _failure_count: int = field(default=0, init=False)
    _success_count: int = field(default=0, init=False)
    _last_failure_time: float = field(default=0.0, init=False)

    @property
    def state(self) -> CircuitState:
        if self._state == CircuitState.OPEN:
            if time.time() - self._last_failure_time > self.recovery_timeout:
                self._state = CircuitState.HALF_OPEN
                self._success_count = 0
        return self._state

    def allow_request(self) -> bool:
        state = self.state
        if state == CircuitState.CLOSED:
            return True
        if state == CircuitState.HALF_OPEN:
            return True  # Allow one test request
        return False  # OPEN

    def record_success(self) -> None:
        if self._state == CircuitState.HALF_OPEN:
            self._success_count += 1
            if self._success_count >= self.success_threshold:
                self._state = CircuitState.CLOSED
                self._failure_count = 0
        else:
            self._failure_count = 0

    def record_failure(self) -> None:
        self._failure_count += 1
        self._last_failure_time = time.time()
        if self._failure_count >= self.failure_threshold:
            self._state = CircuitState.OPEN

# Usage in gateway
class StripeGateway:
    def __init__(self) -> None:
        self._circuit = CircuitBreaker(failure_threshold=3, recovery_timeout=60.0)
    
    async def charge(self, request: PaymentRequest) -> PaymentResult:
        if not self._circuit.allow_request():
            return PaymentResult(
                success=False,
                status=PaymentStatus.FAILED,
                error="Service temporarily unavailable (circuit open)",
            )
        
        try:
            result = await self._do_charge(request)
            self._circuit.record_success()
            return result
        except Exception as e:
            self._circuit.record_failure()
            return PaymentResult(success=False, status=PaymentStatus.FAILED, error=str(e))
```

### Retry with Exponential Backoff

```python
# adapters/resilience/retry.py
import asyncio
import random
from dataclasses import dataclass
from typing import Callable, TypeVar, Any
from domain.errors.app_error import AppError

T = TypeVar("T")

@dataclass
class RetryConfig:
    max_retries: int = 3
    base_delay: float = 0.5
    max_delay: float = 10.0
    exponential_base: float = 2.0
    jitter: bool = True
    retryable_exceptions: tuple[type[Exception], ...] = (Exception,)

async def retry_with_backoff(
    func: Callable[..., Any],
    config: RetryConfig | None = None,
    *args,
    **kwargs,
) -> Any:
    cfg = config or RetryConfig()
    last_exception = None
    
    for attempt in range(cfg.max_retries + 1):
        try:
            return await func(*args, **kwargs)
        except cfg.retryable_exceptions as e:
            last_exception = e
            if attempt == cfg.max_retries:
                break
            
            delay = min(
                cfg.base_delay * (cfg.exponential_base ** attempt),
                cfg.max_delay,
            )
            if cfg.jitter:
                delay = random.uniform(0, delay)
            
            await asyncio.sleep(delay)
    
    raise last_exception

# Usage
async def charge_with_retry(payment_gateway, request):
    return await retry_with_backoff(
        payment_gateway.charge,
        RetryConfig(max_retries=3, retryable_exceptions=(ConnectionError, TimeoutError)),
        request,
    )
```

### Outbox Pattern (Reliable Event Publishing)

```python
# adapters/persistence/outbox.py
import json
import asyncpg
from datetime import datetime, timezone
from domain.events import DomainEvent

class OutboxRepository:
    """Stores events in DB transaction, published by background worker."""
    
    def __init__(self, pool: asyncpg.Pool) -> None:
        self._pool = pool

    async def save_with_event(self, entity_sql: str, entity_params: tuple, event: DomainEvent) -> None:
        """Save entity and event in same transaction."""
        async with self._pool.acquire() as conn:
            async with conn.transaction():
                await conn.execute(entity_sql, *entity_params)
                await conn.execute(
                    """INSERT INTO outbox (event_type, aggregate_id, payload, created_at)
                       VALUES ($1, $2, $3, $4)""",
                    event.event_type,
                    event.aggregate_id,
                    json.dumps({"type": event.event_type, "payload": event.payload}),
                    datetime.now(timezone.utc),
                )

    async def fetch_unpublished(self, limit: int = 100) -> list[dict]:
        """Fetch events for publishing."""
        rows = await self._pool.fetch(
            "SELECT * FROM outbox WHERE published = FALSE ORDER BY created_at LIMIT $1",
            limit,
        )
        return [dict(r) for r in rows]

    async def mark_published(self, event_ids: list[str]) -> None:
        """Mark events as published."""
        await self._pool.execute(
            "UPDATE outbox SET published = TRUE, published_at = NOW() WHERE id = ANY($1)",
            event_ids,
        )

# Background worker
# adapters/background/outbox_worker.py
import asyncio
from adapters.persistence.outbox import OutboxRepository
from domain.ports.services.event_publisher import EventPublisher

class OutboxWorker:
    def __init__(self, outbox: OutboxRepository, publisher: EventPublisher, interval: float = 1.0) -> None:
        self._outbox = outbox
        self._publisher = publisher
        self._interval = interval
        self._running = False

    async def start(self) -> None:
        self._running = True
        while self._running:
            events = await self._outbox.fetch_unpublished()
            if events:
                event_ids = []
                for event in events:
                    try:
                        await self._publisher.publish(event)
                        event_ids.append(event["id"])
                    except Exception:
                        pass  # Will retry next cycle
                if event_ids:
                    await self._outbox.mark_published(event_ids)
            await asyncio.sleep(self._interval)

    def stop(self) -> None:
        self._running = False
```

### Idempotency Keys (Safe Retries)

```python
# adapters/http/idempotency.py
import hashlib
import json
from dataclasses import dataclass
from typing import Any
import asyncpg

@dataclass
class IdempotencyRecord:
    key: str
    response: dict
    status_code: int

class IdempotencyStore:
    def __init__(self, pool: asyncpg.Pool) -> None:
        self._pool = pool

    async def get(self, idempotency_key: str, user_id: str) -> IdempotencyRecord | None:
        composite_key = f"{user_id}:{idempotency_key}"
        row = await self._pool.fetchrow(
            "SELECT * FROM idempotency_keys WHERE key = $1 AND expires_at > NOW()",
            composite_key,
        )
        if row:
            return IdempotencyRecord(
                key=row["key"],
                response=json.loads(row["response"]),
                status_code=row["status_code"],
            )
        return None

    async def set(self, idempotency_key: str, user_id: str, response: dict, status_code: int, ttl: int = 86400) -> None:
        composite_key = f"{user_id}:{idempotency_key}"
        await self._pool.execute(
            """INSERT INTO idempotency_keys (key, response, status_code, expires_at)
               VALUES ($1, $2, $3, NOW() + INTERVAL '1 second' * $4)
               ON CONFLICT (key) DO UPDATE SET
                   response = EXCLUDED.response,
                   status_code = EXCLUDED.status_code,
                   expires_at = EXCLUDED.expires_at""",
            composite_key, json.dumps(response), status_code, ttl,
        )

# FastAPI dependency
from fastapi import Header, HTTPException

def require_idempotency_key(idempotency_key: str = Header(..., alias="Idempotency-Key")) -> str:
    if not idempotency_key or len(idempotency_key) < 16:
        raise HTTPException(status_code=400, detail="Idempotency-Key must be at least 16 characters")
    return idempotency_key

# Usage in route
@router.post("/orders", status_code=201)
async def create_order(
    body: CreateOrderRequest,
    idempotency_key: str = Depends(require_idempotency_key),
    user: TokenPayload = Depends(get_current_user),
    idempotency_store: IdempotencyStore = Depends(get_idempotency_store),
):
    # Check for existing request
    existing = await idempotency_store.get(idempotency_key, user.sub)
    if existing:
        return JSONResponse(content=existing.response, status_code=existing.status_code)
    
    # Process new request
    order = await create_order_fn(user_id=user.sub, items=body.items)
    response = {"order_id": order.id, "status": order.status}
    
    # Store for idempotency
    await idempotency_store.set(idempotency_key, user.sub, response, 201)
    
    return JSONResponse(content=response, status_code=201)
```

### Feature Flags

```python
# adapters/feature_flags/simple_flags.py
from dataclasses import dataclass
from typing import Any
import json

@dataclass
class FeatureFlag:
    name: str
    enabled: bool
    rollout_percentage: int = 100  # 0-100
    allowed_users: list[str] | None = None
    metadata: dict = {}

class FeatureFlagService:
    """Simple in-memory feature flags — swap for LaunchDarkly/Unleash in prod."""
    
    def __init__(self) -> None:
        self._flags: dict[str, FeatureFlag] = {}

    def register(self, flag: FeatureFlag) -> None:
        self._flags[flag.name] = flag

    def is_enabled(self, flag_name: str, user_id: str | None = None) -> bool:
        flag = self._flags.get(flag_name)
        if flag is None or not flag.enabled:
            return False
        
        if flag.allowed_users and user_id:
            return user_id in flag.allowed_users
        
        if flag.rollout_percentage < 100 and user_id:
            # Deterministic rollout based on user_id hash
            hash_val = int(hashlib.md5(user_id.encode()).hexdigest(), 16) % 100
            return hash_val < flag.rollout_percentage
        
        return True

    def get_variant(self, flag_name: str, user_id: str | None = None, default: Any = None) -> Any:
        flag = self._flags.get(flag_name)
        if flag is None or not flag.enabled:
            return default
        return flag.metadata.get("variant", default)

# FastAPI dependency
_feature_flags = FeatureFlagService()

def get_feature_flags() -> FeatureFlagService:
    return _feature_flags

def require_feature_flag(flag_name: str):
    async def checker(
        user: TokenPayload = Depends(get_current_user),
        flags: FeatureFlagService = Depends(get_feature_flags),
    ) -> bool:
        if not flags.is_enabled(flag_name, user.sub):
            raise HTTPException(status_code=404, detail="Feature not available")
        return True
    return checker

# Usage
@router.post("/experimental-feature")
async def experimental_endpoint(
    _: bool = Depends(require_feature_flag("experimental_feature")),
):
    return {"status": "experimental feature active"}
```

### Health Checks (Liveness + Readiness)

```python
# adapters/http/health.py
from fastapi import APIRouter, Depends
from dataclasses import dataclass
from typing import Any
import asyncio

router = APIRouter(tags=["health"])

@dataclass
class HealthCheck:
    name: str
    status: str
    latency_ms: float
    details: dict = {}

@dataclass
class HealthReport:
    status: str  # healthy, degraded, unhealthy
    checks: list[HealthCheck]
    version: str

# Health check registry
_health_checks: list = []

def register_health_check(check_fn):
    _health_checks.append(check_fn)
    return check_fn

@register_health_check
async def check_database(pool) -> HealthCheck:
    import time
    start = time.perf_counter()
    try:
        await pool.fetchval("SELECT 1")
        latency = (time.perf_counter() - start) * 1000
        return HealthCheck(name="database", status="healthy", latency_ms=round(latency, 2))
    except Exception as e:
        latency = (time.perf_counter() - start) * 1000
        return HealthCheck(name="database", status="unhealthy", latency_ms=round(latency, 2), details={"error": str(e)})

@register_health_check
async def check_redis(redis_client) -> HealthCheck:
    import time
    start = time.perf_counter()
    try:
        await redis_client.ping()
        latency = (time.perf_counter() - start) * 1000
        return HealthCheck(name="redis", status="healthy", latency_ms=round(latency, 2))
    except Exception as e:
        latency = (time.perf_counter() - start) * 1000
        return HealthCheck(name="redis", status="unhealthy", latency_ms=round(latency, 2), details={"error": str(e)})

@router.get("/health/live")
async def liveness():
    """Kubernetes liveness probe — is the app running?"""
    return {"status": "alive"}

@router.get("/health/ready")
async def readiness():
    """Kubernetes readiness probe — is the app ready to serve?"""
    checks = await asyncio.gather(*[check() for check in _health_checks])
    overall = "healthy" if all(c.status == "healthy" for c in checks) else "unhealthy"
    status_code = 200 if overall == "healthy" else 503
    return JSONResponse(
        status_code=status_code,
        content={
            "status": overall,
            "checks": [{"name": c.name, "status": c.status, "latency_ms": c.latency_ms} for c in checks],
        },
    )

@router.get("/health")
async def health():
    """Full health report with details."""
    checks = await asyncio.gather(*[check() for check in _health_checks])
    statuses = [c.status for c in checks]
    if all(s == "healthy" for s in statuses):
        overall = "healthy"
    elif any(s == "unhealthy" for s in statuses):
        overall = "unhealthy"
    else:
        overall = "degraded"
    
    return HealthReport(
        status=overall,
        checks=checks,
        version="1.0.0",
    )
```

### Graceful Shutdown

```python
# main.py lifespan (updated)
from contextlib import asynccontextmanager
import signal
import asyncio

@asynccontextmanager
async def lifespan(app: FastAPI):
    # --- Startup ---
    shutdown_event = asyncio.Event()
    
    pool = await create_pool()
    redis = await create_redis()
    grpc_runner = GrpcServerRunner(port=50051)
    
    app.state.pool = pool
    app.state.redis = redis
    app.state.shutdown_event = shutdown_event
    
    # Start background workers
    outbox_worker = OutboxWorker(outbox, publisher)
    asyncio.create_task(outbox_worker.start())
    
    # Start gRPC server
    await grpc_runner.start(grpc_service)
    
    yield
    
    # --- Shutdown ---
    print("Shutting down gracefully...")
    shutdown_event.set()
    
    # Stop accepting new requests
    await grpc_runner.stop()
    outbox_worker.stop()
    
    # Wait for in-flight requests (max 30s)
    await asyncio.sleep(2)
    
    # Close connections
    await pool.close()
    await redis.close()
    
    print("Shutdown complete")
```

### Request/Response Logging (Audit Trail)

```python
# adapters/http/middleware.py (add audit logging)
class AuditLogMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, logger: LoggerPort) -> None:
        super().__init__(app)
        self._logger = logger

    async def dispatch(self, request: Request, call_next):
        # Log request
        request_body = None
        if request.method in ("POST", "PUT", "PATCH"):
            try:
                request_body = await request.body()
            except Exception:
                pass
        
        self._logger.info(
            "request received",
            method=request.method,
            path=request.url.path,
            query=str(request.url.query),
            client=request.client.host if request.client else None,
            user_agent=request.headers.get("user-agent"),
            body_size=len(request_body) if request_body else 0,
            correlation_id=getattr(request.state, "correlation_id", ""),
        )
        
        # Process request
        start = time.perf_counter()
        response = await call_next(request)
        duration_ms = (time.perf_counter() - start) * 1000
        
        # Log response
        self._logger.info(
            "request completed",
            method=request.method,
            path=request.url.path,
            status=response.status_code,
            duration_ms=round(duration_ms, 1),
            correlation_id=getattr(request.state, "correlation_id", ""),
        )
        
        return response
```

### Bulkhead (Isolation)

```python
# adapters/resilience/bulkhead.py
import asyncio
from dataclasses import dataclass, field

@dataclass
class Bulkhead:
    """Isolate failures — limit concurrent calls to a resource."""
    max_concurrent: int = 10
    max_queue: int = 20
    _semaphore: asyncio.Semaphore = field(init=False)
    _queue_count: int = field(default=0, init=False)

    def __post_init__(self):
        self._semaphore = asyncio.Semaphore(self.max_concurrent)

    async def acquire(self) -> bool:
        if self._queue_count >= self.max_queue:
            return False
        self._queue_count += 1
        await self._semaphore.acquire()
        return True

    def release(self) -> None:
        self._semaphore.release()
        self._queue_count -= 1

# Usage
_payment_bulkhead = Bulkhead(max_concurrent=5, max_queue=10)

async def charge_with_bulkhead(payment_gateway, request):
    if not await _payment_bulkhead.acquire():
        raise Exception("Too many concurrent payment requests")
    try:
        return await payment_gateway.charge(request)
    finally:
        _payment_bulkhead.release()
```

### Saga Pattern (Distributed Transactions)

```python
# adapters/saga/order_saga.py
from dataclasses import dataclass
from typing import Callable, Any
import asyncio

@dataclass
class SagaStep:
    name: str
    execute: Callable[..., Any]
    compensate: Callable[..., Any]

class Saga:
    """Orchestrate distributed transaction with compensation."""
    
    def __init__(self, steps: list[SagaStep]) -> None:
        self._steps = steps
        self._executed: list[SagaStep] = []

    async def execute(self, context: dict) -> dict:
        for step in self._steps:
            try:
                context = await step.execute(context)
                self._executed.append(step)
            except Exception as e:
                # Compensate in reverse order
                await self.compensate()
                raise SagaFailedError(step.name, e)
        return context

    async def compensate(self) -> None:
        for step in reversed(self._executed):
            try:
                await step.compensate()
            except Exception:
                pass  # Log but don't fail compensation
        self._executed.clear()

class SagaFailedError(Exception):
    def __init__(self, step: str, cause: Exception) -> None:
        self.step = step
        self.cause = cause
        super().__init__(f"Saga failed at step '{step}': {cause}")

# Usage
order_saga = Saga(steps=[
    SagaStep(
        name="reserve_inventory",
        execute=lambda ctx: inventory.reserve(ctx["items"]),
        execute=lambda ctx: inventory.release(ctx["items"]),
    ),
    SagaStep(
        name="process_payment",
        execute=lambda ctx: payment.charge(ctx["user_id"], ctx["amount"]),
        execute=lambda ctx: payment.refund(ctx["payment_id"]),
    ),
    SagaStep(
        name="create_order",
        execute=lambda ctx: orders.create(ctx),
        execute=lambda ctx: orders.cancel(ctx["order_id"]),
    ),
])

# In workflow
async def create_order_with_saga(user_id, items):
    context = {"user_id": user_id, "items": items}
    try:
        result = await order_saga.execute(context)
        return result["order"]
    except SagaFailedError as e:
        # Saga compensated automatically
        raise OrderCreationError(f"Failed: {e.step}")
```

### API Versioning

```python
# adapters/http/versioning.py
from fastapi import APIRouter

# Option 1: URL path versioning
v1_router = APIRouter(prefix="/api/v1")
v2_router = APIRouter(prefix="/api/v2")

@v1_router.get("/users")
async def list_users_v1():
    return {"users": [], "version": "1"}

@v2_router.get("/users")
async def list_users_v2():
    # V2 adds pagination, different response shape
    return {"data": [], "meta": {"total": 0}, "version": "2"}

# Option 2: Header versioning
from fastapi import Request

@router.get("/users")
async def list_users(request: Request):
    version = request.headers.get("api-version", "1")
    if version == "2":
        return {"data": [], "meta": {"total": 0}}
    return {"users": []}

# main.py
app.include_router(v1_router)
app.include_router(v2_router)
```

### Cache-Aside Pattern

```python
# adapters/cache/cache_aside.py
from typing import TypeVar, Callable, Any
import json

T = TypeVar("T")

class CacheAside:
    """Cache-aside: check cache → miss → fetch from DB → populate cache."""
    
    def __init__(self, cache: MemoryCache, db_fetch: Callable) -> None:
        self._cache = cache
        self._db_fetch = db_fetch

    async def get(self, key: str, ttl: int = 300) -> Any | None:
        # Check cache
        cached = self._cache.get(key)
        if cached is not None:
            return cached
        
        # Fetch from DB
        result = await self._db_fetch(key)
        if result is not None:
            self._cache.set(key, result, ttl)
        return result

    async def invalidate(self, key: str) -> None:
        self._cache.delete(key)

    async def invalidate_pattern(self, pattern: str) -> None:
        # For Redis: use SCAN + DEL
        # For memory: iterate and delete matching
        pass

# Usage
user_cache = CacheAside(
    cache=memory_cache,
    db_fetch=lambda user_id: user_repo.find_by_id(user_id),
)

async def get_user_cached(user_id: str) -> User | None:
    return await user_cache.get(f"user:{user_id}")
```

### Webhooks (Inbound Events)

```python
# adapters/http/routes/webhooks.py
from fastapi import APIRouter, Request, HTTPException
import hmac
import hashlib

router = APIRouter(prefix="/webhooks", tags=["webhooks"])

def verify_webhook_signature(payload: bytes, signature: str, secret: str) -> bool:
    expected = hmac.new(
        secret.encode(), payload, hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(signature, expected)

@router.post("/stripe")
async def stripe_webhook(request: Request):
    payload = await request.body()
    signature = request.headers.get("stripe-signature", "")
    
    if not verify_webhook_signature(payload, signature, settings.webhook_secret):
        raise HTTPException(status_code=401, detail="Invalid signature")
    
    event = await request.json()
    
    # Route to handler
    handlers = {
        "payment_intent.succeeded": handle_payment_success,
        "payment_intent.payment_failed": handle_payment_failure,
        "customer.subscription.created": handle_subscription_created,
    }
    
    handler = handlers.get(event["type"])
    if handler:
        await handler(event["data"]["object"])
    
    return {"status": "ok"}

async def handle_payment_success(payment_intent: dict):
    # Update order status
    pass

async def handle_payment_failure(payment_intent: dict):
    # Notify user, retry logic
    pass
```

---

## Key Rules

| Rule | How |
|------|-----|
| Domain imports zero frameworks | No `fastapi`, `pydantic`, `asyncpg` in `domain/` |
| DTOs stay in adapters | Pydantic schemas in `adapters/http/schemas/`, not in domain |
| All errors are AppError | Every exception carries code, message, context, cause, origin |
| Composition root is thin | Only wiring — no business logic in `main.py` |
| Sync workflows preferred | Keep domain workflows synchronous; async only at adapter boundary |
| Lifespan manages lifecycle | Startup creates adapters, shutdown cleans up — no global state |
| Correlation ID everywhere | Every request gets an ID, threaded through logs and errors |
| Test at the lowest tier | Unit tests for domain + pure helpers, e2e for full API surface |
| Portable adapters | Adapter files copy to any project — only port contracts and config change |
| Repository = your data | Use repositories for PostgreSQL, MongoDB, SQLite, file systems |
| Gateway = external services | Use gateways for Stripe, Twilio, SendGrid, S3, Auth0 |
| Domain events via ports | Events published through domain port, not direct adapter calls |
| Pagination in domain | PageParams/PaginatedResult are domain models |

## External References

- [Hexagonal Architecture Skill](https://opencode.ai/skills/hexagonal-architecture/SKILL.md)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Pydantic v2 Docs](https://docs.pydantic.dev/)
- [httpx AsyncClient](https://www.python-httpx.org/async/)
- [asyncpg Documentation](https://magicstack.github.io/asyncpg/)
- [OAuth2 with FastAPI](https://fastapi.tiangolo.com/tutorial/security/oauth2-jwt/)
