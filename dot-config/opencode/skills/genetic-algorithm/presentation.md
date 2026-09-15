# Presentation and Reporting

Presentation is an adapter. The search must run identically with a rich terminal, a plain stream, or no output at all. Everything shown is derived from logs, metrics, and best-params artifacts — never from hidden state.

## The Presenter Port

```python
# domain/ports/presenter.py
from typing import Protocol, Sequence

class PresenterPort(Protocol):
    def run_header(self, run_id: str, islands: int, budget: str) -> None: ...
    def generation_line(self, island_id: int, generation: int, best: float,
                        mean: float, diversity: float, evals: int,
                        duration_ms: int) -> None: ...
    def improvement(self, island_id: int, generation: int, best: float) -> None: ...
    def island_table(self, rows: Sequence[Sequence[str]]) -> None: ...
    def champion(self, island_id: int, genome: str, train: float, validation: float) -> None: ...
    def error(self, code: str, message: str, origin: str) -> None: ...
    def report_path(self, path: str) -> None: ...
```

| Adapter | Environment | Behavior |
|---------|-------------|----------|
| `RichPresenter` | TTY dev | Panels, tables, progress bars, sparklines |
| `PlainPresenter` | CI, pipes, `NO_COLOR`, `TERM=dumb` | Same data, plain aligned text |
| `NullPresenter` | Headless batch | Nothing |

Selection happens once at the composition root: `presenter = RichPresenter(...) if console.is_terminal and not no_color else PlainPresenter()`.

## Live Presentation

### Run header

```
╭─ GA Run ga-7f3a91 ──────────────────────────────────────────╮
│ 5 islands (folds) · 200 genomes · cohort 40 · 5000 evals    │
│ target 0.95 · patience 25 · seed 42 · fingerprint 9c1f2ab    │
╰─────────────────────────────────────────────────────────────╯
```

### Per-generation line (one per island, in place)

```
island 2 | gen 057 | best 0.9142 | mean 0.8631 ± 0.0219 | div 0.418 | 28.5k eval | 412ms
island 3 | gen 057 | best 0.9088 | mean 0.8599 ± 0.0231 | div 0.395 | 28.1k eval | 398ms
```

- Use a progress bar for the generation budget and a spinner for long cohorts.
- Print `improvement` lines only when the best improves, with the delta.
- `diversity.low` and `stagnation.warn` appear inline as warnings — the operator should see trouble while it is still fixable.
- Never print per-cohort details unless verbose; INFO output stays a few lines per island per generation.

### Island table (live, refresh each generation)

```
╭──────────────────────────────────────────────────────────────╮
│ Island │ Fold │ Gen │ Best   │ Mean   │ Div   │ Status        │
├────────┼──────┼─────┼────────┼────────┼───────┼───────────────┤
│ 0      │ 0    │ 91  │ 0.9310 │ 0.8702 │ 0.372 │ evolving      │
│ 1      │ 1    │ 88  │ 0.9204 │ 0.8655 │ 0.401 │ evolving      │
│ 2      │ 2    │ 57  │ 0.9142 │ 0.8631 │ 0.418 │ evolving      │
│ 3      │ 3    │ 102 │ 0.9401 │ 0.8810 │ 0.301 │ evolving      │
│ 4      │ 4    │ 60  │ 0.9399 │ 0.8795 │ 0.355 │ stagnating 8  │
╰──────────────────────────────────────────────────────────────╯
```

## Curves

Do not require a plotting dependency; emit an artifact by default and a terminal sparkline when convenient.

| Curve | X | Y | Message |
|-------|---|---|---------|
| Fitness | Generation | best, mean, ±1 std band | Is the search improving? |
| Validation | Island | train vs validation bars | Does it generalize? |
| Diversity | Generation | entropy, unique ratio | Is it collapsing early? |
| Gap | Island | train − validation | Where is overfitting worst? |
| Cost | Generation | evaluations, ms | How expensive is progress? |
| Pareto (multi-objective) | Objective 1 | Objective 2, front line | Trade-off shape |

- Write curves to `build/runs/<run_id>/curves/` as SVG (vector, commit-friendly) or PNG.
- One figure per metric family, one line per island, consistent colors across figures.
- Mark improvements, migration events, and stop reasons on the fitness curve (vertical ticks). The plot should explain the run without the log.
- Terminal fallback: sparkline of `best` per island (`▁▂▃▅▇`) for quick checks.

```
island 0 ▁▁▂▂▃▄▅▆▇  0.9310  ↑ improving
island 4 ▁▂▃▄▅▅▅▅▅  0.9399  · stagnating 8/25
```

## Final Run Report

Always write `build/runs/<run_id>/report.md` (and print it via the presenter at normal termination). The report is the deliverable.

````markdown
# GA Run ga-7f3a91

**Fingerprint** 9c1f2ab · **Duration** 4m12s · **Evaluations** 137.4k · **Stop** stagnation
**Config** 5 islands · 200 genomes · cohort 40 · p_c 0.85 · p_m 0.08 · tournament 3 · patience 25

## Result (what generalizes)

**Optimality claim** `bounded` — best 0.9294 within gap 0.0031 of lower bound 0.9263
(tolerance 0.005) · `p_miss_upper` 4.1e-4 over 8 independent runs · stop reason `p_miss`

| Island | Fold | Best (train) | Validation | Gap | Evals to target | Stop reason |
|--------|------|-------------|------------|-----|-----------------|-------------|
| 3 | 3 | 0.9401 | 0.9294 | 0.0107 | 41.2k | target |
| 0 | 0 | 0.9310 | 0.9211 | 0.0099 | 44.8k | stagnation |
| 4 | 4 | 0.9399 | 0.9188 | 0.0211 | 47.0k | stagnation |
| 1 | 1 | 0.9204 | 0.9110 | 0.0094 | 52.3k | generations |
| 2 | 2 | 0.9142 | 0.9032 | 0.0110 | 55.1k | stagnation |

**Validation mean ± std** 0.9167 ± 0.0090 · **Success rate** 5/5 reached 0.90
**Overall champion** island 3, generation 102 · **Holdout** 0.9250 (evaluated once)

## Generalization

- Mean gap 1.24% — champions transfer across folds.
- Holdout fitness 0.9250 vs validation 0.9294 — consistent, no holdout surprise.

## Search behavior

- Best fitness improved until generation ~100 on all islands; ~10% of improvements
  arrived after generation 80 (recombination still productive late).
- Diversity floor held above 0.30 until generation ~120, then decayed on islands
  1 and 4 — expected near convergence, flagged in metrics.
- Migration (every 20 generations, ring, 2 elites) improved the receiving island's
  best 6/20 times — modest, keep.
- Island 4 restarted twice (generations 137, 168): champion preserved, re-seed
  recovered 0.9211 → 0.9399. `restart_count` = 2, last improvement after restart.
- Duplicate rejection averaged 12% of offspring; crossover produced 61% of
  improvements, mutation 34%, local search 5% (`operator_success_rate`).

## Cost

- 137,402 evaluations, cache hit rate 0.18, cohort p95 1.9s, peak RSS 810MB.
- Evaluator cost share 92% of wall clock; local search 6% of evaluations — keep.
- Mutation strength adapted from 0.08 down to 0.021 over the run (1/5 rule).

## Reproduction

```bash
just run --config configs/ga-run.json --resume ga-7f3a91
```

Config, folds, seeds, and fingerprints are in `build/runs/ga-7f3a91/run.duckdb`.

## Caveats

- Islands 1 and 4 stopped on stagnation before the generation budget — their
  validation numbers come from earlier champions.
- Validation std across folds is small (0.9%), but seed variance was not measured;
  rerun with 3 seeds before treating island 3 as reliably best.
````

## Artifact Layout

```
build/runs/<run_id>/
├── run.duckdb             # THE store: logs · generations · cohorts · best_params · champions · evaluations
├── certificate.json       # claim, bounds, gap, runs/successes, p_miss_upper, fingerprint
├── report.md              # the deliverable above
├── config.json            # frozen config + fingerprint
├── folds.json             # fold assignment
├── best_params.json       # optional export of the snapshot trail
├── log.jsonl              # optional export for tailing
├── metrics.csv            # optional export for spreadsheets
├── curves/                # fitness.svg, diversity.svg, gap.svg, cost.svg, pareto.svg
└── snapshots/             # resumable island state
```

## Querying a Live Run

The report reads from the same DuckDB the run writes to — no parsing, no waiting for completion:

```sql
-- champion trail for an island (improvements + periodic snapshots)
SELECT generation, reason, fitness, validation
FROM best_params
WHERE run_id = 'ga-7f3a91' AND island_id = 3
ORDER BY generation;

-- best genome as of generation 100 (time travel)
SELECT genome FROM best_params
WHERE run_id = 'ga-7f3a91' AND island_id = 3 AND generation <= 100
ORDER BY generation DESC LIMIT 1;

-- validation leaderboard with generalization gap
SELECT island_id, fitness AS train, validation, fitness - validation AS gap
FROM champions WHERE run_id = 'ga-7f3a91' ORDER BY validation DESC;

-- slowest generations
SELECT island_id, generation, generation_ms FROM generations
WHERE run_id = 'ga-7f3a91' ORDER BY generation_ms DESC LIMIT 10;
```

## Presentation Rules

1. **Lead with validation and holdout** — training curves support the claim, they do not make it.
2. **Lead with the claim type and its evidence** — `certified`, `bounded` (with gap and tolerance), `statistical` (with `p_miss_upper` and run count), or `best-so-far`. Never print "optimum" without a certificate.
3. **Always show mean ± std across islands** — a single number hides the fold story.
4. **Show the generalization gap per island** — the most important table in the report.
5. **Show the stopping reason per island and per run** — with the evidence that triggered it and the budget saved.
6. **Show the fingerprint and the rerun command** — an unreproducible report is an anecdote.
7. **Annotate the curves** — migrations, improvements, restarts, and certificates belong on the plot.
8. **Degrade silently, never fail** — no TTY, no color, no dependency: same content, plainer form.
9. **Report caveats** — seed variance unmeasured, folds imbalanced, evaluator noisy: say it.
10. **Point to the store** — the report is a view; `run.duckdb` (`best_params`, `generations`, `champions`) and `certificate.json` are the evidence. Name the run id and the query to reproduce any claim.
