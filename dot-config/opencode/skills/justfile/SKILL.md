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

root := justfile_directory()

default:
    @just --list

greet who=name:
    echo "Hello, {{who}}!"

deploy env target *flags:
    ./deploy.sh {{env}} {{target}} {{flags}}
```

Rules that matter:

- Recipe body lines are concatenated into **one** shell script — not run line-by-line like make.
- Indentation must be consistent (4 spaces preferred).
- Variables use `:=` (immediate) or `=` (lazy). Params are `name` or `name=default`.
- `{{expr}}` interpolates; quote with `{{quote(arg)}}` when needed.
- Strict by default: typos in variables/recipes fail the whole run.

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
