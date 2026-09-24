# Design Tokens Reference

Design tokens are the foundation of the design system. They are documented as references, not full CSS definitions.

## Visual Hierarchy Principles

Visual hierarchy is established through three primary mechanisms:

1. **Typography Scale**: Font size, weight, and line height create reading order
2. **Color Opacity**: Text and element opacity indicate importance levels
3. **Spacing Rhythm**: Consistent spacing creates visual relationships

## Color Tokens

| Token Category | Token Names | Purpose |
|----------------|-------------|---------|
| **Background** | --bg-primary, --bg-secondary, --bg-tertiary | Page and container backgrounds |
| **Surface** | --surface-primary, --surface-secondary, --surface-elevated | Card, modal, dropdown backgrounds |
| **Text** | --text-primary, --text-secondary, --text-tertiary | Heading, body, caption text |
| **Text on Accent** | --text-on-accent | Text on accent-colored backgrounds (buttons, badges) |
| **Border** | --border-primary, --border-secondary, --border-focus | Structural borders, focus rings |
| **Accent** | --accent-primary, --accent-secondary, --accent-hover | Interactive element highlights |
| **State** | --state-success, --state-warning, --state-error, --state-info | Feedback and validation |

### Text Opacity Hierarchy

Text opacity creates visual importance without changing hue:

| Level | Token | Opacity | Use Case |
|-------|-------|---------|----------|
| **Primary** | --text-primary | 100% | Headings, important labels, active content |
| **Secondary** | --text-secondary | 70% | Body text, descriptions, supporting content |
| **Tertiary** | --text-tertiary | 50% | Captions, hints, disabled text, metadata |
| **Disabled** | --text-disabled | 30% | Inactive elements, placeholder text |

**Fallback for busy backgrounds**: When text overlays images or gradients, do not use opacity-based hierarchy. Instead, use solid colors with sufficient contrast:
- Apply a semi-transparent overlay behind text (e.g., `background: var(--bg-overlay)`)
- Use solid color tokens with verified contrast ratios (4.5:1 for normal text, 3:1 for large text)
- Test contrast using tools like WebAIM Contrast Checker

```css
:root {
  --text-primary: rgba(var(--text-color-rgb), 1);
  --text-secondary: rgba(var(--text-color-rgb), 0.7);
  --text-tertiary: rgba(var(--text-color-rgb), 0.5);
  --text-disabled: rgba(var(--text-color-rgb), 0.3);
}

/* Light theme */
[data-theme="light"] {
  --text-color-rgb: 33, 37, 41; /* #212529 */
}

/* Dark theme */
[data-theme="dark"] {
  --text-color-rgb: 248, 249, 250; /* #f8f9fa */
}
```

### Background Opacity Hierarchy

Background opacity indicates layering and importance:

| Level | Token | Opacity | Use Case |
|-------|-------|---------|----------|
| **Base** | --bg-primary | 100% | Page background |
| **Surface** | --bg-secondary | 100% | Card backgrounds, elevated surfaces |
| **Overlay** | --bg-overlay | 50-80% | Modal backdrops, tooltips |
| **Subtle** | --bg-subtle | 10-20% | Hover states, subtle emphasis |

## Typography Tokens

### Type Scale

| Token | Size | Line Height | Use Case |
|-------|------|-------------|----------|
| --font-size-xs | 0.75rem (12px) | 1rem | Captions, labels, metadata |
| --font-size-sm | 0.875rem (14px) | 1.25rem | Secondary text, descriptions |
| --font-size-base | 1rem (16px) | 1.5rem | Body text, paragraphs |
| --font-size-lg | 1.125rem (18px) | 1.75rem | Lead paragraphs, emphasis |
| --font-size-xl | 1.25rem (20px) | 1.75rem | Subheadings, card titles |
| --font-size-2xl | 1.5rem (24px) | 2rem | Section headings |
| --font-size-3xl | 1.875rem (30px) | 2.25rem | Page titles |
| --font-size-4xl | 2.25rem (36px) | 2.5rem | Hero headings |
| --font-size-5xl | 3rem (48px) | 3rem | Display headings, hero sections |
| --font-size-6xl | 3.75rem (60px) | 3.75rem | Large display, landing page heroes |
| --font-size-7xl | 4.5rem (72px) | 4.5rem | Maximum display size |

### Font Weight Hierarchy

| Token | Weight | Use Case |
|-------|--------|----------|
| --font-weight-light | 300 | Large display text, decorative headings |
| --font-weight-normal | 400 | Body text, paragraphs |
| --font-weight-medium | 500 | Labels, emphasized text, navigation |
| --font-weight-semibold | 600 | Subheadings, important labels |
| --font-weight-bold | 700 | Headings, strong emphasis |

### Typography Hierarchy Rules

1. **Heading Scale**: Use consistent size progression (h1 > h2 > h3)
2. **Weight Contrast**: Bold headings, normal body text
3. **Line Height**: Tighter for headings, relaxed for body text
4. **Letter Spacing**: Tighter for large text, normal for body

```css
/* Heading hierarchy */
h1 { 
  font-size: var(--font-size-3xl); 
  font-weight: var(--font-weight-bold);
  line-height: var(--line-height-tight);
  letter-spacing: var(--tracking-tight);
}

h2 { 
  font-size: var(--font-size-2xl); 
  font-weight: var(--font-weight-semibold);
  line-height: var(--line-height-tight);
}

h3 { 
  font-size: var(--font-size-xl); 
  font-weight: var(--font-weight-medium);
  line-height: var(--line-height-normal);
}

/* Body text hierarchy */
.body-primary {
  font-size: var(--font-size-base);
  font-weight: var(--font-weight-normal);
  line-height: var(--line-height-relaxed);
}

.body-secondary {
  font-size: var(--font-size-sm);
  font-weight: var(--font-weight-normal);
  line-height: var(--line-height-normal);
  color: var(--text-secondary);
}

.caption {
  font-size: var(--font-size-xs);
  font-weight: var(--font-weight-normal);
  line-height: var(--line-height-normal);
  color: var(--text-tertiary);
}
```

### Font Family Tokens

| Token | Purpose |
|-------|---------|
| --font-heading | Headings, titles, emphasis |
| --font-body | Body text, paragraphs, labels |
| --font-mono | Code, technical content, data |

## Border Radius Tokens

| Token | Value | Use Case |
|-------|-------|----------|
| --border-radius-sm | 3px | Small elements (badges, tags) |
| --border-radius | 5px | Standard components (cards, buttons, inputs) |
| --border-radius-lg | 8px | Elevated surfaces, modals |
| --border-radius-xl | 12px | Large containers, pattern 3 flat theme |
| --border-radius-full | 9999px | Pill shapes, circular avatars |

**Rules:**
- Always use border-radius tokens, never raw values
- Pattern 1 uses `--border-radius` (5px) for strict geometric consistency
- Pattern 2 uses `0` (sharp edges) — override at component level
- Pattern 3 uses `--border-radius-lg` or `--border-radius-xl` for softer aesthetics
- Pattern 4 uses paired dual-radius tokens (below) for shell + well morphing

### Dual Radius Tokens (Pattern 4)

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

**Morph rule**: whenever `--radius-outer-*` transitions, the paired `--radius-inner-*` on the well element transitions on the same clock (`--duration-morph` + `--easing-morph`). See [decision-rules.md](./decision-rules.md) Q5/Q6.

## Spacing Scale

Spacing follows a conceptual scale. Use consistent relative sizing:

| Token | Concept | Typical Use |
|-------|---------|-------------|
| --space-xs | Extra small | Tight padding, small gaps |
| --space-sm | Small | Input padding, inline spacing |
| --space-md | Medium | Component padding, card gaps |
| --space-lg | Large | Section padding, major gaps |
| --space-xl | Extra large | Page sections, hero spacing |
| --space-2xl | Double extra large | Major layout divisions |
| --space-3xl | Triple extra large | Full-page sections, hero blocks |

## Elevation Tokens

Shadow tokens indicate depth and hierarchy:

| Token | Concept | Use Case |
|-------|---------|----------|
| --shadow-sm | Subtle | resting state for flat elements |
| --shadow-md | Medium | Card resting state |
| --shadow-lg | Elevated | Card hover, dropdown menus |
| --shadow-xl | Highest | Modals, dialogs, popovers |
| --shadow-hover | Interactive lift | Hover elevation (Pattern 3/4) |
| --shadow-active | Pressed | Active/pressed elevation (Pattern 3/4) |

**Rules:**
- Never write raw `box-shadow` values in component CSS — define elevation changes as theme-level tokens (`--shadow-hover`, `--shadow-active`) when a state needs a custom shadow.

## Border Width Token

| Token | Value | Use Case |
|-------|-------|----------|
| --border-width | 1px | Standard structural borders (Pattern 1) |

## Focus Ring Tokens

| Token | Value | Use Case |
|-------|-------|----------|
| --border-focus-width | 2px | Focus indicator width |
| --border-focus-offset | 2px | Focus indicator offset from element |

## Overlay Token

| Token | Value | Use Case |
|-------|-------|----------|
| --bg-overlay | rgba(0, 0, 0, 0.5) | Modal backdrops, scrims |

## State Soft Tokens

Soft background tints for feedback surfaces (error banners, success toasts):

| Token | Use Case |
|-------|----------|
| --state-success-soft | Success background tint |
| --state-warning-soft | Warning background tint |
| --state-error-soft | Error background tint |
| --state-info-soft | Info background tint |

## Size Tokens

Fixed component dimensions (not spacing):

| Token | Value | Use Case |
|-------|-------|----------|
| --size-sidebar | 250px | Sidebar width |
| --size-modal-max | 500px | Modal max-inline-size |
| --size-toast-min | 300px | Toast min-inline-size |
| --size-toast-max | 450px | Toast max-inline-size |
| --size-icon-sm | 16px | Small inline icon/spinner |
| --size-spinner-sm | 20px | Small spinner |
| --size-spinner-md | 40px | Default spinner |
| --size-spinner-lg | 60px | Large spinner |

## Motion Tokens

| Token | Concept | Use Case |
|-------|---------|----------|
| --duration-instant | 0ms | Immediate response |
| --duration-fast | 100ms | Micro-interactions (button press) |
| --duration-normal | 200ms | Standard transitions (hover states) |
| --duration-slow | 300ms | Complex animations (modals, drawers) |
| --duration-morph | 350ms | Dual-radius morph transitions (Pattern 4) |
| --duration-slower | 500ms | Page transitions |
| --duration-spinner | 1000ms | Spinner rotation cycle |
| --duration-loading | 1500ms | Skeleton shimmer cycle |

**Easing Functions:**

| Token | Value | Use Case |
|-------|-------|----------|
| --easing-default | cubic-bezier(0.4, 0, 0.2, 1) | Most transitions |
| --easing-in | cubic-bezier(0.4, 0, 1, 1) | Elements exiting |
| --easing-out | cubic-bezier(0, 0, 0.2, 1) | Elements entering |
| --easing-in-out | cubic-bezier(0.42, 0, 0.58, 1) | Symmetric animations |
| --easing-morph | cubic-bezier(0.65, 0, 0.35, 1) | Symmetric shape morphs (radius pairs) |
| --easing-peel | cubic-bezier(0.33, 1, 0.68, 1) | Lift-off / peel exits ("coming off") |
| --easing-bounce | cubic-bezier(0.68, -0.55, 0.265, 1.55) | Playful emphasis |

## Z-index Scale

Layering tokens prevent z-index conflicts:

| Token | Value | Use Case |
|-------|-------|----------|
| --z-below | -1 | Background elements |
| --z-base | 0 | Default stacking |
| --z-above | 1 | Above siblings |
| --z-dropdown | 1000 | Dropdown menus |
| --z-sticky | 1020 | Sticky headers |
| --z-fixed | 1030 | Fixed position elements |
| --z-overlay | 1040 | Backdrops, overlays |
| --z-modal | 1050 | Modal dialogs |
| --z-popover | 1060 | Popovers, tooltips |
| --z-tooltip | 1070 | Tooltips |
| --z-toast | 1080 | Toast notifications |

**Rules:**
- Never use raw z-index values
- Always use z-index tokens
- Document stacking context creation
- Avoid z-index above 1000

## Breakpoint Tokens (Desktop-First)

| Token | Value | Target |
|-------|-------|--------|
| --bp-xs | 0 | Mobile portrait |
| --bp-sm | 576px | Mobile landscape |
| --bp-md | 768px | Tablet |
| --bp-lg | 992px | Desktop |
| --bp-xl | 1200px | Large desktop |
| --bp-xxl | 1400px | Extra large desktop |

**Usage (Desktop-First):**

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
