# Local-First Backing Services (DuckDB Hub)

**Principle:** In development, one local DuckDB database backs **logs, metrics, and events**. Ports never change — only the composition root swaps DuckDB dev adapters for managed prod services. Everything runs locally; production swaps in the real thing with zero code changes.

## Why a single hub process

DuckDB permits **one read-write process per database file** — multiple readers **or** one writer, never both. Multi-process writes require the beta Quack remote protocol or DuckLake with a Postgres catalog; neither is local-only.

A dev workspace runs several processes (`api`, `worker`, `frontend`, `device`), so exactly one process owns the file: the **dev hub**. Every other process — including the `insights` tool — talks to the hub over a local socket. Opening the file directly fails with `Could not set lock`.

## Hub Architecture

```
┌───────────┐   ┌───────────┐   ┌───────────┐
│ api       │   │ worker    │   │ frontend  │   each process constructs
└─────┬─────┘   └─────┬─────┘   └─────┬─────┘   DuckDB* adapters that
      │               │               │          speak the hub protocol
      └───────┬───────┴───────┬───────┘
              ▼               ▼
        local socket / localhost
              │
       ┌──────┴────────┐
       │ adapters/     │   single writer, owns the DuckDB file
       │ duckdb/hub    │   logs | metrics | events | insights views
       └──────┬────────┘
              ▲
       adapters/duckdb/insights   driving adapter — queries through the hub
```

The hub is **not** a new architectural layer. It is a composition root (the same wiring rules as `main`), plus a driven adapter set that talks to DuckDB. It lives at `adapters/duckdb/hub.py` — no new root folder.

## Dev / Prod Adapter Swapping

| Port | Dev (DuckDB hub) | Prod |
|------|------------------|------|
| `LoggerPort` | `DuckDbLoggerAdapter` | Sentry / JSON stdout adapter |
| `MetricsPort` | `DuckDbMetricsAdapter` | Prometheus / Datadog adapter |
| `EventPublisherPort` | `DuckDbEventBusAdapter` | Kafka / RabbitMQ adapter |
| `EventConsumerPort` | `DuckDbEventBusAdapter` | Kafka / RabbitMQ adapter |
| `*Repository` | `DuckDbRepositoryAdapter` | Firestore / Cloud SQL adapter |

The domain, ports, and workflows are identical in every column. Only the composition root's wiring differs.

## Buffered Writes + LifetimePort Flush

DuckDB is optimized for bulk operations; many tiny transactions are slow. Adapters **buffer and flush** on a size threshold, on an interval (via `TimePort.sleep_ms`), and on process exit via `LifetimePort.register_cleanup` — so logs, metrics, and events survive crashes and `SIGTERM`.

## Pubsub: Append + Cursor Poll

DuckDB has no `LISTEN`/`NOTIFY`, so the event bus is an **append-only `events` table plus a per-consumer cursor**:

1. `publish(topic, payload)` — `INSERT` a row with the next `seq` from a sequence.
2. `subscribe(topic, handler)` — poll `WHERE topic = ? AND seq > :cursor ORDER BY seq`, invoke `handler`, persist the cursor, and sleep `poll_interval` via `TimePort.sleep_ms` until `LifetimePort.is_shutting_down()`.

Semantics, documented not hidden: **at-least-once** (consumers must be idempotent), **retention** (trim old events), **latency** bounded by the poll interval, **fan-out** via one cursor row per consumer.

## Insights (Driving Adapter)

`adapters/duckdb/insights.py` answers dev questions by sending read queries **through the hub** (`query` op):

- error rate per service
- p50 / p95 / p99 latency per workflow
- throughput over time
- event lag per consumer cursor

Insights are a driving adapter (like a CLI or admin task), never domain logic.

## Managing Logs, Metrics, and Events Together

One database, three tables, one `ts`. Correlate across them by `request_id` and time — metrics find the *when*, logs/events find the *what*.

```sql
-- Metric spike -> time window -> the failing requests in logs
SELECT request_id, count(*) AS errors, approx_quantile(duration_ms, 0.95) AS p95_ms
FROM logs
WHERE ts > now() - INTERVAL '15 minutes' AND level = 'ERROR'
GROUP BY request_id
ORDER BY p95_ms DESC
LIMIT 20;
```

- **Correlate, don't duplicate** — every log and event carries `request_id` (and `trace_id` for spans); metrics carry **low-cardinality** labels only.
- **Retention** — keep raw rows for a window, not forever. An admin task deletes by `ts` (DuckDB rewrites affected data, so prune on a schedule with coarse windows):

```sql
DELETE FROM logs    WHERE ts < now() - INTERVAL '7 days';
DELETE FROM metrics WHERE ts < now() - INTERVAL '30 days';
DELETE FROM events  WHERE ts < now() - INTERVAL '7 days'
  AND seq <= (SELECT min(last_seq) FROM event_cursors);
```

- **Rollups** — materialize per-minute aggregates so insights read small tables, not raw rows:

```sql
CREATE OR REPLACE TABLE metrics_1m AS
SELECT date_trunc('minute', ts) AS minute, name,
       approx_quantile(value, 0.95) AS p95, count(*) AS n
FROM metrics
GROUP BY 1, 2;
```

- **Cardinality** — never put ids, paths, or user values in metric labels; that belongs in logs/events.
- **Sampling** — sample verbose DEBUG logs (1-in-N); always keep ERROR/WARN and all events.
- **Schema versioning** — version the observability tables separately (`obs_schema_version`) with migrations under `adapters/duckdb/migrations/`; the hub applies them at startup.
- **Size & compaction** — `CHECKPOINT`/`VACUUM`, cap temp size, and watch growth with `just db-size`. `build/` is untracked, so the dev DB is disposable.
- **Inspection** — the hub holds the write lock, so inspect through the hub (`just insights`, or the `query` op) or stop the hub before opening the file with the DuckDB CLI/UI. Never open a second read-write connection.

## Rules

1. **Four root folders only** — `domain/`, `infra/`, `adapters/`, `tests/`. Entry points and the hub are root files or live under an existing dir; never add a root folder for a capability.
2. **The hub is the only writer** — everyone else goes through the hub protocol; never open the file read-only while the hub runs.
3. **Ports are unchanged** — DuckDB types never leak into domain models.
4. **No direct DuckDB access in workflows** — always go through a port.
5. **Buffer and flush** — register the flush handler with `LifetimePort`.
6. **Events are at-least-once** — consumers must be idempotent.
7. **Prod uses real backing services** — the composition root decides; no code changes.
8. **DuckDB is dev/local insight, not prod shared state** — for prod multi-process coordination use Postgres or DuckLake, not a bare file.

Full schema, adapters, hub protocol, escape hatch, and tests: see [python.md](./python.md#local-first-backing-services-duckdb-hub-python).
