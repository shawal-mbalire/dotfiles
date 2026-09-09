# Rust — Hexagonal Architecture Guide

Rust-specific code examples and patterns for hexagonal architecture. See [SKILL.md](./SKILL.md) for core architecture principles.

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
    pub struct Document {
        pub id: String,
        pub content: String,
    }
}

pub mod ports {
    pub trait FileRepository {
        fn save(&self, doc: &models::Document) -> Result<(), String>;
        fn find_by_id(&self, id: &str) -> Result<Option<models::Document>, String>;
    }
}

pub mod workflows {
    use super::{models::Document, ports::FileRepository};

    pub fn save_document(content: &str, repo: &dyn FileRepository) -> Result<(), String> {
        if content.is_empty() {
            return Err("Content cannot be empty".to_string());
        }
        let doc = Document {
            id: uuid::Uuid::new_v4().to_string(),
            content: content.to_string(),
        };
        repo.save(&doc)
    }
}

// src/main.rs (Composition Root + Driving Adapter)
use tauri::State;
use std::sync::Arc;

pub struct AppDIState {
    pub file_repository: Arc<dyn domain::ports::FileRepository>,
}

#[tauri::command]
fn save_file_command(
    payload: String,
    state: State<AppDIState>
) -> Result<(), String> {
    domain::workflows::save_document(&payload, state.file_repository.as_ref())
}

#[tauri::command]
fn read_file_command(
    path: String,
    state: State<AppDIState>
) -> Result<String, String> {
    match state.file_repository.find_by_id(&path)? {
        Some(doc) => Ok(doc.content),
        None => Err("File not found".to_string()),
    }
}
```

## Infra

```rust
// src/infra/config.rs
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
use domain::ports::LoggerPort;
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

impl LoggerPort for StructuredLogger {
    fn info(&self, event: &str, data: Option<HashMap<String, String>>) {
        let mut log = HashMap::new();
        log.insert("level", "info");
        log.insert("service", &self.service_name);
        log.insert("event", &event.to_string());
        if let Some(ref id) = self.request_id {
            log.insert("request_id", id);
        }
        if let Some(data) = data {
            for (k, v) in data { log.insert(&k, &v); }
        }
        println!("{}", serde_json::to_string(&log).unwrap());
    }

    fn error(&self, event: &str, data: Option<HashMap<String, String>>) {
        let mut log = HashMap::new();
        log.insert("level", "error");
        log.insert("service", &self.service_name);
        log.insert("event", &event.to_string());
        if let Some(ref id) = self.request_id {
            log.insert("request_id", id);
        }
        if let Some(data) = data {
            for (k, v) in data { log.insert(&k, &v); }
        }
        eprintln!("{}", serde_json::to_string(&log).unwrap());
    }
}
```

## Testing

```rust
// domain/tests/save_document_test.rs
use domain::models::Document;
use domain::ports::FileRepository;
use domain::workflows::save_document;
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
    fn save(&self, doc: &Document) -> Result<(), String> {
        self.storage.borrow_mut().insert(doc.id.clone(), doc.clone());
        *self.save_count.borrow_mut() += 1;
        Ok(())
    }

    fn find_by_id(&self, id: &str) -> Result<Option<Document>, String> {
        Ok(self.storage.borrow().get(id).cloned())
    }
}

#[test]
fn test_save_document_success() {
    let repo = FakeFileRepository::new();
    let result = save_document("Hello World", &repo);

    assert!(result.is_ok());
    assert_eq!(repo.storage.borrow().len(), 1);
    assert_eq!(*repo.save_count.borrow(), 1);
}

#[test]
fn test_save_document_empty_content_fails() {
    let repo = FakeFileRepository::new();
    let result = save_document("", &repo);

    assert!(result.is_err());
    assert!(result.unwrap_err().contains("empty"));
    assert_eq!(*repo.save_count.borrow(), 0);
}
```
