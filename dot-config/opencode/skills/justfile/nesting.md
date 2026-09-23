# Nested Justfiles (Directory-CHDir Style)

Assumed layout — monorepo multi-stack:

```
repo/
├── justfile                 # root coordinator + target-dispatch ops
├── frontend/
│   ├── justfile             # frontend-only, fully self-contained
│   └── package.json
├── mobile/
│   └── justfile
└── backend/
    └── justfile
```

Each subdirectory justfile is **fully self-contained** — no imports from root, no env injection, duplicate tiny constants if needed. The root justfile never duplicates stack recipes — it only *delegates*.

**Goal UX:** `just frontend dev`, `just backend run`, `just test all`, `just setup`.

## Root: Stack Routers

Two clean forms. Prefer Form A.

### Form A — `cd && just` (clearest)

```just
# root justfile
root := justfile_directory()

default:
    @just --list

frontend *args:
    @cd {{root}}/frontend && just {{args}}

mobile *args:
    @cd {{root}}/mobile && just {{args}}

backend *args:
    @cd {{root}}/backend && just {{args}}
```

### Form B — short `-f` flag (no subshell)

```just
root := justfile_directory()

frontend *args:
    @just -f {{root}}/frontend/justfile {{args}}

mobile *args:
    @just -f {{root}}/mobile/justfile {{args}}

backend *args:
    @just -f {{root}}/backend/justfile {{args}}
```

### Why this shape works

- `*args` forwards everything: `just frontend dev --port 3000` → `dev --port 3000` inside `frontend/justfile`.
- `@` silences the delegation line; child output still shows.
- Root is a pure router — no stack logic leaks upward.
- Namespaces isolate: `dev` in `frontend/` and `dev` in `backend/` never collide.

### Bare `just frontend` → child's list

Each child's `default` recipe prints its own `--list`. Root does **not** intercept empty args:

```just
frontend *args:
    @cd {{root}}/frontend && just {{args}}
```

```just
# frontend/justfile
default:
    @just --list
```

So `just frontend` (no subcommand) runs the child's default → prints frontend recipes. Each stack owns its help text.

## Root: Target-Dispatch Cross-Stack Ops

Uniform pattern for `test`, `build`, `fmt`, `lint`, `run`, `deploy` — space-separated, target defaults to `all`:

```just
# Shared shape: target first, defaults to "all", variadic tail for pass-through
test target="all" *args:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "{{target}}" == "all" ]]; then
      just backend test {{args}}
      just frontend test {{args}}
      just mobile test {{args}}
    else
      just {{target}} test {{args}}
    fi

build target="all" *args:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "{{target}}" == "all" ]]; then
      just backend build {{args}}
      just frontend build {{args}}
      just mobile build {{args}}
    else
      just {{target}} build {{args}}
    fi

fmt target="all" *args:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "{{target}}" == "all" ]]; then
      just backend fmt {{args}}
      just frontend fmt {{args}}
      just mobile fmt {{args}}
    else
      just {{target}} fmt {{args}}
    fi

lint target="all" *args:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "{{target}}" == "all" ]]; then
      just backend lint {{args}}
      just frontend lint {{args}}
      just mobile lint {{args}}
    else
      just {{target}} lint {{args}}
    fi

run target *args:
    just {{target}} run {{args}}

deploy target env *args:
    just {{target}} deploy {{env}} {{args}}
```

Invocation:

```bash
just test              # → test all (default target)
just test all          # explicit
just test backend      # one stack
just build all
just fmt
just lint frontend
just run backend
just deploy frontend prod
```

Notes:

- Sequential `just stack verb` lines — readable CI logs, deterministic order.
- `run` / `deploy` require an explicit target (no sensible "run all" default).
- `test` / `build` / `fmt` / `lint` default `target="all"`.

### Factoring the dispatch (optional)

If the `if/else` boilerplate bothers you, extract a private helper:

```just
[private]
_each verb *args:
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{args}}"   # first word
    rest="${@:2}"
    ...
```

Usually not worth it — four explicit lines per verb is clearer than a clever helper.

## Root: Setup Orchestrator

```just
setup:
    @just backend setup
    @just frontend setup
    @just mobile setup
```

Each child owns its own install logic:

```just
# backend/justfile
setup:
    cargo fetch
    # or: make deps, pip install, etc.

# frontend/justfile
setup:
    npm ci

# mobile/justfile
setup:
    npm ci
    cd ios && pod install
```

- Bare `just setup` at root installs everything, sequential.
- `just frontend setup` still works standalone — child is self-contained.

## Child Justfiles: Self-Contained Stacks

```just
# frontend/justfile
here := justfile_directory()     # → .../repo/frontend

default:
    @just --list

setup:
    npm ci

dev port="3000":
    npm run dev -- --port {{port}}

build:
    npm run build

test *args:
    npm test {{args}}

fmt:
    npm run fmt

lint:
    npm run lint
```

Key points:

- `justfile_directory()` resolves to the **child's** dir — self-contained paths, no knowledge of root.
- Recipes wrap package scripts (`npm run dev`, not raw `vite`) — just is glue.
- Relative paths work freely because cwd is always the child dir.
- Children never call back into root — dependency stays root → child.
- Duplicate `node_version := "22"` locally if needed; do **not** import a shared file.

## Passing Flags Through Layers

```bash
just frontend dev --host 0.0.0.0
just test backend --coverage --filter auth
just build all --quiet
```

Variadic `*args` forwards flags root never needs to understand. Inject shared context in the **child** signature via defaulted params if absolutely required — never via root env-smuggling.

## When NOT to Use Directory-CHDir

- **Single package**: one justfile, `[group: "..."]`, short names — no router.
- **You accept `:` syntax**: `mod frontend 'frontend/justfile'` → `just frontend:dev` (violates space-separated rule — avoid for this skill).

## Debugging Delegation

```bash
just --dry-run frontend dev        # what would root forward?
just -f frontend/justfile --list   # what does the child expose?
just -f frontend/justfile --evaluate
just test backend --dry-run
```

If `just frontend dev` fails, inspect the child directly with `-f` — recipe mismatch between root mental model and child file is the usual cause.
