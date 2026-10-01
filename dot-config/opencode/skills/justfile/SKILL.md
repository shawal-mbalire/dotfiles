---
name: justfile
description: Design, write, and refactor justfiles — a make replacement with strict parsing, path variables, parameterized recipes, and nested monorepo subcommands like `just frontend dev`, `just mobile run`, `just test all`. Use when creating or editing justfile/Justfile/.justfile, adding subcommands, wiring path vars across nested justfiles, migrating from Makefile, or debugging just recipe/attribute/module issues.
---

# Justfile

`just` is a command runner, not a build system. No dependency graphs, no timestamps — recipes run when you ask, in the order you ask. What it gives you instead: strict parsing (typos fail fast), first-class variables and path helpers, parameterized recipes, attributes for control flow, and nested/multi-justfile layouts for monorepos.

## UX Rules (Locked)

1. **Space-separated subcommands everywhere** — `just backend run`, `just test all`, `just frontend dev`. Never `backend-run`, never `backend:run`.
2. **Short delegation only** — `cd dir && just` or `just -f path`. Never long `--justfile` / `--working-directory` flags.
3. **Children are fully self-contained** — no shared import files, no env-var injection from root. Duplicate tiny constants if needed.
4. **Just wraps package scripts** — recipes call `npm run …`, `cargo …`, `flutter …`; just is thin glue, not the command owner.
5. **Cross-stack ops use target-dispatch** — `just test all`, `just build all`, `just fmt all`, `just run backend`, `just deploy frontend prod`. Bare target defaults to `all`.
6. **Silent single-line commands** — every recipe command line is prefixed with `@` so just never echoes it. One `@`-command per line.
7. **Python shebang for extra logic** — when a recipe needs more than a trivial one-liner (control flow, validation, string juggling, multi-step ops), use an inline `#!/usr/bin/env python3` shebang recipe body **inside the justfile**. No external script files; the body *is* the logic.

## Reference Files

`SKILL.md` is the map. Open a file below only when you need its depth.

| Topic | File |
|-------|------|
| Monorepo layout, directory-chdir delegation, root router patterns | [nesting.md](./nesting.md) |
| Target-dispatch (`just test all`), params, private/group/doc recipes | [subcommands.md](./subcommands.md) |
| Path variables, `justfile_directory()`, self-contained children | [path-vars.md](./path-vars.md) |
| Attributes, `set` options, shell completion, CI patterns, Makefile migration | [patterns.md](./patterns.md) |

## Anatomy

```just
set shell := ["bash", "-euo", "pipefail", "-c"]
set positional-arguments := true

root := justfile_directory()

default:
    @just --list

greet who=name:
    @echo "Hello, {{who}}!"

deploy env target *flags:
    #!/usr/bin/env python3
    import sys
    env, target, *flags = sys.argv[1:]
    if env not in ("dev", "staging", "prod"):
        sys.exit(f"bad env: {env}")
    print(f"deploying {target} to {env}")
```

Rules that matter:

- `@` before a command line silences just's echo of that line — prefix **every** recipe line.
- Recipe body lines are concatenated into **one** shell script — not run line-by-line like make.
- A body starting with `#!` is a **shebang recipe**: just runs it with that interpreter (Python here), and recipe params arrive as `sys.argv[1:]` (requires `set positional-arguments := true` or the `[positional-arguments]` attribute).
- Indentation must be consistent (4 spaces preferred).
- Variables use `:=` (immediate) or `=` (lazy). Params are `name` or `name=default`.
- `{{expr}}` interpolates; quote with `{{quote(arg)}}` when needed.
- Strict by default: typos in variables/recipes fail the whole run.

## Extra Logic → Inline Python Shebang (Default)

Recipes stay **one line** whenever possible. The moment a recipe needs branching, loops, env/arg validation, or more than a couple of chained commands, **default to an inline Python shebang body** — no external script files:

```just
[private]
[positional-arguments]
check-tools:
    #!/usr/bin/env python3
    import shutil
    for tool in ("just", "node", "docker"):
        if shutil.which(tool) is None:
            raise SystemExit(f"missing tool: {tool}")
    print("all tools present")
```

```just
[positional-arguments]
sync source target:
    #!/usr/bin/env python3
    import sys
    source, target = sys.argv[1:3]
    if source == target:
        raise SystemExit("source and target are the same")
    # ...logic lives here, not in shell...
```

- **Shebang recipe**: first body line is `#!/usr/bin/env python3`; just executes the whole body as a Python script.
- **Params → argv**: add `set positional-arguments := true` at the top (or `[positional-arguments]` per recipe) so recipe args arrive as `sys.argv[1:]`.
- Keep non-logic recipes as silent one-liners; reserve shebang bodies for recipes that actually need logic.
- Exit non-zero (`sys.exit(...)` / `raise SystemExit`) to fail the recipe like any failing command.

## Async Processes (Concurrent Work)

Two tools, chosen by what you're fanning out:

### 1. `[parallel]` dependencies — fan out *recipes*

Parallelize a recipe's dependencies with the `[parallel]` attribute (just ≥ 1.42). Cap concurrency with `--jobs N` (or `JUST_JOBS`), read the limit in-recipe with `num_jobs()`:

```just
[parallel]
build-all: build-a build-b build-c

build-a:
    @sleep 0.5 && echo "built a"
build-b:
    @sleep 0.5 && echo "built b"
build-c:
    @sleep 0.5 && echo "built c"
```

- Only **direct** dependencies fan out; the body runs after they all finish.
- Shared transitive deps run exactly once (deduped), so `setup → fan-out` graphs work.
- `just --jobs 2 build-all` caps at 2 concurrent recipes.
- Params pass through naturally: `[parallel] all: (_check "lint") (_check "test")`.

### 2. Python `asyncio` / `subprocess` shebang — fan out *tasks within one recipe*

When the work is granular (many items, one operation), keep it in the recipe body via an inline shebang:

```just
[positional-arguments]
fanout *items:
    #!/usr/bin/env python3
    import asyncio, sys

    async def work(name: str) -> None:
        await asyncio.sleep(0.2)
        print(f"done {name}", flush=True)

    async def main() -> None:
        await asyncio.gather(*(work(t) for t in sys.argv[1:]))

    asyncio.run(main())
```

```just
fetch *urls:
    #!/usr/bin/env python3
    import sys
    from concurrent.futures import ThreadPoolExecutor
    import urllib.request

    urls = sys.argv[1:]
    with ThreadPoolExecutor(max_workers=8) as pool:
        list(pool.map(urllib.request.urlopen, urls))
    print(f"fetched {len(urls)} urls")
```

- `asyncio` for I/O-bound concurrency; `ThreadPoolExecutor` for blocking calls; `subprocess.Popen` to spawn external processes.
- `flush=True` on prints keeps interleaved output readable.
- Any non-zero exit (or uncaught exception) fails the recipe like a failing command.

Choose `[parallel]` when the units are named recipes; choose a Python shebang when the units are items/data.

## Discovery & Invocation

`just` searches upward from cwd for `justfile`, `Justfile`, or `.justfile`.

```bash
just                     # default recipe
just --list              # available recipes — run this first on unfamiliar repos
just recipe arg1 arg2
just -f path/to/justfile recipe
just --dry-run recipe
just --evaluate          # dump variables
just --summary           # script-friendly one-liner
```

## Canonical Invocation Surface (Monorepo)

```bash
just                       # root list
just setup                  # install everything (orchestrates all stacks)

just frontend               # frontend's list (child default recipe)
just frontend dev           # npm run dev in frontend/
just frontend dev --port 4000
just backend run
just mobile run

just test all               # backend → frontend → mobile, sequential
just test                   # same as `just test all` (target defaults to all)
just test backend           # just one stack
just build all
just fmt all
just lint all
just run backend
just deploy frontend prod
```

## Makefile Mindset Shift

| Make | Just |
|------|------|
| Targets + prerequisites DAG | Recipes, run on demand, no DAG |
| Tabs required | Spaces (or tabs) |
| `.PHONY` | Not needed — recipes aren't files |
| `$@`, `$<` | `{{arg}}`, parameters |
| Pattern rules | Parameterized recipes, no patterns |
| `include` | `import` (rarely — children stay self-contained) |
| Sub-makes `$(MAKE) -C dir` | `cd dir && just` or `just -f dir/justfile` |

## Composition Tool Choice

- **Multi-stack monorepo** (default): root router + directory-chdir children. See [nesting.md](./nesting.md).
- **Single package**: one justfile, `[group: "..."]` buckets, short names (`dev`, `build`) — no hyphenation.
- **`import`**: avoid for shared vars (children are self-contained by rule). Only for truly pure one-off helpers if forced.
- **`mod`**: avoid — colon syntax (`frontend:dev`) violates the space-separated rule.
