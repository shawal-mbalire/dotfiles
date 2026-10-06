# Railway-Oriented Workflows (Result over Exceptions)

A workflow returns a **`Result`**: either a `Success` carrying the value, or a `Failure` carrying an `AppError`. Expected failures ride a visible "failure track" instead of unwinding the stack. The driving adapter inspects the result once and renders both tracks.

This replaces exception-based control flow for **expected** outcomes. It does not replace exceptions for **defects** — see below.

## Two Kinds of Failure

Not every bad outcome is the same. Routing them the same way is the root of `try/except` spaghetti.

| Kind | Examples | Mechanism |
|------|----------|-----------|
| **Expected domain failure** | validation rejected, insufficient funds, not found, transient vendor outage | Return `Failure(AppError)` on the railway — never raise |
| **Defect** | postcondition violated, invariant breached, programming error, unrecoverable corrupt state | **Raise** `ContractViolationError` (Python/TS) or panic (`panic!`, `throw`) — fail fast |

Only defects halt. Expected failures are values. This is the reconciliation of ROP with [Fail Fast](./SKILL.md#core-principles): invalid *system* state halts; an invalid *request* returns a `Failure`.

**Rule:** if a caller could reasonably branch on the outcome and continue, it is a `Failure`. If it means the program itself is broken, it is an exception/panic.

## The Result Type

`Failure` always carries an **`AppError`** — never a bare string, never a vendor object. That is what keeps `code`, `context`, `cause`, `origin`, `correlation_id`, `retryable`, and `remediation` alive across the port boundary (see [Diagnostic Error Contract](./testing.md#diagnostic-error-contract)).

One type parameter is enough: because `Failure` is always an `AppError`, `Result[T, E]` collapses to `Result[T]`.

```python
# domain/result.py
from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Generic, TypeAlias, TypeVar, Union

from domain.errors.app_error import AppError

T = TypeVar("T")
U = TypeVar("U")

@dataclass(frozen=True, slots=True)
class Success(Generic[T]):
    value: T

@dataclass(frozen=True, slots=True)
class Failure:
    """The failure track. Always an AppError — never a bare string."""
    error: AppError

# Python 3.12+:  type Result[T] = Success[T] | Failure
Result: TypeAlias = Union[Success[T], Failure]
```

`Result` is domain vocabulary: it imports only `AppError` (also domain) and the standard library, so it stays inside the inner ring.

## The Bounded Toolkit

Compose the failure track with a **small, fixed set** of combinators. They exist so a workflow reads top-to-bottom instead of repeating `if isinstance(...)` guards.

```python
# domain/result.py (continued)

def and_then(result: Result[T], step: Callable[[T], Result[U]]) -> Result[U]:
    """Railway switch: run `step` on the success track, short-circuit on failure."""
    if isinstance(result, Failure):
        return result                       # AppError passes through untouched
    return step(result.value)

def map_value(result: Result[T], fn: Callable[[T], U]) -> Result[U]:
    """Transform the success value; leave the failure track alone."""
    if isinstance(result, Failure):
        return result
    return Success(fn(result.value))

def pipeline(start: Result[object],
             *steps: Callable[[object], Result[object]]) -> Result[object]:
    """Left fold with early exit — the only place the track switches."""
    current: Result[object] = start
    for step in steps:
        if isinstance(current, Failure):
            return current
        current = step(current.value)
    return current

def recover(result: Result[T], handler: Callable[[AppError], Result[T]]) -> Result[T]:
    """Explicit, local fallback — the only sanctioned way to leave the failure track."""
    if isinstance(result, Failure):
        return handler(result.error)
    return result
```

**Allowed:**
- `and_then`, `map_value`, `pipeline`, `recover` — in `domain/workflows/` and the composition root.
- Steps are **named functions or `functools.partial`s**. A named step can be tested in isolation and read in the workflow.

**Banned** (this is the surviving half of [Rule 33 — Bounded ROP, No Ad-Hoc Combinators](./SKILL.md#architecture-rules)):
- Error-*translation* combinators used to build control flow: `.map_err`, `.ok_or`, `.ok`, `.unwrap_or_else`, `.transpose`, `.flatten`.
- Inline lambdas/closures that contain business logic — the logic goes in the named step.
- Nesting `Result[Option[T]]` to represent two failure kinds at once.
- Catching a `Failure` inside a workflow and continuing on the success track without `recover` (that is a swallowed error).

## Workflows on the Railway

A workflow is a **pure orchestrator that returns `Result`**. Each step is named, one intent per line.

```python
# domain/workflows/withdraw.py
from decimal import Decimal
from domain.result import Result, Success, Failure, and_then, pipeline
from domain.ports.account_repository import AccountRepository
from domain.ports.ledger import LedgerPort
from domain.ports.logger import LoggerPort
from domain.errors.account_errors import AccountNotFoundError

def validate_withdrawal(account_id: str, amount: Decimal) -> Result[tuple[str, Decimal]]:
    """Pure precondition. Returns the caller's error on the failure track."""
    if not account_id:
        return Failure(ValidationError("ACC-001", "account id is required"))
    if amount <= 0:
        return Failure(ValidationError("ACC-002", "amount must be positive"))
    return Success((account_id, amount))

def load_account(data: tuple[str, Decimal],
                 accounts: AccountRepository) -> Result[tuple[Account, Decimal]]:
    account_id, amount = data
    match accounts.find_by_id(account_id):
        case Failure() as failed:
            return failed                      # port already returned AppError
        case Success(None):
            return Failure(AccountNotFoundError(account_id))
        case Success(account):
            return Success((account, amount))

def debit(data: tuple[Account, Decimal],
          ledger: LedgerPort) -> Result[Balance]:
    account, amount = data
    if amount > account.balance:
        return Failure(ValidationError("ACC-003", "insufficient funds"))
    balance = account.balance - amount         # pure arithmetic
    match ledger.record(account.id, amount):   # port
        case Failure() as failed:
            return failed
        case Success():
            return Success(balance)

# The workflow proper — flat, one intent per line (Rule 33 shape).
def withdraw(account_id: str, amount: Decimal,
             accounts: AccountRepository,
             ledger: LedgerPort,
             logger: LoggerPort) -> Result[Balance]:
    checked = validate_withdrawal(account_id, amount)
    if isinstance(checked, Failure):
        return checked
    loaded = load_account(checked.value, accounts)
    if isinstance(loaded, Failure):
        return loaded
    result = debit(loaded.value, ledger)
    if isinstance(result, Failure):
        logger.error("withdrawal_failed", code=result.error.code)
        return result
    logger.info("withdrawal_complete", balance=str(result.value))
    return result
```

The identical workflow with the toolkit — same steps, no logic in the composition:

```python
from functools import partial

def withdraw(account_id, amount, accounts, ledger, logger) -> Result[Balance]:
    return pipeline(
        validate_withdrawal(account_id, amount),
        partial(load_account, accounts=accounts),   # named step
        partial(debit, ledger=ledger),              # named step
    )
```

Both are valid. Use the flat form when steps need per-step logging or branching; use `pipeline` when the flow is strictly linear.

## Ports on the Railway

A port that can fail in an **expected** way returns `Result`; a port that can only fail by defect keeps raising.

| Port method shape | Return | Meaning |
|-------------------|--------|---------|
| `find_by_id(id)` | `Result[T \| None]` | `Success(None)` is a valid *not found*; `Failure` means the lookup itself failed. Never `None`-because-broken |
| `save(entity)` | `Result[None]` | `Success` when persisted and postcondition discharged; `Failure` for a transient/operational error |
| `charge(...)`, `track_shipment(...)` | `Result[Result]` | domain result on success; translated `AppError` on failure |
| postcondition/invariant breach | **raise** `ContractViolationError` | a defect, not a value |

Adapters still **translate vendor errors to `AppError` at the boundary** — they now return it inside a `Failure`:

```python
# adapters/postgres/account_repository.py (portable)
def find_by_id(self, entity_id: str) -> Result[Account | None]:
    try:
        row = self._execute(self._config.select_sql, (entity_id,)).fetchone()
    except DriverError as e:
        return Failure(StorageUnavailableError(
            cause=e, retryable=True,
            context={"operation": "find_by_id", "adapter": "postgres"},
        ))
    if row is None:
        return Success(None)                       # valid not-found
    account = self._from_row(row)
    if not Account.is_balanced(account):           # invariant breach = defect
        raise ContractViolationError("STO-003", "corrupt account row")
    return Success(account)
```

## Driving Adapters

The driving adapter switches tracks **once** and renders both. No workflow exceptions, no guessing.

```python
@app.post("/withdrawals")
def create_withdrawal(request: WithdrawalRequest) -> Response:
    result = withdraw(
        request.account_id, request.amount,
        accounts=accounts, ledger=ledger, logger=logger,
    )
    match result:
        case Success(balance):
            return JSONResponse({"balance": str(balance)}, status_code=200)
        case Failure(error):
            return JSONResponse(render(error), status_code=http_status_for(error))

def http_status_for(error: AppError) -> int:
    if isinstance(error, ValidationError):
        return 400          # caller error
    if isinstance(error, AccountNotFoundError):
        return 404
    return 500              # internal / defect surfaced as AppError
```

Defects still escape as exceptions and are caught by the process-level crash handler (see [Diagnostics & Failure Localization](./observability.md#diagnostics--failure-localization)).

## Testing

- **Steps are pure** (or take fakes) and tested by asserting on `Success`/`Failure` — no mocking framework.
- **Contract tests** assert the failure track too: an invalid precondition returns `Failure` with the right `code` and `retryable`, and wrote nothing (see [Contract Tests for Ports](./testing.md#contract-tests-for-ports)).
- **Fault injection** feeds a `Failure` from a fake port and asserts the workflow propagates the same `AppError` unchanged; defects are asserted with `pytest.raises` / `expect(...).rejects` / `should_panic`.

```python
def test_withdraw_rejects_empty_id(accounts):
    result = withdraw("", Decimal("10"), accounts, FakeLedger(), FakeLogger())
    assert isinstance(result, Failure)
    assert result.error.code == "ACC-001"
    assert result.error.retryable is False

def test_withdraw_propagates_storage_failure():
    accounts = FailingAccountRepository(StorageUnavailableError("down", retryable=True))
    result = withdraw("acc-1", Decimal("10"), accounts, FakeLedger(), FakeLogger())
    assert isinstance(result, Failure)
    assert result.error.code == "STO-001"
    assert result.error.retryable is True
```

## Language Idioms

| Language | Result idiom | Binder |
|----------|--------------|--------|
| Python | `Success[T]` / `Failure` union | `and_then` / `map_value` / `pipeline` |
| TypeScript | discriminated union `{ ok: true, value }` \| `{ ok: false, error }` | `andThen` / `mapResult` |
| Rust | native `Result<T, DomainError>` | `?` and `match` — no toolkit needed |
| C++ | `std::expected<T, AppError>` (C++23) or `std::variant` | hand-written `and_then` |
| Dart / Flutter | `sealed class Result<T>` + pattern `switch` | `andThen` extension |
| MicroPython | plain `Success`/`Failure` classes | `isinstance` guards (no `match`) |

**Languages with a native `?` are already ROP.** `?` is the railway switch and `match` is the branch, so the stricter half of [Rule 33](./SKILL.md#architecture-rules) applies unchanged: return `Result`, propagate with `?`, branch with `match`, and never chain `.and_then`/`.ok_or`/`.map_err` to build control flow.

**TypeScript:**

```typescript
export type Result<T> = Success<T> | Failure;
export interface Success<T> { readonly ok: true; readonly value: T; }
export interface Failure { readonly ok: false; readonly error: AppError; }

export const ok = <T>(value: T): Success<T> => ({ ok: true, value });
export const fail = (error: AppError): Failure => ({ ok: false, error });

export function andThen<T, U>(result: Result<T>, step: (value: T) => Result<U>): Result<U> {
  return result.ok ? step(result.value) : result;   // short-circuits the failure track
}
```

**Dart:**

```dart
sealed class Result<T> {
  const Result();
}
class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}
class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}

Result<U> andThen<T, U>(Result<T> result, Result<U> Function(T) step) =>
    switch (result) {
      Success<T>(:final value) => step(value),
      Failure<T>() => result as Failure<U>,
    };
```

**MicroPython** (no `match`, no generics): keep two classes and guard with `isinstance`, exactly as the flat Python workflow above.

## Anti-Patterns

- `Failure("Insufficient funds")` — a bare string throws away `code`/`cause`/`origin`; always pass an `AppError`.
- `try/except` around a port inside a workflow — the port should be returning `Failure`; convert at the adapter, not the workflow.
- `return Success(None)` when the backend failed — that is a swallowed error; the failure track exists precisely to prevent it.
- Catching a `Failure` mid-workflow and continuing — use `recover` for an explicit, local fallback or propagate.
- Combinator chains that translate errors (`map_err`/`ok_or`) or hide logic in inline lambdas — the surviving [Rule 33](./SKILL.md#architecture-rules) ban.
