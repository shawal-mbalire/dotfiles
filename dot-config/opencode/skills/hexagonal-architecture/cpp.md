# C++ — Hexagonal Architecture Guide

C++-specific setup, tooling, code examples, and testing patterns for hexagonal architecture. See [SKILL.md](./SKILL.md) for core architecture principles.

## Project Structure

```
project/
├── domain/
│   ├── models/
│   │   ├── document.h
│   │   └── document.cpp
│   ├── constants.h
│   ├── errors/
│   │   ├── domain_error.h
│   │   └── empty_content_error.h
│   ├── ports/
│   │   ├── repository.h
│   │   └── logger.h
│   └── workflows/
│       ├── create_document.h
│       └── create_document.cpp
├── infra/
│   ├── config.h
│   └── config.cpp
├── adapters/
│   ├── firestore_adapter.h
│   ├── firestore_adapter.cpp
│   ├── console_logger.h
│   └── console_logger.cpp
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── main.cpp
├── CMakeLists.txt
└── vcpkg.json
```

## Code Example (Document Management)

```cpp
// domain/models/document.h
#pragma once
#include <string>
#include <uuid/uuid.h>

enum class DocumentStatus {
    DRAFT,
    PUBLISHED,
    ARCHIVED
};

struct Document {
    std::string id;
    std::string content;
    DocumentStatus status = DocumentStatus::DRAFT;

    static Document create(const std::string& content) {
        uuid_t uuid;
        uuid_generate(uuid);
        char uuid_str[37];
        uuid_unparse_lower(uuid, uuid_str);
        return Document{uuid_str, content, DocumentStatus::DRAFT};
    }
};

// domain/dto/document_dto.h
// DTOs live OUTSIDE the domain — adapters create them, domain never sees them
#pragma once
#include <string>

struct DocumentDto {
    std::string id;
    std::string content;
    std::string status;  // String, not enum — wire format
};

struct CreateDocumentRequest {
    std::string content;
};

// domain/errors/domain_error.h
#pragma once
#include <stdexcept>
#include <string>

class DomainError : public std::runtime_error {
public:
    explicit DomainError(const std::string& msg) : std::runtime_error(msg) {}
};

// domain/errors/empty_content_error.h
#pragma once
#include "domain_error.h"

class EmptyContentError : public DomainError {
public:
    EmptyContentError() : DomainError("Document content cannot be empty") {}
};

// domain/ports/repository.h
#pragma once
#include <optional>
#include <domain/models/document.h>

class DocumentRepository {
public:
    virtual ~DocumentRepository() = default;
    virtual void save(const Document& document) = 0;
    virtual std::optional<Document> find_by_id(const std::string& document_id) = 0;
};

// domain/ports/logger.h
#pragma once
#include <string>

class Logger {
public:
    virtual ~Logger() = default;
    virtual void info(const std::string& message) = 0;
    virtual void error(const std::string& message) = 0;
};

// domain/ports/time_port.h
#pragma once
#include <cstdint>

class TimePort {
public:
    virtual ~TimePort() = default;
    virtual uint64_t now_ms() = 0;
    virtual uint64_t elapsed_ms(uint64_t start_ms) = 0;
};

enum class ExitReason {
    Normal,
    UserExit,
    Crash,
    Timeout,
    Shutdown
};

class LifetimePort {
public:
    virtual ~LifetimePort() = default;
    virtual void register_cleanup(std::function<void()> handler) = 0;
    virtual void on_exit(std::function<void(ExitReason)> handler) = 0;
    virtual ExitReason get_exit_reason() = 0;
    virtual bool is_shutting_down() = 0;
};

// domain/workflows/create_document.h
#pragma once
#include <domain/models/document.h>
#include <domain/ports/repository.h>
#include <domain/ports/logger.h>
#include <domain/ports/time_port.h>

Document create_document(
    const std::string& content,
    DocumentRepository& repository,
    Logger& logger,
    TimePort& time
);

// domain/workflows/create_document.cpp
#include "create_document.h"
#include <domain/errors/empty_content_error.h>
#include <algorithm>

Document create_document(
    const std::string& content,
    DocumentRepository& repository,
    Logger& logger,
    TimePort& time
) {
    auto start = time.now_ms();
    if (content.empty() || std::all_of(content.begin(), content.end(), ::isspace)) {
        throw EmptyContentError();
    }

    auto document = Document::create(content);
    repository.save(document);
    auto elapsed = time.elapsed_ms(start);
    logger.info("Document created with identifier " + document.id + " in " + std::to_string(elapsed) + "ms");
    return document;
}

// infra/config.h
#pragma once
#include <string>

struct FirestoreConfig {
    std::string project_id;
    std::string collection_name = "documents";

    static FirestoreConfig from_environment();
};

struct LoggingConfig {
    std::string log_level = "INFO";

    static LoggingConfig from_environment();
};

// infra/config.cpp
#include "config.h"
#include <cstdlib>

FirestoreConfig FirestoreConfig::from_environment() {
    FirestoreConfig config;
    const char* project_id = std::getenv("GCP_PROJECT_ID");
    config.project_id = project_id ? project_id : "";
    const char* collection = std::getenv("FIRESTORE_COLLECTION");
    config.collection_name = collection ? collection : "documents";
    return config;
}

LoggingConfig LoggingConfig::from_environment() {
    LoggingConfig config;
    const char* level = std::getenv("LOG_LEVEL");
    config.log_level = level ? level : "INFO";
    return config;
}

// adapters/console_logger.h
#pragma once
#include <domain/ports/logger.h>
#include <iostream>

class ConsoleLogger : public Logger {
public:
    void info(const std::string& message) override {
        std::cout << "[INFO] " << message << std::endl;
    }

    void error(const std::string& message) override {
        std::cerr << "[ERROR] " << message << std::endl;
    }
};

// adapters/firestore_mappings.h (Pure helpers — no I/O, trivial to test)
#pragma once
#include <domain/models/document.h>
#include <string>
#include <map>

struct FirestoreDoc {
    std::string content;
    std::string status;
};

inline FirestoreDoc document_to_firestore(const Document& doc) {
    return {doc.content, status_to_string(doc.status)};
}

inline Document firestore_to_document(const std::string& id, const FirestoreDoc& doc) {
    return {id, doc.content, string_to_status(doc.status)};
}

// adapters/system_time.h
#pragma once
#include <domain/ports/time_port.h>
#include <chrono>

class SystemTimeAdapter : public TimePort {
public:
    uint64_t now_ms() override {
        auto now = std::chrono::system_clock::now();
        auto duration = now.time_since_epoch();
        return std::chrono::duration_cast<std::chrono::milliseconds>(duration).count();
    }

    uint64_t elapsed_ms(uint64_t start_ms) override {
        return now_ms() - start_ms;
    }
};

// adapters/mock_time.h (for testing)
#pragma once
#include <domain/ports/time_port.h>

class MockTimeAdapter : public TimePort {
public:
    MockTimeAdapter() : current_ms_(1000) {}

    uint64_t now_ms() override { return current_ms_; }
    uint64_t elapsed_ms(uint64_t start_ms) override { return current_ms_ - start_ms; }
    void advance_ms(uint64_t ms) { current_ms_ += ms; }

private:
    uint64_t current_ms_;
};

// adapters/signal_lifetime.h
#pragma once
#include <domain/ports/lifetime_port.h>
#include <vector>
#include <functional>
#include <csignal>

class SignalLifetimeAdapter : public LifetimePort {
public:
    void register_cleanup(std::function<void()> handler) override {
        cleanup_handlers_.push_back(std::move(handler));
    }

    void on_exit(std::function<void(ExitReason)> handler) override {
        exit_handlers_.push_back(std::move(handler));
    }

    ExitReason get_exit_reason() override { return exit_reason_; }
    bool is_shutting_down() override { return shutting_down_; }

    void install() {
        std::signal(SIGTERM, signal_handler);
        std::signal(SIGINT, signal_handler);
    }

    static void signal_handler(int signum) {
        auto& self = instance();
        self.shutting_down_ = true;
        self.exit_reason_ = (signum == SIGTERM) ? ExitReason::Shutdown : ExitReason::UserExit;
        for (auto& h : self.exit_handlers_) h(self.exit_reason_);
        for (auto& h : self.cleanup_handlers_) h();
    }

    static SignalLifetimeAdapter& instance() {
        static SignalLifetimeAdapter inst;
        return inst;
    }

private:
    std::vector<std::function<void()>> cleanup_handlers_;
    std::vector<std::function<void(ExitReason)>> exit_handlers_;
    ExitReason exit_reason_ = ExitReason::Normal;
    bool shutting_down_ = false;
};

// adapters/mock_lifetime.h (for testing)
#pragma once
#include <domain/ports/lifetime_port.h>
#include <vector>
#include <functional>

class MockLifetimeAdapter : public LifetimePort {
public:
    void register_cleanup(std::function<void()> handler) override {
        cleanup_handlers_.push_back(std::move(handler));
    }

    void on_exit(std::function<void(ExitReason)> handler) override {
        exit_handlers_.push_back(std::move(handler));
    }

    ExitReason get_exit_reason() override { return exit_reason_; }
    bool is_shutting_down() override { return shutting_down_; }

    void trigger_exit(ExitReason reason) {
        shutting_down_ = true;
        exit_reason_ = reason;
        for (auto& h : exit_handlers_) h(reason);
        for (auto& h : cleanup_handlers_) { h(); cleanup_count++; }
    }

    int cleanup_count = 0;

private:
    std::vector<std::function<void()>> cleanup_handlers_;
    std::vector<std::function<void(ExitReason)>> exit_handlers_;
    ExitReason exit_reason_ = ExitReason::Normal;
    bool shutting_down_ = false;
};

// adapters/firestore_adapter.h
#pragma once
#include <domain/ports/repository.h>
#include <firestore.h>

class FirestoreDocumentAdapter : public DocumentRepository {
public:
    FirestoreDocumentAdapter(const std::string& project_id, const std::string& collection_name);

    void save(const Document& document) override;
    std::optional<Document> find_by_id(const std::string& document_id) override;

private:
    FirestoreClient client_;
    std::string collection_name_;
};

// adapters/firestore_adapter.cpp
#include "firestore_adapter.h"
#include <domain/models/document.h>

FirestoreDocumentAdapter::FirestoreDocumentAdapter(
    const std::string& project_id,
    const std::string& collection_name
) : client_(project_id), collection_name_(collection_name) {}

void FirestoreDocumentAdapter::save(const Document& document) {
    auto doc = client_.collection(collection_name_).document(document.id);
    doc.set({
        {"content", document.content},
        {"status", status_to_string(document.status)}
    });
}

std::optional<Document> FirestoreDocumentAdapter::find_by_id(const std::string& document_id) {
    auto doc = client_.collection(collection_name_).document(document_id).get();
    if (doc.exists()) {
        auto data = doc.data();
        return Document{
            document_id,
            data["content"].string(),
            string_to_status(data["status"].string())
        };
    }
    return std::nullopt;
}

// main.cpp (Composition Root)
#include <infra/config.h>
#include <adapters/firestore_adapter.h>
#include <adapters/console_logger.h>
#include <domain/workflows/create_document.h>

int main() {
    auto firestore_config = FirestoreConfig::from_environment();
    FirestoreDocumentAdapter repository(firestore_config.project_id, firestore_config.collection_name);
    ConsoleLogger logger;

    auto document = create_document("Hello World", repository, logger);
    std::cout << "Created: " << document.id << std::endl;

    return 0;
}
```

## Domain Constants Pattern

```cpp
// domain/constants.h
#pragma once
#include <cstddef>
#include <cstdint>

// Static constants: fixed business knowledge, never change per deployment
constexpr size_t MAX_CONTENT_LENGTH = 10000;
constexpr double DEGREES_TO_RADIANS = 0.017453292519943295;
constexpr double MAX_LATITUDE = 90.0;
constexpr double MAX_LONGITUDE = 180.0;

// Configurable constants: injected from infra/config
struct DomainConstants {
    int max_retry_count;
    int request_timeout_ms;
    int max_content_length;
};

// domain/workflows/create_document.cpp (using constants)
#include "create_document.h"
#include <domain/constants.h>

Document create_document(
    const std::string& content,
    DocumentRepository& repository,
    Logger& logger
) {
    if (content.empty() || std::all_of(content.begin(), content.end(), ::isspace)) {
        throw EmptyContentError();
    }
    if (content.length() > MAX_CONTENT_LENGTH) {
        throw DomainError("Content exceeds maximum length");
    }
    // ...
}

// infra/config.h (loading configurable constants)
#pragma once
#include <domain/constants.h>

struct InfraConfig {
    static DomainConstants load_domain_constants();
};

// infra/config.cpp
#include "config.h"
#include <cstdlib>

DomainConstants InfraConfig::load_domain_constants() {
    DomainConstants constants;
    const char* retry = std::getenv("MAX_RETRY_COUNT");
    constants.max_retry_count = retry ? std::stoi(retry) : 3;
    const char* timeout = std::getenv("REQUEST_TIMEOUT_MS");
    constants.request_timeout_ms = timeout ? std::stoi(timeout) : 30000;
    const char* max_len = std::getenv("MAX_CONTENT_LENGTH");
    constants.max_content_length = max_len ? std::stoi(max_len) : 10000;
    return constants;
}
```

## Lifecycle Hooks

### Signal Handling

```cpp
// main.cpp
#include <csignal>
#include <cstdlib>

bool running = true;

void signal_handler(int signum) {
    running = false;
    // Adapter cleanup happens in destructors (RAII)
}

int main() {
    std::signal(SIGTERM, signal_handler);
    std::signal(SIGINT, signal_handler);

    auto config = FirestoreConfig::from_environment();
    FirestoreDocumentAdapter repo(config.project_id, config.collection_name);
    ConsoleLogger logger;

    while (running) {
        // Process requests
    }

    // repo destructor flushes and closes connections (RAII)
    return 0;
}
```

### RAII Cleanup

```cpp
// adapters/pool_adapter.h
class ConnectionPoolAdapter : public PoolPort {
public:
    ConnectionPoolAdapter(const std::string& connection_string) {
        pool_ = create_pool(connection_string);
    }

    ~ConnectionPoolAdapter() {
        // Called automatically — flush pending, close connections
        if (pool_) {
            pool_->flush();
            pool_->close();
        }
    }

private:
    std::unique_ptr<ConnectionPool> pool_;
};
```

## Hard-Fail Patterns

```cpp
// BAD: soft fail — returns empty, hides error
std::optional<Document> result = find_document(id);
if (!result) return std::nullopt;  // What went wrong?

// GOOD: hard fail — throws with context
Document result = find_document(id);  // Throws DocumentNotFound
// Catch at the boundary, log with context

// BAD: assert without message
EXPECT_EQ(result.status, DocumentStatus::PUBLISHED);

// GOOD: assert with context
EXPECT_EQ(result.status, DocumentStatus::PUBLISHED)
    << "Expected PUBLISHED, got " << status_to_string(result.status)
    << ". Content: " << result.content;

// BAD: generic exception
throw std::runtime_error("Invalid input");

// GOOD: specific error
throw EmptyContentError("Document content cannot be empty");
```

## Pure Functions in Domain

Domain workflows should be pure functions: same input → same output, no side effects. I/O happens in adapters only.

```cpp
// BAD: impure — depends on external state
double calculate_total(const Cart& cart) {
    double tax_rate = get_tax_rate_from_db(); // Hidden dependency!
    return cart.subtotal * (1.0 + tax_rate);
}

// GOOD: pure — all dependencies injected
double calculate_total(const Cart& cart, double tax_rate) {
    return cart.subtotal * (1.0 + tax_rate);
}

// Testing pure functions is trivial
TEST(CartTest, CalculateTotal) {
    Cart cart{.subtotal = 20.0};
    EXPECT_DOUBLE_EQ(calculate_total(cart, 0.08), 21.6);
}

TEST(CartTest, CalculateTotalZeroTax) {
    Cart cart{.subtotal = 20.0};
    EXPECT_DOUBLE_EQ(calculate_total(cart, 0.0), 20.0);
}
// No mocks, no setup, no database — just input → output
```

## Structured Logging

```cpp
// adapters/structured_logger.h
#pragma once
#include <domain/ports/logger.h>
#include <iostream>
#include <string>
#include <map>

class StructuredLogger : public Logger {
public:
    explicit StructuredLogger(const std::string& service) : service_(service) {}

    void set_request_id(const std::string& id) { request_id_ = id; }

    void info(const std::string& event, const std::map<std::string, std::string>& data = {}) {
        log("info", event, data);
    }

    void error(const std::string& event, const std::map<std::string, std::string>& data = {}) {
        log("error", event, data);
    }

private:
    void log(const std::string& level, const std::string& event, const std::map<std::string, std::string>& data) {
        std::cerr << "{"
            << "\"level\":\"" << level << "\","
            << "\"service\":\"" << service_ << "\","
            << "\"event\":\"" << event << "\","
            << "\"request_id\":\"" << request_id_ << "\"";
        for (const auto& [k, v] : data) {
            std::cerr << ",\"" << k << "\":\"" << v << "\"";
        }
        std::cerr << "}" << std::endl;
    }

    std::string service_;
    std::string request_id_;
};
```

## Testing

### Fake Implementations

```cpp
// tests/fixtures/fake_repository.h
#pragma once
#include <domain/ports/repository.h>
#include <unordered_map>

class FakeDocumentRepository : public DocumentRepository {
public:
    void save(const Document& document) override {
        storage_[document.id] = document;
        save_count++;
    }

    std::optional<Document> find_by_id(const std::string& document_id) override {
        auto it = storage_.find(document_id);
        if (it != storage_.end()) return it->second;
        return std::nullopt;
    }

    std::unordered_map<std::string, Document> storage_;
    int save_count = 0;
};

// tests/fixtures/fake_logger.h
#pragma once
#include <domain/ports/logger.h>
#include <vector>
#include <utility>

class FakeLogger : public Logger {
public:
    void info(const std::string& message) override {
        messages.emplace_back("info", message);
        info_count++;
    }

    void error(const std::string& message) override {
        messages.emplace_back("error", message);
        error_count++;
    }

    std::vector<std::pair<std::string, std::string>> messages;
    int info_count = 0;
    int error_count = 0;
};

// tests/fixtures/fake_time.h
#pragma once
#include <domain/ports/time_port.h>

class FakeTimeAdapter : public TimePort {
public:
    FakeTimeAdapter() : current_ms_(1000) {}

    uint64_t now_ms() override { return current_ms_; }
    uint64_t elapsed_ms(uint64_t start_ms) override { return current_ms_ - start_ms; }
    void advance_ms(uint64_t ms) { current_ms_ += ms; }

private:
    uint64_t current_ms_;
};
```

### Unit Tests (Google Test)

```cpp
// tests/unit/test_create_document.cpp
#include <gtest/gtest.h>
#include <domain/workflows/create_document.h>
#include <domain/errors/empty_content_error.h>
#include <tests/fixtures/fake_repository.h>
#include <tests/fixtures/fake_logger.h>
#include <tests/fixtures/fake_time.h>

class CreateDocumentTest : public ::testing::Test {
protected:
    FakeDocumentRepository repo;
    FakeLogger logger;
    FakeTimeAdapter time;
};

TEST_F(CreateDocumentTest, CreatesDocumentWithContent) {
    auto result = create_document("Hello World", repo, logger, time);

    EXPECT_FALSE(result.id.empty());
    EXPECT_EQ(result.content, "Hello World");
    EXPECT_EQ(logger.info_count, 1);
}

TEST_F(CreateDocumentTest, ThrowsOnEmptyContent) {
    EXPECT_THROW(create_document("", repo, logger, time), EmptyContentError);
}

TEST_F(CreateDocumentTest, ThrowsOnWhitespaceOnly) {
    EXPECT_THROW(create_document("   ", repo, logger, time), EmptyContentError);
}

TEST_F(CreateDocumentTest, SavesToRepository) {
    create_document("Test content", repo, logger, time);
    EXPECT_EQ(repo.save_count, 1);
}

TEST_F(CreateDocumentTest, LogsCreationWithDuration) {
    time.advance_ms(42);
    create_document("Test content", repo, logger, time);
    EXPECT_EQ(logger.messages.size(), 1);
    EXPECT_EQ(logger.messages[0].first, "info");
    EXPECT_NE(logger.messages[0].second.find("42ms"), std::string::npos);
}
```

### Integration Tests

```cpp
// tests/integration/test_firestore_adapter.cpp
#include <gtest/gtest.h>
#include <adapters/firestore_adapter.h>
#include <domain/models/document.h>

class FirestoreAdapterTest : public ::testing::Test {
protected:
    void SetUp() override {
        adapter = std::make_unique<FirestoreDocumentAdapter>("test-project", "test-documents");
    }

    void TearDown() override {
        // Cleanup test data
    }

    std::unique_ptr<FirestoreDocumentAdapter> adapter;
};

TEST_F(FirestoreAdapterTest, SaveAndRetrieveDocument) {
    Document doc{"test-123", "Integration test content", DocumentStatus::DRAFT};

    adapter->save(doc);
    auto retrieved = adapter->find_by_id("test-123");

    ASSERT_TRUE(retrieved.has_value());
    EXPECT_EQ(retrieved->content, doc.content);
    EXPECT_EQ(retrieved->status, doc.status);
}

TEST_F(FirestoreAdapterTest, FindNonexistentReturnsNullopt) {
    auto result = adapter->find_by_id("nonexistent-id");

    EXPECT_FALSE(result.has_value());
}

TEST_F(FirestoreAdapterTest, SaveOverwritesExistingDocument) {
    Document doc1{"test-123", "Original content", DocumentStatus::DRAFT};
    Document doc2{"test-123", "Updated content", DocumentStatus::PUBLISHED};

    adapter->save(doc1);
    adapter->save(doc2);
    auto retrieved = adapter->find_by_id("test-123");

    ASSERT_TRUE(retrieved.has_value());
    EXPECT_EQ(retrieved->content, "Updated content");
    EXPECT_EQ(retrieved->status, DocumentStatus::PUBLISHED);
}
```

### E2E Tests

```cpp
// tests/e2e/test_document_flow.cpp
#include <gtest/gtest.h>
#include <domain/workflows/create_document.h>
#include <domain/errors/empty_content_error.h>
#include <tests/fixtures/fake_repository.h>
#include <tests/fixtures/fake_logger.h>

class DocumentFlowE2E : public ::testing::Test {
protected:
    FakeDocumentRepository repo;
    FakeLogger logger;
};

TEST_F(DocumentFlowE2E, CreateAndRetrieveDocument) {
    // Create a document
    auto doc = create_document("E2E test content", repo, logger);

    EXPECT_FALSE(doc.id.empty());
    EXPECT_EQ(doc.content, "E2E test content");

    // Verify it was saved to repository
    auto retrieved = repo.find_by_id(doc.id);
    ASSERT_TRUE(retrieved.has_value());
    EXPECT_EQ(retrieved->content, "E2E test content");

    // Verify it was logged
    EXPECT_EQ(logger.info_count, 1);
    EXPECT_NE(logger.messages[0].second.find(doc.id), std::string::npos);
}

TEST_F(DocumentFlowE2E, CreateMultipleDocuments) {
    auto doc1 = create_document("First document", repo, logger);
    auto doc2 = create_document("Second document", repo, logger);
    auto doc3 = create_document("Third document", repo, logger);

    // All have unique IDs
    EXPECT_NE(doc1.id, doc2.id);
    EXPECT_NE(doc2.id, doc3.id);

    // All are retrievable
    EXPECT_TRUE(repo.find_by_id(doc1.id).has_value());
    EXPECT_TRUE(repo.find_by_id(doc2.id).has_value());
    EXPECT_TRUE(repo.find_by_id(doc3.id).has_value());

    // All were logged
    EXPECT_EQ(logger.info_count, 3);
}

TEST_F(DocumentFlowE2E, CreateDocumentWithEmptyContentFails) {
    EXPECT_THROW(create_document("", repo, logger), EmptyContentError);
    EXPECT_EQ(repo.save_count, 0);
    EXPECT_EQ(logger.info_count, 0);
}

TEST_F(DocumentFlowE2E, CreateDocumentWithWhitespaceFails) {
    EXPECT_THROW(create_document("   ", repo, logger), EmptyContentError);
    EXPECT_EQ(repo.save_count, 0);
}
```

## Justfile

```just
set dotenv-load

# Toolchain
CXX := "g++"
CXXFLAGS := "-std=c++20 -Wall -Wextra -pedantic -I."
LDFLAGS := "-lgtest -lgtest_main -lpthread -luuid"

# Directories
BUILD_DIR := "build"
TEST_DIR := "tests/unit"

default:
    @just --list

# Create build directory structure
build-dirs:
    mkdir -p {{BUILD_DIR}}/domain {{BUILD_DIR}}/adapters {{BUILD_DIR}}/infra {{BUILD_DIR}}/{{TEST_DIR}}

# Compile sources in a directory
build-obj dir: build-dirs
    #!/usr/bin/env bash
    for src in {{dir}}/**/*.cpp; do
        [ -f "$src" ] || continue
        obj="{{BUILD_DIR}}/${src}.o"
        mkdir -p "$(dirname "$obj")"
        {{CXX}} {{CXXFLAGS}} -c "$src" -o "$obj"
    done

# Build domain objects
build-domain: (build-obj "domain")

# Build adapter objects
build-adapters: (build-obj "adapters")

# Build infra objects
build-infra: (build-obj "infra")

# Build the application
build: build-domain build-adapters build-infra
    {{CXX}} {{CXXFLAGS}} main.cpp {{BUILD_DIR}}/**/*.o -o {{BUILD_DIR}}/app {{LDFLAGS}}

# Run the application
run: build
    ./{{BUILD_DIR}}/app

# Build and run tests
test: build-dirs
    #!/usr/bin/env bash
    for src in {{TEST_DIR}}/**/*.cpp; do
        [ -f "$src" ] || continue
        obj="{{BUILD_DIR}}/${src}.o"
        mkdir -p "$(dirname "$obj")"
        {{CXX}} {{CXXFLAGS}} -c "$src" -o "$obj"
    done
    {{CXX}} {{CXXFLAGS}} {{TEST_DIR}}/**/*.cpp -o {{BUILD_DIR}}/tests {{LDFLAGS}}
    ./{{BUILD_DIR}}/tests

# Run unit tests only
test-unit: build-dirs
    #!/usr/bin/env bash
    for src in tests/unit/**/*.cpp; do
        [ -f "$src" ] || continue
        obj="{{BUILD_DIR}}/${src}.o"
        mkdir -p "$(dirname "$obj")"
        {{CXX}} {{CXXFLAGS}} -c "$src" -o "$obj"
    done
    {{CXX}} {{CXXFLAGS}} tests/unit/**/*.cpp -o {{BUILD_DIR}}/unit_tests {{LDFLAGS}}
    ./{{BUILD_DIR}}/unit_tests

# Run integration tests
test-integration: build-dirs
    #!/usr/bin/env bash
    for src in tests/integration/**/*.cpp; do
        [ -f "$src" ] || continue
        obj="{{BUILD_DIR}}/${src}.o"
        mkdir -p "$(dirname "$obj")"
        {{CXX}} {{CXXFLAGS}} -c "$src" -o "$obj"
    done
    {{CXX}} {{CXXFLAGS}} tests/integration/**/*.cpp -o {{BUILD_DIR}}/integration_tests {{LDFLAGS}}
    ./{{BUILD_DIR}}/integration_tests

# Run e2e tests
test-e2e: build-dirs
    #!/usr/bin/env bash
    for src in tests/e2e/**/*.cpp; do
        [ -f "$src" ] || continue
        obj="{{BUILD_DIR}}/${src}.o"
        mkdir -p "$(dirname "$obj")"
        {{CXX}} {{CXXFLAGS}} -c "$src" -o "$obj"
    done
    {{CXX}} {{CXXFLAGS}} tests/e2e/**/*.cpp -o {{BUILD_DIR}}/e2e_tests {{LDFLAGS}}
    ./{{BUILD_DIR}}/e2e_tests

# Run tests with verbose output
test-verbose: test
    ./{{BUILD_DIR}}/tests --gtest_brief=0

# Lint with clang-tidy
lint:
    clang-tidy domain/**/*.cpp adapters/**/*.cpp infra/**/*.cpp main.cpp -- -std=c++20 -I.

# Format with clang-format
format:
    clang-format -i domain/**/*.cpp domain/**/*.h adapters/**/*.cpp adapters/**/*.h infra/**/*.cpp infra/**/*.h tests/**/*.cpp tests/**/*.h main.cpp

# Clean build artifacts
clean:
    rm -rf {{BUILD_DIR}}/

# Watch for changes and rebuild (requires entr)
watch:
    find . -name '*.cpp' -o -name '*.h' | entr -s 'just test'
```

## conanfile.py

```python
from conan import ConanFile

class HexagonalArchitectureConan(ConanFile):
    name = "hexagonal-architecture"
    version = "0.1.0"
    requires = "gtest/1.14.0", "uuid/1.0"
    generators = "CMakeDeps", "CMakeToolchain"
    settings = "os", "compiler", "build_type", "arch"
```
