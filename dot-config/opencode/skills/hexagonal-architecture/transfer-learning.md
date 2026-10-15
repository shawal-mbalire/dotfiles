# Transfer Learning (Unsupported Languages)

Language not listed? Use Python as the reference and map to your language's idioms. The architecture is language-agnostic — only the syntax changes.

## Concept Mapping

| Python | Go | Java | C# | Kotlin | Swift | PHP |
|--------|-----|------|-----|--------|-------|-----|
| `class` | `struct` | `class` | `class` | `class` | `struct/class` | `class` |
| `Protocol` | `interface` | `interface` | `interface` | `interface` | `protocol` | `interface` |
| `ABC` | `interface` | `abstract class` | `abstract class` | `abstract class` | `protocol` | `abstract class` |
| `@dataclass(frozen=True)` | `struct` | `record` | `record` | `data class` | `struct` | readonly class |
| `typing.Protocol` | `interface` | `interface` | `interface` | `interface` | `protocol` | `interface` |
| `__init__` | constructor | constructor | constructor | constructor | `init` | `__construct` |
| `Result[T]` | `(T, error)` | `sealed interface Result<T>` | `abstract record Result<T>` | `sealed interface Result<out T>` | `Result<T, AppError>` | `Success\|Failure` classes |
| `return Failure(e)` (expected) | `return nil, err` | `return new Failure<>(e)` | `return new Failure<T>(e)` | `return Failure(e)` | `return .failure(e)` | `return new Failure($e)` |
| `isinstance(r, Failure)` | `if err != nil` | `r instanceof Failure<T> f` | `r is Failure<T> f` | `is Failure ->` | `case .failure(let e)` | `$r instanceof Failure` |
| `raise` (defect only) | `panic` | `throw` | `throw` | `throw` | `fatalError` | `throw` |
| `pytest` | `testing` | `JUnit` | `xUnit/NUnit` | `JUnit` | `XCTest` | `PHPUnit` |

Naming notes: in Kotlin, define the domain type as `Outcome<T>` (or import it explicitly) — `Result` collides with the auto-imported `kotlin.Result`, which wraps `Throwable` rather than `AppError`. In C#, `Unit` is not in the BCL; declare `public readonly record struct Unit;` in `domain/result`.

## File Structure Mapping

```
Python                          →  Your Language
────────────────────────────────────────────────────
domain/models/document.py       →  domain/models/document.{ext}
domain/ports/repository.py      →  domain/ports/repository.{ext}
domain/workflows/create.py      →  domain/workflows/create.{ext}
domain/errors/empty_error.py    →  domain/errors/empty_error.{ext}
adapters/firestore_adapter.py   →  adapters/firestore_adapter.{ext}
adapters/firestore_mappings.py  →  adapters/firestore_mappings.{ext}
infra/config.py                 →  infra/config.{ext}
main.py                         →  main.{ext}
tests/unit/test_create.py       →  tests/unit/create_test.{ext}
```

## Port Translation Examples

**Python Protocol → Go Interface:**
```go
// domain/ports/repository.go
type DocumentRepository interface {
    Save(doc *Document) error
    FindByID(id string) (*Document, error)
}
```

**Python Protocol → Java Interface:**
```java
// domain/ports/DocumentRepository.java
public interface DocumentRepository {
    Result<Void> save(Document document);
    Result<Optional<Document>> findById(String documentId);   // Optional = not-found, not a failure
}
```

**Python Protocol → C# Interface:**
```csharp
// domain/ports/IDocumentRepository.cs
public interface IDocumentRepository {
    Result<Unit> Save(Document document);
    Result<Document?> FindById(string documentId);
}
```

**Python Protocol → Swift Protocol:**
```swift
// domain/ports/DocumentRepository.swift
protocol DocumentRepository {
    func save(_ document: Document) -> Result<Void, AppError>
    func findById(_ id: String) -> Result<Document?, AppError>
}
```

## Workflow Translation

**Python → Go:**
```go
// domain/workflows/create_document.go
func CreateDocument(content string, repo DocumentRepository, logger Logger) (*Document, error) {
    if strings.TrimSpace(content) == "" {
        return nil, ErrEmptyContent
    }
    doc := &Document{
        ID:      uuid.New().String(),
        Content: content,
    }
    if err := repo.Save(doc); err != nil {
        return nil, fmt.Errorf("save document: %w", err)
    }
    logger.Info("document_created", "document_id", doc.ID)
    return doc, nil
}
```

**Python → Java:**
```java
// domain/workflows/CreateDocument.java
public class CreateDocument {
    private final DocumentRepository repo;
    private final Logger logger;

    public CreateDocument(DocumentRepository repo, Logger logger) {
        this.repo = repo;
        this.logger = logger;
    }

    public Result<Document> execute(String content) {
        if (content == null || content.isBlank()) {
            return new Failure<>(new EmptyContentError());
        }
        Document doc = new Document(UUID.randomUUID().toString(), content);
        if (repo.save(doc) instanceof Failure<Void> failed) {
            return new Failure<>(failed.error());
        }
        logger.info("document_created", Map.of("document_id", doc.getId()));
        return new Success<>(doc);
    }
}
```

## Adapter Translation

**Python → Go:**
```go
// adapters/firestore_adapter.go
type FirestoreDocumentAdapter struct {
    client     *firestore.Client
    collection string
}

func NewFirestoreDocumentAdapter(projectID, collection string) (*FirestoreDocumentAdapter, error) {
    client, err := firestore.NewClient(context.Background(), projectID)
    if err != nil {
        return nil, fmt.Errorf("create firestore client: %w", err)
    }
    return &FirestoreDocumentAdapter{client: client, collection: collection}, nil
}

func (a *FirestoreDocumentAdapter) Save(doc *Document) error {
    _, err := a.client.Collection(a.collection).Doc(doc.ID).Set(context.Background(), map[string]interface{}{
        "content": doc.Content,
        "status":  doc.Status,
    })
    if err != nil {
        return StorageUnavailable("save", err)   // translate to AppError; never leak the SDK error
    }
    return nil
}
```

## Testing Translation

**Python → Go:**
```go
// tests/unit/create_document_test.go
type FakeRepository struct {
    docs map[string]*Document
}

func (f *FakeRepository) Save(doc *Document) error {
    f.docs[doc.ID] = doc
    return nil
}

func TestCreateDocument(t *testing.T) {
    repo := &FakeRepository{docs: make(map[string]*Document)}
    logger := &FakeLogger{}

    doc, err := CreateDocument("Hello", repo, logger)

    assert.NoError(t, err)
    assert.Equal(t, "Hello", doc.Content)
}
```

## Justfile for Any Language

```just
# Copy this justfile and replace tool commands for your language

# Path vars — root is this justfile's directory.
# Multi-project repos: add one var per project below root.
root := justfile_directory()

default:
    @just --list

run:
    # Replace with your language's run command
    # Go: go run .
    # Java: mvn exec:java
    # C#: dotnet run
    # Kotlin: ./gradlew run

test:
    # Go: go test ./...
    # Java: mvn test
    # C#: dotnet test
    # Kotlin: ./gradlew test

lint:
    # Go: golangci-lint run
    # Java: checkstyle
    # C#: dotnet format --verify-no-changes
    # Kotlin: ./gradlew ktlintCheck

format:
    # Go: gofmt -w .
    # Java: google-java-format -i **/*.java
    # C#: dotnet format
    # Kotlin: ./gradlew ktlintFormat

build:
    # Go: go build -o build/app .
    # Java: mvn package
    # C#: dotnet build -c Release
    # Kotlin: ./gradlew build

clean:
    rm -rf build/ target/ bin/ obj/
```
