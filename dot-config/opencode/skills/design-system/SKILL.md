---
name: design-system
description: Generate HTML and CSS based on UI/UX Design Patterns with strict token adherence, accessibility compliance, and theme adaptability. Includes a rule-based shape questionnaire, dual-radius morph pattern, and animations library. Use when building UI components, implementing design systems, creating responsive layouts, applying consistent visual patterns, defining morph transitions, or running design decision rules across web interfaces.
---

# Design System Skill

This skill provides guidelines for generating HTML and CSS based on UI/UX Design Patterns, with **Angular as the preferred frontend framework**. The focus is on **pluggable, token-driven design** that enforces consistency through lint rules and architectural constraints.

## Core Focus

1. **Pluggable Design** — Components accept configuration via injection tokens and signals. Swap visual strategies without modifying component logic.
2. **Token-Driven** — Every visual value traces to a design token. No ad-hoc CSS values.
3. **Lint-Enforced** — Design rules are enforced programmatically, not just documented. See [lint-rules.md](./lint-rules.md).
4. **Hexagonal Architecture** — Angular projects follow hexagonal (ports & adapters) architecture. Domain logic is framework-agnostic. Adapters handle Angular-specific plumbing.

## Framework Preference

**Angular** is the preferred framework. **Flutter** is a supported target.

### Framework Detection

| Signals in project | Target |
|--------------------|--------|
| `angular.json` | Angular |
| `pubspec.yaml` | Flutter |
| Both or neither | Ask the user once; do not guess |

When ambiguous, ask: "Should I generate Angular or Flutter code for this?"

### Angular Implementation Notes

When generating Angular component code, services, or interactive behavior:

- Use Angular **standalone components** (default since Angular 15+)
- Use **signals** for reactive state management (Angular 16+)
- Use **OnPush change detection** by default for performance
- Use **Angular CDK** for layout, accessibility, and breakpoint utilities
- Use **Angular animations** (`@angular/animations`) for complex enter/leave transitions
- Use **Angular DI** (`@Injectable`, `providedIn`) for services
- Use Angular **template syntax** (`*ngIf`, `*ngFor`, `[class]`, `(click)`) in examples
- Use **SCSS** for component styles with `encapsulation: ViewEncapsulation.None` where design tokens require global access

When generating JavaScript logic (validators, managers, controllers), always provide the **Angular implementation** first, with vanilla JS as a fallback only when explicitly requested.

### Flutter Implementation Notes

See [frameworks/flutter.md](./frameworks/flutter.md) for Flutter-specific mapping (tokens → ThemeExtension, ports → adapters, widget contracts, motion mapping, focus traps, RTL via Directionality).

## Reference Files

`SKILL.md` is the map. Open a file below only when you need its depth.

| Topic | File |
|-------|------|
| Color, typography, spacing, elevation, motion, z-index, breakpoint tokens | [tokens.md](./tokens.md) |
| Card, button, list item, navigation, input, link component contracts | [components.md](./components.md) |
| Multi-theme, numbered list, flat theme, morphic surfaces pattern specifications | [patterns.md](./patterns.md) |
| Shape questionnaire, layered decision rules, Shape Spec consistency | [decision-rules.md](./decision-rules.md) |
| WCAG AA requirements, ARIA roles, contrast, keyboard navigation, focus traps | [accessibility.md](./accessibility.md) |
| Nielsen Norman heuristics for design system implementation | [usability.md](./usability.md) |
| Desktop-first strategy, container queries, fluid typography | [responsive.md](./responsive.md) |
| Theme switching, CSS variables, palette examples, Angular service | [themes.md](./themes.md) |
| Motion principles, timing functions, transition property tables | [motion.md](./motion.md) |
| Keyframe registry, utility classes, AnimationPort/Service, morph and peel recipes | [animations-library.md](./animations-library.md) |
| Box model, specificity, OOCSS naming, Angular file structure, utilities | [architecture.md](./architecture.md) |
| Skeleton screens, progress indicators, error states, Angular services | [loading.md](./loading.md) |
| RTL support, text expansion, bidirectional text, locale formatting | [i18n.md](./i18n.md) |
| UI lifestyle categories, navigation patterns, content hierarchy | [ui-lifestyles.md](./ui-lifestyles.md) |
| Design lint rules, token enforcement, no-emoji, Lucide icons, no-gradients | [lint-rules.md](./lint-rules.md) |
| Flutter token mapping, widget contracts, focus traps, RTL, reduced motion | [frameworks/flutter.md](./frameworks/flutter.md) |

## Evaluation Rubric

When generating HTML, CSS, or component code based on these guidelines, evaluate output against:

1. **Token Accuracy**: Are specific CSS values (e.g., exact border-radius, border-widths, spacing scales) strictly applied without deviation?
2. **Structural Fidelity**: Does HTML markup follow required nested structure (e.g., semantic tags, flexbox containers, distinct span wrappers)?
3. **Interaction Completeness**: Are all defined :hover, :active, and :focus states fully implemented with appropriate CSS transitions?
4. **Theme Adaptability**: Are all color values handled via CSS variables (e.g., var(--bg-color)) rather than hardcoded hex/RGB values?
5. **Accessibility Compliance**: Does output meet WCAG AA requirements (contrast, keyboard, ARIA)?
6. **Usability Compliance**: Does output follow Nielsen Norman usability heuristics?
7. **Visual Hierarchy**: Does output establish clear reading order through typography scale, color opacity, and spacing rhythm?
8. **Angular Idiomatic**: Does Angular code use standalone components, OnPush change detection, signals for state, and proper DI patterns?
9. **Angular Performance**: Does code avoid unnecessary re-renders, use `trackBy` in `*ngFor`, and apply `ChangeDetectionStrategy.OnPush`?
10. **Lint Compliance**: Does output pass all design lint rules (no hardcoded values, no gradients, no emojis, Lucide icons only)?
11. **Hexagonal Purity**: Does domain code have zero Angular imports? Do components depend on ports, not concrete adapters?
12. **Motion Compliance**: Do animations come from the animations library, use motion tokens (no raw ms/cubic-bezier), and honor `prefers-reduced-motion`?
13. **Consistency**: Does the component match the Shape Spec resolved by the decision-rules questionnaire (same answers ⇒ identical radius, elevation, structure, motion bundle)?

## Core Principles

1. **Minimal DOM Complexity**: Generated HTML must be as flat as possible. Avoid unnecessary wrapper `<div>` elements ("divitis"). Leverage CSS layouts over wrappers, use semantic tags first, apply styles directly, and use pseudo-elements for decorative additions.

2. **CSS Variables for All Colors**: NEVER hardcode color values in component CSS. All backgrounds, text, and border colors must map to CSS variable tokens defined in the root theme stylesheet.

3. **Accessibility by Default**: Every component must be accessible: visible focus indicators, WCAG AA contrast (4.5:1 for text, 3:1 for UI), alt text for images, keyboard navigation, and ARIA roles where semantic HTML is insufficient.

4. **Progressive Enhancement**: Build from baseline up to enhanced experiences: base styles work without JavaScript, enhanced interactions layer on top, use `@supports` for feature detection, and provide fallbacks for advanced CSS features.

5. **Separation of Concerns**: Maintain clear separation: HTML for structure and semantics only, CSS for presentation and visual behavior, TypeScript for interactivity and state management. In Angular, this maps to: templates (HTML), styles (SCSS), and component class (TypeScript).

6. **Consistent Token Usage**: Use design tokens consistently across all components. Never introduce ad-hoc values. Tokens ensure visual consistency and maintainability.

7. **Interaction Completeness**: Every interactive element must have hover, focus, active, and disabled states. Transitions should be purposeful and respect user motion preferences.

8. **Responsive by Design**: All components must work across breakpoints. Use fluid typography, flexible layouts, and container queries where appropriate. In Angular, prefer `@angular/cdk/layout` BreakpointObserver for responsive logic.

9. **Theme Agnostic**: Components should work in any theme without modification. Use CSS variables for all theme-dependent values. In Angular, inject a `ThemeService` rather than directly manipulating the DOM.

10. **Performance Conscious**: Minimize reflows, use transform/opacity for animations, leverage CSS containment, and avoid expensive layout calculations. In Angular, use `OnPush` change detection, signal-based reactivity, and `trackBy` functions.

11. **Visual Hierarchy**: Establish clear reading order and importance through:
    - **Typography Scale**: Font size, weight, and line height create hierarchy
    - **Color Opacity**: Text opacity (100% primary, 70% secondary, 50% tertiary, 30% disabled)
    - **Spacing Rhythm**: Consistent padding/margins create visual relationships
    - **Component Hierarchy**: Titles > Subtitles > Body > Captions

12. **Opacity-Based Hierarchy**: Use opacity changes for:
    - **Text Levels**: Primary (100%), Secondary (70%), Tertiary (50%), Disabled (30%)
    - **Interaction States**: Default (100%), Hover (90%), Active (80%), Disabled (50%)
    - **Visual Layering**: Background opacity indicates depth and importance

13. **Internationalization Ready**: Use logical properties for RTL support, ensure text expansion accommodation, and respect bidirectional text requirements. In Angular, use `@angular/localize` and inject `LOCALE_ID`.

14. **Error Prevention**: Validate inputs, provide clear error messages, and offer recovery paths. Never let users reach error states without guidance. In Angular, use reactive forms with `Validators` and `AbstractControl`.

15. **Progressive Disclosure**: Show only what's needed when it's needed. Reduce cognitive load through appropriate information architecture.

16. **Consistent Interaction Patterns**: Similar components should behave similarly. Users should be able to predict interactions based on prior experience.

17. **Documentation as Code**: Design decisions should be documented through token names, component contracts, and pattern specifications. In Angular, use JSDoc on component inputs/outputs and Storybook for visual documentation.

---

## Design Patterns

Patterns provide visual approaches for structuring UI. The choice between patterns is user discretion based on project needs, brand identity, and design goals. All patterns address core design concerns: accessibility, responsiveness, theme adaptability, and interaction completeness.

### Pattern Selection Guidance

Consider the following when choosing a pattern:

- **Pattern 1 (Multi-Theme Containers & Controls)**: Best for applications requiring multiple color themes, consistent geometric aesthetic, and clear visual hierarchy through borders and shadows.

- **Pattern 2 (Interactive Numbered List)**: Best for minimalist, typography-focused interfaces where clean rows and hover interactions take precedence over heavy containers.

- **Pattern 3 (Minimalist Flat Theme)**: Best for modern, clean interfaces with restricted color palettes, subtle depth through shadows, and emphasis on content over chrome.

- **Pattern 4 (Morphic Surfaces)**: Best for interactive apps where components should feel like one continuous material — dual-radius shells that morph between states with tasteful lift/peel ("coming off") motion.

**Important**: These patterns are not mutually exclusive. Elements from different patterns can be combined within an application as long as the visual language remains consistent.

### Angular Implementation Notes

- **Pattern switching**: Use Angular DI to inject pattern-specific strategy services (e.g., `PATTERN_STRATEGY` token).
- **Component variants**: Use `@Input()` or `input()` to toggle between pattern variants (e.g., `variant: 'elevated' | 'bordered' | 'flat'`).
- **Theme classes**: Apply pattern-specific classes via `[class]` binding: `[class.pattern-1]="pattern === 1"`.
- **CSS encapsulation**: Use `ViewEncapsulation.None` when pattern styles must override global token values.

### All Patterns Address:

- ✅ Accessibility (WCAG AA compliance)
- ✅ Responsive design (desktop-first strategy)
- ✅ Theme adaptability (CSS variables)
- ✅ Interaction completeness (hover, focus, active, disabled)
- ✅ Reduced motion support
- ✅ High contrast mode support
- ✅ Keyboard navigation
- ✅ Screen reader compatibility

See [patterns.md](./patterns.md) for detailed specifications.

---

## Hexagonal Architecture for Angular

Angular projects should follow hexagonal (ports & adapters) architecture. The design system layer sits in the **adapters** ring, implementing domain ports.

### Layer Mapping

```
src/
├── domain/                    # Pure TypeScript, zero Angular imports
│   ├── models/                # Component config interfaces, theme models
│   ├── ports/                 # IconPort, ThemePort, LayoutPort, AnimationPort
│   └── workflows/             # UI orchestration logic (pure functions)
├── adapters/                  # Angular implementations of ports
│   ├── icons/                 # LucideIconAdapter implements IconPort
│   ├── theme/                 # ThemeService implements ThemePort
│   ├── layout/                # BreakpointAdapter implements LayoutPort
│   └── animation/             # AngularAnimationAdapter implements AnimationPort
├── shared/                    # Angular standalone components
│   ├── components/
│   └── pipes/
├── app.config.ts              # Composition root — wires ports to adapters
└── styles/
    └── _tokens.scss           # Design tokens as CSS variables
```

### Key Ports for Design System

```typescript
// domain/ports/IconPort.ts
export interface IconPort {
  getIcon(name: string): string;
  getAvailableIcons(): string[];
}

// domain/ports/ThemePort.ts
export interface ThemePort {
  getCurrentTheme(): string;
  setTheme(theme: string): void;
  getAvailableThemes(): string[];
}

// domain/ports/LayoutPort.ts
export interface LayoutPort {
  isMobile(): boolean;
  isTablet(): boolean;
  isDesktop(): boolean;
  getBreakpoint(): string;
}

// domain/ports/AnimationPort.ts
export interface MorphState {
  outerRadius: string;
  innerRadius?: string;
  scale?: number;
}

export interface PeelOptions {
  duration?: number;
  distance?: number;
}

export interface AnimationPort {
  fadeIn(element: HTMLElement, duration?: number): void;
  fadeOut(element: HTMLElement, duration?: number): void;
  slideIn(element: HTMLElement, direction?: string): void;
  morph(element: HTMLElement, from: MorphState, to: MorphState): void;
  peelOff(element: HTMLElement, options?: PeelOptions): void;
}
```

### Composition Root (app.config.ts)

```typescript
import { ApplicationConfig } from '@angular/core';
import { ThemeService } from './adapters/theme/theme.service';
import { ResponsiveService } from './adapters/layout/responsive.service';
import { AnimationService } from './adapters/animation/animation.service';
import { IconService } from './adapters/icons/icon.service';
import { ThemePort } from './domain/ports/ThemePort';
import { LayoutPort } from './domain/ports/LayoutPort';
import { AnimationPort } from './domain/ports/AnimationPort';
import { IconPort } from './domain/ports/IconPort';

export const appConfig: ApplicationConfig = {
  providers: [
    { provide: ThemePort, useClass: ThemeService },
    { provide: LayoutPort, useClass: ResponsiveService },
    { provide: AnimationPort, useClass: AnimationService },
    { provide: IconPort, useClass: IconService },
  ]
};
```

### Rules

1. **Domain has zero Angular imports** — Pure TypeScript interfaces and types only
2. **Adapters implement ports** — Angular services (`@Injectable`) implement domain ports
3. **Components depend on ports** — Inject ports via DI tokens, never concrete adapters
4. **Composition root wires everything** — `app.config.ts` is the only place adapters are bound to ports
5. **Tokens are CSS variables** — Design tokens live in `_tokens.scss`, not in TypeScript constants

---

## Usage

When generating UI code:

1. **Understand the context** - What type of interface are you building? See [ui-lifestyles.md](./ui-lifestyles.md) for guidance.
2. **Select pattern approach** - Choose based on project needs, not prescription.
3. **Run the shape questionnaire** - Answer L2 questions (hybrid mode: infer from context, ask only when ambiguous), apply decision rules, resolve the Shape Spec. See [decision-rules.md](./decision-rules.md).
4. **Apply all tokens** from the [Design Tokens Reference](./tokens.md) — radius, elevation, and motion tokens must match the Shape Spec.
5. **Follow component contracts** from [Component Contracts](./components.md) and the structure template from the Shape Spec.
6. **Implement all interaction states** (hover, focus, active, disabled).
7. **Use animations from the library** - keyframes, utilities, and Angular triggers only from [animations-library.md](./animations-library.md); motion principles from [motion.md](./motion.md).
8. **Ensure accessibility requirements** are met (WCAG AA) from [Accessibility Requirements](./accessibility.md).
9. **Apply usability principles** from [Usability Principles](./usability.md).
10. **Evaluate against the rubric** before finalizing (including Motion Compliance and Consistency).

### Angular-Specific Workflow

When generating Angular components:

1. **Component setup**: Use standalone components with `ChangeDetectionStrategy.OnPush` by default.
2. **Template**: Use semantic HTML with Angular template syntax. Apply design tokens via class bindings.
3. **State**: Use `signal()` for local component state, `computed()` for derived state.
4. **Inputs/Outputs**: Use `input()` and `output()` signal-based APIs (Angular 17+).
5. **Services**: Use `@Injectable({ providedIn: 'root' })` for singletons (ThemeService, AnimationService).
6. **Styles**: Use SCSS with `:host` for component scoping. Access CSS variables via `var()`.
7. **Responsive**: Use `@angular/cdk/layout` BreakpointObserver, not window.matchMedia.
8. **Animations**: Use `@angular/animations` for enter/leave; CSS transitions for hover/focus states. All primitives from [animations-library.md](./animations-library.md); Pattern 4 morphs use `morph()`/`peelOff()`.
9. **Forms**: Use reactive forms with `Validators` for input validation patterns.

Always reference the appropriate sections and apply all rules. Verify output against the Evaluation Rubric before finalizing.

---

## External References

### Design Systems
- <https://www.w3.org/WAI/WCAG21/quickref/> — WCAG 2.1 Quick Reference
- <https://designsystem.energy.gov/> — US Web Design System (USWDS)
- <https://carbondesignsystem.com/> — IBM Carbon Design System
- <https://material.io/design> — Google Material Design
- <https://developer.apple.com/design/human-interface-guidelines/> — Apple Human Interface Guidelines
- <https://www.nngroup.com/articles/ten-usability-heuristics/> — Nielsen Norman Group Usability Heuristics

### CSS & Layout
- <https://css-tricks.com/snippets/css/a-guide-to-flexbox/> — CSS-Tricks Flexbox Guide
- <https://css-tricks.com/snippets/css/complete-guide-grid/> — CSS-Tricks Grid Guide
- <https://web.dev/learn/css/> — Learn CSS (web.dev)
- <https://www.w3.org/TR/css-logical-1/> — CSS Logical Properties and Values Level 1

### Angular
- <https://angular.dev/guide/components> — Angular Components Guide
- <https://angular.dev/guide/signals> — Angular Signals
- <https://angular.dev/guide/animations> — Angular Animations
- <https://material.angular.io/> — Angular Material (reference for component patterns)
- <https://angular.dev/guide/templates/template-syntax> — Angular Template Syntax
- <https://angular.dev/guide/di> — Angular Dependency Injection

### Books
- Dan Mall, *Design Systems* — O'Reilly Media
- Alla Kholmatova, *Design Systems* — Smashing Magazine
