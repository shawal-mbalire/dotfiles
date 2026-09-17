# Usability Principles

The following principles are based on Jakob Nielsen's 10 Usability Heuristics (1994), adapted for design system implementation.

## 1. Visibility of System Status

**The design should always keep users informed about what is going on.**

| Implementation | Pattern |
|----------------|---------|
| Loading indicators | Skeleton screens, spinners, progress bars |
| Success feedback | Toast notifications, inline confirmations |
| Error feedback | Inline errors, error states on components |
| Processing state | Disabled buttons with loading spinner |

## 2. Match Between System and Real World

**Use words, phrases, and concepts familiar to the user.**

| Implementation | Pattern |
|----------------|---------|
| Terminology | Use user language, not technical jargon |
| Icons | Use universally recognized icons |
| Layout | Follow natural reading patterns (F-pattern, Z-pattern) |
| Metaphors | Use real-world metaphors (shopping cart, folder, trash) |

## 3. User Control and Freedom

**Provide clearly marked "emergency exits" for unwanted actions.**

| Implementation | Pattern |
|----------------|---------|
| Undo/Redo | Allow reversing actions |
| Clear exits | Cancel buttons, close icons, escape key |
| Confirmation | Confirm destructive actions |
| Back navigation | Breadcrumbs, back buttons |

## 4. Consistency and Standards

**Follow platform and industry conventions.**

| Implementation | Pattern |
|----------------|---------|
| Internal consistency | Same component behaves same way everywhere |
| External consistency | Follow platform conventions (iOS, Android, Web) |
| Design tokens | Consistent spacing, colors, typography |
| Interaction patterns | Same gestures, same results |

## 5. Error Prevention

**Prevent problems from occurring in the first place.**

| Implementation | Pattern |
|----------------|---------|
| Input constraints | Min/max values, format masks |
| Confirmation dialogs | For destructive actions |
| Defaults | Sensible default values |
| Constraints | Disable invalid options |

## 6. Recognition Rather than Recall

**Make elements, actions, and options visible.**

| Implementation | Pattern |
|----------------|---------|
| Persistent labels | Always visible, not placeholder-only |
| Contextual help | Tooltips, help text near inputs |
| Visible actions | Buttons over hidden keyboard shortcuts |
| History | Recent items, recently viewed |

## 7. Flexibility and Efficiency of Use

**Allow users to tailor frequent actions.**

| Implementation | Pattern |
|----------------|---------|
| Keyboard shortcuts | For power users |
| Customization | Configurable layouts, themes |
| Personalization | Remember user preferences |
| Accelerators | Quick actions, bulk operations |

## 8. Aesthetic and Minimalist Design

**Keep interfaces focused on essentials.**

| Implementation | Pattern |
|----------------|---------|
| Progressive disclosure | Show only what's needed |
| Visual hierarchy | Guide attention with size, color, spacing |
| White space | Use spacing to reduce cognitive load |
| Content priority | Primary actions prominent, secondary hidden |

## 9. Error Recovery

**Help users recognize, diagnose, and recover from errors.**

| Implementation | Pattern |
|----------------|---------|
| Clear error messages | Plain language, no error codes |
| Error suggestions | "Did you mean...?" |
| Recovery paths | Inline correction, undo |
| Error prevention | Validate before submission |

## 10. Help and Documentation

**Provide contextual help when needed.**

| Implementation | Pattern |
|----------------|---------|
| Inline help | Help text near inputs |
| Tooltips | On hover/focus for complex elements |
| Onboarding | Guided tours for new users |
| Documentation | Searchable, task-focused |

## Usability Checklist

- [ ] System status visible (loading, success, error)
- [ ] Language matches user expectations
- [ ] User can undo/redo actions
- [ ] Consistent behavior across components
- [ ] Errors prevented where possible
- [ ] Information is recognizable, not recalled
- [ ] Shortcuts for power users
- [ ] Minimal, focused design
- [ ] Error messages are clear and helpful
- [ ] Help is available when needed
