---
name: multi-theme
description: Generate HTML and CSS for Multi-Theme Containers & Controls — a strict, uniform geometric UI built on bordered structural elements (cards, buttons, inputs, sections, navigation) that switch between distinct color themes via CSS variables. Use when building applications that require multiple color palettes, consistent 1px borders, clear visual hierarchy through borders and shadows, or token-driven theme switching.
---

# Multi-Theme Containers & Controls (Pattern 1)

Structural UI elements (cards, buttons, sections, navigation) that support seamless switching between distinct color palettes while maintaining a strict, uniform geometric aesthetic.

## When to Use

Best for applications requiring multiple color themes, consistent geometric aesthetic, and clear visual hierarchy through borders and shadows. Typography-focused and border-light interfaces are better served by the [mono-tone-list](../mono-tone-list/SKILL.md) or [minimal-flat](../minimal-flat/SKILL.md) skills; continuous-material surfaces use [morphic-surfaces](../morphic-surfaces/SKILL.md).

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

**Objective**: Structural UI elements (cards, buttons, sections) that support seamless switching between distinct color palettes while maintaining a strict, uniform geometric aesthetic.

### Design Tokens

- **Border Radius**: Strict adherence to `var(--border-radius)` (5px) for all structural elements (cards, buttons, input fields). Do not use fully rounded/pill-shaped corners unless explicitly requested for a specific icon button.
- **Borders**: All containers, buttons, and distinct UI sections MUST have uniform border. Apply `border: var(--border-width) solid var(--border-primary)`.
- **Spacing**: Use mathematically even padding and margins (conceptual scale: xs, sm, md, lg) to ensure 1px borders align cleanly on the grid.
- **Colors**: NEVER hardcode color values in the component CSS. All backgrounds, text, and border colors must map to CSS variable tokens defined in the root theme stylesheet.

### Interactions

| State | Property | Value |
|-------|----------|-------|
| Hover (card) | box-shadow | increase elevation |
| Hover (button) | background-color | --accent-hover |
| Hover (link) | background-color | --surface-primary |
| Focus (all) | outline | `var(--border-focus-width, 2px) solid var(--border-focus)` |
| Active (button) | transform | scale(0.98) |
| Disabled | opacity | 0.5 |

**Transitions** (all via motion tokens):
- Background color: `transition: background-color var(--duration-normal) var(--easing-default)`
- Box shadow: `transition: box-shadow var(--duration-normal) var(--easing-default)`
- Transform: `transition: transform var(--duration-fast) var(--easing-default)`

## Design Tokens

Design tokens are the foundation. They are documented as references, not full CSS definitions.

### Visual Hierarchy Principles

1. **Typography Scale**: Font size, weight, and line height create reading order
2. **Color Opacity**: Text and element opacity indicate importance levels
3. **Spacing Rhythm**: Consistent spacing creates visual relationships

### Color Tokens

| Token Category | Token Names | Purpose |
|----------------|-------------|---------|
| **Background** | --bg-primary, --bg-secondary, --bg-tertiary | Page and container backgrounds |
| **Surface** | --surface-primary, --surface-secondary, --surface-elevated | Card, modal, dropdown backgrounds |
| **Text** | --text-primary, --text-secondary, --text-tertiary | Heading, body, caption text |
| **Text on Accent** | --text-on-accent | Text on accent-colored backgrounds |
| **Border** | --border-primary, --border-secondary, --border-focus | Structural borders, focus rings |
| **Accent** | --accent-primary, --accent-secondary, --accent-hover | Interactive element highlights |
| **State** | --state-success, --state-warning, --state-error, --state-info | Feedback and validation |

### Text Opacity Hierarchy

| Level | Token | Opacity | Use Case |
|-------|-------|---------|----------|
| **Primary** | --text-primary | 100% | Headings, important labels |
| **Secondary** | --text-secondary | 70% | Body text, descriptions |
| **Tertiary** | --text-tertiary | 50% | Captions, hints, metadata |
| **Disabled** | --text-disabled | 30% | Inactive elements, placeholders |

```css
:root {
  --text-primary: rgba(var(--text-color-rgb), 1);
  --text-secondary: rgba(var(--text-color-rgb), 0.7);
  --text-tertiary: rgba(var(--text-color-rgb), 0.5);
  --text-disabled: rgba(var(--text-color-rgb), 0.3);
}

/* Light theme */
[data-theme="light"] { --text-color-rgb: 33, 37, 41; }

/* Dark theme */
[data-theme="dark"] { --text-color-rgb: 248, 249, 250; }
```

**Fallback for busy backgrounds**: When text overlays images, do not use opacity-based hierarchy. Use a semi-transparent overlay (`var(--bg-overlay)`) with solid color tokens at verified contrast (4.5:1 text, 3:1 large text).

### Background Opacity Hierarchy

| Level | Token | Opacity | Use Case |
|-------|-------|---------|----------|
| **Base** | --bg-primary | 100% | Page background |
| **Surface** | --bg-secondary | 100% | Card backgrounds |
| **Overlay** | --bg-overlay | 50-80% | Modal backdrops |
| **Subtle** | --bg-subtle | 10-20% | Hover states |

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

**Typography Hierarchy Rules**: consistent size progression (h1 > h2 > h3); bold headings, normal body; tighter line height for headings, relaxed for body; tighter letter spacing for large text.

**Font Family Tokens**: `--font-heading`, `--font-body`, `--font-mono`.

### Border Radius Tokens

| Token | Value | Use Case |
|-------|-------|----------|
| --border-radius-sm | 3px | Badges, tags |
| --border-radius | 5px | Cards, buttons, inputs (**this pattern**) |
| --border-radius-lg | 8px | Elevated surfaces, modals |
| --border-radius-xl | 12px | Large containers |
| --border-radius-full | 9999px | Pills, avatars |

### Spacing Scale

| Token | Concept | Typical Use |
|-------|---------|-------------|
| --space-xs | Extra small | Tight padding, small gaps |
| --space-sm | Small | Input padding |
| --space-md | Medium | Component padding, card gaps |
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

Never write raw `box-shadow` values in component CSS — always use tokens.

### Border & Focus Tokens

| Token | Value | Use Case |
|-------|-------|----------|
| --border-width | 1px | Standard structural borders |
| --border-focus-width | 2px | Focus indicator width |
| --border-focus-offset | 2px | Focus offset |
| --bg-overlay | rgba(0, 0, 0, 0.5) | Modal backdrops |

### State Soft Tokens

`--state-success-soft`, `--state-warning-soft`, `--state-error-soft`, `--state-info-soft` — soft background tints for feedback surfaces.

### Size Tokens

`--size-sidebar` (250px), `--size-modal-max` (500px), `--size-toast-min` (300px), `--size-toast-max` (450px), `--size-icon-sm` (16px), `--size-spinner-sm` (20px), `--size-spinner-md` (40px), `--size-spinner-lg` (60px).

### Motion Tokens

| Token | Value | Use Case |
|-------|-------|----------|
| --duration-instant | 0ms | Immediate response |
| --duration-fast | 100ms | Micro-interactions (button press) |
| --duration-normal | 200ms | Standard transitions (hover) |
| --duration-slow | 300ms | Complex animations (modals) |
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
.container { max-inline-size: var(--bp-xl); }

/* Tablet and below */
@media (max-width: 1200px) { }
/* Mobile landscape and below */
@media (max-width: 992px) { }
/* Mobile portrait and below */
@media (max-width: 768px) { }
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
| Icon + text uses `gap` | `display: flex; gap: var(--space-sm)` |
| Never use emoji as icons | No `✓` or `🎉`, always Lucide |

Common Lucide names: `home`, `menu`, `chevron-left/right`, `arrow-left/right`, `check`, `x`, `plus`, `minus`, `edit`, `trash-2`, `copy`, `download`, `check-circle`, `alert-circle`, `alert-triangle`, `info`, `loader`, `play`, `pause`, `search`, `filter`, `grid`, `list`, `mail`, `message-circle`, `bell`, `send`.

## Component Contracts

Components are documented as contracts specifying required elements, tokens, variants, and interactions. Contracts apply to every target (Angular, React, Flutter).

### Component Opacity States

| State | Opacity |
|-------|---------|
| Default | 100% |
| Hover | 90% |
| Active | 80% |
| Disabled | 50% |
| Loading / Retrying | 70% |
| Failed | 100% (error affordance visible, not dimmed) |

### Card

**Required Elements**: `<article>`, optional `<header>`, `<section>`, `<footer>`
**Required Tokens**: --bg-primary, --border-primary, --shadow-md
**Variants**: `elevated` (shadow depth, no border), `bordered` (visible border, minimal shadow), `flat` (no shadow/border)

**Typography**: Title `--font-size-lg` semibold 100%; Subtitle `--font-size-sm` medium 70%; Body `--font-size-base` normal 100%; Caption `--font-size-xs` 50%.

**Interactions**: Hover shadow `--shadow-md` → `--shadow-lg`; Focus 2px outline; Transition `box-shadow var(--duration-slow) var(--easing-default)`.

**States**: Default, Hover, Focus, Disabled (`opacity: 0.5`), Loading (skeleton/spinner overlay).

**Accessibility**: `<article>` with optional `aria-label`; visible focus indicator (2px minimum).

**Angular** (standalone, OnPush, signals):

```typescript
import { Component, ChangeDetectionStrategy, input, output, signal, computed } from '@angular/core';

@Component({
  selector: 'app-card',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <article [class]="cssClasses()" [attr.aria-label]="ariaLabel()"
      (mouseenter)="isHovered.set(true)" (mouseleave)="isHovered.set(false)"
      (focus)="isHovered.set(true)" (blur)="isHovered.set(false)"
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
  variant = input<'elevated' | 'bordered' | 'flat'>('elevated');
  clickable = input(false);
  ariaLabel = input<string>();
  cardClick = output<void>();
  isHovered = signal(false);

  cssClasses = computed(() => ({
    'card': true,
    'card--elevated': this.variant() === 'elevated',
    'card--bordered': this.variant() === 'bordered',
    'card--flat': this.variant() === 'flat',
    'card--hovered': this.isHovered(),
    'card--clickable': this.clickable()
  }));
}
```

### Button

**Required Elements**: `<button>` or `<a>` with button role
**Required Tokens**: --bg-primary, --text-primary, --accent-primary, --border-primary
**Variants**: `primary` (filled accent), `secondary` (outlined), `ghost` (text only), `danger`

**Typography**: Label `--font-size-sm` medium 100%; Icon `--font-size-base` 100%; Helper `--font-size-xs` 70%.

**Interactions**: Hover background shift; Active `transform: scale(0.98)`; Focus 2px outline; Disabled `opacity: 0.5`, `cursor: not-allowed`; Transition `background-color var(--duration-normal) var(--easing-default), transform var(--duration-fast) var(--easing-default), box-shadow var(--duration-normal) var(--easing-default)`.

**States**: Default, Hover, Active (dispatch ack — visual), Focus, Disabled, Loading (spinner + `aria-busy="true"`, disabled double-submit guard), Retrying (loading + attempt text), Failed (re-enabled for next retry).

**Accessibility**: visible focus; 44x44px touch target (24x24px minimum, WCAG 2.5.8); disabled announced to screen readers.

**Angular**:

```typescript
@Component({
  selector: 'app-button',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (loading()) { <span class="spinner spinner--sm" aria-hidden="true"></span> }
    <ng-content></ng-content>
  `
})
export class ButtonComponent {
  variant = input<'primary' | 'secondary' | 'ghost' | 'danger'>('primary');
  size = input<'sm' | 'md' | 'lg'>('md');
  disabled = input(false);
  loading = input(false);
  buttonClick = output<MouseEvent>();

  @HostBinding('class') get hostClasses() { return `btn btn--${this.variant()} btn--${this.size()}`; }
  @HostBinding('attr.disabled') get nativeDisabled() { return this.disabled() || this.loading() ? '' : null; }
  @HostBinding('attr.aria-disabled') get ariaDisabled() { return this.disabled() || this.loading() ? 'true' : null; }
  @HostBinding('attr.aria-busy') get ariaBusy() { return this.loading() ? 'true' : null; }

  @HostListener('click', ['$event'])
  onClick(event: MouseEvent) {
    if (!this.disabled() && !this.loading()) this.buttonClick.emit(event);
  }
}
```

**React** (zero extra deps, React 19):

```tsx
export function Button({ variant = 'primary', size = 'md', disabled = false, loading = false, onButtonClick, children }: ButtonProps) {
  const inactive = disabled || loading;
  return (
    <button type="button"
      className={[styles.btn, styles[`btn--${variant}`], styles[`btn--${size}`], loading ? styles['btn--loading'] : ''].filter(Boolean).join(' ')}
      disabled={inactive}
      aria-disabled={inactive || undefined}
      aria-busy={loading || undefined}
      onClick={(e) => { if (!inactive) onButtonClick?.(e); }}>
      {loading && <span className="spinner spinner--sm" aria-hidden="true" />}
      {children}
    </button>
  );
}
```

### ListItem

**Required Elements**: `<li>` or `<a>` with listitem role
**Required Tokens**: --bg-primary, --text-primary, --border-secondary

**Typography**: Number `--font-size-sm` bold 50%; Title `--font-size-base` medium 100%; Subtitle `--font-size-sm` normal 70%; Icon `--font-size-base` 50%.

**Interactions**: Hover background `--surface-primary`; Arrow `translateX(4px)` on row hover; Focus 2px outline; Transition `background-color var(--duration-normal) var(--easing-default), transform var(--duration-normal) var(--easing-default)`.

**Accessibility**: `role="listitem"` or `<li>`; arrow and number `aria-hidden="true"` (decorative).

### Navigation

**Required Elements**: `<nav>`, `<a>`
**Required Tokens**: --bg-primary, --text-primary, --border-primary
**Variants**: `horizontal`, `vertical`, `tabs`

**Interactions**: Hover background shift or underline; Active persistent accent/border; Focus 2px outline; Transition `background-color var(--duration-normal) var(--easing-default), border-color var(--duration-normal) var(--easing-default)`.

**Accessibility**: `<nav>` with `aria-label`; active item `aria-current="page"`; arrow-key navigation for tabs.

### Input

**Required Elements**: `<label>`, `<input>` or `<textarea>`
**Required Tokens**: --bg-primary, --text-primary, --border-primary, --border-focus
**Variants**: `text`, `textarea`, `select`

**Typography**: Label `--font-size-sm` medium; Input `--font-size-base`; Placeholder `--text-tertiary` 50%; Helper `--font-size-xs` 70%; Error `--font-size-xs` medium `--state-error`.

**Interactions**: Focus border `--border-focus` + 2px outline; Error border `--state-error`; Disabled `opacity: 0.5`; Transition `border-color var(--duration-normal) var(--easing-default), box-shadow var(--duration-normal) var(--easing-default)`.

**Accessibility**: visible or `aria-label` label; errors via `aria-describedby`; required `aria-required="true"`.

**Reactivity note**: with OnPush, never wrap a raw `FormControl` in `computed()` alone — subscribe via `toSignal(control.statusChanges)` so error UI updates on validation.

### Link

**Required Elements**: `<a>` or link role
**Required Tokens**: --accent-primary, --text-primary
**Variants**: `inline`, `standalone`, `nav`

**Typography**: Link `--accent-primary` 100%; Hover `--accent-hover`; Visited `--accent-secondary` 70%.

**Interactions**: Hover underline/background; Focus 2px outline; Transition `background-color var(--duration-normal) var(--easing-default), color var(--duration-normal) var(--easing-default)`.

**Accessibility**: keyboard focusable; distinct from surrounding text; skip link for main content.

### Modal/Dialog

**Required Elements**: `<dialog>` or `role="dialog"`, `<header>`, `<footer>`
**Required Tokens**: --bg-primary, --text-primary, --shadow-xl, --z-modal
**Variants**: `default`, `fullscreen`, `confirmation`

**Interactions**: Open fade overlay + scale dialog; Close reverse; Backdrop/Escape close; focus trap (CDK `cdkTrapFocus` / React native `<dialog>`); restore focus on close; Transition `opacity var(--duration-normal) var(--easing-default), transform var(--duration-normal) var(--easing-default)`.

**Accessibility**: `role="dialog"` + `aria-modal="true"`; title via `aria-labelledby`; focus trapped; return focus to trigger; background scroll locked.

**Angular** uses `FocusTrapFactory` from `@angular/cdk/a11y`; **React** prefers native `<dialog>.showModal()`; **Flutter** uses `FocusScope`/`FocusTraversalGroup`.

### Toast/Notification

**Required Elements**: `role="status"` or `role="alert"`, optional icon, close button
**Required Tokens**: --bg-primary, --text-primary, --state-*, --z-toast
**Variants**: `success`, `warning`, `error`, `info`

**Interactions**: Enter slide+fade; Exit reverse; auto-dismiss 5-8s (pause on hover); Transition `transform var(--duration-slow) var(--easing-default), opacity var(--duration-slow) var(--easing-default)`.

**Accessibility**: `role="status"` non-critical / `role="alert"` error; `aria-live`; close button `aria-label="Dismiss"`; never auto-dismiss error toasts; error toasts offering Retry must wire the Retry Contract (see Loading & Retry section).

### Tabs

**Required Elements**: `role="tablist"`, `role="tab"`, `role="tabpanel"`
**Required Tokens**: --bg-primary, --text-primary, --accent-primary, --border-primary, --border-focus
**Variants**: `line`, `pill`, `enclosed`

**Accessibility**: arrow keys; roving tabindex; `aria-selected`, `aria-controls`, `aria-labelledby`; `aria-orientation="horizontal"`.

### Menu

**Required Elements**: `role="menu"`, `role="menuitem"`
**Required Tokens**: --surface-primary, --text-primary, --accent-primary, --shadow-lg, --z-dropdown

**Interactions**: fade+scale in; item hover highlight; Escape/outside click close; focus trap; restore focus on close; `aria-haspopup="menu"`, `aria-expanded`.

### Tooltip

**Required Elements**: trigger with `aria-describedby`, tooltip `role="tooltip"`
**Required Tokens**: --surface-elevated, --text-primary, --shadow-lg, --z-tooltip

**Interactions**: show on hover AND keyboard focus (never click-only); hide on blur/mouse-leave/Escape; ~`--duration-slow` delay in, none out.

**Accessibility**: never the only source of critical info; keyboard focus shows tooltip; no interactive content by default.

### Table

**Required Elements**: `<table>`, `<thead>`, `<tbody>`, `<th scope>`
**Required Tokens**: --bg-primary, --surface-primary, --text-primary, --border-primary

**Interactions**: row hover subtle background; sortable headers focus + `aria-sort`.

**Accessibility**: caption or `aria-label`; `scope` on headers.

### Badge

**Required Elements**: `<span>` with optional status text
**Required Tokens**: --state-*-soft (or --accent-primary), --text-primary, --border-radius-full
**Variants**: `success`, `warning`, `error`, `info`, `neutral`

**Accessibility**: status conveyed by text not color alone; `aria-label` if number-only.

### Drawer

**Required Elements**: `<aside>` or `role="dialog" aria-modal="true"`
**Required Tokens**: --surface-primary, --bg-overlay, --shadow-xl, --z-modal
**Variants**: `side` (inline-end/start), `bottom`

**Interactions**: slide in from edge + backdrop fade; Escape/backdrop close; focus trap; restore focus; logical properties for edge.

## Motion Design

Motion principles and transition guidance. All durations and easings must use tokens — never raw ms/cubic-bezier.

### When to Use Which

| Use Case | Approach |
|----------|----------|
| Hover/focus/active states | CSS transitions |
| Element enter/leave (`@if`, `*ngIf`) | `@angular/animations` |
| List animations | `animateChild()` + `query()` |
| Route transitions | `@routeAnimation` trigger |
| Simple show/hide | CSS transitions with `[class.hidden]` |

### Transition Principles

1. **Purposeful**: Every animation has a purpose (feedback, orientation, focus)
2. **Quick**: Most transitions 100-300ms
3. **Smooth**: Appropriate easing tokens
4. **Respectful**: Honor `prefers-reduced-motion`
5. **Tokenized**: Never hardcode duration or easing — always `var(--duration-*)` / `var(--easing-*)`

### Transition Properties

| Property | Duration Token | Easing Token |
|----------|----------------|--------------|
| `background-color` | --duration-normal | --easing-default |
| `color` | --duration-normal | --easing-default |
| `border-color` | --duration-normal | --easing-default |
| `box-shadow` | --duration-slow | --easing-default |
| `transform` | --duration-normal | --easing-default |
| `opacity` | --duration-normal | --easing-default |
| `width/height` | --duration-slow | --easing-default (avoid when possible) |

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
```

### Animation Guidelines

- Avoid animations that flash or blink
- Keep animations under 5 seconds
- Provide pause/stop controls for auto-playing animations
- Use `will-change` sparingly
- Prefer `transform` and `opacity`
- All keyframes and animation classes must come from the registry below

## Animations Library

Canonical registry. Framework-neutral: keyframes and `.anim-*` / state classes are plain CSS, identical for Angular, React, and web.

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

`AnimationService` (Angular adapter) implements this with `AnimationBuilder`. React toggles `.is-entering`/`.is-exiting` + `onAnimationEnd` with no animation library. Flutter maps to `AnimatedOpacity`/`SlideTransition`/`AnimatedContainer`.

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

```html
<div @fade *ngIf="visible()">Content</div>
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
| ListItem | `listitem` or `link` | `aria-current` |
| Navigation | `navigation` | `aria-label` |
| Input | `textbox` | `aria-required`, `aria-invalid`, `aria-describedby` |
| Modal | `dialog` | `aria-modal`, `aria-labelledby` |
| Tab | `tab` | `aria-selected`, `aria-controls` |
| Tab Panel | `tabpanel` | `aria-labelledby` |

### Contrast Requirements

| Element Type | Minimum Contrast |
|--------------|------------------|
| Normal text (<18px) | 4.5:1 |
| Large text (≥18px or ≥14px bold) | 3:1 |
| UI components & graphics | 3:1 |
| Focus indicators | 3:1 |

### Target Sizes

| Element Type | Minimum | Recommended |
|--------------|---------|-------------|
| Interactive elements | 24x24px | 44x44px |
| Touch targets | 44x44px | 48x48px |

### Keyboard Navigation

- All interactive elements reachable via Tab
- Focus order follows visual order
- Visible focus indicator (2px outline minimum)
- Escape closes modals/dropdowns
- Arrow keys navigate composite widgets

### Focus Traps

Overlays (modal, drawer, menu) must trap focus and restore to the trigger on close. **Angular**: CDK `cdkTrapFocus` / `FocusTrapFactory`. **React**: native `<dialog>.showModal()`. **Flutter**: `FocusScope`/`FocusTraversalGroup`.

### Focus Indicators

- Minimum 2px width
- Use `outline` or `box-shadow` (never `border`, avoids layout shift)
- Contrast ≥ 3:1
- Visible in light and dark themes

```css
:focus-visible {
  outline: var(--border-focus-width, 2px) solid var(--border-focus);
  outline-offset: var(--border-focus-offset, 2px);
}
```

### Screen Reader Considerations

- Decorative icons: `aria-hidden="true"`
- Decorative numbers: `aria-hidden="true"`
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

1. Calculate relative luminance: L = 0.2126R + 0.7152G + 0.0722B (linearized)
2. Contrast ratio = (L1 + 0.05) / (L2 + 0.05)
3. Verify thresholds: 4.5:1 text, 3:1 large text/UI

## Responsive Design

### Desktop-First Strategy

Start with desktop layout and adapt downward.

```css
/* Base: Desktop (1200px+) */
.grid { display: grid; grid-template-columns: repeat(3, 1fr); }

/* Tablet (992px and below) */
@media (max-width: 992px) { .grid { grid-template-columns: repeat(2, 1fr); } }

/* Mobile (768px and below) */
@media (max-width: 768px) { .grid { grid-template-columns: 1fr; } }
```

### Angular CDK BreakpointObserver

Use `@angular/cdk/layout` in Angular (not `window.matchMedia`); React uses a local `useMediaQuery` hook; Flutter uses `LayoutBuilder` + breakpoint helpers.

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
  --font-size-xl: clamp(1.25rem, 1rem + 0.5vw, 1.75rem);
}
```

### Touch Considerations

- Minimum touch target 44x44px
- Minimum spacing between targets 8px
- Consider thumb zones on mobile
- Avoid hover-dependent interactions on touch

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

- Root attribute `data-theme` or `body.theme-*` controls the global theme
- Interactive control updates the attribute
- Persist to localStorage
- Theme transitions: `transition: background-color var(--duration-slow) var(--easing-default), color var(--duration-slow) var(--easing-default);`
- Angular: `ThemeService` with signals; React: `ThemeContext` exposing theme name only; Flutter: `ThemeExtension`

### Light Theme (Default) CSS Variables

```css
:root {
  --bg-primary: #ffffff;
  --bg-secondary: #f8f9fa;
  --bg-tertiary: #e9ecef;
  --surface-primary: #ffffff;
  --surface-secondary: #f8f9fa;
  --surface-elevated: #ffffff;
  --text-primary: #212529;
  --text-secondary: #6c757d;
  --text-tertiary: #adb5bd;
  --text-on-accent: #ffffff;
  --border-primary: #dee2e6;
  --border-secondary: #e9ecef;
  --border-focus: #2563eb;
  --accent-primary: #0d6efd;
  --accent-secondary: #6ea8fe;
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
  --bg-overlay: rgba(0, 0, 0, 0.5);
  --border-width: 1px;
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
  --space-2xl: 3rem;
  --font-heading: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
  --font-body: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
  --font-mono: SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  --font-size-xs: 0.75rem;
  --font-size-sm: 0.875rem;
  --font-size-base: 1rem;
  --font-size-lg: 1.125rem;
  --font-size-xl: 1.25rem;
  --font-size-2xl: 1.5rem;
  --font-size-3xl: 1.875rem;
  --font-size-4xl: 2.25rem;
  --font-size-5xl: 3rem;
  --font-size-6xl: 3.75rem;
  --font-size-7xl: 4.5rem;
  --font-weight-light: 300;
  --font-weight-normal: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;
  --line-height-tight: 1.25;
  --line-height-normal: 1.5;
  --line-height-relaxed: 1.75;
  --duration-instant: 0ms;
  --duration-fast: 100ms;
  --duration-normal: 200ms;
  --duration-slow: 300ms;
  --duration-slower: 500ms;
  --duration-spinner: 1000ms;
  --duration-loading: 1500ms;
  --easing-default: cubic-bezier(0.4, 0, 0.2, 1);
  --easing-in: cubic-bezier(0.4, 0, 1, 1);
  --easing-out: cubic-bezier(0, 0, 0.2, 1);
  --easing-in-out: cubic-bezier(0.42, 0, 0.58, 1);
  --easing-bounce: cubic-bezier(0.68, -0.55, 0.265, 1.55);
  --z-below: -1;
  --z-base: 0;
  --z-above: 1;
  --z-dropdown: 1000;
  --z-sticky: 1020;
  --z-fixed: 1030;
  --z-overlay: 1040;
  --z-modal: 1050;
  --z-popover: 1060;
  --z-tooltip: 1070;
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

### Dark Theme

```css
[data-theme="dark"] {
  --bg-primary: #212529;
  --bg-secondary: #343a40;
  --bg-tertiary: #495057;
  --surface-primary: #343a40;
  --surface-secondary: #495057;
  --surface-elevated: #495057;
  --text-primary: #f8f9fa;
  --text-secondary: #adb5bd;
  --text-tertiary: #6c757d;
  --text-on-accent: #212529;
  --border-primary: #495057;
  --border-secondary: #6c757d;
  --border-focus: #93c5fd;
  --accent-primary: #6ea8fe;
  --accent-secondary: #9ec5fe;
  --accent-hover: #86b7fe;
  --state-success: #75b798;
  --state-warning: #ffda6a;
  --state-error: #ea868f;
  --state-info: #6edff6;
  --shadow-sm: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.25);
  --shadow-md: 0 0.5rem 1rem rgba(0, 0, 0, 0.35);
  --shadow-lg: 0 1rem 3rem rgba(0, 0, 0, 0.4);
  --shadow-xl: 0 1rem 3rem rgba(0, 0, 0, 0.5);
  --bg-overlay: rgba(0, 0, 0, 0.6);
}
```

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

  private getInitialTheme(): Theme {
    if (isPlatformBrowser(this.platformId)) {
      const stored = localStorage.getItem(this.STORAGE_KEY);
      if (stored === 'light' || stored === 'dark') return stored;
      if (window.matchMedia?.('(prefers-color-scheme: dark)').matches) return 'dark';
    }
    return 'light';
  }
}
```

### Theme Accessibility

- Keyboard-accessible toggle
- Announce theme changes to screen readers
- Focus visibility in both themes
- Test contrast in light and dark
- Respect `prefers-color-scheme`

## Internationalization

### Logical Properties

| Physical | Logical |
|----------|---------|
| `margin-left` | `margin-inline-start` |
| `margin-right` | `margin-inline-end` |
| `padding-left` | `padding-inline-start` |
| `padding-right` | `padding-inline-end` |
| `border-left` | `border-inline-start` |
| `border-right` | `border-inline-end` |
| `text-align: left` | `text-align: start` |
| `text-align: right` | `text-align: end` |

### RTL Support

```css
[dir="rtl"] { direction: rtl; }

.icon-left { margin-inline-end: var(--space-sm); }
.icon-right { margin-inline-start: var(--space-sm); }
```

### Text Expansion

Languages can expand 200%+ when translated: use `min-width` not fixed width; flexbox/grid for automatic resizing; test with pseudo-localization.

```css
/* Good - flexible width */
.button { min-width: 100px; padding: var(--space-sm) var(--space-md); }

/* Bad - fixed width */
.button { width: 150px; }
```

### Number & Date Formatting

Use `Intl.DateTimeFormat` / `Intl.NumberFormat` with locale. Use `font-variant-numeric: tabular-nums` for alignment.

### Bidirectional Text

Use `unicode-bidi: plaintext` for auto-detect; `dir` attribute for forced direction.

## Usability Principles (Nielsen)

1. **Visibility of System Status** — loading indicators, success/error feedback, processing states, retry feedback (attempt counter, no silent backoff), action acknowledgement
2. **Match Between System and Real World** — user language, recognized icons, natural reading patterns
3. **User Control and Freedom** — undo/redo, clear exits, confirm destructive actions
4. **Consistency and Standards** — same component behaves same way everywhere
5. **Error Prevention** — input constraints, sensible defaults, disable invalid options
6. **Recognition Rather than Recall** — persistent labels, visible actions
7. **Flexibility and Efficiency** — keyboard shortcuts, customization
8. **Aesthetic and Minimalist Design** — progressive disclosure, visual hierarchy
9. **Error Recovery** — clear messages, recovery paths
10. **Help and Documentation** — inline help, tooltips

## Architecture

### Angular

- **Standalone components** (Angular 15+), no NgModules
- **OnPush** change detection by default
- **Signals** for state (`signal()`, `computed()`), `input()`/`output()` (Angular 17+)
- **SCSS** with `:host` scoping; tokens via `var(--token)`
- **CDK** for layout (`BreakpointObserver`), a11y (`FocusTrapFactory`)
- **Reactive forms** with `Validators`
- **`trackBy`** in `*ngFor` / `@for (track ...)`

### React (React 19 baseline)

- **Function components** + hooks only
- **State**: `useState`/`useReducer`/`useContext`/`useMemo` — no external state library
- **Async**: `useOptimistic`/`useActionState`/`useTransition` + `fetch`
- **Styling**: CSS variables + CSS Modules (or SCSS) — no Tailwind/styled-components
- **Focus traps**: native `<dialog>.showModal()`
- **Dependency budget**: `react`, `react-dom`, `lucide-react` only
- **Ports via Context**: `usePorts()` — never import adapters in components

### Flutter

- Tokens → `ThemeExtension` + `ThemeData.extensions`
- Ports → adapters (`FlutterThemeAdapter`, etc.)
- Widgets inject ports, never concrete adapters
- Motion: `AnimatedContainer`/`AnimatedOpacity`/`SlideTransition`/`AnimationController`
- RTL via `Directionality`; logical geometry (`EdgeInsetsDirectional`)
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
    var(--surface-secondary) 50%,
    var(--surface-primary) 75%);
  background-size: 200% 100%;
  animation: shimmer var(--duration-loading) infinite;
  border-radius: var(--border-radius-sm);
}
```

### Progress Indicators

- **Determinate**: progress bar with `role="progressbar"`, `aria-valuenow/min/max`
- **Indeterminate**: spinner (`animation: spin var(--duration-spinner) linear infinite`) or dots loading

```css
.spinner {
  width: var(--size-spinner-md);
  height: var(--size-spinner-md);
  border: var(--border-width) solid var(--border-primary);
  border-block-start-color: var(--accent-primary);
  border-radius: var(--border-radius-full);
  animation: spin var(--duration-spinner) linear infinite;
}
```

### Optimistic UI

**Angular**: signals + HttpClient with rollback on error. **React 19**: `useOptimistic` + `useTransition`. Rollback must surface a visible error (Retry Contract rule 6).

### Button Loading

```css
.button--loading { position: relative; pointer-events: none; color: transparent; }

.button--loading::after {
  content: '';
  position: absolute;
  inset: 0;
  margin: auto;
  width: var(--size-icon-sm);
  height: var(--size-icon-sm);
  border: 2px solid transparent;
  border-block-start-color: currentColor;
  border-radius: var(--border-radius-full);
  animation: spin var(--duration-spinner) linear infinite;
}
```

### Error States

- Validate on blur; error below input; `aria-describedby`; `aria-invalid="true"`
- Error format: `[Field Label] is required.` / `must be at least [X] characters.`
- Form error summary at top; focus first error field
- Clear errors when user starts correcting

### Retry Contract

**Every retry is a user action and must produce feedback** — visual/AT only; haptics are a separate optional channel.

```
press → dispatch ack (visual press state)
      → loading (spinner in control, aria-busy="true", control disabled)
      → settled:
           success → success feedback (toast/inline)
           failure → error surface + attempt counter; control re-enabled for next retry
```

Rules:

1. **Re-ack every attempt** — each retry press fires the dispatch ack again
2. **Attempt feedback** — "Retrying… (attempt N of M)" while pending
3. **Backoff is never silent** — visible countdown ("Retry available in 4s") or manual-only retry
4. **Double-submit guard** — retry control disabled + `aria-busy` until settle
5. **First fail vs re-fail** — same error affordance; only attempt counter increments
6. **Rollback surfaces errors** — optimistic rollback emits visible error
7. **Announce outcomes** — `role="alert"`/`aria-live` on failure; polite live region for retrying
8. **Bounded waits** — every wait terminates `success | error | timeout`; ops >1s get progress + cancel

### Retry Control Sketch

```html
<button class="button" [attr.aria-busy]="retrying() || null"
  [disabled]="retrying() || backoffRemaining() > 0" (click)="onRetry()">
  @if (backoffRemaining() > 0) {
    <span>Retry in {{ backoffRemaining() }}s</span>
  } @else if (retrying()) {
    <span class="spinner spinner--sm" aria-hidden="true"></span>
    <span>Retrying… (attempt {{ attempt() }} of {{ maxAttempts() }})</span>
  } @else {
    <span>Retry</span>
  }
</button>
```

### Loading Accessibility

`aria-busy="true"` on loading containers; `aria-live="polite"` for status; visible, contrasting indicators.

## Haptic Feedback (Optional Channel)

Haptics are a **separate optional channel** from visual/AT action feedback. Never the sole feedback; never required for contract compliance.

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

Web adapter feature-detects `navigator.vibrate` and **no-ops silently** when unsupported (iOS Safari) or disabled. Flutter maps via `HapticFeedback` (lightImpact/selectionClick/notificationImpact/errorImpact). Honor OS settings and `prefers-reduced-motion` as a conservative disable proxy.

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

Never modal for non-interrupting feedback; never transient toast only for blocking failure.

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

Escalate one level at a time; success never blocks.

### Key Rules

- **Undo over confirm** for reversible actions; reserve confirm for irreversible + high-cost
- **Idempotency**: double-submit guard; debounce search 200-300ms; coalesce in-flight duplicates (dispatch ack still fires per press)
- **Continuity**: continuous controls react continuously (follows input, no lag), settle on release; never gate on network round-trip
- **Cross-channel congruence**: channels separate but tell the same story (success haptic never with visual error)
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
| `no-hardcoded-border-width` | ERROR |

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

`aria-required-for-inputs`, `aria-invalid-on-error`, `error-has-role-alert`, `focus-visible-ring`, `reduced-motion-support`, `contrast-ratio` — all ERROR except reduced-motion (WARNING).

### Component Structure

`no-divitis`, `semantic-html`, `angular-standalone` (ERROR), `angular-onpush` (ERROR), `angular-signal-inputs`.

### CSS Architecture

`no-important` (ERROR), `no-id-selectors` (ERROR), `max-nesting-depth` (WARNING), `contain-layout` (INFO).

### Reaction Design (review-level)

`reaction-within-budget`, `reaction-weight-match`, `no-silent-wait` (ERROR), `prefer-undo-over-confirm`, `same-action-same-reaction`.

## Core Principles

1. **Minimal DOM Complexity** — flat HTML; avoid "divitis"; semantic tags first; pseudo-elements for decoration
2. **CSS Variables for All Colors** — never hardcode colors
3. **Accessibility by Default** — visible focus, WCAG AA, keyboard nav, ARIA
4. **Progressive Enhancement** — base works without JS; enhanced layers on top; `@supports` detection
5. **Separation of Concerns** — HTML structure, CSS presentation, TS interactivity
6. **Consistent Token Usage** — never ad-hoc values
7. **Interaction Completeness** — hover/focus/active/disabled on every interactive element
8. **Responsive by Design** — desktop-first; container queries; CDK BreakpointObserver
9. **Theme Agnostic** — components work in any theme via CSS variables
10. **Performance Conscious** — transform/opacity; OnPush; `trackBy`
11. **Visual Hierarchy** — typography scale, color opacity, spacing rhythm
12. **Opacity-Based Hierarchy** — text 100/70/50/30; interaction 100/90/80/50
13. **Internationalization Ready** — logical properties, text expansion, bidi
14. **Error Prevention** — validation, clear errors, recovery paths
15. **Progressive Disclosure** — show only what's needed
16. **Consistent Interaction Patterns** — similar components behave similarly
17. **Documentation as Code** — decisions documented via tokens/contracts/patterns
18. **Action Acknowledgement** — every action gets visual (and AT) feedback at dispatch; async shows pending → outcome; retries re-ack, show loading (`aria-busy`), and surface settled outcome with attempt feedback; haptics are a separate optional channel
19. **Reaction Design** — feedback present *and* right: time budgets, weight match, microinteraction anatomy, escalation one level at a time, undo over confirm, deduplication, continuity, congruence, identical actions → identical reactions

## Usage

When generating UI code:

1. **Understand the context** — what type of interface? (landing, dashboard, SaaS, e-commerce, content, portfolio, docs, social, admin, onboarding)
2. **Confirm the pattern** — this skill is Multi-Theme Containers & Controls
3. **Apply all tokens** from the Design Tokens section — radius (`--border-radius`), elevation, motion
4. **Follow component contracts** — elements, tokens, variants, states
5. **Implement all interaction states** (hover, focus, active, disabled) and the async lifecycle (dispatch ack, pending, success, error, retry)
6. **Use animations from the library** — keyframes and utility classes only
7. **Ensure accessibility** (WCAG AA) and **usability** (Nielsen) requirements
8. **Apply haptics** (optional separate channel) on discrete commits only
9. **Tune the reaction** — time budgets, weight, interruption level, undo-vs-confirm
10. **Verify against the Evaluation Rubric** before finalizing

## Evaluation Rubric

1. **Token Accuracy**: Are specific CSS values strictly applied without deviation?
2. **Structural Fidelity**: Does HTML follow required nested structure (semantic tags, flexbox containers)?
3. **Interaction Completeness**: Are all hover/focus/active/disabled states implemented? Do async-triggering controls implement the full lifecycle (ack → pending → success/error/retry)?
4. **Theme Adaptability**: Are all color values via CSS variables, not hardcoded hex/RGB?
5. **Accessibility Compliance**: WCAG AA (contrast, keyboard, ARIA)?
6. **Usability Compliance**: Nielsen heuristics?
7. **Visual Hierarchy**: clear reading order through typography, opacity, spacing?
8. **Angular Idiomatic**: standalone, OnPush, signals, DI patterns?
9. **Angular Performance**: `trackBy`, no unnecessary re-renders?
10. **Lint Compliance**: no hardcoded values, no gradients, no emojis, Lucide only?
11. **Hexagonal Purity**: domain has zero framework imports; components depend on ports
12. **Motion Compliance**: animations from library, motion tokens, `prefers-reduced-motion`
13. **Consistency**: same answers ⇒ identical radius, elevation, structure, motion
14. **Action Feedback**: every action produces visual/AT feedback at dispatch with full async lifecycle — complete on its own, no dependence on haptics
15. **Haptics**: separate optional channel; registry events only; never sole feedback
16. **React Idiomatic** (React target): function components + hooks, React 19 builtins, minimal deps
17. **Reaction Design**: time budgets, weight match, microinteraction anatomy, interruption budget, undo over confirm, dedupe, continuity, congruence, identical reactions

## External References

### Design Systems
- <https://www.w3.org/WAI/WCAG21/quickref/> — WCAG 2.1 Quick Reference
- <https://carbondesignsystem.com/> — IBM Carbon Design System
- <https://material.io/design> — Google Material Design
- <https://developer.apple.com/design/human-interface-guidelines/> — Apple HIG
- <https://www.nngroup.com/articles/ten-usability-heuristics/> — Nielsen Norman

### CSS & Layout
- <https://css-tricks.com/snippets/css/a-guide-to-flexbox/> — Flexbox Guide
- <https://css-tricks.com/snippets/css/complete-guide-grid/> — Grid Guide
- <https://web.dev/learn/css/> — Learn CSS
- <https://www.w3.org/TR/css-logical-1/> — CSS Logical Properties

### Angular
- <https://angular.dev/guide/components> — Components Guide
- <https://angular.dev/guide/signals> — Signals
- <https://angular.dev/guide/animations> — Animations
- <https://angular.dev/guide/di> — Dependency Injection