# Multi-Island, Multi-Cohort Evolution

The run is a hierarchy: **Run → Island (fold) → Generation (epoch) → Cohort (batch) → Breeding step (optimizer step)**. Each level has its own record, budget, and stopping logic.

## Run Hierarchy

| Level | GA term | Training analogue | One record per… |
|-------|---------|-------------------|-----------------|
| Run | Run | Experiment | Run config + fingerprint + final report |
| k populations | Islands / demes | k-fold splits | Island start/validation/champion |
| Pass over a population | Generation | Epoch | Generation metrics + log |
| Offspring bred per step | Cohort | Mini-batch | Cohort metrics + log |
| select → crossover → mutate → integrate | Breeding step | Optimizer step | Debug log if needed |

## Step 0 — Fold Construction

1. Split the dataset into `k` folds. Stratify when the target is categorical or imbalanced.
2. Assign one island per fold:
   - **Train slice** = all folds except fold `i`. Used for every fitness evaluation during evolution.
   - **Validation slice** = fold `i`. Read-only during evolution; used once to validate the island champion.
3. Reserve a **holdout fold** before anything else if k allows (train/validation/holdout). The overall champion touches it exactly once at the end.
4. Give each island a **seed** and optionally a **different parameter set** (population size, mutation rate, pressure). Heterogeneous islands are a random-search ensemble — they decorrelate the folds and diversify the run.
5. Record the fold assignment itself (row ids per fold) in the run artifacts. A fold is data — it must be reproducible.

```
RunConfig
├── folds:        k, stratified, seed, assignment artifact
├── islands:      k configs (params may differ), one seed each, one train/val slice each
├── budget:       max_generations, max_evaluations, max_seconds
└── stop rules:   target_fitness, stagnation_patience
```

## Step 1 — Population Initialization

- Seed the population per island from that island's RNG stream.
- Prefer **random initialization with domain bounds**; use heuristics only if they are seeded and recorded.
- Population size is a budget decision: bigger populations explore more per generation but afford fewer generations for the same evaluation budget.
- Initialize best-params tracking by scoring the initial population (cohort by cohort — never all at once) and snapshotting the first champion.

## Step 2 — The Generation Loop

```
for generation in 0..max_generations:
    for cohort in cohorts(population, cohort_size):

        parents    = select(cohort_size, population)        # fitness-driven, incest-aware
        offspring  = crossover(parents, p_crossover)
        offspring  = mutate(offspring, p_mutation)
        offspring  = eliminate_duplicates(offspring, population)   # phenotype key
        offspring  = local_search(offspring, budget) if ls_enabled  # memetic step
        fit        = evaluate(offspring, train_fold, island_seed)   # batched
        integrate(population, offspring, fit)               # μ+λ or steady-state

        record cohort → log + metrics                       # one record per step
        snapshot best_params if best improved               # reason: improvement

    record generation → log + metrics                       # aggregate of cohorts
    update p_mutation via success rule (1/5)                # adaptive parameters
    snapshot best_params if generation % snapshot_interval == 0   # reason: periodic
    members = migrate(population, neighbors) if generation % migration_interval == 0
    restart(cataclysm) if diversity < floor and restart_patience exhausted
    stop = target_hit or stagnated or budget_spent
```

### Cohort integration strategies

| Strategy | Population update | Analogy | When |
|----------|-------------------|---------|------|
| Generational (μ, λ) | Whole population replaced by offspring each generation | Full-batch epoch | Simple, cheap operators; small populations |
| Elitist (μ + λ) | Best μ kept, best λ offspring added | Full-batch + momentum | Default; guarantees monotonic best |
| Steady-state / cohort | Offspring replace the worst (or most similar) members immediately, per cohort | SGD mini-batch | Large populations, expensive evaluations, streaming metrics |
| Generational gap | Replace a fixed fraction per cohort | Batch with partial update | Middle ground; tune the gap like a batch size/shuffle |

Defaults: elitist generational at small scale, steady-state cohorts at large scale. **Never let the elite count exceed ~5% of the population** — elitism is a leash on diversity.

### Three small loop upgrades (cheap, proven, usually on by default)

**Duplicate elimination — before evaluation.** New offspring that duplicate an existing individual (or each other) are re-drawn or counted out before the evaluator is paid. Key on the **phenotype** when the encoding is redundant (permutations, decoders); genotypic elimination is ineffective there. It is the cheapest diversity mechanism with proven runtime bounds, and it directly saves budget on expensive evaluators.

**Adaptive mutation — the 1/5 success rule.** Track the share of offspring that beat their cohort's previous best. If ≥ 1/5 succeed, the step is too conservative — multiply mutation strength by `F` (commonly 2). If < 1/5, multiply by `F^-1/4` (≈ 0.84 for F = 2) so one success in five keeps the parameter stable. Apply per generation, clamp to `[1/L, 1/2]` per-gene (or an absolute sigma floor), and record the effective value as a metric. Self-adaptive variants encode the rate in the genome instead (more machinery, more robust to unknown landscapes); the 2-rate scheme (half the cohort at 2×, half at 0.5×, keep the winner's rate) is a strong middle ground.

**Local search — the memetic step.** When cheap local moves exist (swap, flip, repair, coordinate ascent), run a bounded hill-climb on a fraction of offspring before scoring. Keep the improved genome (Lamarckian) or only its fitness (Baldwinian), budget the extra evaluations explicitly (`local_search_evals`), and schedule effort: light search on all offspring, heavy search only on promise. See [operators.md](./operators.md#local-search-memetic-algorithms).

### Restarts (CHC-style cataclysm)

When diversity collapses or stagnation outlasts patience, do not simply stop or continue inbred search: **keep the champion, re-seed the rest**.

1. Detect the stall: entropy below floor, duplicate ratio above ceiling, or incest threshold decayed to zero.
2. Preserve the best genome (and optionally the top 10% or archived elites).
3. Re-seed the remainder with random genomes (cataclysm) or immigrants from neighbor islands.
4. Reset adaptive parameters (mutation strength, mating threshold) to their initial values.
5. Cap the number of restarts per island; a run that still stalls after `max_restarts` is a signal about encoding or evaluator, not about restart count.
6. Snapshot with reason `restart` and log the event — restarts explain fitness jumps in the report.

## Best-Parameter Snapshots (Persist Often)

The champion is the run's most valuable output, so persist it constantly — not just at the end. Every snapshot carries the genome (the best parameters), its fitness, its island's validation fitness when known, and the island's GA parameters, written to DuckDB.

| Trigger | `reason` | Why |
|---------|----------|-----|
| Initial population scored | `init` | First reference point, before generation 1 |
| Best fitness improved | `improvement` | Immediate durability; never lose a new best to a crash |
| Every `snapshot_interval` generations (default: 1 for small populations, 10 otherwise) | `periodic` | Time-travel: reconstruct the champion as of any generation |
| Cohort integration (optional, verbose) | `cohort` | Fine-grained trajectory of the search |
| Migration send | `migrant` | Know exactly what was shared with neighbors |
| Island stop (before validation) | `island_stop` | Freeze candidate; validation fills in the score |
| Island validation complete | `validated` | Champion with its generalization numbers attached |
| Cataclysmic restart | `restart` | Champion preserved across the re-seed |
| Certificate closed | `certified` | Best genome frozen as provably optimal (or statistically confident) |
| Run end / holdout | `final` | The delivered artifact |
| Crash handler flush | `crash` | Last-known-best survives an unhandled failure |

```sql
-- best_params: one row per snapshot, never overwritten
CREATE TABLE best_params (
    run_id     TEXT,
    island_id  INTEGER,
    generation INTEGER,
    reason     TEXT,             -- init | improvement | periodic | cohort | migrant | island_stop | validated | restart | certified | final | crash
    fitness    DOUBLE,           -- train fitness at snapshot time
    validation DOUBLE,           -- NULL until island validation
    genome     JSON,             -- the best parameters (decoded, readable)
    params     JSON,             -- island GA parameters in effect
    ts         TIMESTAMP
);

-- champions: one row per island, upserted at validation; plus the holdout winner
CREATE TABLE champions (
    run_id     TEXT,
    island_id  INTEGER,
    generation INTEGER,          -- generation the champion was found
    train      DOUBLE,
    validation DOUBLE,
    gap        DOUBLE,
    genome     JSON,
    ts         TIMESTAMP
);
```

Cadence rules:

- **Improvement snapshots are never pruned** — they are the search's spine, and there are at most O(generations) of them.
- **Periodic snapshots are cheap** — DuckDB compresses well; keep all of them during the run, prune to the last `snapshot_retention` (default 500) per island afterward if needed.
- **Snapshots do not gate the search** — a failed snapshot write is logged and swallowed, like any observability write. The evolution loop never blocks on the database.
- **Validation back-fill** — when the island validates, insert a `validated` snapshot rather than mutating the `island_stop` row. Snapshots are an append-only log.

The snapshot answers, in one query, "what was the best genome as of generation N, and which island/parameters produced it?" — the query you reach for when a run surprises you.

## Step 3 — Migration (Cross-Island Exchange)

Migration is your fold-to-fold knowledge transfer. Keep it small and infrequent.

| Parameter | Default | Notes |
|-----------|---------|-------|
| Topology | Ring (bidirectional) | Extended rings are safest for exploration; fully connected spreads genes too fast and destroys the diversity the island model exists to protect |
| Interval | Every 10–25 generations | Too frequent → islands collapse into one (loses fold discipline); too rare → migration stops mattering; tune by messages-per-generation rather than raw generations |
| Migrants | 1–3 elites (≤ 10% of population) | Migrants must be the best, not random; when tuned, 10–20% bandwidth is the aggressive end |
| Replacement | Replace worst (or most similar) residents | Never overwrite the receiving island's champion |
| Direction | Unidirectional per interval, then reverse | Avoid ping-ponging the same genomes |
| Trigger | Generation interval | Optional: diversity-triggered migration — exchange when neighbor similarity exceeds a threshold instead of on a timer |
| Sync | Synchronous | Synchronous suits reproducible runs; asynchronous suits distributed wall-clock throughput |

Migration records go to logs/metrics like any other step: `migration.done` with source island, destination, migrants, and the receiving best before/after.

## Step 4 — Island Validation

When an island stops (target, stagnation, or budget):

1. Freeze the island champion genome.
2. Evaluate it on the island's **validation fold** (not the train fold).
3. Record: train fitness, validation fitness, **generalization gap = train − validation**.
4. If validation is re-evaluated with noise, evaluate `n` times and report mean ± std.
5. Write a `validated` snapshot to DuckDB `best_params` with island id, generation found, genome, and the validation record, and upsert the row in the `champions` table.

## Step 5 — Aggregation and Holdout

- Aggregate island champions: **mean ± std** of validation fitness across folds, best island, success rate (islands hitting target).
- Rank islands — a champion that wins one fold may lose the next; report the distribution, not one number.
- Evaluate the overall champion on the holdout fold **exactly once**. If you tune after seeing holdout, it is no longer a holdout.
- Report the generalization gap and the stopping reason for every island.

## Step 6 — Verification and Stopping

After the islands stop, the run evaluates its evidence — see [optima.md](./optima.md) for the full rule stack.

1. **Certified gap** — if the problem admits a lower bound (relaxation, interval arithmetic, enumeration), compare it to the best feasible value: `best − L ≤ tolerance` closes the certificate.
2. **Statistical confidence** — otherwise, update `runs`/`successes`, compute the Wilson upper bound on the success rate, and derive `P(miss) ≤ (1 − p_hi)^k`. Fix `k` before the runs, not after.
3. **Stopping controller** — first rule that fires wins: certified → target → budget → `p_miss` → collapse → stagnation → racing. Record `stop_reason`, the evidence, and the budget saved.
4. **Certificate artifact** — write `certificate.json` with the claim, bounds, gap, `runs`/`successes`, `p_miss_upper`, and the fingerprint.
5. **Claim** — `certified`, `bounded`, `statistical`, or `best-so-far`; the presentation reports exactly this claim and no more.

## Termination Rules

| Rule | Trigger | Record |
|------|---------|--------|
| Certified / target | `best − L ≤ tolerance`, or best ≥ target | `run.completed`, reason `certified`/`target` + snapshot reason `certified` |
| Stagnation | no best-improvement for `patience` generations (after escapes tried) | `run.completed`, reason `stagnation` |
| Generation budget | `generation == max_generations` | `run.completed`, reason `budget_generations` |
| Evaluation budget | `evaluations_used ≥ max_evaluations` | `run.completed`, reason `budget_evals` |
| Time budget | `elapsed_s ≥ max_seconds` | `run.completed`, reason `budget_time` |
| Statistical miss bound | `(1 − p_hi)^k ≤ α` over independent runs | `run.completed`, reason `p_miss` |
| Diversity collapse | entropy below floor for `patience` generations | `restart` event + snapshot, reason `restart` (up to `max_restarts`) |
| Restart budget spent | `restarts == max_restarts` and still stalled | `run.completed`, reason `collapse` |
| Racing | another island certified, or budget reallocated to leaders | `run.completed`/island stop, reason `budget_reallocated` |
| Crash | unhandled error | `run.failed` (AppError) + DuckDB buffers and best-params flushed by the LifetimePort cleanup |

Stopping is per-island first, then per-run. One collapsed island does not end the run — it restarts its population, or validates its champion and lets the others continue. Early stops record the budget they saved (`evals_saved`).

## Reproducibility

- **One RNG stream per island**: `RandomPort(seed=island_seed)`. Never a global RNG, never interleaved streams from other islands.
- **Deterministic evaluation**: same genome + same fold + same seed → same fitness. If the evaluator is stochastic, re-evaluate `n` trials per genome and record the seed(s) used.
- **Fingerprint the run**: config values (all parameters, budgets) + seeds + fold assignment hash + code version. Store as `config.json` and a short hash.
- **Stable iteration order**: sort maps/sets before iterating when they feed the RNG or operators.
- **Replay from snapshot**: the latest `best_params` row + seed + generation must be enough to resume an island.

## Crash Recovery

- The composition root owns a `LifetimePort`: adapters register cleanup with it, and on any exit reason (normal, user exit, crash, timeout) it flushes DuckDB write buffers and writes a `crash`/`final` best-params snapshot for every in-flight island. No `atexit`, no module-level handlers.
- Resume payload per island: generation, population (or elites), RNG state (or seed + generation to fast-forward), best genome from `best_params`, evaluations used.
- DuckDB is the source of truth after a crash: `best_params` gives the last-known-best even if the in-memory population is lost.
- Resume is opt-in: `run --resume <run_id>`. On resume, verify the fingerprint matches; refuse if config or folds changed.

```
build/runs/<run_id>/
├── run.duckdb            # THE store: logs, metrics, best_params, champions, evaluations
├── certificate.json      # the claim: bounds, gap, runs/successes, p_miss_upper
├── config.json           # frozen RunConfig + fingerprint
├── folds.json            # fold assignment (row ids), seed, k
├── best_params.json      # optional export of the snapshot trail
├── log.jsonl             # optional export for tailing/grep
├── metrics.csv           # optional export for spreadsheets
├── snapshots/            # resumable island states
├── curves/               # fitness/diversity/gap plots (svg/png or ascii)
└── report.md             # final presentation
```

`run.duckdb` is append-only during the run and queryable while the run is live — tail the latest champion with SQL instead of parsing files:

```sql
SELECT island_id, generation, reason, fitness, validation
FROM best_params
WHERE run_id = 'ga-7f3a91' AND reason = 'improvement'
ORDER BY fitness DESC LIMIT 5;
```
