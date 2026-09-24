# Loading States

**Note on gradients**: Skeleton screens use `linear-gradient` for the shimmer effect. This is a functional animation for loading feedback, not visual decoration. The "no gradients" rule in patterns.md applies to decorative styling of base components (backgrounds, borders), not to loading state animations.

**Note on keyframes**: `shimmer`, `spin`, and `dotPulse` are defined in [animations-library.md](./animations-library.md). Do not redefine them here — reference the library names.

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
  animation: shimmer var(--duration-loading) infinite;
  border-radius: var(--border-radius-sm);
}

/* Skeleton variants */
.skeleton-text {
  height: 1em;
  margin-bottom: var(--space-sm);
}

.skeleton-title {
  height: 1.5em;
  width: 60%;
  margin-bottom: var(--space-md);
}

.skeleton-avatar {
  width: var(--size-spinner-md);
  height: var(--size-spinner-md);
  border-radius: var(--border-radius-full);
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
  height: var(--space-sm);
  background: var(--surface-secondary);
  border-radius: var(--border-radius-sm);
  overflow: hidden;
}

.progress-bar {
  height: 100%;
  background: var(--accent-primary);
  border-radius: var(--border-radius-sm);
  transition: width var(--duration-slow) var(--easing-default);
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
  width: var(--size-spinner-md);
  height: var(--size-spinner-md);
  border: var(--border-width) solid var(--border-primary);
  border-block-start-color: var(--accent-primary);
  border-radius: var(--border-radius-full);
  animation: spin var(--duration-spinner) linear infinite;
}

/* Small spinner */
.spinner--sm {
  width: var(--size-spinner-sm);
  height: var(--size-spinner-sm);
  border-width: 2px;
}

/* Large spinner */
.spinner--lg {
  width: var(--size-spinner-lg);
  height: var(--size-spinner-lg);
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
  gap: var(--space-xs);
}

.dot-loading span {
  width: var(--space-sm);
  height: var(--space-sm);
  border-radius: var(--border-radius-full);
  background: var(--accent-primary);
  animation: dotPulse var(--duration-spinner) ease-in-out infinite;
}

.dot-loading span:nth-child(1) { animation-delay: -0.32s; }
.dot-loading span:nth-child(2) { animation-delay: -0.16s; }
.dot-loading span:nth-child(3) { animation-delay: 0s; }
```

## Optimistic UI

Use framework builtins for optimistic updates. Angular example first; React 19 equivalent below.

### Angular (signals + HttpClient)

```typescript
import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

export interface OptimisticState<T> {
  data: T;
  pending: boolean;
  error: string | null;
}

@Injectable({ providedIn: 'root' })
export class OptimisticUIService {
  update<T>(
    http: HttpClient,
    url: string,
    currentData: T,
    updatePayload: Partial<T>,
    successCallback?: (result: T) => void,
    errorCallback?: (error: any) => void
  ): OptimisticState<T> {
    const state = signal<OptimisticState<T>>({
      data: { ...currentData, ...updatePayload },
      pending: true,
      error: null
    });

    firstValueFrom(http.put<T>(url, updatePayload))
      .then((result) => {
        state.set({ data: result, pending: false, error: null });
        successCallback?.(result);
      })
      .catch((error) => {
        // Rollback to original state
        state.set({ data: currentData, pending: false, error: error.message });
        errorCallback?.(error);
      });

    return state();
  }
}
```

### Angular Usage in Component

```typescript
import { Component, inject, signal, ChangeDetectionStrategy } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { OptimisticUIService } from './optimistic-ui.service';

@Component({
  selector: 'app-todo-item',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div [class.pending]="state.pending">
      <input
        [value]="state.data.title"
        (blur)="updateTitle($any($event.target).value)"
        [disabled]="state.pending">
      @if (state.error) {
        <span class="error">{{ state.error }}</span>
      }
    </div>
  `
})
export class TodoItemComponent {
  private http = inject(HttpClient);
  private optimisticUI = inject(OptimisticUIService);

  todo = signal({ id: 1, title: 'Buy milk' });
  state = signal({ data: this.todo(), pending: false, error: null });

  updateTitle(newTitle: string) {
    if (newTitle === this.todo().title) return;

    this.state.set(
      this.optimisticUI.update(
        this.http,
        `/api/todos/${this.todo().id}`,
        this.todo(),
        { title: newTitle },
        (result) => this.todo.set(result)
      )
    );
  }
}
```

### React 19 (useOptimistic)

Zero external deps — React 19 builtins only. Rollback **must** surface an error (Retry Contract rule 6).

```tsx
import { useOptimistic, useTransition, useState, type FormEvent } from 'react';

export function TodoItem({ todo }: { todo: { id: number; title: string } }) {
  const [current, setCurrent] = useState(todo);
  const [error, setError] = useState<string | null>(null);
  const [optimisticTitle, setOptimisticTitle] = useOptimistic(current.title);
  const [pending, startTransition] = useTransition();

  function updateTitle(title: string) {
    if (title === current.title) return;
    setError(null);
    startTransition(async () => {
      setOptimisticTitle(title);
      try {
        const res = await fetch(`/api/todos/${current.id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ title }),
        });
        if (!res.ok) throw new Error('Save failed');
        const result = await res.json();
        setCurrent(result);
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Save failed'); // visible — no silent rollback
      }
    });
  }

  return (
    <div className={pending ? 'is-pending' : undefined}>
      <input
        defaultValue={current.title}
        disabled={pending}
        aria-busy={pending || undefined}
        onBlur={(e: FormEvent<HTMLInputElement>) => updateTitle(e.currentTarget.value)}
      />
      {error && (
        <span role="alert" className="input-error-message">
          {error}
        </span>
      )}
    </div>
  );
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
  inset: 0;
  margin: auto;
  width: var(--size-icon-sm);
  height: var(--size-icon-sm);
  border: 2px solid transparent;
  border-block-start-color: currentColor;
  border-radius: var(--border-radius-full);
  animation: spin var(--duration-spinner) linear infinite;
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
  inset: 0;
  margin: auto;
  width: max-content;
  height: max-content;
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
  inset-inline-end: var(--space-sm);
  top: 50%;
  transform: translateY(-50%);
  width: var(--size-icon-sm);
  height: var(--size-icon-sm);
  border: 2px solid var(--border-primary);
  border-block-start-color: var(--accent-primary);
  border-radius: var(--border-radius-full);
  animation: spin var(--duration-spinner) linear infinite;
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
  margin-block-start: var(--space-xs);
}

.input-error-icon {
  color: var(--state-error);
  margin-inline-end: var(--space-xs);
}
```

```html
<div class="input-group">
  <input type="text" class="input input--error" aria-invalid="true" aria-describedby="email-error">
  <div class="input-error-message" id="email-error" role="alert">
    <ds-icon name="alert-triangle" [attr.aria-hidden]="true" class="input-error-icon" />
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
  background: var(--state-error-soft);
  border-radius: 0 0 var(--border-radius) var(--border-radius);
}
```

### Recovery Paths

- Provide inline correction (not just error message)
- Offer undo for destructive actions
- Allow retry for failed operations
- Clear errors when user starts correcting

## Retry Contract

**Every retry is a user action and must produce feedback** (Core Principle 18: Action Acknowledgement). Applies to all targets (Angular, React, Flutter). This contract is **visual/AT only** — haptics are a separate optional channel ([haptics.md](./haptics.md)) that may fire alongside but are never part of contract compliance.

### Lifecycle

```
press → dispatch ack (visual press state)
      → loading (spinner in control, aria-busy="true", control disabled for double-submit guard)
      → settled:
           success → success feedback (toast/inline)
           failure → error surface + attempt counter; control re-enabled for next retry
```

Rules:

1. **Re-ack every attempt** — each retry press fires the dispatch ack again (visual press state). Never suppress acks after the first failure.
2. **Attempt feedback** — show "Retrying… (attempt N of M)" or equivalent while pending when the operation has a known/max attempt count.
3. **Backoff is never silent** — while waiting before an automatic retry: control is disabled **with visible countdown text** ("Retry available in 4s"), or the retry stays manual-only. No invisible waiting states.
4. **Double-submit guard** — the retry control is `disabled` (and `aria-busy="true"` while in-flight) until the attempt settles.
5. **First fail vs re-fail** — both surface the same error affordance; only the attempt counter increments. Do not escalate visuals on each failure unless the error class changed.
6. **Rollback surfaces errors** — optimistic UI rollback must emit visible error feedback (inline or toast); a silent rollback violates the contract.
7. **Announce outcomes** — `role="alert"` / `aria-live` on failure; polite live region for "Retrying…" updates.
8. **Bounded waits** — every wait terminates in `success | error | timeout` (never hangs); operations that can exceed 1s get progress + cancel treatment per the response-time budgets in [reactions.md](./reactions.md).

### Retry Control Sketch

```html
<button
  class="button"
  [attr.aria-busy]="retrying() || null"
  [disabled]="retrying() || backoffRemaining() > 0"
  (click)="onRetry()">
  @if (backoffRemaining() > 0) {
    <span>Retry in {{ backoffRemaining() }}s</span>
  } @else if (retrying()) {
    <span class="spinner spinner--sm" aria-hidden="true"></span>
    <span>Retrying… (attempt {{ attempt() }} of {{ maxAttempts() }})</span>
  } @else {
    <span>Retry</span>
  }
</button>
```

### Angular Reactive Forms Validation

Use Angular's `FormGroup`, `FormControl`, and `Validators` for form validation:

```typescript
import { Component, inject, signal, ChangeDetectionStrategy } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators, AbstractControl, ValidationErrors } from '@angular/forms';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-validated-form',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <form [formGroup]="form" (ngSubmit)="onSubmit()">
      @if (formErrors().length > 0) {
        <div class="form-error-summary" role="alert">
          <h3>Please correct the following errors:</h3>
          <ul>
            @for (error of formErrors(); track error.field) {
              <li><a [href]="'#' + error.field">{{ error.message }}</a></li>
            }
          </ul>
        </div>
      }

      <div class="form-group">
        <label for="name">Name</label>
        <input
          id="name"
          formControlName="name"
          [class.input--error]="isFieldInvalid('name')">
        @if (isFieldInvalid('name')) {
          <div class="input-error-message" id="name-error" role="alert">
            {{ getFieldError('name') }}
          </div>
        }
      </div>

      <div class="form-group">
        <label for="email">Email</label>
        <input
          id="email"
          type="email"
          formControlName="email"
          [class.input--error]="isFieldInvalid('email')">
        @if (isFieldInvalid('email')) {
          <div class="input-error-message" id="email-error" role="alert">
            {{ getFieldError('email') }}
          </div>
        }
      </div>

      <button type="submit" [disabled]="form.invalid">Submit</button>
    </form>
  `
})
export class ValidatedFormComponent {
  private fb = inject(FormBuilder);

  form = this.fb.group({
    name: ['', [Validators.required, Validators.minLength(2)]],
    email: ['', [Validators.required, Validators.email]]
  });

  formErrors = signal<{ field: string; message: string }[]>([]);

  isFieldInvalid(field: string): boolean {
    const control = this.form.get(field);
    return !!(control && control.invalid && (control.dirty || control.touched));
  }

  getFieldError(field: string): string {
    const control = this.form.get(field);
    if (!control || !control.errors) return '';

    const errorMessages: Record<string, string> = {
      required: `${this.getFieldLabel(field)} is required.`,
      email: `${this.getFieldLabel(field)} must be a valid email.`,
      minlength: `${this.getFieldLabel(field)} must be at least ${control.errors['minlength'].requiredLength} characters.`
    };

    const firstError = Object.keys(control.errors)[0];
    return errorMessages[firstError] || `${this.getFieldLabel(field)} is invalid.`;
  }

  private getFieldLabel(field: string): string {
    const labels: Record<string, string> = { name: 'Name', email: 'Email' };
    return labels[field] || field;
  }

  onSubmit() {
    if (this.form.valid) {
      // Submit form
    } else {
      // Mark all fields as touched to show errors
      this.form.markAllAsTouched();

      // Build error summary
      const errors: { field: string; message: string }[] = [];
      Object.keys(this.form.controls).forEach(field => {
        if (this.isFieldInvalid(field)) {
          errors.push({ field, message: this.getFieldError(field) });
        }
      });
      this.formErrors.set(errors);

      // Focus first error field
      const firstErrorField = document.querySelector('[class.input--error]') as HTMLElement;
      firstErrorField?.focus();
    }
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
