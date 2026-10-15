# Testing Strategy

Tests prove the system works before it hits production. Every test should fail loudly with a clear message about what broke and why.

## Test Pyramid

| Layer    | Test Type         | Location             | Speed        | Dependencies  | Purpose |
| -------- | ----------------- | -------------------- | ------------ | ------------- | ------- |
| Domain   | Unit Tests        | `tests/unit/`        | Milliseconds | None (pure)   | Prove application logic is correct |
| Adapters | Integration Tests | `tests/integration/` | Seconds      | Real services | Prove adapters connect correctly |
| Main     | End-to-End Tests  | `tests/e2e/`         | Minutes      | Full stack    | Prove the whole system works |

## Verification Portfolio

No single test type proves correctness — stack independent layers. Each tier has a CI gate (see Confidence Gates).

| Tier | What it proves | Tooling |
| ---- | -------------- | ------- |
| Static hardening | Types and boundaries are sound; illegal states can't compile | strict typecheck, linters, `adapters-check` |
| Unit (pure domain) | Logic is correct for known cases | `pytest` / `vitest` / `cargo test` |
| Contract (per port) | Any adapter or fake honors the port | shared contract suites |
| Integration | Adapters talk to real backends | ephemeral DB / emulator / testcontainer |
| Fault injection | Failure paths behave and diagnostics are correct | failing and flaky fakes |
| E2E | The wired system works through driving adapters | HTTP / CLI / UI tests |
| Coverage | Nothing important is unexercised | branch coverage, domain-focused |
| Property-based | Invariants hold for *all* inputs, not just examples | `hypothesis` / `fast-check` / `proptest` |
| Mutation | The tests actually catch defects (verify the verifier) | `mutmut` / Stryker / `cargo-mutants` |
| Formal | The core algorithm/protocol is provably correct | TLA+ / Kani / CBMC / Dafny |

Examples are the floor, not the ceiling: every production bug becomes a regression test at the lowest tier that can catch it.

## Hard-Fail Patterns

**Fail fast, fail loud.** Never swallow errors silently. Every failure must produce a clear, actionable message.

```
# BAD: soft fail — hides the error, makes debugging impossible
try:
    result = create_document(content, repo, logger)
except Exception:
    return None  # What went wrong? Nobody knows.

# GOOD: every outcome is explicit — Failure is handled, defects still raise
match create_document(content, repo, logger):
    case Success(doc):
        assert doc.id is not None, f"Document created without an id: {doc}"
    case Failure(error):
        render(error)            # code, cause, origin, correlation_id — nothing lost
```

```
# BAD: generic assertion — test fails but you don't know why
assert result == expected

# GOOD: specific assertion — test fails with exact mismatch
assert result.status == DocumentStatus.PUBLISHED, (
    f"Expected PUBLISHED, got {result.status}. "
    f"Content: {result.content!r}"
)
```

## Diagnostic Error Contract

**One error type, used by domain and adapters.** Every failure carries enough to answer *what, where, and why*. Subclass it for named domain errors, but everything serializes to this shape.

```
# domain/errors/app_error.py
from dataclasses import dataclass, field

@dataclass(frozen=True)
class AppError(Exception):
    code: str                       # stable, registry-backed (e.g. "DOC-001")
    message: str
    context: dict = field(default_factory=dict)   # ids, operation, inputs (redacted)
    cause: Exception | None = None  # the original error — never discarded
    origin: str = ""                # layer + module.function:line, set at the boundary
    correlation_id: str = ""
    retryable: bool = False
    remediation: str = ""           # one-line hint on how to fix

# Contract families — subclass these, never the base directly.
class ValidationError(AppError):
    """Precondition failure: the caller supplied invalid input (a client error)."""
    def __init__(self, code, message, **kw):
        super().__init__(code=code, message=message, retryable=False, **kw)

class ContractViolationError(AppError):
    """Postcondition or invariant breach: an internal/infrastructure failure."""
    def __init__(self, code, message, **kw):
        super().__init__(code=code, message=message, **kw)

class EmptyContentError(ValidationError):
    def __init__(self, message="Document content cannot be empty", **kw):
        super().__init__(code="DOC-001", message=message,
                         remediation="Provide non-empty content", **kw)
```

**Rules:**

- **Uniform across layers** — expected failures cross every layer as `Failure(AppError)`: workflows return them on the failure track; adapters translate vendor errors into an `AppError` and return it in a `Failure`. Defects still raise. Nothing returns a raw SDK error, a bare string, or `None`-on-failure. See [Railway-Oriented Workflows](./rop.md).
- **Failure payload is always `AppError`** — never a bare string or a vendor object, or the `code`/`cause`/`origin`/`correlation_id` chain is lost before the boundary can render it.
- **Preserve causality** — always keep the original: Python `raise ... from e`, Rust `#[source]`, Go `%w`, TS `new AppError(msg, { cause })`. A lost cause is a bug.
- **`origin` is filled at the boundary** — the driving/driven adapter sets layer + `module.function:line` and the `correlation_id`; the domain never knows file locations.
- **Context is structured and redacted** — `{"document_id": ..., "operation": "save", "adapter": "postgres"}`; never secrets or PII.
- **One renderer** — `render(error)` for logs, CLI, and HTTP (map `code` → status). Log the full cause chain once, at the boundary.
- **Error-code registry** — every `code` maps to meaning, owner, retryable, HTTP status, and a runbook. `just errors-check` fails CI on unknown or duplicate codes. The codes in the examples (`DOC-002`, `DOM-001`, `STO-002`, …) are illustrative; every code that ships must be registered here.
- **Contract families** — `ValidationError` signals a caller error (precondition; `retryable=False`); `ContractViolationError` signals an internal/infrastructure breach (postcondition or invariant). Both are `AppError` subclasses and render through the registry, not by string matching. A `ValidationError` crosses ports as a value inside `Failure`; a `ContractViolationError` is a defect and is raised (Rust: `panic_any`), never returned. Every language uses this one uniform error shape, named `AppError`.

```
# errors.toml
["DOC-001"]
meaning = "Document content is empty"
retryable = false
http_status = 422
runbook = "docs/runbooks/DOC-001.md"

["VAL-000"]
meaning = "One or more invalid fields (see context.violations)"
retryable = false
http_status = 422
runbook = "docs/runbooks/VAL-000.md"

["STO-001"]
meaning = "Storage backend unavailable"
retryable = true
http_status = 503
runbook = "docs/runbooks/STO-001.md"
```

```
# Adapter boundary — translate + enrich, never swallow
try:
    self._pool.execute(self._config.save_sql, params)
except DriverError as e:
    return Failure(StorageUnavailableError(
        code="STO-001", message="Storage write failed", cause=e,
        context={"operation": "save", "adapter": "postgres"},
        origin=origin_here(), correlation_id=correlation_id, retryable=True,
    ))
```

## Optional Returns vs Errors: When `None` Is Acceptable

The rule "never return `None`-on-failure" has a nuance: `None` is legitimate for **"not found" semantics** — the operation succeeded, but the entity doesn't exist. `None` is the anti-pattern when used as a substitute for error reporting.

| Scenario | Return `Success(None)`? | Reason |
|----------|----------------|--------|
| `find_by_id("missing-id")` | **Yes** | Entity doesn't exist — `Success(None)` is the correct answer |
| `find_by_id("valid-id")` but DB is down | **No** | Operation failed — return `Failure(StorageUnavailableError)` |
| `get_user("unknown-email")` for lookup | **Yes** | Lookup semantics — `Success(None)` means "not found" |
| `get_user("unknown-email")` for auth | **No** | Auth failure — return `Failure(AuthenticationError)` |
| `save(entity)` fails due to constraint violation | **No** | Operation failed — return `Failure(ConflictError)` |

**Rule:** If the operation *should* have succeeded but didn't (infrastructure error, constraint violation, timeout), return `Failure(AppError)` (or raise, if it is a defect). `Success(None)` is only when "nothing found" is the expected, valid outcome of a lookup.

```python
# ROP shape: not-found and backend-failure are different tracks
def find_by_id(self, entity_id: str) -> Result[Document | None]:
    row = ...                                   # backend lookup
    if row is None:
        return Success(None)                    # valid not-found
    if not self._ok(row):
        raise ContractViolationError("STO-003", "corrupt row")   # defect
    return Success(self._from_row(row))
```

## Test Directory Structure

**Small projects:**

```
tests/
├── fixtures           # Shared test data and factories
├── unit/
│   └── test_*
├── integration/
│   └── test_*
└── e2e/
    └── test_*
```

**Larger projects:**

```
tests/
├── fixtures/              # Shared test data and factories
│   ├── factories          # Domain model factories
│   ├── builders           # Test data builders
│   └── fakes/             # Fake implementations
│       ├── fake_repos
│       ├── fake_loggers
│       └── fake_adapters
├── unit/
│   └── test_*
├── integration/
│   └── test_*
└── e2e/
    └── test_*
```

## Testing Principles

- **Domain unit tests** use in-memory fakes — no I/O, no frameworks, milliseconds to run
- **Adapter integration tests** hit real services — databases, APIs, file systems
- **E2E tests** exercise the full stack through driving adapters (HTTP, CLI, UI)
- **Fakes implement ports** — same interface as real adapters, but with in-memory storage
- **Factories create test data** — avoid hardcoded test values scattered across tests
- **Every test has one reason to fail** — if a test fails, you know exactly what broke
- **Test names describe behavior** — `test_create_document_rejects_empty_content`, not `test_1`
- **Assert with context** — always include expected vs actual in assertion messages
- **Contract tests per port** — every adapter passes the port's shared contract suite, so drop-in adapters can't drift

## Contract Tests for Ports

Every standard port gets one **contract test suite** that any adapter must pass. It lives with the other integration tests (structure unchanged) and is parameterized over an adapter factory — so a local adapter, a copied-in collection adapter, and a fake all prove the same behavior.

```python
# tests/integration/test_repository_contract.py
import pytest

@pytest.fixture
def repository():
    raise NotImplementedError("override in the adapter's test module")

def test_save_then_find_round_trips(repository):
    entity = make_entity("id-1")
    assert repository.save(entity) == Success(None)
    assert repository.find_by_id("id-1") == Success(entity)

def test_find_missing_returns_success_none(repository):
    assert repository.find_by_id("missing") == Success(None)   # not-found is not a Failure

def test_save_is_idempotent(repository):
    entity = make_entity("id-1")
    assert repository.save(entity) == Success(None)
    assert repository.save(entity) == Success(None)   # upsert, not duplicate
    assert repository.find_all() == Success([entity])

def test_delete_removes(repository):
    repository.save(make_entity("id-1"))
    assert repository.delete("id-1") == Success(None)
    assert repository.find_by_id("id-1") == Success(None)
```

- **One suite per standard port** (`Repository`, `CachePort`, `KeyValueStorePort`, `BlobStorePort`, `EventPublisherPort`), kept once and run by every adapter.
- **Adapters run it against an ephemeral backend** (temp file, `:memory:`, emulator, testcontainer).
- **Fakes run it too** (minus persistence-specific cases) so fake and real behavior cannot drift.
- A copied-in adapter is only accepted once the contract suite passes in the target project.

**Contracts are executable — the DbC clauses are the test cases.** The suite asserts all three: preconditions reject, postconditions hold, invariants are preserved.

```python
# Precondition: invalid input is rejected with the right code, before any side effect.
def test_save_rejects_blank_id(repository, counting_backend):
    result = repository.save(make_entity(id=""))     # documented precondition
    assert isinstance(result, Failure)               # expected failure = a value
    assert isinstance(result.error, ValidationError)
    assert result.error.code == "DOC-002"
    assert result.error.retryable is False
    assert counting_backend.writes == 0              # nothing was persisted

# Postcondition: the round-trip guarantee, not merely "no Failure".
def test_save_postcondition_round_trips(repository):
    entity = make_entity("id-1")
    assert repository.save(entity) == Success(None)
    stored = repository.find_by_id("id-1")
    assert stored == Success(entity)                 # postcondition — never a partial record

# Invariant: every value a port returns satisfies the model's pure predicate.
def test_find_never_returns_invalid_aggregate(repository):
    repository.save(make_entity("id-1"))
    found = repository.find_by_id("id-1")
    assert isinstance(found, Success) and Account.is_balanced(found.value)
```

- **Precondition tests** prove invalid input is returned as `Failure(ValidationError)` *before* a side effect (assert the counting fake wrote nothing).
- **Postcondition tests** prove the guarantee, not just the absence of an exception.
- **Invariant hooks** run the model's pure predicate over every value a port returns.
- **Mutation testing** mutates the predicate (flip `>=` to `>`); if the suite still passes, the contract is not really tested.

## Fault Injection

Happy-path correctness is half the job; the other half is behaving correctly when a dependency fails. Inject failures through fakes and assert both the outcome and the diagnostic.

```python
# tests/unit/test_create_document_faults.py
from domain.result import Success, Failure

def test_save_failure_surfaces_storage_error():
    repo = FailingRepo(fail_with=TimeoutError("backend timed out"))  # returns Failure(...)
    result = create_document("Hello", repo, FakeLogger())

    assert isinstance(result, Failure)           # expected failure = a value
    err = result.error
    assert err.code == "STO-001"                 # right class
    assert err.retryable is True                 # right policy
    assert isinstance(err.cause, TimeoutError)   # cause preserved
    assert err.context["operation"] == "save"

def test_save_contract_violation_is_a_defect():
    # A backend that persists nothing is a defect, not a value: it must raise.
    with pytest.raises(ContractViolationError):
        create_document("Hello", CorruptRepo(), FakeLogger())

def test_observability_survives_sink_failure():
    # logging/metrics must not raise even when their sink is down
    result = create_document("Hello", FakeRepo(), FailingLogger())
    assert isinstance(result, Success)
```

Expected failures assert on `Failure`; **defects are asserted with `pytest.raises` / `expect(...).rejects.toThrow` / `#[should_panic]`.** A fault-injection test must never accept a defect as a value — that is the failure track leaking into the success track.

Standard fault set per driven adapter: connection refused, timeout, malformed payload, partial write, duplicate key, auth failure. Assert the `code`, `origin`, `retryable`, and that the failure was logged with the same `correlation_id`.

Also inject **postcondition violations** — a `save` that returns without persisting, a gateway payload missing a required field — and assert they surface as `ContractViolationError` with the `cause` preserved, never as a silent default or a `None`.

## Static & Runtime Hardening

Cheap, high-leverage guarantees that catch whole defect classes before tests run:

- **Strict types everywhere** — no implicit `any`/`Any`, exhaustive `match`/`switch`, non-null by default; turn warnings into errors.
- **No accidental panics in production paths** — forbid `unwrap`/`expect` (Rust), `!`/non-null assertions (TS), bare `except` (Python); return `Failure` instead. The only sanctioned panic/raise is a deliberate defect (`ContractViolationError` / `std::panic::panic_any(ContractViolation { .. })`).
- **Boundary schema validation** — parse external input (config, HTTP bodies, rows) into typed values at the edge and return `Failure(ValidationError)` before it reaches the domain.
- **Internal sanity checks as assertions** — debug-only `assert` for things only a programming error could break; compiled out in prod. Preconditions return `Failure`; postconditions and production invariants raise `ContractViolationError` explicitly ([Design by Contract](./domain.md#design-by-contract-in-the-domain)).
- **Memory/UB safety** — Rust `Miri`, C++/Rust AddressSanitizer + UndefinedBehaviorSanitizer + ThreadSanitizer, valgrind; race detector for concurrent adapters.

## Reproducibility

A test or replay is only conclusive if the run is reproducible.

- **Seeded randomness** — inject a `RandomPort`; prod uses a secure source, dev/test a fixed seed. Never call the global RNG in domain or adapters.
- **Frozen time** — `MockTimeAdapter` in tests; `TimePort` everywhere else.
- **Pinned dependencies and toolchains** — lockfiles committed, toolchain versions pinned, build in a container/devcontainer.
- **Deterministic builds** — same inputs produce the same artifact; `build/` is always recreatable.

## Confidence Gates & Definition of Done

Nothing merges unless the gates pass. `just check` is the fast local loop; `just verify` is the full gate:

```just
verify: lint typecheck adapters-check errors-check test-unit test-contract test-integration test-fault test-e2e
    # Full gate — run before merge and in CI
verify-hard:
    just verify && just sanitizers   # memory/UB sanitation — nightly / pre-release
verify-plus:
    just verify && just test-property && just mutation   # verify the verifier — nightly
replay id:
    uv run python cli.py replay {{id}}   # re-run a captured failure deterministically
```

**Definition of done for a change:** it has a test at the lowest tier that can catch its failure, a regression test for any bug fixed, no new untriaged `code`, and `just verify` is green. 100% certainty is impossible — the goal is that every defect is either prevented by a gate or pinpointed by a diagnostic.

**Contract test deployment gate:** An adapter is not production-ready until its port's contract test suite passes — no exceptions. A copied-in adapter from a collection must pass the contract suite in the target project before it is accepted. If a contract test fails, the adapter is broken, not the test. Fix the adapter, not the test or the gate.

## Property-Based Testing

Instead of enumerating examples, state invariants and let the tool generate inputs (and shrink failures to minimal counterexamples). Properties live with the pure domain.

```python
from hypothesis import given, strategies as st

@given(st.lists(st.text()))
def test_encode_decode_round_trips(documents):
    assert [decode(encode(d)) for d in documents] == documents

@given(st.lists(st.tuples(st.integers(min_value=0), st.integers(min_value=1))))
def test_total_is_order_independent(items):
    cart = Cart(items=[CartItem(price=p, quantity=q) for p, q in items])
    reversed_cart = Cart(items=list(reversed(cart.items)))
    assert calculate_total(cart, tax_rate=0.0) == calculate_total(reversed_cart, tax_rate=0.0)
```

A failing property prints the **minimal** counterexample — that is the "exactly how it failed" you want. Add each discovered counterexample as a regression example test.

## Mutation Testing (Verify the Verifier)

Coverage says code ran; mutation says the tests would *notice* if it broke. Tooling mutates the source (flip operators, drop calls, change constants); a mutant that survives means a missing or weak assertion.

- Python `mutmut` / `cosmic-ray`, TS `StrykerJS`, Rust `cargo-mutants`, C++ `mull`.
- Gate on a **mutation score threshold** for the domain package (not the whole repo); investigate survivors, don't blindly raise the number.
- Run nightly / pre-release, not on every commit (it is slow).

## Formal Methods (Highest Assurance)

For the small, high-risk core (a protocol, a scheduler, a financial calculation, a state machine), prove properties instead of sampling them:

- **Model checking** — TLA+/PlusCal (design) or Quint + Apalache for temporal/consensus properties.
- **Bounded verification of real code** — Kani (Rust), CBMC/ESBMC (C/C++): prove panics/overflow/assertions cannot occur within bounds.
- **Deductive verification** — Dafny / Frama-C / SPARK for functional correctness proofs.
- **Types as proofs** — push invariants into the type system (newtypes, typestate, exhaustive enums) so invalid states are unrepresentable.

Keep the pure domain small and side-effect-free so it is tractable to verify; the adapters around it stay conventional.

## Progressive Delivery (Fail Safe in Prod)

Confidence does not end at merge — assume something will slip through and bound the blast radius:

- **Feature flags** — a `FeatureFlagPort`; ship dark, enable per environment/tenant. Rollback = flip the flag.
- **Canary** — roll the new artifact to a small slice, watch error rate/latency/`code` distribution, then ramp.
- **Health and deep checks** — `/healthz` (process up) and `/readyz` (dependencies reachable); a failing deep check removes an instance from rotation instead of serving errors.
- **Automatic rollback** — alert on the same metrics/logs the DuckDB hub already captures; revert on threshold breach.
- **Blast-radius limits** — timeouts, circuit breakers, bulkheads, and idempotency keys so one failing dependency degrades instead of cascading.
