# Animations Library

Canonical registry for keyframes, utility classes, `AnimationPort`/`AnimationService`, declarative Angular triggers, and composition recipes. All animation keyframes and classes used in the design system must come from this file.

**Framework-neutral**: keyframes and `.anim-*` / state classes (`.is-lifted`, `.is-pressed`, `.is-entering`, `.is-exiting`) are plain CSS — identical for Angular, React, and web. Angular `@angular/animations` triggers and `AnimationService` are optional Angular conveniences; React toggles the same classes (enter/leave via `is-entering`/`is-exiting` + `onAnimationEnd`) with no animation library. Haptics are not part of this registry — see [haptics.md](./haptics.md).

## Keyframe Registry

All keyframes are defined once. Reference by name — never redefine.

### shimmer

Used for skeleton screen loading animation.

```css
@keyframes shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
```

### spin

Used for spinners and loading indicators.

```css
@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
```

### dotPulse

Used for dots loading indicator.

```css
@keyframes dotPulse {
  0%, 80%, 100% { transform: scale(0.6); opacity: 0.4; }
  40% { transform: scale(1); opacity: 1; }
}
```

### fadeIn

Generic fade-in for entering elements.

```css
@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}
```

### fadeOut

Generic fade-out for exiting elements.

```css
@keyframes fadeOut {
  from { opacity: 1; }
  to { opacity: 0; }
}
```

### slideInUp

Enter from below.

```css
@keyframes slideInUp {
  from { transform: translateY(100%); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}
```

### slideOutDown

Exit downward.

```css
@keyframes slideOutDown {
  from { transform: translateY(0); opacity: 1; }
  to { transform: translateY(100%); opacity: 0; }
}
```

### slideInRight

Enter from right (for RTL-aware sidebars, drawers).

```css
@keyframes slideInRight {
  from { transform: translateX(100%); opacity: 0; }
  to { transform: translateX(0); opacity: 1; }
}
```

### slideOutLeft

Exit left.

```css
@keyframes slideOutLeft {
  from { transform: translateX(0); opacity: 1; }
  to { transform: translateX(-100%); opacity: 0; }
}
```

### peelOff

Pattern 4 dismiss animation: lift → fade → radius contract.

```css
@keyframes peelOff {
  0% {
    transform: translateY(0) scale(1);
    opacity: 1;
    border-radius: var(--radius-outer-lg);
  }
  40% {
    transform: translateY(-8px) scale(1.02);
    opacity: 0.8;
  }
  100% {
    transform: translateY(-20px) scale(0.95);
    opacity: 0;
    border-radius: var(--radius-outer-sm);
  }
}
```

### morphRadius

Subtle radius pulse for state changes.

```css
@keyframes morphRadius {
  0% { border-radius: var(--radius-outer-md); }
  50% { border-radius: var(--radius-outer-lg); }
  100% { border-radius: var(--radius-outer-md); }
}
```

### scaleIn

Pop-in effect for modals, tooltips.

```css
@keyframes scaleIn {
  from { transform: scale(0.95); opacity: 0; }
  to { transform: scale(1); opacity: 1; }
}
```

### scaleOut

Pop-out effect.

```css
@keyframes scaleOut {
  from { transform: scale(1); opacity: 1; }
  to { transform: scale(0.95); opacity: 0; }
}
```

---

## Utility Classes

Apply animation classes to elements. All durations and easings use tokens.

| Class | Animation | Duration | Easing | Use Case |
|-------|-----------|----------|--------|----------|
| `.anim-fade-in` | fadeIn | `--duration-normal` | `--easing-default` | Generic enter |
| `.anim-fade-out` | fadeOut | `--duration-normal` | `--easing-default` | Generic exit |
| `.anim-slide-in-up` | slideInUp | `--duration-slow` | `--easing-out` | Toast/drawer enter |
| `.anim-slide-out-down` | slideOutDown | `--duration-slow` | `--easing-in` | Toast/drawer exit |
| `.anim-slide-in-right` | slideInRight | `--duration-slow` | `--easing-out` | Sidebar enter |
| `.anim-slide-out-left` | slideOutLeft | `--duration-slow` | `--easing-in` | Sidebar exit |
| `.anim-peel-off` | peelOff | `--duration-slow` | `--easing-peel` | Pattern 4 dismiss |
| `.anim-scale-in` | scaleIn | `--duration-normal` | `--easing-out` | Modal/tooltip enter |
| `.anim-scale-out` | scaleOut | `--duration-normal` | `--easing-in` | Modal/tooltip exit |
| `.anim-morph-radius` | morphRadius | `--duration-morph` | `--easing-morph` | State change pulse |
| `.anim-spin` | spin | `--duration-spinner` | linear | Spinners |
| `.anim-shimmer` | shimmer | `--duration-loading` | linear | Skeleton screens |
| `.anim-dot-pulse` | dotPulse | `--duration-spinner` | ease-in-out | Dots loading |

### State Classes

| Class | Effect | Use Case |
|-------|--------|----------|
| `.is-lifted` | `transform: translateY(-2px); box-shadow: var(--shadow-hover);` | Pattern 4 hover state |
| `.is-pressed` | `transform: scale(0.98); box-shadow: var(--shadow-active);` | Pattern 4 active state |
| `.is-entering` | Applied during enter animation | Animation lifecycle |
| `.is-exiting` | Applied during exit animation | Animation lifecycle |

```css
.anim-fade-in {
  animation: fadeIn var(--duration-normal) var(--easing-default);
}

.anim-slide-in-up {
  animation: slideInUp var(--duration-slow) var(--easing-out);
}

.anim-peel-off {
  animation: peelOff var(--duration-slow) var(--easing-peel) forwards;
}

.is-lifted {
  transform: translateY(-2px);
  box-shadow: var(--shadow-hover);
}

.is-pressed {
  transform: scale(0.98);
  box-shadow: var(--shadow-active);
}
```

---

## AnimationPort (Domain Layer)

Framework-agnostic interface for animations. No DOM types in the domain layer.

```typescript
// domain/ports/AnimationPort.ts

export interface AnimationCoordinates {
  readonly x: number;
  readonly y: number;
  readonly width: number;
  readonly height: number;
}

export interface AnimationResult {
  readonly cancel: () => void;
}

export interface AnimationPort {
  fadeIn(target: string, duration?: number): AnimationResult;
  fadeOut(target: string, duration?: number): AnimationResult;
  slideIn(target: string, direction: 'up' | 'down' | 'left' | 'right', duration?: number): AnimationResult;
  slideOut(target: string, direction: 'up' | 'down' | 'left' | 'right', duration?: number): AnimationResult;
  scaleIn(target: string, duration?: number): AnimationResult;
  scaleOut(target: string, duration?: number): AnimationResult;
  peelOff(target: string, duration?: number): AnimationResult;
  morphRadius(target: string, fromRadius: string, toRadius: string, duration?: number): AnimationResult;
  spin(target: string, duration?: number): AnimationResult;
  stop(animation: AnimationResult): void;
}
```

---

## AnimationService (Angular Adapter)

Angular implementation of `AnimationPort` using `@angular/animations`.

```typescript
// adapters/animation/animation.service.ts

import { Injectable, inject } from '@angular/core';
import { AnimationBuilder, style, animate, AnimationPlayer } from '@angular/animations';
import { AnimationPort, AnimationResult } from '../../domain/ports/AnimationPort';

@Injectable({ providedIn: 'root' })
export class AnimationService implements AnimationPort {
  private builder = inject(AnimationBuilder);

  fadeIn(target: string, duration = 200): AnimationResult {
    const player = this.builder.build([
      style({ opacity: 0 }),
      animate(`${duration}ms cubic-bezier(0.4, 0, 0.2, 1)`, style({ opacity: 1 }))
    ]).create(document.querySelector(target));

    player.play();
    return { cancel: () => player.destroy() };
  }

  fadeOut(target: string, duration = 200): AnimationResult {
    const player = this.builder.build([
      style({ opacity: 1 }),
      animate(`${duration}ms cubic-bezier(0.4, 0, 1, 1)`, style({ opacity: 0 }))
    ]).create(document.querySelector(target));

    player.play();
    return { cancel: () => player.destroy() };
  }

  slideIn(target: string, direction: 'up' | 'down' | 'left' | 'right', duration = 300): AnimationResult {
    const transforms: Record<string, string> = {
      up: 'translateY(100%)',
      down: 'translateY(-100%)',
      left: 'translateX(100%)',
      right: 'translateX(-100%)'
    };

    const player = this.builder.build([
      style({ transform: transforms[direction], opacity: 0 }),
      animate(`${duration}ms cubic-bezier(0, 0, 0.2, 1)`, style({ transform: 'translate(0)', opacity: 1 }))
    ]).create(document.querySelector(target));

    player.play();
    return { cancel: () => player.destroy() };
  }

  slideOut(target: string, direction: 'up' | 'down' | 'left' | 'right', duration = 300): AnimationResult {
    const transforms: Record<string, string> = {
      up: 'translateY(-100%)',
      down: 'translateY(100%)',
      left: 'translateX(-100%)',
      right: 'translateX(100%)'
    };

    const player = this.builder.build([
      style({ transform: 'translate(0)', opacity: 1 }),
      animate(`${duration}ms cubic-bezier(0.4, 0, 1, 1)`, style({ transform: transforms[direction], opacity: 0 }))
    ]).create(document.querySelector(target));

    player.play();
    return { cancel: () => player.destroy() };
  }

  scaleIn(target: string, duration = 200): AnimationResult {
    const player = this.builder.build([
      style({ transform: 'scale(0.95)', opacity: 0 }),
      animate(`${duration}ms cubic-bezier(0, 0, 0.2, 1)`, style({ transform: 'scale(1)', opacity: 1 }))
    ]).create(document.querySelector(target));

    player.play();
    return { cancel: () => player.destroy() };
  }

  scaleOut(target: string, duration = 200): AnimationResult {
    const player = this.builder.build([
      style({ transform: 'scale(1)', opacity: 1 }),
      animate(`${duration}ms cubic-bezier(0.4, 0, 1, 1)`, style({ transform: 'scale(0.95)', opacity: 0 }))
    ]).create(document.querySelector(target));

    player.play();
    return { cancel: () => player.destroy() };
  }

  peelOff(target: string, duration = 300): AnimationResult {
    const player = this.builder.build([
      style({ transform: 'translateY(0) scale(1)', opacity: 1 }),
      animate(`${duration}ms cubic-bezier(0.33, 1, 0.68, 1)`, style({
        transform: 'translateY(-20px) scale(0.95)',
        opacity: 0
      }))
    ]).create(document.querySelector(target));

    player.play();
    return { cancel: () => player.destroy() };
  }

  morphRadius(target: string, fromRadius: string, toRadius: string, duration = 350): AnimationResult {
    const player = this.builder.build([
      style({ borderRadius: fromRadius }),
      animate(`${duration}ms cubic-bezier(0.65, 0, 0.35, 1)`, style({ borderRadius: toRadius }))
    ]).create(document.querySelector(target));

    player.play();
    return { cancel: () => player.destroy() };
  }

  spin(target: string, duration = 1000): AnimationResult {
    const player = this.builder.build([
      style({ transform: 'rotate(0deg)' }),
      animate(`${duration}ms linear`, style({ transform: 'rotate(360deg)' }))
    ]).create(document.querySelector(target));

    player.play();
    return { cancel: () => player.destroy() };
  }

  stop(animation: AnimationResult): void {
    animation.cancel();
  }
}
```

---

## Declarative Angular Triggers

Use these triggers in Angular templates for enter/leave animations.

### @fadeTrigger

```typescript
import { trigger, transition, style, animate } from '@angular/animations';

export const fadeTrigger = trigger('fade', [
  transition(':enter', [
    style({ opacity: 0 }),
    animate('200ms cubic-bezier(0.4, 0, 0.2, 1)', style({ opacity: 1 }))
  ]),
  transition(':leave', [
    animate('200ms cubic-bezier(0.4, 0, 1, 1)', style({ opacity: 0 }))
  ])
]);
```

```html
<div @fade *ngIf="visible()">Content</div>
```

### @slideTrigger

```typescript
export const slideTrigger = trigger('slide', [
  transition(':enter', [
    style({ transform: 'translateY(100%)', opacity: 0 }),
    animate('300ms cubic-bezier(0, 0, 0.2, 1)', style({ transform: 'translateY(0)', opacity: 1 }))
  ]),
  transition(':leave', [
    animate('300ms cubic-bezier(0.4, 0, 1, 1)', style({ transform: 'translateY(100%)', opacity: 0 }))
  ])
]);
```

### @peelOffTrigger

Pattern 4 dismiss animation.

```typescript
export const peelOffTrigger = trigger('peelOff', [
  transition(':leave', [
    animate('300ms cubic-bezier(0.33, 1, 0.68, 1)', style({
      transform: 'translateY(-20px) scale(0.95)',
      opacity: 0
    }))
  ])
]);
```

```html
<div @peelOff *ngIf="isOpen()">Modal content</div>
```

### @morphSurfaceTrigger

Dual-radius morph for Pattern 4.

```typescript
export const morphSurfaceTrigger = trigger('morphSurface', [
  transition('* => hovered', [
    animate('350ms cubic-bezier(0.65, 0, 0.35, 1)')
  ]),
  transition('hovered => *', [
    animate('350ms cubic-bezier(0.65, 0, 0.35, 1)')
  ])
]);
```

---

## Composition Recipes

### Lift Recipe (Pattern 4 Hover)

Apply to any surface that lifts on hover.

```css
.surface-lift {
  transition:
    transform var(--duration-normal) var(--easing-peel),
    box-shadow var(--duration-slow) var(--easing-default),
    border-radius var(--duration-morph) var(--easing-morph);
}

.surface-lift:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-hover);
}

.surface-lift:active {
  transform: translateY(0) scale(0.99);
  box-shadow: var(--shadow-active);
}
```

### Morph Recipe (Pattern 4 Radius Change)

Apply when radius changes between states.

```css
.surface-morph {
  transition: border-radius var(--duration-morph) var(--easing-morph);
}

.surface-morph:hover {
  border-radius: var(--radius-outer-xl);
}

.surface-morph:hover .surface-morph__well {
  border-radius: var(--radius-inner-xl);
}
```

### Peel Exit Recipe (Pattern 4 Dismiss)

Apply to elements that peel off when dismissed.

```css
.surface-peel-exit {
  transition:
    transform var(--duration-normal) var(--easing-peel),
    box-shadow var(--duration-slow) var(--easing-default);
}

.surface-peel-exit.is-exiting {
  animation: peelOff var(--duration-slow) var(--easing-peel) forwards;
}
```

---

## Reduced Motion Policy

When `prefers-reduced-motion: reduce` is active:

- **All animations**: Duration set to `0.01ms` (effectively instant)
- **All transitions**: Duration set to `0.01ms`
- **Skeleton shimmer**: Disabled (show static placeholder)
- **Spinners**: Still visible but static (no rotation)
- **Enter/leave**: Instant show/hide (no fade, slide, or peel)
- **Hover effects**: No transform or shadow changes

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }

  .anim-shimmer {
    animation: none;
  }

  .spinner {
    animation: none;
  }
}
```

---

## Performance Guidelines

1. **Prefer `transform` and `opacity`** — These are GPU-accelerated and don't trigger layout
2. **Avoid animating `width`, `height`, `top`, `left`** — These trigger layout recalculation
3. **Use `will-change` sparingly** — Only on elements that will animate, remove after animation completes
4. **Use `contain: layout style`** on animated components to limit browser paint area
5. **Batch DOM reads/writes** — Don't read layout properties inside animation callbacks

```css
/* Good — GPU-accelerated */
.surface:hover {
  transform: translateY(-2px);
  opacity: 0.9;
}

/* Bad — triggers layout */
.surface:hover {
  top: -2px;
  width: calc(100% + 4px);
}
```
