# Motion Design

Motion principles and transition guidance for the design system. The canonical animation registry — keyframes, utility classes, `AnimationService`, declarative triggers, and composition recipes — lives in [animations-library.md](./animations-library.md). Haptic feedback is not part of motion tokens — see [haptics.md](./haptics.md).

## When to Use Which

| Use Case | Approach |
|----------|----------|
| Hover/focus/active states | CSS transitions |
| Element enter/leave (`*ngIf`, `@if`) | `@angular/animations` |
| List animations (`*ngFor`, `@for`) | `animateChild()` + `query()` |
| Route transitions | `@routeAnimation` trigger |
| Complex choreographed sequences | `@angular/animations` stagger |
| Simple show/hide | CSS transitions with `[class.hidden]` |
| Dual-radius morph (Pattern 4) | `morph()` port / `morphSurface` trigger |
| Peel exits (Pattern 4) | `peelOff()` port / `@peelOff` trigger |

## Angular Animation Module

For complex enter/leave transitions, use `@angular/animations`. For simple hover/focus state changes, use CSS transitions.

```typescript
// app.config.ts
import { provideAnimationsAsync } from '@angular/platform-browser/animations/async';

export const appConfig: ApplicationConfig = {
  providers: [
    provideAnimationsAsync(),
    // ... other providers
  ]
};
```

## Transition Principles

1. **Purposeful**: Every animation should have a purpose (feedback, orientation, focus)
2. **Quick**: Most transitions should be 100-300ms; morphs max out at `--duration-morph` (350ms)
3. **Smooth**: Use appropriate easing functions from the token set
4. **Respectful**: Honor `prefers-reduced-motion`
5. **Tokenized**: Never hardcode duration or easing values — always `var(--duration-*)` / `var(--easing-*)`

## Transition Properties

| Property | Duration Token | Easing Token | Use Case |
|----------|----------------|--------------|----------|
| `background-color` | `--duration-normal` (200ms) | `--easing-default` | Color changes |
| `color` | `--duration-normal` | `--easing-default` | Text color changes |
| `border-color` | `--duration-normal` | `--easing-default` | Border color changes |
| `box-shadow` | `--duration-slow` (300ms) | `--easing-default` | Elevation changes |
| `transform` | `--duration-normal` | `--easing-peel` (lift) / `--easing-out` | Movement, scale |
| `opacity` | `--duration-normal` | `--easing-default` | Show/hide |
| `border-radius` | `--duration-morph` (350ms) | `--easing-morph` | Dual-radius morph (Pattern 4) |
| `width/height` | `--duration-slow` | `--easing-default` | Size changes (avoid when possible) |

## Combined Transitions

```css
.btn {
  transition: background-color var(--duration-normal) var(--easing-default),
              transform var(--duration-fast) var(--easing-default);
}

.card {
  transition: box-shadow var(--duration-slow) var(--easing-default),
              transform var(--duration-normal) var(--easing-default);
}

.nav-item {
  transition: background-color var(--duration-normal) var(--easing-default),
              color var(--duration-normal) var(--easing-default);
}

/* Pattern 4 surface — lift + morph + shadow */
.surface {
  transition: transform var(--duration-normal) var(--easing-peel),
              box-shadow var(--duration-slow) var(--easing-default),
              border-radius var(--duration-morph) var(--easing-morph);
}
```

## Animation Guidelines

- Avoid animations that flash or blink
- Keep animations under 5 seconds
- Provide pause/stop controls for auto-playing animations
- Use `will-change` sparingly for performance
- Prefer `transform` and `opacity`; animate `border-radius` only for morph primitives
- All keyframes and animation classes must come from [animations-library.md](./animations-library.md)

## Timing Functions

### Ease Variations

| Token | Value | Use |
|-------|-------|-----|
| `--easing-default` | cubic-bezier(0.4, 0, 0.2, 1) | Most transitions |
| `--easing-in` | cubic-bezier(0.4, 0, 1, 1) | Exiting elements |
| `--easing-out` | cubic-bezier(0, 0, 0.2, 1) | Entering elements |
| `--easing-in-out` | cubic-bezier(0.42, 0, 0.58, 1) | Symmetric animations |
| `--easing-morph` | cubic-bezier(0.65, 0, 0.35, 1) | Dual-radius shape morphs |
| `--easing-peel` | cubic-bezier(0.33, 1, 0.68, 1) | Lift-off / peel exits |
| `--easing-bounce` | cubic-bezier(0.68, -0.55, 0.265, 1.55) | Playful emphasis (use sparingly) |

```css
/* Always via tokens */
transition: transform var(--duration-normal) var(--easing-out);
transition: border-radius var(--duration-morph) var(--easing-morph);
```

## Reduced Motion Support

See [Accessibility Requirements](./accessibility.md#reduced-motion) for the full implementation. Always include this media query in production CSS. The [animations-library.md](./animations-library.md#reduced-motion-policy) documents library-specific reduced-motion behavior.

## What Lives Where

| Concern | File |
|---------|------|
| Principles, when-to-use, timing tables | This file |
| Keyframe registry | [animations-library.md](./animations-library.md) |
| Utility classes (`.anim-*`, `.is-lifted`) | [animations-library.md](./animations-library.md) |
| `AnimationPort` + `AnimationService` | [animations-library.md](./animations-library.md) |
| Declarative triggers (`@morphSurface`, `@peelOff`) | [animations-library.md](./animations-library.md) |
| Composition recipes (lift, morph, peel) | [animations-library.md](./animations-library.md) |
| When to peel vs fade (binding rule) | [decision-rules.md](./decision-rules.md) L4 |
