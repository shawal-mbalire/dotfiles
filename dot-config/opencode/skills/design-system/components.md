# Component Contracts

Components are documented as contracts specifying required elements, tokens, variants, and interactions.

## Visual Hierarchy Guidelines

All components must establish visual hierarchy through:

1. **Typography**: Use size, weight, and color to indicate importance
2. **Opacity**: Apply opacity changes for state and hierarchy
3. **Spacing**: Consistent padding/margins create visual relationships

### Text Hierarchy in Components

| Element | Typography | Opacity | Use Case |
|---------|------------|---------|----------|
| **Title** | --font-size-lg, --font-weight-semibold | 100% | Primary heading, card title |
| **Subtitle** | --font-size-sm, --font-weight-medium | 70% | Secondary heading, description |
| **Body** | --font-size-base, --font-weight-normal | 100% | Main content, paragraphs |
| **Caption** | --font-size-xs, --font-weight-normal | 50% | Metadata, hints, labels |
| **Disabled** | Any | 30% | Inactive text, placeholders |

### Component Opacity States

| State | Opacity | Use Case |
|-------|---------|----------|
| **Default** | 100% | Active, interactive elements |
| **Hover** | 90% | Interactive feedback |
| **Active** | 80% | Pressed state feedback |
| **Disabled** | 50% | Inactive elements |
| **Loading** | 70% | Processing state |

---

## Card Component

**Required Elements**: `<article>`, optional `<header>`, `<section>`, `<footer>`
**Required Tokens**: --bg-primary, --border-primary, --shadow-md
**Variants**:
- `elevated`: shadow-based depth, no visible border
- `bordered`: visible border, minimal shadow
- `flat`: no shadow or border, background differentiation only

### Typography Hierarchy
- **Card Title**: --font-size-lg, --font-weight-semibold, --text-primary (100% opacity)
- **Card Subtitle**: --font-size-sm, --font-weight-medium, --text-secondary (70% opacity)
- **Card Body**: --font-size-base, --font-weight-normal, --text-primary (100% opacity)
- **Card Caption**: --font-size-xs, --font-weight-normal, --text-tertiary (50% opacity)

### Interactions
- Hover: increase shadow elevation (--shadow-md -> --shadow-lg)
- Focus: 2px outline ring using --border-focus
- Transition: `box-shadow 0.3s ease`

### States
- Default: resting state
- Hover: elevated shadow
- Focus: visible outline
- Disabled: `opacity: 0.5`
- Loading: skeleton or spinner overlay

### Accessibility
- Use `<article>` with optional `aria-label` for context
- Ensure focus indicator is visible (2px minimum)

---

## Button Component

**Required Elements**: `<button>` or `<a>` with button role
**Required Tokens**: --bg-primary, --text-primary, --accent-primary, --border-primary
**Variants**:
- `primary`: filled background with accent color
- `secondary`: outlined with border, transparent background
- `ghost`: no background or border, text only
- `danger`: error state styling

### Typography Hierarchy
- **Button Label**: --font-size-sm, --font-weight-medium, 100% opacity
- **Button Icon**: --font-size-base, 100% opacity
- **Button Helper**: --font-size-xs, --text-secondary, 70% opacity

### Interactions
- Hover: background-color shift or border-color shift
- Active: `transform: scale(0.98)`
- Focus: 2px outline ring
- Disabled: `opacity: 0.5`, `cursor: not-allowed`
- Transition: `background-color 0.2s ease, transform 0.15s ease, box-shadow 0.2s ease`

### States
- Default: resting state
- Hover: color shift
- Active: pressed state
- Focus: visible outline
- Disabled: reduced opacity
- Loading: spinner replaces label

### Accessibility
- Must have visible focus indicator
- Minimum touch target: 44x44px (recommended), 24x24px absolute minimum (WCAG 2.5.8)
- Disabled state must be announced to screen readers

---

## ListItem Component

**Required Elements**: `<li>` or `<a>` with listitem role
**Required Tokens**: --bg-primary, --text-primary, --border-secondary
**Structure**:
- Left group: number + title
- Right group: action icon (optional)

### Typography Hierarchy
- **Number**: --font-size-sm, --font-weight-bold, --text-tertiary (50% opacity)
- **Title**: --font-size-base, --font-weight-medium, --text-primary (100% opacity)
- **Subtitle**: --font-size-sm, --font-weight-normal, --text-secondary (70% opacity)
- **Icon**: --font-size-base, --text-tertiary (50% opacity)

### Interactions
- Hover: background-color shift to --surface-primary
- Arrow animation: `transform: translateX(4px)` on row hover
- Focus: 2px outline ring
- Transition: `background-color 0.2s ease, transform 0.2s ease`

### States
- Default: resting state
- Hover: background highlight
- Focus: visible outline
- Active: pressed state
- Disabled: reduced opacity
- Selected: persistent accent color

### Accessibility
- Use `role="listitem"` or semantic `<li>`
- Arrow icon must have `aria-hidden="true"`
- Number must have `aria-hidden="true"` (decorative)

---

## Navigation Component

**Required Elements**: `<nav>`, `<a>` with appropriate roles
**Required Tokens**: --bg-primary, --text-primary, --border-primary
**Variants**:
- `horizontal`: top navigation bar
- `vertical`: sidebar navigation
- `tabs`: tabbed interface

### Typography Hierarchy
- **Nav Item**: --font-size-sm, --font-weight-medium, --text-primary (100% opacity)
- **Nav Label**: --font-size-xs, --font-weight-normal, --text-secondary (70% opacity)
- **Nav Badge**: --font-size-xs, --font-weight-bold, 100% opacity

### Interactions
- Hover: background-color shift or underline
- Active: persistent accent color or border indicator
- Focus: 2px outline ring
- Transition: `background-color 0.2s ease, border-color 0.2s ease`

### States
- Default: resting state
- Hover: background highlight
- Focus: visible outline
- Active/Current: persistent indicator
- Disabled: reduced opacity

### Accessibility
- Use `<nav>` with `aria-label` for multiple nav regions
- Active item: `aria-current="page"`
- Keyboard navigation with arrow keys for tab patterns

---

## Input Component

**Required Elements**: `<label>`, `<input>` or `<textarea>`
**Required Tokens**: --bg-primary, --text-primary, --border-primary, --border-focus
**Variants**:
- `text`: standard text input
- `textarea`: multi-line input
- `select`: dropdown selection

### Typography Hierarchy
- **Label**: --font-size-sm, --font-weight-medium, --text-primary (100% opacity)
- **Input Text**: --font-size-base, --font-weight-normal, --text-primary (100% opacity)
- **Placeholder**: --font-size-base, --font-weight-normal, --text-tertiary (50% opacity)
- **Helper**: --font-size-xs, --font-weight-normal, --text-secondary (70% opacity)
- **Error**: --font-size-xs, --font-weight-medium, --state-error, 100% opacity

### Interactions
- Focus: border-color shifts to --border-focus, 2px outline ring
- Error: border-color shifts to --state-error
- Disabled: `opacity: 0.5`, `cursor: not-allowed`
- Transition: `border-color 0.2s ease, box-shadow 0.2s ease`

### States
- Default: resting state
- Focus: highlighted border
- Error: error border + message
- Disabled: reduced opacity
- Readonly: no interaction
- Loading: spinner indicator

### Accessibility
- Every input must have a `<label>` (visible or `aria-label`)
- Error messages must be associated via `aria-describedby`
- Required fields must have `aria-required="true"`

---

## Link Component

**Required Elements**: `<a>` or element with link role
**Required Tokens**: --accent-primary, --text-primary
**Variants**:
- `inline`: within paragraph text
- `standalone`: clickable area with padding
- `nav`: navigation link with hover states

### Typography Hierarchy
- **Link Text**: --font-size-base, --font-weight-normal, --accent-primary, 100% opacity
- **Link Hover**: --font-size-base, --font-weight-normal, --accent-hover, 100% opacity
- **Link Visited**: --font-size-base, --font-weight-normal, --accent-secondary, 70% opacity

### Interactions
- Hover: background-color shift or underline
- Focus: 2px outline ring
- Transition: `background-color 0.2s ease, color 0.2s ease`

### States
- Default: accent color text
- Hover: background highlight or underline
- Focus: visible outline
- Visited: muted accent color (optional)

### Accessibility
- Must be focusable via keyboard
- Distinct from surrounding text (color, underline, or both)
- Skip link for main content navigation

---

## Modal/Dialog Component

**Required Elements**: `<dialog>` or `<div role="dialog">`, `<header>`, `<footer>`
**Required Tokens**: --bg-primary, --text-primary, --shadow-xl, --z-modal
**Variants**:
- `default`: standard modal with overlay backdrop
- `fullscreen`: full viewport overlay
- `confirmation`: minimal dialog for confirm/cancel actions

### Typography Hierarchy
- **Modal Title**: --font-size-xl, --font-weight-semibold, --text-primary (100% opacity)
- **Modal Body**: --font-size-base, --font-weight-normal, --text-primary (100% opacity)
- **Modal Caption**: --font-size-sm, --font-weight-normal, --text-secondary (70% opacity)

### Interactions
- Open: fade in overlay + scale up dialog
- Close: fade out overlay + scale down dialog
- Backdrop click: closes modal (unless persistent)
- Escape key: closes modal
- Transition: `opacity 0.2s ease, transform 0.2s ease`

### States
- Default: visible, interactive
- Closed: hidden from DOM or `aria-hidden="true"`
- Loading: spinner in body area

### Accessibility
- Use `<dialog>` element or `role="dialog"` with `aria-modal="true"`
- Title linked via `aria-labelledby`
- Focus trapped within modal when open
- Return focus to trigger element on close
- Background scroll locked when open

```css
.modal {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: var(--z-modal);
  opacity: 0;
  visibility: hidden;
  transition: opacity 0.2s ease, visibility 0.2s ease;
}

.modal--open {
  opacity: 1;
  visibility: visible;
}

.modal__content {
  background: var(--surface-primary);
  border-radius: var(--border-radius-lg);
  padding: var(--space-lg);
  max-width: 500px;
  width: 90%;
  box-shadow: var(--shadow-xl);
  transform: scale(0.95);
  transition: transform 0.2s ease;
}

.modal--open .modal__content {
  transform: scale(1);
}
```

---

## Toast/Notification Component

**Required Elements**: `<div role="status">` or `<div role="alert">`, optional icon, close button
**Required Tokens**: --bg-primary, --text-primary, --state-success, --state-warning, --state-error, --state-info, --z-toast
**Variants**:
- `success`: positive outcome feedback
- `warning`: caution or attention needed
- `error`: failure or critical message
- `info`: neutral information

### Typography Hierarchy
- **Toast Message**: --font-size-sm, --font-weight-normal, --text-primary (100% opacity)
- **Toast Title**: --font-size-sm, --font-weight-semibold, --text-primary (100% opacity)
- **Toast Action**: --font-size-sm, --font-weight-medium, --accent-primary

### Interactions
- Enter: slide in from edge + fade
- Exit: slide out + fade
- Auto-dismiss: after 5-8 seconds (configurable)
- Pause auto-dismiss on hover
- Transition: `transform 0.3s ease, opacity 0.3s ease`

### States
- Entering: slide + fade in
- Visible: persistent until dismissed
- Exiting: slide + fade out
- Dismissed: removed from DOM

### Accessibility
- Use `role="status"` for non-critical toasts
- Use `role="alert"` for error/critical toasts
- Announce content to screen readers via `aria-live`
- Provide close button with `aria-label="Dismiss"`
- Do not auto-dismiss error toasts

```css
.toast-container {
  position: fixed;
  bottom: var(--space-lg);
  inset-inline-end: var(--space-lg);
  display: flex;
  flex-direction: column;
  gap: var(--space-sm);
  z-index: var(--z-toast);
  pointer-events: none;
}

.toast {
  display: flex;
  align-items: flex-start;
  gap: var(--space-sm);
  padding: var(--space-md);
  background: var(--surface-primary);
  border: 1px solid var(--border-primary);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-lg);
  min-width: 300px;
  max-width: 450px;
  pointer-events: auto;
  transform: translateX(100%);
  opacity: 0;
  transition: transform 0.3s ease, opacity 0.3s ease;
}

.toast--visible {
  transform: translateX(0);
  opacity: 1;
}

.toast--success { border-inline-start: 3px solid var(--state-success); }
.toast--warning { border-inline-start: 3px solid var(--state-warning); }
.toast--error { border-inline-start: 3px solid var(--state-error); }
.toast--info { border-inline-start: 3px solid var(--state-info); }

[dir="rtl"] .toast {
  transform: translateX(-100%);
}

[dir="rtl"] .toast--visible {
  transform: translateX(0);
}
```
