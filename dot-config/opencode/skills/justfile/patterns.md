# Attributes, Settings, Completion & CI

## Essential Attributes

```just
[private]
helper:
    echo "hidden from --list"

[group: "frontend"]
dev:
    npm run dev

[doc: "Build production bundles"]
build:
    npm run build

[linux]
only-linux:
    echo "runs on linux only"

[macos]
only-macos:
    echo "runs on macOS only"

[windows]
only-windows:
    echo "runs on windows"

[confirm]
dangerous:
    rm -rf build/

[confirm("Really delete?")]
interactive-dangerous:
    rm -rf build/

[no-cd]
stay-in-invocation-dir:
    pwd   # stays where `just` was run, not justfile dir

[no-exit-message]
quiet-fail:
    false   # suppresses just's exit banner

[private]
[confirm]
cleanup:
    rm -rf tmp/
```

- **`[private]`** — hide from `--list`; still callable by name.
- **`[group: "..."]`** — bucket in `--list`; single-file alternative to hyphenated names.
- **`[doc: "..."]`** — human-readable help line.
- **`[confirm]` / `[confirm("msg")]`** — y/N prompt before destructive ops.
- **`[no-cd]`** — stay at invocation cwd instead of justfile dir.
- **`[no-exit-message]`** — suppress exit status banner.
- **`[linux]` / `[macos]` / `[windows]`** — platform-gated.
- Stack attributes on separate lines above the recipe.

## Settings (Top of File)

```just
set shell := ["bash", "-euo", "pipefail", "-c"]   # strict bash everywhere
set positional-arguments := true                  # $1.. in shebang/body
set dotenv-load := true                           # auto-load .env
set export := true                                # export vars to recipes
set allow-duplicate-recipes := false              # default: errors on dupes
set tempdir := "/tmp"
set dotenv-path := ".env"
set working-directory := justfile_directory()     # default; rarely change
```

- **`set shell`** — one place for `set -euo pipefail`; every recipe inherits it.
- **`set dotenv-load`** — `.env` → just vars + recipe env. Local dev yes; CI sets vars explicitly.
- **`set export`** — all vars exported (careful with secrets; prefer explicit `export FOO := ...` for those).
- **`set positional-arguments`** — `$1`, `$2` available alongside `{{param}}`.

## Shebang Recipes

Multiline logic → shebang; body becomes one script:

```just
[private]
check:
    #!/usr/bin/env bash
    set -euo pipefail
    for f in src/*.ts; do
        npx tsc --noEmit "$f"
    done
```

- `#!` on first line switches to shebang mode; `{{interpolation}}` still applies before exec.
- Prefer `set shell` for one-liners; shebangs for control flow (if/for/case).

## Shell Completion

### Bash

```bash
just --completions bash > ~/.local/share/bash-completion/completions/just
# or
just --completions bash > /etc/bash_completion.d/just
```

### Zsh

```bash
just --completions zsh > "${fpath[1]}/_just"    # ensure fpath dir exists first
```

### Fish

```bash
just --completions fish > ~/.config/fish/completions/just.fish
```

### Others

```bash
just --completions nu
just --completions elvish
just --completions powershell
```

Completions cover recipe names (via `--list`) + parameter hints where supported. New recipes appear next shell session (dynamic `--list`-backed completion — no regen).

## CI-Friendly Patterns

### Discoverability

```bash
just --list            # humans
just --summary         # space-separated names — scripts
just --evaluate        # dump variables (debug CI env)
just --dry-run build   # print without executing
just --unstable --list --groups
```

### Fail fast

```just
set shell := ["bash", "-euo", "pipefail", "-c"]

ci-test:
    just --summary >/dev/null   # parse check
    just test all
```

- CI invokes **explicit names**: `just test all`, `just build all`, `just setup`.
- Lint jobs: `just --summary` / `just --dry-run` to validate justfiles without side effects.

### Idempotent / CI-safe env

```just
ci := env_var_or_default("CI", "false")

test target="all" *args:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "{{ci}}" == "true" ]]; then
      # CI branch — coverage, retries, etc.
      ...
    else
      ...
    fi
```

### Concurrency

No built-in lock — if two CI jobs write shared state, `flock` inside the recipe or serialize at the CI layer. Target-dispatch (`just test all`) is sequential by design (readable logs).

### Calling just in CI

```yaml
# GitHub Actions sketch
- uses: extractions/setup-just@v2
- run: just --list
- run: just setup
- run: just test all
  working-directory: .
```

Pin just version in CI (`setup-just` or `cargo install just --version X.Y.Z`) so attributes/settings match local.

## Makefile → Just Migration Checklist

1. **Targets → recipes**: drop timestamp deps; keep ordering deps (`build: prepare`) only if truly sequential.
2. **Tabs → spaces** (4). Fix mixed indentation — just is strict.
3. **Automatic vars**: `$@`/`$<` → `{{param}}`.
4. **`.PHONY`**: delete — recipes aren't files. Rename if a recipe creates a same-named file.
5. **`include`**: → avoid (self-contained children); use `env_var_or_default` for optionals.
6. **Sub-makes** (`$(MAKE) -C dir`): → `cd dir && just` / `just -f dir/justfile`. Cross-stack targets → target-dispatch (`just test all`), **not** `backend-test` hyphens.
7. **Pattern rules**: no equivalent — parameterized recipe instead.
8. **Variable export**: explicit `export FOO := ...` or `set dotenv-load` / `set export`.
9. **`.DEFAULT_GOAL`**: first recipe wins, or name one `default`. Put `default:` first.
10. **Validate**: `just --list` + `just --dry-run <target>` after each chunk.
