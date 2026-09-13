# TypeScript — Hexagonal Architecture Guide

TypeScript-specific setup, tooling, code examples, and testing patterns for hexagonal architecture. See [SKILL.md](./SKILL.md) for core architecture principles.

## Project Setup

### Initialize with npm

```bash
mkdir my-project && cd my-project
npm init -y

mkdir -p domain/models domain/ports domain/workflows domain/errors
mkdir -p infra adapters tests/unit tests/integration tests/e2e tests/fixtures
```

### package.json

```json
{
  "name": "my-project",
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "tsx watch main.ts",
    "start": "tsx main.ts",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "test:unit": "vitest run --dir tests/unit",
    "test:integration": "vitest run --dir tests/integration",
    "test:e2e": "vitest run --dir tests/e2e",
    "lint": "eslint .",
    "format": "prettier --write .",
    "typecheck": "tsc --noEmit"
  },
  "devDependencies": {
    "@types/node": "^22.0",
    "eslint": "^9.0",
    "prettier": "^3.0",
    "tsx": "^4.0",
    "typescript": "^5.6",
    "vitest": "^2.0",
    "@vitest/coverage-v8": "^2.0"
  }
}
```

### tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": "dist",
    "rootDir": ".",
    "declaration": true,
    "paths": {
      "@domain/*": ["./domain/*"],
      "@infra/*": ["./infra/*"],
      "@adapters/*": ["./adapters/*"]
    }
  },
  "include": ["domain/**/*", "infra/**/*", "adapters/**/*", "main.ts"],
  "exclude": ["node_modules", "dist", "tests"]
}
```

### vitest.config.ts

```typescript
import { defineConfig } from "vitest/config";
import path from "path";

export default defineConfig({
  resolve: {
    alias: {
      "@domain": path.resolve(__dirname, "domain"),
      "@infra": path.resolve(__dirname, "infra"),
      "@adapters": path.resolve(__dirname, "adapters"),
    },
  },
  test: {
    include: ["tests/**/*.test.ts"],
    environment: "node",
    coverage: {
      provider: "v8",
      include: ["domain/**/*", "infra/**/*", "adapters/**/*"],
    },
  },
});
```

### Justfile

```just
set dotenv-load

default:
    @just --list

run:
    tsx main.ts

test:
    vitest run

test-unit:
    vitest run --dir tests/unit

test-integration:
    vitest run --dir tests/integration

test-e2e:
    vitest run --dir tests/e2e

test-coverage:
    vitest run --coverage

lint:
    eslint .

format:
    prettier --write .

typecheck:
    tsc --noEmit

adapters-check:
    depcruise --validate .dependency-cruiser.cjs   # adapters must not import domain/app or read env

errors-check:
    tsx tools/checkErrorCodes.ts                   # registry: no unknown or duplicate codes

sanitizers:
    node --enable-source-maps --stack-trace-limit=100 vitest run   # TS has no ASan

test-contract:
    vitest run tests/integration -t contract

test-fault:
    vitest run tests/fault

verify: lint typecheck adapters-check errors-check test test-contract test-fault test-e2e

replay id:
    tsx tools/replay.ts {{id}}

check: lint typecheck adapters-check errors-check test

clean:
    rm -rf dist node_modules .vitest

install:
    npm install

update:
    npm update
```

### Platform-Specific Justfiles

**Node.js / Backend:**

```just
# api/justfile
set dotenv-load

run:
    tsx watch main.ts

logs:
    tsx main.ts --verbose

test:
    vitest run

test-watch:
    vitest

lint:
    eslint .

format:
    prettier --write .

typecheck:
    tsc --noEmit
```

**React / Frontend:**

```just
# frontend/justfile
set dotenv-load

run:
    npm run dev

build:
    npm run build

test:
    vitest run

lint:
    eslint .

format:
    prettier --write .

typecheck:
    tsc --noEmit
```

## Code Example (Cart Management)

### Domain

```typescript
// domain/models/Cart.ts
export interface Cart {
  items: CartItem[];
  total: number;
}

export interface CartItem {
  productId: string;
  quantity: number;
  price: number;
}

// domain/errors/CartErrors.ts
export class EmptyCartError extends Error {
  constructor() {
    super("Cart is empty");
    this.name = "EmptyCartError";
  }
}

export class ProductNotFoundError extends Error {
  constructor(productId: string) {
    super(`Product not found: ${productId}`);
    this.name = "ProductNotFoundError";
  }
}

export class InsufficientStockError extends Error {
  constructor(productId: string, requested: number, available: number) {
    super(
      `Insufficient stock for ${productId}: requested ${requested}, available ${available}`
    );
    this.name = "InsufficientStockError";
  }
}

// domain/ports/CartRepository.ts
export interface CartRepository {
  saveCart(cart: Cart): Promise<void>;
  getCart(): Promise<Cart | null>;
}

// domain/ports/Logger.ts
export interface Logger {
  info(message: string, fields?: Record<string, unknown>): void;
  error(message: string, fields?: Record<string, unknown>): void;
}

// domain/ports/TimePort.ts
export interface TimePort {
  nowMs(): number;
  elapsedMs(startMs: number): number;
  sleepMs(ms: number): Promise<void>;
}

// domain/ports/LifetimePort.ts
export type ExitReason = "normal" | "user_exit" | "crash" | "timeout" | "shutdown";

export interface LifetimePort {
  registerCleanup(handler: () => void): void;
  onExit(handler: (reason: ExitReason) => void): void;
  getExitReason(): ExitReason;
  isShuttingDown(): boolean;
}

// domain/ports/StockChecker.ts
export interface StockChecker {
  getAvailableStock(productId: string): Promise<number>;
}

// domain/workflows/AddToCartWorkflow.ts
import { Cart, CartItem } from "../models/Cart";
import { CartRepository } from "../ports/CartRepository";
import { Logger } from "../ports/Logger";
import { StockChecker } from "../ports/StockChecker";
import { TimePort } from "../ports/TimePort";
import { InsufficientStockError } from "../errors/CartErrors";

export class AddToCartWorkflow {
  constructor(
    private cartRepo: CartRepository,
    private stockChecker: StockChecker,
    private logger: Logger,
    private time: TimePort,
  ) {}

  async execute(
    productId: string,
    quantity: number,
    price: number,
  ): Promise<Cart> {
    const start = this.time.nowMs();
    const available = await this.stockChecker.getAvailableStock(productId);
    if (available < quantity) {
      throw new InsufficientStockError(productId, quantity, available);
    }

    const existingCart = (await this.cartRepo.getCart()) || {
      items: [],
      total: 0,
    };
    const existingItem = existingCart.items.find(
      (i) => i.productId === productId,
    );

    if (existingItem) {
      existingItem.quantity += quantity;
    } else {
      existingCart.items.push({ productId, quantity, price });
    }

    existingCart.total = existingCart.items.reduce(
      (sum, item) => sum + item.price * item.quantity,
      0,
    );
    await this.cartRepo.saveCart(existingCart);
    const elapsed = this.time.elapsedMs(start);
    this.logger.info(`Added ${quantity} of product ${productId} to cart in ${elapsed}ms`);
    return existingCart;
  }
}
```

### Domain Constants Pattern

```typescript
// domain/constants.ts

// Static constants: fixed business knowledge, never change per deployment
export const EMPTY_CART_TOTAL = 0;
export const MAX_CART_ITEMS = 50;
export const TAX_RATE = 0.08;

// Configurable constants: injected from infra/config
export interface DomainConstants {
  readonly maxRetryCount: number;
  readonly requestTimeoutMs: number;
  readonly maxContentLength: number;
}

// domain/workflows/AddToCartWorkflow.ts (using constants)
import { EMPTY_CART_TOTAL, MAX_CART_ITEMS } from "../constants";

export class AddToCartWorkflow {
  async execute(productId: string, quantity: number, price: number): Promise<Cart> {
    const cart = (await this.cartRepo.getCart()) || { items: [], total: EMPTY_CART_TOTAL };

    if (cart.items.length >= MAX_CART_ITEMS) {
      throw new Error("Cart is full");
    }
    // ...
  }
}

// infra/config.ts (loading configurable constants)
import type { DomainConstants } from "../domain/constants";

export function loadDomainConstants(): DomainConstants {
  return {
    maxRetryCount: parseInt(process.env.MAX_RETRY_COUNT || "3", 10),
    requestTimeoutMs: parseInt(process.env.REQUEST_TIMEOUT_MS || "30000", 10),
    maxContentLength: parseInt(process.env.MAX_CONTENT_LENGTH || "10000", 10),
  };
}
```

### Infrastructure

```typescript
// infra/config.ts
export const config = {
  storageKey: process.env.APP_STORAGE_KEY || "cart",
  logLevel: process.env.APP_LOG_LEVEL || "info",
  firestoreProjectId: process.env.FIRESTORE_PROJECT_ID || "",
  firestoreCollection: process.env.FIRESTORE_COLLECTION || "carts",
};

// infra/logging.ts
import { Logger } from "../domain/ports/Logger";

export class ConsoleLogger implements Logger {
  info(message: string): void {
    console.log(`[INFO] ${message}`);
  }

  error(message: string): void {
    console.error(`[ERROR] ${message}`);
  }
}

// adapters/SystemTimeAdapter.ts
import { TimePort } from "../domain/ports/TimePort";

export class SystemTimeAdapter implements TimePort {
  nowMs(): number {
    return Date.now();
  }

  elapsedMs(startMs: number): number {
    return this.nowMs() - startMs;
  }

  async sleepMs(ms: number): Promise<void> {
    await new Promise((resolve) => setTimeout(resolve, ms));
  }
}

// adapters/MockTimeAdapter.ts (for testing)
import { TimePort } from "../domain/ports/TimePort";

export class MockTimeAdapter implements TimePort {
  private currentMs = 1000;
  private sleptMs = 0;

  nowMs(): number {
    return this.currentMs;
  }

  elapsedMs(startMs: number): number {
    return this.currentMs - startMs;
  }

  async sleepMs(ms: number): Promise<void> {
    this.sleptMs += ms; // deterministic — no real waiting in tests
  }

  advanceMs(ms: number): void {
    this.currentMs += ms;
  }
}

// adapters/ProcessLifetimeAdapter.ts
import { LifetimePort, ExitReason } from "../domain/ports/LifetimePort";

export class ProcessLifetimeAdapter implements LifetimePort {
  private cleanupHandlers: (() => void)[] = [];
  private exitHandlers: ((reason: ExitReason) => void)[] = [];
  private exitReason: ExitReason = "normal";
  private shuttingDown = false;

  registerCleanup(handler: () => void): void {
    this.cleanupHandlers.push(handler);
  }

  onExit(handler: (reason: ExitReason) => void): void {
    this.exitHandlers.push(handler);
  }

  getExitReason(): ExitReason {
    return this.exitReason;
  }

  isShuttingDown(): boolean {
    return this.shuttingDown;
  }

  install(): void {
    process.on("SIGTERM", () => this.handleSignal("shutdown"));
    process.on("SIGINT", () => this.handleSignal("user_exit"));
    process.on("uncaughtException", () => this.handleSignal("crash"));
  }

  private handleSignal(reason: ExitReason): void {
    this.shuttingDown = true;
    this.exitReason = reason;
    this.exitHandlers.forEach((h) => h(reason));
    this.cleanupHandlers.forEach((h) => h());
  }
}

// adapters/MockLifetimeAdapter.ts (for testing)
import { LifetimePort, ExitReason } from "../domain/ports/LifetimePort";

export class MockLifetimeAdapter implements LifetimePort {
  private cleanupHandlers: (() => void)[] = [];
  private exitHandlers: ((reason: ExitReason) => void)[] = [];
  private exitReason: ExitReason = "normal";
  private shuttingDown = false;
  public cleanupCount = 0;

  registerCleanup(handler: () => void): void {
    this.cleanupHandlers.push(handler);
  }

  onExit(handler: (reason: ExitReason) => void): void {
    this.exitHandlers.push(handler);
  }

  getExitReason(): ExitReason {
    return this.exitReason;
  }

  isShuttingDown(): boolean {
    return this.shuttingDown;
  }

  triggerExit(reason: ExitReason): void {
    this.shuttingDown = true;
    this.exitReason = reason;
    this.exitHandlers.forEach((h) => h(reason));
    this.cleanupHandlers.forEach((h) => { h(); this.cleanupCount++; });
  }
}
```

### Adapters

```typescript
// adapters/cart-mappings.ts (Pure helpers — no I/O, trivial to test)
import { Cart, CartItem } from "../domain/models/Cart";

interface FirestoreCartDoc {
  items: Array<{ productId: string; quantity: number; price: number }>;
  total: number;
}

export function cartToFirestoreDoc(cart: Cart): FirestoreCartDoc {
  return { items: cart.items, total: cart.total };
}

export function firestoreDocToCart(doc: FirestoreCartDoc): Cart {
  return { items: doc.items, total: doc.total };
}

// adapters/LocalStorageCartAdapter.ts (Thin I/O — calls pure helpers)
import { CartRepository } from "../domain/ports/CartRepository";
import { Cart } from "../domain/models/Cart";
import { cartToFirestoreDoc, firestoreDocToCart } from "./cart-mappings";

export class LocalStorageCartAdapter implements CartRepository {
  constructor(private storageKey: string) {}

  async saveCart(cart: Cart): Promise<void> {
    localStorage.setItem(this.storageKey, JSON.stringify(cartToFirestoreDoc(cart)));
  }

  async getCart(): Promise<Cart | null> {
    const data = localStorage.getItem(this.storageKey);
    return data ? firestoreDocToCart(JSON.parse(data)) : null;
  }
}

// tests/unit/cart-mappings.test.ts (Test pure helpers — no mocks needed)
import { describe, it, expect } from "vitest";
import { cartToFirestoreDoc, firestoreDocToCart } from "../../adapters/cart-mappings";

describe("cart mappings", () => {
  it("converts cart to firestore doc", () => {
    const cart = { items: [{ productId: "1", quantity: 2, price: 9.99 }], total: 19.98 };
    const doc = cartToFirestoreDoc(cart);
    expect(doc).toEqual({ items: cart.items, total: 19.98 });
  });

  it("converts firestore doc to cart", () => {
    const doc = { items: [{ productId: "1", quantity: 2, price: 9.99 }], total: 19.98 };
    const cart = firestoreDocToCart(doc);
    expect(cart).toEqual({ items: doc.items, total: 19.98 });
  });
});
// No mocks, no Firestore emulator — just input → output

// adapters/FirestoreCartAdapter.ts (Driven Adapter)
import { CartRepository } from "../domain/ports/CartRepository";
import { Cart } from "../domain/models/Cart";

export class FirestoreCartAdapter implements CartRepository {
  constructor(
    private projectId: string,
    private collectionName: string,
  ) {}

  async saveCart(cart: Cart): Promise<void> {
    // Firestore implementation
    console.log(`Saving cart to Firestore project ${this.projectId}`);
  }

  async getCart(): Promise<Cart | null> {
    // Firestore implementation
    return null;
  }
}

// adapters/HttpStockChecker.ts (Driven Adapter)
import { StockChecker } from "../domain/ports/StockChecker";

export class HttpStockChecker implements StockChecker {
  constructor(private apiUrl: string) {}

  async getAvailableStock(productId: string): Promise<number> {
    const response = await fetch(`${this.apiUrl}/stock/${productId}`);
    const data = await response.json();
    return data.available;
  }
}

// adapters/useCartController.ts (Driving Adapter - React)
import { useState } from "react";
import { AddToCartWorkflow } from "../domain/workflows/AddToCartWorkflow";
import { Cart } from "../domain/models/Cart";

export function useCartController(addToCartWorkflow: AddToCartWorkflow) {
  const [cartState, setCartState] = useState<Cart | null>(null);

  const handleAdd = async (productId: string, price: number) => {
    const updatedCart = await addToCartWorkflow.execute(productId, 1, price);
    setCartState(updatedCart);
  };

  return { cartState, handleAdd };
}

// main.ts (Composition Root)
import { AddToCartWorkflow } from "./domain/workflows/AddToCartWorkflow";
import { FirestoreCartAdapter } from "./adapters/FirestoreCartAdapter";
import { HttpStockChecker } from "./adapters/HttpStockChecker";
import { ConsoleLogger } from "./infra/logging";
import { config } from "./infra/config";

const cartRepo = new FirestoreCartAdapter(
  config.firestoreProjectId,
  config.firestoreCollection,
);
const stockChecker = new HttpStockChecker("http://localhost:3001/api");
const logger = new ConsoleLogger();

const addToCartWorkflow = new AddToCartWorkflow(cartRepo, stockChecker, logger);

// Use the workflow in driving adapters (routes, handlers, UI)
```

### Angular Example

```typescript
// domain/ports/UserRepository.ts
export interface UserRepository {
  getUser(id: string): Promise<User>;
  saveUser(user: User): Promise<void>;
}

// adapters/HttpUserAdapter.ts (Driven Adapter)
import { Injectable } from "@angular/core";
import { HttpClient } from "@angular/common/http";
import { firstValueFrom } from "rxjs";
import { UserRepository } from "../domain/ports/UserRepository";
import { User } from "../domain/models/User";

interface UserDto {
  id: string;
  name: string;
  email: string;
}

function mapDtoToDomain(dto: UserDto): User {
  return { id: dto.id, name: dto.name, email: dto.email };
}

@Injectable()
export class HttpUserAdapter implements UserRepository {
  constructor(
    private http: HttpClient,
    private baseUrl: string,
  ) {}

  async getUser(id: string): Promise<User> {
    const dto = await firstValueFrom(
      this.http.get<UserDto>(`${this.baseUrl}/users/${id}`),
    );
    return mapDtoToDomain(dto);
  }

  async saveUser(user: User): Promise<void> {
    await firstValueFrom(
      this.http.put(`${this.baseUrl}/users/${user.id}`, user),
    );
  }
}

// main.ts (Composition Root - app.config.ts)
import { ApplicationConfig } from "@angular/core";
import { HttpUserAdapter } from "./adapters/HttpUserAdapter";
import { UserRepository } from "./domain/ports/UserRepository";
import { SentryLogger } from "./infra/logging";
import { Logger } from "./domain/ports/Logger";

export const appConfig: ApplicationConfig = {
  providers: [
    { provide: UserRepository, useClass: HttpUserAdapter },
    { provide: Logger, useClass: SentryLogger },
  ],
};
```

## SQL Repository Adapter (TypeScript)

Persistence goes through a `*Repository` port implemented by a SQL adapter. There is no ORM — the adapter owns its SQL and its row → domain mapping. Target the **generic** port with injected mappers so the file copies to any project.

```typescript
// domain/models/Document.ts (pure — no DB imports)
export type DocumentStatus = "draft" | "published";
export interface Document { id: string; content: string; status: DocumentStatus; }

// domain/ports/Repository.ts (standard, generic)
export interface Repository<T, Id = string> {
  save(entity: T): Promise<void>;
  findById(id: Id): Promise<T | null>;
  findAll(): Promise<T[]>;
  delete(id: Id): Promise<void>;
}

// Domain-specific alias — optional
export type DocumentRepository = Repository<Document, string>;

// adapters/sql/PgRepository.ts (PORTABLE — copy to any project, unmodified)
// implements: Repository<T, Id>
// config: SqlConfig; deps: `pg` only
import { Pool } from "pg";

export interface SqlConfig {
  table: string;
  saveSql: string;
  selectSql: string;
  selectAllSql: string;
  deleteSql: string;
}

export class PgRepository<T, Id = string> implements Repository<T, Id> {
  constructor(
    private readonly pool: Pool,                          // injected
    private readonly config: SqlConfig,                  // frozen, no env reads
    private readonly toParams: (entity: T) => unknown[], // pure mapper
    private readonly fromRow: (row: Record<string, unknown>) => T, // pure mapper
  ) {}

  async save(entity: T): Promise<void> {
    try {
      await this.pool.query(this.config.saveSql, this.toParams(entity)); // parameterized
    } catch (e) {
      throw new StorageUnavailableError(String(e));       // translate vendor errors
    }
  }

  async findById(id: Id): Promise<T | null> {
    const { rows } = await this.pool.query(this.config.selectSql, [id]);
    return rows[0] ? this.fromRow(rows[0]) : null;
  }

  async findAll(): Promise<T[]> {
    const { rows } = await this.pool.query(this.config.selectAllSql);
    return rows.map(this.fromRow);
  }

  async delete(id: Id): Promise<void> {
    await this.pool.query(this.config.deleteSql, [id]);
  }
}
```

Only the composition root binds the adapter to an aggregate — the adapter never names `Document`:

```typescript
// main.ts (root) — bind SqlConfig + mappers here
const documentRepo = new PgRepository<Document, string>(
  pool,
  {
    table: "documents",
    saveSql: `INSERT INTO documents (id, content, status) VALUES ($1, $2, $3)
              ON CONFLICT (id) DO UPDATE SET content = EXCLUDED.content, status = EXCLUDED.status`,
    selectSql: "SELECT id, content, status FROM documents WHERE id = $1",
    selectAllSql: "SELECT id, content, status FROM documents",
    deleteSql: "DELETE FROM documents WHERE id = $1",
  },
  (d) => [d.id, d.content, d.status],
  (row) => ({ id: row.id as string, content: row.content as string, status: row.status as DocumentStatus }),
);
```

Register `pool.end` with the `LifetimePort`. Migrations are `.sql` files run by a root-level admin entry point:

```typescript
// migrate.ts (root)
import { readdirSync, readFileSync } from "node:fs";
import { Pool } from "pg";

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
for (const file of readdirSync("adapters/sql/migrations").sort()) {
  await pool.query(readFileSync(`adapters/sql/migrations/${file}`, "utf8"));
}
await pool.end();
```

## Local-First Backing Services (DuckDB Hub)

Dev defaults to one local DuckDB database for **logs, metrics, and events**, owned by a single hub process. Ports never change; the composition root swaps DuckDB adapters for prod services.

```typescript
// domain/ports/Metrics.ts
export interface MetricsPort {
  counter(name: string, value?: number, labels?: Record<string, string>): void;
  gauge(name: string, value: number, labels?: Record<string, string>): void;
  timing(name: string, durationMs: number, labels?: Record<string, string>): void;
}

// domain/ports/EventBus.ts
export interface EventPublisherPort {
  publish(topic: string, payload: unknown): void;
}
export type EventHandler = (payload: unknown) => void;
export interface EventConsumerPort {
  subscribe(topic: string, consumer: string, handler: EventHandler): void;
}

// infra/config.ts
export interface DuckDbConfig {
  mode: "hub" | "inprocess"; // hub = multi-process, inprocess = single process
  databasePath: string;
  socketPath: string;
  pollIntervalMs: number;
  batchSize: number;
}

export function duckDbConfigFromEnv(): DuckDbConfig {
  return {
    mode: (process.env.DUCKDB_MODE as DuckDbConfig["mode"]) ?? "hub",
    databasePath: process.env.DUCKDB_PATH ?? "build/dev.duckdb",
    socketPath: process.env.DUCKDB_SOCKET ?? "build/dev.duckdb.sock",
    pollIntervalMs: Number(process.env.DUCKDB_POLL_INTERVAL_MS ?? 250),
    batchSize: Number(process.env.DUCKDB_BATCH_SIZE ?? 100),
  };
}

// adapters/duckdb/HubConnection.ts (thin client to the single-writer hub)
import net from "node:net";

export class HubConnection {
  private socket?: net.Socket;

  constructor(private readonly socketPath: string) {}

  connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      this.socket = net.createConnection(this.socketPath, () => resolve());
      this.socket.once("error", reject);
    });
  }

  request(payload: unknown): Promise<any> {
    return new Promise((resolve, reject) => {
      if (!this.socket) return reject(new Error("HubConnection used before connect()"));
      const onData = (chunk: Buffer) => {
        this.socket!.off("data", onData);
        resolve(JSON.parse(chunk.toString()));
      };
      this.socket.once("data", onData);
      this.socket.write(JSON.stringify(payload) + "\n");
    });
  }

  close(): void {
    this.socket?.end();
  }
}

// adapters/duckdb/DuckDbLogger.ts (buffered — flushed via LifetimePort)
import { LoggerPort } from "../../domain/ports/Logger";
import { HubConnection } from "./HubConnection";

export class DuckDbLogger implements LoggerPort {
  private buffer: object[] = [];

  constructor(
    private readonly connection: HubConnection,
    private readonly service: string,
    private readonly batchSize = 100,
  ) {}

  info(message: string, requestId?: string, fields: Record<string, unknown> = {}): void {
    this.append("INFO", message, requestId, fields);
  }

  error(message: string, requestId?: string, fields: Record<string, unknown> = {}): void {
    this.append("ERROR", message, requestId, fields);
  }

  private append(level: string, message: string, requestId: string | undefined, fields: object): void {
    this.buffer.push({
      ts: Date.now(), level, service: this.service,
      request_id: requestId, message, fields,
    });
    if (this.buffer.length >= this.batchSize) this.flush();
  }

  flush(): void {
    if (this.buffer.length === 0) return;
    this.connection.request({ op: "append_logs", rows: this.buffer });
    this.buffer = [];
  }
}

// adapters/duckdb/DuckDbEventBus.ts (publish + cursor poll)
import { EventConsumerPort, EventHandler, EventPublisherPort } from "../../domain/ports/EventBus";
import { LifetimePort } from "../../domain/ports/LifetimePort";
import { TimePort } from "../../domain/ports/TimePort";

export class DuckDbEventBus implements EventPublisherPort, EventConsumerPort {
  private buffer: object[] = [];

  constructor(
    private readonly connection: HubConnection,
    private readonly time: TimePort,
    private readonly lifetime: LifetimePort,
    private readonly batchSize = 100,
    private readonly pollIntervalMs = 250,
  ) {}

  publish(topic: string, payload: unknown): void {
    this.buffer.push({ ts: this.time.nowMs(), topic, payload });
    if (this.buffer.length >= this.batchSize) this.flush();
  }

  flush(): void {
    if (this.buffer.length === 0) return;
    this.connection.request({ op: "append_events", rows: this.buffer });
    this.buffer = [];
  }

  async subscribe(topic: string, consumer: string, handler: EventHandler): Promise<void> {
    // Durable cursor lives in the hub; 0 on first run
    let cursor = (await this.connection.request({ op: "load_cursor", topic, consumer })).last_seq;
    while (!this.lifetime.isShuttingDown()) {
      const { rows } = await this.connection.request({ op: "poll_events", topic, after_seq: cursor });
      for (const row of rows) {
        handler(row.payload); // at-least-once: handlers must be idempotent
        cursor = row.seq;
      }
      if (rows.length > 0) {
        await this.connection.request({ op: "save_cursor", topic, consumer, last_seq: cursor });
      }
      await this.time.sleepMs(this.pollIntervalMs);
    }
  }
}

// adapters/duckdb/hub.ts (composition root for the hub — the ONLY writer)
// Sketch: the row <-> domain mappings and INSERTs mirror python.md.
import { DuckDBConnection, DuckDBInstance } from "@duckdb/node-api";
import net from "node:net";
import { readFileSync } from "node:fs";

async function dispatch(connection: DuckDBConnection, request: any): Promise<unknown> {
  switch (request.op) {
    case "append_logs":
    case "append_metrics":
    case "append_events":
      // Map + INSERT rows (see duckdb_mappings in python.md)
      return { ok: true };
    case "poll_events": {
      const reader = await connection.runAndReadAll(
        "SELECT seq, ts, topic, payload FROM events WHERE topic = ? AND seq > ? ORDER BY seq",
        [request.topic, request.after_seq],
      );
      return { ok: true, rows: reader.getRowObjectsJson() };
    }
    case "load_cursor": {
      const reader = await connection.runAndReadAll(
        "SELECT last_seq FROM event_cursors WHERE topic = ? AND consumer = ?",
        [request.topic, request.consumer],
      );
      const rows = reader.getRowObjectsJson();
      return { ok: true, last_seq: rows.length ? rows[0].last_seq : 0 };
    }
    case "save_cursor":
      await connection.run(
        "INSERT INTO event_cursors (topic, consumer, last_seq) VALUES (?, ?, ?) " +
          "ON CONFLICT (topic, consumer) DO UPDATE SET last_seq = excluded.last_seq",
        [request.topic, request.consumer, request.last_seq],
      );
      return { ok: true };
    case "query": {
      // Insights read THROUGH the hub — never open the file directly
      const reader = await connection.runAndReadAll(request.sql, request.params ?? []);
      return { ok: true, rows: reader.getRowObjectsJson() };
    }
    default:
      throw new Error(`Unknown hub op: ${request.op}`);
  }
}

export async function serveHub(socketPath: string, databasePath: string): Promise<void> {
  const instance = await DuckDBInstance.create(databasePath);
  const connection = await instance.connect();
  await connection.run(readFileSync(new URL("./schema.sql", import.meta.url), "utf8"));

  const server = net.createServer((socket) => {
    let buffer = "";
    socket.on("data", async (chunk) => {
      buffer += chunk.toString();
      let index;
      while ((index = buffer.indexOf("\n")) !== -1) {
        const request = JSON.parse(buffer.slice(0, index));
        buffer = buffer.slice(index + 1);
        socket.write(JSON.stringify(await dispatch(connection, request)) + "\n");
      }
    });
  });
  server.listen(socketPath);
}
```

Logger and metrics adapters share the buffer/flush shape; register every `flush()` with the `LifetimePort` so buffered writes survive `SIGTERM`, crashes, and reloads. The hub is the only writer — every other connection is a `HubConnection` client, and `DuckDbInsights` queries through the hub's `query` op rather than opening the file.

## Lifecycle Hooks

### Node.js / Backend

```typescript
// main.ts (Composition Root)
const repo = new FirestoreCartAdapter(config.firestoreProjectId, config.firestoreCollection);
const logger = new ConsoleLogger();

// Graceful shutdown
process.on("SIGTERM", () => {
  console.log("SIGTERM received, shutting down...");
  // Flush buffers, close DB connections, drain queues
  process.exit(0);
});

process.on("SIGINT", () => {
  console.log("SIGINT received, shutting down...");
  process.exit(0);
});
```

### NestJS Lifecycle

```typescript
// app.module.ts
import { Module, OnModuleInit, OnModuleDestroy } from "@nestjs/common";

@Module({ providers: [FirestoreAdapter] })
export class AppModule implements OnModuleInit, OnModuleDestroy {
  constructor(private adapter: FirestoreAdapter) {}

  onModuleInit() {
    // Startup: open connections, validate config
    this.adapter.connect();
  }

  onModuleDestroy() {
    // Shutdown: flush buffers, close connections
    this.adapter.disconnect();
  }
}
```

## Hard-Fail Patterns

```typescript
// BAD: soft fail — swallows error
try {
  const result = await addToCartWorkflow.execute(productId, 1, price);
  return result;
} catch {
  return null;
}

// GOOD: hard fail — throws with context
const result = await addToCartWorkflow.execute(productId, 1, price); // Throws on error

// BAD: generic assertion
expect(result).toEqual(expected);

// GOOD: specific assertion with message
expect(result.status).toBe(DocumentStatus.PUBLISHED);
// vitest/jest show the exact mismatch on failure

// BAD: generic error
throw new Error("Invalid input");

// GOOD: specific, self-documenting error
throw new EmptyCartError();
throw new InsufficientStockError(productId, 5, 2);
```

## Pure Functions in Domain

Domain workflows should be pure functions: same input → same output, no side effects. I/O happens in adapters only.

```typescript
// BAD: impure — depends on external state
function calculateTotal(cart: Cart): number {
  const taxRate = getTaxRateFromDb(); // Hidden dependency!
  return cart.total * (1 + taxRate);
}

// GOOD: pure — all dependencies injected
function calculateTotal(cart: Cart, taxRate: number): number {
  return cart.total * (1 + taxRate);
}

// BAD: impure workflow — I/O mixed with logic
async function createDocument(content: string, db: any): Promise<Document> {
  const doc = { id: uuid(), content };
  await db.insert(doc); // Side effect!
  await sendEmail("Document created"); // Side effect!
  return doc;
}

// GOOD: pure workflow — logic only, I/O in adapters
async function createDocument(
  content: string,
  repo: CartRepository,
  logger: Logger,
  time: TimePort,
): Promise<Document> {
  const start = time.nowMs();

  // Pure logic: validation
  if (!content.trim()) throw new EmptyCartError();

  // Pure logic: create model
  const doc = { id: uuid(), content };

  // Adapter calls: all I/O happens here
  await repo.save(doc);
  const elapsed = time.elapsedMs(start);
  logger.info(`Document created ${doc.id} in ${elapsed}ms`);
  return doc;
}
```

**Testing pure functions is trivial:**

```typescript
it("calculates total with tax", () => {
  const cart = { items: [{ price: 10, quantity: 2 }], total: 20 };
  expect(calculateTotal(cart, 0.08)).toBe(21.6);
});

it("calculates total with zero tax", () => {
  const cart = { items: [{ price: 10, quantity: 2 }], total: 20 };
  expect(calculateTotal(cart, 0)).toBe(20);
});

// No mocks, no setup, no database — just input → output
```

## Structured Logging

```typescript
// adapters/structured-logger.ts
import { Logger } from "../domain/ports/Logger";

export class StructuredLogger implements Logger {
  private requestId: string | null = null;

  setRequestId(id: string) {
    this.requestId = id;
  }

  info(event: string, data?: Record<string, unknown>) {
    console.log(
      JSON.stringify({
        level: "info",
        request_id: this.requestId,
        event,
        ...data,
        timestamp: new Date().toISOString(),
      }),
    );
  }

  error(event: string, data?: Record<string, unknown>) {
    console.error(
      JSON.stringify({
        level: "error",
        request_id: this.requestId,
        event,
        ...data,
        timestamp: new Date().toISOString(),
      }),
    );
  }
}

// Usage
logger.info("cart_saved", { cart_id: cart.id, items: cart.items.length });
logger.error("stock_check_failed", { product_id: productId, error: e.message, retry: 1 });
```

## Diagnostics & Failure Localization (TypeScript)

### Uniform Error + Registry

```typescript
// domain/errors/AppError.ts (uniform diagnostic error — every layer uses this)
export type ErrorCode = "DOC-001" | "DOC-002" | "STO-001";

export class AppError extends Error {
  readonly cause?: unknown;
  constructor(
    readonly code: ErrorCode,
    message: string,
    readonly context: Record<string, unknown> = {},
    options: { cause?: unknown; origin?: string; correlationId?: string;
               retryable?: boolean; remediation?: string } = {},
  ) {
    super(message);
    this.name = "AppError";
    this.cause = options.cause;              // original — never discarded
    this.origin = options.origin ?? "";
    this.correlationId = options.correlationId ?? "";
    this.retryable = options.retryable ?? false;
    this.remediation = options.remediation ?? "";
  }
  origin: string;
  correlationId: string;
  retryable: boolean;
  remediation: string;
}
```

```ts
// tools/checkErrorCodes.ts — errors-check: no unknown or duplicate codes
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";

const registry = JSON.parse(readFileSync("errors.json", "utf8")) as Record<string, unknown>;
const known = new Set(Object.keys(registry));
const used = new Set<string>();
const walk = (dir: string) => {
  for (const entry of readdirSync(dir)) {
    const path = join(dir, entry);
    if (statSync(path).isDirectory()) walk(path);
    else if (path.endsWith(".ts"))
      for (const m of readFileSync(path, "utf8").matchAll(/code:\s*"([A-Z]+-\d+)"/g)) used.add(m[1]);
  }
};
walk(".");
const unknown = [...used].filter((c) => !known.has(c));
if (unknown.length) { console.error("Unregistered codes:", unknown); process.exit(1); }
console.log(`OK: ${used.size} codes used, all registered`);
```

### Boundary Translation + Crash Handler

```typescript
// adapters/sql/PgRepository.ts — translate + enrich, never swallow
import { AppError } from "../../domain/errors/AppError";

try {
  await this.pool.query(this.config.saveSql, this.toParams(entity));
} catch (e) {
  throw new AppError("STO-001", "Storage write failed", {
    operation: "save", adapter: "postgres",
  }, { cause: e, retryable: true, origin: "adapter.PgRepository.save:12" });
}

// main.ts (root) — install once; flush observability before exit
process.on("uncaughtException", (err) => {
  console.error(err, (err as AppError).context ?? {});
  flushObservability();                 // never lose buffered logs/metrics/events
  process.exit(70);                     // distinct exit code
});
process.on("unhandledRejection", (reason) => { throw reason; });
```

### Fault Injection

```typescript
// tests/fault/documentFaults.test.ts
it("surfaces STO-001 and preserves the cause", async () => {
  const repo: DocumentRepository = {
    save: async () => { throw new TimeoutError("timed out"); },
    findById: async () => null,
  };
  await expect(createDocument("Hello", repo, fakeLogger, fakeTime))
    .rejects.toMatchObject({ code: "STO-001", retryable: true });
});

it("observability survives a failing sink", async () => {
  await expect(createDocument("Hello", fakeRepo, failingLogger, fakeTime)).resolves.toBeDefined();
});
```

## Light Justfile & Terminal Output (TypeScript)

- The justfile is a **light index**: each recipe delegates (`npm run <task>`, `npx tsx cli.ts <task>`). Logic lives in `cli.ts` (a driving adapter), never in the justfile.
- Colored, structured output via `boxen` (panels) + `chalk` (colors, auto-disabled by `NO_COLOR`/non-TTY) + `ora` (spinners), behind a `PresenterPort` adapter — never `console.log` in domain.

```just
doctor:
    npx tsx cli.ts doctor
seed:
    npx tsx cli.ts seed
```

## Property, Mutation & Formal Verification (TypeScript)

```typescript
// tests/property/document.test.ts (fast-check)
import fc from "fast-check";

test("create then read round-trips", () => {
  fc.assert(fc.property(fc.string({ minLength: 1 }), (content) => {
    const repo = new FakeDocumentRepo();
    const doc = createDocument(content, repo, new FakeLogger(), new FakeTime());
    expect(repo.findById(doc.id)).toEqual(doc);
  }));
});

test("encode/decode round-trips", () => {
  fc.assert(fc.property(fc.array(fc.string()), (docs) =>
    expect(docs.map((d) => decode(encode(d)))).toEqual(docs)));
});
```

```just
test-property:
    vitest run tests/property

mutation:
    npx stryker run        # StrykerJS; enforce thresholds.break in stryker.conf.json
```

- **Mutation**: StrykerJS with `thresholds.break` scoped to `domain/`; a survivor is a missing assertion.
- **Formal**: model-check protocols/state machines in **TLA+/Apalache**; keep the pure core small so it is tractable.

## Testing

### Shared Fixtures

```typescript
// tests/fixtures/fakes.ts
import { CartRepository } from "../../domain/ports/CartRepository";
import { Logger } from "../../domain/ports/Logger";
import { StockChecker } from "../../domain/ports/StockChecker";
import { TimePort } from "../../domain/ports/TimePort";
import { Cart } from "../../domain/models/Cart";

export class FakeCartRepository implements CartRepository {
  private cart: Cart | null = null;
  public saveCount = 0;

  async saveCart(cart: Cart): Promise<void> {
    this.cart = cart;
    this.saveCount++;
  }

  async getCart(): Promise<Cart | null> {
    return this.cart;
  }
}

export class FakeLogger implements Logger {
  public messages: { level: string; message: string }[] = [];
  public infoCount = 0;
  public errorCount = 0;

  info(message: string): void {
    this.messages.push({ level: "info", message });
    this.infoCount++;
  }

  error(message: string): void {
    this.messages.push({ level: "error", message });
    this.errorCount++;
  }
}

export class FakeStockChecker implements StockChecker {
  public stock: Map<string, number> = new Map();
  public checkCount = 0;

  async getAvailableStock(productId: string): Promise<number> {
    this.checkCount++;
    return this.stock.get(productId) ?? 0;
  }

  setStock(productId: string, quantity: number): void {
    this.stock.set(productId, quantity);
  }
}

export class FakeTime implements TimePort {
  private currentMs = 1000;
  private sleptMs = 0;

  nowMs(): number {
    return this.currentMs;
  }

  elapsedMs(startMs: number): number {
    return this.currentMs - startMs;
  }

  async sleepMs(ms: number): Promise<void> {
    this.sleptMs += ms; // deterministic — no real waiting in tests
  }

  advanceMs(ms: number): void {
    this.currentMs += ms;
  }
}

// tests/fixtures/factories.ts
import { Cart, CartItem } from "../../domain/models/Cart";

export function createCart(overrides?: Partial<Cart>): Cart {
  return {
    items: [],
    total: 0,
    ...overrides,
  };
}

export function createCartItem(overrides?: Partial<CartItem>): CartItem {
  return {
    productId: "product-1",
    quantity: 1,
    price: 9.99,
    ...overrides,
  };
}

export function createCartWithItems(count: number): Cart {
  const items: CartItem[] = Array.from({ length: count }, (_, i) =>
    createCartItem({
      productId: `product-${i + 1}`,
      quantity: i + 1,
      price: (i + 1) * 5,
    }),
  );
  return {
    items,
    total: items.reduce((sum, item) => sum + item.price * item.quantity, 0),
  };
}

// tests/fixtures/index.ts
export { FakeCartRepository, FakeLogger, FakeStockChecker, FakeTime } from "./fakes";
export { createCart, createCartItem, createCartWithItems } from "./factories";
```

### Unit Tests

```typescript
// tests/unit/AddToCartWorkflow.test.ts
import { describe, it, expect, beforeEach } from "vitest";
import { AddToCartWorkflow } from "../../domain/workflows/AddToCartWorkflow";
import { InsufficientStockError } from "../../domain/errors/CartErrors";
import {
  FakeCartRepository,
  FakeLogger,
  FakeStockChecker,
  FakeTime,
  createCartItem,
} from "../fixtures";

describe("AddToCartWorkflow", () => {
  let repo: FakeCartRepository;
  let stockChecker: FakeStockChecker;
  let logger: FakeLogger;
  let time: FakeTime;
  let workflow: AddToCartWorkflow;

  beforeEach(() => {
    repo = new FakeCartRepository();
    stockChecker = new FakeStockChecker();
    logger = new FakeLogger();
    time = new FakeTime();
    workflow = new AddToCartWorkflow(repo, stockChecker, logger, time);
  });

  it("should add item to empty cart", async () => {
    stockChecker.setStock("product-1", 10);

    const cart = await workflow.execute("product-1", 2, 9.99);

    expect(cart.items).toHaveLength(1);
    expect(cart.items[0].productId).toBe("product-1");
    expect(cart.items[0].quantity).toBe(2);
    expect(cart.total).toBe(19.98);
    expect(logger.infoCount).toBe(1);
  });

  it("should log duration", async () => {
    stockChecker.setStock("product-1", 10);
    time.advanceMs(42);

    await workflow.execute("product-1", 1, 9.99);

    expect(logger.messages[0].message).toContain("42ms");
  });

  it("should increase quantity for existing item", async () => {
    stockChecker.setStock("product-1", 10);
    await workflow.execute("product-1", 1, 9.99);
    const cart = await workflow.execute("product-1", 3, 9.99);

    expect(cart.items).toHaveLength(1);
    expect(cart.items[0].quantity).toBe(4);
    expect(cart.total).toBe(39.96);
  });

  it("should throw InsufficientStockError when stock is low", async () => {
    stockChecker.setStock("product-1", 2);

    await expect(workflow.execute("product-1", 5, 9.99)).rejects.toThrow(
      InsufficientStockError,
    );
  });

  it("should track save count", async () => {
    stockChecker.setStock("product-1", 10);
    stockChecker.setStock("product-2", 10);

    await workflow.execute("product-1", 1, 9.99);
    await workflow.execute("product-2", 2, 19.99);

    expect(repo.saveCount).toBe(2);
  });

  it("should log each cart addition", async () => {
    stockChecker.setStock("product-1", 10);
    stockChecker.setStock("product-2", 10);

    await workflow.execute("product-1", 1, 9.99);
    await workflow.execute("product-2", 2, 19.99);

    expect(logger.infoCount).toBe(2);
    expect(logger.messages[0].message).toContain("product-1");
    expect(logger.messages[1].message).toContain("product-2");
  });
});
```

### Integration Tests

```typescript
// tests/integration/FirestoreCartAdapter.test.ts
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { FirestoreCartAdapter } from "../../adapters/FirestoreCartAdapter";
import { Cart } from "../../domain/models/Cart";

describe("FirestoreCartAdapter", () => {
  let adapter: FirestoreCartAdapter;

  beforeAll(() => {
    adapter = new FirestoreCartAdapter("test-project", "test-carts");
  });

  afterAll(async () => {
    // Cleanup test data
  });

  it("should save and retrieve a cart", async () => {
    const cart: Cart = {
      items: [{ productId: "test-product", quantity: 1, price: 9.99 }],
      total: 9.99,
    };

    await adapter.saveCart(cart);
    const retrieved = await adapter.getCart();

    expect(retrieved).not.toBeNull();
    expect(retrieved!.items).toHaveLength(1);
    expect(retrieved!.total).toBe(9.99);
  });

  it("should return null for empty cart", async () => {
    const retrieved = await adapter.getCart();
    // After cleanup or in fresh state
    expect(retrieved).toBeNull();
  });
});

// tests/integration/HttpStockChecker.test.ts
import { describe, it, expect } from "vitest";
import { HttpStockChecker } from "../../adapters/HttpStockChecker";

describe("HttpStockChecker", () => {
  it("should fetch available stock from API", async () => {
    const checker = new HttpStockChecker("http://localhost:3001/api");
    const stock = await checker.getAvailableStock("product-1");

    expect(typeof stock).toBe("number");
    expect(stock).toBeGreaterThanOrEqual(0);
  });
});
```

### E2E Tests

```typescript
// tests/e2e/CartFlow.test.ts
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { AddToCartWorkflow } from "../../domain/workflows/AddToCartWorkflow";
import { FakeCartRepository, FakeStockChecker, FakeLogger } from "../fixtures";

describe("Cart E2E Flow", () => {
  let repo: FakeCartRepository;
  let stockChecker: FakeStockChecker;
  let logger: FakeLogger;
  let workflow: AddToCartWorkflow;

  beforeAll(() => {
    repo = new FakeCartRepository();
    stockChecker = new FakeStockChecker();
    logger = new FakeLogger();
    workflow = new AddToCartWorkflow(repo, stockChecker, logger);
  });

  it("should complete full add-to-cart flow", async () => {
    // Setup stock
    stockChecker.setStock("widget-1", 100);
    stockChecker.setStock("gadget-2", 50);

    // Add first item
    const cart1 = await workflow.execute("widget-1", 3, 12.99);
    expect(cart1.items).toHaveLength(1);
    expect(cart1.total).toBe(38.97);

    // Add second item
    const cart2 = await workflow.execute("gadget-2", 1, 24.99);
    expect(cart2.items).toHaveLength(2);
    expect(cart2.total).toBe(63.96);

    // Add more of first item
    const cart3 = await workflow.execute("widget-1", 2, 12.99);
    expect(cart3.items).toHaveLength(2);
    expect(cart3.items[0].quantity).toBe(5);
    expect(cart3.total).toBe(89.94);

    // Verify persistence
    expect(repo.saveCount).toBe(3);
    expect(logger.infoCount).toBe(3);
  });

  it("should reject when stock is insufficient", async () => {
    stockChecker.setStock("limited-item", 1);

    await expect(workflow.execute("limited-item", 10, 5.0)).rejects.toThrow();
    expect(logger.errorCount).toBe(0); // Error thrown before logging
  });
});
```
