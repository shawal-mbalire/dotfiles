---
name: mono-tone-list
description: Generate HTML and CSS for Interactive Numbered Lists (Mono Tone) — minimalist, typography-focused directory lists where items act as full-width interactive rows with zero-padded tabular numbers, horizontal separators, and a single-color-family palette. Use when building scannable directory-style lists, tables with row separators, typography-first interfaces, or minimalist UIs emphasizing clean rows and hover interactions over heavy containers.
---

# Interactive Numbered List (Mono Tone) (Pattern 2)

A minimalist, highly scannable directory list where items act as full-width interactive rows, emphasizing typography and clean hover interactions over heavy card containers. Uses a **mono tone** color scheme — single color family with varying lightness/darkness.

## When to Use

Best for minimalist, typography-focused interfaces where clean rows and hover interactions take precedence over heavy containers. Bordered, geometric multi-theme UIs use [multi-theme](../multi-theme/SKILL.md); flat, shadow-based minimal UIs use [minimal-flat](../minimal-flat/SKILL.md); continuous-material surfaces use [morphic-surfaces](../morphic-surfaces/SKILL.md).

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

**Objective**: Build a minimalist, highly scannable directory list where items act as full-width interactive rows, emphasizing typography and clean hover interactions over heavy card containers. Uses a mono tone color scheme — single color family with varying lightness/darkness.

### Design Tokens

- **Border Radius**: None. All elements have `border-radius: 0` for sharp, rectangular edges.
- **Borders**: 1px solid borders for horizontal separators only. Apply `border-bottom: 1px solid var(--border-secondary)` to row elements. No vertical borders.
- **Layout**: Apply `display: flex; align-items: center; justify-content: space-between;` on the main row container. Use smaller gap (e.g., `gap: 1rem`) for the inner `.left-group` flex container.
- **Separators**: Do not wrap items in individual bordered boxes. Instead, separate them using horizontal lines: apply `border-bottom: 1px solid var(--border-secondary)` to the row elements.
- **Typography**: Sequential numbers MUST be zero-padded (01, 02, 03...). Apply monospace or `font-variant-numeric: tabular-nums;` setting to the numbers so they align vertically across rows.
- **Colors**: All colors must use CSS variable tokens. No hardcoded values.
- **Mono Tone**: Use single color family (e.g., grays, blues) with varying lightness. No accent colors. Interaction states use opacity/lightness changes, not hue shifts.

### Mono Tone Color Palettes

**Important**: These values are theme definitions. Place them in your root theme stylesheet as CSS variables. Component CSS must always reference `var(--token-name)`, never the raw hex values.

**Gray Mono Tone**
| Token | Reference Value |
|-------|----------------|
| --bg-primary | #ffffff |
| --surface-primary | #f8f9fa |
| --text-primary | #212529 |
| --text-secondary | #6c757d |
| --border-primary | #dee2e6 |
| --border-secondary | #e9ecef |

**Blue Mono Tone**
| Token | Reference Value |
|-------|----------------|
| --bg-primary | #f8f9fa |
| --surface-primary | #e9ecef |
| --text-primary | #212529 |
| --text-secondary | #495057 |
| --border-primary | #ced4da |
| --border-secondary | #dee2e6 |

**Slate Mono Tone**
| Token | Reference Value |
|-------|----------------|
| --bg-primary | #f8fafc |
| --surface-primary | #f1f5f9 |
| --text-primary | #0f172a |
| --text-secondary | #475569 |
| --border-primary | #cbd5e1 |
| --border-secondary | #e2e8f0 |

### Interactions

| State | Property | Value |
|-------|----------|-------|
| Hover (row) | background-color | --surface-primary |
| Hover (arrow) | transform | translateX(4px) |
| Focus (row) | outline | `var(--border-focus-width, 2px) solid var(--border-focus)` |
| Active (row) | background-color | --surface-secondary |
| Disabled | opacity | 0.5 |

**Transitions** (all via motion tokens):
- Background color: `transition: background-color var(--duration-normal) var(--easing-default)`
- Transform: `transition: transform var(--duration-normal) var(--easing-default)`
- Combined: `transition: background-color var(--duration-normal) var(--easing-default), transform var(--duration-normal) var(--easing-default)`

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
| **Surface** | --surface-primary, --surface-secondary, --surface-elevated | Row, modal, dropdown backgrounds |
| **Text** | --text-primary, --text-secondary, --text-tertiary | Heading, body, caption text |
| **Border** | --border-primary, --border-secondary, --border-focus | Separators, focus rings |

**This pattern has no accent tokens.** Mono tone only — a single color family with varying lightness. Interaction states use opacity/lightness changes, not hue shifts.

### Text Opacity Hierarchy

| Level | Token | Opacity | Use Case |
|-------|-------|---------|----------|
| **Primary** | --text-primary | 100% | Titles, important labels |
| **Secondary** | --text-secondary | 70% | Subtitle, descriptions |
| **Tertiary** | --text-tertiary | 50% | Numbers, icons, metadata |
| **Disabled** | --text-disabled | 30% | Inactive elements |

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
| --font-size-xs | 0.75rem | 1rem | Captions, metadata |
| --font-size-sm | 0.875rem | 1.25rem | Numbers, secondary text |
| --font-size-base | 1rem | 1.5rem | Titles, body |
| --font-size-lg | 1.125rem | 1.75rem | Lead paragraphs |
| --font-size-xl | 1.25rem | 1.75rem | Subheadings |
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
| --font-weight-medium | 500 | Labels, titles |
| --font-weight-semibold | 600 | Subheadings |
| --font-weight-bold | 700 | Numbers, headings |

**Font Family Tokens**: `--font-heading`, `--font-body`, `--font-mono`. Use `--font-mono` or `font-variant-numeric: tabular-nums` for the zero-padded numbers.

### Border Radius Tokens

| Token | Value | Use Case |
|-------|-------|----------|
| --border-radius | 5px | Focus rings, minimal elements |
| --border-radius-full | 9999px | Spinners |

**This pattern uses `border-radius: 0`** on all row/list elements for sharp, rectangular edges.

### Spacing Scale

| Token | Concept | Typical Use |
|-------|---------|-------------|
| --space-xs | Extra small | Tight padding |
| --space-sm | Small | Row inner gaps |
| --space-md | Medium | Row padding |
| --space-lg | Large | List section padding |
| --space-xl | Extra large | Page sections |
| --space-2xl | Double extra large | Major layout divisions |
| --space-3xl | Triple extra large | Full-page sections |

### Elevation Tokens

| Token | Concept | Use Case |
|-------|---------|----------|
| --shadow-sm | Subtle | Dropdowns, overlays |
| --shadow-lg | Elevated | Menus, toasts |
| --shadow-xl | Highest | Modals |

Never write raw `box-shadow` values in component CSS — always use tokens.

### Border & Focus Tokens

| Token | Value | Use Case |
|-------|-------|----------|
| --border-width | 1px | Row separators |
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
| --duration-fast | 100ms | Micro-interactions |
| --duration-normal | 200ms | Row hover states |
| --duration-slow | 300ms | Modals, drawers |
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
@media (max-width: 992px) { }  /* Mobile landscape and below */
@media (max-width: 768px) { }  /* Mobile portrait and below */
```

## Icon System — Lucide

All icons use [Lucide](https://lucide.dev/). No emoji, no Font Awesome, no custom SVG. In this pattern, icons are typically limited to a single arrow affordance (`arrow-right`) at the row end.

| Rule | Example |
|------|---------|
| Decorative icons must have `aria-hidden` | `<ds-icon name="arrow-right" [attr.aria-hidden]="true" />` |
| Row arrows are decorative | `aria-hidden="true"`, never announced |
| Never use emoji as icons | No `→` or `📄`, always Lucide |

## Component Contracts

Components are documented as contracts specifying required elements, tokens, variants, and interactions. Contracts apply to every target (Angular, React, Flutter).

### ListItem (Core Component)

**Required Elements**: `<li>` or `<a>` with listitem role
**Required Tokens**: --bg-primary, --text-primary, --border-secondary
**Structure**:
- Left group: number + title
- Right group: action icon (optional)

**Typography**:
- **Number**: --font-size-sm, --font-weight-bold, --text-tertiary (50% opacity) — zero-padded (01, 02, 03), `font-variant-numeric: tabular-nums` or `--font-mono`
- **Title**: --font-size-base, --font-weight-medium, --text-primary (100% opacity)
- **Subtitle**: --font-size-sm, --font-weight-normal, --text-secondary (70% opacity)
- **Icon**: --font-size-base, --text-tertiary (50% opacity)

**Interactions**:
- Hover: background-color shift to --surface-primary
- Arrow animation: `transform: translateX(4px)` on row hover
- Focus: 2px outline ring
- Transition: `background-color var(--duration-normal) var(--easing-default), transform var(--duration-normal) var(--easing-default)`

**States**: Default, Hover (background highlight), Focus (visible outline), Active (pressed), Disabled (reduced opacity), Selected (persistent surface color).

**Accessibility**:
- Use `role="listitem"` or semantic `<li>`
- Arrow icon must have `aria-hidden="true"`
- Number must have `aria-hidden="true"` (decorative)

**Structure template**:

```html
<ul class="list" role="list">
  <li class="row">
    <a class="row__link" href="#item-1">
      <span class="row__left-group">
        <span class="row__number" aria-hidden="true">01</span>
        <span class="row__title">Item title</span>
      </span>
      <ds-icon name="arrow-right" class="row__arrow" [attr.aria-hidden]="true" />
    </a>
  </li>
</ul>
```

```css
.list { list-style: none; margin: 0; padding: 0; }

.row { border-bottom: var(--border-width) solid var(--border-secondary); }

.row:last-child { border-bottom: none; }

.row__link {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-md);
  padding: var(--space-md);
  color: var(--text-primary);
  text-decoration: none;
  transition: background-color var(--duration-normal) var(--easing-default),
              transform var(--duration-normal) var(--easing-default);
}

.row__link:hover {
  background-color: var(--surface-primary);
}

.row__link:hover .row__arrow {
  transform: translateX(4px);
}

.row__link:focus-visible {
  outline: var(--border-focus-width, 2px) solid var(--border-focus);
  outline-offset: -var(--border-focus-offset, 2px);
}

.row__left-group {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.row__number {
  font-size: var(--font-size-sm);
  font-weight: var(--font-weight-bold);
  color: var(--text-tertiary);
  font-variant-numeric: tabular-nums;
  min-inline-size: 2ch;
}

.row__arrow {
  color: var(--text-tertiary);
  transition: transform var(--duration-normal) var(--easing-default);
}
```

**Angular** (standalone, OnPush, signals):

```typescript
@Component({
  selector: 'app-list-item',
  standalone: true,
  imports: [LucideAngularModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <li class="row">
      <a class="row__link" [href]="href()"
        (mouseenter)="isHovered.set(true)" (mouseleave)="isHovered.set(false)">
        <span class="row__left-group">
          <span class="row__number" aria-hidden="true">{{ numberLabel() }}</span>
          <span class="row__title">{{ title() }}</span>
          @if (subtitle()) { <span class="row__subtitle">{{ subtitle() }}</span> }
        </span>
        @if (showArrow()) {
          <lucide-icon name="arrow-right" class="row__arrow" [attr.aria-hidden]="true" />
        }
      </a>
    </li>
  `
})
export class ListItemComponent {
  href = input<string>();
  index = input.required<number>();
  title = input.required<string>();
  subtitle = input<string>();
  showArrow = input(true);

  isHovered = signal(false);

  numberLabel = computed(() => String(this.index() + 1).padStart(2, '0'));
}
```

### Table (Row Separators)

**Required Elements**: `<table>`, `<thead>`, `<tbody>`, `<th scope>`
**Required Tokens**: --bg-primary, --surface-primary, --text-primary, --border-primary

**This pattern**: bottom row separators only (no vertical borders, no boxed cells).

```css
.table { inline-size: 100%; border-collapse: collapse; }

.table th,
.table td {
  padding: var(--space-sm) var(--space-md);
  text-align: start;
  border-bottom: var(--border-width) solid var(--border-secondary);
}

.table tbody tr:hover { background-color: var(--surface-primary); }

.table th { font-weight: var(--font-weight-semibold); color: var(--text-primary); }
```

**Accessibility**: caption or `aria-label`; `scope` on headers (`col`/`row`).

### Button

**Required Elements**: `<button>` or `<a>` with button role
**Required Tokens**: --bg-primary, --text-primary, --surface-primary, --border-primary
**Variants**: `primary` (surface-filled), `secondary` (bordered), `ghost` (text only), `danger`

**Interactions**: Hover background shift; Active `transform: scale(0.98)`; Focus 2px outline; Disabled `opacity: 0.5`; Transition `background-color var(--duration-normal) var(--easing-default), transform var(--duration-fast) var(--easing-default)`.

**States**: Default, Hover, Active (dispatch ack), Focus, Disabled, Loading (spinner + `aria-busy`), Retrying (loading + attempt text), Failed.

**Accessibility**: visible focus; 44x44px touch target (24x24px minimum); disabled announced.

### Navigation

**Required Elements**: `<nav>`, `<a>`
**Required Tokens**: --bg-primary, --text-primary, --border-primary

**This pattern**: vertical list nav with bottom separators, no boxes. Hover background `--surface-primary`; active persistent background.

**Interactions**: Hover background shift; Active persistent background; Focus 2px outline.

**Accessibility**: `<nav>` with `aria-label`; active item `aria-current="page"`.

### Input

**Required Elements**: `<label>`, `<input>` or `<textarea>`
**Required Tokens**: --bg-primary, --text-primary, --border-primary, --border-focus

**This pattern**: sharp edges (`border-radius: 0`), bottom border only, focus border `--border-focus`.

**Interactions**: Focus border `--border-focus` + 2px outline; Error border `--state-error`; Disabled `opacity: 0.5`.

**Accessibility**: visible or `aria-label` label; errors via `aria-describedby`; required `aria-required="true"`.

### Link

**Required Elements**: `<a>` or link role
**Required Tokens**: --text-primary, --text-secondary

**This pattern**: no accent color — underline on hover/focus only. Hover `--surface-primary` background for standalone links.

**Interactions**: Hover underline/background; Focus 2px outline; Transition `background-color var(--duration-normal) var(--easing-default), color var(--duration-normal) var(--easing-default)`.

### Modal/Dialog

**Required Elements**: `<dialog>` or `role="dialog"`, `<header>`, `<footer>`
**Required Tokens**: --bg-primary, --text-primary, --shadow-xl, --z-modal

**This pattern**: sharp corners (`border-radius: 0`), minimal chrome, focus trap, `aria-modal="true"`, focus restored on close.

### Toast/Notification

**Required Elements**: `role="status"` or `role="alert"`, optional close button
**Required Tokens**: --bg-primary, --text-primary, --state-*, --z-toast

**This pattern**: flat toast, no border radius, slide+fade enter/exit, `role="alert"` for errors (never auto-dismiss), Retry wiring per the Retry Contract.

### Tabs / Menu / Tooltip / Badge / Drawer

Apply the shared contracts below with mono-tone tokens and sharp edges:

- **Tabs**: `role="tablist"`/`tab`/`tabpanel`; arrow keys; roving tabindex; `aria-selected`.
- **Menu**: `role="menu"`/`menuitem`; focus trap; Escape/outside close; `aria-haspopup="menu"`.
- **Tooltip**: trigger `aria-describedby`, `role="tooltip"`; show on hover AND keyboard focus; never sole source of critical info.
- **Badge**: `--state-*-soft` backgrounds; status conveyed by text not color alone.
- **Drawer**: `<aside>` or `role="dialog" aria-modal="true"`; focus trap; logical properties for edge.

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
| `border-color` | --duration-normal | --easing-default |
| `box-shadow` | --duration-slow | --easing-default |
| `transform` | --duration-normal | --easing-default |
| `opacity` | --duration-normal | --easing-default |

### Row Motion (this pattern)

```css
.row__link {
  transition: background-color var(--duration-normal) var(--easing-default),
              transform var(--duration-normal) var(--easing-default);
}

.row__arrow { transition: transform var(--duration-normal) var(--easing-default); }
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
| ListItem | `listitem` or `link` | `aria-current` for active |
| Button | `button` | `aria-disabled` |
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

```css
:focus-visible {
  outline: var(--border-focus-width, 2px) solid var(--border-focus);
  outline-offset: var(--border-focus-offset, 2px);
}
```

### Screen Reader Considerations

- Decorative icons and numbers: `aria-hidden="true"`
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
  .row__link { border: 2px solid CanvasText; }
}
```

### Contrast Verification

1. L = 0.2126R + 0.7152G + 0.0722B (linearized)
2. Contrast ratio = (L1 + 0.05) / (L2 + 0.05)
3. Thresholds: 4.5:1 text, 3:1 large text/UI

## Responsive Design

### Desktop-First Strategy

Start with desktop layout and adapt downward. Rows collapse to comfortable touch sizes on mobile.

```css
.row__link { padding: var(--space-md); }

@media (max-width: 768px) {
  .row__link { padding: var(--space-sm) var(--space-md); }
  .row__subtitle { display: none; }  /* or keep, but allow wrap */
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

### Fluid Typography

```css
:root {
  --font-size-base: clamp(1rem, 0.9rem + 0.25vw, 1.125rem);
  --font-size-lg: clamp(1.125rem, 1rem + 0.3vw, 1.375rem);
}
```

### Touch Considerations

- Minimum touch target 44x44px (rows are naturally large)
- Minimum spacing between targets 8px
- Avoid hover-dependent interactions on touch (arrow shift is progressive enhancement)

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

### Mono Tone Theme Base

```css
:root {
  --bg-primary: #ffffff;
  --surface-primary: #f8f9fa;
  --surface-secondary: #e9ecef;
  --text-primary: #212529;
  --text-secondary: #6c757d;
  --text-tertiary: #adb5bd;
  --border-primary: #dee2e6;
  --border-secondary: #e9ecef;
  --border-focus: #495057;
  --shadow-sm: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
  --shadow-lg: 0 1rem 3rem rgba(0, 0, 0, 0.175);
  --shadow-xl: 0 1rem 3rem rgba(0, 0, 0, 0.25);
  --bg-overlay: rgba(0, 0, 0, 0.5);
  --border-width: 1px;
  --border-focus-width: 2px;
  --border-focus-offset: 2px;
  --space-xs: 0.25rem;
  --space-sm: 0.5rem;
  --space-md: 1rem;
  --space-lg: 1.5rem;
  --space-xl: 2rem;
  --font-mono: SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  --font-size-xs: 0.75rem;
  --font-size-sm: 0.875rem;
  --font-size-base: 1rem;
  --font-size-lg: 1.125rem;
  --font-size-xl: 1.25rem;
  --font-size-2xl: 1.5rem;
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
}
```

### Dark Mono Tone

```css
[data-theme="dark"] {
  --bg-primary: #212529;
  --surface-primary: #343a40;
  --surface-secondary: #495057;
  --text-primary: #f8f9fa;
  --text-secondary: #adb5bd;
  --text-tertiary: #6c757d;
  --border-primary: #495057;
  --border-secondary: #6c757d;
  --border-focus: #adb5bd;
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
}
```

### Theme Accessibility

- Keyboard-accessible toggle
- Announce theme changes to screen readers
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
```

Rows use flex with logical properties — arrow flips automatically. Numbers keep `text-align: start`.

### Text Expansion

Languages can expand 200%+: use `min-width` not fixed width; flexbox for automatic resizing; test with pseudo-localization.

### Number & Date Formatting

Use `Intl.NumberFormat` / `Intl.DateTimeFormat` with locale. `font-variant-numeric: tabular-nums` keeps zero-padded numbers aligned.

### Bidirectional Text

Use `unicode-bidi: plaintext` for auto-detect; `dir` attribute for forced direction.

## Usability Principles (Nielsen)

1. **Visibility of System Status** — loading indicators, row feedback, error/success, retry attempt counter
2. **Match Between System and Real World** — user language, recognized icons
3. **User Control and Freedom** — undo/redo, clear exits, Escape
4. **Consistency and Standards** — same row behaves same way everywhere
5. **Error Prevention** — input constraints, sensible defaults
6. **Recognition Rather than Recall** — persistent labels, visible actions
7. **Flexibility and Efficiency** — keyboard shortcuts
8. **Aesthetic and Minimalist Design** — this pattern's core: typography focus, no heavy chrome
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
Block: .row { }
Element: .row__link { }
Modifier: .row--selected { }
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
}
```

### Progress Indicators

- **Determinate**: progress bar with `role="progressbar"`, `aria-valuenow/min/max`
- **Indeterminate**: spinner (`animation: spin var(--duration-spinner) linear infinite`)

```css
.spinner {
  width: var(--size-spinner-md);
  height: var(--size-spinner-md);
  border: var(--border-width) solid var(--border-primary);
  border-block-start-color: var(--text-primary);
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
| `tap` | Discrete commit ack | [10] | Row/link activate |
| `select` | Selection changed | [5] | Filter, checkbox |
| `retry-ack` | Retry accepted | [10] | Retry press (every attempt) |
| `success` | Positive terminal | [10, 50, 10] | Async success |
| `warning` | Caution terminal | [10, 40, 10] | Destructive confirm |
| `error` | Failure terminal | [30, 50, 30] | Settled failure |

### When to Fire

| Situation | Event | Notes |
|-----------|-------|-------|
| Row activate | `tap` | At dispatch |
| Filter/toggle change | `select` | Once per commit |
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
3. **Accessibility by Default** — visible focus, WCAG AA, keyboard nav
4. **Progressive Enhancement** — base works without JS; enhanced interactions layer on top
5. **Separation of Concerns** — HTML structure, CSS presentation, TS interactivity
6. **Consistent Token Usage** — never ad-hoc values
7. **Interaction Completeness** — hover/focus/active/disabled on every interactive element
8. **Responsive by Design** — desktop-first; rows adapt to touch sizes
9. **Theme Agnostic** — components work in any theme via CSS variables
10. **Performance Conscious** — transform/opacity; OnPush; `trackBy`
11. **Visual Hierarchy** — typography scale, opacity, spacing rhythm
12. **Opacity-Based Hierarchy** — text 100/70/50/30; interaction 100/90/80/50
13. **Internationalization Ready** — logical properties, text expansion, bidi
14. **Error Prevention** — validation, clear errors, recovery paths
15. **Progressive Disclosure** — show only what's needed
16. **Consistent Interaction Patterns** — similar components behave similarly
17. **Documentation as Code** — decisions documented via tokens/contracts
18. **Action Acknowledgement** — every action gets visual/AT feedback at dispatch; async shows pending → outcome; retries re-ack and surface settled outcome with attempt feedback; haptics are a separate optional channel
19. **Reaction Design** — feedback present *and* right: time budgets, weight match, microinteraction anatomy, escalation, undo over confirm, dedupe, continuity, congruence, identical reactions

## Usage

When generating UI code:

1. **Understand the context** — dashboard, SaaS, documentation, admin, social lists
2. **Confirm the pattern** — this skill is Interactive Numbered List (Mono Tone)
3. **Apply all tokens** — mono tone palette, zero radius, border-bottom separators
4. **Follow component contracts** — ListItem is the core; structure left group + arrow
5. **Implement all interaction states** (hover, focus, active, disabled) and the async lifecycle (ack → pending → success/error/retry)
6. **Use animations from the library** — row hover transitions, arrow shift
7. **Ensure accessibility** (WCAG AA) and **usability** (Nielsen)
8. **Apply haptics** (optional separate channel) on discrete commits only
9. **Tune the reaction** — time budgets, weight, undo-vs-confirm
10. **Verify against the Evaluation Rubric** before finalizing

## Evaluation Rubric

1. **Token Accuracy**: Are specific CSS values strictly applied without deviation?
2. **Structural Fidelity**: Does HTML follow required structure (list, row, left-group, number, title, arrow)?
3. **Interaction Completeness**: Are all hover/focus/active/disabled states implemented? Do async controls implement the full lifecycle (ack → pending → success/error/retry)?
4. **Theme Adaptability**: All colors via CSS variables, not hardcoded hex/RGB?
5. **Accessibility Compliance**: WCAG AA (contrast, keyboard, ARIA)?
6. **Usability Compliance**: Nielsen heuristics?
7. **Typography Focus**: zero-padded numbers, tabular alignment, mono tone (no accent colors, no hue shifts)?
8. **Visual Hierarchy**: clear reading order through typography, opacity, spacing?
9. **Angular Idiomatic**: standalone, OnPush, signals, DI patterns?
10. **Lint Compliance**: no hardcoded values, no gradients, no emojis, Lucide only?
11. **Hexagonal Purity**: domain has zero framework imports; components depend on ports
12. **Motion Compliance**: animations from library, motion tokens, `prefers-reduced-motion`
13. **Consistency**: identical rows behave identically; same answer ⇒ same structure
14. **Action Feedback**: every action produces visual/AT feedback at dispatch with full async lifecycle — complete on its own, no dependence on haptics
15. **Haptics**: separate optional channel; registry events only; never sole feedback
16. **React Idiomatic** (React target): function components + hooks, React 19 builtins, minimal deps
17. **Reaction Design**: time budgets, weight match, microinteraction anatomy, interruption budget, undo over confirm, dedupe, continuity, congruence, identical reactions

## External References

### Design Systems
- <https://www.w3.org/WAI/WCAG21/quickref/> — WCAG 2.1 Quick Reference
- <https://carbondesignsystem.com/> — IBM Carbon Design System
- <https://material.io/design> — Google Material Design
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