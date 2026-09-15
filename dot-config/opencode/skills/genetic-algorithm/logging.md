# Generation Logging

A GA run is a search process; logs are its memory. One structured record per event, with enough context to reconstruct the search from the `logs` table alone.

## Event Taxonomy

| Event | Level | When | Required fields |
|-------|-------|------|-----------------|
| `run.started` | INFO | Composition root begins | `run_id`, `fingerprint`, `k_folds`, `islands`, `budget`, `seed_source` |
| `island.started` | INFO | Island begins evolving | `run_id`, `island_id`, `fold_id`, `seed`, `params`, `train_rows`, `val_rows` |
| `generation.started` | DEBUG | Generation begins | `island_id`, `generation` |
| `cohort.scored` | DEBUG | Cohort evaluated + integrated | `island_id`, `generation`, `cohort`, `size`, `best`, `mean`, `evals_used`, `duration_ms`, `cache_hits` |
| `selection.done` | DEBUG | Parents chosen | `island_id`, `generation`, `cohort`, `selector`, `pressure` |
| `variation.done` | DEBUG | Crossover + mutation applied | `island_id`, `generation`, `cohort`, `p_c`, `p_m`, `effective_p_m` |
| `generation.completed` | INFO | Generation aggregate ready | `island_id`, `generation`, `best`, `mean`, `stddev`, `diversity`, `best_generation`, `evals_total`, `duration_ms` |
| `improvement` | INFO | Island best improved | `island_id`, `generation`, `previous_best`, `best`, `delta` |
| `snapshot.saved` | DEBUG | Periodic/island-stop/validated snapshot written | `island_id`, `generation`, `reason`, `fitness`, `validation` |
| `duplicates.rejected` | DEBUG | Duplicate offspring eliminated (or admitted after retry cap) | `island_id`, `generation`, `cohort`, `count`, `key` |
| `adaptive.updated` | DEBUG | Mutation strength adapted | `island_id`, `generation`, `success_ratio`, `previous_sigma`, `effective_sigma` |
| `local_search.done` | DEBUG | Memetic step executed | `island_id`, `generation`, `cohort`, `searched`, `improved`, `evals_used` |
| `migration.done` | INFO | Island exchange | `from_island`, `to_island`, `generation`, `migrants`, `best_before`, `best_after` |
| `stagnation.warn` | WARN | Patience window exceeded | `island_id`, `generation`, `since_improvement`, `patience` |
| `diversity.low` | WARN | Entropy below floor | `island_id`, `generation`, `diversity`, `floor` |
| `restart` | WARN | Island restarted or reseeded | `island_id`, `generation`, `reason`, `fraction` |
| `evaluation.timeout` | WARN | Genome evaluation exceeded limit | `island_id`, `genome_hash`, `timeout_ms` |
| `evaluation.failed` | WARN | Evaluation raised | `code`, `island_id`, `genome_hash`, `cause`, `penalty`, `retryable` |
| `island.validated` | INFO | Champion scored on validation fold | `island_id`, `champion`, `train_fitness`, `validation_fitness`, `gap`, `generation_found` |
| `island.stopped` | INFO | Island ends | `island_id`, `reason`, `generations`, `evals`, `best`, `duration_ms` |
| `verification.checked` | INFO | Certificate evaluated | `claim`, `best`, `lower_bound`, `gap`, `runs`, `successes`, `p_hi`, `p_miss_upper` |
| `certificate.saved` | INFO | Certificate artifact written | `path`, `claim`, `gap`, `p_miss_upper` |
| `run.stopped_early` | INFO | Evidence-based stop before budget | `reason`, `evals_used`, `evals_saved`, `claim`, `evidence` |
| `holdout.evaluated` | INFO | Overall champion on holdout | `champion_island`, `fitness`, `gap_to_validation`, `protocol` |
| `run.completed` | INFO | All islands done | `run_id`, `reason`, `claim`, `islands`, `mean_validation`, `std_validation`, `best_island`, `evals_total`, `duration_ms` |
| `run.failed` | ERROR | Unhandled failure | `code`, `message`, `context`, `cause`, `origin`, `correlation_id`, `retryable`, `flushed` |

Level guide: `DEBUG` = per-cohort mechanics; `INFO` = per-generation and per-island outcomes; `WARN` = recovery events; `ERROR` = the run is ending abnormally.

## Record Schema

Every record is a flat JSON object. The logger adapter stamps `ts`, `level`, and `run_id` — callers never pass them.

```json
{
  "ts": "2026-09-15T10:00:00.123Z",
  "level": "INFO",
  "event": "generation.completed",
  "run_id": "ga-7f3a91",
  "island_id": 2,
  "fold_id": 2,
  "generation": 57,
  "best": 0.9142,
  "mean": 0.8631,
  "stddev": 0.0219,
  "diversity": 0.418,
  "best_generation": 51,
  "evals_total": 28500,
  "duration_ms": 412
}
```

Naming rules:

- `snake_case` keys, one `event` field, no message prose.
- Fitness fields use `best` / `mean` / `stddev` / `validation` / `holdout` — never `loss` (the GA lingo is fitness).
- `*_ms` for durations, `*_total` for cumulative counters, `*_rate` for ratios.
- `genome_hash` for genome references — never log full genomes at INFO except the champion.
- `run_id`, `island_id`, and `generation` are mandatory context on every record after run start.

## Human-Readable Line

The console presenter derives its line from the same record — one format, two sinks:

```
[island 2/5] gen 057 | best 0.9142 | mean 0.8631 ± 0.0219 | div 0.418 | evals 28.5k | 412ms
```

## Buffering and Flushing

- The dev sink is DuckDB: the logger adapter buffers records and batch-inserts into the `logs` table (`batch_size`, default 200) through the same hub connection as metrics and best-params.
- **Drop-oldest when full** and expose a `dropped_records` counter — visible loss beats unbounded memory.
- **Always flush**: on improvement/best-params snapshot, on island stop, on run end, and from the crash handler.
- DuckDB writes are transactional per batch; the crash handler flushes the buffer before exit so no committed record is lost.
- Keep `run.duckdb` as the source of truth. `log.jsonl` is an optional export (`just export-logs <run_id>`) for `tail`/`grep` workflows; never the primary store.

```sql
CREATE TABLE logs (
    run_id     TEXT,
    level      TEXT,
    event      TEXT,
    island_id  INTEGER,
    generation INTEGER,
    fields     JSON,      -- the rest of the record, unmodified
    ts         TIMESTAMP  -- always the last column; the hub stamps it
);
```

Query the event stream directly:

```sql
SELECT island_id, generation, json_extract(fields, '$.best') AS best
FROM logs
WHERE run_id = 'ga-7f3a91' AND event = 'generation.completed'
ORDER BY generation;
```

## Duration and Time

- Time comes from `TimePort` (monotonic clock), never `datetime.now()` scattered through the loop.
- Every `duration_ms` is computed by the caller from a `start = time.now_ms()` token and passed into the record.
- `generation.completed.duration_ms` is the primary cost signal; `cohort.scored.duration_ms` localizes slow evaluations.

## What to Log Where

| Scope | Level | Volume control |
|-------|-------|----------------|
| Run start/config/fingerprint | INFO | Once |
| Per cohort | DEBUG | Only when debugging or when `--verbose` |
| Per generation | INFO | One line per generation per island |
| Improvements/snapshots/migrations | INFO | On event only |
| Warnings/recoveries | WARN | On event only |
| Validation/holdout/run summary | INFO | Once per island / once per run |
| Failures | ERROR | Once, with full cause |

A default run should emit a readable INFO stream (a few lines per generation per island), a complete DEBUG trail when verbose, and nothing that blocks the search.

## Correlation

- `run_id` is the top-level correlation id. Generate it at the composition root and pass it through every record.
- `island_id` + `generation` + `cohort` locate any event exactly.
- For parallel evaluations, add `worker_id` — never use it in any decision, only in logs.

## Failure Diagnostics

Failures follow the diagnostic contract — one `AppError` shape across domain and adapters:

- `code` (stable, registry-backed, e.g. `GA-004`), `message`, `context` (redacted ids/operation), the full `cause` chain, `origin` (layer + `module.function:line`, set at the boundary), `correlation_id`, `retryable`, and a one-line `remediation`.
- **Never swallow, never return a raw SDK error** — the DuckDB adapter translates driver errors into `AppError` at its boundary; the evaluator adapter translates evaluator faults.
- **Observability writes are the exception** — a failed log/metric/snapshot write is counted and swallowed (the search must not die because DuckDB hiccuped), but it emits one `WARN` with the translator's `code`.
- On `run.failed`, record whether the buffers and best-params were flushed, and the replay hint (`run --resume <run_id>`). The diagnostics checklist is incomplete unless resuming is possible.
- Registry codes used in this skill: `GA-001` invalid genome, `GA-002` evaluation failed, `GA-003` evaluation timeout, `GA-004` budget exhausted, `GA-005` fold/config mismatch on resume, `GA-010` store unavailable, `GA-011` snapshot write failed.
