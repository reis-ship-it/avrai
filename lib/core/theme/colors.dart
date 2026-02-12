import 'package:flutter/material.dart';

/// Centralized minimalist palette: black/grey/white with a single electric green accent.
/// Keep names stable to reduce churn elsewhere in the codebase.
class AppColors {
  // Accent (singular brand color)
  static const Color electricGreen = Color(0xFF00FF66); // primary brand accent
  static const Color electricBlue = Color(0xFF00D4FF); // secondary brand accent
  static const Color transparent = Colors.transparent;

  // Core neutrals
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // Greyscale ramp (approx. 50-900)
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFE5E5E5);
  static const Color grey300 = Color(0xFFCCCCCC);
  static const Color grey400 = Color(0xFFB3B3B3);
  static const Color grey500 = Color(0xFF8A8A8A);
  static const Color grey600 = Color(0xFF6E6E6E);
  static const Color grey700 = Color(0xFF4D4D4D);
  static const Color grey800 = Color(0xFF1F1F1F);
  static const Color grey900 = Color(0xFF0B0B0B);

  // Semantic (kept for clarity; use sparingly)
  static const Color error = Color(0xFFFF4D4D);
  static const Color warning = Color(0xFFFFC107);
  static const Color success = electricGreen; // align success with brand accent

  // Backwards-compat names used across the app (map to new palette)
  static const Color primary = electricGreen;
  static const Color primaryLight = Color(0xFF66FF99);
  static const Color primaryDark = Color(0xFF00CC52);
  static const Color secondary = grey600; // subdued secondary
  static const Color accent = electricGreen;

  // Surfaces and text
  static const Color background = white;
  static const Color surface = white;
  static const Color textPrimary = Color(0xFF121212);
  static const Color textSecondary = grey600;
  static const Color textHint = grey400;

  // Map styling neutrals (prefer greys; overlays/paths may tint with primary)
  static const Color mapPrimary = electricGreen;
  static const Color mapSecondary = grey600;
  static const Color mapAccent = grey400;
}
