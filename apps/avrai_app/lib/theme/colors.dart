import 'package:flutter/material.dart';

/// Neutral, platform-portable palette.
///
/// The baseline contract is monochrome. Semantic colors exist only for states
/// that need user feedback clarity.
class AppColors {
  static const Color transparent = Colors.transparent;

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  static const Color grey50 = Color(0xFFF8F8F8);
  static const Color grey100 = Color(0xFFF2F2F2);
  static const Color grey200 = Color(0xFFE6E6E6);
  static const Color grey300 = Color(0xFFD0D0D0);
  static const Color grey400 = Color(0xFFB2B2B2);
  static const Color grey500 = Color(0xFF8C8C8C);
  static const Color grey600 = Color(0xFF666666);
  static const Color grey700 = Color(0xFF474747);
  static const Color grey800 = Color(0xFF242424);
  static const Color grey900 = Color(0xFF111111);

  static const Color textPrimary = grey900;
  static const Color textSecondary = grey600;
  static const Color textHint = grey500;
  static const Color textInverse = white;

  static const Color background = white;
  static const Color surface = white;
  static const Color surfaceMuted = grey50;
  static const Color surfaceElevated = white;
  static const Color borderSubtle = grey200;
  static const Color borderStrong = grey300;

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFB7791F);
  static const Color error = Color(0xFFB42318);
  static const Color focus = grey900;
  static const Color selection = grey700;

  static const Color primary = focus;
  static const Color primaryLight = grey600;
  static const Color primaryDark = black;
  static const Color secondary = grey700;
  static const Color accent = selection;

  static const Color mapPrimary = grey800;
  static const Color mapSecondary = grey600;
  static const Color mapAccent = grey400;

  // Legacy aliases kept temporarily while the repo migrates.
  static const Color electricGreen = success;
  static const Color electricBlue = selection;
  static const Color slateBlue = selection;
}
