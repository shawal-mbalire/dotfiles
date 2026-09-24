# Design Lint Rules

Automated and reviewable rules for enforcing design system consistency. Inspired by shadcn/ui's approach to component linting.

## Rule Categories

### 1. Token Enforcement

Every CSS value must trace to a design token. No ad-hoc values.

| Rule | Severity | Description |
|------|----------|-------------|
| `no-hardcoded-colors` | ERROR | All color values must use `var(--token)`. Exception: `transparent`, `inherit`, `currentColor`. Use `var(--text-on-accent)` instead of `white`, `var(--text-primary)` instead of `black` |
| `no-hardcoded-spacing` | ERROR | All spacing must use `var(--space-*)` tokens. Exception: `0`, `auto`, `100%` |
| `no-hardcoded-radius` | ERROR | All border-radius must use `var(--border-radius-*)`, `var(--radius-outer-*)`, or `var(--radius-inner-*)` tokens |
| `no-hardcoded-shadow` | ERROR | All box-shadow must use `var(--shadow-*)` tokens |
| `no-hardcoded-font-size` | ERROR | All font-size must use `var(--font-size-*)` tokens |
| `no-hardcoded-z-index` | ERROR | All z-index must use `var(--z-*)` tokens |
| `no-hardcoded-motion` | ERROR | All durations/easing must use `var(--duration-*)` and `var(--easing-*)` tokens |
| `no-hardcoded-border-width` | ERROR | Structural borders must use `var(--border-width)` (focus rings use `var(--border-focus-width)` token) |

```css
/* BAD */
.card { background: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }

/* GOOD */
.card { background: var(--surface-primary); border-radius: var(--border-radius-lg); box-shadow: var(--shadow-md); }

/* GOOD — Pattern 4 dual radius */
.surface { border-radius: var(--radius-outer-lg); }
.surface__well { border-radius: var(--radius-inner-lg); }
```

### 2. No Gradients

Gradient colors are prohibited in component styles. Functional gradients (skeleton shimmer) are permitted.

| Rule | Severity | Description |
|------|----------|-------------|
| `no-decorative-gradients` | ERROR | `background: linear-gradient(...)` prohibited in component CSS |
| `no-gradient-borders` | ERROR | `border-image: linear-gradient(...)` prohibited |
| `no-gradient-text` | ERROR | `background-clip: text` with gradients prohibited |

**Exception**: Skeleton screen shimmer animation (keyframe name `shimmer` from [animations-library.md](./animations-library.md)):
```css
/* PERMITTED — functional loading animation */
.skeleton {
  background: linear-gradient(
    90deg,
    var(--surface-primary) 25%,
    var(--surface-secondary) 50%,
    var(--surface-primary) 75%
  );
  background-size: 200% 100%;
  animation: shimmer var(--duration-loading) infinite;
}
```

### 3. No Emojis in UI

Emojis are prohibited in component templates, labels, and user-facing text.

| Rule | Severity | Description |
|------|----------|-------------|
| `no-emoji-in-templates` | ERROR | No Unicode emoji characters in `.html` template files |
| `no-emoji-in-labels` | ERROR | No emoji in `aria-label`, `placeholder`, button text |
| `no-emoji-in-strings` | WARNING | No emoji in TypeScript string literals used for UI display |

**Use Lucide icons instead** (see Icon System below).

```html
<!-- BAD -->
<button>Submit ✓</button>
<span class="icon">🎉</span>

<!-- GOOD -->
<button>
  <lucide-icon name="check" />
  Submit
</button>
```

### 4. Icon System — Lucide

All icons must come from Lucide. Icons are bundled with the site (no CDN dependency).

| Rule | Severity | Description |
|------|----------|-------------|
| `use-lucide-icons` | ERROR | All icons must be Lucide icons, not emoji, not Font Awesome, not custom SVG |
| `icon-has-label` | ERROR | Icon-only buttons/links must have `aria-label` |
| `icon-is-decorative` | WARNING | Decorative icons must have `aria-hidden="true"` |

#### Setup

```bash
# Install lucide-angular
npm install lucide-angular
```

#### Icon Component

```typescript
import { Component, ChangeDetectionStrategy, input } from '@angular/core';
import { LucideAngularModule } from 'lucide-angular';

@Component({
  selector: 'app-icon',
  standalone: true,
  imports: [LucideAngularModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <lucide-icon
      [name]="name()"
      [size]="size()"
      [strokeWidth]="strokeWidth()"
      [class]="'icon icon--' + size()">
    </lucide-icon>
  `
})
export class IconComponent {
  name = input.required<string>();
  size = input<number>(24);
  strokeWidth = input<number>(2);
}
```

#### Usage

```html
<!-- Decorative icon -->
<app-icon name="home" [attr.aria-hidden]="true" />

<!-- Interactive icon button -->
<button aria-label="Close dialog">
  <app-icon name="x" />
</button>

<!-- Icon with text -->
<app-icon name="check-circle" [attr.aria-hidden]="true" />
<span>Task completed</span>
```

#### Available Icons

Use only from the Lucide icon set. Common icons:

| Category | Icons |
|----------|-------|
| Navigation | `home`, `menu`, `chevron-left`, `chevron-right`, `arrow-left`, `arrow-right` |
| Actions | `check`, `x`, `plus`, `minus`, `edit`, `trash-2`, `copy`, `download` |
| Status | `check-circle`, `alert-circle`, `alert-triangle`, `info`, `loader` |
| Media | `play`, `pause`, `skip-forward`, `volume-2`, `volume-x` |
| Social | `share-2`, `heart`, `bookmark`, `star` |
| Layout | `search`, `filter`, `sort-asc`, `grid`, `list` |
| Communication | `mail`, `message-circle`, `bell`, `send` |

### 5. Logical Properties

All directional CSS properties must use logical equivalents for RTL support.

| Rule | Severity | Description |
|------|----------|-------------|
| `use-logical-properties` | ERROR | No `margin-left`, `margin-right`, `padding-left`, `padding-right`, `border-left`, `border-right` |
| `use-logical-text-align` | ERROR | No `text-align: left` or `text-align: right`, use `start`/`end` |

```css
/* BAD */
.sidebar { margin-left: 250px; padding-right: 16px; }
.text { text-align: left; }

/* GOOD */
.sidebar { margin-inline-start: 250px; padding-inline-end: 16px; }
.text { text-align: start; }
```

### 6. Interaction States

Every interactive element must define all required states.

| Rule | Severity | Description |
|------|----------|-------------|
| `has-hover-state` | ERROR | Interactive elements must have `:hover` styles |
| `has-focus-visible` | ERROR | Interactive elements must have `:focus-visible` styles |
| `has-disabled-state` | WARNING | Interactive elements must have `:disabled` or `[disabled]` styles |
| `has-transition` | WARNING | Interactive elements should have `transition` for state changes |
| `no-transition-all` | WARNING | Avoid `transition: all` — specify individual properties for performance and predictability |
| `no-wholesale-opacity-hover` | WARNING | No blanket `opacity` changes on `:hover` for text-bearing components — use color/background/shadow tokens instead (disabled `opacity` is allowed) |
| `async-action-has-loading` | ERROR | Controls that trigger async work (submit, save, retry) must define a loading/disabled state (`aria-busy` while in-flight) per the Retry Contract in loading.md |
| `retry-has-feedback` | WARNING | Retry affordances must surface pending state and attempt feedback (never silent backoff or bare disabled) |

### 6a. Haptics

Haptics are a **separate optional channel** from visual/AT action feedback — these rules govern haptic call sites only; compliance with the action-feedback contract never depends on them.

| Rule | Severity | Description |
|------|----------|-------------|
| `haptics-from-registry` | WARNING | Haptic calls must use named `HapticEvent` values from haptics.md (`tap`, `select`, `retry-ack`, `success`, `warning`, `error`) — no raw vibration patterns or platform impact constants outside adapters |
| `no-haptic-as-sole-feedback` | WARNING | Every haptic call site must sit alongside visual (and where applicable AT) feedback in the same handler — haptics never replace the action-feedback contract |

### 6b. Motion Library & Shape Spec

Decision rules from [decision-rules.md](./decision-rules.md) are enforced here.

| Rule | Severity | Description |
|------|----------|-------------|
| `animation-from-library` | WARNING | Keyframes and animation classes must come from [animations-library.md](./animations-library.md) registry — no ad-hoc `@keyframes` |
| `morph-uses-library-tokens` | WARNING | Radius transitions must use `--duration-morph` + `--easing-morph`; lift/peel must use `--easing-peel` |
| `shape-spec-match` | ERROR | Component structure, radius tokens (outer/inner pair when Q5=yes), elevation, and motion bundle must match the resolved Shape Spec |
| `pattern-4-dual-radius` | ERROR | Pattern 4 surfaces with an inner well must set both `--radius-outer-*` and `--radius-inner-*` |
| `pattern-4-peel-exit` | WARNING | Pattern 4 dismiss/exit animations must use `peelOff`, not `fadeOut` |

### 7. Accessibility

| Rule | Severity | Description |
|------|----------|-------------|
| `aria-required-for-inputs` | ERROR | All `<input>`, `<textarea>`, `<select>` must have associated `<label>` or `aria-label` |
| `aria-invalid-on-error` | ERROR | Inputs in error state must have `aria-invalid="true"` |
| `error-has-role-alert` | ERROR | Error messages must have `role="alert"` or `aria-live="polite"` |
| `focus-visible-ring` | ERROR | Focus indicators must be visible (2px outline minimum) |
| `reduced-motion-support` | WARNING | Components with animations must respect `prefers-reduced-motion` |
| `contrast-ratio` | ERROR | Text must meet 4.5:1 contrast ratio (normal) or 3:1 (large text) |

### 8. Component Structure

| Rule | Severity | Description |
|------|----------|-------------|
| `no-divitis` | WARNING | Avoid unnecessary wrapper `<div>` elements. Use semantic HTML first |
| `semantic-html` | WARNING | Use `<button>`, `<a>`, `<article>`, `<section>`, `<nav>`, `<header>`, `<footer>` before `<div>` |
| `angular-standalone` | ERROR | All Angular components must be standalone |
| `angular-onpush` | ERROR | All Angular components must use `ChangeDetectionStrategy.OnPush` |
| `angular-signal-inputs` | WARNING | Prefer signal-based `input()` and `output()` over `@Input()`/`@Output()` decorators |

**Scoping**: `angular-*` rules apply only to Angular components (`@Component` files). React targets use function components under the dependency budget in [frameworks/react.md](./frameworks/react.md) (no dedicated React structure rules beyond shared rules above; `react-minimal-deps` is a review checklist item, not an automated rule).

### 9. CSS Architecture

| Rule | Severity | Description |
|------|----------|-------------|
| `no-important` | ERROR | Never use `!important`. Exception: `prefers-reduced-motion` guards only |
| `no-id-selectors` | ERROR | Never use ID selectors for styling |
| `max-nesting-depth` | WARNING | CSS nesting depth must not exceed 3 levels |
| `contain-layout` | INFO | Components with animations should use `contain: layout style` |

### 10. Reaction Design (review-level)

Timing, weight, and interruption rules from [reactions.md](./reactions.md) are judgment checks — review them; most are not automatable.

| Check | Severity | Description |
|-------|----------|-------------|
| `reaction-within-budget` | WARNING (review) | Dispatch ack ≤100ms; settled feedback ≤1s; long ops show progress/cancel and terminate `success\|error\|timeout` |
| `reaction-weight-match` | WARNING (review) | No modal for non-blocking feedback; no transient toast as the only surface for blocking failure; success never blocks |
| `no-silent-wait` | ERROR | Waits/backoff/timeouts must be visible (spinner, countdown, progress) — aligns with Retry Contract |
| `prefer-undo-over-confirm` | WARNING (review) | Confirmation dialogs only for irreversible/high-cost actions; reversible actions offer undo |
| `same-action-same-reaction` | WARNING (review) | Identical triggers produce identical reaction skeletons across the product |

## Configuration

### eslint-plugin-design (Conceptual)

```json
{
  "plugins": ["@design"],
  "rules": {
    "@design/no-hardcoded-colors": "error",
    "@design/no-hardcoded-spacing": "error",
    "@design/no-hardcoded-radius": "error",
    "@design/no-hardcoded-motion": "error",
    "@design/no-decorative-gradients": "error",
    "@design/no-emoji-in-templates": "error",
    "@design/use-lucide-icons": "error",
    "@design/use-logical-properties": "error",
    "@design/has-focus-visible": "error",
    "@design/has-hover-state": "error",
    "@design/no-id-selectors": "error",
    "@design/no-transition-all": "warn",
    "@design/aria-required-for-inputs": "error",
    "@design/angular-standalone": "error",
    "@design/angular-onpush": "error",
    "@design/shape-spec-match": "error",
    "@design/pattern-4-dual-radius": "error",
    "@design/animation-from-library": "warn",
    "@design/morph-uses-library-tokens": "warn",
    "@design/pattern-4-peel-exit": "warn",
    "@design/async-action-has-loading": "error",
    "@design/retry-has-feedback": "warn",
    "@design/haptics-from-registry": "warn",
    "@design/no-haptic-as-sole-feedback": "warn",
    "@design/no-divitis": "warn",
    "@design/semantic-html": "warn",
    "@design/no-important": "error"
  }
}
```

### stylelint-config-design (Conceptual)

```json
{
  "extends": ["stylelint-config-design"],
  "rules": {
    "color-no-hex": [true, { "severity": "error", "message": "Use CSS variable tokens instead of hex colors" }],
    "declaration-property-unit-disallowed-list": {
      "margin": ["px"],
      "padding": ["px"]
    },
    "declaration-no-unknown": [true, { "severity": "error" }],
    "max-nesting-depth": [3, { "severity": "warning" }],
    "no-descending-specificity": [true, { "severity": "warning" }]
  }
}
```

## Enforcement Checklist

Before merging any UI code:

- [ ] All colors use CSS variable tokens
- [ ] No gradient backgrounds (except skeleton shimmer)
- [ ] No emojis in templates or labels
- [ ] All icons are Lucide icons
- [ ] Icon-only elements have `aria-label`
- [ ] Logical properties used (no physical direction properties)
- [ ] All interactive states defined (hover, focus-visible, disabled)
- [ ] Async/retry controls have loading state + attempt feedback (`async-action-has-loading`, `retry-has-feedback`)
- [ ] Focus indicators visible (2px outline)
- [ ] Error states have `role="alert"` or `aria-live`
- [ ] Angular components are standalone with OnPush
- [ ] Semantic HTML used before `<div>`
- [ ] No `!important` declarations (exception: `prefers-reduced-motion` guard only)
- [ ] No wholesale `opacity` hover on text-bearing components
- [ ] No `transition: all` — specify individual properties
- [ ] No ID selectors for styling
- [ ] CSS nesting depth <= 3
- [ ] Shape Spec resolved via decision-rules questionnaire and matched (`shape-spec-match`)
- [ ] Pattern 4: outer + inner radius tokens paired; morph uses `--duration-morph`/`--easing-morph`
- [ ] All animations from the animations library; motion values tokenized
- [ ] Reduced-motion guard present for animated components
- [ ] Haptics (if any) use registry events only and never stand alone as feedback (`haptics-from-registry`, `no-haptic-as-sole-feedback`)
- [ ] Reactions within time budgets; weight matches action; no silent waits; undo preferred over confirm for reversible acts (`reaction-within-budget`, `reaction-weight-match`, `no-silent-wait`, `prefer-undo-over-confirm`, `same-action-same-reaction` — see reactions.md)
- [ ] React targets (if any): dependency budget held — `react`, `react-dom`, `lucide-react` only (per frameworks/react.md)
