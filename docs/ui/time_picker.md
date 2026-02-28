# Material 3 Time Picker Implementation

This document outlines the styling and technical details for the custom Material 3 Time Picker implemented in TaskStack.

## Overview
Flutter's default `showTimePicker` dialog can often fall back to legacy Material 2 color schemes or clash with custom Google Fonts typography overlays (especially in Dark Mode where text can unexpectedly default to black).

To ensure a pixel-perfect, accessible, and legible experience that dynamically adapts to both Dark and Light system aesthetics, we have explicitly mapped the Time Picker to the **Material 3 specs** using `TimePickerThemeData`.

## Architecture & Styling (`app_theme.dart`)

The theme is configured globally in `lib/core/theme/app_theme.dart`. We utilize `WidgetStateColor.resolveWith` to dynamically swap colors during "Selected" vs "Unselected" states.

### 1. Dial & Background Colors
- **Dialog Background:** `colorScheme.surfaceContainerHigh`
- **Dial Background (Unselected):** `colorScheme.surfaceContainerHighest`
- **Dial Selector (Hand & Dot):** `colorScheme.primary`
- **Dial Text (Unselected):** `colorScheme.onSurface`
- **Dial Text (Selected):** `colorScheme.onPrimary`

### 2. Time Input Block Colors (Hour / Minute)
- **Background (Unselected):** `colorScheme.surfaceContainerHighest`
- **Background (Selected):** `colorScheme.primaryContainer`
- **Text (Unselected):** `colorScheme.onSurface`
- **Text (Selected):** `colorScheme.onPrimaryContainer`

### 3. AM/PM Day Period Selector
- **Background (Selected):** `colorScheme.tertiaryContainer`
- **Background (Unselected):** `Colors.transparent`
- **Text (Selected):** `colorScheme.onTertiaryContainer`
- **Text (Unselected):** `colorScheme.onSurfaceVariant`

### 4. Layout & Shape
We strictly enforce a rounded rectangle border of `28pt` radius to perfectly match Material 3 specifications for Dialog shapes:
```dart
shape: const RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(28)),
)
```

## Benefits of Theming at the App Level
By lifting the `TimePickerThemeData` into the root `ThemeData`, any invocation of `showTimePicker()` across the TaskStack app will instantly and automatically render with these correct proportions, states, and text contrasts without requiring individual overrides on every call site.
