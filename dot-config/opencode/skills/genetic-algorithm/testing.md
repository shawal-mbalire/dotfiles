# Testing Strategy

Tests prove the search works before it burns a budget. Every failure path in a run is expensive and often invisible — a bad evaluator or a broken operator produces a confidently wrong report, so the test portfolio is strict: pure domain first, fakes for everything behavioral, real DuckDB for persistence.

## Test Pyramid (GA edition)

| Layer | Test type | Location | Speed | Dependencies | Purpose |
|-------|-----------|----------|-------|--------------|---------|
| Domain | Unit + property | `tests/unit/` | ms | None (pure + fakes) | Operators, dedupe, 1/5 rule, loop logic correct |
| Ports | Contract | `tests/integration/` | ms | None (`:memory:`) | Every adapter/fake honors its port |
| Adapters | Integration | `tests/integration/` | s | Real DuckDB file | Hub, logger, metrics, best-params round-trip |
| Full loop | E2E (tiny) | `tests/e2e/` | s | Fakes or DuckDB | One-island run with fixed seed reaches a known target |
| Failure | Fault injection | `tests/unit/`, `tests/integration/` | ms | Failing fakes | Evaluator/store faults are recorded, never fatal |

See the verification portfolio and confidence gates in [hexagonal-architecture/testing.md](../hexagonal-architecture/testing.md) — property tests, mutation testing, and formal methods apply here unchanged.

## Fakes (in `tests/fixtures/fakes/`)

| Fake | Implements | Behavior |
|------|-----------|----------|
| `FakeEvaluator` | `FitnessEvaluator` | Scores a known landscape (sphere/OneMax-style) or a scripted table |
| `FakeRng` | `RandomPort` | Deterministic sequence; asserts single ownership per island |
| `FakeTime` | `TimePort` | Fixed clock; durations are exact integers |
| `FakeLogger` | `LoggerPort` | Captures `(event, fields)`; assert events and levels without I/O |
| `FakeMetrics` | `MetricsPort` | Captures wide rows; assert curves, sigma, rejection counts |
| `InMemoryBestParams` | `BestParamsRepository` | Append-only list; `latest()` per island |
| `FailingEvaluator` | `FitnessEvaluator` | Raises `AppError GA-002` or times out on command for N genomes |

Fakes implement the same ports as real adapters, so the loop is tested with zero I/O — and the same tests can be rerun against real adapters.

## What to Test

### Operators (pure — property-based where possible)

- **Bounds**: mutation never leaves `params.bounds` (property test over random genomes and sigmas).
- **Determinism**: same seed → identical children; different seed → not identical (with overwhelming probability).
- **Elitism**: `integrate` never drops an existing top-`e` genome; best fitness is monotonic across generations.
- **Dedupe**: `eliminate_duplicates` output contains no genome already in the population; re-drawing terminates within `max_redraws`; rejected count is accurate; `ADMIT` policy passes duplicates through.
- **1/5 rule**: increases sigma at success ratio ≥ 0.2, decreases below, respects floor/ceiling exactly at boundaries.
- **Crossover**: BLX-α children stay near the parent hull for small α; children are the same length as parents.
- **Validity per encoding**: permutations stay permutations; trees stay parseable (replace with the domain's encoding tests).

### Stopping and Verification (pure — property-based)

- **Wilson bounds**: `wilson_upper_bound(0, 0) == 1.0`; monotone non-increasing in `runs` for fixed successes; upper bound ≥ naive `successes / runs`.
- **Coverage math**: `p_miss_after_runs` is non-increasing in `runs`; `required_runs(p, α)` meets `(1-p)^required ≤ α` and misses by one run at `required - 1`.
- **Rule precedence**: `should_stop` returns `certified` before `target`, `target` before budgets, budgets before `p_miss`; returns `("running")` when nothing fires — property-test the ordering with generated threshold combinations.
- **No false certificates**: `build_certificate` never returns `certified`/`bounded` when `lower_bound is None`; `statistical` only when `runs > 0`; `evals_saved` is `max(0, budget − used)`.
- **End-to-end stop**: a scripted fake run stops at the expected reason, writes a `certified` snapshot only with a real bound, and produces a certificate whose `claim` matches the report.

### The Loop (with fakes — no I/O)

- **One generation**: cohorts produce exactly `cohort_size` children each; evaluator is called once per cohort; metrics row per generation; improvement snapshot per new best.
- **Snapshot cadence**: `init`, every improvement, periodic at `snapshot_interval`, `island_stop`, `validated`, `restart`, `final` — assert the reason sequence for a scripted run.
- **Restart**: on diversity collapse + patience, the champion survives, the rest is re-seeded, `restart_count` increments, adaptive sigma resets, max restarts cap is honored.
- **Budget**: run stops exactly at `max_evaluations`/`max_generations`, with reason recorded.
- **Stagnation**: no improvement for `patience` generations stops the island with an `island.stopped` reason.

### Determinism Golden Test (the most valuable test)

```
SEED=42, small population, fake evaluator
→ run the loop twice, byte-for-byte identical snapshot trail
→ compare best-fitness sequence to a checked-in golden file
```

Any code path that sneaks in wall-clock time, global RNG, or non-deterministic iteration order fails this test immediately. Re-run it whenever operators, adaptive rules, or loop ordering change.

### Port Contract Suites (run against fakes and real adapters)

- **`BestParamsRepository`**: `snapshot` is append-only (no row mutated); `latest` returns the highest generation; `latest` of an empty island is `None`; every reason round-trips; resume fingerprint mismatch raises `GA-005`.
- **`FitnessEvaluator`**: same genome + fold + seed → same score; out-of-bounds genome → `GA-001`; evaluator error → `GA-002` with cause preserved; timeout → `GA-003` and the loop continues.
- **`LoggerPort` / `MetricsPort`**: writes never raise on sink failure; dropped/written counters exposed.

### Fault Injection

Standard fault set per driven adapter — connection refused, timeout, malformed payload, partial write, duplicate key, auth failure:

- `FailingEvaluator` → run continues, fault recorded with `code`/`origin`, budget accounted.
- `FailingHub` → logging/metrics failures are swallowed, the search completes, `dropped_records` > 0.
- Snapshot write failure → one `WARN`, search continues (observability must not break the app), `best_params` counts the loss.
- Crash path → `LifetimePort` flushes buffers, writes a `crash` snapshot per island, `run.failed` carries the `AppError` contract.

### Integration (real DuckDB)

- Hub batch insert + `flush` produces the exact row count; schema matches the documented tables.
- Query round-trips: `best_params` time-travel query returns the champion as of generation G.
- Resume: start, kill mid-run (or simulate via `lifetime`), resume from `latest()`, and verify the fingerprint check and continuation.

## Confidence Gates

```just
verify: check test-contract test-fault test-property test-e2e
check: test test-contract errors-check
verify-plus: verify mutation
```

- `just test` — fast unit loop while developing operators or the loop.
- `just test-contract` — every adapter and fake honored its port.
- `just test-fault` — every failure path behaves and is diagnosable.
- `just test-property` — invariants hold for all sampled inputs.
- `just mutation` — nightly gate on the `domain/` mutation score; a surviving mutant is a weak assertion, not a number to raise.
- **Definition of done for a change**: a test at the lowest tier that can catch its failure, a regression test for every bug (with a minimized seed/counterexample), the golden determinism test updated intentionally, and `just verify` green.
