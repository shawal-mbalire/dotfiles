# Design Patterns

Patterns provide visual approaches for structuring UI. The choice between patterns is user discretion based on project needs, brand identity, and design goals. All patterns address core design concerns: accessibility, responsiveness, theme adaptability, and interaction completeness.

## Base Components

Base components provide inherited structure for all patterns. They establish consistent container behavior and spacing without visual decoration.

### Container

**Purpose**: Outer wrapper for content grouping
**Required Tokens**: --bg-primary, --space-md, --space-lg
**Characteristics**:
- No background color (inherits from parent)
- No border
- No shadow
- Provides padding/margin for content spacing
- Responsive width constraints

```css
.container {
  width: 100%;
  max-width: var(--container-max-width, 1200px);
  margin-inline: auto;
  padding-inline: var(--space-md);
}

@media (min-width: 768px) {
  .container {
    padding-inline: var(--space-lg);
  }
}
```

### Wrapper

**Purpose**: Inner content grouping within containers
**Required Tokens**: --bg-primary, --space-sm, --space-md
**Characteristics**:
- Optional background differentiation
- Optional subtle border or shadow
- Provides internal spacing
- Semantic wrapper for related content

```css
.wrapper {
  padding: var(--space-md);
}

.wrapper--elevated {
  background: var(--surface-primary);
  border-radius: var(--border-radius);
}

.wrapper--bordered {
  border: var(--border-width) solid var(--border-primary);
}
```

### Section

**Purpose**: Page-level content division
**Required Tokens**: --bg-primary, --space-lg, --space-xl
**Characteristics**:
- Full-width container
- Vertical spacing between sections
- Optional background color
- No decorative elements

```css
.section {
  padding-block: var(--space-lg);
}

.section--alt {
  background: var(--surface-primary);
}

@media (min-width: 768px) {
  .section {
    padding-block: var(--space-xl);
  }
}
```

### Base Component Rules

1. **No Decorative Gradients**: Base components MUST NOT use gradients for visual decoration (backgrounds, borders, fills). Use flat, solid colors only. Exception: functional animations like skeleton screen shimmers are permitted.
2. **Minimal Decoration**: Borders, shadows, and backgrounds are optional and pattern-specific.
3. **Responsive by Default**: All base components adapt to viewport width.
4. **Semantic HTML**: Use `<header>`, `<main>`, `<section>`, `<article>`, `<aside>` before `<div>`.
5. **Inheritance**: Base components inherit typography, color, and spacing from root/theme.

---

## Pattern 1: Multi-Theme Containers & Controls

**Objective**: Implement structural UI elements (cards, buttons, sections) that support seamless switching between distinct color palettes while maintaining a strict, uniform geometric aesthetic.

### Design Tokens

- **Border Radius**: Strict adherence to `var(--border-radius)` for all structural elements (cards, buttons, input fields). Do not use fully rounded/pill-shaped corners unless explicitly requested for a specific icon button.
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

**Transitions**:
- Transitions (via motion tokens):
  - Background color: `transition: background-color var(--duration-normal) var(--easing-default)`
  - Box shadow: `transition: box-shadow var(--duration-normal) var(--easing-default)`
  - Transform: `transition: transform var(--duration-fast) var(--easing-default)`

## Pattern 2: Interactive Numbered List (Mono Tone)

**Objective**: Build a minimalist, highly scannable directory list where items act as full-width interactive rows, emphasizing typography and clean hover interactions over heavy card containers. This pattern uses a mono tone color scheme - single color family with varying lightness/darkness.

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

**Transitions**:
- Transitions (via motion tokens):
  - Background color: `transition: background-color var(--duration-normal) var(--easing-default)`
  - Transform: `transition: transform var(--duration-normal) var(--easing-default)`
  - Combined: `transition: background-color var(--duration-normal) var(--easing-default), transform var(--duration-normal) var(--easing-default)`

## Pattern 3: Minimalist Flat Theme with Subtle Depth

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

## Pattern 4: Morphic Surfaces (Dual-Radius Morph)

**Objective**: Implement surfaces that read as one continuous material. Components morph between states and into each other by animating paired external (shell) and internal (content well) radii, with tasteful lift/peel motion that feels like layers coming off a surface.

Shape handling for this pattern is governed by the questionnaire in [decision-rules.md](./decision-rules.md). Animations come from [animations-library.md](./animations-library.md).

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

## Pattern Comparison Matrix

| Attribute | Pattern 1 | Pattern 2 | Pattern 3 | Pattern 4 |
|-----------|-----------|-----------|-----------|-----------|
| **Border Radius** | 5px | N/A | 8-12px | Dual: outer 4-16px + inner 2-8px |
| **Borders** | 1px solid | Bottom separators | Avoided | Optional hairline / none |
| **Shadows** | None | None | Subtle elevation | Dynamic (lift states) |
| **Color Palette** | Full theme via CSS vars | Mono tone (single color family) | 3-5 core colors | Full theme via CSS vars |
| **Primary Interaction** | Background shift | Row highlight + arrow | Shadow elevation | Radius morph + lift |
| **Hover Transition** | `--duration-normal` | `--duration-normal` | `--duration-slow` | `--duration-morph` / `--duration-normal` lift |
| **Theme Switching** | Yes (multi-theme) | Single theme | Dual (light/dark) | Yes (multi-theme) |
| **Gradients** | Prohibited | Prohibited | Prohibited | Prohibited |

## Angular Pattern Implementation

### Pattern Switching Service

```typescript
import { Injectable, signal } from '@angular/core';

export type PatternId = 1 | 2 | 3 | 4;

@Injectable({ providedIn: 'root' })
export class PatternService {
  readonly activePattern = signal<PatternId>(1);

  setPattern(id: PatternId): void {
    this.activePattern.set(id);
  }
}
```

### Pattern-Aware Component

```typescript
import { Component, ChangeDetectionStrategy, inject, computed } from '@angular/core';
import { PatternService } from './pattern.service';

@Component({
  selector: 'app-pattern-card',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <article [class]="cardClasses()">
      <ng-content></ng-content>
    </article>
  `
})
export class PatternCardComponent {
  private patternService = inject(PatternService);

  cardClasses = computed(() => {
    const pattern = this.patternService.activePattern();
    return {
      'card': true,
      'card--pattern-1': pattern === 1,
      'card--pattern-2': pattern === 2,
      'card--pattern-3': pattern === 3,
      'card--pattern-4': pattern === 4
    };
  });
}
```

### Pattern-Specific SCSS

```scss
// Pattern 1: Strict geometric, pattern radius, visible borders
:host(.card--pattern-1) {
  border: var(--border-width) solid var(--border-primary);
  border-radius: var(--border-radius);
  box-shadow: none;
}

// Pattern 2: Sharp edges, mono tone, bottom separators
:host(.card--pattern-2) {
  border-radius: 0;
  border-bottom: var(--border-width) solid var(--border-secondary);
  background: var(--surface-primary);
}

// Pattern 3: Soft radius, subtle shadows, no borders
:host(.card--pattern-3) {
  border: none;
  border-radius: var(--border-radius-xl);
  box-shadow: var(--shadow-sm);
}

// Pattern 4: Dual-radius morph, dynamic lift shadows, peel exits
:host(.card--pattern-4) {
  border: none;
  border-radius: var(--radius-outer-lg);
  box-shadow: var(--shadow-sm);
  transition: border-radius var(--duration-morph) var(--easing-morph),
              transform var(--duration-normal) var(--easing-peel),
              box-shadow var(--duration-slow) var(--easing-default);
}

:host(.card--pattern-4:hover) {
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
  border-radius: var(--radius-outer-xl);
}
```

## Token Reference by Category

| Category | Pattern 1 Tokens | Pattern 2 Tokens | Pattern 3 Tokens | Pattern 4 Tokens |
|----------|------------------|------------------|------------------|------------------|
| **Background** | --bg-primary, --bg-secondary | --bg-primary | --bg-primary | --bg-primary |
| **Surface** | --surface-primary | --surface-primary | --surface-primary | --surface-primary |
| **Text** | --text-primary, --text-secondary | --text-primary, --text-secondary | --text-primary | --text-primary, --text-secondary |
| **Border** | --border-primary | --border-primary, --border-secondary | N/A | Optional --border-primary |
| **Accent** | --accent-primary | N/A (mono tone) | --accent-primary | --accent-primary |
| **Shadow** | N/A | N/A | --shadow-sm, --shadow-md, --shadow-lg | --shadow-sm, --shadow-md (dynamic) |
| **Radius** | --border-radius | 0 | --border-radius-lg, --border-radius-xl | --radius-outer-*, --radius-inner-* |
| **Motion** | --duration-normal, --easing-default | --duration-normal, --easing-default | --duration-slow, --easing-default | --duration-morph, --easing-morph, --easing-peel |

## Component Cheat Sheet

| Component | Required Tokens | Border Radius | Transitions |
|-----------|-----------------|---------------|-------------|
| Card | --bg-primary, --border-primary, --shadow-md | `--border-radius` (P1), `--border-radius-lg/xl` (P3), dual outer/inner (P4) | box-shadow `--duration-slow`; P4: + radius morph `--duration-morph` |
| Button | --bg-primary, --text-primary, --accent-primary | `--border-radius` | background-color `--duration-normal`, transform `--duration-fast` |
| ListItem | --bg-primary, --text-primary, --border-secondary | `0` (P2) / pattern default | background-color `--duration-normal`, transform `--duration-normal` |
| Navigation | --bg-primary, --text-primary, --border-primary | `--border-radius` | background-color `--duration-normal` |
| Input | --bg-primary, --text-primary, --border-primary, --border-focus | `--border-radius` | border-color `--duration-normal` |
