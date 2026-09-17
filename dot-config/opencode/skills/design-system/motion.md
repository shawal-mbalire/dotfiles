# Motion Design

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

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

## JavaScript Animation Control

```javascript
class AnimationController {
  constructor() {
    this.prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  }
  
  shouldAnimate() {
    return !this.prefersReducedMotion;
  }
  
  animate(element, animation, duration = 300) {
    if (!this.shouldAnimate()) {
      element.style.opacity = '1';
      return Promise.resolve();
    }
    
    return new Promise((resolve) => {
      element.style.animation = `${animation} ${duration}ms ease-out`;
      element.addEventListener('animationend', () => {
        element.style.animation = '';
        resolve();
      }, { once: true });
    });
  }
  
  fadeIn(element, duration = 300) {
    return this.animate(element, 'fadeIn', duration);
  }
  
  fadeOut(element, duration = 300) {
    return this.animate(element, 'fadeOut', duration);
  }
  
  slideIn(element, direction = 'left', duration = 300) {
    const animation = `slideIn${direction.charAt(0).toUpperCase() + direction.slice(1)}`;
    return this.animate(element, animation, duration);
  }
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
