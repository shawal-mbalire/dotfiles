# React Readiness

React is a first-class supported target for this design system. **Angular remains preferred** when both are viable; detection decides. Domain rules (tokens, Shape Spec, decision rules, haptics registry) are framework-agnostic; React adapters wire ports through Context.

## Framework Detection

| Signals in project | Target |
|--------------------|--------|
| `angular.json` | Angular |
| `package.json` with `react` dependency | React |
| `pubspec.yaml` | Flutter |
| Multiple or none | Ask the user once; do not guess |

When ambiguous, ask: "Should I generate Angular, React, or Flutter code for this?"

## Minimal Dependency Policy

**Allowed by default**: `react`, `react-dom`, `lucide-react`.

| Concern | Use (zero extra deps) | Do not add by default |
|---------|----------------------|------------------------|
| State | `useState`, `useReducer`, `useContext`, `useMemo` | redux, zustand, jotai, mobx |
| Async / optimistic | React 19 `useOptimistic`, `useActionState`, `useTransition`, `fetch` | react-query, swr, axios |
| Styling | CSS variables + CSS Modules (or SCSS) | tailwind, styled-components, emotion |
| Motion | CSS transitions/keyframes from [animations-library.md](../animations-library.md), optional Web Animations API | framer-motion, react-spring |
| Focus traps | Native `<dialog>.showModal()`; tiny local `useFocusTrap` only for non-dialog overlays | focus-trap, radix, headlessui |
| Forms | Controlled inputs + native constraint validation / small local validators | react-hook-form, formik, yup |
| Breakpoints | `matchMedia` in `useMediaQuery` hook + CSS container queries | react-responsive |
| Icons | `lucide-react` (same Lucide set) | font-awesome, custom SVG sets |
| Haptics | `HapticPort` + `WebHapticAdapter` (`navigator.vibrate`) from [haptics.md](../haptics.md) | vibration npm packages |

**Escape hatch**: additional dependencies only when the user explicitly requests them; note the exception in generated code comments.

## Token Mapping

CSS custom properties are used directly — no wrapper theme object required.

- Tokens live in global SCSS/CSS (`_tokens.scss`) exactly as in Angular targets.
- Components reference `var(--token)` in CSS Modules / SCSS.
- JS logic reads the active theme via `ThemeContext` (theme name only); colors stay in CSS.
- Theme switching sets `data-theme` on the root element (same as web/Angular).

## Architecture (Ports & Adapters)

Same hexagonal layout as Angular; adapters are plain TypeScript modules instead of `@Injectable` services.

```
src/
├── domain/                    # Pure TypeScript — zero React (and zero Angular) imports
│   ├── models/
│   ├── ports/                 # IconPort, ThemePort, LayoutPort, AnimationPort, HapticPort
│   └── workflows/             # Pure orchestration functions
├── adapters/                  # Framework-free or React-specific implementations
│   ├── icons/                 # LucideIconAdapter implements IconPort
│   ├── theme/                 # WebThemeAdapter implements ThemePort
│   ├── layout/                # matchMedia LayoutAdapter implements LayoutPort
│   ├── animation/             # WAAPI AnimationAdapter implements AnimationPort
│   └── haptics/               # WebHapticAdapter implements HapticPort
├── app/
│   ├── PortsProvider.tsx      # Composition root — wires ports into Context
│   └── hooks/                 # usePorts, useMediaQuery, useFocusTrap
├── components/                # Function components (co-located .module.css)
└── styles/
    └── _tokens.scss           # Design tokens as CSS variables
```

### Ports Context

```tsx
// app/PortsProvider.tsx
import { createContext, useContext, type ReactNode } from 'react';
import type { ThemePort } from '../domain/ports/ThemePort';
import type { HapticPort } from '../domain/ports/HapticPort';
// ...other ports

export interface Ports {
  theme: ThemePort;
  layout: LayoutPort;
  animation: AnimationPort;
  icons: IconPort;
  haptics: HapticPort;
}

const PortsContext = createContext<Ports | null>(null);

export function PortsProvider({ ports, children }: { ports: Ports; children: ReactNode }) {
  return <PortsContext.Provider value={ports}>{children}</PortsContext.Provider>;
}

export function usePorts(): Ports {
  const ports = useContext(PortsContext);
  if (!ports) throw new Error('usePorts must be used within PortsProvider');
  return ports;
}
```

### Composition Root

```tsx
// app/main.tsx
import { createRoot } from 'react-dom/client';
import { PortsProvider, type Ports } from './PortsProvider';
import { WebThemeAdapter } from '../adapters/theme/web-theme.adapter';
import { WebHapticAdapter } from '../adapters/haptics/web-haptic.adapter';
// ...other adapters

const ports: Ports = {
  theme: new WebThemeAdapter(),
  layout: new MatchMediaLayoutAdapter(),
  animation: new WaaPIAnimationAdapter(),
  icons: new LucideIconAdapter(),
  haptics: new WebHapticAdapter(),
};

createRoot(document.getElementById('root')!).render(
  <PortsProvider ports={ports}>
    <App />
  </PortsProvider>
);
```

### Rules

1. **Domain has zero React imports** — pure TypeScript interfaces/types only (shared verbatim with Angular/Flutter targets).
2. **Adapters implement ports** — plain classes/modules; React-free where possible (Web adapters are shared with the Angular web target).
3. **Components consume ports via `usePorts()`** — never import concrete adapters inside components.
4. **`PortsProvider` is the composition root** — the only place adapters are bound to ports.
5. **Tokens are CSS variables** — same `_tokens.scss` as every other target.

## Component Contracts

Same contracts as [components.md](../components.md); function-component translation:

| Web contract | React shape |
|--------------|-------------|
| Button (loading/retry states) | Function component + CSS module — full exemplar in [components.md](../components.md#button-component) |
| Card | Function component; hover/focus via CSS classes |
| Input | Controlled component; errors via `useSyncExternalStore`/`toSignal`-equivalent = subscribe to control status in state |
| Modal / Drawer / Menu | Native `<dialog>` (focus trap built in); `showModal()`/`close()` |
| Toast | Portal-free fixed container; state via context or lifted signal-equivalent (`useState`) |
| Tabs | Roving `tabindex` with local `useState` |
| Badge / ListItem / Navigation / Table / Tooltip | Same structure + classes as web |

## Motion Mapping

| Library primitive | React |
|-------------------|-------|
| CSS transition | Class/state toggle (`.is-lifted`, `.is-pressed`) — identical CSS |
| Keyframes (`.anim-*`) | Same utility classes from [animations-library.md](../animations-library.md) |
| Angular triggers (`@fade`, `@peelOff`) | CSS class-driven enter/leave (`is-entering` / `is-exiting`) + `onAnimationEnd` |
| `AnimationPort` | Web Animations API adapter (optional, programmatic only) |
| Reduced motion | Same `prefers-reduced-motion` CSS; `matchMedia` in JS only if choreography requires it |

No animation library dependency. Pattern 4 morph/peel use the shared CSS bundles.

## Focus Traps

- **Modal/Drawer**: prefer native `<dialog>` — browser traps focus and restores it; add `closedby` / backdrop handling per contract.
- **Menu**: `<dialog>` or a minimal local `useFocusTrap` hook (Tab cycling + restore trigger focus on close). Do not add a focus-trap package by default.
- **Tabs**: roving focus via `useState` + arrow-key handlers (same behavior as the CDK pattern).

## RTL

- Set `dir` on `<html>` (or a wrapping element); use logical properties (`inset-inline-*`, `margin-inline-*`) — CSS is shared across targets.
- Never hard-code `left`/`right` geometry.

## Icons

- `lucide-react` — same Lucide icon names as the Angular/web icon rules.
- No emoji in JSX, labels, or `aria-label`s.

## Responsive

- `useMediaQuery(query)` hook wrapping `window.matchMedia` with cleanup.
- Prefer CSS container queries for component-level responsiveness; hook only for behavioral branches.
- Breakpoints mirror `--bp-*`: 576 / 768 / 992 / 1200 / 1400.

## Loading States & Retry

- Follow the Retry Contract in [loading.md](../loading.md): dispatch ack → `loading` (`aria-busy`) → settled outcome; every retry press re-acks (visual press state). Haptics, if enabled, are a separate overlay — see [haptics.md](../haptics.md).
- Optimistic UI: React 19 `useOptimistic` + `useTransition` — see [loading.md](../loading.md).
- Button loading/retry exemplar: [components.md](../components.md#button-component).

## Haptics

- Inject `haptics` from `usePorts()`; call semantic events from [haptics.md](../haptics.md) (`tap`, `select`, `retry-ack`, `success`, `warning`, `error`).
- Web adapter (`navigator.vibrate`) is shared with the Angular target — no React-specific haptic code.

## Verification Checklist (React)

- [ ] Function components only; hooks for state/effects (React 19 baseline)
- [ ] Dependency budget honored: `react`, `react-dom`, `lucide-react` (exceptions user-approved)
- [ ] All colors/radii/durations from tokens (no magic numbers, no inline hex)
- [ ] Ports consumed via `usePorts()`; domain has zero React imports
- [ ] Modal focus trap via native `<dialog>` when possible; focus restored on close
- [ ] Logical CSS only (`inset-inline-*`, `margin-inline-*`)
- [ ] Lucide icons only; no emoji
- [ ] Async/retry states match [loading.md](../loading.md) contract (ack, `aria-busy`, attempt feedback)
- [ ] Haptics from registry only; paired with visual feedback
- [ ] `prefers-reduced-motion` respected
- [ ] Shape Spec matches decision-rules output
