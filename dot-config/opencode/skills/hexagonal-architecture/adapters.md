# Adapters

#### Adapter Design for Reusability and Transferability

Write each adapter so **only its file(s) move** to another project. It must work there unmodified — it targets standard ports and knows nothing about your app.

**Portability rules:**

- Import only: standard library, the third-party driver, and standard ports. **No app-`domain` imports, no sibling-adapter imports.**
- Accept a frozen **config struct** via the constructor (URLs, credentials, table/collection names) — never read env vars.
- Take pure `to_row` / `from_row` mappers (and the entity/table name) via the constructor so the adapter is aggregate-agnostic.
- Translate vendor errors into port errors (`NotFoundError`, `ConflictError`, `StorageUnavailableError`); never leak SDK types or exceptions.
- Keep mapping/validation in **pure functions** testable without I/O; the I/O method stays thin.
- Register cleanup via `LifetimePort` — no module-level connections, no global state read at import time.
- Header the file with: backend, port(s) implemented, required driver, config fields, backend assumptions.

**File anatomy of a portable adapter:**

```
adapters/<backend>/
├── <backend>_adapter.py     # I/O: implements the standard port(s)
├── <backend>_mappings.py    # pure: row <-> domain conversions (injectable)
└── <backend>_config.py      # frozen config struct (constructor-injected)
```

**Anti-patterns:** `os.getenv` inside the adapter; importing `domain.models`; returning SDK objects or raw rows; hardcoded table/collection names; module-level connections; swallowing errors.

#### Persistence (Adapter-as-ORM)

Relational persistence goes through a **`*Repository` port** implemented by a **SQL adapter**. There is no ORM layer: the adapter owns its SQL and its row → domain mapping, so the adapter *is* the ORM. Use the database driver directly (or a thin query builder) — never an ORM.

**Rules:**

- Write SQL in the adapter; map rows ↔ domain models with **pure functions** (`*_mappings`) at the boundary
- Rows/DB records live in `adapters/`, never in `domain/` — the domain stays framework-free and SQL-free
- Never return a driver/DB row from a port; return domain models
- The repository adapter owns the connection/transaction lifecycle (open, commit, rollback, close) and registers cleanup via `LifetimePort`
- Use parameterized queries only — never string-interpolate user input
- Migrations live with the adapter or in `infra/` and are applied by a root-level admin entry point (`migrate.py`), not at app startup by default
- One repository per aggregate; keep SQL behind the port, never spread through workflows
- Document stores (Firestore, DynamoDB, Mongo) follow the same shape: driver + pure mappings

| Language | SQL access |
| -------- | ---------- |
| Python | `sqlite3` / `duckdb` / `psycopg` (DB-API), optional SQLAlchemy Core (SQL toolkit, not the ORM) |
| TypeScript/Node | `pg` / `better-sqlite3` / `@duckdb/node-api` |
| Rust | `sqlx` / `rusqlite` / `duckdb` crate |
| Dart/Flutter | `sqlite3` / `sqflite` |
| C++ | `sqlite3` / `duckdb` C++ API |

Full example: [Python, SQL repository adapter](./python.md#sql-repository-adapter-python).

#### Reusable Adapters

The unit of reuse is **the adapter file**. If you can copy it into another project and it compiles/runs unmodified, it is reusable. Adapters in a personal collection are written to this standard.

**The portability contract:**

1. **Standard ports only** — import the generic port (`Repository[T, IdT]`, `CachePort`, …) and the driver. Never import the app's `domain/`, its models, or sibling adapters.
2. **Config struct injected** — a frozen config object (URL, credentials, table/collection) passed to the constructor. No env reads, ever.
3. **Mappers injected** — pure `to_row`/`from_row` functions (plus the entity/table name) passed in, so the adapter never names a domain model.
4. **Errors translated** — vendor exceptions/rows become port errors (`NotFoundError`, `ConflictError`, `StorageUnavailableError`); SDK objects never cross the port.
5. **Lifecycle via port** — connections/clients are created from injected config and closed through `LifetimePort`; nothing global, nothing at import time.

```
# Portable — copy the file, inject config + mappers, done
class SqlRepository(Repository[T, IdT]):
    def __init__(self, connection, config: SqlConfig,
                 to_row, from_row, id_of):
        self._connection = connection
        self._config = config          # frozen: table name, etc.
        self._to_row = to_row          # pure
        self._from_row = from_row      # pure
        self._id_of = id_of

    def save(self, entity: T) -> None:
        self._connection.execute(self._config.upsert_sql, self._to_row(entity))

    def find_by_id(self, entity_id: IdT) -> T | None:
        row = self._connection.execute(self._config.select_sql, (entity_id,)).fetchone()
        return self._from_row(row) if row else None

# NOT portable — app imports, env reads, hardcoded names, SDK types
class BadRepository:
    def __init__(self):
        from domain.models.document import Document   # imports the app
        self.table = "documents"                        # hardcoded
        self.dsn = os.getenv("DATABASE_URL")            # env read
    def find(self, id):
        return self.client.query(...)                   # returns an SDK object
```

**Before adding an adapter from your collection, verify:** it imports no app code, reads no env vars, names no domain model, and passes the port's contract test (below). If any check fails, fix the adapter — not the target project.
