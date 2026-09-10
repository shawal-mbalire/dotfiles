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

check: lint typecheck test

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
  info(message: string): void;
  error(message: string): void;
}

// domain/ports/TimePort.ts
export interface TimePort {
  nowMs(): number;
  elapsedMs(startMs: number): number;
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
}

// adapters/MockTimeAdapter.ts (for testing)
import { TimePort } from "../domain/ports/TimePort";

export class MockTimeAdapter implements TimePort {
  private currentMs = 1000;

  nowMs(): number {
    return this.currentMs;
  }

  elapsedMs(startMs: number): number {
    return this.currentMs - startMs;
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

  nowMs(): number {
    return this.currentMs;
  }

  elapsedMs(startMs: number): number {
    return this.currentMs - startMs;
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
