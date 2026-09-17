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

| Element Type | Minimum Size | Standard |
|--------------|--------------|----------|
| Interactive elements | 24x24px | WCAG 2.5.8 |
| Touch targets | 44x44px (recommended) | WCAG 2.5.5 Enhanced |

## Keyboard Navigation

- All interactive elements must be reachable via Tab key
- Focus order must follow visual order
- Focus indicator must be visible (2px outline minimum)
- Escape key must close modals/dropdowns
- Arrow keys should navigate within composite widgets (tabs, menus)

## Focus Indicators

All focus indicators must:
- Have minimum 2px width
- Use `outline` or `box-shadow` (never `border` to avoid layout shift)
- Contrast ratio ≥ 3:1 against background
- Be visible in both light and dark themes

Example focus style:
```css
:focus-visible {
  outline: 2px solid var(--border-focus);
  outline-offset: 2px;
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
- [ ] Target sizes meet 24x24px minimum
- [ ] Reduced motion supported
- [ ] High contrast mode supported
- [ ] Screen reader tested
