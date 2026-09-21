# Rust — Hexagonal Architecture Guide

Rust-specific setup, tooling, code examples, and testing patterns for hexagonal architecture. See [SKILL.md](./SKILL.md) for core architecture principles.

## Project Setup

### Initialize with cargo

```bash
cargo new my-project --name my_project
cd my-project
mkdir -p domain/src adapters/src infra/src
mkdir -p tests/unit tests/integration tests/e2e tests/fixtures
```

### Cargo.toml

```toml
[package]
name = "my-project"
version = "0.1.0"
edition = "2021"

[dependencies]
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
thiserror = "2.0"
tokio = { version = "1.0", features = ["full"] }
tracing = "0.1"
tracing-subscriber = "0.3"
uuid = { version = "1.0", features = ["v4"] }

[dev-dependencies]
tokio-test = "0.4"
```

### Workspace Structure

For multi-crate projects:

```toml
# Cargo.toml (workspace root)
[workspace]
members = ["domain", "adapters", "infra"]
resolver = "2"
```

### Justfile

```just
set dotenv-load

default:
    @just --list

run:
    cargo run

test:
    cargo test

test-unit:
    cargo test --lib

test-integration:
    cargo test --test '*'

test-e2e:
    cargo test --test e2e

lint:
    cargo clippy -- -D warnings

format:
    cargo fmt

typecheck:
    cargo check

adapters-check:
    cargo deny check bans   # adapters must not depend on domain internals or read env

errors-check:
    cargo run --bin check_error_codes   # registry: no unknown or duplicate codes

sanitizers:
    RUSTFLAGS="-Z sanitizer=address" cargo test -Zbuild-std --target x86_64-unknown-linux-gnu
    cargo +nightly miri test

test-contract:
    cargo test --test contract

test-fault:
    cargo test fault

verify: lint typecheck adapters-check errors-check test test-contract test-fault

replay id:
    cargo run --bin replay -- {{id}}

check: lint typecheck adapters-check errors-check test

clean:
    cargo clean

watch:
    cargo watch -x test
```

## Code Example (Tauri Desktop App)

Two hexagons talking via IPC:

### Frontend (TypeScript)

```typescript
// domain/ports/FileStoragePort.ts
export interface FileStoragePort {
  saveFile(content: string): Promise<void>;
  readFile(path: string): Promise<string>;
}

// adapters/TauriFileStorageAdapter.ts (Driven Adapter)
import { invoke } from "@tauri-apps/api/core";
import { FileStoragePort } from "../domain/ports/FileStoragePort";

export class TauriFileStorageAdapter implements FileStoragePort {
  async saveFile(content: string): Promise<void> {
    await invoke("save_file_command", { payload: content });
  }

  async readFile(path: string): Promise<string> {
    return await invoke("read_file_command", { path });
  }
}
```

### Backend (Rust)

```rust
// domain/src/lib.rs (Pure Rust Domain)
pub mod models {
    #[derive(Debug, Clone, PartialEq)]
    pub struct Document {
        pub id: String,
        pub content: String,
    }
}

pub mod errors {
    use thiserror::Error;

    #[derive(Error, Debug)]
    pub enum DomainError {
        #[error("[{code}] {message}")]
        Diagnostic {
            code: &'static str,
            message: String,
            context: BTreeMap<String, String>,
            #[source]
            cause: Option<Box<dyn std::error::Error + Send + Sync>>,
            origin: String,
            correlation_id: String,
            retryable: bool,
            remediation: String,
        },
    }
}

pub mod ports {
    use crate::domain::models::Document;
    use crate::domain::errors::DomainError;

    pub trait FileRepository: Send + Sync {
        fn save(&self, doc: &Document) -> Result<(), DomainError>;
        fn find_by_id(&self, id: &str) -> Result<Option<Document>, DomainError>;
    }

    pub trait Logger: Send + Sync {
        fn info(&self, message: &str);
        fn error(&self, message: &str);
    }

    pub trait TimePort: Send + Sync {
        fn now_ms(&self) -> u64;
        fn elapsed_ms(&self, start_ms: u64) -> u64;
        fn sleep_ms(&self, ms: u64) {
            std::thread::sleep(std::time::Duration::from_millis(ms));
        }
    }

    pub enum ExitReason {
        Normal,
        UserExit,
        Crash,
        Timeout,
        Shutdown,
    }

    pub trait LifetimePort: Send + Sync {
        fn register_cleanup(&self, handler: Box<dyn FnOnce() + Send>);
        fn on_exit(&self, handler: Box<dyn FnOnce(&ExitReason) + Send>);
        fn get_exit_reason(&self) -> ExitReason;
        fn is_shutting_down(&self) -> bool;
    }
}

pub mod constants {
    // Static constants: fixed business knowledge
    pub const MAX_CONTENT_LENGTH: usize = 10000;
    pub const EMPTY_CONTENT_SENTINEL: &str = "";

    // Configurable constants: injected from infra
    pub struct DomainConstants {
        pub max_retry_count: u32,
        pub request_timeout_ms: u64,
    }
}

pub mod workflows {
    use super::{models::Document, ports::FileRepository, ports::Logger, ports::TimePort, errors::DomainError, constants::MAX_CONTENT_LENGTH};

    pub fn save_document(
        content: &str,
        repo: &dyn FileRepository,
        logger: &dyn Logger,
        time: &dyn TimePort,
    ) -> Result<Document, DomainError> {
        let start = time.now_ms();
        if content.trim().is_empty() {
            return Err(DomainError::empty_content());
        }
        if content.len() > MAX_CONTENT_LENGTH {
            return Err(DomainError::Diagnostic {
                code: "DOC-003",
                message: "Content exceeds maximum length".into(),
                context: [("max_length".to_string(), MAX_CONTENT_LENGTH.to_string())]
                    .into_iter()
                    .collect(),
                cause: None,
                origin: String::new(),
                correlation_id: String::new(),
                retryable: false,
                remediation: "Reduce content length".into(),
            });
        }

        let doc = Document {
            id: uuid::Uuid::new_v4().to_string(),
            content: content.to_string(),
        };
        repo.save(&doc)?;
        let elapsed = time.elapsed_ms(start);
        logger.info(&format!("Document created with identifier {} in {}ms", doc.id, elapsed));
        Ok(doc)
    }
}
```

### Infra

```rust
// infra/src/config.rs
use std::env;

pub struct AppConfig {
    pub storage_path: String,
    pub log_level: String,
}

impl AppConfig {
    pub fn from_environment() -> Self {
        Self {
            storage_path: env::var("STORAGE_PATH").unwrap_or_else(|_| "./data".to_string()),
            log_level: env::var("LOG_LEVEL").unwrap_or_else(|_| "info".to_string()),
        }
    }
}

pub fn load_domain_constants() -> domain::constants::DomainConstants {
    domain::constants::DomainConstants {
        max_retry_count: env::var("MAX_RETRY_COUNT")
            .unwrap_or_else(|_| "3".to_string())
            .parse()
            .unwrap_or(3),
        request_timeout_ms: env::var("REQUEST_TIMEOUT_MS")
            .unwrap_or_else(|_| "30000".to_string())
            .parse()
            .unwrap_or(30000),
    }
}
```

### Composition Root

```rust
// src/main.rs (Composition Root + Driving Adapter)
use tauri::State;
use std::sync::Arc;

pub struct AppDIState {
    pub file_repository: Arc<dyn domain::ports::FileRepository>,
    pub logger: Arc<dyn domain::ports::Logger>,
}

#[tauri::command]
fn save_file_command(
    payload: String,
    state: State<AppDIState>
) -> Result<String, String> {
    let doc = domain::workflows::save_document(
        &payload,
        state.file_repository.as_ref(),
        state.logger.as_ref(),
    ).map_err(|e| e.to_string())?;
    Ok(doc.id)
}

#[tauri::command]
fn read_file_command(
    path: String,
    state: State<AppDIState>
) -> Result<String, String> {
    match state.file_repository.find_by_id(&path) {
        Ok(Some(doc)) => Ok(doc.content),
        Ok(None) => Err("File not found".to_string()),
        Err(e) => Err(e.to_string()),
    }
}

#[tokio::main]
async fn main() {
    let config = infra::config::AppConfig::from_environment();

    // Create adapters
    let repo = Arc::new(adapters::firestore::FirestoreAdapter::new(&config.storage_path));
    let logger = Arc::new(adapters::console::ConsoleLogger::new());

    let state = AppDIState {
        file_repository: repo,
        logger,
    };

    tauri::Builder::default()
        .manage(state)
        .invoke_handler(tauri::generate_handler![save_file_command, read_file_command])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

## Domain Constants Pattern

```rust
// domain/src/constants.rs

// Static constants: fixed business knowledge, never change per deployment
pub const MAX_CONTENT_LENGTH: usize = 10000;
pub const EMPTY_CONTENT_SENTINEL: &str = "";
pub const DEGREES_TO_RADIANS: f64 = 0.017453292519943295;

// Configurable constants: injected from infra/config
pub struct DomainConstants {
    pub max_retry_count: u32,
    pub request_timeout_ms: u64,
    pub max_content_length: usize,
}

// domain/src/workflows/save_document.rs (using constants)
use crate::constants::{MAX_CONTENT_LENGTH, EMPTY_CONTENT_SENTINEL};

pub fn save_document(content: &str, repo: &dyn FileRepository) -> Result<Document, DomainError> {
    if content == EMPTY_CONTENT_SENTINEL {
        return Err(DomainError::EmptyContent);
    }
    if content.len() > MAX_CONTENT_LENGTH {
        return Err(DomainError::Storage("Content too long".into()));
    }
    // ...
}

// infra/src/config.rs (loading configurable constants)
pub fn load_domain_constants() -> DomainConstants {
    DomainConstants {
        max_retry_count: std::env::var("MAX_RETRY_COUNT")
            .unwrap_or_else(|_| "3".to_string())
            .parse()
            .unwrap_or(3),
        request_timeout_ms: std::env::var("REQUEST_TIMEOUT_MS")
            .unwrap_or_else(|_| "30000".to_string())
            .parse()
            .unwrap_or(30000),
        max_content_length: std::env::var("MAX_CONTENT_LENGTH")
            .unwrap_or_else(|_| "10000".to_string())
            .parse()
            .unwrap_or(10000),
    }
}
```

## SQL Repository Adapter (Rust)

Persistence goes through a `*Repository` port implemented by a SQL adapter. There is no ORM — the adapter owns its SQL and its row → domain mapping. Target the **generic** `Repository<T>` port with an injected `SqlMapper<T>` so the file copies to any project.

> Verified against `sqlx = 0.8` (`runtime-tokio`, `sqlite`) and `async-trait = 0.1`. Uses SQLite `?` placeholders; for Postgres use `$1..` and `PgPool`/`PgRow`.

```rust
// domain/src/ports/repository.rs (standard, generic, async)
use crate::errors::DomainError;

#[async_trait::async_trait]
pub trait Repository<T>: Send + Sync
where
    T: Send + Sync,
{
    async fn save(&self, entity: &T) -> Result<(), DomainError>;
    async fn find_by_id(&self, id: &str) -> Result<Option<T>, DomainError>;
    async fn find_all(&self) -> Result<Vec<T>, DomainError>;
    async fn delete(&self, id: &str) -> Result<(), DomainError>;
}

// adapters/src/sql/sqlite_repository.rs (PORTABLE — copy to any project, unmodified)
// backend: sqlx (SQLite/Pg); implements: Repository<T>
// deps: sqlx, async-trait; config: injected via SqlMapper
use std::sync::Arc;

use async_trait::async_trait;
use sqlx::query::Query;
use sqlx::sqlite::{Sqlite, SqliteArguments, SqlitePool, SqliteRow};
use sqlx::Row;

use domain::errors::DomainError;
use domain::ports::repository::Repository;

/// Owns the SQL and the *type-safe* binds for exactly one aggregate.
/// This is the injected mapper: the adapter never names a domain type.
pub trait SqlMapper<T>: Send + Sync {
    fn save_sql(&self) -> &str;
    fn select_sql(&self) -> &str;
    fn select_all_sql(&self) -> &str;
    fn delete_sql(&self) -> &str;

    fn bind_save<'q>(
        &'q self,
        query: Query<'q, Sqlite, SqliteArguments<'q>>,
        entity: &'q T,
    ) -> Query<'q, Sqlite, SqliteArguments<'q>>;

    fn from_row(&self, row: &SqliteRow) -> Result<T, sqlx::Error>;
}

pub struct SqliteRepository<T> {
    pool: SqlitePool,                 // injected — never created here
    mapper: Arc<dyn SqlMapper<T>>,    // injected mapper (config + SQL + binds)
}

impl<T> SqliteRepository<T> {
    pub fn new(pool: SqlitePool, mapper: Arc<dyn SqlMapper<T>>) -> Self {
        Self { pool, mapper }
    }
}

#[async_trait]
impl<T: Send + Sync> Repository<T> for SqliteRepository<T> {
    async fn save(&self, entity: &T) -> Result<(), DomainError> {
        let query = self
            .mapper
            .bind_save(sqlx::query(self.mapper.save_sql()), entity);
        query
            .execute(&self.pool)
            .await
            .map(|_| ()) // parameterized only
            .map_err(|e| DomainError::storage_unavailable(
                e, "adapter.sqlite_repository.save", ""  // correlation_id set by caller
            ))?
    }

    async fn find_by_id(&self, id: &str) -> Result<Option<T>, DomainError> {
        let row = sqlx::query(self.mapper.select_sql())
            .bind(id)
            .fetch_optional(&self.pool)
            .await
            .map_err(|e| DomainError::storage_unavailable(
                e, "adapter.sqlite_repository.find_by_id", ""
            ))?;
        row.as_ref()
            .map(|r| self.mapper.from_row(r))
            .transpose()
            .map_err(|e| DomainError::storage_unavailable(
                e, "adapter.sqlite_repository.from_row", ""
            ))
    }

    async fn find_all(&self) -> Result<Vec<T>, DomainError> {
        let rows = sqlx::query(self.mapper.select_all_sql())
            .fetch_all(&self.pool)
            .await
            .map_err(|e| DomainError::storage_unavailable(
                e, "adapter.sqlite_repository.find_all", ""
            ))?;
        rows.iter()
            .map(|r| self.mapper.from_row(r))
            .collect::<Result<Vec<_>, _>>()
            .map_err(|e| DomainError::storage_unavailable(
                e, "adapter.sqlite_repository.from_row", ""
            ))
    }

    async fn delete(&self, id: &str) -> Result<(), DomainError> {
        sqlx::query(self.mapper.delete_sql())
            .bind(id)
            .execute(&self.pool)
            .await
            .map(|_| ())
            .map_err(|e| DomainError::storage_unavailable(
                e, "adapter.sqlite_repository.delete", ""
            ))
    }
}
```

Only the composition root binds the adapter to `Document` — the mapper is the single place that names a domain type:

```rust
// composition root — bind the aggregate here, not inside the adapter
use std::sync::Arc;
use sqlx::query::Query;
use sqlx::sqlite::{Sqlite, SqliteArguments, SqlitePool, SqliteRow};
use sqlx::Row;

pub struct DocumentMapper;

impl SqlMapper<Document> for DocumentMapper {
    fn save_sql(&self) -> &str {
        "INSERT INTO documents (id, content, status) VALUES (?, ?, ?) \
         ON CONFLICT(id) DO UPDATE SET content = excluded.content, status = excluded.status"
    }
    fn select_sql(&self) -> &str {
        "SELECT id, content, status FROM documents WHERE id = ?"
    }
    fn select_all_sql(&self) -> &str {
        "SELECT id, content, status FROM documents"
    }
    fn delete_sql(&self) -> &str {
        "DELETE FROM documents WHERE id = ?"
    }

    fn bind_save<'q>(
        &'q self,
        query: Query<'q, Sqlite, SqliteArguments<'q>>,
        entity: &'q Document,
    ) -> Query<'q, Sqlite, SqliteArguments<'q>> {
        query
            .bind(entity.id.as_str())
            .bind(entity.content.as_str())
            .bind(entity.status.as_str())
    }

    fn from_row(&self, row: &SqliteRow) -> Result<Document, sqlx::Error> {
        Ok(Document {
            id: row.try_get("id")?,
            content: row.try_get("content")?,
            status: DocumentStatus::from_str(row.try_get("status")?),
        })
    }
}

pub fn make_document_repository(pool: SqlitePool) -> SqliteRepository<Document> {
    SqliteRepository::new(pool, Arc::new(DocumentMapper))
}
```

Register the pool in the composition root and close it via RAII/`LifetimePort`. Migrations are `.sql` files run by a root-level admin entry point:

```rust
// migrate.rs (root)
// Apply adapters/sql/migrations/*.sql in order via sqlx::query(...).execute(&pool).await
fn main() {}
```

## Local-First Backing Services (DuckDB Hub)

Dev defaults to one local DuckDB database for **logs, metrics, and events**, owned by a single hub process. Ports never change; the composition root swaps DuckDB adapters for prod services.

```rust
// domain/src/ports/metrics_port.rs
pub trait MetricsPort: Send + Sync {
    fn counter(&self, name: &str, value: f64, labels: &[(&str, &str)]);
    fn gauge(&self, name: &str, value: f64, labels: &[(&str, &str)]);
    fn timing(&self, name: &str, duration_ms: f64, labels: &[(&str, &str)]);
}

// domain/src/ports/event_bus.rs
use serde_json::Value;

pub trait EventPublisherPort: Send + Sync {
    fn publish(&self, topic: &str, payload: Value);
}

pub trait EventConsumerPort: Send + Sync {
    fn subscribe(&self, topic: &str, consumer: &str, handler: Box<dyn Fn(Value) + Send + Sync>);
}

// infra/src/config.rs (add to existing config)
pub struct DuckDbConfig {
    pub mode: String, // "hub" (multi-process) or "inprocess" (single process)
    pub database_path: String,
    pub socket_path: String,
    pub poll_interval_ms: u64,
    pub batch_size: usize,
}

pub fn duck_db_config_from_env() -> DuckDbConfig {
    DuckDbConfig {
        mode: std::env::var("DUCKDB_MODE").unwrap_or_else(|_| "hub".into()),
        database_path: std::env::var("DUCKDB_PATH").unwrap_or_else(|_| "build/dev.duckdb".into()),
        socket_path: std::env::var("DUCKDB_SOCKET").unwrap_or_else(|_| "build/dev.duckdb.sock".into()),
        poll_interval_ms: std::env::var("DUCKDB_POLL_INTERVAL_MS").ok().and_then(|v| v.parse().ok()).unwrap_or(250),
        batch_size: std::env::var("DUCKDB_BATCH_SIZE").ok().and_then(|v| v.parse().ok()).unwrap_or(100),
    }
}

// adapters/src/duckdb/hub_connection.rs (thin client to the single-writer hub)
use std::io::{BufRead, BufReader, Write};
use std::os::unix::net::UnixStream;
use serde_json::Value;

pub struct HubConnection {
    writer: UnixStream,
    reader: BufReader<UnixStream>,
}

impl HubConnection {
    pub fn connect(socket_path: &str) -> std::io::Result<Self> {
        let stream = UnixStream::connect(socket_path)?;
        let reader = BufReader::new(stream.try_clone()?);
        Ok(Self { writer: stream, reader })
    }

    pub fn request(&mut self, payload: &Value) -> std::io::Result<Value> {
        writeln!(self.writer, "{}", payload)?;
        let mut line = String::new();
        self.reader.read_line(&mut line)?; // persistent reader — never drops buffered bytes
        serde_json::from_str(&line)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))
    }
}

// adapters/src/duckdb/duckdb_logger.rs (buffered — flushed via LifetimePort)
use std::sync::Mutex;
use crate::duckdb::hub_connection::HubConnection;

pub struct DuckDbLogger {
    connection: Mutex<HubConnection>,
    service: String,
    batch_size: usize,
    buffer: Mutex<Vec<serde_json::Value>>,
}

impl DuckDbLogger {
    pub fn new(connection: HubConnection, service: &str, batch_size: usize) -> Self {
        Self {
            connection: Mutex::new(connection),
            service: service.into(),
            batch_size,
            buffer: Mutex::new(Vec::new()),
        }
    }

    pub fn info(&self, message: &str) {
        self.append("INFO", message);
    }

    pub fn error(&self, message: &str) {
        self.append("ERROR", message);
    }

    fn append(&self, level: &str, message: &str) {
        let mut buffer = self.buffer.lock().unwrap();
        buffer.push(serde_json::json!({
            "ts": std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH).unwrap().as_millis() as u64,
            "level": level,
            "service": self.service,
            "message": message,
            "fields": {},
        }));
        if buffer.len() >= self.batch_size {
            drop(buffer);
            self.flush();
        }
    }

    pub fn flush(&self) {
        let mut buffer = self.buffer.lock().unwrap();
        if buffer.is_empty() { return; }
        let rows = std::mem::take(&mut *buffer);
        self.connection.lock().unwrap()
            .request(&serde_json::json!({ "op": "append_logs", "rows": rows }))
            .expect("hub append_logs failed");
    }
}

// adapters/src/duckdb/duckdb_event_bus.rs (publish + durable cursor poll)
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};

use serde_json::Value;

use crate::duckdb::hub_connection::HubConnection;
use domain::ports::event_bus::{EventConsumerPort, EventPublisherPort};

pub struct DuckDbEventBus {
    connection: Mutex<HubConnection>,
    batch_size: usize,
    poll_interval_ms: u64,
    buffer: Mutex<Vec<Value>>,
    shutdown: Arc<AtomicBool>, // set by the composition root / LifetimePort
}

impl DuckDbEventBus {
    pub fn new(connection: HubConnection, batch_size: usize, poll_interval_ms: u64,
               shutdown: Arc<AtomicBool>) -> Self {
        Self {
            connection: Mutex::new(connection),
            batch_size,
            poll_interval_ms,
            buffer: Mutex::new(Vec::new()),
            shutdown,
        }
    }

    pub fn flush(&self) {
        let mut buffer = self.buffer.lock().unwrap();
        if buffer.is_empty() { return; }
        let rows = std::mem::take(&mut *buffer);
        self.connection.lock().unwrap()
            .request(&serde_json::json!({ "op": "append_events", "rows": rows }))
            .expect("hub append_events failed");
    }
}

impl EventPublisherPort for DuckDbEventBus {
    fn publish(&self, topic: &str, payload: Value) {
        let ts = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH).unwrap().as_millis() as u64;
        let mut buffer = self.buffer.lock().unwrap();
        buffer.push(serde_json::json!({ "ts": ts, "topic": topic, "payload": payload }));
        if buffer.len() >= self.batch_size {
            drop(buffer);
            self.flush();
        }
    }
}

impl EventConsumerPort for DuckDbEventBus {
    fn subscribe(&self, topic: &str, consumer: &str, handler: Box<dyn Fn(Value) + Send + Sync>) {
        // Durable cursor lives in the hub; 0 on first run
        let mut cursor = self.connection.lock().unwrap()
            .request(&serde_json::json!({ "op": "load_cursor", "topic": topic, "consumer": consumer }))
            .map(|r| r["last_seq"].as_i64().unwrap_or(0))
            .unwrap_or(0);

        while !self.shutdown.load(Ordering::Relaxed) {
            let response = self.connection.lock().unwrap()
                .request(&serde_json::json!({
                    "op": "poll_events", "topic": topic, "after_seq": cursor
                }))
                .expect("hub poll_events failed");
            let rows = response["rows"].as_array().cloned().unwrap_or_default();
            for row in &rows {
                handler(row["payload"].clone()); // at-least-once: handlers must be idempotent
                cursor = row["seq"].as_i64().unwrap_or(cursor);
            }
            if !rows.is_empty() {
                self.connection.lock().unwrap()
                    .request(&serde_json::json!({
                        "op": "save_cursor", "topic": topic,
                        "consumer": consumer, "last_seq": cursor
                    })).expect("hub save_cursor failed");
            }
            std::thread::sleep(std::time::Duration::from_millis(self.poll_interval_ms));
        }
    }
}
```

The hub itself (`adapters/duckdb/hub.rs`) is a small single-writer process: it owns the one `duckdb::Connection`, applies `schema.sql`, and serves newline-delimited JSON over a Unix socket (`append_logs`, `append_metrics`, `append_events`, `poll_events`, `load_cursor`, `save_cursor`, `query`). Register every adapter `flush()` with the `LifetimePort` (see the RAII `Drop` and signal sections below) so buffered writes are never lost. Only the hub writes; `adapters/duckdb/insights.rs` sends `query` requests through the hub rather than opening the file.

## Lifecycle Hooks

### Drop Trait (RAII Cleanup)

```rust
// adapters/firestore_adapter.rs
pub struct FirestoreAdapter {
    client: FirestoreClient,
}

impl FirestoreAdapter {
    pub fn new(project_id: &str) -> Self {
        Self {
            client: FirestoreClient::new(project_id),
        }
    }
}

impl Drop for FirestoreAdapter {
    fn drop(&mut self) {
        // Called automatically when adapter is destroyed
        // Flush pending writes, close connections
        println!("Flushing Firestore adapter...");
    }
}
```

### Signal Handling

```rust
// main.rs
use tokio::signal;

#[tokio::main]
async fn main() {
    let repo = FirestoreAdapter::new("my-project");
    let app = build_app(repo);

    // Wait for shutdown signal
    tokio::select! {
        _ = app.run() => {}
        _ = signal::ctrl_c() => {
            println!("Shutting down gracefully...");
            // Adapter Drop impls handle cleanup
        }
    }
}
```

## Hard-Fail Patterns

```rust
// BAD: soft fail — Option hides the error
fn find_document(id: &str) -> Option<Document> { ... }

// GOOD: hard fail — Result with specific error
fn find_document(id: &str) -> Result<Document, DomainError> {
    repo.find_by_id(id)
        .ok_or_else(|| DomainError::DocumentNotFound { id: id.to_string() })?
}

// BAD: unwrap everywhere — panics with no context
let doc = repo.find_by_id(id).unwrap();

// GOOD: expect with context — clear message on panic
let doc = repo.find_by_id(id)
    .expect("Failed to find document after creation");

// BAD: assert without message
assert_eq!(result.status, DocumentStatus::PUBLISHED);

// GOOD: assert_eq! with custom message
assert_eq!(
    result.status, DocumentStatus::PUBLISHED,
    "Expected PUBLISHED, got {:?}. Content: {:?}",
    result.status, result.content
);
```

## Structured Logging

```rust
// adapters/structured_logger.rs
use domain::ports::Logger;
use std::collections::HashMap;

pub struct StructuredLogger {
    service_name: String,
    request_id: Option<String>,
}

impl StructuredLogger {
    pub fn new(service_name: &str) -> Self {
        Self {
            service_name: service_name.to_string(),
            request_id: None,
        }
    }

    pub fn set_request_id(&mut self, id: String) {
        self.request_id = Some(id);
    }
}

impl Logger for StructuredLogger {
    fn info(&self, event: &str) {
        let mut log = HashMap::new();
        log.insert("level", "info");
        log.insert("service", &self.service_name);
        log.insert("event", &event.to_string());
        if let Some(ref id) = self.request_id {
            log.insert("request_id", id);
        }
        println!("{}", serde_json::to_string(&log).unwrap());
    }

    fn error(&self, event: &str) {
        let mut log = HashMap::new();
        log.insert("level", "error");
        log.insert("service", &self.service_name);
        log.insert("event", &event.to_string());
        if let Some(ref id) = self.request_id {
            log.insert("request_id", id);
        }
        eprintln!("{}", serde_json::to_string(&log).unwrap());
    }
}

// adapters/firestore_mappings.rs (Pure helpers — no I/O, trivial to test)
use domain::models::Document;

pub struct FirestoreDoc {
    pub content: String,
    pub status: String,
}

pub fn document_to_firestore(doc: &Document) -> FirestoreDoc {
    FirestoreDoc {
        content: doc.content.clone(),
        status: format!("{:?}", doc.status).to_lowercase(),
    }
}

pub fn firestore_to_document(id: &str, doc: FirestoreDoc) -> Document {
    Document {
        id: id.to_string(),
        content: doc.content,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_document_to_firestore() {
        let doc = Document { id: "123".into(), content: "Hello".into() };
        let firestore = document_to_firestore(&doc);
        assert_eq!(firestore.content, "Hello");
    }

    #[test]
    fn test_firestore_to_document() {
        let firestore = FirestoreDoc { content: "Hello".into(), status: "draft".into() };
        let doc = firestore_to_document("123", firestore);
        assert_eq!(doc.id, "123");
        assert_eq!(doc.content, "Hello");
    }
}

// adapters/system_time.rs
use domain::ports::TimePort;
use std::time::{SystemTime, UNIX_EPOCH};

pub struct SystemTimeAdapter;

impl TimePort for SystemTimeAdapter {
    fn now_ms(&self) -> u64 {
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64
    }

    fn elapsed_ms(&self, start_ms: u64) -> u64 {
        self.now_ms() - start_ms
    }
}

// adapters/mock_time.rs (for testing)
use domain::ports::TimePort;

pub struct MockTimeAdapter {
    current_ms: std::cell::Cell<u64>,
}

impl MockTimeAdapter {
    pub fn new() -> Self {
        Self {
            current_ms: std::cell::Cell::new(1000),
        }
    }

    pub fn advance_ms(&self, ms: u64) {
        self.current_ms.set(self.current_ms.get() + ms);
    }
}

impl TimePort for MockTimeAdapter {
    fn now_ms(&self) -> u64 {
        self.current_ms.get()
    }

    fn elapsed_ms(&self, start_ms: u64) -> u64 {
        self.current_ms.get() - start_ms
    }
}

// adapters/signal_lifetime.rs
use domain::ports::{LifetimePort, ExitReason};
use std::sync::{Arc, Mutex};

pub struct SignalLifetimeAdapter {
    cleanup_handlers: Mutex<Vec<Box<dyn FnOnce() + Send>>>,
    exit_handlers: Mutex<Vec<Box<dyn FnOnce(&ExitReason) + Send>>>,
    exit_reason: Mutex<ExitReason>,
    shutting_down: std::sync::atomic::AtomicBool,
}

impl SignalLifetimeAdapter {
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            cleanup_handlers: Mutex::new(Vec::new()),
            exit_handlers: Mutex::new(Vec::new()),
            exit_reason: Mutex::new(ExitReason::Normal),
            shutting_down: std::sync::atomic::AtomicBool::new(false),
        })
    }
}

impl LifetimePort for SignalLifetimeAdapter {
    fn register_cleanup(&self, handler: Box<dyn FnOnce() + Send>) {
        self.cleanup_handlers.lock().unwrap().push(handler);
    }

    fn on_exit(&self, handler: Box<dyn FnOnce(&ExitReason) + Send>) {
        self.exit_handlers.lock().unwrap().push(handler);
    }

    fn get_exit_reason(&self) -> ExitReason {
        self.exit_reason.lock().unwrap().clone()
    }

    fn is_shutting_down(&self) -> bool {
        self.shutting_down.load(std::sync::atomic::Ordering::SeqCst)
    }
}

// adapters/mock_lifetime.rs (for testing)
use domain::ports::{LifetimePort, ExitReason};

pub struct MockLifetimeAdapter {
    cleanup_handlers: Vec<Box<dyn FnOnce() + Send>>,
    exit_handlers: Vec<Box<dyn FnOnce(&ExitReason) + Send>>,
    exit_reason: ExitReason,
    shutting_down: bool,
    pub cleanup_count: usize,
}

impl MockLifetimeAdapter {
    pub fn new() -> Self {
        Self {
            cleanup_handlers: Vec::new(),
            exit_handlers: Vec::new(),
            exit_reason: ExitReason::Normal,
            shutting_down: false,
            cleanup_count: 0,
        }
    }

    pub fn trigger_exit(&mut self, reason: ExitReason) {
        self.shutting_down = true;
        self.exit_reason = reason.clone();
        for handler in self.exit_handlers.drain(..) {
            handler(&reason);
        }
        for handler in self.cleanup_handlers.drain(..) {
            handler();
            self.cleanup_count += 1;
        }
    }
}

impl LifetimePort for MockLifetimeAdapter {
    fn register_cleanup(&self, handler: Box<dyn FnOnce() + Send>) {
        self.cleanup_handlers.lock().unwrap().push(handler);
    }

    fn on_exit(&self, handler: Box<dyn FnOnce(&ExitReason) + Send>) {
        self.exit_handlers.lock().unwrap().push(handler);
    }

    fn get_exit_reason(&self) -> ExitReason {
        self.exit_reason.clone()
    }

    fn is_shutting_down(&self) -> bool {
        self.shutting_down
    }
}
```

## Pure Functions in Domain

Domain workflows should be pure functions: same input → same output, no side effects. I/O happens in adapters only.

```rust
// BAD: impure — depends on external state
fn calculate_total(cart: &Cart) -> f64 {
    let tax_rate = get_tax_rate_from_db(); // Hidden dependency!
    cart.subtotal * (1.0 + tax_rate)
}

// GOOD: pure — all dependencies injected
fn calculate_total(cart: &Cart, tax_rate: f64) -> f64 {
    cart.subtotal * (1.0 + tax_rate)
}

// Testing pure functions is trivial
#[test]
fn test_calculate_total() {
    let cart = Cart { subtotal: 20.0 };
    assert_eq!(calculate_total(&cart, 0.08), 21.6);
}

#[test]
fn test_calculate_total_zero_tax() {
    let cart = Cart { subtotal: 20.0 };
    assert_eq!(calculate_total(&cart, 0.0), 20.0);
}
// No mocks, no setup, no database — just input → output
```

## Diagnostics & Failure Localization (Rust)

### Uniform Error + Registry

The project's error type carries the `AppError` shape of SKILL.md (code, context, cause, origin, correlation id, retryability):

```rust
// domain/src/errors.rs
use std::collections::BTreeMap;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum DomainError {
    #[error("[{code}] {message}")]
    Diagnostic {
        code: &'static str,          // registry-backed, e.g. "STO-001"
        message: String,
        context: BTreeMap<String, String>,
        #[source]                     // original error — never discarded
        cause: Option<Box<dyn std::error::Error + Send + Sync>>,
        origin: String,               // layer + module.function:line
        correlation_id: String,
        retryable: bool,
        remediation: String,
    },
}

impl DomainError {
    /// Construct a diagnostic error for storage failures.
    /// Use this instead of DomainError::Storage(String).
    pub fn storage_unavailable(
        cause: impl std::error::Error + Send + Sync + 'static,
        origin: impl Into<String>,
        correlation_id: impl Into<String>,
    ) -> Self {
        DomainError::Diagnostic {
            code: "STO-001",
            message: "Storage backend unavailable".into(),
            context: [("adapter".to_string(), "sqlite".to_string())]
                .into_iter()
                .collect(),
            cause: Some(Box::new(cause)),
            origin: origin.into(),
            correlation_id: correlation_id.into(),
            retryable: true,
            remediation: "Retry with backoff; check the database".into(),
        }
    }

    /// Construct a diagnostic error for content validation failures.
    pub fn empty_content() -> Self {
        DomainError::Diagnostic {
            code: "DOC-001",
            message: "Document content cannot be empty".into(),
            context: BTreeMap::new(),
            cause: None,
            origin: String::new(),
            correlation_id: String::new(),
            retryable: false,
            remediation: "Provide non-empty content".into(),
        }
    }

    /// Construct a diagnostic error for not-found failures.
    pub fn not_found(entity: &str, id: &str) -> Self {
        DomainError::Diagnostic {
            code: "DOC-002",
            message: format!("{} not found: {}", entity, id),
            context: [("id".to_string(), id.to_string())]
                .into_iter()
                .collect(),
            cause: None,
            origin: String::new(),
            correlation_id: String::new(),
            retryable: false,
            remediation: format!("Verify the {} id and try again", entity),
        }
    }

    pub fn code(&self) -> &'static str {
        match self {
            DomainError::Diagnostic { code, .. } => code,
        }
    }

    pub fn retryable(&self) -> bool {
        match self {
            DomainError::Diagnostic { retryable, .. } => *retryable,
        }
    }
}
```

```rust
// src/bin/check_error_codes.rs — errors-check: registry has no unknown/duplicate codes
use std::{collections::BTreeSet, fs, path::PathBuf};

fn main() {
    let registry = fs::read_to_string("errors.toml").expect("errors.toml");
    let walk = |dir: &str, found: &mut BTreeSet<String>| {
        for entry in fs::read_dir(dir).unwrap().flatten() {
            let path: PathBuf = entry.path();
            if path.is_dir() {
                walk(path.to_str().unwrap(), found);
            } else if path.extension().is_some_and(|e| e == "rs") {
                let text = fs::read_to_string(&path).unwrap();
                for line in text.lines() {
                    if let Some(rest) = line.split("code:").nth(1) {
                        if let Some(code) = rest.split('"').nth(1) {
                            found.insert(code.to_string());
                        }
                    }
                }
            }
        }
    };
    let mut used = BTreeSet::new();
    walk("src", &mut used);
    let missing: Vec<_> = used.iter().filter(|c| !registry.contains(c.as_str())).collect();
    assert!(missing.is_empty(), "Unregistered error codes: {missing:?}");
    println!("OK: {} codes used, all registered", used.len());
}
```

### Origin, Causality, and Panic Hook

```rust
// adapters/src/sql/sqlite_repository.rs
fn origin_here() -> String {
    let loc = std::panic::Location::caller();
    format!("adapter.{}.{}:{}", loc.file(), loc.line(), loc.column())
}
// on a driver error:
return Err(DomainError::storage_unavailable(e, origin_here(), correlation_id));

// main.rs (root) — capture backtrace + breadcrumbs, flush, exit with a distinct code
std::panic::set_hook(Box::new(|info| {
    eprintln!("panic: {info}");
    eprintln!("backtrace:\n{}", std::backtrace::Backtrace::force_capture());
    eprintln!("breadcrumbs: {:?}", breadcrumbs::snapshot());
    flush_observability();                    // never lose buffered logs/metrics/events
}));
// after the hook runs the process aborts; wrap main in catch_unwind to exit(70) instead
```

### Fault Injection

```rust
#[cfg(test)]
mod fault_tests {
    use super::*;

    struct FailingRepo;
    #[async_trait::async_trait]
    impl domain::ports::repository::Repository<Document> for FailingRepo {
        async fn save(&self, _: &Document) -> Result<(), DomainError> {
            Err(DomainError::storage_unavailable(
                std::io::Error::new(std::io::ErrorKind::ConnectionRefused, "refused"),
                "adapter.sqlite_repository.save:42",
                "req-1",
            ))
        }
        async fn find_by_id(&self, _: &str) -> Result<Option<Document>, DomainError> { Ok(None) }
        async fn find_all(&self) -> Result<Vec<Document>, DomainError> { Ok(vec![]) }
        async fn delete(&self, _: &str) -> Result<(), DomainError> { Ok(()) }
    }

    #[tokio::test]
    async fn surfaces_storage_error_and_preserves_cause() {
        let err = create_document("Hello", &FailingRepo).await.unwrap_err();
        assert_eq!(err.code(), "STO-001");
        assert!(err.retryable());
        assert!(std::error::Error::source(&err).is_some()); // cause preserved
    }
}
```

## Light Justfile & Terminal Output (Rust)

- The justfile is a **light index**: each recipe delegates to a binary (`cargo run --quiet --bin cli -- <task>`). Logic lives in `src/bin/cli.rs` (a driving adapter).
- Colored, structured output via `comfy-table` (tables) + `owo-colors` (respects `NO_COLOR`) + `indicatif` (progress), behind a `PresenterPort`.

```just
doctor:
    cargo run --quiet --bin cli -- doctor
seed:
    cargo run --quiet --bin cli -- seed
```

## Property, Mutation & Formal Verification (Rust)

```rust
// tests/property.rs (proptest)
use proptest::prelude::*;

proptest! {
    #[test]
    fn encode_decode_round_trips(docs in prop::collection::vec(any::<String>(), 0..32)) {
        let round: Vec<_> = docs.iter().map(|d| decode(&encode(d))).collect();
        prop_assert_eq!(round, docs);
    }
}
```

```just
test-property:
    cargo test --test property

mutation:
    cargo mutants --in-place --dir domain/src --fail-on-survived   # cargo-mutants
```

- **Mutation**: `cargo-mutants`; fail when a mutant in `domain/` survives.
- **Formal**: **Kani** bounded-verifies real Rust (`cargo kani`) for panics/overflow/assertions; push invariants into newtypes/enums so invalid states cannot compile.

## Testing

### Shared Fixtures

```rust
// tests/fixtures/mod.rs
pub mod fakes;
pub mod factories;

// tests/fixtures/fakes.rs
use domain::models::Document;
use domain::ports::{FileRepository, Logger, TimePort};
use domain::errors::DomainError;
use std::collections::HashMap;
use std::cell::RefCell;

pub struct FakeFileRepository {
    storage: RefCell<HashMap<String, Document>>,
    save_count: RefCell<u32>,
}

impl FakeFileRepository {
    pub fn new() -> Self {
        Self {
            storage: RefCell::new(HashMap::new()),
            save_count: RefCell::new(0),
        }
    }
}

impl FileRepository for FakeFileRepository {
    fn save(&self, doc: &Document) -> Result<(), DomainError> {
        self.storage.borrow_mut().insert(doc.id.clone(), doc.clone());
        *self.save_count.borrow_mut() += 1;
        Ok(())
    }

    fn find_by_id(&self, id: &str) -> Result<Option<Document>, DomainError> {
        Ok(self.storage.borrow().get(id).cloned())
    }
}

pub struct FakeLogger {
    messages: RefCell<Vec<(String, String)>>,
    info_count: RefCell<u32>,
}

impl FakeLogger {
    pub fn new() -> Self {
        Self {
            messages: RefCell::new(Vec::new()),
            info_count: RefCell::new(0),
        }
    }
}

impl Logger for FakeLogger {
    fn info(&self, message: &str) {
        self.messages.borrow_mut().push(("info".to_string(), message.to_string()));
        *self.info_count.borrow_mut() += 1;
    }

    fn error(&self, message: &str) {
        self.messages.borrow_mut().push(("error".to_string(), message.to_string()));
    }
}

pub struct FakeTime {
    current_ms: Cell<u64>,
}

impl FakeTime {
    pub fn new() -> Self {
        Self {
            current_ms: Cell::new(1000),
        }
    }

    pub fn advance_ms(&self, ms: u64) {
        self.current_ms.set(self.current_ms.get() + ms);
    }
}

impl TimePort for FakeTime {
    fn now_ms(&self) -> u64 {
        self.current_ms.get()
    }

    fn elapsed_ms(&self, start_ms: u64) -> u64 {
        self.current_ms.get() - start_ms
    }
}

// tests/fixtures/factories.rs
use domain::models::Document;

pub fn create_document(id: Option<&str>, content: &str) -> Document {
    Document {
        id: id.unwrap_or(&uuid::Uuid::new_v4().to_string()).to_string(),
        content: content.to_string(),
    }
}

pub fn create_documents(count: usize) -> Vec<Document> {
    (0..count)
        .map(|i| create_document(None, &format!("Document {}", i)))
        .collect()
}
```

### Unit Tests

```rust
// domain/tests/save_document_test.rs
use domain::models::Document;
use domain::ports::FileRepository;
use domain::workflows::save_document;
use domain::errors::DomainError;
use std::collections::HashMap;
use std::cell::RefCell;

struct FakeFileRepository {
    storage: RefCell<HashMap<String, Document>>,
    save_count: RefCell<u32>,
}

impl FakeFileRepository {
    fn new() -> Self {
        Self {
            storage: RefCell::new(HashMap::new()),
            save_count: RefCell::new(0),
        }
    }
}

impl FileRepository for FakeFileRepository {
    fn save(&self, doc: &Document) -> Result<(), DomainError> {
        self.storage.borrow_mut().insert(doc.id.clone(), doc.clone());
        *self.save_count.borrow_mut() += 1;
        Ok(())
    }

    fn find_by_id(&self, id: &str) -> Result<Option<Document>, DomainError> {
        Ok(self.storage.borrow().get(id).cloned())
    }
}

struct FakeLogger;

impl domain::ports::Logger for FakeLogger {
    fn info(&self, _message: &str) {}
    fn error(&self, _message: &str) {}
}

struct FakeTime {
    current_ms: std::cell::Cell<u64>,
}

impl FakeTime {
    fn new() -> Self {
        Self { current_ms: std::cell::Cell::new(1000) }
    }

    fn advance_ms(&self, ms: u64) {
        self.current_ms.set(self.current_ms.get() + ms);
    }
}

impl domain::ports::TimePort for FakeTime {
    fn now_ms(&self) -> u64 { self.current_ms.get() }
    fn elapsed_ms(&self, start_ms: u64) -> u64 { self.current_ms.get() - start_ms }
}

#[test]
fn test_save_document_success() {
    let repo = FakeFileRepository::new();
    let logger = FakeLogger;
    let time = FakeTime::new();
    let result = save_document("Hello World", &repo, &logger, &time);

    assert!(result.is_ok());
    let doc = result.unwrap();
    assert!(!doc.id.is_empty());
    assert_eq!(doc.content, "Hello World");
    assert_eq!(*repo.save_count.borrow(), 1);
}

#[test]
fn test_save_document_empty_content_fails() {
    let repo = FakeFileRepository::new();
    let logger = FakeLogger;
    let time = FakeTime::new();
    let result = save_document("", &repo, &logger, &time);

    assert!(result.is_err());
    let err = result.unwrap_err();
    assert_eq!(err.code(), "DOC-001");
    assert!(!err.retryable());
    assert_eq!(*repo.save_count.borrow(), 0);
}

#[test]
fn test_save_document_whitespace_only_fails() {
    let repo = FakeFileRepository::new();
    let logger = FakeLogger;
    let result = save_document("   ", &repo, &logger);

    assert!(result.is_err());
    assert_eq!(result.unwrap_err().code(), "DOC-001");
}
```

### Integration Tests

```rust
// tests/integration/firestore_adapter_test.rs
use adapters::firestore::FirestoreAdapter;
use domain::models::Document;
use domain::ports::FileRepository;

#[tokio::test]
async fn test_firestore_save_and_retrieve() {
    let adapter = FirestoreAdapter::new("test-project");
    let doc = Document {
        id: "test-123".to_string(),
        content: "Integration test content".to_string(),
    };

    adapter.save(&doc).expect("Failed to save");
    let retrieved = adapter.find_by_id("test-123").expect("Failed to find");

    assert!(retrieved.is_some());
    assert_eq!(retrieved.unwrap().content, doc.content);
}

#[tokio::test]
async fn test_firestore_find_nonexistent_returns_none() {
    let adapter = FirestoreAdapter::new("test-project");
    let result = adapter.find_by_id("nonexistent").expect("Failed to query");

    assert!(result.is_none());
}
```

### E2E Tests

```rust
// tests/e2e/cart_flow_test.rs
use domain::workflows::save_document;
use domain::ports::{FileRepository, Logger};
use domain::errors::DomainError;
use std::collections::HashMap;
use std::cell::RefCell;

struct E2EFileRepository {
    storage: RefCell<HashMap<String, domain::models::Document>>,
}

impl E2EFileRepository {
    fn new() -> Self {
        Self {
            storage: RefCell::new(HashMap::new()),
        }
    }
}

impl FileRepository for E2EFileRepository {
    fn save(&self, doc: &domain::models::Document) -> Result<(), DomainError> {
        self.storage.borrow_mut().insert(doc.id.clone(), doc.clone());
        Ok(())
    }

    fn find_by_id(&self, id: &str) -> Result<Option<domain::models::Document>, DomainError> {
        Ok(self.storage.borrow().get(id).cloned())
    }
}

struct E2ELogger;

impl Logger for E2ELogger {
    fn info(&self, message: &str) { println!("[INFO] {}", message); }
    fn error(&self, message: &str) { eprintln!("[ERROR] {}", message); }
}

#[test]
fn test_full_document_lifecycle() {
    let repo = E2EFileRepository::new();
    let logger = E2ELogger;

    // Create first document
    let doc1 = save_document("First document", &repo, &logger)
        .expect("Failed to create first document");
    assert!(!doc1.id.is_empty());

    // Create second document
    let doc2 = save_document("Second document", &repo, &logger)
        .expect("Failed to create second document");
    assert_ne!(doc1.id, doc2.id);

    // Retrieve both
    let retrieved1 = repo.find_by_id(&doc1.id).unwrap().unwrap();
    let retrieved2 = repo.find_by_id(&doc2.id).unwrap().unwrap();
    assert_eq!(retrieved1.content, "First document");
    assert_eq!(retrieved2.content, "Second document");
}
```
