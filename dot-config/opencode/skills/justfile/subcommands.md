# Subcommands, Target-Dispatch & Recipes

**UX rule:** space-separated only — `just backend run`, `just test all`, `just frontend dev`. Never `backend-run`, never `backend:run`.

## 1. Stack Router Subcommands (Primary)

Root recipe + `*args` → cd/`-f` into child. See [nesting.md](./nesting.md).

```just
frontend *args:
    @cd {{root}}/frontend && just {{args}}
```

→ `just frontend dev`, `just mobile run`.

## 2. Target-Dispatch Cross-Stack Ops

For verbs that apply to one stack *or* all stacks — `test`, `build`, `fmt`, `lint`, `run`, `deploy`:

```just
[positional-arguments]
test target="all" *args:
    #!/usr/bin/env python3
    import subprocess, sys

    target = sys.argv[1] if len(sys.argv) > 1 else "all"
    args = sys.argv[2:]
    stacks = ("backend", "frontend", "mobile") if target == "all" else (target,)

    for stack in stacks:
        proc = subprocess.run(["just", stack, "test", *args])
        if proc.returncode != 0:
            raise SystemExit(proc.returncode)
```

Rules:

| Verb | Target default | Example |
|------|----------------|---------|
| `test` | `"all"` | `just test`, `just test backend` |
| `build` | `"all"` | `just build all`, `just build frontend` |
| `fmt` | `"all"` | `just fmt`, `just fmt backend` |
| `lint` | `"all"` | `just lint frontend` |
| `run` | *required* | `just run backend` |
| `deploy` | *required* + env | `just deploy frontend prod` |

- Space-separated: `just test all` / `just test backend` — not `test-all`, not `test:backend`.
- Sequential child calls — readable logs, deterministic order; `@` keeps each line silent.
- Dispatch logic uses an **inline Python shebang body** (see [SKILL.md](./SKILL.md) — Python owns external commands); each `just stack verb` call runs via `subprocess` inside the body, so sequencing and validation stay in Python. Params arrive as `sys.argv[1:]` with `set positional-arguments := true` or the `[positional-arguments]` attribute.
- `run`/`deploy` take explicit target (no "run everything" default).
- Validation: unknown target → `just {{target}} …` fails naturally (child router 404s) or add a guard in the shebang body.

### Bare `just test` → defaults to `all`

`target="all"` as a defaulted param means `just test` ≡ `just test all`. No special empty-arg handling needed.

## 3. Single-File Multi-Stack: Groups, Not Hyphens

One justfile? Keep names short, bucket with groups — never `frontend-dev`:

```just
[group: "frontend"]
dev:
    @npm --prefix frontend run dev

[group: "frontend"]
build:
    @npm --prefix frontend run build

[group: "mobile"]
run:
    @npm --prefix mobile run ios

[group: "backend"]
run:
    @cargo run
```

If stacks need colliding bare names (`dev` × 3), split into nested justfiles (section 1) instead of hyphenating.

## 4. Native Modules (`mod`) — Avoid

`mod frontend 'frontend/justfile'` → `just frontend:dev` (colon). Violates space-separated rule. Skip unless explicitly accepting that syntax.

## Parameterized Recipes

```just
deploy environment:
    @./deploy {{environment}}

serve port=8080 host="127.0.0.1":
    @python -m http.server {{port}} --bind {{host}}

test *args:
    @pytest {{args}}

test env="dev" *args:
    @ENV={{env}} pytest {{args}}
```

- Params positional; defaults make trailing params optional.
- `*args` must be last — swallows everything remaining.
- Quote: `{{quote(name)}}` for shell-safe interpolation.

## Private / Hidden Recipes

```just
[private]
prepare-env:
    @export FOO=bar

[private]
_check-tools:
    @command -v jq >/dev/null || echo "jq missing"
```

`[private]` hides from `--list`; `just prepare-env` still works for scripts/CI.

## Doc & Group Metadata

```just
[doc: "Start the frontend dev server"]
[group: "frontend"]
dev:
    @npm run dev
```

- `doc:` — help line in `--list`.
- `group:` — buckets in `--list`; also the single-file alternative to hyphenated names.

## Calling Other Recipes From a Recipe

```just
build-all: prepare

build-all:
    @just frontend build
    @just backend build
```

1. **Dependency line** (`recipe: dep1`) — runs deps first, then body.
2. **Explicit `@just other`** in body — full control over order/conditionals.

For cross-stack target-dispatch, always use explicit `just stack verb` inside shebang bodies — dependency lines don't compose across `-f` boundaries.

## Setup Orchestrator

```just
setup:
    @just backend setup
    @just frontend setup
    @just mobile setup
```

Each child defines its own `setup` (`npm ci`, `cargo fetch`, `pod install`). Root `just setup` runs them all; `just frontend setup` still works standalone.

## Subcommand Router Idiom (External CLIs Only)

When dispatching a single external CLI with many verbs:

```just
[positional-arguments]
db *args:
    #!/usr/bin/env python3
    import subprocess, sys

    action = sys.argv[1] if len(sys.argv) > 1 else "help"
    if action in ("migrate", "seed"):
        cmd = ["docker", "exec", "-i", "web", "python", "manage.py", action, *sys.argv[2:]]
        raise SystemExit(subprocess.run(cmd).returncode)
    print("usage: just db {migrate|seed}")
    raise SystemExit(1)
```

Use sparingly — separate recipes + `--list` usually beat a hand-rolled router. Reach for this only for `kubectl`/`docker`/`terraform`-style external verbs. Params arrive as `sys.argv[1:]` via the `[positional-arguments]` attribute (or `set positional-arguments := true`).
