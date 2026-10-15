# Profiling, Timing, and Performance

**Measure at the edges, never in the domain.** Workflows say *what* happens; how long it took is plumbing. Timing lives in decorators wired by the composition root, spans wrap workflows from the outside, and CPU/memory profiling is tooling run against the process — never a port the domain calls.

| Question | Mechanism | Lives in |
|----------|-----------|----------|
| How long did each port call take, and did it fail? | `Instrumented` decorator around every driven port | `adapters/decorators/`, wired in the composition root |
| How long did the whole workflow take? | `traced(...)` wrapper around the workflow | Composition root |
| Where is CPU / memory going? | Sampling profiler attached to the process | `justfile` recipe (dev), continuous profiler (prod) |
| Is the process healthy over time? | `ProcessSampler` adapter pushing gauges | `adapters/`, started in the composition root |
| Did this change make the domain slower? | Benchmarks of workflows against fakes | `tests/bench/`, gated in CI |

`TimePort` stays in the domain only where time is **business logic** — deadlines, expiry, timeouts, poll intervals (see [TimePort](./lifecycle.md#timeport)).

## Two Clocks

Timestamps and durations need different clocks. A wall clock jumps (NTP sync, DST, manual change); a duration computed from it can go negative or spike. `TimePort` therefore exposes both:

| Method | Clock | Use for |
|--------|-------|---------|
| `now_ms()` | Wall (epoch) | Record timestamps (`ts`), business time (expiry, deadlines) |
| `monotonic_ms()` | Monotonic | Durations only — never stored, never compared across processes |
| `elapsed_ms(start)` | Monotonic | `monotonic_ms() - start`, where `start` came from `monotonic_ms()` |

**Rule:** a value from `monotonic_ms()` is meaningless outside the process that produced it. Never persist it, never put it in an event.

## Port Timing: The `Instrumented` Decorator

One decorator wraps **any** port. It opens a span, times the call on the monotonic clock, and labels the outcome from the railway — so latency splits by error code with no extra code anywhere.

```python
# adapters/decorators/instrumented.py
from typing import Any, Callable
from domain.ports.metrics import MetricsPort
from domain.ports.time_port import TimePort
from domain.ports.tracer_port import TracerPort
from domain.result import Success

def outcome_of(result: object) -> str:
    """Pure: the railway track as a low-cardinality label."""
    return "success" if isinstance(result, Success) else f"failure:{result.error.code}"

class Instrumented:
    """Decorator for any port: one span + one timing per call, labelled by outcome."""

    def __init__(self, inner: Any, name: str, tracer: TracerPort,
                 metrics: MetricsPort, time: TimePort):
        self._inner, self._name = inner, name
        self._tracer, self._metrics, self._time = tracer, metrics, time

    def __getattr__(self, op: str) -> Callable[..., Any]:
        call = getattr(self._inner, op)
        if not callable(call):
            return call
        metric = f"{self._name}.{op}"

        def measured(*args: Any, **kwargs: Any) -> Any:
            span = self._tracer.start_span(metric)
            start = self._time.monotonic_ms()
            outcome = "defect"                       # stays "defect" if the call raises
            try:
                result = call(*args, **kwargs)
                outcome = outcome_of(result)
                return result                        # Result passes through untouched
            finally:
                self._metrics.timing(metric, self._time.elapsed_ms(start), labels={"outcome": outcome})
                self._tracer.end_span(span, status=outcome)
        return measured
```

**Rules:**
- **Outcome labels come from the railway.** `success`, `failure:<code>`, or `defect`. Error codes come from the registry, so the label set is bounded — never label with ids, messages, or user input.
- **Never alter the result.** `Instrumented` returns the inner `Result` unchanged and lets defects propagate (it only records them). Same contract as every [adapter decorator](./adapters.md#decorator--middleware-pattern-for-cross-cutting-concerns).
- **Wrap outermost.** Stack it *outside* retry so one logical call is one span; wrap *inside* retry instead when per-attempt latency is the question.
- **Async ports** get an `InstrumentedAsync` twin whose `measured` is `async def` and awaits the call — same labels, same rules.
- **Other languages:** a TS `Proxy`, a Rust generic wrapper `Instrumented<P: Port>` implementing the port trait (or a small `macro_rules!` per port), a Java dynamic proxy / Kotlin delegation (`by inner`), a hand-written C++ wrapper. Generate it if the port is large; never hand-time inside the adapter.

```python
# main.py — composition root: instrument every driven port in one place
def instrument(port, name):
    return Instrumented(port, name, tracer=tracer, metrics=metrics, time=time)

accounts = instrument(RetryRepository(SqlRepository(...)), "accounts")
ledger   = instrument(PostgresLedger(...), "ledger")
```

## Workflow Spans: Wrap From Outside

The workflow is the parent span; port spans from `Instrumented` nest under it because the tracer adapter keeps the current span in a context variable (`contextvars` / `AsyncLocalStorage` / `tracing::Span::current`).

```python
# infra/tracing.py — composition-root helper
from functools import wraps

def traced(name: str, workflow, tracer: TracerPort, metrics: MetricsPort, time: TimePort):
    @wraps(workflow)
    def run(*args, **kwargs):
        span = tracer.start_span(f"workflow.{name}")
        start = time.monotonic_ms()
        outcome = "defect"
        try:
            result = workflow(*args, **kwargs)
            outcome = outcome_of(result)
            return result
        finally:
            metrics.timing(f"workflow.{name}", time.elapsed_ms(start), labels={"outcome": outcome})
            tracer.end_span(span, status=outcome)
    return run

# main.py
withdraw = traced("withdraw", partial(withdraw, accounts=accounts, ledger=ledger, logger=logger),
                  tracer, metrics, time)
```

The workflow itself has no `start = time.now_ms()`, no `elapsed_ms`, and no `TimePort` parameter unless it uses business time. Its log line records **what** happened; the span records **how long**.

```python
# domain/workflows/create_document.py — no timing code
def create_document(content: str, repo: DocumentRepository,
                    logger: LoggerPort) -> Result[Document]:
    checked = validate_content(content)
    if isinstance(checked, Failure):
        return checked
    doc = Document.create(content=checked.value)
    saved = repo.save(doc)
    if isinstance(saved, Failure):
        return saved
    logger.info("document_created", document_id=doc.id)
    return Success(doc)
```

## Process Profiling (CPU, Memory, Flame Graphs)

Profiling is **infrastructure**, not a port. A sampling profiler attaches to the process from outside; the code never knows.

**Dev — on demand.** One `justfile` recipe per profile kind, output under `build/profile/` (gitignored):

```just
# Record a CPU flame graph of an entry point: just profile main.py
profile *args:
    py-spy record --rate 250 -o {{root}}/build/profile/cpu.svg -- python {{args}}

# Record allocations: just profile-mem main.py
profile-mem *args:
    memray run -o {{root}}/build/profile/mem.bin {{args}} && memray flamegraph {{root}}/build/profile/mem.bin
```

| Language | CPU | Memory / allocations |
|----------|-----|----------------------|
| Python | `py-spy record` (attach with `--pid`, no restart) | `memray`, `tracemalloc` |
| TypeScript / Node | `node --cpu-prof`, `0x`, Chrome DevTools | `node --heap-prof`, heap snapshots |
| Rust | `samply record`, `cargo flamegraph` | `dhat`, `heaptrack` |
| Go | `pprof` (`net/http/pprof` on an admin port) | `pprof -alloc_space` |
| C++ | `perf record -g` + Hotspot | `heaptrack`, `valgrind --tool=massif` |
| JVM | async-profiler, JFR | JFR allocation events |
| Dart / Flutter | DevTools CPU profiler | DevTools memory view |
| MicroPython | `time.ticks_us` around suspect calls (dev builds only) | `gc.mem_free()` gauges |

**Staging / prod — continuous.** A low-overhead sampling profiler (Pyroscope, Parca, OpenTelemetry profiles; ~1–2% CPU) is enabled by config, never by code change:

```python
# infra/config.py — 12FA: the environment decides
@dataclass(frozen=True)
class ProfilingConfig:
    enabled: bool          # PROFILING_ENABLED
    endpoint: str          # PROFILING_ENDPOINT
    sample_hz: int         # PROFILING_SAMPLE_HZ

# main.py — started once, stopped via LifetimePort
if config.profiling.enabled:
    profiler = start_continuous_profiler(config.profiling, tags=version_stamp)
    lifetime.register_cleanup(profiler.stop)
```

Tag profiles with the same version/git SHA stamp as logs and metrics ([Version and Context Stamping](./observability.md#version-and-context-stamping)) so a regression maps to a commit.

## Process Health: The `ProcessSampler`

Resource usage over time (RSS, CPU time, GC, open file descriptors) is a driven concern: a small adapter samples on an interval and pushes gauges through `MetricsPort`. It is a long-running component, so it uses `TimePort.sleep_ms` and `LifetimePort` like any poll loop.

```python
# adapters/process_sampler.py (portable — stdlib only)
import gc
import os
import resource
import time as stdlib_time

class ProcessSampler:
    """Samples process resources every interval_ms and emits gauges."""

    def __init__(self, metrics: MetricsPort, time: TimePort,
                 lifetime: LifetimePort, interval_ms: int):
        self._metrics, self._time, self._lifetime = metrics, time, lifetime
        self._interval_ms = interval_ms

    def run(self) -> None:
        while not self._lifetime.is_shutting_down():
            for name, value in sample_process().items():
                self._metrics.gauge(f"process.{name}", value)
            self._time.sleep_ms(self._interval_ms)

def sample_process() -> dict[str, float]:
    usage = resource.getrusage(resource.RUSAGE_SELF)
    return {
        "max_rss_kb": usage.ru_maxrss,
        "cpu_seconds": stdlib_time.process_time(),
        "gc_collections": sum(s["collections"] for s in gc.get_stats()),
        "open_fds": len(os.listdir("/proc/self/fd")) if os.path.exists("/proc/self/fd") else -1,
    }
```

Start it on a background thread/task from the composition root; never from a workflow.

## Benchmarks

Because workflows are pure orchestrators, a benchmark against in-memory fakes measures **domain cost only** — deterministic, no network noise.

```python
# tests/bench/test_withdraw_bench.py
def test_withdraw_bench(benchmark):
    accounts, ledger = FakeAccountRepository.with_balance("acc-1", Decimal("100")), FakeLedger()
    result = benchmark(withdraw, "acc-1", Decimal("10"), accounts, ledger, FakeLogger())
    assert isinstance(result, Success)               # benchmark the success track, not a Failure
```

- `pytest-benchmark` / `criterion` / `vitest bench` / `testing.B` / JMH / Google Benchmark.
- Benchmark the hot pure functions and the main workflows, both tracks: a slow `Failure` path is still slow.
- `just bench` runs them; CI compares against the stored baseline from `main` and fails on a regression above a set threshold (e.g. 10%). Keep runners fixed — benchmarks on shared CI hardware need a margin.
- I/O latency is not a benchmark concern: measure it with spans in staging and load tests (k6, Locust) against real backing services.

## Testing the Instrumentation

```python
def test_instrumented_labels_failure_and_passes_it_through():
    clock, tracer, metrics = MockTimeAdapter(), FakeTracer(), FakeMetrics()
    inner = SlowFailingRepository(clock, delay_ms=40,
                                  error=StorageUnavailableError("down", retryable=True))
    repo = Instrumented(inner, "accounts", tracer, metrics, clock)

    result = repo.find_by_id("acc-1")

    assert result == inner.last_result                       # unchanged
    assert metrics.timings == [("accounts.find_by_id", 40, {"outcome": "failure:STO-001"})]
    assert tracer.ended == [("accounts.find_by_id", "failure:STO-001")]

def test_instrumented_records_defect_and_reraises():
    repo = Instrumented(CorruptRepo(), "accounts", FakeTracer(), metrics := FakeMetrics(),
                        MockTimeAdapter())
    with pytest.raises(ContractViolationError):
        repo.find_by_id("acc-1")
    assert metrics.timings[0][2] == {"outcome": "defect"}
```

`MockTimeAdapter.advance_ms` moves the monotonic clock, so durations are exact in tests.

## Anti-Patterns

- `start = time.now_ms()` … `elapsed_ms(start)` inside a workflow — timing is a decorator's job; the workflow should read like pseudocode.
- Durations from the wall clock (`time.time()`, `Date.now()`, `SystemTime`) — they jump; use `monotonic_ms()`.
- Persisting or emitting a monotonic value — it has no meaning outside the process.
- A `ProfilerPort` called from the domain — profiling attaches from outside; the domain never knows.
- Metric labels with ids, messages, or user input — cardinality explosion; label with the outcome and registry code only.
- A decorator that swallows a defect or turns a `Failure` into an exception while measuring it.
- Profiling enabled by code edit or a debug branch — it is a config flag.
- Benchmarking against real I/O — the noise hides the domain regression you were looking for.
