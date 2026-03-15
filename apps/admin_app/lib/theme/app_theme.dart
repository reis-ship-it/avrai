import 'package:avrai_admin_app/theme/colors.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = AppColors.primary;
  static const Color secondaryColor = AppColors.secondary;
  static const Color accentColor = AppColors.accent;
  static const Color backgroundColor = AppColors.background;
  static const Color surfaceColor = AppColors.surface;
  static const Color errorColor = AppColors.error;
  static const Color successColor = AppColors.success;
  static const Color warningColor = AppColors.warning;

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return _applyTheme(base, brightness: Brightness.light);
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return _applyTheme(base, brightness: Brightness.dark);
  }

  static ThemeData _applyTheme(ThemeData base,
      {required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? AppColors.grey900 : AppColors.background;
    final surface = isDark ? AppColors.grey800 : AppColors.surface;
    final textColor = isDark ? AppColors.white : AppColors.textPrimary;
    final borderColor = isDark ? AppColors.grey700 : AppColors.borderSubtle;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppColors.white : AppColors.primary,
      onPrimary: isDark ? AppColors.black : AppColors.white,
      secondary: isDark ? AppColors.grey300 : AppColors.secondary,
      onSecondary: isDark ? AppColors.black : AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      surface: surface,
      onSurface: textColor,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerColor: borderColor,
      iconTheme: IconThemeData(color: textColor),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.grey800 : AppColors.surfaceMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.white : AppColors.primary,
            width: 1.5,
          ),
        ),
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.white : AppColors.primary,
          foregroundColor: isDark ? AppColors.black : AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(
              color: isDark ? AppColors.grey400 : AppColors.borderStrong),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.grey800 : AppColors.surfaceMuted,
        selectedColor: isDark ? AppColors.white : AppColors.primary,
        disabledColor: isDark ? AppColors.grey800 : AppColors.surfaceMuted,
        secondarySelectedColor: isDark ? AppColors.white : AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        labelStyle: TextStyle(color: textColor),
        secondaryLabelStyle:
            TextStyle(color: isDark ? AppColors.black : AppColors.white),
        brightness: brightness,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.black,
        contentTextStyle: TextStyle(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
