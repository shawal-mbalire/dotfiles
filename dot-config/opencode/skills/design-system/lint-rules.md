# Design Lint Rules

Automated and reviewable rules for enforcing design system consistency. Inspired by shadcn/ui's approach to component linting.

## Rule Categories

### 1. Token Enforcement

Every CSS value must trace to a design token. No ad-hoc values.

| Rule | Severity | Description |
|------|----------|-------------|
| `no-hardcoded-colors` | ERROR | All color values must use `var(--token)`. Exception: `transparent`, `inherit`, `currentColor` |
| `no-hardcoded-spacing` | ERROR | All spacing must use `var(--space-*)` tokens. Exception: `0`, `auto`, `100%` |
| `no-hardcoded-radius` | ERROR | All border-radius must use `var(--border-radius-*)` tokens |
| `no-hardcoded-shadow` | ERROR | All box-shadow must use `var(--shadow-*)` tokens |
| `no-hardcoded-font-size` | ERROR | All font-size must use `var(--font-size-*)` tokens |
| `no-hardcoded-z-index` | ERROR | All z-index must use `var(--z-*)` tokens |

```css
/* BAD */
.card { background: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }

/* GOOD */
.card { background: var(--surface-primary); border-radius: var(--border-radius-lg); box-shadow: var(--shadow-md); }
```

### 2. No Gradients

Gradient colors are prohibited in component styles. Functional gradients (skeleton shimmer) are permitted.

| Rule | Severity | Description |
|------|----------|-------------|
| `no-decorative-gradients` | ERROR | `background: linear-gradient(...)` prohibited in component CSS |
| `no-gradient-borders` | ERROR | `border-image: linear-gradient(...)` prohibited |
| `no-gradient-text` | ERROR | `background-clip: text` with gradients prohibited |

**Exception**: Skeleton screen shimmer animation:
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
  animation: skeleton-shimmer 1.5s infinite;
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
| `has-hover-state` | WARNING | Interactive elements must have `:hover` styles |
| `has-focus-visible` | ERROR | Interactive elements must have `:focus-visible` styles |
| `has-disabled-state` | WARNING | Interactive elements must have `:disabled` or `[disabled]` styles |
| `has-transition` | WARNING | Interactive elements should have `transition` for state changes |

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

### 9. CSS Architecture

| Rule | Severity | Description |
|------|----------|-------------|
| `no-important` | ERROR | Never use `!important` |
| `no-id-selectors` | WARNING | Never use ID selectors for styling |
| `max-nesting-depth` | WARNING | CSS nesting depth must not exceed 3 levels |
| `contain-layout` | INFO | Components with animations should use `contain: layout style` |

## Configuration

### eslint-plugin-design (Conceptual)

```json
{
  "plugins": ["@design"],
  "rules": {
    "@design/no-hardcoded-colors": "error",
    "@design/no-hardcoded-spacing": "error",
    "@design/no-decorative-gradients": "error",
    "@design/no-emoji-in-templates": "error",
    "@design/use-lucide-icons": "error",
    "@design/use-logical-properties": "error",
    "@design/has-focus-visible": "error",
    "@design/aria-required-for-inputs": "error",
    "@design/angular-standalone": "error",
    "@design/angular-onpush": "error",
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
- [ ] Focus indicators visible (2px outline)
- [ ] Error states have `role="alert"` or `aria-live`
- [ ] Angular components are standalone with OnPush
- [ ] Semantic HTML used before `<div>`
- [ ] No `!important` declarations
- [ ] CSS nesting depth <= 3
