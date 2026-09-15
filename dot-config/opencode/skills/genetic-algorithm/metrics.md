# Metrics

Logs tell the story of what happened; metrics tell the state of the search. Emit one record per cohort (detailed) and one record per generation (primary). Aggregate across islands for the run report.

## Metric Families

### 1. Fitness

| Metric | Definition | Why |
|--------|-----------|-----|
| `best` | Island best train fitness this generation | Search progress |
| `mean` / `median` | Population central tendency | Overall health |
| `stddev` / `iqr` | Population spread | Convergence vs stagnation |
| `validation_fitness` | Champion on the island's validation fold | What generalizes |
| `gap` | `best − validation_fitness` | Overfitting signal |
| `holdout_fitness` | Overall champion on the holdout fold | Final claim |
| `target_reached` | Generation target was first hit | Success measure |

Report best/mean per generation as curves; validation only per island stop; holdout once.

### 2. Convergence

| Metric | Definition | Why |
|--------|-----------|-----|
| `improvement_rate` | `Δbest / Δgeneration` (rolling window) | Is the search still moving? |
| `evals_to_target` | Cumulative evaluations when target first hit | Search efficiency, the fair comparison metric |
| `generations_to_target` | Generation when target first hit | Convergence speed |
| `stagnation` | Generations since last best improvement | Early-stop trigger |
| `best_generation` | Generation of the current best genome | Detects late recombinative jumps |
| `convergence_slope` | Slope of `best` over a rolling window | Plateau detection |

`evals_to_target` is the headline number across islands — wall-time and generations are confounded by island parameters.

### 3. Diversity

| Metric | Definition | Why |
|--------|-----------|-----|
| `genome_entropy` | Shannon entropy over gene distributions (normalized 0–1) | Global variety |
| `unique_ratio` | Distinct genomes / population size | Cloning detector |
| `mean_pairwise_distance` | Mean encoding-aware distance between genomes | Population spread |
| `fitness_variance` | Variance of population fitness | Search activity |
| `niche_count` | Occupied niches (distance threshold) | Multi-modality preservation |
| `elite_age` | Generations since the champion was replaced | Stuck-champion detector |
| `duplicate_rejection_rate` | Rejected duplicates / offspring generated | Diversity pressure + wasted-effort detector |
| `mating_threshold` | Current incest-prevention distance (CHC) | Shows when the population converged |
| `restart_count` | Cataclysmic restarts so far | Explains fitness jumps and collapses |

Diversity collapsing precedes performance collapse. Plot entropy next to best fitness — a rising best with falling entropy is a bubble, not progress.

### 4. Efficiency

| Metric | Definition | Why |
|--------|-----------|-----|
| `evals_total` | Cumulative evaluations | Budget currency |
| `evals_per_second` | Throughput | Evaluator cost |
| `cohort_ms_p50` / `cohort_ms_p95` | Per-cohort latency | Tail latency from slow genomes |
| `generation_ms` | Wall-clock per generation | Loop overhead vs evaluation cost |
| `cache_hit_rate` | Cached / attempted evaluations | Evaluator caching value |
| `evaluation_timeout_rate` | Timeouts / evaluations | Evaluator robustness |
| `local_search_evals` | Evaluations spent in local search | Memetic budget visibility |
| `ls_cost_share` | `local_search_evals / evals_total` | Keeps refinement from starving evolution |
| `peak_memory_mb` | Peak RSS | Cohort sizing sanity |

### 5. Operator and Adaptation

| Metric | Definition | Why |
|--------|-----------|-----|
| `operator_success_rate` | Improving children produced / children from this operator | Davis-style credit; tune operator mix |
| `effective_p_m` / `effective_sigma` | Mutation strength actually used | The adaptation trace explains progress |
| `success_ratio` | Fraction of offspring beating their cohort's previous best | Input to the 1/5 rule; watch for oscillation |
| `crossover_skip_rate` | Pairs refused by the mating threshold | Incest prevention activity |

Operator metrics are per-generation, low-volume, and high-value: when a run improves in bursts, these columns usually say why.

### 6. Reliability (cross-island)

| Metric | Definition | Why |
|--------|-----------|-----|
| `island_success_rate` | Islands reaching target / k | Stability across folds |
| `validation_mean` / `stddev` | Across island champions | The report's headline (± std) |
| `best_island` | Island with best validation | Which fold was typical/easiest |
| `fold_rank_stability` | Rerun-to-rerun ranking agreement | Is the winner real or noise? |
| `seed_variance` | Metric spread across seeds | How much of the result is luck |
| `stop_reason` | Certified / target / budget / p_miss / collapse / stagnation / racing | The claim's provenance |
| `claim` | certified / bounded / statistical / best-so-far | Report headline |

A single champion number is not a result. `mean ± std` across folds plus `seed_variance` is.

### 7. Verification and Stopping

| Metric | Definition | Why |
|--------|-----------|-----|
| `lower_bound` | Rigorous bound on the optimum (relaxation, interval arithmetic, enumeration) | Turns "best found" into a gap |
| `best_bound_gap` | `best − lower_bound` | Distance to a certified optimum |
| `certified` | Gap ≤ tolerance reached (1/0) | Strongest claim the run can make |
| `runs` / `successes` | Independent runs and how many reached the best-known value | Inputs to the miss bound |
| `p_hi` | Wilson upper bound on the success rate | Valid at small `k` and near zero |
| `p_miss_upper` | `(1 − p_hi)^k` | Statistical certificate; α decides stopping |
| `escape_credit` | Improvements attributed to each escape mechanism | Justifies restarts/tabu/VNS machinery |
| `evals_saved` | Budget remaining when the run stopped early | Payoff of evidence-based stopping |

### 8. Cost

| Metric | Definition |
|--------|-----------|
| `wall_clock_s` | Run duration |
| `cpu_seconds` | Total CPU time |
| `evaluator_cost_share` | Evaluation time / wall clock |
| `bytes_written` | Artifact size (logs, metrics, snapshots) |

## Record Schema

Primary record: one row per **island × generation** in the `generations` table. Columns:

```
run_id, island_id, fold_id, generation,
best, mean, median, stddev, diversity, unique_ratio,
effective_sigma, duplicates_rejected, local_search_evals, restarts,
evals_total, evals_to_target, stagnation, best_generation,
cache_hit_rate, generation_ms, ts
```

Detail record (optional, larger): one row per **island × generation × cohort** in the `cohorts` table with `cohort`, `size`, `best`, `mean`, `evals_used`, `duration_ms`.

Storage: **DuckDB is the primary store** (`build/runs/<run_id>/run.duckdb`) — logs, metrics, best-params, and champions share one local database, so curves are ad-hoc SQL while the run is still live:

```sql
-- fitness curve for one island
SELECT generation, best, mean, diversity FROM generations
WHERE run_id = 'ga-7f3a91' AND island_id = 2 ORDER BY generation;

-- cross-island leaderboard
SELECT island_id, max(best) AS best, any_value(evals_to_target) AS to_target
FROM generations WHERE run_id = 'ga-7f3a91' GROUP BY island_id ORDER BY best DESC;
```

CSV/parquet exports are derived artifacts for spreadsheets and sharing (`just export-metrics <run_id>`), never the source of truth.

## Cross-Island Aggregation

At island stop and run end:

1. Collect each island's `best` train fitness, `validation_fitness`, `gap`, `evals_total`, `evals_to_target`, `generations`, `stop_reason`.
2. Compute `validation_mean`, `validation_stddev`, and the 95% bootstrap CI over islands.
3. Rank islands by validation fitness; report the ranking alongside the spread.
4. Evaluate the overall champion on the holdout fold and record the holdout row.
5. Surface the winner only if its validation advantage exceeds `2 × validation_stddev / √k` — otherwise call it a tie.

## Reading the Curves

| Curve shape | Diagnosis | Response |
|-------------|-----------|----------|
| Best rises, mean follows, diversity stable | Healthy search | Continue |
| Best flat from gen 0 | Evaluator broken, mutation too low, or target unreachable | Check evaluator, raise exploration |
| Best rises, diversity collapses, validation flat | Overfitting to train fold / premature convergence | Raise diversity pressure, lower elitism/pressure, enable incest prevention |
| Best flat then jumps upward | Cataclysmic restart or late recombination burst | Check `restart_count` and `operator_success_rate`; keep the mechanism |
| Best rises then plateaus, diversity healthy | Local optimum with live population | Restart fraction, raise mutation during stagnation |
| Mean tracks best with zero spread early | Population collapsed instantly | Lower selection pressure, raise mutation |
| Spiky best, stable mean | Noisy evaluator or aggressive mutation | Re-evaluate with more trials, lower `p_m` |
| Validation ≫ train for all islands | Trivial fold or leakage | Re-check the split and preprocessing |
| `success_ratio` oscillates 0 ↔ 1 every generation | Adaptive rule overshooting | Halve update factor `F` or switch to 2-rate self-adjustment |
| Local search dominates wall clock | Refinement starving evolution | Lower `ls_cost_share`, restrict search to promising offspring |

## Anti-Goodhart Rules

- Fitness is an optimization signal, not a success metric. Success = validation/holdout results across islands.
- Never compare runs by `best` alone — compare `evals_to_target`, `validation_mean ± std`, and `gap`.
- Never tune against the holdout. If the holdout influenced a decision, it is a validation fold now — say so in the report.
- A metric with no threshold is decoration; give every gate a number before the run starts.

## Gates (example)

| Gate | Example | Action on fail |
|------|---------|----------------|
| target reached | ≥ 1 island hits target | Investigate encoding/evaluator |
| generalization | mean gap < 10% of best | Add diversity pressure, reduce elitism |
| stability | validation_stddev / mean < 15% | Rerun with more seeds, check fold balance |
| efficiency | evals_to_target < budget × 0.7 | Cache, surrogate, or smaller population |
| diversity floor | unique_ratio > 0.1 through generation G | Strengthen diversity preservation |
| certificate | claim is `certified` or `bounded` with gap ≤ tolerance | Add a bound, or downgrade the claim in the report |
| statistical | `p_miss_upper ≤ α` across ≥ `required_runs(p̂, α)` runs | Run more independent runs or widen α |
