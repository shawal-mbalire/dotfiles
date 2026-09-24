# Reaction Design

How the system should respond to user actions — beyond *whether* feedback exists (Action Acknowledgement, [SKILL.md](./SKILL.md) Principle 18) and *which channel* carries it (visual/AT contract vs the separate [haptics.md](./haptics.md) channel). This file governs **timing, weight, structure, and predictability** of reactions. Framework-agnostic: applies to Angular, React, and Flutter targets.

## 1. Response-Time Budgets (Nielsen)

| Budget | Threshold | Applies to | If exceeded |
|--------|-----------|------------|-------------|
| Dispatch ack | ≤ 100ms | Press → visual reaction (floor = Principle 18) | Feels dead/unresponsive |
| Settled result | ≤ 1s | Simple async (search, toggle save, navigation) | Show pending at 100ms; progress treatment by 1s |
| Extended operation | ≤ 10s | Long async (reports, uploads, exports) | Determinate progress + cancel/escape by 1s; at 10s explain what is happening |
| Timeout | Explicit, always | Any operation | Never hang — settle as error and enter the Retry Contract |

Rules:

- The 100ms dispatch ack is the floor; this table governs what happens **after** the ack.
- If an operation can exceed 1s, apply "extended" treatment (progress + cancel) **before** the wait, not after.
- Every wait path terminates: `success | error | timeout` — all three are settled outcomes with full feedback (no fourth silent state).

## 2. Perceived Performance

Optimize felt speed without faking completion:

| Technique | Use | Anti-pattern |
|-----------|-----|--------------|
| Optimistic UI | Reversible, low-risk mutations (like, draft save, local reorder) | Optimistic for irreversible or money actions |
| Skeleton / early content | Known-shape content loads | Blank void, then pop-in |
| Early hints | Start fetch on hover/focus of the primary action | Blocking first interaction on cold start |
| Staged reveal | Shell first, secondary data second | Blocking the whole UI on the slowest request |
| Instant local echo | Typing, drag preview | Waiting on the server to echo input |

Rollback on optimism failure must surface a visible error (Retry Contract rule 6) — perceived speed never replaces honest outcomes.

## 3. Reaction Weight = Action Weight

Match the magnitude of the reaction to the significance of the action. Wrong weight reads as broken (too quiet) or nagging (too loud).

| Action class | Example | Reaction weight |
|--------------|---------|-----------------|
| Trivial, reversible, in-context | Checkbox, like, tab switch | Micro: state change only; no toast |
| Background success | Settings persist, draft save | Inline confirm or quiet polite toast; no focus steal |
| Foreground result | Form submit, search complete | Result rendered where the user is already looking |
| Destructive / irreversible | Delete, purchase, permission grant | Explicit confirm **or** undo window (see §7); assertive AT on failure |
| Failure that blocks progress | Validation, payment error | Persistent inline error or non-auto-dismiss `role="alert"` toast |

Rules:

- Never use a modal for feedback the user did not need to be interrupted for.
- Never use only a transient toast for a failure that blocks the next step.
- Haptics (if enabled) follow [haptics.md](./haptics.md) independently; weight rules govern the visual/AT channels.

## 4. Microinteraction Anatomy (Saffer)

Every reaction is a microinteraction with four parts — missing anatomy = missing reaction:

```
trigger → rules → feedback → loop / mode (if needed)
```

| Part | Question | Example (retry button) |
|------|----------|------------------------|
| Trigger | What starts it? | Click / Enter / tap |
| Rules | What happens, in what order? | ack → double-submit guard → request → settle |
| Feedback | What does the user perceive? | Press state, spinner, attempt count, result surface |
| Loop / mode | Does it repeat or change future behavior? | `attempt++`, backoff countdown; success exits the loop |

Checklist: name all four parts for each new interactive behavior before shipping.

- Toggles have **mode** (on/off persists).
- Retries have **loop** (attempt count, backoff).
- Hovers typically have **no loop** (state reverts on leave).
- Continuous controls (sliders) have a **continuous feedback** part — see §9.

## 5. Non-Interruption Budget

Feedback must not interrupt harder than the action requires:

| Level | Mechanism | When allowed |
|-------|-----------|--------------|
| Passive | Inline text / border / icon change | **Default** for all feedback adjacent to the control |
| Polite | Toast (`role="status"`, `aria-live="polite"`) | Background outcomes away from the trigger; never steals focus |
| Assertive | `role="alert"` / assertive live region / dialog | Only when the user cannot proceed until they know |
| Blocking | Modal dialog | Only destructive confirmation or unrecoverable states — **never for success** |

Rules:

- Escalate one level at a time; never jump passive → blocking.
- Success never blocks; failure blocks only when the next step is impossible without it.
- Auto-dismiss only for polite non-error toasts (existing toast rules in [components.md](./components.md)).

## 6. Affordance & Predictability

- The reaction must be predictable from the control's signifier: a button looks pressable → press state + result; a link looks navigational → route change.
- A surprising reaction (click label → delete) violates this even when the feedback is loud.
- If an outcome cannot be predicted from the control, add a **signifier** (tooltip, helper text, icon) — do not compensate with a louder reaction.

## 7. Reversibility over Confirmation

- Prefer **undo** (react after the fact) over **confirm dialogs** (block before).
- Offer undo for: deletes, moves, bulk edits, delayed sends.
- Reserve confirmation for: irreversible + high-cost (payment, permanent delete with no trash, security changes).
- The undo affordance obeys reaction rules itself: visible countdown, keyboard-reachable; a silent or invisible undo window violates §1 and §5.

## 8. Idempotency & Debounce

Repeated or duplicate input produces **one** expensive reaction:

- **Double-submit guard** for async commits (Retry Contract) — already required.
- **Toggle spam**: state machine debounces rapid flips; suppress intermediate flicker.
- **Search-as-you-type**: debounce ~200–300ms; each keystroke is not a separate visible reaction.
- **In-flight duplicates**: cancel or coalesce (`AbortController`, RxJS `switchMap`, framework equivalent).

The **dispatch ack still fires per press** (Principle 18); what is deduplicated is the outcome/work reaction, not the acknowledgement.

## 9. Direct Manipulation Continuity

| Control class | Reaction mode |
|---------------|---------------|
| Discrete (button, checkbox, tab) | Commit ack only: dispatch + settle |
| Continuous (slider, drag, resize) | Continuous visual reaction during the gesture (follows input, no perceptible lag); settle reaction once on release |
| Continuous + network (drag-to-sort) | Local echo first; server confirm silent or quiet; failure rolls back visibly |

- Never gate continuous visual response on a network round-trip.
- Keyboard equivalents (arrow keys on a slider) get the same continuous reaction as pointer input.

## 10. Cross-Channel Congruence

Channels are **separate** (Principle 18 / [haptics.md](./haptics.md)) but must tell the **same story** when both fire:

- A success haptic never accompanies a visual error state (and vice versa).
- `aria-live` text matches the visible text.
- Turning haptics off leaves the visual/AT story intact.
- Reduced motion leaves state changes visible — no feedback that exists **only** in animation.

## 11. Same Action → Same Reaction

- Identical actions produce identical reactions across the product (Consistent Interaction Patterns; rubric check).
- When context forces variation (offline, degraded mode), the **skeleton stays identical**: `ack → pending → settled`; only content differs.
- Different controls must not compete for the same trigger with different reactions (two "Save" buttons, two outcomes).

## Rubric Mapping

Covered by Evaluation Rubric **#17 Reaction Design** in [SKILL.md](./SKILL.md). Lint/checklist hooks live in [lint-rules.md](./lint-rules.md) (review-level; timing/weight are judgment rules, not automatable).
