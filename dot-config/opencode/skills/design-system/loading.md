# Loading States

## Skeleton Screens

Use skeleton screens for content loading:

```css
.skeleton {
  background: linear-gradient(
    90deg,
    var(--surface-primary) 25%,
    var(--surface-secondary) 50%,
    var(--surface-primary) 75%
  );
  background-size: 200% 100%;
  animation: skeleton-shimmer 1.5s infinite;
  border-radius: 4px;
}

@keyframes skeleton-shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}

/* Skeleton variants */
.skeleton-text {
  height: 1em;
  margin-bottom: 0.5em;
}

.skeleton-title {
  height: 1.5em;
  width: 60%;
  margin-bottom: 1em;
}

.skeleton-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
}

.skeleton-image {
  width: 100%;
  height: 200px;
}

.skeleton-button {
  width: 120px;
  height: 40px;
}
```

## Progress Indicators

### Determinate Progress
Progress bar with percentage. Use for known durations.

```css
.progress {
  width: 100%;
  height: 8px;
  background: var(--surface-secondary);
  border-radius: 4px;
  overflow: hidden;
}

.progress-bar {
  height: 100%;
  background: var(--accent-primary);
  border-radius: 4px;
  transition: width 0.3s ease;
}

.progress-bar--success {
  background: var(--state-success);
}

.progress-bar--warning {
  background: var(--state-warning);
}

.progress-bar--error {
  background: var(--state-error);
}
```

```html
<div class="progress" role="progressbar" aria-valuenow="75" aria-valuemin="0" aria-valuemax="100">
  <div class="progress-bar" style="width: 75%"></div>
</div>
```

### Indeterminate Progress
Spinner or infinite progress bar. Use for unknown durations.

```css
.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid var(--border-primary);
  border-top: 4px solid var(--accent-primary);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* Small spinner */
.spinner--sm {
  width: 20px;
  height: 20px;
  border-width: 2px;
}

/* Large spinner */
.spinner--lg {
  width: 60px;
  height: 60px;
  border-width: 6px;
}

/* Inline spinner */
.spinner--inline {
  display: inline-block;
  vertical-align: middle;
}
```

```html
<div class="spinner" aria-label="Loading..."></div>
```

### Dots Loading
```css
.dot-loading {
  display: flex;
  gap: 4px;
}

.dot-loading span {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--accent-primary);
  animation: dot-pulse 1.4s ease-in-out infinite;
}

.dot-loading span:nth-child(1) { animation-delay: -0.32s; }
.dot-loading span:nth-child(2) { animation-delay: -0.16s; }
.dot-loading span:nth-child(3) { animation-delay: 0s; }

@keyframes dot-pulse {
  0%, 80%, 100% { transform: scale(0); }
  40% { transform: scale(1); }
}
```

## Optimistic UI

- Update UI immediately before server confirms
- Rollback on failure
- Show success toast on confirmation

```javascript
class OptimisticUI {
  constructor(element) {
    this.element = element;
    this.originalState = null;
  }
  
  update(updateFn, rollbackFn, asyncFn) {
    // Save original state
    this.originalState = this.element.innerHTML;
    
    // Apply optimistic update
    updateFn();
    
    // Try async operation
    return asyncFn()
      .then((result) => {
        // Apply server response
        this.element.innerHTML = result;
        return result;
      })
      .catch((error) => {
        // Rollback on failure
        this.element.innerHTML = this.originalState;
        rollbackFn(error);
        throw error;
      });
  }
}
```

## Loading States for Components

### Button Loading
```css
.button--loading {
  position: relative;
  pointer-events: none;
  color: transparent;
}

.button--loading::after {
  content: '';
  position: absolute;
  width: 16px;
  height: 16px;
  border: 2px solid transparent;
  border-top-color: currentColor;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
  top: 50%;
  left: 50%;
  margin-top: -8px;
  margin-left: -8px;
}
```

```html
<button class="button button--loading" disabled>
  <span>Submit</span>
</button>
```

### Card Loading
```css
.card--loading {
  position: relative;
  overflow: hidden;
}

.card--loading::after {
  content: '';
  position: absolute;
  inset: 0;
  background: var(--surface-primary);
  opacity: 0.7;
}

.card--loading .card__content {
  visibility: hidden;
}

.card--loading .spinner {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  z-index: 1;
}
```

### Input Loading
```css
.input--loading {
  position: relative;
}

.input--loading::after {
  content: '';
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  width: 16px;
  height: 16px;
  border: 2px solid var(--border-primary);
  border-top-color: var(--accent-primary);
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}
```

## Error States

### Input Validation Patterns

**Inline Validation:**
- Validate on blur (not on every keystroke)
- Show error below the input
- Use `aria-describedby` to link error message
- Use `aria-invalid="true"` on invalid inputs

**Error Message Format:**
```
[Field Label] is required.
[Field Label] must be at least [X] characters.
[Field Label] must be a valid [format].
```

### Error States for Components

**Input Error:**
- Border color: --state-error
- Error message below input
- Icon indicator (optional)

```css
.input--error {
  border-color: var(--state-error);
}

.input-error-message {
  color: var(--state-error);
  font-size: var(--font-size-sm);
  margin-top: var(--space-xs);
}

.input-error-icon {
  color: var(--state-error);
  margin-right: var(--space-xs);
}
```

```html
<div class="input-group">
  <input type="text" class="input input--error" aria-invalid="true" aria-describedby="email-error">
  <div class="input-error-message" id="email-error">
    <span class="input-error-icon">⚠️</span>
    Email is required.
  </div>
</div>
```

**Form Error:**
- Summary at top of form
- Individual field errors
- Focus first error field

```html
<div class="form-error-summary" role="alert">
  <h3>Please correct the following errors:</h3>
  <ul>
    <li><a href="#name">Name is required</a></li>
    <li><a href="#email">Email is invalid</a></li>
  </ul>
</div>
```

**Card Error:**
- Error state variant
- Retry action
- Clear error message

```css
.card--error {
  border-color: var(--state-error);
}

.card__error-message {
  color: var(--state-error);
  padding: var(--space-md);
  background: rgba(220, 53, 69, 0.1);
  border-radius: 0 0 var(--border-radius) var(--border-radius);
}
```

### Recovery Paths

- Provide inline correction (not just error message)
- Offer undo for destructive actions
- Allow retry for failed operations
- Clear errors when user starts correcting

```javascript
class FormValidator {
  constructor(form) {
    this.form = form;
    this.errors = new Map();
  }
  
  validateField(field) {
    const error = this.getFieldError(field);
    
    if (error) {
      this.errors.set(field.name, error);
      this.showFieldError(field, error);
      return false;
    } else {
      this.errors.delete(field.name);
      this.clearFieldError(field);
      return true;
    }
  }
  
  getFieldError(field) {
    if (field.required && !field.value.trim()) {
      return `${field.label} is required.`;
    }
    
    if (field.type === 'email' && !this.isValidEmail(field.value)) {
      return `${field.label} must be a valid email.`;
    }
    
    if (field.minLength && field.value.length < field.minLength) {
      return `${field.label} must be at least ${field.minLength} characters.`;
    }
    
    return null;
  }
  
  showFieldError(field, error) {
    field.setAttribute('aria-invalid', 'true');
    field.setAttribute('aria-describedby', `${field.name}-error`);
    
    let errorEl = document.getElementById(`${field.name}-error`);
    if (!errorEl) {
      errorEl = document.createElement('div');
      errorEl.id = `${field.name}-error`;
      errorEl.className = 'input-error-message';
      errorEl.setAttribute('role', 'alert');
      field.parentNode.appendChild(errorEl);
    }
    
    errorEl.textContent = error;
  }
  
  clearFieldError(field) {
    field.removeAttribute('aria-invalid');
    field.removeAttribute('aria-describedby');
    
    const errorEl = document.getElementById(`${field.name}-error`);
    if (errorEl) {
      errorEl.remove();
    }
  }
  
  validateForm() {
    let isValid = true;
    this.errors.clear();
    
    const fields = this.form.querySelectorAll('input, textarea, select');
    fields.forEach((field) => {
      if (!this.validateField(field)) {
        isValid = false;
      }
    });
    
    if (!isValid) {
      this.showErrorSummary();
      this.focusFirstError();
    }
    
    return isValid;
  }
  
  showErrorSummary() {
    let summaryEl = this.form.querySelector('.form-error-summary');
    
    if (!summaryEl) {
      summaryEl = document.createElement('div');
      summaryEl.className = 'form-error-summary';
      summaryEl.setAttribute('role', 'alert');
      this.form.insertBefore(summaryEl, this.form.firstChild);
    }
    
    const errorList = Array.from(this.errors.entries())
      .map(([name, error]) => `<li><a href="#${name}">${error}</a></li>`)
      .join('');
    
    summaryEl.innerHTML = `
      <h3>Please correct the following errors:</h3>
      <ul>${errorList}</ul>
    `;
  }
  
  focusFirstError() {
    const firstErrorField = this.form.querySelector('[aria-invalid="true"]');
    if (firstErrorField) {
      firstErrorField.focus();
    }
  }
  
  isValidEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }
}
```

## Accessibility for Loading States

- Announce loading states to screen readers
- Use `aria-busy="true"` on loading containers
- Provide `aria-live="polite"` for status updates
- Ensure loading indicators are visible and have sufficient contrast

```html
<div aria-busy="true" aria-live="polite">
  <div class="spinner" aria-label="Loading content..."></div>
  <span class="sr-only">Loading...</span>
</div>
```

```css
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}
```
