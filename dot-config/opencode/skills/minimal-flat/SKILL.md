---
name: minimal-flat
description: Generate HTML and CSS for Minimalist Flat Theme with Subtle Depth — a modern, clean interface using a strict dual-theme (Light/Dark) system with a restricted 3-5 color palette, flat backgrounds accented only by soft diffused box-shadows (no borders), and a moderate larger border radius. Use when building modern flat interfaces that emphasize content over chrome, restrict color palettes, and indicate elevation purely through shadow.
---

# Minimalist Flat Theme with Subtle Depth (Pattern 3)

A clean, modern interface utilizing a strict dual-theme (Light/Dark) system with a highly restricted color palette. The design relies on flat backgrounds accented only by soft, subtle box-shadows to indicate elevation and interactive states, avoiding harsh borders or excessive visual noise.

## When to Use

Best for modern, clean interfaces with restricted color palettes, subtle depth through shadows, and emphasis on content over chrome. Bordered, geometric multi-theme UIs use [multi-theme](../multi-theme/SKILL.md); typography-focused lists use [mono-tone-list](../mono-tone-list/SKILL.md); continuous-material surfaces use [morphic-surfaces](../morphic-surfaces/SKILL.md).

## Framework Detection

| Signals in project | Target |
|--------------------|--------|
| `angular.json` | Angular |
| `package.json` with `react` dependency | React |
| `pubspec.yaml` | Flutter |
| Multiple or none | Ask the user once; do not guess |

When ambiguous, ask: "Should I generate Angular, React, or Flutter code for this?"

Generate the **detected target's** implementation. Only fall back to vanilla JS when the target is ambiguous or explicitly requested.

## Pattern Specification

**Objective**: Implement clean, modern interface utilizing strict dual-theme (Light/Dark) system with a highly restricted color palette. The design relies on flat backgrounds accented only by soft, subtle box-shadows to indicate elevation and interactive states, avoiding harsh borders or excessive visual noise.

### Design Tokens

- **Color Discipline**: Agents MUST NOT introduce colors outside the defined 3-5 color palette. Gradients are prohibited.
- **Border Radius**: Use a moderate, modern border radius (`--border-radius-lg` or `--border-radius-xl`) to soften the flat design. It should be slightly larger than Pattern 1's `--border-radius`.
- **Elevation (Shadows)**: Do not use visible borders to separate main content areas. Instead, use very soft, diffused shadow for elevated elements (cards, modals).
  - Define theme-level soft elevation tokens (or override `--shadow-md`/`--shadow-lg` in the pattern theme) — do not write raw `box-shadow` values in component CSS.

### Minimal Color Palettes

Use these restricted palettes (3-5 colors maximum). Place values in your root theme stylesheet as CSS variables. Component CSS must always reference `var(--token-name)`.

**Clean Light**
| Token | Reference Value |
|-------|----------------|
| --bg-primary | #ffffff |
| --surface-primary | #f8f9fa |
| --text-primary | #212529 |
| --accent-primary | #0d6efd |

**Clean Dark**
| Token | Reference Value |
|-------|----------------|
| --bg-primary | #121212 |
| --surface-primary | #1e1e1e |
| --text-primary | #e0e0e0 |
| --accent-primary | #64b5f6 |

**Warm Light**
| Token | Reference Value |
|-------|----------------|
| --bg-primary | #fafaf8 |
| --surface-primary | #f5f5f0 |
| --text-primary | #2d2d2d |
| --accent-primary | #d97706 |

**Warm Dark**
| Token | Reference Value |
|-------|----------------|
| --bg-primary | #1a1814 |
| --surface-primary | #2d2a24 |
| --text-primary | #e8e4de |
| --accent-primary | #fbbf24 |

### Interactions

| State | Property | Token |
|-------|----------|-------|
| Hover (card) | box-shadow | `--shadow-hover` |
| Hover (link) | text-decoration | underline |
| Focus (all) | outline | `var(--border-focus-width, 2px) solid var(--accent-primary)` |
| Active (card) | box-shadow | `--shadow-active` |
| Disabled | opacity | 0.5 |

**Transitions** (all via motion tokens):
- Box shadow: `transition: box-shadow var(--duration-slow) var(--easing-default)`
- Text decoration: `transition: text-decoration-color var(--duration-normal) var(--easing-default)`
- Transform (if used): `transition: transform var(--duration-normal) var(--easing-default)`

## Design Tokens

Design tokens are the foundation. They are documented as references, not full CSS definitions.

### Visual Hierarchy Principles

1. **Typography Scale**: Font size, weight, and line height create reading order
2. **Color Opacity**: Text and element opacity indicate importance levels
3. **Spacing Rhythm**: Consistent spacing creates visual relationships

### Color Tokens

| Token Category | Token Names | Purpose |
|----------------|-------------|---------|
| **Background** | --bg-primary | Page background |
| **Surface** | --surface-primary | Card, modal backgrounds |
| **Text** | --text-primary | Headings, body |
| **Accent** | --accent-primary, --accent-hover | Interactive highlights |

**This pattern restricts to 3-5 colors maximum.** Only `--bg-primary`, `--surface-primary`, `--text-primary`, and `--accent-primary` (plus state tokens for feedback) are allowed. Gradients are prohibited.

### Text Opacity Hierarchy

| Level | Token | Opacity | Use Case |
|-------|-------|---------|----------|
| **Primary** | --text-primary | 100% | Headings, important labels |
| **Secondary** | --text-primary | 70% | Body text (opacity-derived) |
| **Tertiary** | --text-primary | 50% | Captions, metadata |
| **Disabled** | --text-primary | 30% | Inactive elements |

```css
:root {
  --text-primary: rgba(var(--text-color-rgb), 1);
  --text-secondary: rgba(var(--text-color-rgb), 0.7);
  --text-tertiary: rgba(var(--text-color-rgb), 0.5);
  --text-disabled: rgba(var(--text-color-rgb), 0.3);
}
```

**Fallback for busy backgrounds**: use a semi-transparent overlay (`var(--bg-overlay)`) with solid color tokens at verified contrast (4.5:1 text, 3:1 large text).

### Typography Tokens

| Token | Size | Line Height | Use Case |
|-------|------|-------------|----------|
| --font-size-xs | 0.75rem | 1rem | Captions, labels |
| --font-size-sm | 0.875rem | 1.25rem | Secondary text |
| --font-size-base | 1rem | 1.5rem | Body text |
| --font-size-lg | 1.125rem | 1.75rem | Lead paragraphs |
| --font-size-xl | 1.25rem | 1.75rem | Subheadings, card titles |
| --font-size-2xl | 1.5rem | 2rem | Section headings |
| --font-size-3xl | 1.875rem | 2.25rem | Page titles |
| --font-size-4xl | 2.25rem | 2.5rem | Hero headings |
| --font-size-5xl | 3rem | 3rem | Display headings |
| --font-size-6xl | 3.75rem | 3.75rem | Large display |
| --font-size-7xl | 4.5rem | 4.5rem | Maximum display |

| Token | Weight | Use Case |
|-------|--------|----------|
| --font-weight-light | 300 | Large display text |
| --font-weight-normal | 400 | Body text |
| --font-weight-medium | 500 | Labels, navigation |
| --font-weight-semibold | 600 | Subheadings |
| --font-weight-bold | 700 | Headings |

**Font Family Tokens**: `--font-heading`, `--font-body`, `--font-mono`.

### Border Radius Tokens

| Token | Value | Use Case |
|-------|-------|----------|
| --border-radius-sm | 3px | Small elements |
| --border-radius | 5px | Standard elements |
| --border-radius-lg | 8px | Cards (**this pattern**) |
| --border-radius-xl | 12px | Large containers (**this pattern**) |
| --border-radius-full | 9999px | Pills, avatars |

**This pattern uses `--border-radius-lg` or `--border-radius-xl`** — a moderate, modern radius slightly larger than Pattern 1's `--border-radius`.

### Spacing Scale

| Token | Concept | Typical Use |
|-------|---------|-------------|
| --space-xs | Extra small | Tight padding |
| --space-sm | Small | Input padding |
| --space-md | Medium | Component padding |
| --space-lg | Large | Section padding |
| --space-xl | Extra large | Page sections |
| --space-2xl | Double extra large | Major layout divisions |
| --space-3xl | Triple extra large | Full-page sections |

### Elevation Tokens

| Token | Concept | Use Case |
|-------|---------|----------|
| --shadow-sm | Subtle | Resting flat elements |
| --shadow-md | Medium | Card resting state |
| --shadow-lg | Elevated | Card hover, dropdowns |
| --shadow-xl | Highest | Modals, dialogs |
| --shadow-hover | Interactive lift | Hover elevation |
| --shadow-active | Pressed | Active/pressed elevation |

Define elevation changes as theme-level tokens (`--shadow-hover`, `--shadow-active`). Never write raw `box-shadow` in component CSS.

### Border & Focus Tokens

| Token | Value | Use Case |
|-------|-------|----------|
| --border-focus-width | 2px | Focus indicator width |
| --border-focus-offset | 2px | Focus offset |
| --bg-overlay | rgba(0, 0, 0, 0.5) | Modal backdrops |

**This pattern uses no visible borders on main surfaces** — focus rings use `--accent-primary`.

### State Soft Tokens

`--state-success-soft`, `--state-warning-soft`, `--state-error-soft`, `--state-info-soft` — soft background tints for feedback surfaces.

### Size Tokens

`--size-sidebar` (250px), `--size-modal-max` (500px), `--size-toast-min` (300px), `--size-toast-max` (450px), `--size-icon-sm` (16px), `--size-spinner-sm` (20px), `--size-spinner-md` (40px), `--size-spinner-lg` (60px).

### Motion Tokens

| Token | Value | Use Case |
|-------|-------|----------|
| --duration-instant | 0ms | Immediate response |
| --duration-fast | 100ms | Micro-interactions |
| --duration-normal | 200ms | Standard transitions |
| --duration-slow | 300ms | Shadow/elevation transitions |
| --duration-slower | 500ms | Page transitions |
| --duration-spinner | 1000ms | Spinner cycle |
| --duration-loading | 1500ms | Skeleton shimmer cycle |

| Token | Value | Use Case |
|-------|-------|----------|
| --easing-default | cubic-bezier(0.4, 0, 0.2, 1) | Most transitions |
| --easing-in | cubic-bezier(0.4, 0, 1, 1) | Elements exiting |
| --easing-out | cubic-bezier(0, 0, 0.2, 1) | Elements entering |
| --easing-in-out | cubic-bezier(0.42, 0, 0.58, 1) | Symmetric animations |
| --easing-bounce | cubic-bezier(0.68, -0.55, 0.265, 1.55) | Playful emphasis |

### Z-index Scale

`--z-below` (-1), `--z-base` (0), `--z-above` (1), `--z-dropdown` (1000), `--z-sticky` (1020), `--z-fixed` (1030), `--z-overlay` (1040), `--z-modal` (1050), `--z-popover` (1060), `--z-tooltip` (1070), `--z-toast` (1080). Never use raw z-index values.

### Breakpoint Tokens (Desktop-First)

| Token | Value | Target |
|-------|-------|--------|
| --bp-xs | 0 | Mobile portrait |
| --bp-sm | 576px | Mobile landscape |
| --bp-md | 768px | Tablet |
| --bp-lg | 992px | Desktop |
| --bp-xl | 1200px | Large desktop |
| --bp-xxl | 1400px | Extra large desktop |

```css
/* Base styles for desktop */
@media (max-width: 992px) { }  /* Tablet and below */
@media (max-width: 768px) { }  /* Mobile portrait and below */
```

## Icon System — Lucide

All icons use [Lucide](https://lucide.dev/). No emoji, no Font Awesome, no custom SVG.

```bash
npm install lucide-angular   # Angular
npm install lucide-react     # React
```

| Rule | Example |
|------|---------|
| Decorative icons must have `aria-hidden` | `<ds-icon name="home" [attr.aria-hidden]="true" />` |
| Interactive icons must have `aria-label` | `<button aria-label="Close"><ds-icon name="x" /></button>` |
| Never use emoji as icons | No `✓` or `🎉`, always Lucide |

## Component Contracts

Components are documented as contracts specifying required elements, tokens, variants, and interactions. Contracts apply to every target (Angular, React, Flutter).

### Card (Core Component)

**Required Elements**: `<article>`, optional `<header>`, `<section>`, `<footer>`
**Required Tokens**: --bg-primary, --surface-primary, --shadow-md, --shadow-hover, --shadow-active
**Variants**:
- `elevated`: shadow-based depth, no border (**default**)
- `flat`: no shadow or border, background differentiation only

**Typography**: Title `--font-size-lg` semibold 100%; Subtitle `--font-size-sm` medium 70%; Body `--font-size-base` normal 100%; Caption `--font-size-xs` 50%.

**Interactions**:
- Hover: box-shadow `--shadow-md` → `--shadow-hover`
- Active: box-shadow → `--shadow-active`
- Focus: outline `var(--border-focus-width, 2px) solid var(--accent-primary)`
- Transition: `box-shadow var(--duration-slow) var(--easing-default)`

**States**: Default, Hover (elevated shadow), Focus (accent outline), Disabled (`opacity: 0.5`), Loading (skeleton/spinner).

**Accessibility**: `<article>` with optional `aria-label`; visible focus (2px minimum).

```css
.card {
  background: var(--surface-primary);
  border: none;
  border-radius: var(--border-radius-xl);
  box-shadow: var(--shadow-md);
  transition: box-shadow var(--duration-slow) var(--easing-default);
}

.card:hover {
  box-shadow: var(--shadow-hover);
}

.card:active {
  box-shadow: var(--shadow-active);
}

.card:focus-visible {
  outline: var(--border-focus-width, 2px) solid var(--accent-primary);
  outline-offset: var(--border-focus-offset, 2px);
}
```

**Angular** (standalone, OnPush, signals):

```typescript
@Component({
  selector: 'app-card',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <article [class]="cssClasses()" [attr.aria-label]="ariaLabel()"
      (mouseenter)="isHovered.set(true)" (mouseleave)="isHovered.set(false)"
      [tabindex]="clickable() ? 0 : null"
      (click)="clickable() && cardClick.emit()"
      (keydown.enter)="clickable() && cardClick.emit()">
      @if (title()) {
        <header class="card__header">
          <h3 class="card__title">{{ title() }}</h3>
          @if (subtitle()) { <p class="card__subtitle">{{ subtitle() }}</p> }
        </header>
      }
      <section class="card__body"><ng-content></ng-content></section>
    </article>
  `
})
export class CardComponent {
  title = input<string>();
  subtitle = input<string>();
  variant = input<'elevated' | 'flat'>('elevated');
  clickable = input(false);
  ariaLabel = input<string>();
  cardClick = output<void>();
  isHovered = signal(false);

  cssClasses = computed(() => ({
    'card': true,
    'card--elevated': this.variant() === 'elevated',
    'card--flat': this.variant() === 'flat',
    'card--hovered': this.isHovered(),
    'card--clickable': this.clickable()
  }));
}
```

### Button

**Required Elements**: `<button>` or `<a>` with button role
**Required Tokens**: --bg-primary, --text-primary, --accent-primary
**Variants**: `primary` (filled accent), `secondary` (surface-filled), `ghost` (text only), `danger`

**Interactions**: Hover background shift; Active `transform: scale(0.98)`; Focus accent outline; Disabled `opacity: 0.5`; Transition `background-color var(--duration-normal) var(--easing-default), transform var(--duration-fast) var(--easing-default), box-shadow var(--duration-normal) var(--easing-default)`.

**States**: Default, Hover, Active (dispatch ack), Focus, Disabled, Loading (spinner + `aria-busy`), Retrying (loading + attempt text), Failed.

**Accessibility**: visible focus; 44x44px touch target (24x24px minimum); disabled announced.

```css
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-sm);
  padding: var(--space-sm) var(--space-md);
  border: none;
  border-radius: var(--border-radius-lg);
  background: var(--surface-primary);
  color: var(--text-primary);
  font-size: var(--font-size-sm);
  font-weight: var(--font-weight-medium);
  cursor: pointer;
  transition: background-color var(--duration-normal) var(--easing-default),
              transform var(--duration-fast) var(--easing-default),
              box-shadow var(--duration-normal) var(--easing-default);
}

.btn--primary {
  background: var(--accent-primary);
  color: var(--text-on-accent, #ffffff);
}

.btn--primary:hover { box-shadow: var(--shadow-hover); }

.btn:active { transform: scale(0.98); box-shadow: var(--shadow-active); }

.btn:focus-visible {
  outline: var(--border-focus-width, 2px) solid var(--accent-primary);
  outline-offset: var(--border-focus-offset, 2px);
}

.btn:disabled { opacity: 0.5; cursor: not-allowed; }
```

### ListItem

**Required Elements**: `<li>` or `<a>` with listitem role
**Required Tokens**: --bg-primary, --text-primary, --surface-primary

**Interactions**: Hover background `--surface-primary`; Focus accent outline; Transition `background-color var(--duration-normal) var(--easing-default)`.

**Accessibility**: `role="listitem"` or `<li>`; decorative icons `aria-hidden="true"`.

### Navigation

**Required Elements**: `<nav>`, `<a>`
**Required Tokens**: --bg-primary, --text-primary, --accent-primary

**Interactions**: Hover background shift or underline; Active persistent accent; Focus accent outline; Transition `background-color var(--duration-normal) var(--easing-default), color var(--duration-normal) var(--easing-default)`.

**Accessibility**: `<nav>` with `aria-label`; active item `aria-current="page"`; arrow-key navigation for tabs.

### Input

**Required Elements**: `<label>`, `<input>` or `<textarea>`
**Required Tokens**: --bg-primary, --surface-primary, --text-primary, --border-focus
**Variants**: `text`, `textarea`, `select`

**This pattern**: inputs sit on `--surface-primary` with no border at rest; focus raises shadow or shows accent outline.

**Interactions**: Focus accent outline + shadow; Error `--state-error`; Disabled `opacity: 0.5`.

**Accessibility**: visible or `aria-label` label; errors via `aria-describedby`; required `aria-required="true"`.

```css
.input {
  width: 100%;
  padding: var(--space-sm) var(--space-md);
  border: none;
  border-radius: var(--border-radius-lg);
  background: var(--surface-primary);
  color: var(--text-primary);
  font-size: var(--font-size-base);
  transition: box-shadow var(--duration-normal) var(--easing-default),
              border-color var(--duration-normal) var(--easing-default);
}

.input:focus-visible {
  outline: none;
  box-shadow: 0 0 0 var(--border-focus-width, 2px) var(--accent-primary);
}

.input--error { box-shadow: 0 0 0 var(--border-focus-width, 2px) var(--state-error); }
```

### Link

**Required Elements**: `<a>` or link role
**Required Tokens**: --accent-primary, --text-primary

**Interactions**: Hover underline; Focus accent outline; Transition `background-color var(--duration-normal) var(--easing-default), color var(--duration-normal) var(--easing-default)`.

**Accessibility**: keyboard focusable; distinct from surrounding text.

### Modal/Dialog

**Required Elements**: `<dialog>` or `role="dialog"`, `<header>`, `<footer>`
**Required Tokens**: --bg-primary, --text-primary, --shadow-xl, --z-modal

**This pattern**: soft radius (`--border-radius-xl`), `--shadow-xl`, no border. Focus trap, `aria-modal="true"`, focus restored on close.

```css
.modal__content {
  background: var(--surface-primary);
  border-radius: var(--border-radius-xl);
  padding: var(--space-lg);
  max-inline-size: var(--size-modal-max);
  box-shadow: var(--shadow-xl);
  transform: scale(0.95);
  transition: transform var(--duration-normal) var(--easing-default);
}
```

### Toast/Notification

**Required Elements**: `role="status"` or `role="alert"`, optional close button
**Required Tokens**: --bg-primary, --text-primary, --state-*, --z-toast

**This pattern**: soft radius (`--border-radius-lg`), `--shadow-lg`, no border. Slide+fade enter/exit; `role="alert"` for errors (never auto-dismiss); Retry wiring per the Retry Contract.

### Tabs / Menu / Tooltip / Badge / Drawer

Apply the shared contracts below with soft-radius, shadow-only surfaces:

- **Tabs**: `role="tablist"`/`tab`/`tabpanel`; arrow keys; roving tabindex; `aria-selected`.
- **Menu**: `role="menu"`/`menuitem`; `--shadow-lg`; focus trap; Escape/outside close; `aria-haspopup="menu"`.
- **Tooltip**: trigger `aria-describedby`, `role="tooltip"`; show on hover AND keyboard focus; never sole source of critical info.
- **Badge**: `--state-*-soft` backgrounds; status conveyed by text not color alone.
- **Drawer**: `<aside>` or `role="dialog" aria-modal="true"`; `--shadow-xl`; focus trap; logical properties for edge.

### Table

**Required Elements**: `<table>`, `<thead>`, `<tbody>`, `<th scope>`
**Required Tokens**: --bg-primary, --surface-primary, --text-primary

**This pattern**: zebra/hover via `--surface-primary`, no borders.

```css
.table tbody tr:hover { background-color: var(--surface-primary); }
```

**Accessibility**: caption or `aria-label`; `scope` on headers.

## Motion Design

Motion principles and transition guidance. All durations and easings must use tokens — never raw ms/cubic-bezier.

### Transition Principles

1. **Purposeful**: Every animation has a purpose
2. **Quick**: Most transitions 100-300ms
3. **Smooth**: Appropriate easing tokens
4. **Respectful**: Honor `prefers-reduced-motion`
5. **Tokenized**: Never hardcode duration or easing

### Transition Properties

| Property | Duration Token | Easing Token |
|----------|----------------|--------------|
| `background-color` | --duration-normal | --easing-default |
| `color` | --duration-normal | --easing-default |
| `box-shadow` | --duration-slow | --easing-default |
| `transform` | --duration-normal | --easing-default |
| `opacity` | --duration-normal | --easing-default |
| `text-decoration-color` | --duration-normal | --easing-default |

### Elevation Motion (this pattern)

```css
.card {
  transition: box-shadow var(--duration-slow) var(--easing-default);
}
```

### Animation Guidelines

- Avoid flashing/blinking animations
- Keep animations under 5 seconds
- Prefer `transform` and `opacity`
- All keyframes and animation classes must come from the registry below

## Animations Library

Canonical registry. Framework-neutral: keyframes and `.anim-*` / state classes are plain CSS.

### Keyframe Registry

```css
@keyframes shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

@keyframes dotPulse {
  0%, 80%, 100% { transform: scale(0.6); opacity: 0.4; }
  40% { transform: scale(1); opacity: 1; }
}

@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
@keyframes fadeOut { from { opacity: 1; } to { opacity: 0; } }

@keyframes slideInUp {
  from { transform: translateY(100%); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

@keyframes slideOutDown {
  from { transform: translateY(0); opacity: 1; }
  to { transform: translateY(100%); opacity: 0; }
}

@keyframes slideInRight {
  from { transform: translateX(100%); opacity: 0; }
  to { transform: translateX(0); opacity: 1; }
}

@keyframes slideOutLeft {
  from { transform: translateX(0); opacity: 1; }
  to { transform: translateX(-100%); opacity: 0; }
}

@keyframes scaleIn { from { transform: scale(0.95); opacity: 0; } to { transform: scale(1); opacity: 1; } }
@keyframes scaleOut { from { transform: scale(1); opacity: 1; } to { transform: scale(0.95); opacity: 0; } }
```

### Utility Classes

| Class | Animation | Duration | Easing |
|-------|-----------|----------|--------|
| `.anim-fade-in` | fadeIn | --duration-normal | --easing-default |
| `.anim-fade-out` | fadeOut | --duration-normal | --easing-default |
| `.anim-slide-in-up` | slideInUp | --duration-slow | --easing-out |
| `.anim-slide-out-down` | slideOutDown | --duration-slow | --easing-in |
| `.anim-slide-in-right` | slideInRight | --duration-slow | --easing-out |
| `.anim-slide-out-left` | slideOutLeft | --duration-slow | --easing-in |
| `.anim-scale-in` | scaleIn | --duration-normal | --easing-out |
| `.anim-scale-out` | scaleOut | --duration-normal | --easing-in |
| `.anim-spin` | spin | --duration-spinner | linear |
| `.anim-shimmer` | shimmer | --duration-loading | linear |
| `.anim-dot-pulse` | dotPulse | --duration-spinner | ease-in-out |

### AnimationPort (Domain Layer)

```typescript
export interface AnimationPort {
  fadeIn(target: string, duration?: number): AnimationResult;
  fadeOut(target: string, duration?: number): AnimationResult;
  slideIn(target: string, direction: 'up' | 'down' | 'left' | 'right', duration?: number): AnimationResult;
  slideOut(target: string, direction: 'up' | 'down' | 'left' | 'right', duration?: number): AnimationResult;
  scaleIn(target: string, duration?: number): AnimationResult;
  scaleOut(target: string, duration?: number): AnimationResult;
  spin(target: string, duration?: number): AnimationResult;
  stop(animation: AnimationResult): void;
}
```

`AnimationService` (Angular adapter) implements this with `AnimationBuilder`. React toggles `.is-entering`/`.is-exiting` + `onAnimationEnd`. Flutter maps to `AnimatedOpacity`/`SlideTransition`/`AnimatedContainer`.

### Declarative Angular Triggers

```typescript
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

### Reduced Motion Policy

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
  .anim-shimmer { animation: none; }
  .spinner { animation: none; }
}
```

### Performance Guidelines

1. Prefer `transform` and `opacity` (GPU-accelerated)
2. Avoid animating `width`, `height`, `top`, `left`
3. Use `will-change` sparingly
4. Use `contain: layout style` on animated components
5. Batch DOM reads/writes

## Accessibility Requirements (WCAG AA)

### ARIA Roles by Component

| Component | ARIA Role | Additional Attributes |
|-----------|-----------|----------------------|
| Card | `article` | `aria-label` if no heading |
| Button | `button` | `aria-disabled` |
| Navigation | `navigation` | `aria-label` |
| Input | `textbox` | `aria-required`, `aria-invalid`, `aria-describedby` |
| Modal | `dialog` | `aria-modal`, `aria-labelledby` |
| Tab | `tab` | `aria-selected`, `aria-controls` |

### Contrast Requirements

| Element Type | Minimum Contrast |
|--------------|------------------|
| Normal text (<18px) | 4.5:1 |
| Large text (≥18px or ≥14px bold) | 3:1 |
| UI components & graphics | 3:1 |
| Focus indicators | 3:1 |

**This pattern's restricted palette makes contrast critical** — verify accent-on-background and text-on-accent ratios with the provided palette values (e.g., `#0d6efd` on `#ffffff` = 4.54:1 ✓).

### Target Sizes

| Element Type | Minimum | Recommended |
|--------------|---------|-------------|
| Interactive elements | 24x24px | 44x44px |
| Touch targets | 44x44px | 48x48px |

### Keyboard Navigation

- All interactive elements reachable via Tab
- Focus order follows visual order
- Visible focus indicator (2px accent outline minimum)
- Escape closes modals/dropdowns
- Arrow keys navigate composite widgets

### Focus Traps

Overlays must trap focus and restore to the trigger on close. **Angular**: CDK `cdkTrapFocus`/`FocusTrapFactory`. **React**: native `<dialog>.showModal()`. **Flutter**: `FocusScope`/`FocusTraversalGroup`.

### Focus Indicators

```css
:focus-visible {
  outline: var(--border-focus-width, 2px) solid var(--accent-primary);
  outline-offset: var(--border-focus-offset, 2px);
}
```

### Screen Reader Considerations

- Decorative icons: `aria-hidden="true"`
- Required fields: `aria-required="true"`
- Error messages: `aria-describedby`
- Live regions: `aria-live="polite"` for dynamic content

### Reduced Motion

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

### High Contrast Mode

```css
@media (forced-colors: active) {
  .btn { border: 2px solid ButtonText; }
  .card { border: 2px solid CanvasText; }
}
```

### Contrast Verification

1. L = 0.2126R + 0.7152G + 0.0722B (linearized)
2. Contrast ratio = (L1 + 0.05) / (L2 + 0.05)
3. Thresholds: 4.5:1 text, 3:1 large text/UI

## Responsive Design

### Desktop-First Strategy

Start with desktop layout and adapt downward. Shadows stay subtle at all sizes.

```css
.card-grid {
  display: grid;
  gap: var(--space-lg);
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
}

@media (max-width: 768px) {
  .card-grid { grid-template-columns: 1fr; }
}
```

### Angular CDK BreakpointObserver

Use `@angular/cdk/layout` in Angular; React uses a local `useMediaQuery` hook; Flutter uses `LayoutBuilder` + breakpoint helpers.

```typescript
isMobile = toSignal(
  this.breakpointObserver.observe(Breakpoints.Handset).pipe(map(result => result.matches)),
  { initialValue: false }
);
```

### Container Queries for Components

```css
.card-container { container-type: inline-size; }

@container (min-width: 400px) {
  .card { display: grid; grid-template-columns: 200px 1fr; }
}
```

### Fluid Typography

```css
:root {
  --font-size-base: clamp(1rem, 0.9rem + 0.25vw, 1.125rem);
  --font-size-lg: clamp(1.125rem, 1rem + 0.3vw, 1.375rem);
}
```

### Touch Considerations

- Minimum touch target 44x44px
- Minimum spacing between targets 8px
- Avoid hover-dependent interactions on touch (shadow elevation is progressive enhancement)

## Theme System

### Theme Switching Interface

```
ThemePort:
  - getCurrentTheme() -> Theme
  - setTheme(theme: Theme) -> void
  - getAvailableThemes() -> Theme[]
  - onThemeChange(callback) -> Unsubscribe
```

### Theme Implementation

- Root attribute `data-theme` or `body.theme-*`
- Interactive control updates the attribute
- Persist to localStorage
- Theme transitions: `transition: background-color var(--duration-slow) var(--easing-default), color var(--duration-slow) var(--easing-default);`
- Angular: `ThemeService` with signals; React: `ThemeContext`; Flutter: `ThemeExtension`

### Clean Light Theme

```css
:root {
  --bg-primary: #ffffff;
  --surface-primary: #f8f9fa;
  --text-primary: #212529;
  --accent-primary: #0d6efd;
  --accent-hover: #0b5ed7;
  --state-success: #198754;
  --state-warning: #ffc107;
  --state-error: #dc3545;
  --state-info: #0dcaf0;
  --state-success-soft: #d1e7dd;
  --state-warning-soft: #fff3cd;
  --state-error-soft: #f8d7da;
  --state-info-soft: #cff4fc;
  --shadow-sm: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
  --shadow-md: 0 0.5rem 1rem rgba(0, 0, 0, 0.15);
  --shadow-lg: 0 1rem 3rem rgba(0, 0, 0, 0.175);
  --shadow-xl: 0 1rem 3rem rgba(0, 0, 0, 0.25);
  --shadow-hover: 0 0.5rem 0.9375rem rgba(0, 0, 0, 0.08);
  --shadow-active: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.03);
  --bg-overlay: rgba(0, 0, 0, 0.5);
  --border-focus-width: 2px;
  --border-focus-offset: 2px;
  --border-radius-sm: 3px;
  --border-radius: 5px;
  --border-radius-lg: 8px;
  --border-radius-xl: 12px;
  --border-radius-full: 9999px;
  --space-xs: 0.25rem;
  --space-sm: 0.5rem;
  --space-md: 1rem;
  --space-lg: 1.5rem;
  --space-xl: 2rem;
  --font-size-xs: 0.75rem;
  --font-size-sm: 0.875rem;
  --font-size-base: 1rem;
  --font-size-lg: 1.125rem;
  --font-size-xl: 1.25rem;
  --font-size-2xl: 1.5rem;
  --font-size-3xl: 1.875rem;
  --font-weight-normal: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;
  --duration-fast: 100ms;
  --duration-normal: 200ms;
  --duration-slow: 300ms;
  --duration-spinner: 1000ms;
  --duration-loading: 1500ms;
  --easing-default: cubic-bezier(0.4, 0, 0.2, 1);
  --easing-in: cubic-bezier(0.4, 0, 1, 1);
  --easing-out: cubic-bezier(0, 0, 0.2, 1);
  --easing-in-out: cubic-bezier(0.42, 0, 0.58, 1);
  --z-dropdown: 1000;
  --z-overlay: 1040;
  --z-modal: 1050;
  --z-toast: 1080;
  --bp-sm: 576px;
  --bp-md: 768px;
  --bp-lg: 992px;
  --bp-xl: 1200px;
  --bp-xxl: 1400px;
  --size-sidebar: 250px;
  --size-modal-max: 500px;
  --size-toast-min: 300px;
  --size-toast-max: 450px;
  --size-icon-sm: 16px;
  --size-spinner-sm: 20px;
  --size-spinner-md: 40px;
  --size-spinner-lg: 60px;
}
```

### Clean Dark Theme

```css
[data-theme="dark"] {
  --bg-primary: #121212;
  --surface-primary: #1e1e1e;
  --text-primary: #e0e0e0;
  --accent-primary: #64b5f6;
  --accent-hover: #90caf9;
  --shadow-sm: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.5);
  --shadow-md: 0 0.5rem 1rem rgba(0, 0, 0, 0.6);
  --shadow-lg: 0 1rem 3rem rgba(0, 0, 0, 0.7);
  --shadow-xl: 0 1rem 3rem rgba(0, 0, 0, 0.8);
  --shadow-hover: 0 0.5rem 0.9375rem rgba(0, 0, 0, 0.5);
  --shadow-active: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.4);
  --bg-overlay: rgba(0, 0, 0, 0.6);
}
```

### Warm Theme

**Warm Light**: `--bg-primary: #fafaf8`, `--surface-primary: #f5f5f0`, `--text-primary: #2d2d2d`, `--accent-primary: #d97706`, `--accent-hover: #b45309`.
**Warm Dark**: `--bg-primary: #1a1814`, `--surface-primary: #2d2a24`, `--text-primary: #e8e4de`, `--accent-primary: #fbbf24`, `--accent-hover: #fcd34d`.

### Angular ThemeService

```typescript
@Injectable({ providedIn: 'root' })
export class ThemeService {
  private readonly STORAGE_KEY = 'theme';
  readonly currentTheme = signal<Theme>(this.getInitialTheme());
  readonly availableThemes: Theme[] = ['light', 'dark'];

  constructor(@Inject(PLATFORM_ID) private platformId: Object) {
    effect(() => {
      const theme = this.currentTheme();
      if (isPlatformBrowser(this.platformId)) {
        document.documentElement.setAttribute('data-theme', theme);
        localStorage.setItem(this.STORAGE_KEY, theme);
      }
    });
  }

  setTheme(theme: Theme): void { this.currentTheme.set(theme); }
  toggleTheme(): void { this.currentTheme.update(c => c === 'light' ? 'dark' : 'light'); }
}
```

### Theme Accessibility

- Keyboard-accessible toggle
- Announce theme changes to screen readers
- Test contrast in both light and dark (restricted palette — verify each)
- Respect `prefers-color-scheme`

## Internationalization

### Logical Properties

| Physical | Logical |
|----------|---------|
| `margin-left` | `margin-inline-start` |
| `margin-right` | `margin-inline-end` |
| `padding-left` | `padding-inline-start` |
| `padding-right` | `padding-inline-end` |
| `text-align: left` | `text-align: start` |
| `text-align: right` | `text-align: end` |

### RTL Support

```css
[dir="rtl"] { direction: rtl; }
```

### Text Expansion

Languages can expand 200%+: use `min-width` not fixed width; flexbox/grid for automatic resizing; test with pseudo-localization.

### Number & Date Formatting

Use `Intl.NumberFormat` / `Intl.DateTimeFormat` with locale. `font-variant-numeric: tabular-nums` for alignment.

### Bidirectional Text

Use `unicode-bidi: plaintext` for auto-detect; `dir` attribute for forced direction.

## Usability Principles (Nielsen)

1. **Visibility of System Status** — loading indicators, success/error feedback, retry attempt counter
2. **Match Between System and Real World** — user language, recognized icons
3. **User Control and Freedom** — undo/redo, clear exits, Escape
4. **Consistency and Standards** — same component behaves same way everywhere
5. **Error Prevention** — input constraints, sensible defaults
6. **Recognition Rather than Recall** — persistent labels, visible actions
7. **Flexibility and Efficiency** — keyboard shortcuts
8. **Aesthetic and Minimalist Design** — this pattern's core: restricted palette, no visual noise
9. **Error Recovery** — clear messages, recovery paths
10. **Help and Documentation** — inline help, tooltips

## Architecture

### Angular

- **Standalone components** (Angular 15+), no NgModules
- **OnPush** change detection
- **Signals** for state; `input()`/`output()`
- **SCSS** with `:host` scoping; tokens via `var(--token)`
- **CDK** for layout and a11y
- **`@for (track ...)`** in lists

### React (React 19 baseline)

- **Function components** + hooks only
- **State**: `useState`/`useReducer`/`useContext`/`useMemo`
- **Async**: `useOptimistic`/`useActionState`/`useTransition` + `fetch`
- **Styling**: CSS variables + CSS Modules (or SCSS)
- **Dependency budget**: `react`, `react-dom`, `lucide-react` only
- **Ports via Context**: `usePorts()`

### Flutter

- Tokens → `ThemeExtension`
- Ports → adapters
- Motion: `AnimatedContainer`/`AnimatedOpacity`/`SlideTransition`
- RTL via `Directionality`; logical geometry
- Reduced motion via `MediaQuery.disableAnimationsOf(context)`

### OOCSS Naming

```
Block: .card { }
Element: .card__header { }
Modifier: .card--elevated { }
State: .is-active { }
```

### CSS Architecture Rules

- `border-box` sizing globally
- Never `!important` (except `prefers-reduced-motion` guard)
- No ID selectors
- Max 3 levels of nesting
- Use classes, not tags, for styling
- Logical properties for RTL
- Desktop-first by default

## Loading States & Retry Contract

### Skeleton Screens

```css
.skeleton {
  background: linear-gradient(90deg,
    var(--surface-primary) 25%,
    var(--bg-primary) 50%,
    var(--surface-primary) 75%);
  background-size: 200% 100%;
  animation: shimmer var(--duration-loading) infinite;
  border-radius: var(--border-radius-lg);
}
```

### Progress Indicators

- **Determinate**: progress bar with `role="progressbar"`, `aria-valuenow/min/max`
- **Indeterminate**: spinner (`animation: spin var(--duration-spinner) linear infinite`)

```css
.spinner {
  width: var(--size-spinner-md);
  height: var(--size-spinner-md);
  border: var(--border-width, 1px) solid var(--surface-primary);
  border-block-start-color: var(--accent-primary);
  border-radius: var(--border-radius-full);
  animation: spin var(--duration-spinner) linear infinite;
}
```

### Optimistic UI

**Angular**: signals + HttpClient with rollback. **React 19**: `useOptimistic` + `useTransition`. Rollback must surface a visible error (Retry Contract rule 6).

### Error States

- Validate on blur; error below input; `aria-describedby`; `aria-invalid="true"`
- Error format: `[Field Label] is required.` / `must be at least [X] characters.`
- Form error summary at top; focus first error field

### Retry Contract

**Every retry is a user action and must produce feedback** — visual/AT only; haptics are a separate optional channel.

```
press → dispatch ack (visual press state)
      → loading (spinner in control, aria-busy="true", control disabled)
      → settled:
           success → success feedback (toast/inline)
           failure → error surface + attempt counter; control re-enabled
```

Rules:

1. **Re-ack every attempt** — each retry press fires the dispatch ack again
2. **Attempt feedback** — "Retrying… (attempt N of M)" while pending
3. **Backoff is never silent** — visible countdown or manual-only retry
4. **Double-submit guard** — retry control disabled + `aria-busy` until settle
5. **First fail vs re-fail** — same error affordance; only attempt counter increments
6. **Rollback surfaces errors** — optimistic rollback emits visible error
7. **Announce outcomes** — `role="alert"`/`aria-live` on failure
8. **Bounded waits** — every wait terminates `success | error | timeout`; ops >1s get progress + cancel

### Loading Accessibility

`aria-busy="true"` on loading containers; `aria-live="polite"` for status; visible, contrasting indicators.

## Haptic Feedback (Optional Channel)

Haptics are a **separate optional channel** from visual/AT action feedback. Never the sole feedback.

### Event Registry

| Event | Meaning | Vibration (ms) | Typical trigger |
|-------|---------|----------------|-----------------|
| `tap` | Discrete commit ack | [10] | Button press |
| `select` | Selection changed | [5] | Checkbox, tab select |
| `retry-ack` | Retry accepted | [10] | Retry press (every attempt) |
| `success` | Positive terminal | [10, 50, 10] | Async success |
| `warning` | Caution terminal | [10, 40, 10] | Destructive confirm |
| `error` | Failure terminal | [30, 50, 30] | Settled failure |

### When to Fire

| Situation | Event | Notes |
|-----------|-------|-------|
| Control press (dispatch) | `tap` | Before async settles |
| Toggle/tab change | `select` | Once per commit |
| Retry press | `retry-ack` | Every attempt; NOT `success` |
| Async success | `success` | Once, terminal |
| Async failure | `error` | Once per settled failure |
| Loading / hover / focus | — | No haptics |

### HapticPort (Domain Layer)

```typescript
export type HapticEvent = 'tap' | 'select' | 'retry-ack' | 'success' | 'warning' | 'error';

export interface HapticPort {
  play(event: HapticEvent): void;
  isEnabled(): boolean;
  setEnabled(enabled: boolean): void;
}
```

Web adapter feature-detects `navigator.vibrate` and no-ops when unsupported/disabled. Flutter maps via `HapticFeedback`. Honor OS settings and `prefers-reduced-motion` as a conservative disable proxy.

## Reaction Design

Beyond *whether* feedback exists and *which channel* carries it — this governs **timing, weight, structure, and predictability**.

### Response-Time Budgets

| Budget | Threshold | Applies to |
|--------|-----------|------------|
| Dispatch ack | ≤ 100ms | Press → visual reaction |
| Settled result | ≤ 1s | Simple async |
| Extended operation | ≤ 10s | Long async (progress + cancel by 1s) |
| Timeout | Explicit, always | Never hang — settle as error |

### Reaction Weight = Action Weight

| Action class | Reaction weight |
|--------------|-----------------|
| Trivial, reversible | Micro: state change only, no toast |
| Background success | Inline confirm or quiet polite toast |
| Foreground result | Result rendered where user is looking |
| Destructive/irreversible | Confirm or undo window; assertive AT on failure |
| Blocking failure | Persistent inline error or non-auto-dismiss alert toast |

### Microinteraction Anatomy (Saffer)

```
trigger → rules → feedback → loop / mode (if needed)
```

### Non-Interruption Budget

| Level | Mechanism | When allowed |
|-------|-----------|--------------|
| Passive | Inline text/border/icon | Default |
| Polite | Toast `role="status"` | Background outcomes |
| Assertive | `role="alert"` | Cannot proceed until known |
| Blocking | Modal dialog | Destructive confirmation only |

### Key Rules

- **Undo over confirm** for reversible actions
- **Idempotency**: double-submit guard; debounce search 200-300ms; coalesce in-flight duplicates
- **Continuity**: continuous controls react continuously, settle on release
- **Cross-channel congruence**: channels separate but tell the same story
- **Same action → same reaction**: identical triggers produce identical reaction skeletons

## Design Lint Rules

### Token Enforcement

| Rule | Severity |
|------|----------|
| `no-hardcoded-colors` | ERROR |
| `no-hardcoded-spacing` | ERROR |
| `no-hardcoded-radius` | ERROR |
| `no-hardcoded-shadow` | ERROR |
| `no-hardcoded-font-size` | ERROR |
| `no-hardcoded-z-index` | ERROR |
| `no-hardcoded-motion` | ERROR |

**This pattern also enforces color discipline**: `color-palette-restricted` (ERROR) — no colors outside the defined 3-5 palette.

### No Gradients

`no-decorative-gradients`, `no-gradient-borders`, `no-gradient-text` — all ERROR. Exception: skeleton shimmer.

### No Emojis in UI

`no-emoji-in-templates` (ERROR), `no-emoji-in-labels` (ERROR), `no-emoji-in-strings` (WARNING). Use Lucide icons.

### Icons

`use-lucide-icons` (ERROR), `icon-has-label` (ERROR), `icon-is-decorative` (WARNING).

### Logical Properties

`use-logical-properties` (ERROR), `use-logical-text-align` (ERROR).

### Interaction States

`has-hover-state`, `has-focus-visible`, `has-disabled-state`, `has-transition`, `no-transition-all`, `no-wholesale-opacity-hover`, `async-action-has-loading` (ERROR), `retry-has-feedback`.

### Haptics

`haptics-from-registry` (WARNING), `no-haptic-as-sole-feedback` (WARNING).

### Accessibility

`aria-required-for-inputs`, `aria-invalid-on-error`, `error-has-role-alert`, `focus-visible-ring`, `reduced-motion-support`, `contrast-ratio`.

### Component Structure

`no-divitis`, `semantic-html`, `angular-standalone` (ERROR), `angular-onpush` (ERROR), `angular-signal-inputs`.

### CSS Architecture

`no-important` (ERROR), `no-id-selectors` (ERROR), `max-nesting-depth` (WARNING), `contain-layout` (INFO).

### Reaction Design (review-level)

`reaction-within-budget`, `reaction-weight-match`, `no-silent-wait` (ERROR), `prefer-undo-over-confirm`, `same-action-same-reaction`.

## Core Principles

1. **Minimal DOM Complexity** — flat HTML; no wrapper divs
2. **CSS Variables for All Colors** — never hardcode colors
3. **Restricted Palette** — never introduce colors outside the 3-5 color palette
4. **Accessibility by Default** — visible focus, WCAG AA, keyboard nav
5. **Progressive Enhancement** — base works without JS; enhanced layers on top
6. **Separation of Concerns** — HTML structure, CSS presentation, TS interactivity
7. **Consistent Token Usage** — never ad-hoc values
8. **Interaction Completeness** — hover/focus/active/disabled on every interactive element
9. **Responsive by Design** — desktop-first; container queries
10. **Theme Agnostic** — dual light/dark via CSS variables
11. **Performance Conscious** — transform/opacity; OnPush; `trackBy`
12. **Visual Hierarchy** — typography scale, opacity, spacing rhythm
13. **Opacity-Based Hierarchy** — text 100/70/50/30; interaction 100/90/80/50
14. **Internationalization Ready** — logical properties, text expansion, bidi
15. **Error Prevention** — validation, clear errors, recovery paths
16. **Progressive Disclosure** — show only what's needed
17. **Consistent Interaction Patterns** — similar components behave similarly
18. **Documentation as Code** — decisions documented via tokens/contracts
19. **Action Acknowledgement** — every action gets visual/AT feedback at dispatch; async shows pending → outcome; retries re-ack and surface settled outcome with attempt feedback; haptics are a separate optional channel
20. **Reaction Design** — feedback present *and* right: time budgets, weight match, microinteraction anatomy, escalation, undo over confirm, dedupe, continuity, congruence, identical reactions

## Usage

When generating UI code:

1. **Understand the context** — landing, dashboard, SaaS, e-commerce, content, portfolio
2. **Confirm the pattern** — this skill is Minimalist Flat Theme with Subtle Depth
3. **Apply all tokens** — restricted 3-5 palette, `--border-radius-lg`/`xl`, shadow-based elevation, no borders
4. **Follow component contracts** — Card is the core; shadow-driven elevation
5. **Implement all interaction states** (hover, focus, active, disabled) and the async lifecycle (ack → pending → success/error/retry)
6. **Use animations from the library** — shadow elevation, enter/leave
7. **Ensure accessibility** (WCAG AA, verify restricted-palette contrast) and **usability** (Nielsen)
8. **Apply haptics** (optional separate channel) on discrete commits only
9. **Tune the reaction** — time budgets, weight, undo-vs-confirm
10. **Verify against the Evaluation Rubric** before finalizing

## Evaluation Rubric

1. **Token Accuracy**: Are specific CSS values strictly applied without deviation?
2. **Color Discipline**: Is the palette restricted to 3-5 colors? No gradients?
3. **Structural Fidelity**: Does HTML follow required structure (semantic tags, no divitis)?
4. **Interaction Completeness**: Are all hover/focus/active/disabled states implemented? Do async controls implement the full lifecycle (ack → pending → success/error/retry)?
5. **Elevation**: Is depth expressed purely through soft shadows (`--shadow-*`), never borders?
6. **Theme Adaptability**: Do light/dark themes work via CSS variables only?
7. **Accessibility Compliance**: WCAG AA (contrast verified on restricted palette, keyboard, ARIA)?
8. **Usability Compliance**: Nielsen heuristics?
9. **Visual Hierarchy**: clear reading order through typography, opacity, spacing?
10. **Angular Idiomatic**: standalone, OnPush, signals, DI patterns?
11. **Lint Compliance**: no hardcoded values, no gradients, no emojis, Lucide only?
12. **Hexagonal Purity**: domain has zero framework imports; components depend on ports
13. **Motion Compliance**: animations from library, motion tokens, `prefers-reduced-motion`
14. **Consistency**: same answers ⇒ identical radius, elevation, structure, motion
15. **Action Feedback**: every action produces visual/AT feedback at dispatch with full async lifecycle — complete on its own, no dependence on haptics
16. **Haptics**: separate optional channel; registry events only; never sole feedback
17. **React Idiomatic** (React target): function components + hooks, React 19 builtins, minimal deps
18. **Reaction Design**: time budgets, weight match, microinteraction anatomy, interruption budget, undo over confirm, dedupe, continuity, congruence, identical reactions

## External References

### Design Systems
- <https://www.w3.org/WAI/WCAG21/quickref/> — WCAG 2.1 Quick Reference
- <https://carbondesignsystem.com/> — IBM Carbon Design System
- <https://material.io/design> — Google Material Design
- <https://developer.apple.com/design/human-interface-guidelines/> — Apple HIG
- <https://www.nngroup.com/articles/ten-usability-heuristics/> — Nielsen Norman

### CSS & Layout
- <https://css-tricks.com/snippets/css/a-guide-to-flexbox/> — Flexbox Guide
- <https://web.dev/learn/css/> — Learn CSS
- <https://www.w3.org/TR/css-logical-1/> — CSS Logical Properties

### Angular
- <https://angular.dev/guide/components> — Components Guide
- <https://angular.dev/guide/signals> — Signals
- <https://angular.dev/guide/animations> — Animations
- <https://angular.dev/guide/di> — Dependency Injection