# Theme System

## Theme Switching Interface

```
ThemePort:
  - getCurrentTheme() -> Theme
  - setTheme(theme: Theme) -> void
  - getAvailableThemes() -> Theme[]
  - onThemeChange(callback: (theme: Theme) -> void) -> Unsubscribe
```

## Theme Implementation

- Use a root-level attribute (e.g., `<html data-theme="dark">` or `<body class="theme-dark">`) to control the global theme.
- Provide an interactive control (e.g., `<select>` or radio group) that updates this DOM attribute.
- Save theme preference to localStorage for persistence across sessions.
- Apply theme transitions smoothly: `transition: background-color 0.25s ease, color 0.25s ease;`

## High Contrast Mode

See [Accessibility Requirements](./accessibility.md#high-contrast-mode) for implementation.

## Reduced Motion

See [Accessibility Requirements](./accessibility.md#reduced-motion) for implementation.

## Theme Palette Template

```markdown
## Theme: [Name]

| Token | Light Value | Dark Value |
|-------|-------------|------------|
| --bg-primary | [hex] | [hex] |
| --bg-secondary | [hex] | [hex] |
| --surface-primary | [hex] | [hex] |
| --surface-secondary | [hex] | [hex] |
| --text-primary | [hex] | [hex] |
| --text-secondary | [hex] | [hex] |
| --accent-primary | [hex] | [hex] |
| --accent-secondary | [hex] | [hex] |
| --border-primary | [hex] | [hex] |
| --border-secondary | [hex] | [hex] |
```

## Theme Palette Examples

**Solarized**
| Token | Light | Dark |
|-------|-------|------|
| --bg-primary | #fdf6e3 | #002b36 |
| --bg-secondary | #eee8d5 | #073642 |
| --text-primary | #657b83 | #839496 |
| --text-secondary | #93a1a1 | #586e75 |
| --accent-primary | #2aa198 | #2aa198 |
| --border-primary | #93a1a1 | #586e75 |

**Catppuccin Mocha**
| Token | Light | Dark |
|-------|-------|------|
| --bg-primary | #eff1f5 | #1e1e2e |
| --bg-secondary | #e6e9ef | #313244 |
| --text-primary | #4c4f69 | #cdd6f4 |
| --text-secondary | #5c5f77 | #a6adc8 |
| --accent-primary | #1e66f5 | #89b4fa |
| --border-primary | #ccd0da | #45475a |

**Nord**
| Token | Light | Dark |
|-------|-------|------|
| --bg-primary | #eceff4 | #2e3440 |
| --bg-secondary | #e5e9f0 | #3b4252 |
| --text-primary | #2e3440 | #d8dee9 |
| --text-secondary | #4c566a | #a6adc8 |
| --accent-primary | #5e81ac | #88c0d0 |
| --border-primary | #d8dee9 | #4c566a |

## CSS Variables Implementation

### Light Theme (Default)
```css
:root {
  /* Background */
  --bg-primary: #ffffff;
  --bg-secondary: #f8f9fa;
  --bg-tertiary: #e9ecef;
  
  /* Surface */
  --surface-primary: #ffffff;
  --surface-secondary: #f8f9fa;
  --surface-elevated: #ffffff;
  
  /* Text */
  --text-primary: #212529;
  --text-secondary: #6c757d;
  --text-tertiary: #adb5bd;
  
  /* Border */
  --border-primary: #dee2e6;
  --border-secondary: #e9ecef;
  --border-focus: #2563eb;
  
  /* Accent */
  --accent-primary: #0d6efd;
  --accent-secondary: #6ea8fe;
  --accent-hover: #0b5ed7;
  
  /* State */
  --state-success: #198754;
  --state-warning: #ffc107;
  --state-error: #dc3545;
  --state-info: #0dcaf0;
  
  /* Shadow */
  --shadow-sm: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
  --shadow-md: 0 0.5rem 1rem rgba(0, 0, 0, 0.15);
  --shadow-lg: 0 1rem 3rem rgba(0, 0, 0, 0.175);
  --shadow-xl: 0 1rem 3rem rgba(0, 0, 0, 0.25);
  
  /* Z-index */
  --z-below: -1;
  --z-base: 0;
  --z-above: 1;
  --z-dropdown: 100;
  --z-sticky: 200;
  --z-overlay: 300;
  --z-modal: 400;
  --z-popover: 500;
  --z-tooltip: 600;
  --z-toast: 700;
  
  /* Border Radius */
  --border-radius-sm: 3px;
  --border-radius: 5px;
  --border-radius-lg: 8px;
  --border-radius-xl: 12px;
  --border-radius-full: 9999px;

  /* Spacing */
  --space-xs: 0.25rem;
  --space-sm: 0.5rem;
  --space-md: 1rem;
  --space-lg: 1.5rem;
  --space-xl: 2rem;
  --space-2xl: 3rem;
  
  /* Typography */
  --font-heading: system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  --font-body: system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  --font-mono: SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
  
  /* Font sizes */
  --font-size-xs: 0.75rem;
  --font-size-sm: 0.875rem;
  --font-size-base: 1rem;
  --font-size-lg: 1.125rem;
  --font-size-xl: 1.25rem;
  --font-size-2xl: 1.5rem;
  --font-size-3xl: 1.875rem;
  --font-size-4xl: 2.25rem;
  --font-size-5xl: 3rem;
  --font-size-6xl: 3.75rem;
  --font-size-7xl: 4.5rem;
  
  /* Font weights */
  --font-weight-light: 300;
  --font-weight-normal: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;
  
  /* Line heights */
  --line-height-tight: 1.25;
  --line-height-normal: 1.5;
  --line-height-relaxed: 1.75;
  
  /* Motion */
  --duration-instant: 0ms;
  --duration-fast: 100ms;
  --duration-normal: 200ms;
  --duration-slow: 300ms;
  --duration-slower: 500ms;
  
  /* Easing */
  --easing-default: cubic-bezier(0.4, 0, 0.2, 1);
  --easing-in: cubic-bezier(0.4, 0, 1, 1);
  --easing-out: cubic-bezier(0, 0, 0.2, 1);
  --easing-in-out: cubic-bezier(0.42, 0, 0.58, 1);
  --easing-bounce: cubic-bezier(0.68, -0.55, 0.265, 1.55);
  
  /* Breakpoints */
  --bp-xs: 0;
  --bp-sm: 576px;
  --bp-md: 768px;
  --bp-lg: 992px;
  --bp-xl: 1200px;
  --bp-xxl: 1400px;
}
```

### Dark Theme
```css
[data-theme="dark"] {
  /* Background */
  --bg-primary: #212529;
  --bg-secondary: #343a40;
  --bg-tertiary: #495057;
  
  /* Surface */
  --surface-primary: #343a40;
  --surface-secondary: #495057;
  --surface-elevated: #495057;
  
  /* Text */
  --text-primary: #f8f9fa;
  --text-secondary: #adb5bd;
  --text-tertiary: #6c757d;
  
  /* Border */
  --border-primary: #495057;
  --border-secondary: #6c757d;
  --border-focus: #93c5fd;
  
  /* Accent */
  --accent-primary: #6ea8fe;
  --accent-secondary: #9ec5fe;
  --accent-hover: #86b7fe;
  
  /* State */
  --state-success: #75b798;
  --state-warning: #ffda6a;
  --state-error: #ea868f;
  --state-info: #6edff6;
  
  /* Shadow */
  --shadow-sm: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.25);
  --shadow-md: 0 0.5rem 1rem rgba(0, 0, 0, 0.35);
  --shadow-lg: 0 1rem 3rem rgba(0, 0, 0, 0.4);
  --shadow-xl: 0 1rem 3rem rgba(0, 0, 0, 0.5);
  
  /* Dark mode elevation: shadows on dark backgrounds are subtle.
     For visible elevation, use lighter shadows or combine with
     subtle border highlights (e.g., border: 1px solid rgba(255,255,255,0.1)) */
}
```

## Theme JavaScript Implementation

```javascript
class ThemeManager {
  constructor() {
    this.currentTheme = this.getStoredTheme() || 'light';
    this.applyTheme(this.currentTheme);
  }
  
  getStoredTheme() {
    return localStorage.getItem('theme');
  }
  
  setStoredTheme(theme) {
    localStorage.setItem('theme', theme);
  }
  
  applyTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    this.currentTheme = theme;
    this.setStoredTheme(theme);
  }
  
  toggleTheme() {
    const newTheme = this.currentTheme === 'light' ? 'dark' : 'light';
    this.applyTheme(newTheme);
  }
  
  getAvailableThemes() {
    return ['light', 'dark'];
  }
  
  onThemeChange(callback) {
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.type === 'attributes' && mutation.attributeName === 'data-theme') {
          callback(this.currentTheme);
        }
      });
    });
    
    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['data-theme']
    });
    
    return () => observer.disconnect();
  }
}
```

## Theme Control HTML

```html
<!-- Simple select control -->
<select id="theme-select" aria-label="Select theme">
  <option value="light">Light</option>
  <option value="dark">Dark</option>
</select>

<!-- Radio group control -->
<fieldset>
  <legend>Theme</legend>
  <label>
    <input type="radio" name="theme" value="light" checked>
    Light
  </label>
  <label>
    <input type="radio" name="theme" value="dark">
    Dark
  </label>
</fieldset>

<!-- Toggle button -->
<button id="theme-toggle" aria-label="Toggle theme">
  <span class="icon-sun">☀️</span>
  <span class="icon-moon">🌙</span>
</button>
```

## Theme Accessibility

- Ensure theme toggle is keyboard accessible
- Announce theme changes to screen readers
- Maintain focus visibility in both themes
- Test color contrast in both light and dark modes
- Respect `prefers-color-scheme` media query for initial theme selection

```javascript
// Respect user preference
if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
  // User prefers dark theme
  themeManager.applyTheme('dark');
}

// Listen for preference changes
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
  if (!themeManager.getStoredTheme()) {
    themeManager.applyTheme(e.matches ? 'dark' : 'light');
  }
});
```
