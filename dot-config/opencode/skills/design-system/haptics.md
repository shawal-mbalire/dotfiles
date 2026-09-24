# Haptic Feedback

Semantic haptic registry for the design system.

**Haptics and visual/AT feedback are separate channels.** The Action Acknowledgement contract ([SKILL.md](./SKILL.md) Principle 18, Retry Contract in loading.md) is defined and satisfied in visual/AT terms alone — haptics are never required to pass that contract, and never substitute for it. This file governs an optional extra channel: when a product enables haptics, these are the rules. Canonical event names live here; platform adapters map events to vibration patterns / platform haptic APIs.

## Principles

1. **Optional parallel channel** — haptics may fire on the same interactions the visual contract already covers (press dispatch, settled outcomes, every retry press); disabling haptics changes nothing about action-feedback compliance.
2. **Terminal outcomes get distinct haptics** — success ≠ error ≠ warning; retry press ≠ retry success.
3. **Registry only** — call sites use semantic event names from this file, never raw `navigator.vibrate(ms)` patterns or platform impact constants inline.
4. **Never the sole channel** — always paired with the visual (and AT) feedback the action contract already requires.
5. **Never continuous** — no haptics on hover/focus, no repeating haptics while a spinner runs, no per-frame vibration.

## Event Registry

| Event | Meaning | Vibration pattern (ms) | Typical trigger |
|-------|---------|------------------------|-----------------|
| `tap` | Discrete commit ack | `[10]` | Button press, link activate |
| `select` | Selection changed | `[5]` | Checkbox, toggle, tab select, segmented control |
| `retry-ack` | Retry attempt accepted (same weight as `tap`) | `[10]` | Retry button press — fires **every** attempt |
| `success` | Positive terminal outcome | `[10, 50, 10]` | Async operation succeeded |
| `warning` | Caution terminal outcome | `[10, 40, 10]` | Destructive confirm, degraded success |
| `error` | Failure terminal outcome | `[30, 50, 30]` | Validation failure, network error settled |

**Patterns are adapter-internal.** Call sites only pass the event name. Flutter/`HapticFeedback` maps these to `lightImpact` / `selectionClick` / `notificationImpact` / `errorImpact` (see [frameworks/flutter.md](./frameworks/flutter.md)).

## When to Fire

| Situation | Event | Notes |
|-----------|-------|-------|
| Control press (dispatch) | `tap` | Fire at dispatch, before async settles |
| Toggle / tab / checkbox change | `select` | Once per committed change |
| Retry press (any attempt) | `retry-ack` | Immediate ack of the attempt; NOT `success` |
| Async success settles | `success` | Once, terminal |
| Async failure settles | `error` | Once per settled failure (each retry failure re-fires `error`) |
| Loading in progress | — | No haptics while pending |
| Hover / focus only | — | No haptics |
| Hover-reveal tooltips, theme switch mid-animation | — | No haptics |

### Retry Lifecycle (visual contract + haptic overlay)

The visual sequence is the contract; haptics overlay it only when the channel is enabled:

```
press → visual press state                     + haptic(retry-ack)?
      → loading (aria-busy, no haptic)
      → success: visual success feedback       + haptic(success)?
      → failure: visual error + attempt count  + haptic(error)?
```

## HapticPort (Domain Layer)

Framework-agnostic. No DOM, no Flutter imports.

```typescript
// domain/ports/HapticPort.ts
export type HapticEvent = 'tap' | 'select' | 'retry-ack' | 'success' | 'warning' | 'error';

export interface HapticPort {
  play(event: HapticEvent): void;
  isEnabled(): boolean;
  setEnabled(enabled: boolean): void;
}
```

## Web Adapter (Angular + React)

Shared adapter for browser targets. Feature-detects the Vibration API; **no-ops silently** when unsupported (notably iOS Safari) or when disabled.

```typescript
// adapters/haptics/web-haptic.adapter.ts
import { HapticPort, HapticEvent } from '../../domain/ports/HapticPort';

const PATTERNS: Record<HapticEvent, number[]> = {
  'tap': [10],
  'select': [5],
  'retry-ack': [10],
  'success': [10, 50, 10],
  'warning': [10, 40, 10],
  'error': [30, 50, 30],
};

export class WebHapticAdapter implements HapticPort {
  private enabled = true;

  play(event: HapticEvent): void {
    if (!this.enabled) return;
    if (typeof navigator === 'undefined' || typeof navigator.vibrate !== 'function') return;
    try {
      navigator.vibrate(PATTERNS[event]);
    } catch {
      /* unsupported or blocked — haptics are best-effort */
    }
  }

  isEnabled(): boolean {
    return this.enabled;
  }

  setEnabled(enabled: boolean): void {
    this.enabled = enabled;
  }
}
```

**iOS / hybrid note**: the Vibration API is unavailable in iOS Safari (adapter no-ops, visual feedback still required). For hybrid apps the user may explicitly opt into `@capacitor/haptics` behind the same `HapticPort` — that is an approved dependency escape hatch, never a default.

### Usage (Angular)

```typescript
private haptics = inject(HapticPort);

onRetry() {
  this.haptics.play('retry-ack');   // dispatch ack, before request
  this.retrying.set(true);
  // ... async settle → play('success') | play('error')
}
```

### Usage (React)

```tsx
const haptics = usePorts().haptics;

function handleRetry() {
  haptics.play('retry-ack');
  setRetrying(true);
  // ... async settle → haptics.play('success') | haptics.play('error')
}
```

## Flutter Adapter

Map events via `HapticPort` — see [frameworks/flutter.md](./frameworks/flutter.md#haptics).

## Reduced / Disabled Haptics

- Honor the platform OS setting for haptic feedback where the platform exposes it.
- Honor `prefers-reduced-motion: reduce` as a **conservative default proxy** to disable haptics unless the product explicitly opts out of that coupling.
- Expose `HapticPort.setEnabled()` for an in-app preference.
- When disabled or unsupported: adapter no-ops; **visual + AT feedback must already cover the action** (see [accessibility.md](./accessibility.md)).

## Lint Rules

Enforced in [lint-rules.md](./lint-rules.md):

- `haptics-from-registry` (WARNING) — only named `HapticEvent` values at call sites; no raw vibration patterns outside adapters.
- `no-haptic-as-sole-feedback` (WARNING) — every haptic call site must be accompanied by visual (and where applicable AT) feedback in the same handler.
