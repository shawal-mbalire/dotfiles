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

check: lint typecheck test

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
        #[error("Document content cannot be empty")]
        EmptyContent,

        #[error("Document not found: {id}")]
        DocumentNotFound { id: String },

        #[error("Storage error: {0}")]
        Storage(String),
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
            return Err(DomainError::EmptyContent);
        }
        if content.len() > MAX_CONTENT_LENGTH {
            return Err(DomainError::Storage("Content too long".into()));
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
    match result.unwrap_err() {
        DomainError::EmptyContent => {}
        other => panic!("Expected EmptyContent, got {:?}", other),
    }
    assert_eq!(*repo.save_count.borrow(), 0);
}

#[test]
fn test_save_document_whitespace_only_fails() {
    let repo = FakeFileRepository::new();
    let logger = FakeLogger;
    let result = save_document("   ", &repo, &logger);

    assert!(result.is_err());
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
