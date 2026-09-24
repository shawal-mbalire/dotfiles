# Accessibility Requirements (WCAG AA)

## ARIA Roles by Component

| Component | ARIA Role | Additional Attributes |
|-----------|-----------|----------------------|
| Card | `article` | `aria-label` if no heading |
| Button | `button` | `aria-disabled` for disabled state |
| ListItem | `listitem` or `link` | `aria-current` for active state |
| Navigation | `navigation` | `aria-label` for multiple navs |
| Input | `textbox` | `aria-required`, `aria-invalid`, `aria-describedby` |
| Modal | `dialog` | `aria-modal`, `aria-labelledby` |
| Tab | `tab` | `aria-selected`, `aria-controls` |
| Tab Panel | `tabpanel` | `aria-labelledby` |

## Contrast Requirements (WCAG AA)

| Element Type | Minimum Contrast | Standard |
|--------------|------------------|----------|
| Normal text (<18px) | 4.5:1 | WCAG AA |
| Large text (≥18px or ≥14px bold) | 3:1 | WCAG AA |
| UI components & graphics | 3:1 | WCAG AA |
| Focus indicators | 3:1 | WCAG AA |

## Target Sizes (WCAG AA)

| Element Type | Minimum Size | Recommended | Standard |
|--------------|--------------|-------------|----------|
| Interactive elements | 24x24px | 44x44px | WCAG 2.5.8 |
| Touch targets | 44x44px | 48x48px | WCAG 2.5.5 Enhanced |

## Keyboard Navigation

- All interactive elements must be reachable via Tab key
- Focus order must follow visual order
- Focus indicator must be visible (2px outline minimum)
- Escape key must close modals/dropdowns
- Arrow keys should navigate within composite widgets (tabs, menus)

## Focus Traps

Overlays (modal, drawer, menu) must trap focus while open and restore focus to the trigger on close.

**Angular**: use Angular CDK `cdkTrapFocus` / `FocusTrapFactory` — do not hand-roll Tab-key listeners.

```typescript
import { FocusTrapFactory } from '@angular/cdk/a11y';

// In the open effect:
this.focusTrap = this.focusTrapFactory.create(this.dialogElement.nativeElement);
this.focusTrap.focusInitialElementWhenReady();
// On close: this.focusTrap.destroy(); then this.triggerElement?.focus();
```

```html
<div cdkTrapFocus *cdkTrapFocus="isOpen" class="modal__content" tabindex="-1">…</div>
```

**Flutter**: use `FocusScope` with `canRequestFocus` / `FocusTraversalGroup` (see [frameworks/flutter.md](./frameworks/flutter.md)).

## Focus Indicators

All focus indicators must:
- Have minimum 2px width
- Use `outline` or `box-shadow` (never `border` to avoid layout shift)
- Contrast ratio ≥ 3:1 against background
- Be visible in both light and dark themes

Example focus style:
```css
:focus-visible {
  outline: var(--border-focus-width, 2px) solid var(--border-focus);
  outline-offset: var(--border-focus-offset, 2px);
}
```

## Screen Reader Considerations

- Decorative icons: `aria-hidden="true"`
- Decorative numbers: `aria-hidden="true"`
- Required fields: `aria-required="true"`
- Error messages: `aria-describedby` linked to input
- Live regions: `aria-live="polite"` for dynamic content updates

## Reduced Motion

Respect user preferences:
```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

## High Contrast Mode

Support Windows High Contrast Mode:
```css
@media (forced-colors: active) {
  .btn {
    border: 2px solid ButtonText;
  }
  .card {
    border: 2px solid CanvasText;
  }
}
```

## Accessibility Checklist

- [ ] All images have alt text
- [ ] All inputs have labels
- [ ] Color contrast meets 4.5:1 (text) and 3:1 (UI)
- [ ] All interactive elements keyboard accessible
- [ ] Focus indicators visible
- [ ] ARIA roles applied correctly
- [ ] Target sizes meet 44x44px recommended (24x24px minimum)
- [ ] Reduced motion supported
- [ ] High contrast mode supported
- [ ] Screen reader tested

## Contrast Verification

To verify contrast ratios when generating code:

1. **Calculate relative luminance**: For colors in sRGB, use the formula:
   - L = 0.2126 * R + 0.7152 * G + 0.0722 * B
   - Where R, G, B are linearized (convert from sRGB: if value <= 0.03928, divide by 12.92; else raise to power 2.4 after adding 0.055 and dividing by 1.055)

2. **Calculate contrast ratio**: (L1 + 0.05) / (L2 + 0.05) where L1 is the lighter color

3. **Verify thresholds**:
   - Normal text (<18px): 4.5:1 minimum
   - Large text (≥18px or ≥14px bold): 3:1 minimum
   - UI components: 3:1 minimum

4. **Recommended tools**:
   - WebAIM Contrast Checker: https://webaim.org/resources/contrastchecker/
   - Chrome DevTools: Inspect element → Accessibility panel → Contrast ratio
   - Colour Contrast Analyser (desktop app)
