# Pure Functions in Domain

Domain workflows should be pure functions wherever possible. This makes testing trivial, eliminates code duplication, and makes the system predictable.

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
