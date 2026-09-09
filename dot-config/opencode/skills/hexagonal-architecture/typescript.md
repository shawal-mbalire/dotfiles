# TypeScript — Hexagonal Architecture Guide

TypeScript-specific code examples and patterns for hexagonal architecture. See [SKILL.md](./SKILL.md) for core architecture principles.

## Code Examples

### React (Frontend)

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

// domain/constants.ts
export const EMPTY_CART_TOTAL = 0;

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

// domain/workflows/AddToCartWorkflow.ts
import { Cart, CartItem } from "../models/Cart";
import { CartRepository } from "../ports/CartRepository";
import { Logger } from "../ports/Logger";
import { EMPTY_CART_TOTAL } from "../constants";

export class AddToCartWorkflow {
  constructor(
    private cartRepo: CartRepository,
    private logger: Logger,
  ) {}

  async execute(
    productId: string,
    quantity: number,
    price: number,
  ): Promise<Cart> {
    const existingCart = (await this.cartRepo.getCart()) || {
      items: [],
      total: EMPTY_CART_TOTAL,
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
      EMPTY_CART_TOTAL,
    );
    await this.cartRepo.saveCart(existingCart);
    this.logger.info(`Added ${quantity} of product ${productId} to cart`);
    return existingCart;
  }
}

// infra/config.ts
export const config = {
  storageKey: process.env.REACT_APP_STORAGE_KEY || "cart",
  logLevel: process.env.REACT_APP_LOG_LEVEL || "info",
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

// adapters/LocalStorageCartAdapter.ts
import { CartRepository } from "../domain/ports/CartRepository";
import { Cart } from "../domain/models/Cart";

export class LocalStorageCartAdapter implements CartRepository {
  constructor(private storageKey: string) {}

  async saveCart(cart: Cart): Promise<void> {
    localStorage.setItem(this.storageKey, JSON.stringify(cart));
  }

  async getCart(): Promise<Cart | null> {
    const data = localStorage.getItem(this.storageKey);
    return data ? JSON.parse(data) : null;
  }
}

// adapters/useCartController.ts (Driving Adapter)
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
```

### Angular

```typescript
// domain/ports/UserRepository.ts
export interface UserRepository {
  getUser(id: string): Promise<User>;
  saveUser(user: User): Promise<void>;
}

// infra/logging.ts
import { Logger } from "../domain/ports/Logger";

export class SentryLogger implements Logger {
  info(message: string): void {
    Sentry.captureMessage(message, "info");
  }

  error(message: string): void {
    Sentry.captureException(new Error(message));
  }
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
const repo = new FirestoreDocumentAdapter(config.projectId, config.collectionName);
const logger = new ConsoleLogger();

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down...');
  // Flush buffers, close DB connections, drain queues
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down...');
  process.exit(0);
});
```

### NestJS Lifecycle

```typescript
// app.module.ts
import { Module, OnModuleInit, OnModuleDestroy } from '@nestjs/common';

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
  const result = await createDocument(content, repo, logger);
  return result;
} catch {
  return null;
}

// GOOD: hard fail — throws with context
const result = await createDocument(content, repo, logger); // Throws on error

// BAD: generic assertion
expect(result).toEqual(expected);

// GOOD: specific assertion with message
expect(result.status).toBe(DocumentStatus.PUBLISHED);
// vitest/jest show the exact mismatch on failure

// BAD: generic error
throw new Error("Invalid input");

// GOOD: specific, self-documenting error
throw new EmptyContentError("Document content cannot be empty");
throw new DocumentNotFoundError(documentId);
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
    console.log(JSON.stringify({
      level: "info",
      request_id: this.requestId,
      event,
      ...data,
      timestamp: new Date().toISOString(),
    }));
  }

  error(event: string, data?: Record<string, unknown>) {
    console.error(JSON.stringify({
      level: "error",
      request_id: this.requestId,
      event,
      ...data,
      timestamp: new Date().toISOString(),
    }));
  }
}

// Usage
logger.info("document_saved", { document_id: doc.id, collection: "documents" });
logger.error("firestore_save_failed", { document_id: doc.id, error: e.message, retry: 1 });
```

## Testing

### Shared Fixtures

```typescript
// tests/fixtures/fakes.ts
import { CartRepository } from '../../domain/ports/CartRepository';
import { Logger } from '../../domain/ports/Logger';
import { Cart } from '../../domain/models/Cart';

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

  info(message: string): void {
    this.messages.push({ level: 'info', message });
  }

  error(message: string): void {
    this.messages.push({ level: 'error', message });
  }
}

export { FakeCartRepository, FakeLogger } from './fakes';
```

### Unit Tests

```typescript
// tests/unit/AddToCartWorkflow.test.ts
import { describe, it, expect, beforeEach } from "vitest";
import { AddToCartWorkflow } from "../../domain/workflows/AddToCartWorkflow";
import {
  CartFactory,
  FakeCartRepository,
  FakeLogger,
  CartBuilder,
} from "../fixtures";

describe("AddToCartWorkflow", () => {
  let repo: FakeCartRepository;
  let logger: FakeLogger;
  let workflow: AddToCartWorkflow;

  beforeEach(() => {
    repo = new FakeCartRepository();
    logger = new FakeLogger();
    workflow = new AddToCartWorkflow(repo, logger);
  });

  it("should add item to empty cart", async () => {
    const cart = await workflow.execute("product-1", 2, 9.99);

    expect(cart.items).toHaveLength(1);
    expect(cart.items[0].productId).toBe("product-1");
    expect(cart.items[0].quantity).toBe(2);
    expect(cart.total).toBe(19.98);
    expect(logger.infoCount).toBe(1);
  });

  it("should increase quantity for existing item", async () => {
    await workflow.execute("product-1", 1, 9.99);
    const cart = await workflow.execute("product-1", 3, 9.99);

    expect(cart.items).toHaveLength(1);
    expect(cart.items[0].quantity).toBe(4);
    expect(cart.total).toBe(39.96);
  });

  it("should track save count", async () => {
    await workflow.execute("product-1", 1, 9.99);
    await workflow.execute("product-2", 2, 19.99);

    expect(repo.saveCount).toBe(2);
  });
});
```
