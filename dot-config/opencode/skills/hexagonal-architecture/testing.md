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

# GOOD: hard fail — stops execution, clear error message
result = create_document(content, repo, logger)  # Raises if anything is wrong
assert result.id is not None, f"Document creation failed: {result}"
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

class EmptyContentError(AppError):
    def __init__(self, message="Document content cannot be empty", **kw):
        super().__init__(code="DOC-001", message=message,
                         remediation="Provide non-empty content", **kw)
```

**Rules:**

- **Uniform across layers** — workflows raise `AppError` subclasses; adapters translate vendor errors into `AppError` at the boundary. Nothing returns a raw SDK error, a bare string, or `None`-on-failure.
- **Preserve causality** — always keep the original: Python `raise ... from e`, Rust `#[source]`, Go `%w`, TS `new AppError(msg, { cause })`. A lost cause is a bug.
- **`origin` is filled at the boundary** — the driving/driven adapter sets layer + `module.function:line` and the `correlation_id`; the domain never knows file locations.
- **Context is structured and redacted** — `{"document_id": ..., "operation": "save", "adapter": "postgres"}`; never secrets or PII.
- **One renderer** — `render(error)` for logs, CLI, and HTTP (map `code` → status). Log the full cause chain once, at the boundary.
- **Error-code registry** — every `code` maps to meaning, owner, retryable, and a runbook. `just errors-check` fails CI on unknown or duplicate codes.

```
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

```
# Adapter boundary — translate + enrich, never swallow
try:
    self._pool.execute(self._config.save_sql, params)
except DriverError as e:
    raise AppError(
        code="STO-001", message="Storage write failed", cause=e,
        context={"operation": "save", "adapter": "postgres"},
        origin=origin_here(), correlation_id=correlation_id, retryable=True,
    ) from e
```

#### Optional Returns vs Errors: When `None` Is Acceptable

The rule "never return `None`-on-failure" has a nuance: `None` is legitimate for **"not found" semantics** — the operation succeeded, but the entity doesn't exist. `None` is the anti-pattern when used as a substitute for error reporting.

| Scenario | Return `None`? | Reason |
|----------|----------------|--------|
| `find_by_id("missing-id")` | **Yes** | Entity doesn't exist — `None` is the correct answer |
| `find_by_id("valid-id")` but DB is down | **No** | Operation failed — raise `AppError`, don't return `None` |
| `get_user("unknown-email")` for lookup | **Yes** | Lookup semantics — `None` means "not found" |
| `get_user("unknown-email")` for auth | **No** | Auth failure — raise `AuthorizationError`, don't return `None` |
| `save(entity)` fails due to constraint violation | **No** | Operation failed — raise `ConflictError`, don't return `None` |

**Rule:** If the operation *should* have succeeded but didn't (infrastructure error, constraint violation, timeout), raise an `AppError`. Return `None` only when "nothing found" is the expected, valid outcome of a lookup.

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
    repository.save(entity)
    assert repository.find_by_id("id-1") == entity

def test_find_missing_returns_none(repository):
    assert repository.find_by_id("missing") is None

def test_save_is_idempotent(repository):
    entity = make_entity("id-1")
    repository.save(entity)
    repository.save(entity)                      # upsert, not duplicate
    assert repository.find_all() == [entity]

def test_delete_removes(repository):
    repository.save(make_entity("id-1"))
    repository.delete("id-1")
    assert repository.find_by_id("id-1") is None
```

- **One suite per standard port** (`Repository`, `CachePort`, `KeyValueStorePort`, `BlobStorePort`, `EventPublisherPort`), kept once and run by every adapter.
- **Adapters run it against an ephemeral backend** (temp file, `:memory:`, emulator, testcontainer).
- **Fakes run it too** (minus persistence-specific cases) so fake and real behavior cannot drift.
- A copied-in adapter is only accepted once the contract suite passes in the target project.

## Fault Injection

Happy-path correctness is half the job; the other half is behaving correctly when a dependency fails. Inject failures through fakes and assert both the outcome and the diagnostic.

```python
# tests/unit/test_create_document_faults.py
def test_save_failure_surfaces_storage_error():
    repo = FailingRepo(fail_with=TimeoutError("backend timed out"))
    with pytest.raises(AppError) as exc:
        create_document("Hello", repo, FakeLogger(), FakeTime())
    err = exc.value
    assert err.code == "STO-001"                # right class
    assert err.retryable is True                # right policy
    assert isinstance(err.cause, TimeoutError)  # cause preserved
    assert err.context["operation"] == "save"

def test_observability_survives_sink_failure():
    # logging/metrics must not raise even when their sink is down
    create_document("Hello", FakeRepo(), FailingLogger(), FakeTime())  # must not raise
```

Standard fault set per driven adapter: connection refused, timeout, malformed payload, partial write, duplicate key, auth failure. Assert the `code`, `origin`, `retryable`, and that the failure was logged with the same `correlation_id`.

## Static & Runtime Hardening

Cheap, high-leverage guarantees that catch whole defect classes before tests run:

- **Strict types everywhere** — no implicit `any`/`Any`, exhaustive `match`/`switch`, non-null by default; turn warnings into errors.
- **No panics in production paths** — forbid `unwrap`/`expect` (Rust), `!`/non-null assertions (TS), bare `except` (Python); validate instead.
- **Boundary schema validation** — parse external input (config, HTTP bodies, rows) into typed values at the edge and reject with an `AppError` before it reaches the domain.
- **Invariants as assertions** — debug-only `assert` for pre/postconditions; enabled in dev/test, compiled out in prod.
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

@given(st.integers(min_value=0), st.integers(min_value=0))
def test_total_is_order_independent(price, qty):
    cart = Cart(items=[CartItem(price=price, quantity=qty)])
    assert calculate_total(cart) == calculate_total(cart.reversed())
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
