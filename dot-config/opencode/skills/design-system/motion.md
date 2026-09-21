# Motion Design

## Angular Animation Module

For complex enter/leave transitions, use `@angular/animations`. For simple hover/focus state changes, use CSS transitions.

```typescript
// app.config.ts
import { provideAnimationsAsync } from '@angular/platform-browser/animations/async';

export const appConfig: ApplicationConfig = {
  providers: [
    provideAnimationsAsync(),
    // ... other providers
  ]
};
```

### When to Use Which

| Use Case | Approach |
|----------|----------|
| Hover/focus/active states | CSS transitions |
| Element enter/leave (`*ngIf`, `@if`) | `@angular/animations` |
| List animations (`*ngFor`, `@for`) | `animateChild()` + `query()` |
| Route transitions | `@routeAnimation` trigger |
| Complex choreographed sequences | `@angular/animations` stagger |
| Simple show/hide | CSS transitions with `[class.hidden]` |

## Transition Principles

1. **Purposeful**: Every animation should have a purpose (feedback, orientation, focus)
2. **Quick**: Most transitions should be 100-300ms
3. **Smooth**: Use appropriate easing functions
4. **Respectful**: Honor `prefers-reduced-motion`

## Transition Properties

| Property | Duration | Easing | Use Case |
|----------|----------|--------|----------|
| `background-color` | 200ms | ease | Color changes |
| `color` | 200ms | ease | Text color changes |
| `border-color` | 200ms | ease | Border color changes |
| `box-shadow` | 300ms | ease | Elevation changes |
| `transform` | 200ms | ease-out | Movement, scale |
| `opacity` | 200ms | ease | Show/hide |
| `width/height` | 300ms | ease | Size changes |

## Combined Transitions

```css
.btn {
  transition: background-color 0.2s ease, transform 0.15s ease;
}

.card {
  transition: box-shadow 0.3s ease, transform 0.2s ease;
}

.nav-item {
  transition: background-color 0.2s ease, color 0.2s ease;
}
```

## Animation Guidelines

- Avoid animations that flash or blink
- Keep animations under 5 seconds
- Provide pause/stop controls for auto-playing animations
- Use `will-change` sparingly for performance

## Timing Functions

### Ease Variations
```css
/* Default ease */
transition: all 0.2s ease;

/* Ease in (for exiting elements) */
transition: all 0.2s ease-in;

/* Ease out (for entering elements) */
transition: all 0.2s ease-out;

/* Ease in out (for moving elements) */
transition: all 0.2s ease-in-out;

/* Custom cubic-bezier */
transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
```

### Bounce Effects
```css
/* Subtle bounce */
transition: transform 0.3s cubic-bezier(0.68, -0.55, 0.265, 1.55);

/* Strong bounce */
transition: transform 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275);
```

## Animation Patterns

### Fade In
```css
@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.fade-in {
  animation: fadeIn 0.3s ease-out;
}
```

### Fade Out
```css
@keyframes fadeOut {
  from { opacity: 1; }
  to { opacity: 0; }
}

.fade-out {
  animation: fadeOut 0.3s ease-in;
}
```

### Slide In
```css
@keyframes slideInLeft {
  from { transform: translateX(-100%); }
  to { transform: translateX(0); }
}

.slide-in-left {
  animation: slideInLeft 0.3s ease-out;
}

@keyframes slideInRight {
  from { transform: translateX(100%); }
  to { transform: translateX(0); }
}

.slide-in-right {
  animation: slideInRight 0.3s ease-out;
}

@keyframes slideInUp {
  from { transform: translateY(100%); }
  to { transform: translateY(0); }
}

.slide-in-up {
  animation: slideInUp 0.3s ease-out;
}

@keyframes slideInDown {
  from { transform: translateY(-100%); }
  to { transform: translateY(0); }
}

.slide-in-down {
  animation: slideInDown 0.3s ease-out;
}
```

### Scale
```css
@keyframes scaleIn {
  from { transform: scale(0.9); opacity: 0; }
  to { transform: scale(1); opacity: 1; }
}

.scale-in {
  animation: scaleIn 0.3s ease-out;
}
```

### Spin
```css
@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.spin {
  animation: spin 1s linear infinite;
}
```

### Pulse
```css
@keyframes pulse {
  0% { transform: scale(1); }
  50% { transform: scale(1.05); }
  100% { transform: scale(1); }
}

.pulse {
  animation: pulse 2s ease-in-out infinite;
}
```

### Shake
```css
@keyframes shake {
  0%, 100% { transform: translateX(0); }
  10%, 30%, 50%, 70%, 90% { transform: translateX(-5px); }
  20%, 40%, 60%, 80% { transform: translateX(5px); }
}

.shake {
  animation: shake 0.5s ease-in-out;
}
```

## Loading Animations

### Spinner
```css
.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid var(--border-primary);
  border-top: 4px solid var(--accent-primary);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}
```

### Dots
```css
@keyframes dotPulse {
  0%, 80%, 100% { transform: scale(0); }
  40% { transform: scale(1); }
}

.dot-pulse {
  display: flex;
  gap: 4px;
}

.dot-pulse span {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--accent-primary);
  animation: dotPulse 1.4s ease-in-out infinite;
}

.dot-pulse span:nth-child(1) { animation-delay: -0.32s; }
.dot-pulse span:nth-child(2) { animation-delay: -0.16s; }
.dot-pulse span:nth-child(3) { animation-delay: 0s; }
```

### Skeleton
```css
@keyframes shimmer {
  0% { background-position: -200% 0; }
  100% { background-position: 200% 0; }
}

.skeleton {
  background: linear-gradient(
    90deg,
    var(--surface-primary) 25%,
    var(--surface-secondary) 50%,
    var(--surface-primary) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
  border-radius: 4px;
}
```

## Page Transitions

### Fade
```css
.page-enter {
  opacity: 0;
  transition: opacity 0.3s ease;
}

.page-enter-active {
  opacity: 1;
}

.page-exit {
  opacity: 1;
  transition: opacity 0.3s ease;
}

.page-exit-active {
  opacity: 0;
}
```

### Slide
```css
.slide-enter {
  transform: translateX(100%);
  transition: transform 0.3s ease;
}

.slide-enter-active {
  transform: translateX(0);
}

.slide-exit {
  transform: translateX(0);
  transition: transform 0.3s ease;
}

.slide-exit-active {
  transform: translateX(-100%);
}
```

## Reduced Motion Support

See [Accessibility Requirements](./accessibility.md#reduced-motion) for the full implementation. Always include this media query in production CSS.

## Angular Animation Service

```typescript
import { Injectable, inject } from '@angular/core';
import { AnimationBuilder, style, animate, AnimationPlayer } from '@angular/animations';
import { DOCUMENT } from '@angular/common';

@Injectable({ providedIn: 'root' })
export class AnimationService {
  private builder = inject(AnimationBuilder);
  private doc = inject(DOCUMENT);

  get prefersReducedMotion(): boolean {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  }

  fadeIn(element: HTMLElement, duration = 300): AnimationPlayer {
    if (this.prefersReducedMotion) {
      element.style.opacity = '1';
      return this.createNoopPlayer();
    }

    const factory = this.builder.build([
      style({ opacity: 0 }),
      animate(`${duration}ms ease-out`, style({ opacity: 1 }))
    ]);
    const player = factory.create(element);
    player.play();
    return player;
  }

  fadeOut(element: HTMLElement, duration = 300): AnimationPlayer {
    if (this.prefersReducedMotion) {
      element.style.opacity = '0';
      return this.createNoopPlayer();
    }

    const factory = this.builder.build([
      style({ opacity: 1 }),
      animate(`${duration}ms ease-in`, style({ opacity: 0 }))
    ]);
    const player = factory.create(element);
    player.play();
    return player;
  }

  slideIn(element: HTMLElement, direction: 'left' | 'right' | 'up' | 'down' = 'left', duration = 300): AnimationPlayer {
    if (this.prefersReducedMotion) {
      return this.createNoopPlayer();
    }

    const transforms: Record<string, string> = {
      left: 'translateX(-100%)',
      right: 'translateX(100%)',
      up: 'translateY(-100%)',
      down: 'translateY(100%)'
    };

    const factory = this.builder.build([
      style({ transform: transforms[direction], opacity: 0 }),
      animate(`${duration}ms ease-out`, style({ transform: 'translate(0)', opacity: 1 }))
    ]);
    const player = factory.create(element);
    player.play();
    return player;
  }

  private createNoopPlayer(): AnimationPlayer {
    return { play: () => {}, pause: () => {}, cancel: () => {}, finish: () => {}, destroy: () => {}, onStart: new EventEmitter(), onDone: new EventEmitter(), onReset: new EventEmitter(), onDestroy: new EventEmitter() } as any;
  }
}
```

### Usage in Component

```typescript
import { Component, inject, ElementRef, viewChild, ChangeDetectionStrategy } from '@angular/core';
import { AnimationService } from './animation.service';

@Component({
  selector: 'app-animated-panel',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<div #panel class="panel">Content</div>`
})
export class AnimatedPanelComponent {
  private anim = inject(AnimationService);
  panel = viewChild.required<ElementRef>('panel');

  show() {
    this.anim.fadeIn(this.panel().nativeElement);
  }

  hide() {
    this.anim.fadeOut(this.panel().nativeElement);
  }
}
```

## Angular Declarative Animations

For enter/leave animations on structural directives, use `@angular/animations` triggers:

```typescript
import { trigger, transition, style, animate, state } from '@angular/animations';

// Fade in/out
export const fadeInOut = trigger('fadeInOut', [
  transition(':enter', [
    style({ opacity: 0 }),
    animate('300ms ease-out', style({ opacity: 1 }))
  ]),
  transition(':leave', [
    animate('300ms ease-in', style({ opacity: 0 }))
  ])
]);

// Slide in from right
export const slideInRight = trigger('slideInRight', [
  transition(':enter', [
    style({ transform: 'translateX(100%)', opacity: 0 }),
    animate('300ms ease-out', style({ transform: 'translateX(0)', opacity: 1 }))
  ]),
  transition(':leave', [
    animate('300ms ease-in', style({ transform: 'translateX(100%)', opacity: 0 }))
  ])
]);

// Height animation with state
export const expandCollapse = trigger('expandCollapse', [
  state('void', style({ height: '0', opacity: 0, overflow: 'hidden' })),
  state('*', style({ height: '*', opacity: 1, overflow: 'hidden' })),
  transition('void <=> *', animate('300ms ease-in-out'))
]);
```

### Template Usage

```html
<!-- Simple fade -->
@if (isVisible) {
  <div @fadeInOut class="panel">Content</div>
}

<!-- List animation -->
@for (item of items; track item.id) {
  <div @slideInRight>{{ item.name }}</div>
}
```

## Performance Considerations

### Use Transform and Opacity
```css
/* Good - GPU accelerated */
.element {
  transition: transform 0.3s ease, opacity 0.3s ease;
}

/* Bad - triggers layout */
.element {
  transition: width 0.3s ease, height 0.3s ease;
}
```

### Will Change
```css
/* Use sparingly for complex animations */
.animated-element {
  will-change: transform, opacity;
}

/* Remove after animation completes */
.animated-element.animation-complete {
  will-change: auto;
}
```

### Contain Layout
```css
/* Reduce layout recalculation */
.animated-container {
  contain: layout style;
}
```
