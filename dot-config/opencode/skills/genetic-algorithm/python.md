# Python Reference Implementation

Language-agnostic architecture with Python as the reference. Any language maps 1:1: frozen structs → records, Protocols → interfaces/traits, pure functions → pure functions. The structure follows the `hexagonal-architecture` skill: exactly four root directories, pure domain, ports for every boundary, adapters for plumbing.

Layout (see [testing.md](./testing.md) for the test tree):

```
domain/
├── models.py          # Genome, Scored, IslandParams, IslandConfig, RunConfig, Snapshot, Certificate, enums
├── errors.py          # AppError + GA registry codes
├── operators.py       # pure selection/crossover/mutation/dedupe/integration/1-5 rule
├── evolution.py       # cohort + generation + island loops (pure orchestration)
├── stopping.py        # pure stopping rules + Wilson/coverage certificates
├── run.py             # fold construction, migration, validation, holdout, certificate
└── ports/
    ├── evaluator.py   # FitnessEvaluator
    ├── logger.py      # LoggerPort
    ├── metrics.py     # MetricsPort
    ├── presenter.py   # PresenterPort
    ├── clock.py       # TimePort
    ├── random.py      # RandomPort
    ├── lifetime.py    # LifetimePort
    └── best_params.py # BestParamsRepository
adapters/
├── duckdb/
│   ├── hub.py            # connection + batch buffers — driver only, portable
│   ├── duckdb_config.py  # frozen config struct
│   ├── duckdb_mappings.py# pure row <-> domain conversions (injected)
│   ├── logger.py         # LoggerPort → logs table
│   ├── metrics.py        # MetricsPort → generations/cohorts tables
│   └── best_params.py    # BestParamsRepository → best_params/champions
├── system_lifetime.py
├── system_clock.py
└── rich_presenter.py
infra/config.py        # RunConfig from env/JSON
main.py                # composition root
tests/                 # unit | integration | e2e | fixtures
```

## Domain Models

```python
# domain/models.py
from dataclasses import dataclass
from enum import Enum
from typing import Sequence


class DuplicatePolicy(str, Enum):
    REDRAW = "redraw"   # try to mutate the clone away, then reject
    ADMIT = "admit"     # let duplicates through (counted)


class ExitReason(str, Enum):
    NORMAL = "normal"
    USER_EXIT = "user_exit"
    CRASH = "crash"
    TIMEOUT = "timeout"
    SHUTDOWN = "shutdown"


@dataclass(frozen=True)
class Genome:
    genes: tuple[float, ...]


@dataclass(frozen=True)
class Scored:
    genome: Genome
    fitness: float


@dataclass(frozen=True)
class IslandParams:
    population_size: int = 100
    cohort_size: int = 40
    generations: int = 200
    crossover_rate: float = 0.85
    crossover_alpha: float = 0.5
    mutation_rate: float = 0.08
    mutation_sigma: float = 0.1
    adaptive_mutation: bool = True
    mutation_factor: float = 2.0
    sigma_floor: float = 1e-4
    sigma_ceiling: float = 0.5
    tournament_size: int = 3
    elite_count: int = 3
    migration_interval: int = 20
    migrants: int = 2
    bounds: tuple[float, float] = (-1.0, 1.0)
    gene_count: int = 20
    duplicate_policy: DuplicatePolicy = DuplicatePolicy.REDRAW
    max_redraws: int = 3
    ls_probability: float = 0.2
    ls_steps: int = 10
    diversity_floor: float = 0.2
    restart_patience: int = 25
    max_restarts: int = 2


@dataclass(frozen=True)
class IslandConfig:
    island_id: int
    fold_id: int
    seed: int
    params: IslandParams


@dataclass(frozen=True)
class RunConfig:
    run_id: str
    islands: Sequence[IslandConfig]
    max_evaluations: int
    max_seconds: int = 3600
    stagnation_patience: int = 25
    holdout_fold: int = 0
    snapshot_interval: int = 1
    target_fitness: float = 1.0
    miss_alpha: float = 1e-3          # stop when P(miss) <= alpha over independent runs
    bound_tolerance: float = 1e-6     # gap <= tolerance closes the certificate


@dataclass(frozen=True)
class Snapshot:
    island_id: int
    generation: int
    reason: str          # init | improvement | periodic | validated | restart | certified | final | crash
    best: Scored
    validation: float | None = None


@dataclass(frozen=True)
class Certificate:
    claim: str           # certified | bounded | statistical | best_so_far
    best: float
    lower_bound: float | None
    gap: float | None
    runs: int
    successes: int
    p_hi: float
    p_miss_upper: float
    stop_reason: str
    evals_saved: int
```

## Domain Errors

```python
# domain/errors.py
from dataclasses import dataclass, field


@dataclass(frozen=True)
class AppError(Exception):
    code: str
    message: str
    context: dict = field(default_factory=dict)
    cause: Exception | None = None
    origin: str = ""
    correlation_id: str = ""
    retryable: bool = False
    remediation: str = ""


def evaluation_failed(genome_hash: str, cause: Exception) -> AppError:
    return AppError(code="GA-002", message="Genome evaluation failed",
                    context={"genome_hash": genome_hash}, cause=cause,
                    remediation="Inspect the evaluator and the genome encoding")


def evaluation_timeout(genome_hash: str, timeout_ms: int) -> AppError:
    return AppError(code="GA-003", message="Genome evaluation timed out",
                    context={"genome_hash": genome_hash, "timeout_ms": timeout_ms},
                    retryable=True, remediation="Raise the timeout or simplify the genome")


def fold_mismatch(expected: str, actual: str) -> AppError:
    return AppError(code="GA-005", message="Fold/config mismatch on resume",
                    context={"expected_fingerprint": expected, "actual": actual},
                    remediation="Resume with the original config or start a new run")
```

| Code | Meaning | Retryable |
|------|---------|-----------|
| `GA-001` | Invalid genome (bounds/schema) | no |
| `GA-002` | Evaluation failed | dep. on cause |
| `GA-003` | Evaluation timed out | yes |
| `GA-004` | Budget exhausted mid-operation | no |
| `GA-005` | Fold/config mismatch on resume | no |
| `GA-010` | DuckDB/store unavailable | yes |
| `GA-011` | Snapshot write failed (swallowed, counted) | yes |

## Ports

```python
# domain/ports/evaluator.py
from typing import Protocol, Sequence
from domain.models import Genome

class FitnessEvaluator(Protocol):
    def evaluate_many(self, genomes: Sequence[Genome], fold_id: int) -> list[float]: ...
```

```python
# domain/ports/logger.py  —  adapter stamps ts, level, and run_id
from typing import Protocol

class LoggerPort(Protocol):
    def debug(self, event: str, **fields: object) -> None: ...
    def info(self, event: str, **fields: object) -> None: ...
    def warn(self, event: str, **fields: object) -> None: ...
    def error(self, event: str, **fields: object) -> None: ...
```

```python
# domain/ports/metrics.py  —  one call = one wide row (GA metrics are tabular, not counters)
from typing import Protocol

class MetricsPort(Protocol):
    def record(self, **fields: object) -> None: ...
```

```python
# domain/ports/clock.py
from typing import Protocol

class TimePort(Protocol):
    def now_ms(self) -> int: ...
    def elapsed_ms(self, start_ms: int) -> int: ...
    def now_iso(self) -> str: ...   # adapter-stamped timestamps
```

```python
# domain/ports/random.py  —  ambient capability; random.Random conforms structurally
from typing import Protocol, Sequence, TypeVar

T = TypeVar("T")

class RandomPort(Protocol):
    def random(self) -> float: ...
    def uniform(self, a: float, b: float) -> float: ...
    def gauss(self, mu: float, sigma: float) -> float: ...
    def randint(self, a: int, b: int) -> int: ...
    def sample(self, population: Sequence[T], k: int) -> list[T]: ...
```

```python
# domain/ports/lifetime.py
from typing import Callable, Protocol
from domain.models import ExitReason

class LifetimePort(Protocol):
    def register_cleanup(self, handler: Callable[[], None]) -> None: ...
    def on_exit(self, handler: Callable[[ExitReason], None]) -> None: ...
    def get_exit_reason(self) -> ExitReason: ...
    def is_shutting_down(self) -> bool: ...
```

```python
# domain/ports/best_params.py  —  append-only snapshot trail
from typing import Protocol
from domain.models import Snapshot

class BestParamsRepository(Protocol):
    def snapshot(self, snapshot: Snapshot) -> None: ...
    def latest(self, island_id: int) -> Snapshot | None: ...
```

`PresenterPort` lives in [presentation.md](./presentation.md). No port exists for operators, dedupe, the 1/5 rule, or local search policy — those are pure logic ([Port Taxonomy](../hexagonal-architecture/ports.md#port-taxonomy-when-to-add-a-port)).

## Pure Operators

```python
# domain/operators.py
from typing import Sequence
from domain.models import DuplicatePolicy, Genome, IslandParams, Scored
from domain.ports.random import RandomPort


def tournament_select(population: Sequence[Scored], k: int, rng: RandomPort) -> Scored:
    return max(rng.sample(list(population), k), key=lambda scored: scored.fitness)


def blx_crossover(a: Genome, b: Genome, alpha: float,
                  rng: RandomPort) -> tuple[Genome, Genome]:
    genes_a, genes_b = [], []
    for left, right in zip(a.genes, b.genes):
        lo, hi = min(left, right), max(left, right)
        span = hi - lo
        genes_a.append(rng.uniform(lo - alpha * span, hi + alpha * span))
        genes_b.append(rng.uniform(lo - alpha * span, hi + alpha * span))
    return Genome(tuple(genes_a)), Genome(tuple(genes_b))


def mutate(genome: Genome, params: IslandParams, sigma: float,
           rng: RandomPort) -> Genome:
    lo, hi = params.bounds
    genes = tuple(
        min(hi, max(lo, gene + rng.gauss(0.0, sigma)))
        if rng.random() < params.mutation_rate else gene
        for gene in genome.genes
    )
    return Genome(genes)


def breed(population: Sequence[Scored], count: int, params: IslandParams,
          sigma: float, rng: RandomPort) -> list[Genome]:
    children: list[Genome] = []
    while len(children) < count:
        parent_a = tournament_select(population, params.tournament_size, rng).genome
        if rng.random() < params.crossover_rate:
            parent_b = tournament_select(population, params.tournament_size, rng).genome
            child_a, child_b = blx_crossover(parent_a, parent_b, params.crossover_alpha, rng)
            children.extend([child_a, child_b])
        else:
            children.append(parent_a)
    return [mutate(child, params, sigma, rng) for child in children[:count]]


def eliminate_duplicates(children: Sequence[Genome], population: Sequence[Scored],
                         params: IslandParams, sigma: float,
                         rng: RandomPort) -> tuple[list[Genome], int]:
    seen = {scored.genome.genes for scored in population}
    kept: list[Genome] = []
    rejected = 0
    for child in children:
        candidate = child
        if candidate.genes in seen and params.duplicate_policy is DuplicatePolicy.REDRAW:
            for _ in range(params.max_redraws):
                candidate = mutate(candidate, params, sigma, rng)
                if candidate.genes not in seen:
                    break
        if candidate.genes in seen and params.duplicate_policy is DuplicatePolicy.REDRAW:
            rejected += 1
            continue
        seen.add(candidate.genes)
        kept.append(candidate)
    return kept, rejected


def one_fifth_rule(successes: int, evaluated: int, sigma: float,
                   factor: float, floor: float, ceiling: float) -> tuple[float, float]:
    ratio = successes / max(1, evaluated)
    updated = sigma * (factor if ratio >= 0.2 else factor ** -0.25)
    return min(ceiling, max(floor, updated)), ratio


def integrate(population: Sequence[Scored], offspring: Sequence[Scored],
              params: IslandParams) -> list[Scored]:
    ranked = sorted([*population, *offspring], key=lambda s: s.fitness, reverse=True)
    return ranked[: params.population_size]


def unique_ratio(population: Sequence[Scored]) -> float:
    distinct = {scored.genome.genes for scored in population}
    return len(distinct) / len(population)
```

Duplicate elimination keys on `genome.genes`; for redundant encodings pass a phenotype keyer instead (decode first) — see [operators.md](./operators.md#diversity-preservation).

## Evolution Loop

```python
# domain/evolution.py
import statistics
from typing import Callable, Sequence
from domain.models import Genome, IslandConfig, Scored, Snapshot
from domain.operators import (breed, eliminate_duplicates, integrate,
                              one_fifth_rule, unique_ratio)
from domain.ports.random import RandomPort

LocalSearch = Callable[[Genome, RandomPort, int], tuple[Genome, int]]


def initial_population(island: IslandConfig, rng: RandomPort) -> list[Genome]:
    lo, hi = island.params.bounds
    return [Genome(tuple(rng.uniform(lo, hi) for _ in range(island.params.gene_count)))
            for _ in range(island.params.population_size)]


def score_batch(genomes: Sequence[Genome], fold_id: int, evaluator, logger,
                island_id: int, generation: int, tag: str) -> list[Scored]:
    scores = evaluator.evaluate_many(genomes, fold_id)
    logger.debug("cohort.scored", island_id=island_id, generation=generation,
                 tag=tag, size=len(genomes),
                 best=max(scores), mean=statistics.fmean(scores))
    return [Scored(genome, score) for genome, score in zip(genomes, scores)]


def cataclysm(island: IslandConfig, population: Sequence[Scored],
              evaluator, logger, rng: RandomPort) -> tuple[list[Scored], int]:
    elites = sorted(population, key=lambda s: s.fitness, reverse=True)[: island.params.elite_count]
    fresh = initial_population(island, rng)[island.params.elite_count :]
    logger.warn("restart", island_id=island.island_id, reason="diversity_collapse",
                preserved=len(elites), reseeded=len(fresh))
    reseeded = score_batch(fresh, island.fold_id, evaluator, logger,
                           island.island_id, 0, "restart")
    return elites + reseeded, len(reseeded)


def evolve_island(island: IslandConfig, patience: int, snapshot_interval: int,
                  evaluator, logger, metrics, clock, best_params, rng: RandomPort,
                  local_search: LocalSearch | None = None
                  ) -> tuple[list[Scored], int, int]:
    params = island.params
    population = score_batch(initial_population(island, rng), island.fold_id,
                             evaluator, logger, island.island_id, 0, "init")
    best = max(population, key=lambda scored: scored.fitness)
    best_generation, generation, evals, stagnated, restarts = 0, 0, len(population), 0, 0
    sigma = params.mutation_sigma
    best_params.snapshot(Snapshot(island.island_id, 0, "init", best))

    while generation < params.generations:
        generation += 1
        start = clock.now_ms()
        best_before = best.fitness
        pop_mean = statistics.fmean(s.fitness for s in population)
        successes = rejected_total = ls_evals = generation_evals = 0
        cohorts = [population[i:i + params.cohort_size]
                   for i in range(0, params.population_size, params.cohort_size)]

        for index, cohort in enumerate(cohorts):
            children = breed(population, len(cohort), params, sigma, rng)
            children, rejected = eliminate_duplicates(children, population, params, sigma, rng)
            rejected_total += rejected
            logger.debug("duplicates.rejected", island_id=island.island_id,
                         generation=generation, cohort=index, count=rejected)
            if local_search is not None and rng.random() < params.ls_probability:
                improved, batch_evals = [], 0
                for child in children:
                    child, used = local_search(child, rng, params.ls_steps)
                    batch_evals += used
                    improved.append(child)
                ls_evals += batch_evals
                children = improved
                logger.debug("local_search.done", island_id=island.island_id,
                             generation=generation, cohort=index,
                             searched=len(children), evals_used=batch_evals)
            offspring = score_batch(children, island.fold_id, evaluator, logger,
                                    island.island_id, generation, f"cohort-{index}")
            successes += sum(1 for s in offspring if s.fitness > pop_mean)
            evals += len(offspring)
            generation_evals += len(offspring)
            population = integrate(population, offspring, params)

        evals += ls_evals
        best = max(population, key=lambda scored: scored.fitness)
        if params.adaptive_mutation:
            sigma, ratio = one_fifth_rule(successes, generation_evals, sigma,
                                          params.mutation_factor,
                                          params.sigma_floor, params.sigma_ceiling)
            logger.debug("adaptive.updated", island_id=island.island_id,
                         generation=generation, success_ratio=ratio,
                         effective_sigma=sigma)

        metrics.record(island_id=island.island_id, fold_id=island.fold_id,
                       generation=generation, best=best.fitness,
                       mean=pop_mean, diversity=unique_ratio(population),
                       effective_sigma=sigma, duplicates_rejected=rejected_total,
                       local_search_evals=ls_evals, restarts=restarts,
                       evals_total=evals, generation_ms=clock.elapsed_ms(start))
        logger.info("generation.completed", island_id=island.island_id,
                    generation=generation, best=best.fitness,
                    evals_total=evals, duration_ms=clock.elapsed_ms(start))

        stagnated = 0 if best.fitness > best_before else stagnated + 1
        if best.fitness > best_before:
            best_generation = generation
            best_params.snapshot(Snapshot(island.island_id, generation, "improvement", best))
            logger.info("improvement", island_id=island.island_id, generation=generation,
                        previous_best=best_before, best=best.fitness)
        elif generation % snapshot_interval == 0:
            best_params.snapshot(Snapshot(island.island_id, generation, "periodic", best))

        if (unique_ratio(population) < params.diversity_floor
                and stagnated >= params.restart_patience and restarts < params.max_restarts):
            population, reseeded_evals = cataclysm(island, population, evaluator, logger, rng)
            evals += reseeded_evals
            sigma, restarts, stagnated = params.mutation_sigma, restarts + 1, 0
            best_params.snapshot(Snapshot(island.island_id, generation, "restart", best))
        elif stagnated >= patience:
            logger.warn("stagnation.warn", island_id=island.island_id,
                        generation=generation, since_improvement=stagnated)
            break

    best_params.snapshot(Snapshot(island.island_id, generation, "island_stop", best))
    return population, best_generation, restarts
```

Cohorts inside a generation; an append-only best-params trail; duplicate elimination before the evaluator pays; the 1/5 rule after each generation; a CHC-style cataclysm when diversity collapses and patience runs out. `evals` includes local-search evaluations so the budget stays honest.

## Run Orchestration

```python
# domain/run.py
from domain.models import RunConfig, Scored, Snapshot


def migrate(states: dict[int, list[Scored]], generation: int, migrant_count: int,
            best_params) -> None:
    island_ids = sorted(states)
    for index, island_id in enumerate(island_ids):
        donor, receiver = states[island_ids[index - 1]], states[island_id]
        migrants = sorted(donor, key=lambda s: s.fitness, reverse=True)[:migrant_count]
        worst = sorted(receiver, key=lambda s: s.fitness)[:migrant_count]
        for outgoing, incoming in zip(worst, migrants):
            if incoming.fitness > outgoing.fitness:
                receiver[receiver.index(outgoing)] = incoming
                best_params.snapshot(Snapshot(island_id, generation, "migrant", incoming))


def run(config: RunConfig, evaluator, logger, metrics, presenter, clock,
        best_params, rng_factory, local_search=None) -> dict:
    champions, champion_generations, restarts = {}, {}, {}
    for island in config.islands:
        logger.info("island.started", island_id=island.island_id,
                    fold_id=island.fold_id, seed=island.seed)
        population, found, count = evolve_island(
            island, config.stagnation_patience, config.snapshot_interval,
            evaluator, logger, metrics, clock, best_params,
            rng_factory(island.seed), local_search)
        champion = max(population, key=lambda scored: scored.fitness)
        validation = evaluator.evaluate_many([champion.genome], island.fold_id)[0]
        champions[island.island_id] = (champion, validation)
        champion_generations[island.island_id], restarts[island.island_id] = found, count
        best_params.snapshot(Snapshot(island.island_id, found, "validated", champion, validation))
        logger.info("island.validated", island_id=island.island_id,
                    train=champion.fitness, validation=validation,
                    gap=champion.fitness - validation, restarts=count)

    winner = max(champions, key=lambda island_id: champions[island_id][1])
    champion, _ = champions[winner]
    holdout = evaluator.evaluate_many([champion.genome], config.holdout_fold)[0]
    best_params.snapshot(Snapshot(winner, champion_generations[winner],
                                  "final", champion, holdout))
    logger.info("holdout.evaluated", fitness=holdout)
    presenter.island_table(...)   # mean ± std table
    certificate = build_certificate(config, champion.fitness, lower_bound,
                                    runs, successes, stop_reason, evals_used)
    return {"champions": champions, "holdout": holdout, "certificate": certificate}
```

`rng_factory` is wired at the composition root (`lambda seed: random.Random(seed)`) so the domain never names the RNG implementation. Concurrent schedulers call `migrate(states, generation, migrants, best_params)` every `migration_interval` generations — with one RNG stream per island and the receiver's worst replaced only by strictly better migrants. Sequential runs skip migration or run it as a post-phase; either way it stays in `run.py`, out of `evolve_island`.

## Stopping and Verification

Pure rules, no I/O — the run loop asks one question per generation and the composition root persists the answer.

```python
# domain/stopping.py
import math

from domain.models import Certificate, RunConfig


def p_miss_after_runs(success_rate: float, runs: int) -> float:
    return (1.0 - success_rate) ** runs


def wilson_upper_bound(successes: int, runs: int, z: float = 1.96) -> float:
    if runs == 0:
        return 1.0
    phat = successes / runs
    denom = 1 + z * z / runs
    center = phat + z * z / (2 * runs)
    margin = z * math.sqrt(phat * (1 - phat) / runs + z * z / (4 * runs * runs))
    return min(1.0, (center + margin) / denom)


def required_runs(success_rate: float, alpha: float) -> int:
    if success_rate <= 0:
        return math.inf
    return math.ceil(math.log(alpha) / math.log(1.0 - success_rate))


def should_stop(generation: int, evals: int, elapsed_s: float, *, config: RunConfig,
                best: float, lower_bound: float | None,
                runs: int, successes: int) -> tuple[bool, str]:
    if lower_bound is not None and best - lower_bound <= config.bound_tolerance:
        return True, "certified"
    if best >= config.target_fitness:
        return True, "target"
    if evals >= config.max_evaluations:
        return True, "budget_evals"
    if generation >= max(island.params.generations for island in config.islands):
        return True, "budget_generations"
    if elapsed_s >= config.max_seconds:
        return True, "budget_time"
    if runs > 0 and p_miss_after_runs(wilson_upper_bound(successes, runs), runs) <= config.miss_alpha:
        return True, "p_miss"
    return False, "running"


def build_certificate(config: RunConfig, best: float, lower_bound: float | None,
                      runs: int, successes: int, stop_reason: str,
                      evals_used: int) -> Certificate:
    p_hi = wilson_upper_bound(successes, runs)
    gap = None if lower_bound is None else best - lower_bound
    if gap is not None and gap <= config.bound_tolerance:
        claim = "certified"
    elif gap is not None:
        claim = "bounded"
    elif runs > 0:
        claim = "statistical"
    else:
        claim = "best_so_far"
    return Certificate(claim=claim, best=best, lower_bound=lower_bound, gap=gap,
                       runs=runs, successes=successes, p_hi=p_hi,
                       p_miss_upper=p_miss_after_runs(p_hi, runs),
                       stop_reason=stop_reason,
                       evals_saved=max(0, config.max_evaluations - evals_used))
```

Wiring in `run()`: a lower bound comes from an injected pure function `lower_bound(fold_id) -> float | None` (relaxation, interval arithmetic, or `None` for black box); the loop maintains `runs`/`successes` (independent run count and hits on the best-known value), `evals_used`, and `stop_reason`; one decision point per generation:

```python
# domain/run.py — one decision point per generation
stopped, reason = should_stop(generation, evals, elapsed_s, config=config, best=best,
                              lower_bound=lower_bound, runs=runs, successes=successes)
if stopped:
    certificate = build_certificate(config, best.fitness, lower_bound,
                                    runs, successes, reason, evals)
    if certificate.claim == "certified":
        best_params.snapshot(Snapshot(island.island_id, generation, "certified", best))
    logger.info("verification.checked", claim=certificate.claim,
                best=certificate.best, lower_bound=certificate.lower_bound,
                gap=certificate.gap, p_miss_upper=certificate.p_miss_upper)
    break
```

The composition root writes `certificate.json` from the returned `Certificate` and emits `run.stopped_early` when `evals_saved > 0`. Escape mechanisms are problem-specific pure functions wired like `local_search` — the domain calls them on their trigger and logs `escape_credit`, while `should_stop` stays the only place that decides when to quit. See [optima.md](./optima.md) for the rule stack and the certificate semantics.

## Composition Root

```python
# main.py
import json, random, uuid
from dataclasses import asdict
from pathlib import Path

from adapters.duckdb.best_params import DuckDbBestParams
from adapters.duckdb.hub import DuckDbHub
from adapters.duckdb.duckdb_config import DuckDbConfig
from adapters.duckdb.duckdb_mappings import row_to_snapshot, snapshot_to_row
from adapters.duckdb.logger import DuckDbLogger
from adapters.duckdb.metrics import DuckDbMetrics
from adapters.rich_presenter import build_presenter
from adapters.system_clock import SystemClock
from adapters.system_lifetime import SystemLifetime
from domain.errors import AppError
from domain.run import run
from infra.config import load_run_config

def main(config_path: str) -> None:
    run_id = f"ga-{uuid.uuid4().hex[:6]}"
    config = load_run_config(config_path, run_id=run_id)
    clock = SystemClock()
    lifetime = SystemLifetime()
    hub = DuckDbHub(DuckDbConfig(path=f"build/runs/{run_id}/run.duckdb",
                                 batch_size=200), lifetime, clock)
    logger = DuckDbLogger(hub, run_id=run_id)
    metrics = DuckDbMetrics(hub, run_id=run_id)
    island_params = {island.island_id: island.params for island in config.islands}
    best_params = DuckDbBestParams(hub, run_id=run_id,
                                   to_row=lambda s: snapshot_to_row(s, run_id, island_params),
                                   from_row=row_to_snapshot)
    presenter = build_presenter()

    try:
        logger.info("run.started", fingerprint=config.fingerprint(),
                    islands=len(config.islands))
        result = run(config, evaluator=..., logger=logger, metrics=metrics,
                     presenter=presenter, clock=clock, best_params=best_params,
                     rng_factory=random.Random, local_search=...)
        certificate = result["certificate"]
        Path(f"build/runs/{run_id}/certificate.json").write_text(
            json.dumps(asdict(certificate), indent=2))
        if certificate.evals_saved > 0:
            logger.info("run.stopped_early", reason=certificate.stop_reason,
                        evals_saved=certificate.evals_saved, claim=certificate.claim)
        logger.info("run.completed", reason="finished", claim=certificate.claim,
                    holdout=result["holdout"])
    except AppError as error:
        logger.error("run.failed", code=error.code, message=error.message,
                     context=error.context, origin=error.origin,
                     correlation_id=error.correlation_id, cause=repr(error.cause))
        raise
    finally:
        lifetime.shutdown()   # flushes every cleanup handler once

if __name__ == "__main__":
    import sys
    main(sys.argv[1])
```

One `DuckDbHub` connection serves the logger, metrics, and best-params adapters. Buffers flush on size, on interval through `TimePort`, and on any exit reason through `LifetimePort` — no `atexit`, no module-level connections. `infra/config` creates `build/runs/<run_id>/` while assembling the config, before the hub opens its file. Evaluator and local search are the only problem-specific wiring.

## DuckDB Adapters

The hub is a portable adapter: standard library + driver only, frozen config injected, cleanup registered with `LifetimePort`.

```python
# adapters/duckdb/duckdb_config.py
from dataclasses import dataclass


@dataclass(frozen=True)
class DuckDbConfig:
    path: str
    batch_size: int = 200
```

```python
# adapters/duckdb/hub.py  —  backend: DuckDB | driver: duckdb | no app imports
import duckdb


class DuckDbHub:
    def __init__(self, config: DuckDbConfig, lifetime, clock) -> None:
        self._connection = duckdb.connect(config.path)
        self._config, self._clock = config, clock
        self._buffers: dict[str, list[tuple]] = {}
        self._create_schema()
        lifetime.register_cleanup(self.flush)

    def append(self, table: str, row: tuple) -> None:
        buffer = self._buffers.setdefault(table, [])
        buffer.append((*row, self._clock.now_iso()))  # ts is always the last column
        if len(buffer) >= self._config.batch_size:
            self.flush(table)

    def flush(self, table: str | None = None) -> None:
        for name in ([table] if table else list(self._buffers)):
            rows = self._buffers.get(name) or []
            if rows:
                placeholders = ", ".join("?" for _ in rows[0])
                self._connection.executemany(
                    f"INSERT INTO {name} VALUES ({placeholders})", rows)
                self._buffers[name] = []

    def execute(self, sql: str, params: tuple = ()) -> list[tuple]:
        return self._connection.execute(sql, params).fetchall()
```

```python
# adapters/duckdb/best_params.py  —  append-only trail; mappers injected, no domain imports
class DuckDbBestParams:
    def __init__(self, hub, run_id: str, to_row, from_row) -> None:
        self._hub, self._run_id = hub, run_id
        self._to_row, self._from_row = to_row, from_row

    def snapshot(self, snapshot) -> None:
        self._hub.append("best_params", self._to_row(snapshot))

    def latest(self, island_id: int):
        rows = self._hub.execute(
            "SELECT * FROM best_params WHERE run_id = ? AND island_id = ? "
            "ORDER BY generation DESC LIMIT 1", (self._run_id, island_id))
        return self._from_row(rows[0]) if rows else None
```

The pure mappings live beside the adapter and are injected by the composition root, so the adapter itself (the I/O file) serves any snapshot shape. This mapping module is the one sanctioned boundary translation point — the adapter stays free of app imports:

```python
# adapters/duckdb/duckdb_mappings.py  —  pure functions, testable without I/O
import json

from domain.models import Genome, Scored, Snapshot


def snapshot_to_row(snapshot, run_id: str, island_params: dict) -> tuple:
    return (run_id, snapshot.island_id, snapshot.generation, snapshot.reason,
            snapshot.best.fitness, snapshot.validation,
            json.dumps(snapshot.best.genome.genes),
            json.dumps(island_params[snapshot.island_id].__dict__, default=str))


def row_to_snapshot(row) -> Snapshot:
    run_id, island_id, generation, reason, fitness, validation, genome, params, ts = row
    return Snapshot(island_id=island_id, generation=generation, reason=reason,
                    best=Scored(Genome(tuple(json.loads(genome))), fitness),
                    validation=validation)
```

DuckDB failures never leak: the hub and its siblings translate driver exceptions into `AppError(code="GA-010"/"GA-011")` at the boundary. A failed observability write is swallowed and counted; a failed snapshot write logs one `WARN` — neither can kill the search.

## Justfile

```just
root := justfile_directory()

run config:
    cd {{root}} && uv run python main.py {{config}}

# Single island / quick smoke
run-one:
    cd {{root}} && uv run python main.py configs/quick.json

# Reports and inspection (all read run.duckdb)
report run_id:
    cd {{root}} && uv run python cli.py report {{run_id}}
certificate run_id:
    cd {{root}} && cat build/runs/{{run_id}}/certificate.json
best run_id:
    cd {{root}} && duckdb build/runs/{{run_id}}/run.duckdb -c "SELECT island_id, generation, reason, fitness FROM best_params WHERE reason IN ('improvement','validated') ORDER BY fitness DESC LIMIT 10"
logs run_id:
    cd {{root}} && duckdb build/runs/{{run_id}}/run.duckdb -c "SELECT ts, event, island_id, generation FROM logs WHERE level IN ('INFO','WARN','ERROR') ORDER BY ts DESC LIMIT 50"
db-shell run_id:
    cd {{root}} && duckdb build/runs/{{run_id}}/run.duckdb
db-size run_id:
    cd {{root}} && du -h build/runs/{{run_id}}/run.duckdb
export-metrics run_id:
    cd {{root}} && duckdb build/runs/{{run_id}}/run.duckdb -c "COPY generations TO 'build/runs/{{run_id}}/metrics.csv' (HEADER)"
resume run_id:
    cd {{root}} && uv run python main.py --resume {{run_id}}

# Test tiers
test:
    cd {{root}} && uv run pytest tests/unit
test-contract:
    cd {{root}} && uv run pytest tests/integration -k contract
test-integration:
    cd {{root}} && uv run pytest tests/integration
test-fault:
    cd {{root}} && uv run pytest tests -k fault
test-property:
    cd {{root}} && uv run pytest tests/unit -k property
test-e2e:
    cd {{root}} && uv run pytest tests/e2e
mutation:
    cd {{root}} && uv run mutmut run
errors-check:
    cd {{root}} && uv run python cli.py check-errors

# Combined gates
check: test test-contract errors-check
verify: check test-fault test-property test-e2e
verify-plus: verify mutation

clean:
    rm -rf build/
```

Optional: DEAP (`deap`) or pymoo replace `domain/operators.py` and `domain/evolution.py` internals — the ports, records, logs, metrics, best-params trail, presentation, and every adapter stay exactly the same. The GA discipline is the interface; the library is an implementation detail.
