# Pure Functions

Every function that can be pure must be pure. This applies everywhere — domain, adapters, tests. The only impure functions are thin I/O methods in adapters and the wiring in the composition root. This makes testing trivial, eliminates code duplication, and makes the system predictable.

## What is a Pure Function?

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

## Pure Functions in Domain Workflows

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

## Pure Function Benefits

| Aspect | Impure | Pure |
|--------|--------|------|
| **Testing** | Mock everything, setup/teardown | Call function, check result |
| **Duplication** | Logic scattered across I/O | Logic concentrated in one place |
| **Debugging** | Trace through layers | Test function in isolation |
| **Refactoring** | Fear of breaking side effects | Safe to rearrange pure logic |

## Validate at the Door (Fail Fast in Domain)

Domain workflows validate their inputs as their **first action**. Invalid state must not propagate into side effects. If a workflow is given bad data, it must reject immediately — before calling any adapter, before touching any resource.

```python
# BAD: validation buried after side effects
def create_document(content: str, repo: DocumentRepository, logger: LoggerPort) -> Document:
    document = Document.create(content=content)
    repo.save(document)                          # saved bad data
    if not content.strip():
        raise EmptyContentError()                # too late — already persisted
    return document

# GOOD: validation is the first thing
def create_document(content: str, repo: DocumentRepository, logger: LoggerPort) -> Document:
    # 1. Validate inputs — fail fast before any side effects
    if not content.strip():
        raise EmptyContentError()

    # 2. Only then proceed with side effects
    document = Document.create(content=content)
    repo.save(document)
    return document
```

**Workflow validation checklist:**

- [ ] Validate every input parameter at the top of the workflow
- [ ] Reject with a domain-specific `AppError` subclass (never `ValueError` or bare strings)
- [ ] Validate before calling any adapter — no side effects on invalid input
- [ ] Check preconditions (required fields, ranges, business rules) before orchestration
- [ ] Validate domain model invariants when constructing models (e.g., `Document.create()` validates internally)
- [ ] Fail with enough context to diagnose: what was invalid, what was expected

## Pure Function Testing Pattern

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

## Two Kinds of Code: Pure Functions and Pure Orchestrators

Every function in the system is one of two kinds. Know which one you're writing.

**Pure functions** — logic only, no port calls. Same input → same output. Trivial to test.

```python
def calculate_total(items: list[CartItem], tax_rate: float) -> float:
    subtotal = sum(item.price * item.quantity for item in items)
    return subtotal * (1 + tax_rate)

def validate_content(content: str) -> None:
    if not content.strip():
        raise EmptyContentError()

def apply_discount(total: float, discount_pct: float) -> float:
    return total * (1 - discount_pct)
```

**Pure orchestrators** — coordinate pure functions and port calls. No business logic inline. Testable by faking ports.

```python
def create_document(
    content: str,
    repo: DocumentRepository,
    logger: LoggerPort,
) -> Document:
    validate_content(content)           # pure function
    doc = Document.create(content=content)  # pure function
    repo.save(doc)                      # port call
    logger.info(f"Created {doc.id}")    # port call
    return doc
```

**The split prevents jack-of-all-trades functions.** If a function does validation + logic + I/O, extract the validation and logic into pure functions and keep the orchestration thin. Every function should be either a pure function (test by calling) or a pure orchestrator (test by faking ports). Nothing in between.

## What Is a Workflow?

A workflow is a **domain operation** — a business action that orchestrates pure functions and ports to achieve a goal. It lives in `domain/workflows/` and is the core of what the app does.

**A workflow is a pure orchestrator that represents a business operation.**

```python
# domain/workflows/create_document.py
def create_document(content: str, repo: DocumentRepository,
                    logger: LoggerPort, time: TimePort) -> Document:
    """Create a document: validate, persist, log, return."""
    validate_content(content)
    doc = Document.create(content=content)
    repo.save(doc)
    logger.info(f"Created {doc.id} in {time.elapsed_ms(start)}ms")
    return doc

# domain/workflows/authenticate_user.py
def authenticate_user(email: str, password: str,
                      user_repo: UserRepository,
                      hasher: PasswordHasher,
                      token_service: TokenService) -> str:
    """Authenticate user: look up, verify, generate token."""
    user = user_repo.find_by_email(email)
    if user is None:
        raise AuthenticationError("Invalid credentials")
    if not hasher.verify(password, user.password_hash):
        raise AuthenticationError("Invalid credentials")
    return token_service.generate(user.id)

# domain/workflows/process_payment.py
def process_payment(order: Order, gateway: PaymentGateway,
                    repo: PaymentRepository, logger: LoggerPort) -> PaymentResult:
    """Process payment: charge via gateway, record, log."""
    result = gateway.charge(order.total, order.payment_token)
    payment = Payment.create(order_id=order.id, result=result)
    repo.save(payment)
    logger.info(f"Payment {payment.id} processed for order {order.id}")
    return result
```

**What makes a workflow a workflow:**
- It lives in `domain/workflows/`
- It takes ports as arguments (never adapters, never config, never framework objects)
- It orchestrates pure functions and port calls
- It contains business logic (validation, rules, decisions)
- It has no knowledge of databases, APIs, files, or frameworks
- It is testable by faking the ports

**What a workflow is NOT:**
- Not a driving adapter (HTTP route, CLI handler) — those call workflows
- Not a driven adapter (DB client, API client) — those implement ports
- Not an entry point (main.py) — those wire adapters to workflows
- Not a pure function — workflows call ports (impure), but contain no inline logic

**The relationship:**

```
Driving adapter (HTTP route) calls → Workflow (business operation) calls → Ports → Adapters do I/O
     ↑                                    ↑                                    ↑
  Entry point wires                 Domain logic                     Infrastructure
```

## Adapter Impurity is Fine — But Use Pure Functions Inside

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

## Workflow Style: Functions vs Classes

Domain workflows can be implemented as free functions or classes. Both are valid; the choice depends on language conventions and workflow complexity.

**Use free functions when:**
- The workflow is a single operation (create, update, delete)
- No internal state between invocations
- Simpler to test (call function, check result)
- Idiomatic in Python and Rust

```python
# Python: free function (preferred for simple workflows)
def create_document(
    content: str,
    repo: DocumentRepository,
    logger: LoggerPort,
    time: TimePort,
) -> Document:
    start = time.now_ms()
    if not content.strip():
        raise EmptyContentError()
    document = Document.create(content=content)
    repo.save(document)
    logger.info(f"Created {document.id} in {time.elapsed_ms(start)}ms")
    return document
```

```rust
// Rust: free function (idiomatic)
pub fn save_document(
    content: &str,
    repo: &dyn FileRepository,
    logger: &dyn Logger,
    time: &dyn TimePort,
) -> Result<Document, DomainError> {
    let start = time.now_ms();
    if content.trim().is_empty() {
        return Err(DomainError::empty_content());
    }
    let doc = Document { id: uuid::Uuid::new_v4().to_string(), content: content.to_string() };
    repo.save(&doc)?;
    logger.info(&format!("Created {} in {}ms", doc.id, time.elapsed_ms(start)));
    Ok(doc)
}
```

**Use classes when:**
- The workflow has multiple related operations (CRUD lifecycle)
- Shared state or configuration between operations
- Language convention favors classes (TypeScript, C++)
- Need to register lifecycle hooks (e.g., `LifetimePort`)

```typescript
// TypeScript: class (when multiple operations share state)
export class AddToCartWorkflow {
  constructor(
    private cartRepo: CartRepository,
    private stockChecker: StockChecker,
    private logger: Logger,
    private time: TimePort,
  ) {}

  async execute(productId: string, quantity: number, price: number): Promise<Cart> {
    // ... business logic
  }

  async removeItem(productId: string): Promise<Cart> {
    // ... uses same injected dependencies
  }
}
```

```python
# Python: class (when lifecycle hooks are needed)
class DataCollector:
    def __init__(self, sensor: SensorPort, storage: StoragePort,
                 lifetime: LifetimePort, time: TimePort):
        self.sensor = sensor
        self.storage = storage
        self.time = time
        lifetime.register_cleanup(self._flush)

    def collect(self):
        reading = self.sensor.read()
        self.storage.save(reading)

    def _flush(self):
        # cleanup logic
        pass
```

**Tradeoffs:**

| Aspect | Free Functions | Classes |
|--------|---------------|---------|
| Testing | Trivial — call function, check result | Create instance, call methods |
| State | Stateless (pure) | Can hold state between calls |
| Complexity | Simple workflows | Complex workflows with shared deps |
| Python idiom | Preferred for single operations | Used for lifecycle-bound workflows |
| TypeScript idiom | Less common | Preferred — constructor injection |
| Rust idiom | Preferred (traits for abstraction) | Used for stateful services |
| C++ idiom | Free functions with reference params | Classes for RAII/lifecycle |
