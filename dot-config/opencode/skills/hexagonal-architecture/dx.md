# Developer Experience: Entry Points, Justfile, and Logs

## Entry Point Naming

The composition root can be named based on project role:

| Project Type      | Entry Point          |
| ----------------- | -------------------- |
| API/Web           | `main`, `api`, `app` |
| Worker/Background | `worker`, `consumer` |
| CLI               | `cli`, `main`        |
| Engine/Core       | `engine`, `core`     |
| Scheduler         | `scheduler`, `cron`  |
| Admin/Migration   | `admin`, `migrate`, `manage` |

Admin tasks are just another driving adapter — they reuse the same domain + adapters as the main app. Admin entry points are **root-level files** (`migrate.py`, `manage.py`), never an `admin/` folder.

```
# migrate.py (root) — same wiring as main, different driving adapter
from adapters.firestore_adapter import FirestoreDocumentAdapter
from infra.config import FirestoreConfiguration

config = FirestoreConfiguration.from_environment()
repo = FirestoreDocumentAdapter(config.project_id, config.collection_name)

# Run migration logic using the same domain workflows
```

## Root Justfile Requirements

Every project has a root `justfile` (or `Justfile`) that acts as a **light command index** — it names tasks and delegates; it never contains logic.

**Rules for a light justfile:**

- **One task, one command.** A recipe is a single line calling a program (`uv run python cli.py <task>`, `cargo run --bin <task>`, `npm run <task>`). No inline loops, `awk`, `sed`, or pipelines.
- **Logic lives in code**, in a root entry file (e.g. `cli.py`) or an adapter, where it is typed, tested, and reusable.
- **Doc-comment every recipe** so `just --list` is the menu.
- **`cd {{root}}` first** so recipes are cwd-independent.
- **Output is colored and structured** (see Terminal Output) — never raw `echo`.
- **Compose, don't duplicate:** combined gates depend on other recipes (`verify: check ...`).

```just
set shell := ["bash", "-uc"]
set dotenv-load

root := justfile_directory()

default:
    @just --list

# Develop
run:
    uv run python main.py
dev:
    uv run python cli.py dev
logs:
    uv run python cli.py logs

# Debug & DX
doctor:
    uv run python cli.py doctor
seed:
    uv run python cli.py seed
replay id:
    uv run python cli.py replay {{id}}

# Local-first backing services (only when using the DuckDB hub)
hub:
    uv run python cli.py hub
insights:
    uv run python cli.py insights
db-prune:
    uv run python cli.py db-prune
db-size:
    uv run python cli.py db-size
db-shell:
    uv run python cli.py db-shell

# Test
test:
    uv run pytest
test-unit:
    uv run pytest tests/unit
test-contract:
    uv run pytest tests/integration -k contract
test-integration:
    uv run pytest tests/integration
test-fault:
    uv run pytest tests -k fault
test-property:
    uv run pytest tests/property
test-e2e:
    uv run pytest tests/e2e

# Quality
lint:
    uv run ruff check .
format:
    uv run ruff format .
typecheck:
    uv run pyright
adapters-check:
    uv run lint-imports
errors-check:
    uv run python cli.py check-errors
sanitizers:
    uv run python cli.py sanitizers
mutation:
    uv run mutmut run

# Build
build:
    uv run python cli.py build
clean:
    rm -rf build/

# Dependencies
install:
    uv sync
update:
    uv lock --upgrade && uv sync

# Combined gates
check: lint typecheck adapters-check errors-check test
verify: check test-contract test-fault test-e2e
verify-hard: verify sanitizers
verify-plus: verify test-property mutation
```

### Terminal Output (Rich)

Terminal output is part of the DX: colored, aligned, and structured. It is a **presentation adapter** (`PresenterPort`), never ad-hoc `print`/`echo`.

- **Color with meaning:** green success, red error, yellow warning, cyan info, magenta headings, dim context.
- **Rich panels** for summaries, errors, and check results; **tables** for lists (adapters, insights, coverage); **spinners/progress** for long tasks.
- **Auto-degrade:** respect `NO_COLOR`, `--no-color`, `TERM=dumb`, and non-TTY → plain text. Never hardcode ANSI in domain or driven adapters.
- **Errors use the diagnostic contract:** render `code` + `origin` + `correlation_id` + cause chain in one panel.

```python
# domain/ports/presenter.py
from typing import Protocol, Sequence

class PresenterPort(Protocol):
    def success(self, message: str) -> None: ...
    def error(self, message: str) -> None: ...
    def warn(self, message: str) -> None: ...
    def info(self, message: str) -> None: ...
    def panel(self, title: str, body: str, style: str = "cyan") -> None: ...
    def table(self, title: str, headers: Sequence[str],
              rows: Sequence[Sequence[str]]) -> None: ...

# adapters/console/rich_presenter.py (dev/default) — `rich` panels + tables
from rich.console import Console
from rich.panel import Panel
from rich.table import Table

class RichPresenter(PresenterPort):
    def __init__(self, no_color: bool = False):
        self._console = Console(no_color=no_color)   # honors NO_COLOR / non-TTY
    def success(self, message): self._console.print(f"[green]OK[/green] {message}")
    def error(self, message):   self._console.print(f"[red]FAIL[/red] {message}")
    def warn(self, message):    self._console.print(f"[yellow]WARN[/yellow] {message}")
    def info(self, message):    self._console.print(f"[cyan]INFO[/cyan] {message}")
    def panel(self, title, body, style="cyan"):
        self._console.print(Panel(body, title=title, border_style=style, expand=False))
    def table(self, title, headers, rows):
        table = Table(title=title, show_lines=True)
        for header in headers:
            table.add_column(header, style="bold")
        for row in rows:
            table.add_row(*row)
        self._console.print(table)
```

```python
# rendering a failure as one panel
presenter.panel(
    f"[red]{err.code}[/red] {err.message}",
    f"origin: {err.origin}\ncorrelation: {err.correlation_id}\ncause: {err.cause}",
    style="red",
)
```

| Language | Presenter library |
| -------- | ----------------- |
| Python | `rich` (panels, tables, progress) |
| TypeScript/Node | `boxen` + `chalk` (+ `ora`, `listr2`) |
| Rust | `comfy-table` + `owo-colors` (+ `indicatif`) |
| Dart/Flutter | `ansicolor` (+ a small panel helper) |
| C++ | `fmt` + a small color/panel helper |

**Path variables:** Every justfile defines `root := justfile_directory()` at the top — the directory the justfile lives in. Multi-project repos define one path variable per project below it. Recipes `cd` into their target working directory before running commands, so a command never depends on the caller's cwd:

```just
# Single project — root is this project's directory
root := justfile_directory()

test:
    cd {{root}} && uv run pytest

build:
    cd {{root}}/infra && docker compose build
```

```just
# Multi-project workspace — one path var per project
root := justfile_directory()
backend_dir := root / "backend"
frontend_dir := root / "frontend"

test-backend:
    cd {{backend_dir}} && just test

test-frontend:
    cd {{frontend_dir}} && just test
```

**Why these commands matter:**
- `lint` + `format` + `typecheck` catch errors before they reach tests
- `adapters-check` keeps adapters portable (no app imports, no env reads)
- `test-unit` gives fast feedback during development
- `build` + `clean` ensure reproducible builds from source
- `check` is the single command to run before committing

## Workspace Log Streaming

Every workspace gets a `logs` command that streams all services in real-time with color-coded service identification.

### How It Works

1. Each service's `logs` command writes to stdout
2. A prefix helper tags each line with `[service-name]`
3. The central `logs` command pipes all services through parallel execution

### Color Assignments

| Service  | ANSI Color   | Example                                |
| -------- | ------------ | -------------------------------------- |
| api      | 34 (blue)    | `[api         ] GET /docs 200`         |
| worker   | 33 (yellow)  | `[worker      ] Processing job #123`   |
| frontend | 35 (magenta) | `[frontend    ] Hot reload complete`   |
| device   | 32 (green)   | `[device      ] Sensor reading: 23.5C` |
| shared   | 36 (cyan)    | `[shared      ] Cache invalidated`     |
