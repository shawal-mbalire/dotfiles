# Path Variables

Just is path-aware. Lean on builtins instead of hardcoding strings.

**Rule:** children are fully self-contained — no shared import files, no env injection from root. Each justfile derives what it needs from `justfile_directory()`; duplicate tiny constants locally if required.

## Core Path Functions

```just
root := justfile_directory()        # dir containing THIS justfile
cwd  := invocation_directory()      # dir where `just` was invoked from
home := env_var_or_default("HOME", "/tmp")
```

- **`justfile_directory()`** — right default for "where am I?" in any justfile (root or nested). Stable regardless of caller or working directory.
- **`invocation_directory()`** — original caller cwd; rarely needed in nested setups.
- In a child, `justfile_directory()` → the child's dir (e.g. `.../repo/frontend`). Self-contained by construction.

## Path Joining with `/`

```just
root     := justfile_directory()
frontend := root / "frontend"
dist     := root / "dist"
entry    := root / "src" / "index.ts"
```

- `/` is just's path operator — normalizes separators, no concat bugs.
- Never write `root + "/frontend"` — use `/`.

## Child Paths (Self-Contained)

```just
# frontend/justfile
here := justfile_directory()     # .../repo/frontend
# repo := here / ".."            # only if you must reach root/siblings

default:
    @just --list

build:
    npm --prefix {{here}} run build    # anchored, cwd-independent
    # or simply: npm run build         # cwd is already frontend/
```

- Prefer relative commands (`npm run build`) — cwd is always the child dir under directory-chdir.
- Anchor with `{{here}} / ...` only when bypassing the router or calling sibling paths.
- Climb with `here / ".."` for root-level resources; don't hardcode `../..` chains.

## What NOT to Share Across Nested Files

By design (locked preference): **no shared just-vars file, no root env injection.**

| Approach | Verdict |
|----------|---------|
| Duplicate `node_version := "22"` in each child | ✅ Preferred — explicit, zero coupling |
| `import '../shared/just-vars.just'` | ❌ Avoid — creates hidden coupling, collision risk |
| Root injects `REPO_ROOT=… ` env when delegating | ❌ Avoid — implicit, hard to debug |
| `.env` / `set dotenv-load` per child for local config | ✅ Fine — runtime config, not structural sharing |

If a constant truly must be identical everywhere (e.g. `node_version`), either:

1. Let the tooling own it (`.nvmrc`, `engines` in package.json) and read it via `env_var`/file at runtime, or
2. Accept duplication and update both places — justfiles are small.

## Environment Variables (Runtime Config)

```just
ci := env_var_or_default("CI", "false")
api_url := env_var_or_default("API_URL", "http://localhost:3000")

deploy:
    curl -X POST {{api_url}}/deploy
```

- `env_var("X")` — errors if unset (required secrets in CI).
- `env_var_or_default("X", "fallback")` — optional knobs.
- Per-invocation: `API_URL=https://staging.example just deploy`.
- `.env` via `set dotenv-load := true` — fine for local dev; CI sets vars explicitly.

## Recipe Params as Paths

```just
bundle entry="src/index.ts":
    esbuild {{entry}} --bundle --outfile=dist/out.js

bundle entry="src/index.ts":
    esbuild {{quote(entry)}} --bundle
```

- Defaults may be relative — resolved against recipe cwd (child dir).
- Always `{{quote(...)}}` user-supplied path params for shell safety.

## Anchored Tool Invocations (Root)

```just
root := justfile_directory()

fmt:
    ruff format {{root}}/backend
    prettier --write {{root}}/frontend/src
```

Root-level cross-stack recipes anchor on `{{root}}` so they work regardless of invocation cwd.

## Anti-Patterns

- Hardcoded absolute paths (`/home/you/repo/...`) — breaks CI and other machines.
- String concat for paths (`root + "/x"`) — use `/`.
- Shared `just-vars.just` imports — children stay self-contained.
- Root env-smuggling (`REPO_ROOT=… just …`) — prefer self-contained or duplicate.
- `invocation_directory()` for outputs — callers' cwd varies; anchor on `justfile_directory()`.
