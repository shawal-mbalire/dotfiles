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
    start = time.now_ms()

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

## Design by Contract in the Domain

Validating at the door is the **precondition** half of **Design by Contract (DbC)**. A contract has three clauses, and each belongs at a specific place in the hexagon:

| Contract clause | Where it lives | On failure |
|-----------------|----------------|------------|
| **Precondition** — what the caller must provide | Domain workflow / driving boundary | Raise `ValidationError` (`AppError`, `retryable=False`) — caller error; reject before any side effect |
| **Postcondition** — what the port guarantees on success | Driven port, discharged by the adapter | Raise `ContractViolationError` (`AppError`) — internal/infrastructure failure |
| **Invariant** — what is always true of a domain object | Domain model / aggregate | Raise `ContractViolationError` — a domain bug |

**Write each clause as a pure predicate.** A precondition is a named pure function (`is_valid_amount`); an invariant is a pure function over the aggregate (`is_balanced`). Pure predicates are trivial to test and are reused by the workflow, the adapter, and the contract test.

**Preconditions use explicit raises, never `assert`.** `assert` is compiled out under `python -O` and in release builds, so a check on external input must not rely on it. Reserve `assert` for **internal invariants** that should only fire on a programming error (dev/test).

```python
# domain/models/account.py — an invariant as a pure predicate, enforced on every construction
@dataclass(frozen=True)
class Account:
    id: str
    balance: Decimal

    @staticmethod
    def is_balanced(account: "Account") -> bool:
        return account.balance >= Decimal("0")          # pure predicate

    @classmethod
    def create(cls, id: str, balance: Decimal) -> "Account":
        account = cls(id=id, balance=balance)
        if not cls.is_balanced(account):                # enforce the invariant
            raise ContractViolationError(
                code="DOM-001", message="Account balance cannot be negative",
                context={"account_id": id},
            )
        return account

# domain/workflows/transfer.py — a precondition, checked before any side effect
def is_transferable(amount: Decimal, src: Account) -> bool:
    """Pure precondition predicate: positive and covered by the source balance."""
    return amount > 0 and amount <= src.balance

def transfer(amount: Decimal, src: Account, dst: Account,
             repo: AccountRepository, logger: LoggerPort) -> None:
    # 1. Precondition — caller error, one named pure predicate, explicit raise (never `assert`)
    if not is_transferable(amount, src):
        raise ValidationError(
            code="DOM-002", message="Transfer amount must be positive and available",
            context={"amount": str(amount), "balance": str(src.balance)}, retryable=False,
        )
    # 2. Build the next state through the model factory (invariants enforced)
    src_after = Account.create(src.id, src.balance - amount)
    dst_after = Account.create(dst.id, dst.balance + amount)
    assert src_after.balance + dst_after.balance == src.balance + dst.balance  # dev-only sanity check
    # 3. Persist as one unit of work — the adapter owns the transaction and commits
    #    both accounts atomically; never issue two independent saves from a workflow.
    repo.save_all([src_after, dst_after])
    logger.info("transfer_complete", amount=str(amount))
```

```typescript
// domain/models/Account.ts
export class Account {
  private constructor(public readonly id: string, public readonly balance: Decimal) {}

  static isBalanced(account: Account): boolean {          // pure invariant predicate
    return account.balance.greaterThanOrEqualTo(0);
  }

  static create(id: string, balance: Decimal): Account {
    const account = new Account(id, balance);
    if (!Account.isBalanced(account)) {
      throw new ContractViolationError("DOM-001", "Account balance cannot be negative", { id });
    }
    return account;
  }
}
```

```rust
// domain/src/models/account.rs
impl Account {
    fn is_balanced(&self) -> bool { self.balance >= Decimal::ZERO }   // pure invariant

    pub fn create(id: String, balance: Decimal) -> Result<Account, DomainError> {
        let account = Account { id, balance };
        if !account.is_balanced() {                                   // enforce it
            return Err(DomainError::contract("DOM-001", "account balance cannot be negative"));
        }
        Ok(account)
    }
}
```

**`assert` is a dev-only sanity check.** In Rust use `debug_assert!` and in C++ `assert` only in debug builds; for an invariant that must also hold in production — value conservation, a ledger balance — raise `ContractViolationError` explicitly instead of asserting.

The workflow validation checklist above **is** the precondition list. Put invariants in the model's constructor/factory so every path that builds the object is protected, and let the adapter discharge the port's postconditions (see [Discharging Port Postconditions](./adapters.md#discharging-port-postconditions)).

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
def calculate_total(cart: Cart, tax_rate: float) -> float:
    return cart.subtotal * (1 + tax_rate)

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

### Avoid Monadic Pipelines (Cross-Language)

In languages where errors are values (`Result`, `Option`, `Either`), keep error handling as **flat control flow**, never combinator pipelines. Return `Result`/`Option` from functions and propagate one step at a time with `?`; branch with `match`, guard clauses, and early returns. Do not chain `.and_then`, `.ok_or`, `.map_err`, `.transpose`, or `.flatten` to build control flow — every line must state one intent.

- `ok_or`/`ok` discard the underlying error and break the cause-preserving `AppError` chain
- Inline closures inside chains smuggle logic into data flow — extract a named pure function
- Nested `Result<Option<T>, E>` plus `transpose`/`flatten` hides a second control flow
- One `map_err` is allowed only at the adapter boundary, to translate a vendor error into `AppError` while preserving its `cause` — never in domain code

The full treatment lives in the Rust guide: [Avoid Monadic Pipelines](./rust.md#avoid-monadic-pipelines).

## What Is a Workflow?

A workflow is a **domain operation** — a business action that orchestrates pure functions and ports to achieve a goal. It lives in `domain/workflows/` and is the core of what the app does.

**A workflow is a pure orchestrator that represents a business operation.**

```python
# domain/workflows/create_document.py
def create_document(content: str, repo: DocumentRepository,
                    logger: LoggerPort, time: TimePort) -> Document:
    """Create a document: validate, persist, log, return."""
    start = time.now_ms()
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
- Transient state scoped to the workflow's own lifetime is useful (e.g. an in-flight buffer) — never state shared across instances or processes
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
| State | Stateless (pure) | Transient, instance-scoped — never shared across instances/processes |
| Complexity | Simple workflows | Complex workflows with shared deps |
| Python idiom | Preferred for single operations | Used for lifecycle-bound workflows |
| TypeScript idiom | Less common | Preferred — constructor injection |
| Rust idiom | Preferred (traits for abstraction) | Used for stateful services |
| C++ idiom | Free functions with reference params | Classes for RAII/lifecycle |

**Transient state is allowed; shared state is not.** A workflow instance may hold state for the duration of a single operation or its own lifetime (a buffer, an accumulator, a cursor). What is forbidden is *shared* mutable state: state visible to other instances, other requests, or other processes. When state must outlive the instance or be shared, it belongs in an adapter or backing service, and any buffered state must be flushed via `LifetimePort` on exit. See [State Management](./SKILL.md#state-management).
