# Component Contracts

Components are documented as contracts specifying required elements, tokens, variants, and interactions. **Angular** is the preferred implementation framework.

## Angular Component Pattern

Every component follows this structure:

```typescript
import { Component, ChangeDetectionStrategy, input, output, signal, computed, inject } from '@angular/core';

@Component({
  selector: 'app-[component-name]',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './[component-name].component.html',
  styleUrl: './[component-name].component.scss'
})
export class [ComponentName]Component {
  // Signal-based inputs
  // Signal-based outputs
  // Local state via signals
  // Derived state via computed
}
```

## Icon System — Lucide

All icons in the design system use [Lucide](https://lucide.dev/). No emoji, no Font Awesome, no custom SVG icons.

### Installation

```bash
npm install lucide-angular
```

### Icon Component

```typescript
import { Component, ChangeDetectionStrategy, input, computed } from '@angular/core';
import { LucideAngularModule } from 'lucide-angular';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'ds-icon',
  standalone: true,
  imports: [CommonModule, LucideAngularModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <lucide-icon
      [name]="iconName()"
      [size]="sizePx()"
      [strokeWidth]="strokeWidth()"
      [class]="iconClasses()">
    </lucide-icon>
  `,
  styles: [`:host { display: inline-flex; align-items: center; justify-content: center; }`]
})
export class IconComponent {
  iconName = input.required<string>();
  size = input<'xs' | 'sm' | 'md' | 'lg' | 'xl'>('md');
  strokeWidth = input<number>(2);

  sizePx = computed(() => {
    const sizes = { xs: 14, sm: 16, md: 24, lg: 32, xl: 48 };
    return sizes[this.size()];
  });

  iconClasses = computed(() => ({
    'icon': true,
    [`icon--${this.size()}`]: true
  }));
}
```

### Icon Usage Rules

| Rule | Example |
|------|---------|
| Decorative icons must have `aria-hidden` | `<ds-icon name="home" [attr.aria-hidden]="true" />` |
| Interactive icons must have `aria-label` on parent | `<button aria-label="Close"><ds-icon name="x" /></button>` |
| Icon + text uses `gap` for spacing | `<ds-icon name="check" /><span>Done</span>` with `display: flex; gap: var(--space-sm)` |
| Never use emoji as icons | No `✓` or `🎉`, always `<ds-icon name="check" />` or `<ds-icon name="party-popper" />` |

### Common Icon Names

| Category | Lucide Names |
|----------|--------------|
| Navigation | `home`, `menu`, `chevron-left`, `chevron-right`, `arrow-left`, `arrow-right` |
| Actions | `check`, `x`, `plus`, `minus`, `edit`, `trash-2`, `copy`, `download` |
| Status | `check-circle`, `alert-circle`, `alert-triangle`, `info`, `loader` |
| Media | `play`, `pause`, `volume-2`, `volume-x` |
| Layout | `search`, `filter`, `grid`, `list`, `sliders-horizontal` |
| Communication | `mail`, `message-circle`, `bell`, `send` |

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

### Angular Implementation

```typescript
import { Component, ChangeDetectionStrategy, input, output, signal, computed } from '@angular/core';

@Component({
  selector: 'app-card',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <article
      [class]="cssClasses()"
      [attr.aria-label]="ariaLabel()"
      (mouseenter)="isHovered.set(true)"
      (mouseleave)="isHovered.set(false)"
      (focus)="isHovered.set(true)"
      (blur)="isHovered.set(false)"
      [tabindex]="clickable() ? 0 : null"
      (click)="clickable() && cardClick.emit()"
      (keydown.enter)="clickable() && cardClick.emit()">
      @if (title()) {
        <header class="card__header">
          <h3 class="card__title">{{ title() }}</h3>
          @if (subtitle()) {
            <p class="card__subtitle">{{ subtitle() }}</p>
          }
        </header>
      }
      <section class="card__body">
        <ng-content></ng-content>
      </section>
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

### Angular Implementation

```typescript
import { Component, ChangeDetectionStrategy, input, output, HostBinding, HostListener } from '@angular/core';

@Component({
  selector: 'app-button',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (loading()) {
      <span class="spinner spinner--sm" aria-hidden="true"></span>
    }
    <ng-content></ng-content>
  `
})
export class ButtonComponent {
  variant = input<'primary' | 'secondary' | 'ghost' | 'danger'>('primary');
  size = input<'sm' | 'md' | 'lg'>('md');
  disabled = input(false);
  loading = input(false);
  buttonClick = output<MouseEvent>();

  @HostBinding('class') get hostClasses() {
    return `btn btn--${this.variant()} btn--${this.size()}`;
  }

  @HostBinding('attr.aria-disabled') get ariaDisabled() {
    return this.disabled() || this.loading();
  }

  @HostBinding('attr.aria-busy') get ariaBusy() {
    return this.loading();
  }

  @HostListener('click', ['$event'])
  onClick(event: MouseEvent) {
    if (!this.disabled() && !this.loading()) {
      this.buttonClick.emit(event);
    }
  }
}
```

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

### Angular Implementation

```typescript
import { Component, ChangeDetectionStrategy, input, signal, computed, inject, Self } from '@angular/core';
import { ReactiveFormsModule, FormControl } from '@angular/forms';
import { NgControl } from '@angular/forms';

@Component({
  selector: 'app-input',
  standalone: true,
  imports: [ReactiveFormsModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <label [for]="id()" class="input-label">{{ label() }}</label>
    <input
      [id]="id()"
      [type]="type()"
      [formControl]="control"
      [placeholder]="placeholder()"
      [attr.aria-required]="required()"
      [attr.aria-describedby]="errorMessage() ? id() + '-error' : null"
      [attr.aria-invalid]="hasError()"
      [class.input--error]="hasError()"
      [class.input--disabled]="disabled()">
    @if (helperText() && !hasError()) {
      <div class="input-helper">{{ helperText() }}</div>
    }
    @if (hasError()) {
      <div class="input-error-message" [id]="id() + '-error'" role="alert">
        {{ errorMessage() }}
      </div>
    }
  `
})
export class InputComponent {
  id = input.required<string>();
  label = input.required<string>();
  type = input('text');
  placeholder = input('');
  required = input(false);
  disabled = input(false);
  helperText = input<string>();

  control = new FormControl('');

  hasError = computed(() => this.control.invalid && (this.control.dirty || this.control.touched));

  errorMessage = computed(() => {
    if (!this.control.errors) return '';
    const errors = this.control.errors;
    if (errors['required']) return `${this.label()} is required.`;
    if (errors['email']) return `${this.label()} must be a valid email.`;
    if (errors['minlength']) return `${this.label()} must be at least ${errors['minlength'].requiredLength} characters.`;
    return `${this.label()} is invalid.`;
  });
}
```

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

### Angular Implementation

```typescript
import { Component, ChangeDetectionStrategy, input, output, signal, effect, ElementRef, inject, viewChild, AfterViewInit } from '@angular/core';

@Component({
  selector: 'app-modal',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (isOpen()) {
      <div class="modal" role="dialog" aria-modal="true" [attr.aria-labelledby]="titleId">
        <div class="modal__backdrop" (click)="close()"></div>
        <div class="modal__content" #content>
          <header class="modal__header">
            <h2 [id]="titleId">{{ title() }}</h2>
            <button class="modal__close" (click)="close()" aria-label="Close dialog">×</button>
          </header>
          <section class="modal__body">
            <ng-content></ng-content>
          </section>
          @if (showFooter()) {
            <footer class="modal__footer">
              <ng-content select="[footer]"></ng-content>
            </footer>
          }
        </div>
      </div>
    }
  `
})
export class ModalComponent implements AfterViewInit {
  private elementRef = inject(ElementRef);

  title = input.required<string>();
  isOpen = input(false);
  showFooter = input(true);
  closed = output<void>();

  private titleId = `modal-title-${Math.random().toString(36).slice(2, 9)}`;
  private previousActiveElement: HTMLElement | null = null;

  content = viewChild<ElementRef>('content');

  constructor() {
    effect(() => {
      if (this.isOpen()) {
        this.previousActiveElement = document.activeElement as HTMLElement;
        document.body.style.overflow = 'hidden';
        // Focus trap logic
        setTimeout(() => this.content()?.nativeElement?.focus(), 0);
      } else {
        document.body.style.overflow = '';
        this.previousActiveElement?.focus();
      }
    });
  }

  ngAfterViewInit() {
    this.elementRef.nativeElement.addEventListener('keydown', (e: KeyboardEvent) => {
      if (e.key === 'Escape' && this.isOpen()) {
        this.close();
      }
    });
  }

  close() {
    this.closed.emit();
  }
}
```

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

### Angular Implementation

```typescript
import { Component, ChangeDetectionStrategy, input, output, signal, inject } from '@angular/core';
import { CommonModule } from '@angular/common';

export interface Toast {
  id: string;
  type: 'success' | 'warning' | 'error' | 'info';
  title?: string;
  message: string;
  autoDismiss?: boolean;
  duration?: number;
}

@Component({
  selector: 'app-toast-container',
  standalone: true,
  imports: [CommonModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="toast-container" aria-live="polite">
      @for (toast of toasts(); track toast.id) {
        <div
          class="toast"
          [class]="'toast toast--' + toast.type"
          [attr.role]="toast.type === 'error' ? 'alert' : 'status'"
          [attr.aria-labelledby]="toast.title ? 'toast-title-' + toast.id : null"
          [attr.aria-describedby]="'toast-msg-' + toast.id">
          @if (toast.title) {
            <strong [id]="'toast-title-' + toast.id">{{ toast.title }}</strong>
          }
          <span [id]="'toast-msg-' + toast.id">{{ toast.message }}</span>
          <button
            class="toast__close"
            (click)="dismiss(toast.id)"
            aria-label="Dismiss notification">×</button>
        </div>
      }
    </div>
  `
})
export class ToastContainerComponent {
  toasts = signal<Toast[]>([]);
  private timers = new Map<string, ReturnType<typeof setTimeout>>();

  show(toast: Omit<Toast, 'id'>) {
    const id = crypto.randomUUID();
    const newToast = { ...toast, id };
    this.toasts.update(t => [...t, newToast]);

    if (toast.autoDismiss !== false && toast.type !== 'error') {
      const duration = toast.duration || 5000;
      const timer = setTimeout(() => this.dismiss(id), duration);
      this.timers.set(id, timer);
    }
  }

  dismiss(id: string) {
    this.toasts.update(t => t.filter(toast => toast.id !== id));
    const timer = this.timers.get(id);
    if (timer) {
      clearTimeout(timer);
      this.timers.delete(id);
    }
  }
}
```

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
