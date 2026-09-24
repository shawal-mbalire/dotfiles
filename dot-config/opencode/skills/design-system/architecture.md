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

## Angular Component Architecture

### Standalone Components (Default)

All components should be standalone (Angular 15+). No NgModules required.

```typescript
import { Component, ChangeDetectionStrategy, input, output, signal, computed } from '@angular/core';

@Component({
  selector: 'app-card',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './card.component.html',
  styleUrl: './card.component.scss'
})
export class CardComponent {
  // Signal-based inputs (Angular 17+)
  title = input.required<string>();
  variant = input<'elevated' | 'bordered' | 'flat'>('elevated');
  disabled = input(false);

  // Signal-based outputs (Angular 17+)
  cardClick = output<void>();

  // Local state via signals
  isHovered = signal(false);

  // Derived state via computed
  cssClasses = computed(() => ({
    'card--elevated': this.variant() === 'elevated',
    'card--bordered': this.variant() === 'bordered',
    'card--flat': this.variant() === 'flat',
    'card--disabled': this.disabled(),
    'card--hovered': this.isHovered()
  }));
}
```

### OnPush Change Detection

Always use `ChangeDetectionStrategy.OnPush`. Mutate state via signals, not direct property assignment.

```typescript
@Component({
  selector: 'app-counter',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <span>{{ count() }}</span>
    <button (click)="increment()">+1</button>
  `
})
export class CounterComponent {
  count = signal(0);

  increment() {
    // Correct: signal mutation triggers change detection
    this.count.update(n => n + 1);

    // Wrong: direct mutation won't trigger update with OnPush
    // this.count++;
  }
}
```

### Signals vs Observables

| Use Case | Approach |
|----------|----------|
| Local component state | `signal()` |
| Derived/computed values | `computed()` |
| Async data (HTTP) | `toSignal(http.get(...))` |
| Complex async flows | `Observable` + `async` pipe |
| Cross-component state | `signal()` in shared service |
| Event streams | `Observable` / `Subject` |

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
  border-radius: var(--border-radius-lg);

  &__header {
    padding: var(--space-md);
    border-bottom: var(--border-width) solid var(--border-primary);
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

### Angular Project Structure

```
src/
├── app/
│   ├── core/                    # Singleton services, guards, interceptors
│   │   ├── services/
│   │   │   ├── theme.service.ts
│   │   │   └── animation.service.ts
│   │   ├── guards/
│   │   └── interceptors/
│   ├── shared/                  # Reusable components, directives, pipes
│   │   ├── components/
│   │   │   ├── button/
│   │   │   │   ├── button.component.ts
│   │   │   │   ├── button.component.html
│   │   │   │   ├── button.component.scss
│   │   │   │   └── button.component.spec.ts
│   │   │   ├── card/
│   │   │   └── input/
│   │   ├── directives/
│   │   └── pipes/
│   ├── features/                # Feature modules (lazy-loaded)
│   │   ├── dashboard/
│   │   │   ├── dashboard.component.ts
│   │   │   ├── dashboard.component.html
│   │   │   ├── dashboard.component.scss
│   │   │   └── dashboard.routes.ts
│   │   └── settings/
│   ├── layouts/                 # Layout components
│   │   ├── app-layout/
│   │   └── auth-layout/
│   ├── app.component.ts
│   ├── app.component.html
│   ├── app.component.scss
│   ├── app.config.ts
│   └── app.routes.ts
├── styles/
│   ├── _tokens.scss             # Design tokens (CSS variables)
│   ├── _reset.scss              # CSS reset/normalize
│   ├── _typography.scss         # Typography base styles
│   ├── _utilities.scss          # Utility classes
│   ├── _animations.scss         # Keyframes and animation utilities
│   └── styles.scss              # Main stylesheet (imports all partials)
├── assets/
└── environments/
```

### Component File Structure

Each component lives in its own directory with co-located files:

```
components/button/
├── button.component.ts          # Component class + decorator
├── button.component.html        # Template
├── button.component.scss        # Styles
└── button.component.spec.ts     # Unit tests
```

### Component TypeScript Pattern

```typescript
import {
  Component,
  ChangeDetectionStrategy,
  input,
  output,
  inject,
  signal,
  computed,
  HostBinding,
  HostListener
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { ThemeService } from '../../core/services/theme.service';

@Component({
  selector: 'app-button',
  standalone: true,
  imports: [CommonModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './button.component.html',
  styleUrl: './button.component.scss'
})
export class ButtonComponent {
  private themeService = inject(ThemeService);

  // Inputs
  variant = input<'primary' | 'secondary' | 'ghost' | 'danger'>('primary');
  size = input<'sm' | 'md' | 'lg'>('md');
  disabled = input(false);
  loading = input(false);

  // Outputs
  buttonClick = output<MouseEvent>();

  // Host binding for dynamic classes
  @HostBinding('class') get hostClasses() {
    return `btn btn--${this.variant()} btn--${this.size()} ${
      this.disabled() ? 'btn--disabled' : ''
    } ${this.loading() ? 'btn--loading' : ''}`;
  }

  @HostListener('click', ['$event'])
  onClick(event: MouseEvent) {
    if (!this.disabled() && !this.loading()) {
      this.buttonClick.emit(event);
    }
  }
}
```

### Component HTML Pattern

```html
<!-- Use Angular template syntax, semantic HTML, design tokens via classes -->
<button
  [attr.aria-disabled]="disabled() || loading()"
  [attr.aria-busy]="loading()">
  @if (loading()) {
    <span class="spinner spinner--sm" aria-hidden="true"></span>
  }
  <ng-content></ng-content>
</button>
```

### Component SCSS Pattern

```scss
// Use :host for component scoping
// Access CSS variables via var()
:host {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-sm);
  padding: var(--space-sm) var(--space-md);
  border: var(--border-width) solid var(--border-primary);
  border-radius: var(--border-radius);
  font-size: var(--font-size-sm);
  font-weight: var(--font-weight-medium);
  cursor: pointer;
  transition: background-color var(--duration-normal) var(--easing-default),
              transform var(--duration-fast) var(--easing-default);
  contain: layout style;
}

// BEM-like naming within component scope
:host(.btn--primary) {
  background: var(--accent-primary);
  color: var(--text-on-accent);
  border-color: var(--accent-primary);

  &:hover {
    background: var(--accent-hover);
  }
}

:host(.btn--disabled),
:host(.btn--loading) {
  opacity: 0.5;
  cursor: not-allowed;
  pointer-events: none;
}

:host(.btn--loading) {
  position: relative;
  color: transparent;
}
```

### CSS Modules Pattern (Alternative)
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
  border: var(--border-width) solid var(--border-primary);
  border-radius: var(--border-radius);
  background: var(--surface-primary);
  color: var(--text-primary);
  font-size: var(--font-size-base);
  cursor: pointer;
  transition: background-color var(--duration-normal) var(--easing-default),
              border-color var(--duration-normal) var(--easing-default);
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
  color: var(--text-on-accent);
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

**This skill uses Desktop-First by default** (see tokens.md and responsive.md). Use `max-width` media queries to adapt downward from desktop layouts.

## Pluggable Design Patterns

Components should be configurable through injection tokens, not inheritance. Swap visual strategies by providing different adapters.

### Strategy Pattern via DI

```typescript
// domain/ports/CardVariantStrategy.ts
export interface CardVariantStrategy {
  getClasses(): Record<string, boolean>;
  getStyles(): Record<string, string>;
}

// adapters/patterns/Pattern1CardStrategy.ts
import { Injectable } from '@angular/core';
import { CardVariantStrategy } from '../../domain/ports/CardVariantStrategy';

@Injectable()
export class Pattern1CardStrategy implements CardVariantStrategy {
  getClasses() {
    return {
      'card--bordered': true,
      'card--radius-sm': true
    };
  }

  getStyles() {
    return {
      '--card-radius': 'var(--border-radius)',
      '--card-border': '1px solid var(--border-primary)'
    };
  }
}

// adapters/patterns/Pattern3CardStrategy.ts
import { Injectable } from '@angular/core';
import { CardVariantStrategy } from '../../domain/ports/CardVariantStrategy';

@Injectable()
export class Pattern3CardStrategy implements CardVariantStrategy {
  getClasses() {
    return {
      'card--elevated': true,
      'card--radius-lg': true
    };
  }

  getStyles() {
    return {
      '--card-radius': 'var(--border-radius-xl)',
      '--card-shadow': 'var(--shadow-md)'
    };
  }
}

// adapters/patterns/Pattern4CardStrategy.ts
import { Injectable } from '@angular/core';
import { CardVariantStrategy } from '../../domain/ports/CardVariantStrategy';

@Injectable()
export class Pattern4CardStrategy implements CardVariantStrategy {
  getClasses() {
    return {
      'card--morph': true,
      'card--dual-radius': true
    };
  }

  getStyles() {
    return {
      '--card-radius-outer': 'var(--radius-outer-lg)',
      '--card-radius-inner': 'var(--radius-inner-lg)',
      '--card-shadow': 'var(--shadow-sm)',
      '--card-morph-duration': 'var(--duration-morph)',
      '--card-morph-easing': 'var(--easing-morph)'
    };
  }
}
```

### Component Using Strategy

```typescript
import { Component, ChangeDetectionStrategy, inject, computed } from '@angular/core';
import { CardVariantStrategy } from '../../domain/ports/CardVariantStrategy';

@Component({
  selector: 'app-card',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <article
      [class]="cssClasses()"
      [ngStyle]="styles()">
      <ng-content></ng-content>
    </article>
  `
})
export class CardComponent {
  private strategy = inject(CardVariantStrategy);

  cssClasses = computed(() => ({
    'card': true,
    ...this.strategy.getClasses()
  }));

  styles = computed(() => this.strategy.getStyles());
}
```

### Composition Root Wiring

```typescript
// app.config.ts
import { CardVariantStrategy } from './domain/ports/CardVariantStrategy';
import { Pattern1CardStrategy } from './adapters/patterns/Pattern1CardStrategy';

export const appConfig: ApplicationConfig = {
  providers: [
    { provide: CardVariantStrategy, useClass: Pattern1CardStrategy },
    // Swap to Pattern3CardStrategy for different visual pattern
  ]
};
```

### Injection Token Pattern

```typescript
// domain/tokens/design-tokens.ts
import { InjectionToken } from '@angular/core';

export interface DesignConfig {
  patternId: 1 | 2 | 3 | 4;
  enableAnimations: boolean;
  iconSet: 'lucide';
}

export const DESIGN_CONFIG = new InjectionToken<DesignConfig>('DESIGN_CONFIG', {
  providedIn: 'root',
  factory: () => ({
    patternId: 1,
    enableAnimations: true,
    iconSet: 'lucide'
  })
});

// Usage in component
@Component({...})
export class AppComponent {
  config = inject(DESIGN_CONFIG);

  constructor() {
    console.log(`Using pattern ${this.config.patternId}`);
  }
}
```

### Desktop-First (Default)
```css
/* Base styles (desktop) */
.container {
  padding: var(--space-lg);
  max-inline-size: var(--bp-xl);
  margin-inline: auto;
}

/* Desktop and below */
@media (max-width: 1200px) {
  .container {
    padding: var(--space-md);
  }
}

/* Tablet and below */
@media (max-width: 992px) {
  .container {
    padding: var(--space-sm);
  }
}

/* Mobile and below */
@media (max-width: 768px) {
  .container {
    padding: var(--space-sm);
  }
}
```

### Mobile-First (Alternative)
Use only when explicitly required by project constraints. Uses `min-width` to build upward.
```css
/* Base styles (mobile) */
.container {
  padding: var(--space-sm);
}

/* Tablet and up */
@media (min-width: 993px) {
  .container {
    padding: var(--space-md);
  }
}

/* Desktop and up */
@media (min-width: 1201px) {
  .container {
    padding: var(--space-lg);
    max-inline-size: var(--bp-xl);
    margin-inline: auto;
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
  flex: 2 1 var(--bp-md);
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
  grid-template-columns: var(--size-sidebar) 1fr;
  gap: var(--space-lg);
  min-height: 100vh;
}

@media (max-width: 768px) {
  .layout-sidebar {
    grid-template-columns: 1fr;
  }
  
  .sidebar {
    position: fixed;
    inset-inline-start: calc(var(--size-sidebar) * -1);
    width: var(--size-sidebar);
    height: 100vh;
    background: var(--surface-primary);
    transition: inset-inline-start var(--duration-slow) var(--easing-default);
    z-index: var(--z-overlay);
  }
  
  .sidebar.open {
    inset-inline-start: 0;
  }
  
  .sidebar-overlay {
    position: fixed;
    inset: 0;
    background: var(--bg-overlay);
    opacity: 0;
    visibility: hidden;
    transition: opacity var(--duration-slow) var(--easing-default),
                visibility var(--duration-slow) var(--easing-default);
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

.margin-inline-auto { margin-inline: auto; }
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
.text-align-start { text-align: start; }
.text-align-center { text-align: center; }
.text-align-end { text-align: end; }

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
