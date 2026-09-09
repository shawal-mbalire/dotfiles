# C++ — Hexagonal Architecture Guide

C++-specific code examples and patterns for hexagonal architecture. See [SKILL.md](./SKILL.md) for core architecture principles.

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

// domain/workflows/create_document.h
#pragma once
#include <domain/models/document.h>
#include <domain/ports/repository.h>
#include <domain/ports/logger.h>

Document create_document(
    const std::string& content,
    DocumentRepository& repository,
    Logger& logger
);

// domain/workflows/create_document.cpp
#include "create_document.h"
#include <domain/errors/empty_content_error.h>
#include <algorithm>

Document create_document(
    const std::string& content,
    DocumentRepository& repository,
    Logger& logger
) {
    if (content.empty() || std::all_of(content.begin(), content.end(), ::isspace)) {
        throw EmptyContentError();
    }

    auto document = Document::create(content);
    repository.save(document);
    logger.info("Document created with identifier " + document.id);
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
```

### Unit Tests (Google Test)

```cpp
// tests/unit/test_create_document.cpp
#include <gtest/gtest.h>
#include <domain/workflows/create_document.h>
#include <domain/errors/empty_content_error.h>
#include <tests/fixtures/fake_repository.h>
#include <tests/fixtures/fake_logger.h>

class CreateDocumentTest : public ::testing::Test {
protected:
    FakeDocumentRepository repo;
    FakeLogger logger;
};

TEST_F(CreateDocumentTest, CreatesDocumentWithContent) {
    auto result = create_document("Hello World", repo, logger);

    EXPECT_FALSE(result.id.empty());
    EXPECT_EQ(result.content, "Hello World");
    EXPECT_EQ(logger.info_count, 1);
}

TEST_F(CreateDocumentTest, ThrowsOnEmptyContent) {
    EXPECT_THROW(create_document("", repo, logger), EmptyContentError);
}

TEST_F(CreateDocumentTest, ThrowsOnWhitespaceOnly) {
    EXPECT_THROW(create_document("   ", repo, logger), EmptyContentError);
}

TEST_F(CreateDocumentTest, SavesToRepository) {
    create_document("Test content", repo, logger);
    EXPECT_EQ(repo.save_count, 1);
}

TEST_F(CreateDocumentTest, LogsCreation) {
    create_document("Test content", repo, logger);
    EXPECT_EQ(logger.messages.size(), 1);
    EXPECT_EQ(logger.messages[0].first, "info");
}
```

## Justfile

```just
set dotenv-load

CXX := "g++"
CXXFLAGS := "-std=c++20 -Wall -Wextra -pedantic -I."
LDFLAGS := "-lgtest -lgtest_main -lpthread -luuid"

default:
    @just --list

# Build the application
build:
    {{CXX}} {{CXXFLAGS}} -c domain/workflows/create_document.cpp -o build/create_document.o
    {{CXX}} {{CXXFLAGS}} -c adapters/firestore_adapter.cpp -o build/firestore_adapter.o
    {{CXX}} {{CXXFLAGS}} -c infra/config.cpp -o build/config.o
    {{CXX}} {{CXXFLAGS}} -c adapters/console_logger.cpp -o build/console_logger.o
    {{CXX}} {{CXXFLAGS}} main.cpp build/*.o -o build/app {{LDFLAGS}}

# Run the application
run: build
    ./build/app

# Build and run tests
test:
    mkdir -p build
    {{CXX}} {{CXXFLAGS}} -c tests/unit/test_create_document.cpp -o build/test_create_document.o
    {{CXX}} {{CXXFLAGS}} tests/unit/test_create_document.cpp -o build/tests {{LDFLAGS}}
    ./build/tests

# Run tests with verbose output
test-verbose: test
    ./build/tests --gtest_brief=0

# Lint with clang-tidy
lint:
    clang-tidy domain/**/*.cpp adapters/**/*.cpp infra/**/*.cpp main.cpp -- -std=c++20 -I.

# Format with clang-format
format:
    clang-format -i domain/**/*.cpp domain/**/*.h adapters/**/*.cpp adapters/**/*.h infra/**/*.cpp infra/**/*.h tests/**/*.cpp tests/**/*.h main.cpp

# Clean build artifacts
clean:
    rm -rf build/

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
