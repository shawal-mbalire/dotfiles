---
name: genetic-algorithm
description: Run multi-island (multi-fold) genetic algorithm search with batched cohort evolution, frequent best-params snapshots, structured generation logs, fitness/diversity metrics, and a final presentation report. Use when evolving or optimizing candidate solutions with populations, selection, crossover, mutation, islands/demes, champion checkpoints, reproducible seeds, DuckDB-backed observability, and fitness evaluation across any language.
---

# Genetic Algorithm (Multi-Island, Multi-Cohort)

Populations search. Fitness judges. Islands prove it generalizes.

A genetic algorithm run is a training pipeline. Instead of epochs, mini-batches, and gradient steps, you advance generations, breed cohorts, and apply selection — but the discipline is identical: split the data, evolve in batches, log every generation, measure progress, and present what actually generalizes.

## Reference Files

`SKILL.md` is the map. Open a file below only when you need its depth.

| Topic | File |
|-------|------|
| Run anatomy, islands (folds), generations, cohorts (batches), migration, termination | [evolution.md](./evolution.md) |
| Selection, crossover, mutation, replacement, diversity, parameter defaults | [operators.md](./operators.md) |
| Fitness function contract, train/validation/holdout splits, batched scoring, noisy fitness | [evaluation.md](./evaluation.md) |
| Structured generation logs and event taxonomy | [logging.md](./logging.md) |
| Fitness, diversity, convergence, efficiency, and reliability metrics | [metrics.md](./metrics.md) |
| Local-optima escape, optimality certificates, statistical confidence, early stopping | [optima.md](./optima.md) |
| Live progress, fitness curves, island tables, final run report | [presentation.md](./presentation.md) |
| Ports, fakes, property tests, fault injection, determinism gates | [testing.md](./testing.md) |
| Language-agnostic reference implementation | [python.md](./python.md) |

## The Training → GA Translation

Everything you know from multi-fold multi-batch training has a GA equivalent. Use the right-hand column — GA has its own lingo.

| Training concept | GA equivalent |
|------------------|---------------|
| Epoch | **Generation** |
| Mini-batch | **Cohort** — the offspring bred and scored per breeding step |
| Optimizer step | **Cohort update** — breed → score → integrate into the population |
| k-fold split | **Island (deme)** — one evolving population per data fold |
| Fold ensemble | **Island champions** — best genome per island, aggregated at the end |
| Loss | **Cost** (inverted fitness); fitness is maximized, cost minimized |
| Learning rate | **Selection pressure × mutation rate** |
| Gradient | **Selection gradient** — fitness-weighted drift toward better genomes |
| Weight decay / dropout | **Diversity preservation** — niching, crowding, island isolation |
| Early stopping | **Stagnation halt** — no best-fitness improvement in N generations |
| Checkpoint | **Best-params snapshot** — champion genome + fitness persisted per island and generation |
| Train / validation / test split | **Train fold / validation fold / holdout fold** |
| Hyperparameter sweep | **Heterogeneous island parameters** — each island gets its own config |
| Seed | **Seed** — one per island, recorded in the run fingerprint |
| Training log | **Generation log** — structured event per cohort and generation |
| Loss curves | **Fitness curves** — best/mean/validation fitness per generation |
| Dashboard / report | **Presentation** — live panels, island tables, final run report |

## Run Anatomy

```
Run (k islands = k folds, one config fingerprint, one run_id)
├── Island 0 (fold 0) — train slice / validation slice / seeded RNG
│   ├── Generation 0 … G
│   │   ├── Cohort 0 … C   breed → score → integrate   (one breeding step each)
│   │   ├── generation record → log + metrics
│   │   ├── best-params snapshot → DuckDB (improvement + periodic + stop)
│   │   └── stagnation / budget check
│   ├── migration every M generations (ring topology, elites only)
│   └── island validation → champion genome + validation fitness
├── Island 1 … (different fold, different seed, optionally different parameters)
└── Aggregate → generalization gap → holdout evaluation → certificate + claim → presentation report
```

## Core Principles

1. **Fitness is the only judge** — The fitness function is pure, deterministic for a given seed and input, and the single source of truth. Nothing else may promote or demote a genome.
2. **Breed in cohorts** — Never materialize or score the whole population at once when a cohort (mini-batch) will do. Bounded work per breeding step keeps memory flat and lets you log while the run is live.
3. **Islands are folds** — One population per fold, evolved in isolation on its train slice. Islands are your cross-validation — never merge their training data.
4. **Selection pressure is the learning rate** — Too low and nothing improves; too high and the population collapses to clones. Tune tournament size like you tune a learning rate, and adapt mutation to the observed success rate (1/5 rule) when the landscape is unknown.
5. **Diversity is regularization** — Entropy is a first-class signal. Duplicate elimination, distance-checked mating (incest prevention), crowding, and periodic restarts keep the population from overfitting to itself. Measure diversity every generation and intervene when it collapses.
6. **Generations are epochs** — A generation = one pass of breeding over the population. Track per-generation records exactly like per-epoch training records.
7. **Best params are persisted often** — The island champion (genome, fitness, validation, and its GA parameters) is snapshotted to DuckDB on every improvement, every `snapshot_interval` generations, and on stop. A crash loses a cohort, never the best params.
8. **Local search is a memetic amplifier** — When the problem allows cheap local moves, hybridize: improve a fraction of offspring with hill-climbing/repair, let the population handle the jumps (Lamarckian or Baldwinian), and budget local-search evaluations explicitly.
9. **Stagnation halts or restarts** — Stop on budget exhaustion (generations, evaluations, wall-clock) or no improvement over a patience window. On diversity collapse, prefer a CHC-style cataclysmic restart (keep the champion, re-seed the rest) over a full stop. Escape first, then stop with evidence.
10. **Everything is seeded** — Per-island seeds drive selection, crossover, and mutation through an injected `RandomPort`. The run fingerprint (config + seeds) reproduces any result.
11. **Logs are structured events** — One record per event with run/island/generation/cohort context, written to DuckDB. Never string-concatenated prose.
12. **Metrics tell the truth, fitness only tells direction** — Fitness is a single scalar search signal; report validation fitness, generalization gap, diversity, operator credit, cost, and reliability to know if the run succeeded.
13. **Presentation never touches the search** — Rendering is an adapter. A broken terminal, missing color, or disabled UI must not change a single evaluation.
14. **Failures are diagnosed, not swallowed** — Every failure is an `AppError` (code, context, cause, origin, correlation_id). Observability writes may be swallowed; search failures are recorded and recoverable.
15. **Claim only what you can certify** — Report one of: certified optimum (upper bound = lower bound), bounded best-so-far (gap reported), statistical confidence (`P(miss) ≤ α` from independent runs), or plain best-so-far. Never imply optimality from a lucky run.
16. **Stop early with evidence** — Stopping is a decision, not a timeout: certified gap, target, budget, statistical miss bound, or expected marginal gain below zero. Record the reason and the budget saved.

**The split:** Evolution = the search (population, operators, fitness). Observation = logs, metrics, presentation. Keep them strictly separated.

## Cross-Cutting Concerns

| Concern | Port | Dev backing | Artifact in run dir |
|---------|------|-------------|---------------------|
| Logging | `LoggerPort` | DuckDB hub (`logs` table) | `run.duckdb` (+ optional `log.jsonl` export) |
| Metrics | `MetricsPort` | DuckDB hub (`generations`, `cohorts` tables) | `run.duckdb` (+ optional `metrics.csv`) |
| Best params | `BestParamsRepository` | DuckDB hub (`best_params`, `champions` tables) | `run.duckdb` (+ optional `best_params.json`) |
| Presentation | `PresenterPort` | `rich` panels/tables (TTY) or plain | `report.md` + curves |
| Randomness | `RandomPort` | Seeded per island (`random.Random`) | seed in fingerprint |
| Time | `TimePort` | Monotonic clock | `duration_ms` on every record |
| Lifetime | `LifetimePort` | Signal/exit handling, cleanup registry | flushed buffers, `run.failed`/`run.completed` |
| Config | Args + frozen config | `infra/config` env loading | `config.json` + fingerprint |
| Evaluation | `FitnessEvaluator` | Local or remote evaluator | `evaluations` table (audit) |
| Verification | Certificate artifact | Interval/relaxation bound or run statistics | `certificate.json` + `verification.checked` event |
| Diagnostics | `AppError` | Error registry + `render()` | `run.failed` with code/origin/causality |

**Local-first default:** in dev, logs, metrics, and best-params snapshots all land in the same DuckDB database — insight happens with SQL, not a SaaS dashboard. Prod swaps the adapters (Sentry, Prometheus, object storage) without touching the search.

## Architecture Rules

1. **Pure Operators** — Selection, crossover, and mutation are pure functions over genomes and seeds. Given the same inputs and seed, they produce the same output.
2. **Pure-First Fitness** — The fitness function is pure with respect to its inputs: genome + fold data + seed in, fitness out. Any I/O inside an evaluator adapter is explicit and injectable.
3. **Cohort-Sized Work** — Memory and logging stay bounded: score and integrate `cohort_size` offspring per step; never hold every intermediate.
4. **Fold Isolation** — An island only ever trains on its own train fold. Validation data is read-only and used for island validation, never for breeding decisions within a generation.
5. **One Record Per Step** — Every cohort emits a metric/log record; every generation emits an aggregate record. No silent steps.
6. **Deterministic Reproduction** — One seed per island, one RNG stream per island, injected through a `RandomPort`. Never use global RNG or wall-clock time as an input to the search.
7. **Monotonic Best** — The best fitness of an island never regresses. Elitism guarantees non-decreasing best fitness on train fitness.
8. **Snapshot Best Params Often** — Write the champion's genome + fitness + GA parameters to `best_params` on every improvement, every `snapshot_interval` generations, and on graceful stop or crash flush. Periodic snapshots make the run time-travelable and crash-proof.
9. **Budget-Bounded** — Every run declares a budget (generations, evaluations, and/or seconds) and stops cleanly when it is spent.
10. **No Fitness Caching Leaks** — Cache evaluations by `(genome_hash, fold)`; never reuse a train-fold evaluation result for validation. Duplicate elimination keys on the *phenotype* when the encoding is redundant.
11. **Structured Failure** — A failed evaluation or snapshot is a recorded `AppError` event with a reason, never a silent `None`. Faulty genomes are re-drawn or penalized, never crash the run.
12. **Presentation Is Optional** — The search runs headless in CI. The presenter is wired at the composition root and can be replaced by a no-op.
13. **Artifacts Under One Run Directory** — `build/runs/<run_id>/` holds `run.duckdb` (logs, metrics, best params, champions), config, folds, curves, and the report. Nothing is scattered.
14. **Report What Generalizes** — The presentation leads with validation and holdout results per island, then the training curves as supporting evidence.
15. **LifetimePort for Graceful Exits** — The composition root owns a `LifetimePort`; DuckDB buffers, the presenter, and any session close through `register_cleanup`. No `atexit`, no module-level connections.
16. **Duplicate Elimination** — Reject or replace duplicate offspring before paying for their evaluation (genotypic when the encoding is injective, phenotypic when it is redundant). It is the cheapest diversity mechanism known and it saves budget.
17. **Adaptive Parameters** — When parameters are not tuned in advance, adapt mutation strength to observed success (1/5 rule) or self-adapt per genome. Record the effective values as metrics — they explain the run.
18. **Evidence-Backed Claims** — Every run ends with a claim and its evidence: `certified` (bounds closed), `bounded` (gap reported), `statistical` (miss probability with Wilson interval over independent runs), or `best-so-far`. The stopping controller writes the certificate; the presentation never upgrades the claim.

## When to Use

- Search/optimization problems with a scoreable candidate representation (schedules, layouts, routes, parameters, policies, feature subsets)
- Problems with rugged, discontinuous, or non-differentiable landscapes where gradients fail
- Combinatorial or mixed-integer spaces (permutation, subset, tree, hybrid encodings)
- Situations needing a robust, reproducible search with an audit trail and a report
- Multi-objective trade-off exploration (Pareto fronts)
- Simulation-based optimization where each evaluation is expensive and must be batched

## When Not to Use

- Convex or smooth problems — gradient methods win
- Tiny discrete spaces — exhaustive search or branch and bound win
- Fitness that cannot be evaluated deterministically (re-verify with re-evaluation; if still unstable, aggregate over trials)
- Problems where any candidate is invalid unless a constraint solver is used — repair or hybridize first

## Decision Checklist

```
Starting a GA run?
├─ Define the genome encoding first (binary, real, permutation, tree, hybrid)
├─ Write the fitness function as a pure evaluator: genome + data + seed → fitness/cost
├─ Split data into k folds → k islands; reserve a holdout fold
├─ Choose operators per encoding (tournament selection, crossover, mutation)
├─ Set a starting parameter table (population, cohort, mutation rate, elitism, patience)
├─ Seed each island (RandomPort) and record the run fingerprint
├─ Wire ports at the composition root: Logger, Metrics, BestParams, Presenter, Time, Lifetime
├─ Open the DuckDB hub for dev; logs, metrics, and best params share one database
├─ Run the loop: for each island → for each generation → for each cohort
│   ├─ Breed a cohort (select → crossover → mutate)
│   ├─ Eliminate duplicates (phenotypic when encoding is redundant) before scoring
│   ├─ Optionally local-search a fraction of offspring (memetic, budgeted)
│   ├─ Score the cohort on the train fold (batched)
│   ├─ Integrate (μ+λ or steady-state) and snapshot best params when improved
│   ├─ Update adaptive mutation via the 1/5 rule (effective sigma → metrics)
│   ├─ Emit cohort record → log + metrics
│   └─ Emit generation record (best/mean/std, diversity, evals, duration)
├─ Snapshot best params periodically, on island stop, and from the crash handler
├─ Migrate elites across islands every M generations (ring topology)
├─ Escape: wire trigger → mechanism (cataclysm, ILS, tabu, deflection, VNS) and log `escape_credit`
├─ Verify: compute a lower bound when one exists; track runs/successes and the Wilson miss bound
├─ Stop: first rule that fires wins (certified → target → budget → p_miss → collapse → stagnation → racing)
├─ Validate each island champion on its validation fold
├─ Aggregate: mean ± std per island, generalization gap, success rate
├─ Evaluate the overall champion on the holdout fold (once)
├─ Persist champions per island, the overall champion, and `certificate.json` to the run directory
└─ Present: live panels, fitness/diversity curves, island table, claim + evidence, final report

Reporting standards?
├─ Lead with validation + holdout numbers, not training fitness
├─ State the optimality claim: certified | bounded (gap) | statistical (P(miss) ≤ α) | best-so-far
├─ Show mean ± std across islands (the folds), not a single lucky run
├─ Include the run fingerprint (config + seeds) for reproduction
├─ Include cost metrics (evaluations, wall-clock, cache hit rate, early-stop savings)
└─ State the generalization gap and the stopping reason with its evidence
```

## External References

- <https://deap.readthedocs.io/> — DEAP, Python evolutionary computation framework
- <https://pymoo.org/> — pymoo, multi-objective optimization
- <https://en.wikipedia.org/wiki/Island_model> — island model / coarse-grained parallel GA
- <https://en.wikipedia.org/wiki/Cross-validation_(statistics)> — the fold discipline GA islands mirror
- Eshelman 1991, *The CHC Adaptive Search Algorithm* — elitist selection, incest prevention, cataclysmic restart
- Rechenberg 1973 / Kern et al. 2004 — the 1/5 success rule for adaptive mutation strength
- Krasnogor & Smith 2005, *A Tutorial for Competent Memetic Algorithms* — Lamarckian local search design
- Friedrich et al. 2016, *Escaping Local Optima with Diversity Mechanisms and Crossover* — duplicate elimination, crowding, fitness sharing runtime bounds
- Raidl 1999, *On the Importance of Phenotypic Duplicate Elimination* — eliminate duplicates on the phenotype, not the genotype
- Cantú-Paz / Lässig & Sudholt migration studies — migration interval, topology, and migrant-ratio tuning
- Rudolph 1994 — elitism + reachable mutation converges to the global optimum with probability one
- Barrero et al. 2016 — Wilson confidence intervals for success rates and required run counts
- Mills et al. 2004 / Mladenović & Hansen 1997 — meta-heuristics for escaping local optima; VNS
- Borst et al. 2024 — primal/dual certificates for certified global optimality
