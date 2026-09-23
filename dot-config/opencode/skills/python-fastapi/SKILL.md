---
name: python-fastapi
description: Build production-grade Python REST APIs with FastAPI and hexagonal architecture. Use when creating FastAPI projects, designing API endpoints, implementing dependency injection, middleware, background tasks, async patterns, OpenAPI schemas, or structuring a maintainable backend with clean domain boundaries.
---

# Python FastAPI — Production API Guide

Quick, safe, production-level APIs. Hexagonal architecture, fail-fast validation, RFC 9457 errors, full resilience + observability stack. Copy the patterns, ship with confidence.

**Pattern references** are inline links. Code is minimal — enough to copy, not enough to clutter.

## Project Structure

```
my-api/
├── main.py                 # Composition root
├── pyproject.toml
├── justfile
├── domain/                 # Zero framework imports
│   ├── models.py           # Frozen dataclasses
│   ├── errors.py           # AppError hierarchy (RFC 9457)
│   ├── events.py           # Domain events
│   ├── ports.py            # Protocol interfaces
│   └── workflows.py        # Pure async functions
├── adapters/
│   ├── http/
│   │   ├── routes/         # Thin FastAPI routers
│   │   ├── schemas.py      # Pydantic DTOs
│   │   ├── middleware.py    # Correlation, security, errors
│   │   └── dependencies.py # DI factories
│   ├── persistence/        # Postgres, SQLite, in-memory
│   ├── auth/               # JWT + password hashing
│   ├── external/           # Stripe, SendGrid, S3 gateways
│   ├── resilience/         # Circuit breaker, retry, bulkhead
│   ├── messaging/          # RabbitMQ, Kafka, Redis Streams
│   └── observability/      # Logging, tracing, metrics
├── infra/
│   └── config.py           # Settings (fail-fast)
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── contract/           # Port compliance tests
│   └── e2e/
└── alembic/                # DB migrations
```

**Rule:** Domain never imports `fastapi`, `pydantic`, or any adapter. Dependencies point inward only. ([Hexagonal Architecture](https://en.wikipedia.org/wiki/Hexagonal_architecture_(software)))

---

## Domain

### Models — frozen, validated, immutable

```python
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import StrEnum
import uuid

class UserRole(StrEnum):
    ADMIN = "admin"; MEMBER = "member"; VIEWER = "viewer"

class OrderStatus(StrEnum):
    PENDING = "pending"; PAID = "paid"; SHIPPED = "shipped"; CANCELLED = "cancelled"

@dataclass(frozen=True)
class User:
    id: str; email: str; name: str
    role: UserRole = UserRole.MEMBER
    created_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    @classmethod
    def create(cls, email: str, name: str) -> "User":
        return cls(id=str(uuid.uuid4()), email=email, name=name)

@dataclass(frozen=True)
class OrderItem:
    product_id: str; quantity: int; price: int  # cents
    def __post_init__(self):
        if self.quantity <= 0: raise ValueError("quantity must be positive")

@dataclass(frozen=True)
class Order:
    id: str; user_id: str; items: tuple["OrderItem", ...]
    total_amount: int = 0; status: str = "pending"
    def __post_init__(self):
        if not self.total_amount:
            object.__setattr__(self, "total_amount", sum(i.price * i.quantity for i in self.items))
    def mark_paid(self, payment_id: str) -> "Order":
        return Order(id=self.id, user_id=self.user_id, items=self.items,
                     total_amount=self.total_amount, status="paid")
```

**Why frozen:** Immutable across layers. `mark_paid()` returns a new instance. ([Immutable Object](https://en.wikipedia.org/wiki/Immutable_object)). Use `field(default_factory=...)` for mutable defaults — bare `dict = {}` is shared. ([Python gotcha](https://docs.python.org/3/faq/programming.html#why-are-default-values-shared-between-objects))

### Errors — RFC 9457 Problem Details

Every error owns its HTTP status. No string matching in middleware. ([RFC 9457](https://www.rfc-editor.org/rfc/rfc9457))

```python
from dataclasses import dataclass, field

@dataclass(frozen=True)
class AppError(Exception):
    status_code: int; type: str; title: str; code: str; message: str
    context: dict = field(default_factory=dict)
    remediation: str = ""; retryable: bool = False
    cause: Exception | None = None; origin: str = ""; correlation_id: str = ""

class UserNotFoundError(AppError):
    def __init__(self, uid: str):
        super().__init__(404, "/errors/user-not-found", "Not Found", "USR-001",
                         f"User {uid} not found", context={"user_id": uid})

class DuplicateEmailError(AppError):
    def __init__(self, email: str):
        super().__init__(409, "/errors/duplicate", "Conflict", "USR-002",
                         f"Email {email} taken", remediation="Use a different email")

class PaymentFailedError(AppError):
    def __init__(self, order_id: str, reason: str | None = None):
        super().__init__(402, "/errors/payment-failed", "Payment Failed", "ORD-002",
                         f"Payment failed for order {order_id}",
                         context={"reason": reason}, retryable=True)
```

### Events — domain events via ports

```python
from dataclasses import dataclass, field
from datetime import datetime, timezone

@dataclass(frozen=True)
class DomainEvent:
    event_type: str; aggregate_id: str; payload: dict
    timestamp: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
```

**Why events:** Decouple side effects (emails, analytics) from business logic. ([Event Sourcing — Martin Fowler](https://martinfowler.com/eaaDev/EventSourcing.html))

### Ports — Protocol interfaces

```python
from typing import Protocol

class UserRepository(Protocol):
    async def find_by_id(self, user_id: str) -> User | None: ...
    async def find_by_email(self, email: str) -> User | None: ...
    async def save(self, user: User) -> None: ...
    async def delete(self, user_id: str) -> None: ...

class OrderRepository(Protocol):
    async def find_by_id(self, order_id: str) -> Order | None: ...
    async def save(self, order: Order) -> None: ...

class PaymentGateway(Protocol):
    async def charge(self, amount: int, currency: str, user_id: str) -> dict: ...
    async def refund(self, payment_id: str, amount: int) -> dict: ...

class NotificationGateway(Protocol):
    async def send_email(self, to: str, subject: str, body: str) -> bool: ...

class StorageGateway(Protocol):
    async def upload(self, key: str, data: bytes, content_type: str) -> str: ...
    async def get_url(self, key: str, expires_in: int = 3600) -> str: ...

class EventPublisher(Protocol):
    async def publish(self, event: DomainEvent) -> None: ...

class LoggerPort(Protocol):
    def info(self, message: str, **fields) -> None: ...
    def error(self, message: str, **fields) -> None: ...
    def warning(self, message: str, **fields) -> None: ...

class CachePort(Protocol):
    def get(self, key: str) -> object | None: ...
    def set(self, key: str, value: object, ttl_seconds: int = 300) -> None: ...
    def delete(self, key: str) -> None: ...
```

**Why Protocols:** Structural subtyping. Zero runtime cost. Any matching class satisfies the protocol — no inheritance. ([PEP 544](https://peps.python.org/pep-0544/), [Dependency Inversion](https://en.wikipedia.org/wiki/Dependency_inversion_principle))

### Workflows — pure async, fail-fast

```python
import re
EMAIL_RE = re.compile(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")

async def create_user(email: str, name: str, user_repo: UserRepository,
                      events: EventPublisher, logger: LoggerPort) -> User:
    # Fail-fast: validate before any I/O
    if not email or not EMAIL_RE.match(email):
        raise AppError(422, "/errors/validation", "Validation", "USR-003",
                       "Invalid email", remediation="Provide a valid email address")
    if not name or len(name) > 200:
        raise AppError(422, "/errors/validation", "Validation", "USR-004",
                       "Name must be 1-200 characters")
    if await user_repo.find_by_email(email):
        raise DuplicateEmailError(email)

    user = User.create(email=email, name=name)
    await user_repo.save(user)
    await events.publish(DomainEvent("user.created", user.id, {"email": email}))
    logger.info("user created", user_id=user.id)
    return user

async def create_order(user_id: str, items: list[dict], order_repo: OrderRepository,
                       user_repo: UserRepository, payment: PaymentGateway,
                       events: EventPublisher) -> Order:
    if not items:
        raise AppError(422, "/errors/empty-order", "Empty Order", "ORD-003",
                       "Order must have at least one item")
    user = await user_repo.find_by_id(user_id)
    if not user: raise UserNotFoundError(user_id)

    order = Order.create(user_id=user_id, items=items)
    result = await payment.charge(order.total_amount, "USD", user_id)
    if not result.get("success"):
        raise PaymentFailedError(order.id, result.get("error"))

    paid = order.mark_paid(result["payment_id"])
    await order_repo.save(paid)
    await events.publish(DomainEvent("order.paid", paid.id, {"user_id": user_id}))
    return paid
```

**Why async:** All I/O (DB, HTTP, files) is async. Workflows must await port calls. ([Fail-Fast](https://en.wikipedia.org/wiki/Fail-fast))

---

## Adapters

### HTTP — routes, schemas, middleware

**Routes are thin.** Validate DTO → call workflow → return response. Errors handled by middleware. ([DTO Pattern](https://martinfowler.com/eaaDev/DTO.html))

```python
# schemas.py
from pydantic import BaseModel, EmailStr, Field
from datetime import datetime

class CreateUserRequest(BaseModel):
    email: EmailStr
    name: str = Field(..., min_length=1, max_length=200)

class UserResponse(BaseModel):
    id: str; email: str; name: str; role: str; created_at: datetime

class CreateOrderRequest(BaseModel):
    items: list[dict] = Field(..., min_length=1)

class ProblemDetail(BaseModel):
    type: str; title: str; status: int; detail: str
    remediation: str = ""; trace_id: str = ""
```

```python
# routes/users.py
from typing import Annotated
from fastapi import APIRouter, Depends, Request
from adapters.schemas import CreateUserRequest, UserResponse

router = APIRouter(prefix="/users", tags=["users"])

@router.post("/", response_model=UserResponse, status_code=201)
async def create_user(body: CreateUserRequest, use_case: Annotated[callable, Depends()],
                      request: Request) -> UserResponse:
    user = await use_case(email=body.email, name=body.name,
                          correlation_id=request.state.correlation_id)
    return UserResponse.model_validate(user)

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: str, use_case: Annotated[callable, Depends()]) -> UserResponse:
    return UserResponse.model_validate(await use_case(user_id))
```

### Middleware

```python
# middleware.py
import uuid
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.middleware.cors import CORSMiddleware

# Correlation ID — every request gets a traceable ID
class CorrelationIdMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        request.state.correlation_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
        response = await call_next(request)
        response.headers["X-Request-ID"] = request.state.correlation_id
        return response

# Security headers — OWASP best practices
class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"
        if request.url.scheme == "https":
            response.headers["Strict-Transport-Security"] = "max-age=63072000; includeSubDomains"
        return response

# Rate limiting — token bucket per client
class RateLimitMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, rate: float = 1.0, capacity: int = 20):
        super().__init__(app)
        from collections import defaultdict; import time
        self._rate = rate; self._capacity = capacity
        self._buckets = defaultdict(lambda: {"tokens": capacity, "last": time.time()})
    async def dispatch(self, request, call_next):
        import time
        key = request.client.host if request.client else "unknown"
        b = self._buckets[key]; now = time.time()
        b["tokens"] = min(self._capacity, b["tokens"] + (now - b["last"]) * self._rate)
        b["last"] = now
        if b["tokens"] < 1:
            return JSONResponse(429, {"type": "/errors/rate-limit", "title": "Too Many Requests",
                                      "status": 429, "detail": "Slow down",
                                      "remediation": "Retry after 60s"},
                                headers={"Retry-After": "60"})
        b["tokens"] -= 1
        return await call_next(request)

# Error handler — single point for all AppError → RFC 9457
def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppError)
    async def handler(request: Request, exc: AppError):
        return JSONResponse(status_code=exc.status_code, content={
            "type": exc.type, "title": exc.title, "status": exc.status_code,
            "detail": exc.message, "remediation": exc.remediation,
            "trace_id": getattr(request.state, "correlation_id", ""),
        })
```

### Auth — JWT + OAuth2 + password hashing

([OAuth2 RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749), [JWT RFC 7519](https://datatracker.ietf.org/doc/html/rfc7519))

```python
# auth/jwt_service.py
import hmac, hashlib, time, base64, json, secrets

class JWTService:
    def __init__(self, secret: str, algorithm: str = "HS256"):
        if not secret: raise ValueError("jwt_secret must not be empty")
        self._secret = secret.encode(); self._alg = algorithm

    def create_token(self, user_id: str, scopes: list[str] | None = None) -> str:
        payload = {"sub": user_id, "exp": time.time() + 3600, "scopes": scopes or []}
        return self._encode(payload)

    def verify_token(self, token: str) -> dict:
        header, payload_b64, sig = token.split(".")
        if not hmac.compare_digest(sig, self._sign(f"{header}.{payload_b64}")):
            raise AppError(401, "/errors/auth", "Unauthorized", "AUTH-001", "Invalid token")
        data = json.loads(base64.urlsafe_b64decode(payload_b64 + "=="))
        if data["exp"] < time.time():
            raise AppError(401, "/errors/auth", "Unauthorized", "AUTH-002", "Token expired")
        return data

    def _encode(self, payload: dict) -> str: ...
    def _sign(self, data: str) -> str: ...

# auth/password_hasher.py
import hashlib, secrets

class PasswordHasher:
    def __init__(self, iterations: int = 260000): self._iter = iterations
    def hash(self, password: str) -> str:
        salt = secrets.token_hex(16)
        dk = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), self._iter)
        return f"{salt}${dk.hex()}"
    def verify(self, password: str, hashed: str) -> bool:
        salt, stored = hashed.split("$")
        dk = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), self._iter)
        return hmac.compare_digest(dk.hex(), stored)
```

```python
# auth/dependencies.py
from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/token")

async def get_current_user(token: str = Depends(oauth2_scheme), jwt: JWTService = Depends()):
    try: return jwt.verify_token(token)
    except Exception: raise HTTPException(401, detail={"code": "AUTH-001"})

def require_scopes(*required: str):
    async def checker(user=Depends(get_current_user)):
        if not all(s in user.get("scopes", []) for s in required):
            raise HTTPException(403, detail={"code": "AUTH-003", "message": "Insufficient permissions"})
        return user
    return checker
```

### Persistence — async adapters

([Repository Pattern](https://martinfowler.com/eaaDev/Repository.html))

```python
# persistence/in_memory.py
class InMemoryUserRepository:
    def __init__(self): self._users: dict[str, User] = {}
    async def find_by_id(self, uid: str) -> User | None: return self._users.get(uid)
    async def find_by_email(self, email: str) -> User | None:
        return next((u for u in self._users.values() if u.email == email), None)
    async def save(self, user: User) -> None: self._users[user.id] = user
    async def delete(self, uid: str) -> None: self._users.pop(uid, None)

# persistence/postgres.py
class PostgresUserRepository:
    def __init__(self, pool): self._pool = pool
    async def find_by_id(self, uid: str) -> User | None:
        row = await self._pool.fetchrow("SELECT * FROM users WHERE id=$1", uid)
        return User(id=row["id"], email=row["email"], name=row["name"], role=row["role"]) if row else None
    async def save(self, user: User) -> None:
        await self._pool.execute(
            "INSERT INTO users (id,email,name,role) VALUES ($1,$2,$3,$4) "
            "ON CONFLICT (id) DO UPDATE SET email=$2,name=$3,role=$4",
            user.id, user.email, user.name, user.role.value)
```

### External Gateways — Stripe, SendGrid, S3

([Anti-Corruption Layer](https://learn.microsoft.com/en-us/azure/architecture/patterns/anti-corruption-layer))

```python
# external/stripe_gateway.py
import httpx
from adapters.resilience.circuit_breaker import CircuitBreaker

class StripeGateway:
    def __init__(self, api_key: str):
        self._client = httpx.AsyncClient(base_url="https://api.stripe.com/v1",
                                          headers={"Authorization": f"Bearer {api_key}"})
        self._circuit = CircuitBreaker(failure_threshold=3, recovery_timeout=60)

    async def charge(self, amount: int, currency: str, user_id: str) -> dict:
        if not self._circuit.allow_request():
            raise PaymentFailedError("n/a", "Service temporarily unavailable")
        try:
            r = await self._client.post("/payment_intents", data={
                "amount": amount, "currency": currency.lower(), "metadata[user_id]": user_id})
            self._circuit.record_success()
            return {"success": r.status_code == 200, "payment_id": r.json().get("id")}
        except Exception as e:
            self._circuit.record_failure()
            return {"success": False, "error": str(e)}

# external/sendgrid_gateway.py
class SendGridGateway:
    def __init__(self, api_key: str, from_email: str):
        self._client = httpx.AsyncClient(base_url="https://api.sendgrid.com/v3",
            headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"})
        self._from = from_email
    async def send_email(self, to: str, subject: str, body: str) -> bool:
        r = await self._client.post("/mail/send", json={
            "personalizations": [{"to": [{"email": to}]}],
            "from": {"email": self._from}, "subject": subject,
            "content": [{"type": "text/plain", "value": body}]})
        return r.status_code in (200, 202)

# external/s3_gateway.py
class S3Gateway:
    def __init__(self, bucket: str, region: str):
        import boto3
        self._client = boto3.client("s3", region_name=region); self._bucket = bucket
    async def upload(self, key: str, data: bytes, content_type: str) -> str:
        self._client.put_object(Bucket=self._bucket, Key=key, Body=data, ContentType=content_type)
        return f"s3://{self._bucket}/{key}"
    async def get_url(self, key: str, expires_in: int = 3600) -> str:
        return self._client.generate_presigned_url("get_object",
            Params={"Bucket": self._bucket, "Key": key}, ExpiresIn=expires_in)
```

### Resilience — circuit breaker, retry, bulkhead, saga

([Release It! — Michael Nygard](https://pragprog.com/titles/mnee2/release-it-second-edition/))

```python
# resilience/circuit_breaker.py
from enum import StrEnum; import time

class CircuitState(StrEnum):
    CLOSED = "closed"; OPEN = "open"; HALF_OPEN = "half_open"

class CircuitBreaker:
    def __init__(self, failure_threshold: int = 5, recovery_timeout: float = 30.0):
        self._threshold = failure_threshold; self._recovery = recovery_timeout
        self._state = CircuitState.CLOSED; self._failures = 0; self._last = 0.0
    def allow_request(self) -> bool:
        if self._state == CircuitState.OPEN and time.time() - self._last > self._recovery:
            self._state = CircuitState.HALF_OPEN; return True
        return self._state != CircuitState.OPEN
    def record_success(self):
        if self._state == CircuitState.HALF_OPEN: self._state = CircuitState.CLOSED
        self._failures = 0
    def record_failure(self):
        self._failures += 1; self._last = time.time()
        if self._failures >= self._threshold: self._state = CircuitState.OPEN

# resilience/retry.py
import asyncio, random

async def retry_transient(func, max_retries: int = 3, *args, **kwargs):
    for attempt in range(max_retries + 1):
        try: return await func(*args, **kwargs)
        except (ConnectionError, TimeoutError):
            if attempt == max_retries: raise
            await asyncio.sleep(min(0.5 * (2 ** attempt), 10) * random.uniform(0.5, 1.0))

# resilience/bulkhead.py
import asyncio

class Bulkhead:
    def __init__(self, max_concurrent: int = 10, max_queue: int = 20):
        self._sem = asyncio.Semaphore(max_concurrent); self._queue = max_queue; self._count = 0
    async def acquire(self) -> bool:
        if self._count >= self._queue: return False
        self._count += 1; await self._sem.acquire(); return True
    def release(self): self._sem.release(); self._count -= 1
```

### Messaging — RabbitMQ, Kafka, Redis Streams

([Message Queue pattern](https://www.enterpriseintegrationpatterns.com/patterns/messaging/Messaging.html))

```python
# messaging/rabbitmq.py
import aio_pika

class RabbitMQAdapter:
    def __init__(self, url: str): self._url = url
    async def connect(self):
        self._conn = await aio_pika.connect_robust(self._url)
        self._channel = await self._conn.channel()
    async def publish(self, queue: str, message: dict):
        await self._channel.default_exchange.publish(
            aio_pika.Message(body=str(message).encode()), routing_key=queue)
    async def consume(self, queue: str, handler):
        q = await self._channel.declare_queue(queue, durable=True)
        async with q.iterator() as qi:
            async for msg in qi:
                async with msg.process(): await handler(msg.body.decode())

# messaging/kafka.py
from aiokafka import AIOKafkaProducer, AIOKafkaConsumer

class KafkaAdapter:
    def __init__(self, servers: str, group_id: str):
        self._servers = servers; self._group = group_id; self._producer = None
    async def connect(self):
        self._producer = AIOKafkaProducer(bootstrap_servers=self._servers); await self._producer.start()
    async def publish(self, topic: str, key: str, value: dict):
        await self._producer.send_and_wait(topic, key=key.encode(), value=str(value).encode())
```

### Observability — structured logging, tracing, metrics

([12-Factor Logs](https://12factor.net/logs), [OpenTelemetry](https://opentelemetry.io/))

```python
# observability/logger.py
import logging, json, sys
from datetime import datetime, timezone

class JSONLogger:
    def __init__(self, name: str = "app", level: str = "INFO"):
        self._log = logging.getLogger(name); self._log.setLevel(getattr(logging, level.upper()))
        if not self._log.handlers:
            h = logging.StreamHandler(sys.stdout)
            h.setFormatter(type("F", (logging.Formatter,), {
                "format": lambda s, r: json.dumps({"ts": datetime.now(timezone.utc).isoformat(),
                    "level": r.levelname, "msg": r.getMessage(),
                    **({"fields": r.structured} if hasattr(r, "structured") else {})})
            })())
            self._log.addHandler(h)
    def info(self, msg: str, **kw): self._log.info(msg, extra={"structured": kw})
    def error(self, msg: str, **kw): self._log.error(msg, extra={"structured": kw})

# observability/tracing.py — OpenTelemetry
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

def setup_tracing(service_name: str):
    provider = TracerProvider()
    provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
    trace.set_tracer_provider(provider)
    return trace.get_tracer(service_name)

# observability/metrics.py — Prometheus
from prometheus_client import Counter, Histogram, generate_latest

REQUEST_COUNT = Counter("http_requests_total", "Requests", ["method", "path", "status"])
REQUEST_LATENCY = Histogram("http_request_duration_seconds", "Latency", ["method", "path"])

# In middleware:
# REQUEST_COUNT.labels(method=method, path=path, status=status).inc()
# REQUEST_LATENCY.labels(method=method, path=path).observe(duration)
```

### Caching — in-memory TTL + cache-aside

([Cache-Aside pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/cache-aside))

```python
# caching/memory_cache.py
import time
from dataclasses import dataclass

class MemoryCache:
    def __init__(self): self._cache: dict[str, "CacheEntry"] = {}
    def get(self, key: str):
        e = self._cache.get(key)
        if e and time.time() < e.expires: return e.value
        if e: del self._cache[key]
        return None
    def set(self, key: str, value, ttl: int = 300):
        self._cache[key] = CacheEntry(value, time.time() + ttl)
    def delete(self, key: str): self._cache.pop(key, None)

@dataclass
class CacheEntry:
    value: object; expires: float
```

### File Uploads — with size + content-type validation

([OWASP File Upload](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html))

```python
# routes/files.py
from fastapi import UploadFile, File, HTTPException

ALLOWED_TYPES = {"image/jpeg", "image/png", "application/pdf"}
MAX_UPLOAD_BYTES = 10 * 1024 * 1024  # 10MB

@router.post("/upload", status_code=201)
async def upload_file(file: UploadFile = File(...), storage: StorageGateway = Depends()):
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(422, detail=f"Content type {file.content_type} not allowed")
    content = await file.read()
    if len(content) > MAX_UPLOAD_BYTES:
        raise HTTPException(422, detail=f"File too large (max {MAX_UPLOAD_BYTES} bytes)")
    key = f"uploads/{uuid.uuid4()}{Path(file.filename or '').suffix}"
    await storage.upload(key, content, file.content_type)
    return {"key": key, "url": await storage.get_url(key)}
```

### Webhooks — inbound event verification

([Stripe Webhooks](https://docs.stripe.com/webhooks), [Webhook pattern](https://www.enterpriseintegrationpatterns.com/patterns/messaging/Webhook.html))

```python
# routes/webhooks.py
import hmac, hashlib

def verify_signature(payload: bytes, signature: str, secret: str) -> bool:
    expected = hmac.new(secret.encode(), payload, hashlib.sha256).hexdigest()
    return hmac.compare_digest(signature, expected)  # timing-safe

@router.post("/stripe")
async def stripe_webhook(request: Request):
    payload = await request.body()
    sig = request.headers.get("stripe-signature", "")
    if not verify_signature(payload, sig, settings.webhook_secret):
        raise HTTPException(401, detail="Invalid signature")
    event = await request.json()
    # route to handler...
```

### Health Checks — liveness + readiness

([Kubernetes Probes](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/))

```python
# routes/health.py
import asyncio

@app.get("/health/live")
async def liveness(): return {"status": "alive"}

@app.get("/health/ready")
async def readiness():
    checks = await asyncio.gather(check_database(), check_redis())
    healthy = all(c["status"] == "ok" for c in checks)
    return JSONResponse(200 if healthy else 503, {"status": "ok" if healthy else "degraded", "checks": checks})

async def check_database():
    try: await pool.fetchval("SELECT 1"); return {"name": "db", "status": "ok"}
    except Exception as e: return {"name": "db", "status": "error", "error": str(e)}
```

### Outbox Pattern — reliable event publishing

([Transactional Outbox — Chris Richardson](https://microservices.io/patterns/data/transactional-outbox.html))

```python
# messaging/outbox.py
class OutboxRepository:
    def __init__(self, pool): self._pool = pool
    async def save_with_event(self, sql: str, params: tuple, event: DomainEvent):
        async with self._pool.acquire() as conn:
            async with conn.transaction():
                await conn.execute(sql, *params)
                await conn.execute("INSERT INTO outbox (event_type,aggregate_id,payload) VALUES ($1,$2,$3)",
                                   event.event_type, event.aggregate_id, json.dumps(event.payload))
    async def fetch_unpublished(self, limit: int = 100):
        return await self._pool.fetch("SELECT * FROM outbox WHERE published=FALSE LIMIT $1", limit)
    async def mark_published(self, ids: list[str]):
        await self._pool.execute("UPDATE outbox SET published=TRUE WHERE id=ANY($1)", ids)
```

### Saga — distributed transactions

([Saga Pattern — microservices.io](https://microservices.io/patterns/data/saga.html))

```python
# resilience/saga.py
from dataclasses import dataclass
from typing import Callable, Any

@dataclass
class SagaStep:
    name: str; execute: Callable; compensate: Callable

class Saga:
    def __init__(self, steps: list[SagaStep]): self._steps = steps; self._executed: list[SagaStep] = []
    async def execute(self, ctx: dict) -> dict:
        for step in self._steps:
            try: ctx = await step.execute(ctx); self._executed.append(step)
            except Exception:
                for s in reversed(self._executed):
                    try: await s.compensate()
                    except Exception: pass
                raise
        return ctx
```

---

## Composition Root

One file that wires everything. No business logic. ([Composition Root](https://markheath.net/post/dependency-injection-separation-of-concerns), [12-Factor Config](https://12factor.net/config))

```python
# main.py
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import asyncpg

from adapters.middleware import CorrelationIdMiddleware, SecurityHeadersMiddleware, RateLimitMiddleware, register_error_handlers
from adapters.auth.jwt_service import JWTService
from adapters.persistence.postgres import PostgresUserRepository
from adapters.observability.tracing import setup_tracing
from infra.config import settings

tracer = setup_tracing("my-api")

@asynccontextmanager
async def lifespan(app: FastAPI):
    pool = await asyncpg.create_pool(dsn=settings.database_url)
    app.state.user_repo = PostgresUserRepository(pool)
    app.state.jwt = JWTService(settings.jwt_secret.get_secret_value())
    yield
    await pool.close()

app = FastAPI(title="My API", version="1.0.0", lifespan=lifespan, docs_url="/docs" if settings.is_dev else None)
app.add_middleware(CORSMiddleware, allow_origins=settings.cors_origins, allow_credentials=True,
                   allow_methods=["*"], allow_headers=["*"])
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(RateLimitMiddleware, rate=1.0, capacity=20)
app.add_middleware(CorrelationIdMiddleware)
register_error_handlers(app)
app.include_router(users.router, prefix="/api/v1")
app.include_router(health.router)
```

```python
# infra/config.py — fail-fast on bad config
from pydantic_settings import BaseSettings
from pydantic import SecretStr, model_validator

class Settings(BaseSettings):
    environment: str = "development"
    database_url: str = "sqlite+aiosqlite:///./dev.db"
    jwt_secret: SecretStr = SecretStr("")
    cors_origins: list[str] = ["http://localhost:3000"]

    @property
    def is_dev(self) -> bool: return self.environment == "development"

    @model_validator(mode="after")
    def validate_production(self) -> "Settings":
        if self.environment == "production":
            val = self.jwt_secret.get_secret_value()
            if not val or val == "change-me-in-production":
                raise ValueError("jwt_secret MUST be set in production")
        return self

settings = Settings()
```

---

## Testing

### Unit — no mocks, pure functions

([Functional Core](https://www.destroyallsoftware.com/screencasts/series/functional-core-imperative-shell))

```python
async def test_create_user():
    repo = InMemoryUserRepository()
    user = await create_user("a@b.com", "Alice", user_repo=repo, events=FakeEvents(), logger=FakeLogger())
    assert user.email == "a@b.com"
    assert await repo.find_by_id(user.id) == user

async def test_create_user_duplicate_email():
    repo = InMemoryUserRepository()
    await create_user("a@b.com", "Alice", user_repo=repo, events=FakeEvents(), logger=FakeLogger())
    with pytest.raises(DuplicateEmailError): await create_user("a@b.com", "Bob", user_repo=repo, ...)
```

### Contract — verify every adapter satisfies its port

([Contract Testing — Pact](https://pact.io/))

```python
@pytest.fixture(params=["in_memory", "postgres"])
async def user_repo(request):
    if request.param == "in_memory": yield InMemoryUserRepository()
    else: yield PostgresUserRepository(pool=await create_test_pool())

async def test_find_by_id(user_repo):
    user = User.create("a@b.com", "Test"); await user_repo.save(user)
    assert await user_repo.find_by_id(user.id) == user
```

### Fault Injection — test every failure path

```python
class FailingPool:
    async def fetchrow(self, *a, **kw): raise ConnectionError("DB down")

async def test_repo_translates_error():
    with pytest.raises(AppError) as exc: await PostgresUserRepository(FailingPool()).find_by_id("x")
    assert exc.value.status_code == 500
```

### E2E — full API

```python
from httpx import AsyncClient, ASGITransport

async def test_create_and_get_user():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        r = await c.post("/api/v1/users/", json={"email": "a@b.com", "name": "Alice"})
        assert r.status_code == 201
        uid = r.json()["id"]
        r = await c.get(f"/api/v1/users/{uid}")
        assert r.status_code == 200 and r.json()["email"] == "a@b.com"
```

---

## Key Rules

| Rule | Why |
|------|-----|
| Domain imports zero frameworks | Test without infrastructure |
| All errors are `AppError` with `status_code` | Consistent RFC 9457, no string matching |
| Workflows are `async def` | Consistent I/O model |
| Fail-fast validation | Invalid state never propagates |
| Frozen dataclasses + `field(default_factory=...)` | No mutation bugs |
| Correlation ID on every request | Distributed tracing |
| Contract tests per port | Adapter compliance guaranteed |
| Composition root is thin | Single wiring point |
| `SecretStr` + model_validator | Crashes at startup on bad config |

## References

| Pattern | Link |
|---------|------|
| Hexagonal Architecture | [Cockburn](https://web.archive.org/web/20230926092432/https://alistair.cockburn.us/hexagonal-architecture/) |
| RFC 9457 Problem Details | [RFC 9457](https://www.rfc-editor.org/rfc/rfc9457) |
| Repository Pattern | [Fowler](https://martinfowler.com/eaaDev/Repository.html) |
| Circuit Breaker | [Fowler](https://martinfowler.com/bliki/CircuitBreaker.html) |
| Saga Pattern | [microservices.io](https://microservices.io/patterns/data/saga.html) |
| Outbox Pattern | [Chris Richardson](https://microservices.io/patterns/data/transactional-outbox.html) |
| Token Bucket | [Wikipedia](https://en.wikipedia.org/wiki/Token_bucket) |
| Dependency Inversion | [Wikipedia](https://en.wikipedia.org/wiki/Dependency_inversion_principle) |
| Fail-Fast | [Wikipedia](https://en.wikipedia.org/wiki/Fail-fast) |
| 12-Factor App | [12factor.net](https://12factor.net/) |
| OAuth2/JWT | [RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749), [RFC 7519](https://datatracker.ietf.org/doc/html/rfc7519) |
| OWASP API Security | [owasp.org](https://owasp.org/API-Security/) |
| OpenTelemetry | [opentelemetry.io](https://opentelemetry.io/) |
| FastAPI | [fastapi.tiangolo.com](https://fastapi.tiangolo.com/) |
| Pydantic v2 | [docs.pydantic.dev](https://docs.pydantic.dev/) |
| Release It! | [Michael Nygard](https://pragprog.com/titles/mnee2/release-it-second-edition/) |
