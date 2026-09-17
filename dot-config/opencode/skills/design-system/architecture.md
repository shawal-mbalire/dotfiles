# CSS Architecture Guidelines

## Box Model

All elements must use `border-box` sizing:

```css
*, *::before, *::after {
  box-sizing: border-box;
}
```

## Specificity Management

Keep selectors flat and maintainable:

| Do | Don't |
|----|-------|
| `.card__title` | `div.card > h2.title` |
| `.btn--primary` | `.container .wrapper .button.primary` |
| `.nav.is-active` | `#navigation ul li a.active` |

**Rules:**
- Never use `!important`
- Avoid ID selectors for styling
- Maximum 3 levels of nesting
- Use classes, not tags, for styling

## OOCSS Naming Convention

Follow Object-Oriented CSS naming:

```
Block: .card { }
Element: .card__header { }
Modifier: .card--elevated { }
State: .is-active { }
```

**Structure:**
- **Block**: Standalone entity (`.card`, `.nav`, `.btn`)
- **Element**: Part of a block (`.card__title`, `.nav__item`)
- **Modifier**: Variation or state (`.card--dark`, `.btn--small`)
- **State**: JavaScript-toggled state (`.is-open`, `.is-disabled`)

## CSS Nesting

Use CSS Nesting for component-scoped styles:

```css
.card {
  background: var(--surface-primary);
  border-radius: 8px;

  &__header {
    padding: var(--space-md);
    border-bottom: 1px solid var(--border-primary);
  }

  &__body {
    padding: var(--space-lg);
  }

  &--elevated {
    box-shadow: var(--shadow-md);
  }

  &:hover {
    box-shadow: var(--shadow-lg);
  }
}
```

## Logical Properties

Use logical properties for internationalization:

| Physical | Logical | Purpose |
|----------|---------|---------|
| `margin-left` | `margin-inline-start` | RTL support |
| `padding-right` | `padding-inline-end` | RTL support |
| `width` | `inline-size` | Writing mode agnostic |
| `height` | `block-size` | Writing mode agnostic |
| `text-align: left` | `text-align: start` | RTL support |

## File Organization

### Component-Based Structure
```
styles/
├── base/           # Reset, typography, global styles
│   ├── reset.css
│   ├── typography.css
│   └── global.css
├── components/     # Individual component styles
│   ├── button.css
│   ├── card.css
│   ├── input.css
│   └── navigation.css
├── layouts/        # Layout patterns
│   ├── grid.css
│   ├── sidebar.css
│   └── container.css
├── utilities/      # Helper classes
│   ├── spacing.css
│   ├── visibility.css
│   └── text.css
├── themes/         # Theme definitions
│   ├── light.css
│   └── dark.css
└── main.css        # Imports all modules
```

### CSS Modules Pattern
```css
/* Button.module.css */
.button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: var(--space-sm) var(--space-md);
  border: 1px solid var(--border-primary);
  border-radius: var(--border-radius);
  background: var(--surface-primary);
  color: var(--text-primary);
  font-size: var(--font-size-base);
  cursor: pointer;
  transition: all var(--duration-normal) var(--easing-default);
}

.button:hover {
  background: var(--surface-secondary);
}

.button:focus-visible {
  outline: 2px solid var(--border-focus);
  outline-offset: 2px;
}

.button--primary {
  background: var(--accent-primary);
  color: white;
  border-color: var(--accent-primary);
}

.button--primary:hover {
  background: var(--accent-hover);
}

.button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
```

## Responsive Patterns

### Mobile-First
```css
/* Base styles (mobile) */
.container {
  padding: var(--space-sm);
}

/* Tablet and up */
@media (min-width: 768px) {
  .container {
    padding: var(--space-md);
  }
}

/* Desktop and up */
@media (min-width: 1024px) {
  .container {
    padding: var(--space-lg);
    max-width: 1200px;
    margin: 0 auto;
  }
}
```

### Desktop-First
```css
/* Base styles (desktop) */
.container {
  padding: var(--space-lg);
  max-width: 1200px;
  margin: 0 auto;
}

/* Tablet and below */
@media (max-width: 1024px) {
  .container {
    padding: var(--space-md);
  }
}

/* Mobile and below */
@media (max-width: 768px) {
  .container {
    padding: var(--space-sm);
  }
}
```

## Layout Patterns

### Flexbox Layout
```css
.flex-container {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-md);
}

.flex-item {
  flex: 1 1 300px;
}

.flex-item--wide {
  flex: 2 1 600px;
}
```

### Grid Layout
```css
.grid-container {
  display: grid;
  gap: var(--space-md);
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
}

.grid-item--span-2 {
  grid-column: span 2;
}

.grid-item--span-3 {
  grid-column: span 3;
}
```

### Sidebar Layout
```css
.layout-sidebar {
  display: grid;
  grid-template-columns: 250px 1fr;
  gap: var(--space-lg);
  min-height: 100vh;
}

@media (max-width: 768px) {
  .layout-sidebar {
    grid-template-columns: 1fr;
  }
  
  .sidebar {
    position: fixed;
    left: -250px;
    width: 250px;
    height: 100vh;
    background: var(--surface-primary);
    transition: left 0.3s ease;
    z-index: var(--z-overlay);
  }
  
  .sidebar.open {
    left: 0;
  }
  
  .sidebar-overlay {
    position: fixed;
    inset: 0;
    background: rgba(0, 0, 0, 0.5);
    opacity: 0;
    visibility: hidden;
    transition: opacity 0.3s ease, visibility 0.3s ease;
  }
  
  .sidebar.open + .sidebar-overlay {
    opacity: 1;
    visibility: visible;
  }
}
```

## Utility Classes

### Spacing
```css
.margin-0 { margin: 0; }
.margin-xs { margin: var(--space-xs); }
.margin-sm { margin: var(--space-sm); }
.margin-md { margin: var(--space-md); }
.margin-lg { margin: var(--space-lg); }
.margin-xl { margin: var(--space-xl); }

.padding-0 { padding: 0; }
.padding-xs { padding: var(--space-xs); }
.padding-sm { padding: var(--space-sm); }
.padding-md { padding: var(--space-md); }
.padding-lg { padding: var(--space-lg); }
.padding-xl { padding: var(--space-xl); }

.margin-horizontal-auto { margin-left: auto; margin-right: auto; }
```

### Display
```css
.display-none { display: none; }
.display-block { display: block; }
.display-flex { display: flex; }
.display-grid { display: grid; }
.display-inline { display: inline; }
.display-inline-block { display: inline-block; }
.display-inline-flex { display: inline-flex; }
```

### Flexbox
```css
.flex-row { flex-direction: row; }
.flex-column { flex-direction: column; }
.flex-wrap { flex-wrap: wrap; }
.flex-nowrap { flex-wrap: nowrap; }

.justify-content-start { justify-content: flex-start; }
.justify-content-center { justify-content: center; }
.justify-content-end { justify-content: flex-end; }
.justify-content-between { justify-content: space-between; }
.justify-content-around { justify-content: space-around; }

.align-items-start { align-items: flex-start; }
.align-items-center { align-items: center; }
.align-items-end { align-items: flex-end; }
.align-items-stretch { align-items: stretch; }

.gap-xs { gap: var(--space-xs); }
.gap-sm { gap: var(--space-sm); }
.gap-md { gap: var(--space-md); }
.gap-lg { gap: var(--space-lg); }
.gap-xl { gap: var(--space-xl); }
```

### Text
```css
.text-align-left { text-align: left; }
.text-align-center { text-align: center; }
.text-align-right { text-align: right; }

.text-color-primary { color: var(--text-primary); }
.text-color-secondary { color: var(--text-secondary); }
.text-color-accent { color: var(--accent-primary); }

.font-weight-light { font-weight: var(--font-weight-light); }
.font-weight-normal { font-weight: var(--font-weight-normal); }
.font-weight-medium { font-weight: var(--font-weight-medium); }
.font-weight-bold { font-weight: var(--font-weight-bold); }

.font-size-xs { font-size: var(--font-size-xs); }
.font-size-sm { font-size: var(--font-size-sm); }
.font-size-base { font-size: var(--font-size-base); }
.font-size-lg { font-size: var(--font-size-lg); }
.font-size-xl { font-size: var(--font-size-xl); }
.font-size-2xl { font-size: var(--font-size-2xl); }
```

### Visibility
```css
.visibility-visible { visibility: visible; }
.visibility-hidden { visibility: hidden; }
.overflow-hidden { overflow: hidden; }
.overflow-auto { overflow: auto; }
.overflow-scroll { overflow: scroll; }
```

## Performance Optimization

### Critical CSS
```html
<style>
  /* Inline critical CSS for above-the-fold content */
  .header { padding: 1rem; background: var(--surface-primary); }
  .hero { min-height: 50vh; display: flex; align-items: center; }
</style>
<link rel="preload" href="styles/main.css" as="style" onload="this.onload=null;this.rel='stylesheet'">
```

### CSS Containment
```css
.component {
  contain: layout style paint;
}

.card {
  contain: layout style;
}
```

### Will Change
```css
.animated {
  will-change: transform, opacity;
}

.animated.complete {
  will-change: auto;
}
```
