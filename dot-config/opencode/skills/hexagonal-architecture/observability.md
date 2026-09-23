# Observability, Diagnostics, and Debugging

## Developer Experience & Debugging

Observability is only as good as the context attached to it. These make an incident debuggable in minutes.

### Version and Context Stamping

- Stamp build version, git SHA, environment, and service on startup **and on every log/metric record** (the adapter does it, not the caller) — you must know which code produced a record.
- Build the version once in `infra/config` (`GIT_SHA`, `APP_VERSION`, `ENVIRONMENT`) and inject it into the logger/metrics adapters.

### Correlation and Tracing

- Generate a `request_id` at the **driving adapter**, pass it through as a context value; log/event adapters attach it automatically.
- Add a `TracerPort` for spans; dev spans land in the DuckDB `spans` table, prod goes to OpenTelemetry. Spans expose cross-adapter latency.

```python
# domain/ports/tracer_port.py
from typing import Protocol

class TracerPort(Protocol):
    def start_span(self, name: str) -> str: ...
    def end_span(self, span_id: str) -> None: ...
```

### Observability Must Not Break the App

- A failed log/metric/event write is **swallowed** (last-resort `stderr`), never propagated into a workflow.
- Buffers are bounded with **drop-oldest**; expose a `dropped_records` counter so loss is visible.
- If the prod observability backend is down, the app keeps serving.

### Dev vs Prod Fail-Fast Posture

Fail-fast behavior must adapt to the environment. In dev, surface every problem immediately. In prod, prioritize availability.

| Concern | Dev | Prod | Rationale |
|---------|-----|------|-----------|
| **Observability failure** | Panic (crash) | Swallow + stderr fallback | Dev: wiring bugs must surface immediately. Prod: logging must never take down the serving path |
| **Adapter health check** | Fail startup | Fail startup | Both environments: an unreachable dependency at startup is always fatal |
| **Config validation** | Fail startup | Fail startup | Both: invalid config means the process cannot operate correctly |
| **Port contract violation** | Panic (assert/check at startup) | Fail startup | Dev: catch type mismatches fast. Prod: catch them at deploy time |
| **Missing adapter (unwired port)** | Panic (None/TypeError) | Fail startup | Both: a missing adapter is never acceptable at runtime |
| **Event consumer poison pill** | Log + DLQ + alert | Log + DLQ + alert | Both: infinite retry wastes resources; silent drop loses data |
| **Rate limiting** | Ignore (no limit) | Enforce + 429 | Dev: no artificial constraints. Prod: protect the system |
| **Circuit breaker tripped** | Log warning | Degrade gracefully + alert | Dev: surface the issue. Prod: serve partial results if possible |

**Rule:** In dev/test, observability failures should panic to surface wiring and configuration issues instantly. In prod, observability failures fall back to `stderr` — resilience takes priority, but the loss must be visible via a `dropped_records` counter.

### Redaction and Privacy

- Redact or allowlist fields in the logger adapter **before** persisting; never log secrets, tokens, passwords, or full PII.
- Treat the dev DuckDB as real data — it may contain real payloads.

### Health, Readiness, and Prod Scrape

- Adapters expose readiness/liveness; the composition root wires `/healthz` and `/readyz`.
- Expose a `/metrics` endpoint in prod (Prometheus), independent of the dev adapter.

### Local DX Commands

| Command | Purpose |
| ------- | ------- |
| `just doctor` | Preflight: env vars, deps, ports, config valid, DB reachable |
| `just seed` | Load fixtures into the dev store |
| `just db-shell` | Inspect the dev DB (through the hub / read-only) |
| `just db-prune` | Apply retention to logs/metrics/events |
| `just db-size` | Dev DB size and row counts per table |
| `just debug` | Run with a debugger attached (`pdb`, `node --inspect`, `gdb`) |
| `just test-watch` | Re-run tests on change |
| `just logs [service]` | Tail streamed logs, filterable by service |

### Debug in Tests

- Fakes for `LoggerPort`/`MetricsPort`/`EventPublisherPort` capture records — assert events, metrics, and `duration_ms` in unit tests with no I/O.
- `MockTimeAdapter` makes durations and poll loops deterministic.
- Validate config and dependencies at startup — a clear startup error beats a mid-request failure.

## Diagnostics & Failure Localization

When something fails, the system must tell you **what failed, where, and why** — without a debugger and without guessing.

### Crash / Panic Handler

Install one process-level handler as part of the composition root. On an unhandled error or panic it must:

1. Capture the **backtrace**, build version/git SHA, and `correlation_id`.
2. Dump the **breadcrumb ring buffer** (the last N logs/events/spans) — see below.
3. Flush buffered logs/metrics/events via `LifetimePort` cleanup so nothing is lost.
4. Exit with a **distinct code per `ExitReason`** (normal / user_exit / crash / timeout / shutdown) so supervisors and scripts can react.

### Breadcrumbs

Keep a small fixed-size ring buffer of recent operations (logger adapter writes to it). On crash, the buffer is included in the report — this is the trail that shows *where* the process was before it died.

### Failure Capture

Every `AppError` crossing a driving-adapter boundary is written to a `diagnostics` table in the dev DuckDB (via the hub `execute` op) with: `ts`, `code`, `origin`, `correlation_id`, `context`, the redacted input, and the build version. Prod forwards the same record to the error backend (Sentry).

### Replay a Failure

Because domain workflows are pure and inputs are captured, a failure is reproducible:

```
# just replay <diagnostic-id> — reloads the captured input and re-runs the workflow
just replay doc-8f3a
```

This turns "works on my machine" into a deterministic, versioned reproduction.

### When It Fails — Capture Checklist

- [ ] `code` + `message` (what) and the full `cause` chain (why)
- [ ] `origin` (which layer/file/line) and `correlation_id` (which request)
- [ ] the redacted `context`/input, and the build version/git SHA
- [ ] breadcrumbs (what happened just before)
- [ ] whether it is `retryable`, and the runbook for that `code`
- [ ] a replay id, so it can be re-run against the exact input

If any item is missing, the fix is to add it — not to work around the failure.

## Logging Strategy

Logging is how you see inside the system at runtime. Good logs let you trace a request through every adapter and pinpoint exactly where something went wrong.

### Log at Adapter Boundaries

The domain doesn't log — adapters do. Log every point where the system crosses a boundary:

```
Driving Adapter receives request
  → Log: request received, request ID, parameters
Driven Adapter calls external service
  → Log: calling [service], request ID, what we're sending
Driven Adapter gets response
  → Log: [service] responded, request ID, status, duration
Driven Adapter gets error
  → Log: [service] failed, request ID, error, retry attempt
Workflow completes
  → Log: workflow [name] completed, request ID, result summary
```

### Structured Logging

Logs must be parseable and searchable. Use structured fields, not string concatenation. The **adapter stamps time** — callers never pass `ts`:

```
# BAD: string concat — impossible to search, impossible to grep
logger.info("User " + user_id + " created order " + order_id)

# GOOD: structured fields — searchable, filterable, aggregatable
logger.info("order_created", user_id=user_id, order_id=order_id, total=total)
```

### Timestamps and Delays

Every log and metric record carries a timestamp so you can see where time is spent. Adapters stamp time from the injected `TimePort` (never a raw `now()`), so it is mockable in tests:

- **Logger** — each record gets `ts`; log `duration_ms` for any operation that crosses a boundary (from `TimePort.elapsed_ms(start)`), so slow calls stand out.
- **Metrics** — every `counter`/`gauge`/`timing` sample gets `ts`; `timing(name, duration_ms)` captures latency directly.
- In dev the DuckDB hub stores `ts` on every row and the `slow_requests` view derives request latency from log timestamps — delays become a SQL query, not a guess.

```
# Adapter stamps ts + duration; the caller supplies only business fields
start = time.now_ms()
repo.save(document)
logger.info("document_saved", document_id=document.id,
            duration_ms=time.elapsed_ms(start))
```

### Request Tracing

Every request gets an ID that follows it through every adapter and layer:

```
[req-abc-123] POST /documents
[req-abc-123] FirestoreAdapter.save: saving document doc-456
[req-abc-123] ConsoleLogger: Document created doc-456
[req-abc-123] POST /documents → 201 Created (45ms)
```

### Log Levels (use them correctly)

| Level | When | Example |
|-------|------|---------|
| `ERROR` | Something failed and needs attention | `Database connection failed: timeout after 5s` |
| `WARN` | Something unexpected but recoverable | `Retrying Firestore call (attempt 2/3)` |
| `INFO` | Normal operations worth recording | `Document created doc-456` |
| `DEBUG` | Detailed troubleshooting info | `FirestoreAdapter.save: collection=docs, id=doc-456` |

**Rule:** Production should run at `INFO` or `WARN`. Drop to `DEBUG` only when investigating a specific issue.
