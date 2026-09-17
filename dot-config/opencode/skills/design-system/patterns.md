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
  border: 1px solid var(--border-primary);
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

1. **No Gradients**: Base components MUST NOT use gradients. Use flat, solid colors only.
2. **Minimal Decoration**: Borders, shadows, and backgrounds are optional and pattern-specific.
3. **Responsive by Default**: All base components adapt to viewport width.
4. **Semantic HTML**: Use `<header>`, `<main>`, `<section>`, `<article>`, `<aside>` before `<div>`.
5. **Inheritance**: Base components inherit typography, color, and spacing from root/theme.

---

## Pattern 1: Multi-Theme Containers & Controls

**Objective**: Implement structural UI elements (cards, buttons, sections) that support seamless switching between distinct color palettes while maintaining a strict, uniform geometric aesthetic.

### Design Tokens

- **Border Radius**: Strict adherence to `border-radius: 5px` for all structural elements (cards, buttons, input fields). Do not use fully rounded/pill-shaped corners unless explicitly requested for a specific icon button.
- **Borders**: All containers, buttons, and distinct UI sections MUST have uniform border. Apply `border: 1px solid var(--border-color)`.
- **Spacing**: Use mathematically even padding and margins (conceptual scale: xs, sm, md, lg) to ensure 1px borders align cleanly on the grid.
- **Colors**: NEVER hardcode color values in the component CSS. All backgrounds, text, and border colors must map to CSS variable tokens defined in the root theme stylesheet.

### Interactions

| State | Property | Value |
|-------|----------|-------|
| Hover (card) | box-shadow | increase elevation |
| Hover (button) | background-color | --accent-hover |
| Hover (link) | background-color | --surface-primary |
| Focus (all) | outline | 2px solid --border-focus |
| Active (button) | transform | scale(0.98) |
| Disabled | opacity | 0.5 |

**Transitions**:
- Background color: `transition: background-color 0.25s ease`
- Box shadow: `transition: box-shadow 0.25s ease`
- Transform: `transition: transform 0.15s ease`

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

**Gray Mono Tone**
| Token | Value |
|-------|-------|
| --bg-primary | #ffffff |
| --surface-primary | #f8f9fa |
| --text-primary | #212529 |
| --text-secondary | #6c757d |
| --border-primary | #dee2e6 |
| --border-secondary | #e9ecef |

**Blue Mono Tone**
| Token | Value |
|-------|-------|
| --bg-primary | #f8f9fa |
| --surface-primary | #e9ecef |
| --text-primary | #212529 |
| --text-secondary | #495057 |
| --border-primary | #ced4da |
| --border-secondary | #dee2e6 |

**Slate Mono Tone**
| Token | Value |
|-------|-------|
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
| Focus (row) | outline | 2px solid --border-focus |
| Active (row) | background-color | --surface-secondary |
| Disabled | opacity | 0.5 |

**Transitions**:
- Background color: `transition: background-color 0.2s ease`
- Transform: `transition: transform 0.2s ease`
- Combined: `transition: background-color 0.2s ease, transform 0.2s ease`

## Pattern 3: Minimalist Flat Theme with Subtle Depth

**Objective**: Implement clean, modern interface utilizing strict dual-theme (Light/Dark) system with a highly restricted color palette. The design relies on flat backgrounds accented only by soft, subtle box-shadows to indicate elevation and interactive states, avoiding harsh borders or excessive visual noise.

### Design Tokens

- **Color Discipline**: Agents MUST NOT introduce colors outside the defined 3-5 color palette. Gradients are prohibited.
- **Border Radius**: Use a moderate, modern border radius (e.g., `border-radius: 8px` or `12px`) to soften the flat design. It should be slightly larger than Pattern 1's 5px.
- **Elevation (Shadows)**: Do not use visible borders to separate main content areas. Instead, use very soft, diffused shadow for elevated elements (cards, modals).
  - Light Theme: `box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05)`
  - Dark Theme: `box-shadow: 0 4px 6px rgba(0, 0, 0, 0.2)`

### Minimal Color Palettes

Use these restricted palettes (3-5 colors maximum):

**Clean Light**
| Token | Value |
|-------|-------|
| --bg-primary | #ffffff |
| --surface-primary | #f8f9fa |
| --text-primary | #212529 |
| --accent-primary | #0d6efd |

**Clean Dark**
| Token | Value |
|-------|-------|
| --bg-primary | #121212 |
| --surface-primary | #1e1e1e |
| --text-primary | #e0e0e0 |
| --accent-primary | #64b5f6 |

**Warm Light**
| Token | Value |
|-------|-------|
| --bg-primary | #fafaf8 |
| --surface-primary | #f5f5f0 |
| --text-primary | #2d2d2d |
| --accent-primary | #d97706 |

**Warm Dark**
| Token | Value |
|-------|-------|
| --bg-primary | #1a1814 |
| --surface-primary | #2d2a24 |
| --text-primary | #e8e4de |
| --accent-primary | #fbbf24 |

### Interactions

| State | Property | Value |
|-------|----------|-------|
| Hover (card) | box-shadow | 0 8px 15px rgba(0,0,0,0.08) light / 0 8px 15px rgba(0,0,0,0.25) dark |
| Hover (link) | text-decoration | underline |
| Focus (all) | outline | 2px solid --accent-primary |
| Active (card) | box-shadow | 0 2px 4px rgba(0,0,0,0.03) light / 0 2px 4px rgba(0,0,0,0.15) dark |
| Disabled | opacity | 0.5 |

**Transitions**:
- Box shadow: `transition: box-shadow 0.3s ease`
- Text decoration: `transition: text-decoration-color 0.2s ease`
- Transform (if used): `transition: transform 0.2s ease`

## Pattern Comparison Matrix

| Attribute | Pattern 1 | Pattern 2 | Pattern 3 |
|-----------|-----------|-----------|-----------|
| **Border Radius** | 5px | N/A | 8-12px |
| **Borders** | 1px solid | Bottom separators | Avoided |
| **Shadows** | None | None | Subtle elevation |
| **Color Palette** | Full theme via CSS vars | Mono tone (single color family) | 3-5 core colors |
| **Primary Interaction** | Background shift | Row highlight + arrow | Shadow elevation |
| **Hover Transition** | 0.25s ease | 0.2s ease | 0.3s ease |
| **Theme Switching** | Yes (multi-theme) | Single theme | Dual (light/dark) |
| **Gradients** | Prohibited | Prohibited | Prohibited |

## Token Reference by Category

| Category | Pattern 1 Tokens | Pattern 2 Tokens | Pattern 3 Tokens |
|----------|------------------|------------------|------------------|
| **Background** | --bg-primary, --bg-secondary | --bg-primary | --bg-primary |
| **Surface** | --surface-primary | --surface-primary | --surface-primary |
| **Text** | --text-primary, --text-secondary | --text-primary, --text-secondary | --text-primary |
| **Border** | --border-primary | --border-primary, --border-secondary | N/A |
| **Accent** | --accent-primary | N/A (mono tone) | --accent-primary |
| **Shadow** | N/A | N/A | --shadow-sm, --shadow-md, --shadow-lg |

## Component Cheat Sheet

| Component | Required Tokens | Border Radius | Transitions |
|-----------|-----------------|---------------|-------------|
| Card | --bg-primary, --border-primary, --shadow-md | 5px (P1), 8-12px (P3) | box-shadow 0.3s ease |
| Button | --bg-primary, --text-primary, --accent-primary | 5px | background-color 0.2s ease, transform 0.15s ease |
| ListItem | --bg-primary, --text-primary, --border-secondary | N/A | background-color 0.2s ease, transform 0.2s ease |
| Navigation | --bg-primary, --text-primary, --border-primary | 5px | background-color 0.2s ease |
| Input | --bg-primary, --text-primary, --border-primary, --border-focus | 5px | border-color 0.2s ease |
