# Operators and Parameters

Operators are pure functions of `(genomes, parameters, rng)` → genomes. They never read the clock, the file system, or global state, and they never call the fitness function.

## Encoding First

The genome representation dictates the operators. Pick it before anything else.

| Encoding | Genome | Crossover | Mutation | Typical problems |
|----------|--------|-----------|----------|------------------|
| Binary | Bit string | Single/multi-point, uniform | Bit-flip | Feature subsets, knapsack, on/off decisions |
| Real-valued | Float vector | BLX-α, SBX, blend | Gaussian/Polynomial (bounded) | Hyperparameters, control gains, layouts |
| Permutation | Ordering of ids | Order/PMX/OX | Swap, inversion, scramble | Routing, scheduling, TSP |
| Integer/mixed | Bounded ints + reals | Uniform per-gene | Creep / random reset | Resource allocation, mixed configs |
| Tree/hybrid | AST or nested structure | Subtree swap | Subtree/point/hoist | Symbolic regression, programs, expressions |

Rule: **respect gene bounds during mutation** (clamp, reflect, or resample). An operator that produces out-of-bounds genomes pushes the repair cost into the evaluator and corrupts metrics.

**Binary encoding note:** use **Gray code** when adjacent integers should be adjacent bit patterns — standard binary has Hamming cliffs that make small numeric changes cost many flips. For real-valued parameters quantized to bits, Gray coding measurably improves mutation locality. If the search stalls on plateau-like landscapes, randomly shifted Gray codes are a known escape hatch.

## Selection

Selection converts fitness into reproductive opportunity. It is your learning rate.

| Method | Mechanism | Pressure | Notes |
|--------|-----------|----------|-------|
| Tournament (default) | Sample `k` genomes, take the best | Tunable via `k` | Cheap, robust to fitness scaling, works with noise |
| Rank | Sample proportional to rank | Tunable via exponent | Ignores fitness magnitude gaps — good for skewed fitness |
| Roulette (fitness-proportional) | Sample by fitness share | High | Fragile: negative/noisy/scaled fitness breaks it |
| Truncation | Take the top `p%` | Very high | Fast convergence, fast diversity loss |
| SUS | Roulette with even spacing | Same as roulette | Lower variance than roulette, same fragility |
| Lexicase / novelty | Case- or novelty-based | Task-specific | For noisy fitness, novelty search, or test suites |

**Pressure guidance:** tournament size `2` ≈ weak (exploration), `3–5` ≈ moderate, `7+` ≈ strong (exploitation). Start at 3 and tune from curves, not vibes.

**Incest prevention (CHC-style):** only mate pairs whose distance exceeds a threshold `d`, and decay `d` (×0.9) each generation until crosses are refused. It is a cheap, self-tuning way to keep crossover productive; when `d` hits zero, the population has converged — restart (see [Restarts](./evolution.md#restarts-chc-style-cataclysm)).

**Operator credit assignment:** log which operator/parameters produced each improving child (Davis-style), then adapt operator probabilities from their success share. Even without adaptation, the per-operator improvement rate is one of the most useful diagnostic metrics in the report.

Diversity-preserving selection: fitness sharing, crowding (replace most similar), and restricted mating (mate only if distance > threshold). Use them when the diversity curve collapses early.

## Crossover

| Family | Operators | Notes |
|--------|-----------|-------|
| Binary | Single-point, two-point, uniform | Uniform is a strong default for feature masks |
| Real | BLX-α (α≈0.5), SBX (η≈2–20), blend/arithmetic | SBX for bounded variables, arithmetic for smooth landscapes |
| Permutation | OX, PMX, order-based | Must repair/guarantee valid orderings |
| Tree | Subtree crossover | Preserve syntax; bound generated depth |

Crossover rate `p_c` (probability a pair reproduces sexually): start `0.8–0.9` for most encodings. When it is 1.0 the population mixes constantly; when it is 0 it degenerates to hill-climbing with mutation.

## Mutation

| Family | Operators | Notes |
|--------|-----------|-------|
| Binary | Bit-flip at per-gene rate | Rate `1/L` ≈ one flip per genome |
| Real | Gaussian (σ annealed), polynomial, creep | σ shrinks over generations for fine-tuning |
| Permutation | Swap, inversion, scramble | Inversion preserves most edges (good for TSP) |
| Tree | Subtree/point mutation | Bound depth and node count |

Mutation rate `p_m`: start `1/L` (per-gene) or `0.01–0.1` (per-genome) for binary; `0.1–0.3` per-gene for real-valued. This is your exploration dial — lower it to exploit, raise it to escape local optima.

### Adaptive Mutation — the 1/5 Success Rule

When you cannot tune mutation offline, let the population tune it. Count successes — offspring that beat the best of their parent cohort — and update multiplicatively:

```
fraction = successes / cohort_size
if fraction >= 1/5:  sigma *= F          # too conservative, explore harder
else:                sigma *= F**(-1/4)  # too disruptive, refine
clamp sigma to [sigma_floor, sigma_ceiling]
```

`F = 2` makes one success in five exactly neutral (stability), which is why the rule is self-correcting rather than oscillating. On binary genomes apply it to the per-gene flip probability with floor `1/L`; on real-valued genomes apply it to Gaussian σ with floor ~`1e-4` and ceiling ~half the range. Record `effective_p_m`/`effective_sigma` per generation — the adaptation trace explains the run.

```python
# pure — no clock, no I/O; returns the next strength plus the ratio fed to metrics
def one_fifth_rule(successes: int, cohort_size: int,
                   sigma: float, factor: float = 2.0,
                   floor: float = 1e-4, ceiling: float = 0.5) -> tuple[float, float]:
    ratio = successes / cohort_size
    updated = sigma * (factor if ratio >= 0.2 else factor ** -0.25)
    return min(ceiling, max(floor, updated)), ratio
```

Two stronger variants when the landscape is unknown:

- **2-rate self-adjustment** — breed half the cohort at `2σ` and half at `σ/2`; keep the rate of the winning offspring. More robust to success-rule oscillation, no threshold to tune.
- **Self-adaptation (per-genome σ)** — encode the strength in the genome and let selection evolve it. More machinery and slower, but it adapts per individual rather than per island; useful when different regions of the space need different step sizes.

**Stagnation schedules:** also raise mutation during stagnation windows and restart from the pre-stagnation value when progress resumes. Decay-only schedules (annealing) are predictable but can get trapped; success-based rules adapt to the landscape.

## Local Search (Memetic Algorithms)

Evolution finds the basins; local search finds the bottom of the basin. A **memetic algorithm** adds a trajectory method (hill climbing, coordinate ascent, 2-opt, swap descent, repair) to the evolutionary loop — historically the single biggest quality-per-evaluation improvement on combinatorial problems.

Design decisions, in the order they matter:

| Decision | Guidance |
|----------|----------|
| Where in the cycle | Local-search **offspring after variation, before selection** (Lamarckian: improved genome replaces the child). Baldwinian (fitness only, genome unchanged) is a valid alternative that preserves genetic diversity. |
| Who gets searched | All offspring if the evaluator is expensive and the move is cheap; only the top `p%` or tournament winners if the move is expensive. Never the whole population every generation. |
| How much | First-ascent to a step budget (`ls_steps`), not to true local optimality unless affordable. Partial search on promise, extended budget only for elites (coarse-grain scheduling). |
| Budget accounting | Local-search evaluations count toward the run budget and are reported separately (`local_search_evals`, `ls_cost_share`). An unbudgeted local search will silently starve the population. |
| When to use | Landscapes where a cheap improvement move approximates the gradient: schedules (swap/shift), routes (2-opt/3-opt), assignments (reassign), subsets (add/drop/swap). |
| When to skip | No cheap neighborhood exists, or evaluations already dominate cost and the move cannot reuse them. |

Rules of thumb from practice:

- **Lamarckian beats Baldwinian when the genotype can express the improvement** (permutations, bounded reals); Baldwinian preserves diversity when it cannot.
- **Local search increases selection pressure** — it makes good genomes better before they compete. Watch the diversity curve and compensate with crowding, lower pressure, or periodic restarts.
- **Refine, don't replace.** A local search that dominates the evolutionary search (e.g., full descent on every child) collapses to iterated hill climbing with extra steps. Keep the ratio visible.

## Replacement and Elitism

- **Elitism count**: keep the top `e` genomes untouched per generation. Default `e = max(1, round(0.02 × population))`, hard ceiling 5%.
- **Duplicates**: deduplicate identical genomes in the elite pool to avoid spending slots on clones.
- **Steady-state**: when a cohort's offspring integrate immediately, replace the worst resident or the most-similar resident (crowding). Never replace the champion.
- **Generational gap**: fraction replaced per cohort; smaller gap = smoother trajectories, larger gap = faster turnover.
- **Tie-breaking for diversity**: when replacing among equal-fitness residents, prefer the one in the largest duplicate cluster (duplicate minimisation) — a proven cheap improvement over both random and no-dedupe replacement.

## Diversity Preservation

| Mechanism | How | When |
|-----------|-----|------|
| Island isolation | Populations never merge | Always (inherent to the island model) |
| Migration control | Small, infrequent migrant batches | Always (see [evolution.md](./evolution.md#step-3--migration-cross-island-exchange)) |
| Duplicate elimination | Re-draw/refuse offspring identical to an existing genome; key on phenotype when encoding is redundant | Default, before every evaluation |
| Incest prevention | Refuse mating below a distance threshold; decay the threshold each generation (CHC) | Default for small populations; stops late-run inbreeding |
| Crowding | Replace nearest neighbors | Converging to clones |
| Fitness sharing | Divide fitness by niche density | Multi-modal landscapes |
| Cataclysmic restart | Keep champion, re-seed the rest, reset adaptive parameters (CHC) | Diversity collapse or long stagnation (see [evolution.md](./evolution.md#restarts-chc-style-cataclysm)) |
| Encoding-aware distance | Hamming, Euclidean, edit distance, tree distance | Diversity metrics, mating thresholds, crowding |

Empirical ordering when budget is tight and you can only add one mechanism: **duplicate elimination → island isolation → incest prevention → crowding → fitness sharing → restarts**. Duplicate elimination is nearly free and has the strongest proven effect on crossover-driven search.

## Parameter Defaults (starting points, not gospel)

| Parameter | Default | Tune when |
|-----------|---------|-----------|
| Population size | 50–200 | Budget-bound; use larger with cheap evaluations |
| Cohort size | `population / 5` … `population / 2` | Bigger = smoother metrics, smaller = more updates |
| Generations | Budget-dependent; 100–1000 typical | Landscapes that need long annealing |
| Crossover rate `p_c` | 0.85 | No improvement mid-run → raise; premature convergence → lower |
| Mutation rate `p_m` | `1/L` or 0.05–0.2 per gene | Stagnation → raise; chaos/no convergence → lower |
| Adaptive mutation | 1/5 rule, `F = 2`, floor `1/L`, ceiling `1/2` | Unknown landscapes or expensive manual tuning |
| Tournament size | 3 | Slow convergence → raise; collapse → lower |
| Elitism | 2% (≥1) | Always ≥1 for monotonic best |
| Duplicate policy | Reject + re-draw, phenotype-keyed | Always on; switch to penalty when re-drawing loops |
| Mating threshold (CHC) | Initial: mean pairwise distance; decay ×0.9/generation | Small populations prone to late-run inbreeding |
| Local search | ≤ 20% of offspring evaluated, step budget | Cheap neighborhoods exist; watch diversity and budget |
| Stagnation patience | `max(15, generations / 10)` | Too short kills slow-burn progress |
| Migration interval | 10–25 generations | Frequent = one meta-population, rare = independent folds |
| Migrants | 1–3 (≤ 10% of population) | More migrants = faster fold blending |
| Restarts | `max_restarts = 2–3` per island | Diversity collapse that repeats after reset |
| Seed | One per island | Fixed for reproducibility; sweep seeds to measure variance |

## Operator → Training Translation

| Operator concept | Training analogue |
|------------------|-------------------|
| Selection pressure (tournament size) | Learning rate |
| Crossover rate | Layer mixing / feature reuse |
| Mutation rate | Exploration noise / dropout rate |
| Elitism | Gradient momentum — keeps the best direction |
| Population size | Batch size × capacity |
| Cohort size | Mini-batch size |
| Fitness sharing / crowding | Regularization |
| Restart | Learning-rate reset |

## Testing Operators

Operators are pure — test them like pure functions:

- **Bounds**: mutated genomes stay within domain bounds (property test over random inputs).
- **Validity**: permutation operators produce permutations; tree operators produce parseable trees.
- **Determinism**: same seed → identical output; different seed → (usually) different output.
- **Contract**: population size in = population size out; elites survive elitist replacement unchanged.
- **Coverage**: with high mutation rate and enough samples, reachable regions of the space are reached.
- **Duplicate policy**: elimination never returns a genome already present; re-drawing terminates (bound the retries, then allow the duplicate through with a counted event).
- **Adaptive rule**: `one_fifth_rule` increases strength on ≥ 1/5 success, decreases below, and always stays inside the clamp — property-test the boundaries at ratio = 0, 0.2, 1.
- **Local search**: with zero budget it is identity; with a budget it never returns a worse genome (first-ascent), or returns unchanged if the neighborhood is empty.

## References

- Eshelman, L. J. (1991). *The CHC Adaptive Search Algorithm.* — elitist selection, incest prevention, cataclysmic restart.
- Rechenberg, I. (1973); Kern et al. (2004). — the 1/5 success rule; multiplicative parameter control.
- Doerr et al. (2019). *Self-Adjusting Mutation Rates with Provably Optimal Success Rules.* — update strengths and 2-rate schemes.
- Krasnogor, N. & Smith, J. (2005). *A Tutorial for Competent Memetic Algorithms.* — local search placement, scheduling, Lamarckian vs Baldwinian.
- Friedrich et al. (2016). *Escaping Local Optima with Diversity Mechanisms and Crossover.* — runtime benefits of duplicate elimination, crowding, fitness sharing.
- Raidl, G. (1999). *On the Importance of Phenotypic Duplicate Elimination.* — dedupe on phenotype, not genotype.
- Caruana, R. & Schaffer, J. D. (1988). *Representation and Hidden Bias: Gray vs. Binary Coding.* — Gray code locality.
- Davis, L. (1989). *Adapting Operator Probabilities in Genetic Algorithms.* — operator credit assignment.
