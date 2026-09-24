# Decision Rules

Questionnaire and decision logic for resolving Shape Specs in Pattern 4 (Morphic Surfaces). Each component gets a Shape Spec by answering these questions in order.

## Questionnaire

### Q1: Is this a surface (container) or a control (interactive element)?

- **Surface** → continue to Q2
- **Control** → continue to Q2

Both paths lead to Q2. The answer determines which motion bundle applies.

### Q2: Does this component have an inner well (nested content area)?

The "well" is a visually distinct inner region — a recessed or contrasting area that holds content within the outer shell.

- **Yes** (e.g., card with content area, input with text region) → Q5 = `yes`
- **No** (e.g., badge, chip, avatar, standalone button) → Q5 = `no`

### Q3: Should the component lift on hover?

- **Yes** (cards, clickable surfaces) → `lift` motion bundle
- **No** (static surfaces, decorative) → `settle` motion bundle

### Q4: Should the component bloom (radius expand) on hover?

- **Yes** (cards, prominent surfaces) → outer radius steps up one level on hover
- **No** (compact controls, tight spaces) → radius stays constant

### Q5: Is there an inner well?

This is the output of Q2. Used by lint rule `pattern-4-dual-radius`.

- **yes** → component must set both `--radius-outer-*` and `--radius-inner-*`
- **no** → component sets only `--radius-outer-*`; omit well structure

### Q6: Does the component need a peel exit animation?

- **Yes** (modals, drawers, dismissible surfaces) → exit uses `peelOff` animation
- **No** (toasts, non-dismissible overlays) → exit uses `fadeOut` or `slideOut`

## Shape Spec Output

After answering all questions, the Shape Spec is:

```
pattern: 4
surface-type: surface | control
well: yes | no
lift: yes | no
bloom: yes | no
exit: peel | fade | slide
```

## Motion Bundles

### Lift Bundle

Applied to surfaces that rise on hover.

```css
.surface {
  transition:
    transform var(--duration-normal) var(--easing-peel),
    box-shadow var(--duration-slow) var(--easing-default),
    border-radius var(--duration-morph) var(--easing-morph);
}

.surface:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-hover);
}
```

### Settle Bundle

Applied to static surfaces that don't lift.

```css
.surface {
  transition:
    box-shadow var(--duration-slow) var(--easing-default),
    border-radius var(--duration-morph) var(--easing-morph);
}
```

### Peel Exit Bundle

Applied to dismissible surfaces (modals, drawers).

```css
/* Used with @angular/animations or CSS keyframes */
.surface--exiting {
  animation: peelOff var(--duration-slow) var(--easing-peel) forwards;
}
```

### Fade Exit Bundle

Applied to non-dismissible overlays (toasts, notifications).

```css
.surface--exiting {
  animation: fadeOut var(--duration-normal) var(--easing-default) forwards;
}
```

## Decision Flow Chart

```
Component
  │
  ├─ Pattern ≠ 4? → Use pattern-specific rules (1, 2, or 3)
  │
  └─ Pattern = 4?
       │
       ├─ Q2: Has inner well?
       │    ├─ Yes → Set both --radius-outer-* and --radius-inner-*
       │    └─ No  → Set only --radius-outer-*
       │
       ├─ Q3: Lift on hover?
       │    ├─ Yes → Apply lift bundle (transform + shadow + radius)
       │    └─ No  → Apply settle bundle (shadow + radius only)
       │
       ├─ Q4: Bloom radius on hover?
       │    ├─ Yes → Outer + inner radii step up one level on hover
       │    └─ No  → Radii stay constant
       │
       └─ Q6: Peel exit?
            ├─ Yes → peelOff animation (lift → fade → radius contract)
            └─ No  → fadeOut or slideOut animation
```

## Examples

### Card (Surface, Well, Lift, Bloom, Peel Exit)

```
Shape Spec:
  pattern: 4
  surface-type: surface
  well: yes
  lift: yes
  bloom: yes
  exit: peel
```

```css
.card {
  background: var(--surface-primary);
  border-radius: var(--radius-outer-lg);
  box-shadow: var(--shadow-sm);
  transition:
    transform var(--duration-normal) var(--easing-peel),
    box-shadow var(--duration-slow) var(--easing-default),
    border-radius var(--duration-morph) var(--easing-morph);
}

.card:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-hover);
  border-radius: var(--radius-outer-xl);
}

.card__well {
  background: var(--bg-primary);
  border-radius: var(--radius-inner-lg);
  transition: border-radius var(--duration-morph) var(--easing-morph);
}

.card:hover .card__well {
  border-radius: var(--radius-inner-xl);
}
```

### Badge (Surface, No Well, No Lift, No Bloom, Fade Exit)

```
Shape Spec:
  pattern: 4
  surface-type: surface
  well: no
  lift: no
  bloom: no
  exit: fade
```

```css
.badge {
  background: var(--surface-primary);
  border-radius: var(--radius-outer-sm);
  box-shadow: var(--shadow-sm);
  transition: box-shadow var(--duration-slow) var(--easing-default);
}
```

### Button (Control, No Well, Lift on Press, No Bloom, No Exit)

Retry controls are the same Shape Spec as buttons (`surface-type: control`, `exit: none`); the retry lifecycle (ack → loading → outcome) lives in [loading.md](./loading.md).

```
Shape Spec:
  pattern: 4
  surface-type: control
  well: no
  lift: no
  bloom: no
  exit: none
```

```css
.btn {
  background: var(--accent-primary);
  border-radius: var(--radius-outer-md);
  box-shadow: var(--shadow-sm);
  transition:
    background-color var(--duration-normal) var(--easing-default),
    transform var(--duration-fast) var(--easing-default),
    box-shadow var(--duration-normal) var(--easing-default);
}

.btn:hover {
  box-shadow: var(--shadow-hover);
}

.btn:active {
  transform: scale(0.98);
  box-shadow: var(--shadow-active);
}
```

## Lint Rule Mapping

| Question | Lint Rule | Severity |
|----------|-----------|----------|
| Q5 = yes | `pattern-4-dual-radius` | ERROR |
| Q6 = peel | `pattern-4-peel-exit` | WARNING |
| Any | `shape-spec-match` | ERROR |
| Any | `morph-uses-library-tokens` | WARNING |

## Binding Rule: Peel vs Fade (L4)

When deciding between peel and fade exits:

- **Peel** when the surface has a physical, layered quality (cards, drawers, modals that feel "lifted"). The peel animation reinforces the spatial metaphor.
- **Fade** when the surface is a flat overlay (toasts, notifications, tooltips). These don't have spatial depth, so a peel would feel disconnected.

Rule of thumb: if Q3 = yes (lift on hover), then Q6 = peel. If Q3 = no, then Q6 = fade.
