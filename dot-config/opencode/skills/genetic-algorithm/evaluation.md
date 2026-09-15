# Fitness Evaluation

Fitness is the objective. Everything else — selection, diversity, presentation — only serves to find genomes that score well under it. A flawed evaluator produces a confidently wrong report, so the evaluator is the most carefully designed part of the run.

## The Fitness Contract

```
fitness(genome, fold_data, seed) → score
```

- **Pure**: no side effects, no reading global state, no writing artifacts. I/O belongs in the evaluator adapter, not in the scoring rule.
- **Deterministic**: same genome + same fold + same seed → same score. If the environment is stochastic, see [Noisy Fitness](#noisy-fitness).
- **Bounded**: an evaluation has a hard timeout/budget. A soft-locked genome is a fault, not a wait.
- **Comparable**: scores are on one scale for a given island/fold. Different folds may differ in difficulty — never compare raw fitness across folds without normalizing.
- **Total**: return a score or a structured failure — never a silent `None`.

Define direction once: fitness is **maximized**; cost is **minimized**. Keep the sign convention in one place (`score = -cost` or `1/(1+cost)`) so logs, metrics, and plots never disagree.

## Splits: Train Fold, Validation Fold, Holdout

| Slice | Used by | Used when | Written to |
|-------|---------|-----------|------------|
| Train fold | Fitness during evolution | Every breeding step | never written — consumed |
| Validation fold | Island champion validation | Once per island, after it stops | `island.validated` |
| Holdout fold | Overall champion | Exactly once, at the end | `holdout` record in report |

Rules:

1. **No leakage** — the evaluator may only see the genome and its own fold's rows. Feature engineering, scaling, and normalization must be fit on the train slice only, then applied to validation/holdout.
2. **No fold mixing** — islands never share train rows. That is the entire point of the island/fold correspondence.
3. **No peeking** — validation is not read during generations; holdout is not read until the report.
4. **Freeze the split** — write `folds.json` (row ids per fold) before generation 0. Reassignment invalidates comparability.

The validation fold is the exact GA analogue of a holdout in training: if fitness on train keeps rising while validation fitness stalls, you are evolving overfitting. See [the generalization gap](#generalization-gap).

## Batched Evaluation

Cohorts exist so evaluation is bounded and observable:

- Score a cohort of `cohort_size` genomes per step. Keep `cohort_size` small enough that one cohort's latency is comfortable and memory stays flat.
- Log cumulative `evaluations_used` after every cohort. Evaluation budget is the real currency of a GA run.
- Cache by `(genome_hash, fold_id)` when evaluations are expensive. Cache hits are a metric (`cache_hit_rate`) — never a hidden optimization.
- Parallelize *within* a cohort only. Parallelism must not change results: evaluation order and RNG must stay deterministic per island.
- An expensive evaluator can be wrapped with a surrogate (e.g. a cheap regressor trained on evaluated genomes). The surrogate decides where to sample, never the reported fitness.

```
cohort = [genome_1 ... genome_b]
scores = evaluator.evaluate_many(cohort, fold=train_fold)
# one record per cohort: batch index, size, best/mean, duration, cache hits, evals used
```

## Noisy Fitness

Simulation, sampling, or randomized environments make `fitness(genome)` a random variable.

- **Re-evaluate**: run `n` trials per genome (or per promising genome) and score with the mean. `n` is a budget decision — log it.
- **Seed the trials** and record them; noise without recorded seeds is unreproducible.
- **Prefer rank/tournament selection** with noisy fitness — they are robust to score jitter.
- **Re-evaluate champions** at validation time with a larger `n`. The final number you report must be the low-noise one.
- **Track variance as a metric**: if within-genome variance is comparable to between-genome variance, the landscape is noise-dominated — fix the evaluator or increase `n` before trusting any curve.

## Constraints and Penalties

| Approach | Mechanism | When |
|----------|-----------|------|
| Reject | Invalid genome gets score `-inf` (or is never born) | Hard constraints expressible in operators |
| Repair | Map invalid → nearest valid before scoring | Constraints with an obvious projection |
| Penalty (static) | `fitness − λ × violation` | Soft constraints, simple |
| Penalty (adaptive) | λ grows with generation | Early exploration, later feasibility |
| Feasibility-first | Compare feasible > infeasible, then by violation | Hard constraints, must-have feasibility |
| Stochastic ranking | Probabilistically swap adjacent feasible/infeasible by violation | Balancing objective vs constraint pressure without tuning λ |
| Multi-objective | Objectives include violation | Trade-offs matter in the report |

Record violation statistics per generation (`feasible_ratio`, `mean_violation`) — a population that is 30% infeasible deserves a visible metric, not a mystery penalty.

## Multi-Objective Evaluation

- Evaluate all objectives per genome; keep them as a vector, not a weighted sum (collapse weights only if you must).
- Maintain a **Pareto archive** (non-dominated set) instead of a single champion; snapshot the archive to DuckDB alongside the champion rows.
- Metrics: **hypervolume**, Pareto front size, spacing, and coverage. These replace "best fitness" in the curves.
- Selection: NSGA-II-style non-dominated sorting + crowding distance, or decomposition (weighted sums with rotated weights across islands — a natural fit for the island model).
- Presentation: show the front as a scatter (2D) or a parallel-coordinates plot (3D+), plus a table of representative trade-off points.

## Generalization Gap

```
gap = train_fitness(champion) − validation_fitness(champion)
```

- `gap ≈ 0` — the island learned something that transfers.
- `gap > 0` and growing — overfitting to the train fold; add diversity pressure, reduce elitism, shorten patience, or regularize the genome.
- `gap < 0` — the validation fold is easier than train. Usually benign, but check for leakage or split imbalance; report it rather than hiding it.

Every island reports its gap. A run with a great training curve and a terrible gap is a failed run — say so in the presentation.

## Evaluator Faults

- **Timeout** → record `evaluation.timeout` with genome id, mark the genome unfit for that generation, and continue. Never hang the run.
- **Exception** → `evaluation.failed` with the error and a genome hash; penalize or resample. Repeated failures from the same region are a signal about the encoding.
- **NaN/Inf** → treat as infeasible with a visible counter; NaN propagating into selection destroys the run silently.
- **Resource exhaustion** (memory, process, GPU) → halt cleanly via the budget mechanism, flush DuckDB buffers, and best-params snapshot per island.

## Bounds and Certificates

When the objective admits a rigorous bound, compute it and let verification use it:

- **Lower bound** (`L ≤ OPT`): LP/MIP relaxation, Lagrangian relaxation, interval arithmetic, Lipschitz/convexity bounds, or exhaustive enumeration for small finite spaces. A cheap bound computed once per fold beats no bound at all.
- **Upper bound**: any feasible genome's fitness — the champion is the upper bound.
- The run's `best_bound_gap = best − L`; a gap within tolerance certifies optimality over the searched space. See [optima.md](./optima.md#verifying-true-optima).
- Bounds are pure functions of the fold (`lower_bound(fold) -> float | None`), injected like the evaluator; they never enter the fitness function itself, so search behavior is unchanged.

## Evaluation Checklist

- [ ] Direction and scale defined once (maximize fitness, minimize cost)
- [ ] Pure scoring rule, I/O isolated in an evaluator adapter
- [ ] Fold assignment frozen and written to disk before generation 0
- [ ] No leakage: all preprocessing fit on train slice only
- [ ] Evaluation budget tracked and logged per cohort
- [ ] Cache keyed by genome + fold, hit rate reported
- [ ] Timeout, exception, NaN, and infeasible paths all produce structured records
- [ ] Noisy evaluations re-scored with recorded seeds and reported mean ± std
- [ ] Champions re-evaluated at validation with a low-noise protocol
- [ ] Generalization gap computed per island and surfaced in the report
- [ ] Holdout evaluated exactly once, after all tuning is frozen
- [ ] A lower bound computed where one exists; `best_bound_gap` recorded per generation
- [ ] Evaluator bounds never leak into selection — fitness alone drives breeding
