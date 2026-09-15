# Escaping Local Optima, Verifying True Optima, Early Stopping

Three connected jobs: **escape** traps when they happen, **certify** optimality when you can, and **stop** the moment continuing stops paying. A GA without all three either terminates on a lucky local optimum or burns budget chasing an optimum it already has.

## Why Local Optima Trap the Search

| Failure mode | Mechanism | Signature |
|--------------|-----------|-----------|
| Premature convergence | Diversity dies before the global basin is sampled | Entropy falls, best rises, validation flat |
| Deceptive landscape | Local optima point away from the global optimum | Improvement stalls early with high diversity |
| Ruggedness | Many comparable basins, small attraction radii | Best improves in bursts, plateaus repeat |
| Search-market failure | Selection pressure favors a mediocre basin | Mean tracks best, `success_ratio` → 0 |

Documented theory: without elitism a canonical GA provably **never** converges to the global optimum (the best solution is lost and re-found infinitely often — Rudolph 1994). With elitism plus mutation reachability, it converges with probability one — but only *as time → ∞*. Neither fact tells you what to do at generation 200, which is why escape mechanisms and finite-time certificates matter.

**Landscape triage** (cheap, before committing): run a few short pilot runs, plot best-vs-generation, measure fitness-distance correlation to the best-known, and count distinct basins reached from random starts. High correlation + many basins → local perturbation will work; low correlation + early convergence → prefer restarts and diversity mechanisms.

## Escape Toolkit

Two families: **trajectory escapes** (perturb or bias the walk) and **population escapes** (keep diversity alive). Pick at most two, wire them to a trigger, and log which mechanism produced each improvement (`escape_credit`).

| Mechanism | How it works | Trigger | Cost |
|-----------|--------------|---------|------|
| Cataclysmic restart (CHC) | Keep champion, re-seed the rest, reset adaptation | Diversity collapse + patience | Low |
| Iterated local search / basin hopping | Perturb the champion (or best-so-far) and re-optimize; accept if better (or Metropolis) | Stagnation with healthy diversity | Medium — budget the re-optimization |
| Tabu memory | Forbid recently visited attributes/moves; aspiration overrides when a new best appears; reactive tenure grows on revisits | Repeatedly returning to the same basin | Low, memory grows |
| Deflection / guided penalties | Add a dynamic penalty to features of the current local optimum so the landscape tilts away from it | Multi-basin with shared features | Low |
| VNS (variable neighborhood) | Increase neighborhood size in a shake phase, descend again | Local descent exhausts one move type | Medium |
| Multi-start with archive | Fresh independent runs, never re-seeding from archive genomes already tried | Deceptive landscape | High (but parallelizable) |
| Migration (islands) | Import elites from differently-seeded islands | Inter-island best diverge | Low |
| Hybrid parameter heterogeneity | Islands run different operators/rates | Unknown landscape | Low |

Rules of thumb:

- **Proximate optimality principle** — good local optima cluster near the global optimum. Perturb *locally* when the walk is in a promising region; use *global* restarts only when improvement probability collapses entirely.
- **Never perturb the champion destructively** — snapshot first, perturb a copy, and accept only per the acceptance criterion.
- **One trigger per mechanism** — stagnation → ILS/restart; revisits → tabu/deflection; diversity collapse → cataclysm; exhaustion of a move type → VNS. Overlapping triggers mask each other's effects.
- **Verify escapes work** — `escape_credit` (improvements attributed to each mechanism) plus `restart_count` should justify every mechanism's complexity. If a mechanism never wins, delete it.

## Verifying True Optima

No black-box heuristic can prove global optimality from search alone (no-free-lunch). But many problems admit a *certificate* — a mathematical argument that the best found value cannot be improved. The claim you report must match the evidence you hold:

| Claim | Evidence required | When available |
|-------|-------------------|----------------|
| **Certified global optimum** | Upper bound (feasible solution) = lower bound (dual/relaxation/enumeration) | Structured problems: LP/MIP relaxations, interval arithmetic, bounded finite spaces |
| **Bounded best-so-far** | Feasible `U` and rigorous `L` with `L ≤ OPT ≤ U`; report the gap | Any problem with a computable relaxation or Lipschitz/interval bound |
| **Statistical confidence** | `P(missed optimum) ≤ α` from independent runs with the search process unchanged | Any problem, requires multiple independent runs |
| **Best-so-far, no claim** | None | Default — say this explicitly rather than implying optimality |

### Exact certificates

- **Enumeration**: if the search space is finite and the evaluation count covers it (or a sound pruning bound eliminates regions), the best found *is* the optimum. Record the coverage proof with the run.
- **Primal–dual gap**: a feasible solution gives the upper bound `U`; a dual bound from an LP/MIP relaxation, Lagrangian relaxation, or branch-and-bound gives `L ≤ OPT`. When `U = L`, optimality is proven — this is how exact solvers certify (and how VIPR-style certificates are checked independently).
- **Interval arithmetic / Lipschitz bounds**: for continuous problems, evaluate the objective with outward-rounded intervals; if the bound at a candidate beats the interval of every other region, that candidate is certified optimal over those regions. The bound need not be tight globally — only where it prunes.
- **Benchmarks with known optima**: use functions with published global optima (sphere, Rastrigin, Ackley, Himmelblau) to calibrate the search. This certifies the *search*, not the problem — but it is how you prove the pipeline can reach a global optimum at all.

Rule: **bound where you can, enumerate where you must, and never title a run "optimum found" without one of the two.**

### Statistical certificates (black-box)

When no analytical bound exists, the best available certificate is a coverage probability over independent runs:

1. Run `k` independent GA runs (fresh seeds, identical config, process unchanged).
2. Count successes `s` (runs that reached the best-known value or the target).
3. Estimate the success probability with a **Wilson score interval** — it stays valid at small `k` and near `p = 0`, where the normal approximation fails outright.
4. The miss probability after `k` runs is `(1 − p)^k`; bound it with the Wilson upper bound `p_hi`: `P(miss) ≤ (1 − p_hi)^k`.
5. Report `k`, `s`, the interval, and the bound. Choose `k` from `required_runs(p̂, α)` up front.

A finite-time variant: if a known bound on expected hitting time `T̂` exists, one run of length `c·T̂` misses with probability `≤ 1/c` (Markov inequality); `k` independent runs give `P(miss) ≤ c^-k`. Twenty runs at `c = 2` bound the miss probability below `10^-6`.

**Order-statistics bound**: with `N` samples, the `k`-th best value bounds the optimum from above with a computable confidence — the width of the one-sided confidence interval shrinks as `N` grows. Stop when the interval width drops below your tolerance (this is a stopping rule as well as a certificate).

**Guardrails**: runs must be independent; the stopping decision must not depend on the outcome being certified (otherwise the statistics lie); and `k` must be fixed before the runs, not after a disappointing one.

## Early Stopping

Cheapest rules first, every generation — first rule that fires wins:

| Order | Rule | Fires when | Reason |
|-------|------|-----------|--------|
| 1 | Certified / target | `U − L ≤ tolerance`, or best ≥ target | `certified`, `target` |
| 2 | Budget | Evaluations, generations, or seconds exhausted | `budget_evals`, `budget_generations`, `budget_time` |
| 3 | Statistical miss bound | `(1 − p_hi)^k ≤ α` with all runs stopped | `p_miss` |
| 4 | Restart or stop | Diversity collapse + patience: restart first, stop after `max_restarts` | `collapse` |
| 5 | Stagnation | No improvement for `patience`, with at least one escape mechanism already tried | `stagnation` |
| 6 | Racing | Independent islands: stop when any island certifies, or reallocate budget to leaders | `budget_reallocated` |

Practical rules:

- **Stagnation needs a probability, not a hunch.** "No improvement in 40 generations" alone means nothing; support it with the observed improvement distribution, the success-ratio trend, or the statistical miss bound across runs. In noisy evaluators, re-evaluate the champion before declaring a plateau.
- **Loss-minimization criterion**: stop when the expected marginal gain from more evaluations is negative given the run's observed improvement history — the restart-scheduling literature shows this stops earlier than fixed patience windows at equal quality.
- **Hedge, don't herd**: stop losing islands early and give their budget to islands whose improvement probability is still above threshold; keep at least one exploration island alive unless a certificate exists.
- **Early stopping must record its savings**: `evals_saved`, `time_saved`, and the evidence (`p_miss_upper`, `certificate`), so the report can justify the early exit.
- **The holdout stays untouched** — verification and stopping decisions read train/validation only.

## Pipeline Integration

1. **Escape**: each island tracks its escape mechanisms; triggers call the mechanism and emit `restart`/`escape` events with `escape_credit`.
2. **Verify**: after every island stop, update `runs`/`successes` and recompute the Wilson bound; if a relaxation exists, compute `L` per generation and record `best_bound_gap`. Write `certificate.json` when a claim reaches `certified` or `p_miss`.
3. **Stop**: a single stopping controller (composition root or `run.py`) evaluates the rule stack per generation, sets `stop_reason`, records savings, and flushes the certificate. Snapshot the champion with reason `certified` when a certificate closes.
4. **Report**: the presentation leads with the claim type, the evidence, and the gap — never a bare "best found".

## References

- Rudolph, G. (1994). *Convergence Analysis of Canonical Genetic Algorithms.* — elitism + reachable mutation ⇒ global convergence w.p. 1; non-elitist CGA never converges.
- Rudolph, G. (1997). *Handbook of Evolutionary Computation*, B2.4.2. — first-hitting-time bounds; `P(T > cT̂) ≤ 1/c`; `c^-k` after `k` runs.
- Barrero, D. F. et al. (2016). *Improving Experimental Methods on Success Rates in Evolutionary Computation.* — Wilson intervals for success rates; required run counts.
- Mills, P. et al. (2004). *A Survey of AI-based Meta-heuristics for Dealing with Local Optima.* — tabu, GLS/deflection, VNS, ILS, proximate optimality principle.
- Mladenović & Hansen (1997). *Variable Neighborhood Search.* — systematic neighborhood changes for escape.
- Borst, Eifler & Gleixner (2024). *Certified Constraint Propagation and Dual Proof Analysis.* — primal/dual certificates for exact global optimality.
- Bartkutė et al. (2006). *Optimality Testing in Stochastic and Heuristic Algorithms.* — order-statistics confidence intervals on the optimum; stop when the interval narrows.
- Hutter, F. & Hamadi, Y. et al. work on restart scheduling / loss-minimization criteria for stopping and restarting.
