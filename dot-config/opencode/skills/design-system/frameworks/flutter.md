# Flutter Readiness

Flutter is a first-class target for this design system. Domain rules (tokens, Shape Spec, decision rules) are framework-agnostic; adapters map ports to Flutter widgets.

## Framework Detection

| Signals in project | Target |
|--------------------|--------|
| `angular.json` | Angular |
| `pubspec.yaml` | Flutter |
| Both or neither | Ask the user once; do not guess |

When ambiguous, ask: "Should I generate Angular or Flutter code for this?"

## Token Mapping

CSS custom properties map to a single `AppTokens` class (or `ThemeExtension`) with light/dark overrides.

```dart
// lib/design/tokens.dart
class AppColors {
  static const bgPrimary = Color(0xFFffffff);
  static const surfacePrimary = Color(0xFFf8f9fa);
  static const accentPrimary = Color(0xFF0d6efd);
  static const shadowHover = Color(0x14000000); // pair with BoxShadow
}

class AppRadii {
  static const sm = 3.0;
  static const md = 5.0;
  static const lg = 8.0;
  static const xl = 12.0;
  static const full = 9999.0;
  // Pattern 4 dual radius
  static const radiusOuterLg = 12.0;
  static const radiusInnerLg = 12.0;
}

class AppDurations {
  static const fast = Duration(milliseconds: 100);
  static const normal = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 300);
  static const morph = Duration(milliseconds: 350);
  static const spinner = Duration(milliseconds: 1000);
  static const loading = Duration(milliseconds: 1500);
}
```

Prefer `ThemeExtension` + `ThemeData.extensions` for light/dark switching (equivalent of CSS variables).

## Architecture (Ports & Adapters)

Same hexagonal layout as Angular:

```
lib/
├── domain/           # pure Dart — ShapeSpec, AnimationPort, ThemePort
├── adapters/         # Flutter implementations
├── widgets/          # design-system widgets
└── main.dart
```

- Domain: zero Flutter imports.
- Adapters: `FlutterThemeAdapter implements ThemePort`, etc.
- Widgets inject ports (constructor or `Provider`/`Riverpod`), never concrete adapters when testing.

## Widget Contracts

| Web | Flutter |
|-----|---------|
| Card | `Card` / custom `Surface` with dual `BorderRadius` |
| Button | `ElevatedButton` / `InkWell` + tokens |
| Modal | `showDialog` / custom with focus trap |
| Drawer | `Drawer` (edge via `Directionality`, not hard-coded right) |
| Toast | `OverlayEntry` + `AnimatedSlide` |
| Tabs | `TabBar` / `TabBarView` |
| Tooltip | `Tooltip` |
| Table | `DataTable` / `GridView.builder` |
| Badge | `Chip` / custom |
| Spinner | `CircularProgressIndicator` with token stroke |

## Motion Mapping

| Library primitive | Flutter |
|-------------------|---------|
| CSS transition | `AnimatedContainer` / `AnimatedDecoratedBox` with token durations |
| `fadeIn`/`fadeOut` | `AnimatedOpacity` / `FadeTransition` |
| `slideIn` | `SlideTransition` with `Directionality` (no hard-coded left/right) |
| `spin` / `shimmer` / `dotPulse` | `AnimationController` + `CustomPainter` or package equivalents |
| `morph` (dual radius) | `AnimatedBuilder` interpolating outer/inner `BorderRadius` |
| `peelOff` | `AnimatedBuilder`: lift (offset + scale) + fade + radius contract |

Use `MediaQuery.disableAnimationsOf(context)` (or `TickerMode`) for reduced-motion — equivalent of `prefers-reduced-motion`.

## Focus Traps

- Modal/Drawer/Menu: `FocusScope` with `canRequestFocus`, or `FocusTraversalGroup`.
- Restore focus to the trigger on close (`FocusNode` saved before open).
- Tabs: roving focus via `Focus` + arrow-key handlers (same as CDK pattern).

## RTL

- Use `Directionality.of(context)` and logical alignment (`AlignmentDirectional`, `EdgeInsetsDirectional`).
- Never hard-code `left`/`right` geometry for layout edges.

## Icons

- Use `lucide_flutter` (same icon set as web Lucide).
- No emoji in widgets or `Semantics` labels.

## Responsive

- Breakpoints mirror `--bp-*`: 576 / 768 / 992 / 1200 / 1400.
- `LayoutBuilder` + breakpoint helpers (equivalent of CDK BreakpointObserver).

## Loading States

- Skeleton: `Shimmer` package or custom gradient animation with `AppDurations.loading`.
- Progress: `LinearProgressIndicator` / `CircularProgressIndicator` with token colors.
- Pattern and a11y rules from [loading.md](../loading.md) apply unchanged.

## Verification Checklist (Flutter)

- [ ] All colors/radii/durations come from tokens (no magic numbers in widget trees)
- [ ] Light/dark via `ThemeExtension`, not scattered `if (dark)` in widgets
- [ ] Pattern 4: outer + inner radius pair animated together
- [ ] Reduced motion respected
- [ ] Focus trapped in overlays; focus restored on close
- [ ] Logical geometry only (`EdgeInsetsDirectional`, `AlignmentDirectional`)
- [ ] Lucide icons only; no emoji
- [ ] Shape Spec matches decision-rules output
