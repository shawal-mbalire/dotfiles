---
name: design-system
description: Generate HTML and CSS based on UI/UX Design Patterns with strict token adherence, accessibility compliance, and theme adaptability. Use when building UI components, implementing design systems, creating responsive layouts, or applying consistent visual patterns across web interfaces.
---

# Design System Skill

This skill provides guidelines for generating HTML and CSS based on UI/UX Design Patterns. When generating code, output MUST be evaluated against the technical criteria below.

## Reference Files

`SKILL.md` is the map. Open a file below only when you need its depth.

| Topic | File |
|-------|------|
| Color, typography, spacing, elevation, motion, z-index, breakpoint tokens | [tokens.md](./tokens.md) |
| Card, button, list item, navigation, input, link component contracts | [components.md](./components.md) |
| Multi-theme, numbered list, flat theme pattern specifications | [patterns.md](./patterns.md) |
| WCAG AA requirements, ARIA roles, contrast, keyboard navigation | [accessibility.md](./accessibility.md) |
| Nielsen Norman heuristics for design system implementation | [usability.md](./usability.md) |
| Desktop-first strategy, container queries, fluid typography | [responsive.md](./responsive.md) |
| Theme switching, CSS variables, palette examples, JavaScript implementation | [themes.md](./themes.md) |
| Transition principles, timing functions, animation patterns, reduced motion | [motion.md](./motion.md) |
| Box model, specificity, OOCSS naming, file organization, utilities | [architecture.md](./architecture.md) |
| Skeleton screens, progress indicators, error states, recovery paths | [loading.md](./loading.md) |
| RTL support, text expansion, bidirectional text, locale formatting | [i18n.md](./i18n.md) |
| UI lifestyle categories, navigation patterns, content hierarchy | [ui-lifestyles.md](./ui-lifestyles.md) |

## Evaluation Rubric

When generating HTML, CSS, or component code based on these guidelines, evaluate output against:

1. **Token Accuracy**: Are specific CSS values (e.g., exact border-radius, border-widths, spacing scales) strictly applied without deviation?
2. **Structural Fidelity**: Does HTML markup follow required nested structure (e.g., semantic tags, flexbox containers, distinct span wrappers)?
3. **Interaction Completeness**: Are all defined :hover, :active, and :focus states fully implemented with appropriate CSS transitions?
4. **Theme Adaptability**: Are all color values handled via CSS variables (e.g., var(--bg-color)) rather than hardcoded hex/RGB values?
5. **Accessibility Compliance**: Does output meet WCAG AA requirements (contrast, keyboard, ARIA)?
6. **Usability Compliance**: Does output follow Nielsen Norman usability heuristics?
7. **Visual Hierarchy**: Does output establish clear reading order through typography scale, color opacity, and spacing rhythm?

## Core Principles

1. **Minimal DOM Complexity**: Generated HTML must be as flat as possible. Avoid unnecessary wrapper `<div>` elements ("divitis"). Leverage CSS layouts over wrappers, use semantic tags first, apply styles directly, and use pseudo-elements for decorative additions.

2. **CSS Variables for All Colors**: NEVER hardcode color values in component CSS. All backgrounds, text, and border colors must map to CSS variable tokens defined in the root theme stylesheet.

3. **Accessibility by Default**: Every component must be accessible: visible focus indicators, WCAG AA contrast (4.5:1 for text, 3:1 for UI), alt text for images, keyboard navigation, and ARIA roles where semantic HTML is insufficient.

4. **Progressive Enhancement**: Build from baseline up to enhanced experiences: base styles work without JavaScript, enhanced interactions layer on top, use `@supports` for feature detection, and provide fallbacks for advanced CSS features.

5. **Separation of Concerns**: Maintain clear separation: HTML for structure and semantics only, CSS for presentation and visual behavior, JavaScript for interactivity and state management.

6. **Consistent Token Usage**: Use design tokens consistently across all components. Never introduce ad-hoc values. Tokens ensure visual consistency and maintainability.

7. **Interaction Completeness**: Every interactive element must have hover, focus, active, and disabled states. Transitions should be purposeful and respect user motion preferences.

8. **Responsive by Design**: All components must work across breakpoints. Use fluid typography, flexible layouts, and container queries where appropriate.

9. **Theme Agnostic**: Components should work in any theme without modification. Use CSS variables for all theme-dependent values.

10. **Performance Conscious**: Minimize reflows, use transform/opacity for animations, leverage CSS containment, and avoid expensive layout calculations.

11. **Visual Hierarchy**: Establish clear reading order and importance through:
    - **Typography Scale**: Font size, weight, and line height create hierarchy
    - **Color Opacity**: Text opacity (100% primary, 70% secondary, 50% tertiary, 30% disabled)
    - **Spacing Rhythm**: Consistent padding/margins create visual relationships
    - **Component Hierarchy**: Titles > Subtitles > Body > Captions

12. **Opacity-Based Hierarchy**: Use opacity changes for:
    - **Text Levels**: Primary (100%), Secondary (70%), Tertiary (50%), Disabled (30%)
    - **Interaction States**: Default (100%), Hover (90%), Active (80%), Disabled (50%)
    - **Visual Layering**: Background opacity indicates depth and importance

13. **Internationalization Ready**: Use logical properties for RTL support, ensure text expansion accommodation, and respect bidirectional text requirements.

14. **Error Prevention**: Validate inputs, provide clear error messages, and offer recovery paths. Never let users reach error states without guidance.

15. **Progressive Disclosure**: Show only what's needed when it's needed. Reduce cognitive load through appropriate information architecture.

16. **Consistent Interaction Patterns**: Similar components should behave similarly. Users should be able to predict interactions based on prior experience.

15. **Documentation as Code**: Design decisions should be documented through token names, component contracts, and pattern specifications.

---

## Design Patterns

Patterns provide visual approaches for structuring UI. The choice between patterns is user discretion based on project needs, brand identity, and design goals. All patterns address core design concerns: accessibility, responsiveness, theme adaptability, and interaction completeness.

### Pattern Selection Guidance

Consider the following when choosing a pattern:

- **Pattern 1 (Multi-Theme Containers & Controls)**: Best for applications requiring multiple color themes, consistent geometric aesthetic, and clear visual hierarchy through borders and shadows.

- **Pattern 2 (Interactive Numbered List)**: Best for minimalist, typography-focused interfaces where clean rows and hover interactions take precedence over heavy containers.

- **Pattern 3 (Minimalist Flat Theme)**: Best for modern, clean interfaces with restricted color palettes, subtle depth through shadows, and emphasis on content over chrome.

**Important**: These patterns are not mutually exclusive. Elements from different patterns can be combined within an application as long as the visual language remains consistent.

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

## Usage

When generating UI code:

1. **Understand the context** - What type of interface are you building? See [ui-lifestyles.md](./ui-lifestyles.md) for guidance.
2. **Select pattern approach** - Choose based on project needs, not prescription.
3. **Apply all tokens** from the [Design Tokens Reference](./tokens.md).
4. **Follow component contracts** from [Component Contracts](./components.md).
5. **Implement all interaction states** (hover, focus, active, disabled).
6. **Use exact transition properties** as specified in [Motion Design](./motion.md).
7. **Ensure accessibility requirements** are met (WCAG AA) from [Accessibility Requirements](./accessibility.md).
8. **Apply usability principles** from [Usability Principles](./usability.md).
9. **Evaluate against the rubric** before finalizing.

Always reference the appropriate sections and apply all rules. Verify output against the Evaluation Rubric before finalizing.

---

## External References

- <https://www.w3.org/WAI/WCAG21/quickref/> — WCAG 2.1 Quick Reference
- <https://designsystem.energy.gov/> — US Web Design System (USWDS)
- <https://carbondesignsystem.com/> — IBM Carbon Design System
- <https://material.io/design> — Google Material Design
- <https://developer.apple.com/design/human-interface-guidelines/> — Apple Human Interface Guidelines
- <https://www.nngroup.com/articles/ten-usability-heuristics/> — Nielsen Norman Group Usability Heuristics
- <https://css-tricks.com/snippets/css/a-guide-to-flexbox/> — CSS-Tricks Flexbox Guide
- <https://css-tricks.com/snippets/css/complete-guide-grid/> — CSS-Tricks Grid Guide
- <https://web.dev/learn/css/> — Learn CSS (web.dev)
- <https://www.w3.org/TR/css-logical-1/> — CSS Logical Properties and Values Level 1
- Dan Mall, *Design Systems* — O'Reilly Media
- Alla Kholmatova, *Design Systems* — Smashing Magazine
