---
name: morphic-surfaces
description: Generate HTML and CSS for Morphic Surfaces — surfaces that read as one continuous material with paired dual-radius shells (outer shell + inner well) that morph between states with tasteful lift/peel ("coming off") motion. Includes the rule-based shape questionnaire, Shape Spec resolution, motion bundles, and lint rules. Use when building interactive apps where components should feel like one continuous material, defining morph transitions, or running shape decision rules.
---

# Morphic Surfaces (Dual-Radius Morph) (Pattern 4)

Surfaces that read as one continuous material. Components morph between states and into each other by animating paired external (shell) and internal (content well) radii, with tasteful lift/peel motion that feels like layers coming off a surface.

## When to Use

Best for interactive apps where components should feel like one continuous material — dual-radius shells that morph between states with tasteful lift/peel ("coming off") motion. Bordered geometric UIs use [multi-theme](../multi-theme/SKILL.md); typography-focused lists use [mono-tone-list](../mono-tone-list/SKILL.md); flat shadow-based minimal UIs use [minimal-flat](../minimal-flat/SKILL.md).

## Framework Detection

| Signals in project | Target |
|--------------------|--------|
| `angular.json` | Angular |
| `package.json` with `react` dependency | React |
| `pubspec.yaml` | Flutter |
| Multiple or none | Ask the user once; do not guess |

When ambiguous, ask: "Should I generate Angular, React, or Flutter code for this?"

Generate the **detected target's** implementation. Only fall back to vanilla JS when the target is ambiguous or explicitly requested.

## Shape Questionnaire & Decision Rules

Every component gets a **Shape Spec** by answering these questions in order.

### Q1: Is this a surface (container) or a control (interactive element)?

- **Surface** → continue to Q2
- **Control** → continue to Q2

Both paths lead to Q2. The answer determines which motion bundle applies.

### Q2: Does this component have an inner well (nested content area)?

The "well" is a visually distinct inner region — a recessed or contrasting area that holds content within the outer shell.

- **Yes** (e.g., card with content area, input with text region) → Q5 = `yes`
- **No** (e.g., badge, chip, avatar, standalone button) → Q5 = `no`

### Q3: Should the component lift on hover?

- **Yes** (cards, clickable surfaces) → `lift` motion bundle
- **No** (static surfaces, decorative) → `settle` motion bundle

### Q4: Should the component bloom (radius expand) on hover?

- **Yes** (cards, prominent surfaces) → outer radius steps up one level on hover
- **No** (compact controls, tight spaces) → radius stays constant

### Q5: Is there an inner well?

This is the output of Q2. Used by lint rule `pattern-4-dual-radius`.

- **yes** → component must set both `--radius-outer-*` and `--radius-inner-*`
- **no** → component sets only `--radius-outer-*`; omit well structure

### Q6: Does the component need a peel exit animation?

- **Yes** (modals, drawers, dismissible surfaces) → exit uses `peelOff` animation
- **No** (toasts, non-dismissible overlays) → exit uses `fadeOut` or `slideOut`

### Shape Spec Output

After answering all questions, the Shape Spec is:

```
pattern: 4
surface-type: surface | control
well: yes | no
lift: yes | no
bloom: yes | no
exit: peel | fade | slide
```

### Motion Bundles

**Lift Bundle** — surfaces that rise on hover:

```css
.surface {
  transition:
    transform var(--duration-normal) var(--easing-peel),
    box-shadow var(--duration-slow) var(--easing-default),
    border-radius var(--duration-morph) var(--easing-morph);
}

.surface:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-hover);
}
```

**Settle Bundle** — static surfaces that don't lift:

```css
.surface {
  transition:
    box-shadow var(--duration-slow) var(--easing-default),
    border-radius var(--duration-morph) var(--easing-morph);
}
```

**Peel Exit Bundle** — dismissible surfaces (modals, drawers):

```css
.surface--exiting {
  animation: peelOff var(--duration-slow) var(--easing-peel) forwards;
}
```

**Fade Exit Bundle** — non-dismissible overlays (toasts, notifications):

```css
.surface--exiting {
  animation: fadeOut var(--duration-normal) var(--easing-default) forwards;
}
```

### Decision Flow Chart

```
Component
  │
  └─ Pattern = 4?
       ├─ Q2: Has inner well?
       │    ├─ Yes → Set both --radius-outer-* and --radius-inner-*
       │    └─ No  → Set only --radius-outer-*
       ├─ Q3: Lift on hover?
       │    ├─ Yes → Apply lift bundle (transform + shadow + radius)
       │    └─ No  → Apply settle bundle (shadow + radius only)
       ├─ Q4: Bloom radius on hover?
       │    ├─ Yes → Outer + inner radii step up one level on hover
       │    └─ No  → Radii stay constant
       └─ Q6: Peel exit?
            ├─ Yes → peelOff animation (lift → fade → radius contract)
            └─ No  → fadeOut or slideOut animation
```

### Binding Rule: Peel vs Fade

- **Peel** when the surface has a physical, layered quality (cards, drawers, modals that feel "lifted"). The peel animation reinforces the spatial metaphor.
- **Fade** when the surface is a flat overlay (toasts, notifications, tooltips). These don't have spatial depth, so a peel would feel disconnected.

Rule of thumb: if Q3 = yes (lift on hover), then Q6 = peel. If Q3 = no, then Q6 = fade.

### Shape Spec Examples

**Card (Surface, Well, Lift, Bloom, Peel Exit):**

```
Shape Spec:
  pattern: 4
  surface-type: surface
  well: yes
  lift: yes
  bloom: yes
  exit: peel
```

```css
.card {
  background: var(--surface-primary);
  border-radius: var(--radius-outer-lg);
  box-shadow: var(--shadow-sm);
  transition:
    transform var(--duration-normal) var(--easing-peel),
    box-shadow var(--duration-slow) var(--easing-default),
    border-radius var(--duration-morph) var(--easing-morph);
}

.card:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-hover);
  border-radius: var(--radius-outer-xl);
}

.card__well {
  background: var(--bg-primary);
  border-radius: var(--radius-inner-lg);
  transition: border-radius var(--duration-morph) var(--easing-morph);
}

.card:hover .card__well {
  border-radius: var(--radius-inner-xl);
}
```

**Badge (Surface, No Well, No Lift, No Bloom, Fade Exit):**

```
Shape Spec:
  pattern: 4
  surface-type: surface
  well: no
  lift: no
  bloom: no
  exit: fade
```

```css
.badge {
  background: var(--surface-primary);
  border-radius: var(--radius-outer-sm);
  box-shadow: var(--shadow-sm);
  transition: box-shadow var(--duration-slow) var(--easing-default);
}
```

**Button (Control, No Well, Lift on Press, No Bloom, No Exit):**

Retry controls share the same Shape Spec as buttons (`surface-type: control`, `exit: none`); the retry lifecycle (ack → loading → outcome) lives in the Loading & Retry section below.

```
Shape Spec:
  pattern: 4
  surface-type: control
  well: no
  lift: no
  bloom: no
  exit: none
```

```css
.btn {
  background: var(--accent-primary);
  border-radius: var(--radius-outer-md);
  box-shadow: var(--shadow-sm);
  transition:
    background-color var(--duration-normal) var(--easing-default),
    transform var(--duration-fast) var(--easing-default),
    box-shadow var(--duration-normal) var(--easing-default);
}

.btn:hover { box-shadow: var(--shadow-hover); }

.btn:active {
  transform: scale(0.98);
  box-shadow: var(--shadow-active);
}
```

## Pattern Specification

**Objective**: Implement surfaces that read as one continuous material. Components morph between states and into each other by animating paired external (shell) and internal (content well) radii, with tasteful lift/peel motion that feels like layers coming off a surface.

### Design Tokens

- **Dual Radius**: Every surface has an external shell radius (`--radius-outer-*`) and an internal well radius (`--radius-inner-*`). Both are modified during morphs so nested surfaces stay concentric.
  - Relationship rule: `inner ≈ outer − component padding`. Discrete tokens exist for independent morph control (outer may grow while inner holds, or both may step together).
- **Morph Motion**: State changes and radius blooms use `--duration-morph` (350ms) with `--easing-morph`. Lift/peel movement uses `--easing-peel`.
- **Elevation**: Dynamic shadows only. Shadows deepen on lift, settle on press. No static borders on main surfaces (optional hairline for controls).
- **Colors**: NEVER hardcode color values. All backgrounds, text, and border colors map to CSS variable tokens. Gradients prohibited.

### Dual Radius Structure

```html
<article class="surface">
  <div class="surface__well">
    <h3>Title</h3>
    <p>Content</p>
  </div>
</article>
```

```css
.surface {
  background: var(--surface-primary);
  border-radius: var(--radius-outer-md);
  padding: var(--space-md);
  box-shadow: var(--shadow-sm);
  transition: border-radius var(--duration-morph) var(--easing-morph),
              transform var(--duration-normal) var(--easing-peel),
              box-shadow var(--duration-slow) var(--easing-default);
}

.surface__well {
  background: var(--bg-primary);
  border-radius: var(--radius-inner-md);
  padding: var(--space-sm);
  transition: border-radius var(--duration-morph) var(--easing-morph);
}
```

### Interactions

| State | Property | Value |
|-------|----------|-------|
| Hover (surface) | transform | translateY(-2px) — lift off |
| Hover (surface) | box-shadow | --shadow-md (deepen) |
| Hover (surface) | border-radius | outer blooms one step (e.g., md → lg) |
| Hover (well) | border-radius | inner blooms one step in sync |
| Active (surface) | transform | translateY(0) scale(0.99) — press back |
| State morph | border-radius | outer + inner animate together |
| Exit (dismiss) | animation | peelOff (lift → fade → radius contract) |
| Focus (all) | outline | `var(--border-focus-width, 2px) solid var(--border-focus)` |
| Disabled | opacity | 0.5 |

**Transitions**:
- Radius morph: `transition: border-radius var(--duration-morph) var(--easing-morph)`
- Lift: `transition: transform var(--duration-normal) var(--easing-peel)`
- Shadow: `transition: box-shadow var(--duration-slow) var(--easing-default)`
- Combined: all three on the surface host; radius-only on the well

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
| **Surface** | --surface-primary, --surface-secondary, --surface-elevated | Shell and well backgrounds |
| **Text** | --text-primary, --text-secondary, --text-tertiary | Heading, body, caption text |
| **Text on Accent** | --text-on-accent | Text on accent backgrounds |
| **Border** | --border-primary, --border-secondary, --border-focus | Optional hairlines, focus rings |
| **Accent** | --accent-primary, --accent-secondary, --accent-hover | Interactive highlights |
| **State** | --state-success, --state-warning, --state-error, --state-info | Feedback and validation |

### Text Opacity Hierarchy

| Level | Token | Opacity | Use Case |
|-------|-------|---------|----------|
| **Primary** | --text-primary | 100% | Headings, important labels |
| **Secondary** | --text-secondary | 70% | Body text, descriptions |
| **Tertiary** | --text-tertiary | 50% | Captions, hints |
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

### Dual Radius Tokens (Core)

| Token | Value | Use Case |
|-------|-------|----------|
| --radius-outer-sm | 4px | Compact shells (badges, chips) |
| --radius-outer-md | 8px | Standard surfaces, controls |
| --radius-outer-lg | 12px | Containers, cards |
| --radius-outer-xl | 16px | Large containers, overlays |
| --radius-inner-sm | 2px | Inner well paired with outer-sm |
| --radius-inner-md | 6px | Inner well paired with outer-md |
| --radius-inner-lg | 10px | Inner well paired with outer-lg |
| --radius-inner-xl | 14px | Inner well paired with outer-xl |

**Relationship rule**: `inner ≈ outer − component padding` (e.g., outer-lg with space-md padding → inner around 4–6px). Discrete tokens exist so outer and inner can morph independently (outer may bloom while inner holds, or both step together).

**Morph rule**: whenever `--radius-outer-*` transitions, the paired `--radius-inner-*` on the well element transitions on the same clock (`--duration-morph` + `--easing-morph`).

Also available: `--border-radius-sm` (3px), `--border-radius` (5px), `--border-radius-lg` (8px), `--border-radius-xl` (12px), `--border-radius-full` (9999px).

### Spacing Scale

| Token | Concept | Typical Use |
|-------|---------|-------------|
| --space-xs | Extra small | Tight padding |
| --space-sm | Small | Well padding |
| --space-md | Medium | Shell padding |
| --space-lg | Large | Section padding |
| --space-xl | Extra large | Page sections |
| --space-2xl | Double extra large | Major layout divisions |
| --space-3xl | Triple extra large | Full-page sections |

### Elevation Tokens

| Token | Concept | Use Case |
|-------|---------|----------|
| --shadow-sm | Subtle | Resting state (flat surfaces) |
| --shadow-md | Medium | Lift/hover deepening |
| --shadow-lg | Elevated | Dropdowns |
| --shadow-xl | Highest | Modals, dialogs |
| --shadow-hover | Interactive lift | Hover elevation |
| --shadow-active | Pressed | Active/pressed elevation |

Never write raw `box-shadow` in component CSS — always use tokens. **Dynamic shadows only**: shadows deepen on lift, settle on press.

### Border & Focus Tokens

| Token | Value | Use Case |
|-------|-------|----------|
| --border-width | 1px | Optional hairline on controls |
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
| --duration-fast | 100ms | Press feedback |
| --duration-normal | 200ms | Lift/peel, standard transitions |
| --duration-slow | 300ms | Shadow changes, complex animations |
| --duration-morph | 350ms | Dual-radius morph transitions (core) |
| --duration-slower | 500ms | Page transitions |
| --duration-spinner | 1000ms | Spinner cycle |
| --duration-loading | 1500ms | Skeleton shimmer cycle |

| Token | Value | Use Case |
|-------|-------|----------|
| --easing-default | cubic-bezier(0.4, 0, 0.2, 1) | Most transitions |
| --easing-in | cubic-bezier(0.4, 0, 1, 1) | Elements exiting |
| --easing-out | cubic-bezier(0, 0, 0.2, 1) | Elements entering |
| --easing-in-out | cubic-bezier(0.42, 0, 0.58, 1) | Symmetric animations |
| --easing-morph | cubic-bezier(0.65, 0, 0.35, 1) | Symmetric shape morphs (radius pairs) |
| --easing-peel | cubic-bezier(0.33, 1, 0.68, 1) | Lift-off / peel exits ("coming off") |
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

### Pattern 4 Surface Contract

Required whenever Shape Spec `pattern = 4` and Q5 = `yes` (inner well present).

**Required structure**:

```html
<article class="surface" [class.surface--hovered]="hovered()">
  <div class="surface__well">
    <!-- content -->
  </div>
</article>
```

**Required tokens**: `--radius-outer-*`, `--radius-inner-*`, `--shadow-hover`/`--shadow-active` (or pattern elevation tokens), `--duration-morph`, `--easing-morph`, `--easing-peel`.

```css
.surface {
  background: var(--surface-primary);
  border-radius: var(--radius-outer-lg);
  box-shadow: var(--shadow-sm);
  transition:
    border-radius var(--duration-morph) var(--easing-morph),
    box-shadow var(--duration-slow) var(--easing-default),
    transform var(--duration-normal) var(--easing-peel);
}

.surface__well {
  background: var(--bg-primary);
  border-radius: var(--radius-inner-lg);
  transition: border-radius var(--duration-morph) var(--easing-morph);
}

.surface:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-hover);
  border-radius: var(--radius-outer-xl);
}

.surface:hover .surface__well {
  border-radius: var(--radius-inner-xl);
}
```

**Rules**:
- Both radii transition together on the same clock.
- Hover = lift ("coming off") + optional radius bloom one step.
- Dismiss/exit = `peelOff` only (`exit-peel` bundle).
- Atomic components (chip, badge, avatar) may omit the well (Q5 = `no`).

### Card

**Required Elements**: `<article>`, `<section>` (well), optional `<header>`, `<footer>`
**Required Tokens**: --surface-primary, --bg-primary, --radius-outer-*, --radius-inner-*, --shadow-md

**Shape Spec**: surface, well yes, lift yes, bloom yes, exit peel (see example above).

### Button

**Required Elements**: `<button>` or `<a>` with button role
**Required Tokens**: --accent-primary, --radius-outer-md, --shadow-sm

**Shape Spec**: control, well no, lift no, bloom no, exit none.

**Interactions**: Hover `--shadow-hover`; Active `scale(0.98)` + `--shadow-active`; Focus 2px outline; Disabled `opacity: 0.5`; Transition `background-color var(--duration-normal) var(--easing-default), transform var(--duration-fast) var(--easing-default), box-shadow var(--duration-normal) var(--easing-default)`.

**States**: Default, Hover, Active (dispatch ack), Focus, Disabled, Loading (spinner + `aria-busy`), Retrying (loading + attempt text), Failed.

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

**React**:

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
**Required Tokens**: --bg-primary, --text-primary, --surface-primary, --radius-outer-sm/md

**Shape Spec**: surface (row) or control; well optional; lift no (row highlight instead); exit fade.

**Interactions**: Hover background `--surface-primary`; Focus 2px outline; Transition `background-color var(--duration-normal) var(--easing-default)`.

**Accessibility**: `role="listitem"` or `<li>`; decorative icons `aria-hidden="true"`.

### Navigation

**Required Elements**: `<nav>`, `<a>`
**Required Tokens**: --bg-primary, --text-primary, --accent-primary, --border-primary

**Interactions**: Hover background shift or underline; Active persistent accent; Focus 2px outline.

**Accessibility**: `<nav>` with `aria-label`; active item `aria-current="page"`.

### Input

**Required Elements**: `<label>`, `<input>` or `<textarea>`
**Required Tokens**: --bg-primary, --text-primary, --border-primary, --border-focus, --radius-outer-md, --radius-inner-sm

**Shape Spec**: control, well yes (the text region is the well).

**Interactions**: Focus border `--border-focus` + radius morph; Error border `--state-error`; Disabled `opacity: 0.5`.

**Accessibility**: visible or `aria-label` label; errors via `aria-describedby`; required `aria-required="true"`.

### Modal/Dialog

**Required Elements**: `<dialog>` or `role="dialog"`, `<header>`, `<footer>`
**Required Tokens**: --bg-primary, --text-primary, --shadow-xl, --z-modal, --radius-outer-xl, --radius-inner-lg

**Shape Spec**: surface, well yes, lift no, bloom no, exit **peel** (dismissible overlay with physical quality).

**Interactions**: Open fade overlay + scale dialog; Close reverse (peel); Backdrop/Escape close; focus trap; restore focus on close.

**Accessibility**: `role="dialog"` + `aria-modal="true"`; title via `aria-labelledby`; focus trapped; background scroll locked.

### Drawer

**Required Elements**: `<aside>` or `role="dialog" aria-modal="true"`
**Required Tokens**: --surface-primary, --bg-overlay, --shadow-xl, --z-modal, --radius-outer-*

**Shape Spec**: surface, well optional, lift no, bloom no, exit **peel** when Shape Spec says `exit-peel`.

**Interactions**: slide in from edge + backdrop fade; close reverse; Escape/backdrop close; focus trap; restore focus.

### Toast/Notification

**Required Elements**: `role="status"` or `role="alert"`, optional close button
**Required Tokens**: --bg-primary, --text-primary, --state-*, --z-toast, --radius-outer-md

**Shape Spec**: surface, well no, lift no, bloom no, exit **fade** (flat overlay — no spatial depth).

**Interactions**: Enter slide+fade; Exit fade; auto-dismiss 5-8s (never error toasts); Retry wiring per Retry Contract.

### Tabs

**Required Elements**: `role="tablist"`, `role="tab"`, `role="tabpanel"`
**Required Tokens**: --bg-primary, --text-primary, --accent-primary, --border-primary

**Pattern 4 note**: selected tab uses dual-radius morph on the active indicator surface.

**Accessibility**: arrow keys; roving tabindex; `aria-selected`, `aria-controls`, `aria-labelledby`.

### Menu

**Required Elements**: `role="menu"`, `role="menuitem"`
**Required Tokens**: --surface-primary, --text-primary, --accent-primary, --shadow-lg, --z-dropdown, --radius-outer-md

**Interactions**: fade + scale in (or peel when spatial); item hover highlight; Escape/outside close; focus trap; restore focus; `aria-haspopup="menu"`.

### Tooltip / Badge / Table

- **Tooltip**: trigger `aria-describedby`, `role="tooltip"`; show on hover AND keyboard focus; never sole source of critical info.
- **Badge**: `--state-*-soft` backgrounds; compact, **no well** (Q5 = `no`); status by text not color alone.
- **Table**: caption/`aria-label`; `scope` on headers; row hover subtle.

## Motion Design

Motion principles and transition guidance. All durations and easings must use tokens — never raw ms/cubic-bezier.

### When to Use Which

| Use Case | Approach |
|----------|----------|
| Hover/focus/active states | CSS transitions |
| Element enter/leave (`@if`) | `@angular/animations` |
| Dual-radius morph | `morph()` port / `morphSurface` trigger |
| Peel exits | `peelOff()` port / `@peelOff` trigger |
| Simple show/hide | CSS transitions with `[class.hidden]` |

### Transition Principles

1. **Purposeful**: Every animation has a purpose
2. **Quick**: Most transitions 100-300ms; morphs max out at `--duration-morph` (350ms)
3. **Smooth**: Appropriate easing tokens
4. **Respectful**: Honor `prefers-reduced-motion`
5. **Tokenized**: Never hardcode duration or easing

### Transition Properties

| Property | Duration Token | Easing Token | Use Case |
|----------|----------------|--------------|----------|
| `background-color` | --duration-normal | --easing-default | Color changes |
| `color` | --duration-normal | --easing-default | Text color |
| `border-color` | --duration-normal | --easing-default | Border color |
| `box-shadow` | --duration-slow | --easing-default | Elevation |
| `transform` | --duration-normal | --easing-peel (lift) | Movement, scale |
| `opacity` | --duration-normal | --easing-default | Show/hide |
| `border-radius` | --duration-morph | --easing-morph | Dual-radius morph |

### Combined Transitions

```css
.surface {
  transition: transform var(--duration-normal) var(--easing-peel),
              box-shadow var(--duration-slow) var(--easing-default),
              border-radius var(--duration-morph) var(--easing-morph);
}
```

### Animation Guidelines

- Avoid flashing/blinking animations
- Keep animations under 5 seconds
- Prefer `transform` and `opacity`; animate `border-radius` only for morph primitives
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

/* Pattern 4: peel exit — lift → fade → radius contract */
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

/* Pattern 4: subtle radius pulse for state changes */
@keyframes morphRadius {
  0% { border-radius: var(--radius-outer-md); }
  50% { border-radius: var(--radius-outer-lg); }
  100% { border-radius: var(--radius-outer-md); }
}
```

### Utility Classes

| Class | Animation | Duration | Easing | Use Case |
|-------|-----------|----------|--------|----------|
| `.anim-fade-in` | fadeIn | --duration-normal | --easing-default | Generic enter |
| `.anim-fade-out` | fadeOut | --duration-normal | --easing-default | Generic exit |
| `.anim-slide-in-up` | slideInUp | --duration-slow | --easing-out | Toast/drawer enter |
| `.anim-slide-out-down` | slideOutDown | --duration-slow | --easing-in | Toast/drawer exit |
| `.anim-slide-in-right` | slideInRight | --duration-slow | --easing-out | Sidebar enter |
| `.anim-slide-out-left` | slideOutLeft | --duration-slow | --easing-in | Sidebar exit |
| `.anim-peel-off` | peelOff | --duration-slow | --easing-peel | Pattern 4 dismiss |
| `.anim-scale-in` | scaleIn | --duration-normal | --easing-out | Modal enter |
| `.anim-scale-out` | scaleOut | --duration-normal | --easing-in | Modal exit |
| `.anim-morph-radius` | morphRadius | --duration-morph | --easing-morph | State change pulse |
| `.anim-spin` | spin | --duration-spinner | linear | Spinners |
| `.anim-shimmer` | shimmer | --duration-loading | linear | Skeleton screens |
| `.anim-dot-pulse` | dotPulse | --duration-spinner | ease-in-out | Dots loading |

### State Classes

| Class | Effect | Use Case |
|-------|--------|----------|
| `.is-lifted` | `transform: translateY(-2px); box-shadow: var(--shadow-hover);` | Pattern 4 hover |
| `.is-pressed` | `transform: scale(0.98); box-shadow: var(--shadow-active);` | Pattern 4 active |
| `.is-entering` | Applied during enter animation | Lifecycle |
| `.is-exiting` | Applied during exit animation | Lifecycle |

### AnimationPort (Domain Layer)

```typescript
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

`AnimationService` (Angular adapter) implements this with `AnimationBuilder` — `peelOff` and `morphRadius` use `--easing-peel` / `--easing-morph` curves. React toggles `.is-entering`/`.is-exiting`/`.is-lifted`/`.is-pressed` with no animation library. Flutter maps to `AnimatedBuilder` interpolating outer/inner `BorderRadius` (morph) and offset+scale+fade+radius contract (peel).

### Declarative Angular Triggers

```typescript
export const peelOffTrigger = trigger('peelOff', [
  transition(':leave', [
    animate('300ms cubic-bezier(0.33, 1, 0.68, 1)', style({
      transform: 'translateY(-20px) scale(0.95)',
      opacity: 0
    }))
  ])
]);

export const morphSurfaceTrigger = trigger('morphSurface', [
  transition('* => hovered', [
    animate('350ms cubic-bezier(0.65, 0, 0.35, 1)')
  ]),
  transition('hovered => *', [
    animate('350ms cubic-bezier(0.65, 0, 0.35, 1)')
  ])
]);
```

```html
<div @peelOff *ngIf="isOpen()">Modal content</div>
```

### Composition Recipes

**Lift Recipe (hover)**:

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

**Morph Recipe (radius change)**:

```css
.surface-morph {
  transition: border-radius var(--duration-morph) var(--easing-morph);
}

.surface-morph:hover { border-radius: var(--radius-outer-xl); }

.surface-morph:hover .surface-morph__well { border-radius: var(--radius-inner-xl); }
```

**Peel Exit Recipe (dismiss)**:

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

Overlays must trap focus and restore to the trigger on close. **Angular**: CDK `cdkTrapFocus`/`FocusTrapFactory`. **React**: native `<dialog>.showModal()`. **Flutter**: `FocusScope`/`FocusTraversalGroup`.

### Focus Indicators

```css
:focus-visible {
  outline: var(--border-focus-width, 2px) solid var(--border-focus);
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

Start with desktop layout and adapt downward.

```css
.surface-grid {
  display: grid;
  gap: var(--space-lg);
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
}

@media (max-width: 768px) {
  .surface-grid { grid-template-columns: 1fr; }
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
.surface-container { container-type: inline-size; }

@container (min-width: 400px) {
  .surface { display: grid; grid-template-columns: 200px 1fr; }
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
- Avoid hover-dependent interactions on touch (lift is progressive enhancement)

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

### Light Theme (Default)

```css
:root {
  --bg-primary: #ffffff;
  --bg-secondary: #f8f9fa;
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
  --accent-hover: #0b5ed7;
  --state-success: #198754;
  --state-warning: #ffc107;
  --state-error: #dc3545;
  --state-info: #0dcaf0;
  --shadow-sm: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
  --shadow-md: 0 0.5rem 1rem rgba(0, 0, 0, 0.15);
  --shadow-lg: 0 1rem 3rem rgba(0, 0, 0, 0.175);
  --shadow-xl: 0 1rem 3rem rgba(0, 0, 0, 0.25);
  --shadow-hover: 0 0.5rem 0.9375rem rgba(0, 0, 0, 0.08);
  --shadow-active: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.03);
  --bg-overlay: rgba(0, 0, 0, 0.5);
  --border-width: 1px;
  --border-focus-width: 2px;
  --border-focus-offset: 2px;
  --radius-outer-sm: 4px;
  --radius-outer-md: 8px;
  --radius-outer-lg: 12px;
  --radius-outer-xl: 16px;
  --radius-inner-sm: 2px;
  --radius-inner-md: 4px;
  --radius-inner-lg: 6px;
  --radius-inner-xl: 8px;
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
  --duration-morph: 350ms;
  --duration-spinner: 1000ms;
  --duration-loading: 1500ms;
  --easing-default: cubic-bezier(0.4, 0, 0.2, 1);
  --easing-in: cubic-bezier(0.4, 0, 1, 1);
  --easing-out: cubic-bezier(0, 0, 0.2, 1);
  --easing-in-out: cubic-bezier(0.42, 0, 0.58, 1);
  --easing-morph: cubic-bezier(0.65, 0, 0.35, 1);
  --easing-peel: cubic-bezier(0.33, 1, 0.68, 1);
  --easing-bounce: cubic-bezier(0.68, -0.55, 0.265, 1.55);
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

### Dark Theme

```css
[data-theme="dark"] {
  --bg-primary: #212529;
  --bg-secondary: #343a40;
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
  --accent-hover: #86b7fe;
  --state-success: #75b798;
  --state-warning: #ffda6a;
  --state-error: #ea868f;
  --state-info: #6edff6;
  --shadow-sm: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.25);
  --shadow-md: 0 0.5rem 1rem rgba(0, 0, 0, 0.35);
  --shadow-lg: 0 1rem 3rem rgba(0, 0, 0, 0.4);
  --shadow-xl: 0 1rem 3rem rgba(0, 0, 0, 0.5);
  --shadow-hover: 0 0.5rem 0.9375rem rgba(0, 0, 0, 0.25);
  --shadow-active: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.15);
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
}
```

### Theme Accessibility

- Keyboard-accessible toggle
- Announce theme changes to screen readers
- Test contrast in both themes
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
2. **Match Between System and Real World** — user language, recognized icons, material metaphors (peel = physical layer)
3. **User Control and Freedom** — undo/redo, clear exits, Escape
4. **Consistency and Standards** — same surface behaves same way everywhere
5. **Error Prevention** — input constraints, sensible defaults
6. **Recognition Rather than Recall** — persistent labels, visible actions
7. **Flexibility and Efficiency** — keyboard shortcuts
8. **Aesthetic and Minimalist Design** — continuous material, no visual noise
9. **Error Recovery** — clear messages, recovery paths
10. **Help and Documentation** — inline help, tooltips

## Architecture

### Angular

- **Standalone components** (Angular 15+), no NgModules
- **OnPush** change detection
- **Signals** for state; `input()`/`output()`
- **SCSS** with `:host` scoping; tokens via `var(--token)`
- **CDK** for layout and a11y
- **Pattern switching**: inject pattern-specific strategy services via DI token
- **`@for (track ...)`** in lists

### React (React 19 baseline)

- **Function components** + hooks only
- **State**: `useState`/`useReducer`/`useContext`/`useMemo`
- **Async**: `useOptimistic`/`useActionState`/`useTransition` + `fetch`
- **Styling**: CSS variables + CSS Modules (or SCSS)
- **Motion**: CSS classes from the library (`.is-lifted`, `.is-pressed`, `.anim-*`), optional Web Animations API; no animation library
- **Focus traps**: native `<dialog>.showModal()`
- **Dependency budget**: `react`, `react-dom`, `lucide-react` only
- **Ports via Context**: `usePorts()`

### Flutter

- Tokens → `ThemeExtension` (`AppRadii` includes `radiusOuterLg`/`radiusInnerLg`)
- Ports → adapters
- Motion: `AnimatedBuilder` interpolating outer/inner `BorderRadius` for morph; offset+scale+fade+radius contract for peel
- RTL via `Directionality`; logical geometry (`EdgeInsetsDirectional`)
- Reduced motion via `MediaQuery.disableAnimationsOf(context)`
- Haptics via `HapticPort` mapping to `HapticFeedback`

### OOCSS Naming

```
Block: .surface { }
Element: .surface__well { }
Modifier: .surface--hovered { }
State: .is-lifted { }
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
  border-radius: var(--radius-outer-md);
}
```

### Progress Indicators

- **Determinate**: progress bar with `role="progressbar"`, `aria-valuenow/min/max`
- **Indeterminate**: spinner (`animation: spin var(--duration-spinner) linear infinite`)

```css
.spinner {
  width: var(--size-spinner-md);
  height: var(--size-spinner-md);
  border: var(--border-width, 1px) solid var(--border-primary);
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

**Every retry is a user action and must produce feedback** — visual/AT only; haptics are a separate optional channel. Retry controls share the Button Shape Spec (`surface-type: control`, `exit: none`).

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

Web adapter feature-detects `navigator.vibrate` and no-ops when unsupported/disabled. Flutter maps via `HapticFeedback` (lightImpact/selectionClick/notificationImpact/errorImpact). Honor OS settings and `prefers-reduced-motion` as a conservative disable proxy.

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

### Motion Library & Shape Spec

| Rule | Severity | Description |
|------|----------|-------------|
| `animation-from-library` | WARNING | Keyframes/classes from registry — no ad-hoc `@keyframes` |
| `morph-uses-library-tokens` | WARNING | Radius transitions use `--duration-morph` + `--easing-morph`; lift/peel use `--easing-peel` |
| `shape-spec-match` | ERROR | Structure, radius tokens (outer/inner pair when Q5=yes), elevation, motion bundle match the Shape Spec |
| `pattern-4-dual-radius` | ERROR | Pattern 4 surfaces with an inner well must set both `--radius-outer-*` and `--radius-inner-*` |
| `pattern-4-peel-exit` | WARNING | Pattern 4 dismiss/exit animations must use `peelOff`, not `fadeOut` |

### Accessibility

`aria-required-for-inputs`, `aria-invalid-on-error`, `error-has-role-alert`, `focus-visible-ring`, `reduced-motion-support`, `contrast-ratio`.

### Component Structure

`no-divitis`, `semantic-html`, `angular-standalone` (ERROR), `angular-onpush` (ERROR), `angular-signal-inputs`.

### CSS Architecture

`no-important` (ERROR), `no-id-selectors` (ERROR), `max-nesting-depth` (WARNING), `contain-layout` (INFO).

### Reaction Design (review-level)

`reaction-within-budget`, `reaction-weight-match`, `no-silent-wait` (ERROR), `prefer-undo-over-confirm`, `same-action-same-reaction`.

## Core Principles

1. **Minimal DOM Complexity** — flat HTML; surface + well structure only when required
2. **CSS Variables for All Colors** — never hardcode colors
3. **Accessibility by Default** — visible focus, WCAG AA, keyboard nav
4. **Progressive Enhancement** — base works without JS; enhanced interactions layer on top
5. **Separation of Concerns** — HTML structure, CSS presentation, TS interactivity
6. **Consistent Token Usage** — never ad-hoc values
7. **Interaction Completeness** — hover/focus/active/disabled on every interactive element
8. **Responsive by Design** — desktop-first; container queries
9. **Theme Agnostic** — components work in any theme via CSS variables
10. **Performance Conscious** — transform/opacity; OnPush; `trackBy`
11. **Visual Hierarchy** — typography scale, opacity, spacing rhythm
12. **Opacity-Based Hierarchy** — text 100/70/50/30; interaction 100/90/80/50
13. **Internationalization Ready** — logical properties, text expansion, bidi
14. **Error Prevention** — validation, clear errors, recovery paths
15. **Progressive Disclosure** — show only what's needed
16. **Consistent Interaction Patterns** — similar components behave similarly
17. **Documentation as Code** — decisions documented via tokens/contracts/Shape Spec
18. **Dual-Radius Morph** — outer shell + inner well radii transition together on the same clock (`--duration-morph` + `--easing-morph`); hover = lift + optional radius bloom; dismiss = `peelOff`
19. **Action Acknowledgement** — every action gets visual/AT feedback at dispatch; async shows pending → outcome; retries re-ack and surface settled outcome with attempt feedback; haptics are a separate optional channel
20. **Reaction Design** — feedback present *and* right: time budgets, weight match, microinteraction anatomy, escalation, undo over confirm, dedupe, continuity, congruence, identical reactions

## Usage

When generating UI code:

1. **Understand the context** — dashboard, SaaS, portfolio, e-commerce
2. **Confirm the pattern** — this skill is Morphic Surfaces (Dual-Radius Morph)
3. **Run the shape questionnaire** — answer Q1-Q6, resolve the Shape Spec (hybrid mode: infer from context, ask only when ambiguous)
4. **Apply all tokens** — dual-radius tokens (`--radius-outer-*`, `--radius-inner-*`), morph motion (`--duration-morph`, `--easing-morph`, `--easing-peel`), dynamic shadows
5. **Follow component contracts** — Surface Contract requires the well when Q5 = yes
6. **Implement all interaction states** (hover, focus, active, disabled) and the async lifecycle (ack → pending → success/error/retry)
7. **Use animations from the library** — lift/morph/peel recipes only
8. **Ensure accessibility** (WCAG AA) and **usability** (Nielsen)
9. **Apply haptics** (optional separate channel) on discrete commits only
10. **Tune the reaction** — time budgets, weight, undo-vs-confirm
11. **Verify against the Evaluation Rubric** (including Consistency: same questionnaire answers ⇒ identical Shape Spec)

## Evaluation Rubric

1. **Token Accuracy**: Are specific CSS values strictly applied without deviation?
2. **Shape Spec Consistency**: Does the component match the Shape Spec resolved by the questionnaire (same answers ⇒ identical radius, elevation, structure, motion bundle)?
3. **Dual-Radius Correctness**: With Q5 = yes, are both `--radius-outer-*` and `--radius-inner-*` set and transitioned together on the same clock?
4. **Structural Fidelity**: Does HTML follow the surface + well structure (or omit the well when Q5 = no)?
5. **Interaction Completeness**: Are all hover/focus/active/disabled states implemented? Do async controls implement the full lifecycle (ack → pending → success/error/retry)?
6. **Theme Adaptability**: All colors via CSS variables, not hardcoded hex/RGB?
7. **Accessibility Compliance**: WCAG AA (contrast, keyboard, ARIA)?
8. **Usability Compliance**: Nielsen heuristics?
9. **Visual Hierarchy**: clear reading order through typography, opacity, spacing?
10. **Angular Idiomatic**: standalone, OnPush, signals, DI patterns?
11. **Lint Compliance**: `pattern-4-dual-radius`, `pattern-4-peel-exit`, `shape-spec-match`, `morph-uses-library-tokens`, no hardcoded values, no emojis, Lucide only?
12. **Hexagonal Purity**: domain has zero framework imports; components depend on ports
13. **Motion Compliance**: animations from library, motion tokens, `prefers-reduced-motion`, peel vs fade binding rule
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
- <https://web.dev/learn/css/> — Learn CSS
- <https://www.w3.org/TR/css-logical-1/> — CSS Logical Properties

### Angular
- <https://angular.dev/guide/components> — Components Guide
- <https://angular.dev/guide/signals> — Signals
- <https://angular.dev/guide/animations> — Animations
- <https://angular.dev/guide/di> — Dependency Injection