import 'package:flutter/material.dart';

/// TaskStack brand colour constants.
/// All UI should reference M3 [ColorScheme] roles via [Theme.of(context)],
/// not these raw values — except [seedColor] and [taskAccentColors].
class AppColors {
  AppColors._();

  /// M3 seed colour — Indigo brand colour.
  static const seedColor = Color(0xFF5B5FEF);

  /// 12-colour curated task accent palette.
  /// All colours pass WCAG AA against their containers.
  static const taskAccentColors = <Color>[
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFFEAB308), // Yellow
    Color(0xFF22C55E), // Green
    Color(0xFF14B8A6), // Teal
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFFF43F5E), // Rose
    Color(0xFF6366F1), // Indigo
    Color(0xFF64748B), // Slate
    Color(0xFF78716C), // Stone
  ];
}
