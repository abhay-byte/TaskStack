# TaskStack — Design Principles

**Document Version:** 1.0  
**Date:** 2026-02-28  
**Framework:** Material Design 3 (M3) — strictly followed

---

## 1. Core Philosophy

TaskStack strictly follows **Material Design 3 (M3)**, Google's most current design system. Every component, spacing rule, colour role, typographic choice, and interaction pattern must originate from M3 specifications. Custom patterns are only introduced where M3 provides no guidance (e.g., the 24-hour timeline widget).

> **Rule:** If an M3 solution exists for a UI problem, use it. Do not invent.

---

## 2. Colour System

### 2.1 Dynamic Color & Seed Color

M3 uses a **seed-based dynamic colour system**. TaskStack uses a hand-crafted colour scheme generated from a primary seed, while also supporting Android 12+ dynamic colour (Material You). The design tokens follow M3's colour role naming exactly.

**Seed colour:** `#5B5FEF` (Indigo)

### 2.2 Colour Roles (Light & Dark)

M3 defines colour roles, not raw hex values. All widgets must reference token names, not raw colours.

| Role | Light | Dark | Usage |
|---|---|---|---|
| `primary` | `#4A4FD9` | `#BEC2FF` | FAB, active nav, filled buttons |
| `onPrimary` | `#FFFFFF` | `#151799` | Text/icons on primary |
| `primaryContainer` | `#E0E0FF` | `#2D31B7` | Tonal buttons, selected chips |
| `onPrimaryContainer` | `#00007B` | `#E0E0FF` | Text on primary container |
| `secondary` | `#5C5D72` | `#C5C4DD` | Navigation active indicator |
| `secondaryContainer` | `#E1E0F9` | `#44455A` | Nav active indicator background |
| `onSecondaryContainer`| `#191A2C` | `#E1E0F9` | Active nav icon + label |
| `tertiary` | `#78536B` | `#E8B9D5` | Accent, tags |
| `surface` | `#FBF8FF` | `#131318` | Page background |
| `surfaceVariant` | `#E3E1EC` | `#46464F` | Input field fills |
| `surfaceContainerLow`| `#F5F2FB` | `#1C1C21` | Elevated card background |
| `surfaceContainer` | `#EFECF4` | `#201F25` | Card default |
| `surfaceContainerHigh`| `#E9E7EF`| `#2A2930` | Filled card |
| `surfaceContainerHighest`|`#E4E1EC`|`#35343B` | Highest elevation surface |
| `outline` | `#767680` | `#90909A` | Input borders, dividers |
| `outlineVariant` | `#C7C5D0` | `#46464F` | Subtle dividers, outlined card border |
| `error` | `#B3261E` | `#F2B8B5` | Validation errors |
| `onSurface` | `#1C1B1F` | `#E6E1E5` | Primary text |
| `onSurfaceVariant` | `#49454F` | `#CAC4D0` | Secondary text |
| `inverseSurface` | `#313033` | `#E6E1E5` | Snackbars |
| `inversePrimary` | `#BEC2FF` | `#4A4FD9` | Snackbar action |

### 2.3 Task Accent Colours (Semantic Palette)

For task card accents, a curated palette of 12 task colours is provided (all pass WCAG AA against their container):

```
#EF4444 Red      #F97316 Orange   #EAB308 Yellow
#22C55E Green    #14B8A6 Teal     #3B82F6 Blue
#8B5CF6 Violet   #EC4899 Pink     #F43F5E Rose
#6366F1 Indigo   #64748B Slate    #78716C Stone
```

---

## 3. Typography

### 3.1 Type Scale (M3 Exact)

TaskStack uses **Outfit** (display/brand) and **Inter** (body/UI), loaded via `google_fonts` package.

| Role | Font | Weight | Size | Line Height | Letter Spacing | Usage |
|---|---|---|---|---|---|---|
| `displayLarge` | Outfit | 400 | 57sp | 64sp | -0.25 | — (not used in v1.0) |
| `displayMedium` | Outfit | 400 | 45sp | 52sp | 0 | — |
| `displaySmall` | Outfit | 400 | 36sp | 44sp | 0 | Onboarding hero text |
| `headlineLarge` | Outfit | 400 | 32sp | 40sp | 0 | Onboarding subheadlines |
| `headlineMedium` | Outfit | 400 | 28sp | 36sp | 0 | Screen titles |
| `headlineSmall` | Outfit | 400 | 24sp | 32sp | 0 | Section titles |
| `titleLarge` | Outfit | 400 | 22sp | 28sp | 0 | AppBar titles |
| `titleMedium` | Inter | 500 | 16sp | 24sp | 0.15 | Task card title, list item title |
| `titleSmall` | Inter | 500 | 14sp | 20sp | 0.1 | Chip labels, sub-section titles |
| `labelLarge` | Inter | 500 | 14sp | 20sp | 0.1 | Button text |
| `labelMedium` | Inter | 500 | 12sp | 16sp | 0.5 | Nav bar labels, small buttons |
| `labelSmall` | Inter | 500 | 11sp | 16sp | 0.5 | Timeline hour markers, badges |
| `bodyLarge` | Inter | 400 | 16sp | 24sp | 0.5 | Descriptions, body text |
| `bodyMedium` | Inter | 400 | 14sp | 20sp | 0.25 | Secondary body, form helper text |
| `bodySmall` | Inter | 400 | 12sp | 16sp | 0.4 | Captions, timestamps |

### 3.2 Typography Rules

- **Do** use the M3 type role that semantically matches the content purpose.
- **Do not** hard-code `fontSize` anywhere. Always use `Theme.of(context).textTheme.bodyMedium` etc.
- **Do not** use `fontWeight: FontWeight.bold` — use the M3 weight for the role.
- **Do** apply `textScaleFactor` awareness — test all screens at 150% font scale.

---

## 4. Spacing & Layout

### 4.1 Base Grid

M3 recommends an **8dp base grid**. All spacing values must be multiples of 4dp (minimum) or 8dp (preferred).

```
4dp   → xs  — icon gaps, badge padding, tight text spacing
8dp   → sm  — list item internal gaps, chip padding, form field gaps
12dp  → —   — used only for specific M3 component specs (nav active indicator padding)
16dp  → md  — standard content padding, card internal padding
24dp  → lg  — section spacing, screen horizontal gutter
28dp  → —   — navigation drawer left/right padding (M3 spec)
32dp  → xl  — large section gaps
48dp  → xxl — hero section spacing (onboarding)
```

### 4.2 Screen Margins (Horizontal Gutter)

| Window size | Margin | Columns | Gutter |
|---|---|---|---|
| Compact (< 600dp) | 16dp | 4 | 8dp |
| Medium (600–840dp) | 24dp | 8 | 16dp |
| Expanded (> 840dp) | 24dp+ | 12 | 24dp |

TaskStack v1.0 targets **compact** window size (mobile phones). All screens use **16dp horizontal content margin**.

### 4.3 Screen Padding Convention

```dart
// Standard screen padding — use this everywhere
const screenPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);

// Section padding (within a scrollable screen)
const sectionPadding = EdgeInsets.only(top: 16.0, bottom: 8.0);
```

### 4.4 Component-Level Spacing (from M3 Specs)

#### Cards
| Property | Value |
|---|---|
| Corner radius | 12dp |
| Internal padding (left/right) | 16dp |
| Spacing between adjacent cards | 8dp |

#### Navigation Bar (Bottom)
| Property | Value |
|---|---|
| Height | 80dp |
| Icon size | 24dp |
| Active indicator height | 32dp |
| Active indicator width | 64dp |
| Active indicator corner radius | 16dp |
| Label — icon spacing | 4dp |
| Bottom padding (without insets) | 16dp |

#### Navigation Drawer
| Property | Value |
|---|---|
| Container width | 360dp |
| Left/right padding | 28dp |
| Active indicator height | 56dp |
| Active indicator corner radius | 28dp |
| Active indicator width | 336dp |

#### Top App Bar
| Property | Value |
|---|---|
| Height (small) | 64dp |
| Height (medium) | 112dp |
| Height (large) | 152dp |
| Leading icon padding-start | 4dp |
| Title padding-start (small) | 16dp |

#### FAB
| Property | Value |
|---|---|
| Size (regular) | 56dp × 56dp |
| Size (small) | 40dp × 40dp |
| Size (large) | 96dp × 96dp |
| Corner radius (regular) | 16dp |
| Icon size | 24dp |
| Margin from screen edge | 16dp |
| Margin from bottom nav | 16dp |

#### Buttons
| Type | Height | Corner radius | Padding (H) |
|---|---|---|---|
| FilledButton | 40dp | 20dp (full) | 24dp |
| FilledTonal | 40dp | 20dp (full) | 24dp |
| OutlinedButton | 40dp | 20dp (full) | 24dp |
| TextButton | 40dp | 20dp (full) | 12dp |
| ElevatedButton | 40dp | 20dp (full) | 24dp |

#### Chips
| Type | Height | Corner radius | Gap (icon/label) |
|---|---|---|---|
| Assist | 32dp | 8dp | 8dp |
| Filter | 32dp | 8dp | 8dp |
| Input | 32dp | 8dp | 8dp |
| Suggestion | 32dp | 8dp | 8dp |

#### Text Fields (Outlined)
| Property | Value |
|---|---|
| Height (single line) | 56dp |
| Corner radius | 4dp (top) |
| Border width (inactive) | 1dp |
| Border width (focused) | 2dp |
| Leading icon padding | 12dp |
| Internal horizontal padding | 16dp |
| Label text top padding | 8dp |

#### List Tiles
| Property | Value |
|---|---|
| Min height (1-line) | 56dp |
| Min height (2-line) | 72dp |
| Min height (3-line) | 88dp |
| Leading element left padding | 16dp |
| Content right padding | 24dp |
| Content left padding (after leading) | 16dp |
| Divider inset | 16dp |

#### Dialogs
| Property | Value |
|---|---|
| Corner radius | 28dp |
| Horizontal padding | 24dp |
| Vertical padding (top) | 24dp |
| Button row top padding | 24dp |
| Max width | 560dp |
| Min width | 280dp |

#### Bottom Sheets
| Property | Value |
|---|---|
| Corner radius (top) | 28dp |
| Drag handle width | 32dp |
| Drag handle height | 4dp |
| Drag handle top margin | 22dp |
| Content horizontal padding | 16dp |

#### Snackbars
| Property | Value |
|---|---|
| Corner radius | 4dp |
| Horizontal padding | 16dp |
| Vertical padding | 14dp |
| Margin from screen edge | 16dp |
| Margin from bottom nav | 8dp |

---

## 5. Shape (Corner Radius) Scale

M3 defines a shape scale with named tokens:

| Token | Value | Usage |
|---|---|---|
| `extraSmall` | 4dp | Text fields, snackbars, menus |
| `small` | 8dp | Chips, small cards |
| `medium` | 12dp | Cards (default), FAB (small) |
| `large` | 16dp | FAB (regular), navigation items active indicator |
| `extraLarge` | 28dp | Navigation drawer active indicator, dialogs (partial), bottom sheets (top corners) |
| `full` | 999dp (circle) | Buttons, avatar, badges |

---

## 6. Elevation & Tonal Elevation

M3 uses **tonal elevation** (surface + primary tint) instead of shadow-only elevation. Elevation levels:

| Level | dp | Usage |
|---|---|---|
| Level 0 | 0dp | Flat surface, text fields |
| Level 1 | 1dp | Elevated card, navigation bar |
| Level 2 | 3dp | Top app bar (scrolled), FAB resting |
| Level 3 | 6dp | FAB hover, bottom sheet |
| Level 4 | 8dp | Navigation drawer, modal sheets |
| Level 5 | 12dp | Dialog |

**Rule:** Use `surfaceContainerLow` for Level 1, `surfaceContainer` for Level 2, etc. Do not rely on drop shadows alone.

---

## 7. Iconography

### 7.1 Icon Library
- Primary library: **Material Symbols** (outlined style by default, filled when active/selected)
- `icon_size`: 24dp standard, 20dp in dense contexts, 48dp for hero icons
- Use the **outlined** variant for unselected states and **filled** variant for selected/active states (e.g., nav bar)

### 7.2 Task Icons
- TaskStack ships a curated set of 200+ task icons sourced from Material Symbols, organised into categories:
  - Health & Fitness, Work & Productivity, Learning, Food & Cooking, Social, Finance, Home, Travel, Hobbies, Wellbeing

### 7.3 Icon Rules
- Always provide `semanticLabel` on every `Icon` widget for accessibility.
- Do not use icons smaller than 16dp in any context.
- Icons on coloured surfaces use the corresponding `on{Surface}` colour role.

---

## 8. Motion & Animation

M3 defines an **Easing and Duration** system. All animations must use M3 easing curves.

### 8.1 Easing Tokens

| Token | Curve | Usage |
|---|---|---|
| `emphasized` | `cubic-bezier(0.2, 0, 0, 1)` | Most transitions — enter onto screen |
| `emphasizedDecelerate` | `cubic-bezier(0.05, 0.7, 0.1, 1.0)` | Enter transitions |
| `emphasizedAccelerate` | `cubic-bezier(0.3, 0.0, 0.8, 0.15)` | Exit/leave transitions |
| `standard` | `cubic-bezier(0.2, 0, 0, 1)` | Simple element animations |
| `standardDecelerate` | `cubic-bezier(0, 0, 0, 1)` | Small helpers entering |
| `standardAccelerate` | `cubic-bezier(0.3, 0, 1, 1)` | Small helpers leaving |

### 8.2 Duration Tokens

| Token | Duration | Usage |
|---|---|---|
| `short1` | 50ms | Micro fade |
| `short2` | 100ms | Rapid transitions |
| `short3` | 150ms | Icon change, selection state |
| `short4` | 200ms | Chip add/remove, small expands |
| `medium1` | 250ms | FAB expand, card hover |
| `medium2` | 300ms | Screen-level enter |
| `medium3` | 350ms | Page/tab slide |
| `medium4` | 400ms | Modal sheet open, task completion |
| `long1` | 450ms | Large surface transform |
| `long2` | 500ms | Container expand |

### 8.3 TaskStack-Specific Animations

| Animation | Duration | Easing |
|---|---|---|
| Screen enter (forward) | 300ms | `emphasizedDecelerate` |
| Screen exit (forward) | 200ms | `emphasizedAccelerate` |
| Modal sheet open | 400ms | `emphasizedDecelerate` |
| Modal sheet close | 300ms | `emphasizedAccelerate` |
| Task card appear (new task added) | 250ms | `emphasized` |
| Task completion: checkmark draw | 200ms | `standardDecelerate` |
| Task completion: card fade/slide | 300ms | `emphasized` |
| FAB expand | 250ms | `emphasized` |
| Tab switch | 200ms | `standard` |
| Timeline scroll-to-now (launch) | 500ms | `emphasizedDecelerate` |
| Current time indicator update | 800ms | `standard` (linear) |

---

## 9. States (M3 State Layer)

M3 defines **state layers** — semi-transparent overlays on top of components to communicate interaction:

| State | Opacity (on Primary) | Opacity (on Surface) |
|---|---|---|
| Hover | 8% | 8% |
| Focus | 12% | 12% |
| Pressed | 12% | 12% |
| Dragged | 16% | 16% |
| Disabled | 38% (content), 12% (container) | 38% / 12% |

In Flutter, M3 state layers are applied automatically via `InkWell`, `MaterialState`, and `ButtonStyle`. Never override these without strong justification.

---

## 10. Accessibility

M3 compliance requires:

| Requirement | Specification |
|---|---|
| Minimum touch target | 48dp × 48dp |
| Text contrast ratio (normal) | ≥ 4.5:1 (WCAG AA) |
| Text contrast ratio (large text ≥ 18sp) | ≥ 3:1 |
| Icon contrast (on interactive element) | ≥ 3:1 |
| Semantic labels | All icons, images, and interactive widgets |
| Focus traversal | Logical order, all interactive elements focusable |
| Screen reader | All custom widgets must provide `Semantics` |
| Text scaling | All layouts tested at 100%, 130%, 150% font scale |

---

## 11. Adaptive & Responsive Design

TaskStack v1.0 targets compact phones. However, layouts are built responsively:

| Breakpoint | Width | Adaptation |
|---|---|---|
| Compact | < 600dp | Single column, bottom nav, 16dp margins |
| Medium | 600–840dp | Two-column possible, nav rail |
| Expanded | > 840dp | Two-pane, nav drawer |

Use `LayoutBuilder` or `MediaQuery.sizeOf(context)` to adapt layouts. Never hard-code breakpoints as raw numbers — use constants.

---

## 12. Dark Mode

TaskStack follows M3's dark theme exactly:

- All colour roles swap to their dark variants (as defined in the colour table above).
- Tonal elevation still applies in dark — darker surface, lighter tint overlay.
- **Do not** simply invert light colours — always use the M3-defined dark tokens.
- Images and media stay unchanged; only UI chrome adapts.
- `ThemeMode.system` is the default — respect the OS preference.

---

## 13. Component Usage Quick Reference

| Component | M3 Widget | Notes |
|---|---|---|
| Primary action button | `FilledButton` | Main CTAs |
| Secondary action | `FilledButton.tonal` | Secondary actions |
| Destructive action | `TextButton` (error colour) | Delete, discard |
| Navigation (mobile) | `NavigationBar` | 3 items max in v1.0 |
| Page scaffold | `Scaffold` | Always with `AppBar` |
| Top app bar | `AppBar` (M3 by default) | Small bar for most screens |
| Text input | `TextField` with `OutlinedInputBorder` | Standard form fields |
| Search input | `SearchBar` (M3) | Search feature (v1.5) |
| Tags/categories | `FilterChip` (multi-select) or `InputChip` | Task tags |
| Alerts/dialogs | `AlertDialog` | Confirmation, delete |
| Bottom action sheet | `ModalBottomSheet` | Context menus, pickers |
| Time picker | `showTimePicker()` | Native M3 time picker |
| Date picker | `showDatePicker()` | Calendar navigation |
| Settings row | `SwitchListTile`, `ListTile` | Settings screen |
| Progress bar | `LinearProgressIndicator` | Loading states |
| Loading spinner | `CircularProgressIndicator` | Async operations |
| Snack bar feedback | `ScaffoldMessenger.showSnackBar` | Undo, confirmations |
| Dividers | `Divider` (full-width), `Divider(indent:)` | List sections |

---

## 14. What We Do NOT Do

- ❌ Do not use `Colors.blue`, `Colors.red` etc. — use role tokens
- ❌ Do not hard-code `FontSize` — use TextTheme roles
- ❌ Do not use `Padding(padding: EdgeInsets.all(13))` — use the spacing scale (4dp grid)
- ❌ Do not create custom buttons — use M3 button variants
- ❌ Do not animate outside M3 duration/easing tokens without justification
- ❌ Do not use `showDialog` with custom shape — use `AlertDialog`
- ❌ Do not suppress ripple/state layers on interactive elements
- ❌ Do not ignore `Semantics` on custom widgets

---

## 15. References

- [Material Design 3 — material.io/design](https://m3.material.io)
- [M3 Color System](https://m3.material.io/styles/color/the-color-system)
- [M3 Typography](https://m3.material.io/styles/typography/overview)
- [M3 Elevation](https://m3.material.io/styles/elevation/overview)
- [M3 Motion](https://m3.material.io/styles/motion/easing-and-duration/tokens-specs)
- [M3 Shape](https://m3.material.io/styles/shape/shape-scale-tokens)
- [M3 Components](https://m3.material.io/components)
- [flutter/material library](https://api.flutter.dev/flutter/material/material-library.html)

---

*Last updated: 2026-02-28*
