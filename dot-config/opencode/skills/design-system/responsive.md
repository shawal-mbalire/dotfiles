# Responsive Design

## Desktop-First Strategy

Start with desktop layout and adapt downward:

```css
/* Base: Desktop (1200px+) */
.container { max-width: 1200px; }
.grid { display: grid; grid-template-columns: repeat(3, 1fr); }

/* Tablet (992px and below) */
@media (max-width: 992px) {
  .grid { grid-template-columns: repeat(2, 1fr); }
}

/* Mobile (768px and below) */
@media (max-width: 768px) {
  .grid { grid-template-columns: 1fr; }
}
```

## Angular CDK BreakpointObserver

In Angular, use `@angular/cdk/layout` for responsive logic instead of `window.matchMedia`:

```typescript
import { Component, inject, signal, OnInit, OnDestroy, ChangeDetectionStrategy } from '@angular/core';
import { BreakpointObserver, Breakpoints } from '@angular/cdk/layout';
import { toSignal } from '@angular/core/rxjs-interop';
import { map } from 'rxjs/operators';

@Component({
  selector: 'app-responsive-layout',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (isMobile()) {
      <app-mobile-nav />
    } @else {
      <app-desktop-sidebar />
    }
  `
})
export class ResponsiveLayoutComponent {
  private breakpointObserver = inject(BreakpointObserver);

  // Convert observable to signal
  isMobile = toSignal(
    this.breakpointObserver.observe(Breakpoints.Handset).pipe(
      map(result => result.matches)
    ),
    { initialValue: false }
  );

  // Or use a custom breakpoint matching service
  screenSize = toSignal(
    this.breakpointObserver.observe([
      '(max-width: 768px)',
      '(min-width: 769px) and (max-width: 1024px)',
      '(min-width: 1025px)'
    ]).pipe(
      map(result => {
        if (result.breakpoints['(max-width: 768px)']) return 'mobile';
        if (result.breakpoints['(min-width: 769px) and (max-width: 1024px)']) return 'tablet';
        return 'desktop';
      })
    ),
    { initialValue: 'desktop' }
  );
}
```

### Breakpoint Service (Reusable)

```typescript
import { Injectable, inject } from '@angular/core';
import { BreakpointObserver, Breakpoints } from '@angular/cdk/layout';
import { toSignal } from '@angular/core/rxjs-interop';
import { map } from 'rxjs/operators';

@Injectable({ providedIn: 'root' })
export class ResponsiveService {
  private bp = inject(BreakpointObserver);

  readonly isMobile = toSignal(
    this.bp.observe(Breakpoints.Handset).pipe(map(r => r.matches)),
    { initialValue: false }
  );

  readonly isTablet = toSignal(
    this.bp.observe(Breakpoints.Tablet).pipe(map(r => r.matches)),
    { initialValue: false }
  );

  readonly isDesktop = toSignal(
    this.bp.observe(Breakpoints.Web).pipe(map(r => r.matches)),
    { initialValue: true }
  );

  readonly isHandsetOrTablet = toSignal(
    this.bp.observe([...Breakpoints.Handset, ...Breakpoints.Tablet]).pipe(map(r => r.matches)),
    { initialValue: false }
  );
}
```

### Usage in Component

```typescript
@Component({
  selector: 'app-navigation',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (responsive.isMobile()) {
      <app-bottom-nav />
    } @else {
      <app-sidebar-nav />
    }
  `
})
export class NavigationComponent {
  responsive = inject(ResponsiveService);
}
```

## Container Queries for Components

Use container queries for component-level responsiveness:

```css
.card-container {
  container-type: inline-size;
}

@container (min-width: 400px) {
  .card {
    display: grid;
    grid-template-columns: 200px 1fr;
  }
}
```

## Fluid Typography

Use `clamp()` for responsive typography:

```css
:root {
  --font-size-base: clamp(1rem, 0.9rem + 0.25vw, 1.125rem);
  --font-size-lg: clamp(1.125rem, 1rem + 0.3vw, 1.375rem);
  --font-size-xl: clamp(1.25rem, 1rem + 0.5vw, 1.75rem);
}
```

## Breakpoint Usage

Follow the breakpoint tokens defined in the Design Tokens Reference:

```css
/* Mobile portrait and below */
@media (max-width: 768px) { }

/* Mobile landscape and below */
@media (max-width: 992px) { }

/* Tablet and below */
@media (max-width: 1200px) { }

/* Large desktop and above */
@media (min-width: 1400px) { }
```

## Responsive Patterns

### Stack Layout
```css
.grid {
  display: grid;
  gap: var(--space-md);
}

/* Mobile: single column */
@media (max-width: 768px) {
  .grid {
    grid-template-columns: 1fr;
  }
}

/* Tablet: two columns */
@media (min-width: 769px) and (max-width: 1024px) {
  .grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

/* Desktop: three columns */
@media (min-width: 1025px) {
  .grid {
    grid-template-columns: repeat(3, 1fr);
  }
}
```

### Sidebar Layout
```css
.layout {
  display: grid;
  grid-template-columns: 250px 1fr;
  gap: var(--space-lg);
}

/* Tablet: collapsible sidebar */
@media (max-width: 1024px) {
  .layout {
    grid-template-columns: 1fr;
  }
  
  .sidebar {
    position: fixed;
    left: -250px;
    transition: left 0.3s ease;
  }
  
  .sidebar.open {
    left: 0;
  }
}
```

### Card Grid
```css
.card-grid {
  display: grid;
  gap: var(--space-lg);
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
}

/* Mobile: stack cards */
@media (max-width: 600px) {
  .card-grid {
    grid-template-columns: 1fr;
  }
}
```

## Responsive Utilities

### Hide/Show Based on Screen Size
```css
/* Hide on mobile, show on tablet+ */
@media (max-width: 768px) {
  .hide-mobile { display: none !important; }
}

/* Hide on tablet, show on mobile and desktop */
@media (min-width: 769px) and (max-width: 1024px) {
  .hide-tablet { display: none !important; }
}

/* Hide on desktop, show on tablet and mobile */
@media (min-width: 1025px) {
  .hide-desktop { display: none !important; }
}
```

### Responsive Spacing
```css
.section {
  padding: var(--space-xl);
}

@media (max-width: 768px) {
  .section {
    padding: var(--space-md);
  }
}
```

### Responsive Typography
```css
h1 {
  font-size: var(--font-size-2xl);
}

@media (max-width: 768px) {
  h1 {
    font-size: var(--font-size-xl);
  }
}
```

## Touch Considerations

- Minimum touch target: 44x44px (recommended)
- Minimum spacing between touch targets: 8px
- Consider thumb zones on mobile (bottom of screen easier to reach)
- Avoid hover-dependent interactions on touch devices

## Performance

- Use responsive images with `srcset` and `sizes`
- Lazy load images below the fold
- Consider progressive loading for complex layouts
- Use `will-change` sparingly for animations
- Optimize for Core Web Vitals (LCP, FID, CLS)
