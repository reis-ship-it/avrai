import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';

class AppTheme {
  // Centralized tokens for backwards compatibility across the app
  static const Color primaryColor = AppColors.electricGreen;
  static const Color secondaryColor = AppColors.grey600;
  static const Color accentColor = AppColors.electricGreen;
  static const Color backgroundColor = AppColors.white;
  static const Color surfaceColor = AppColors.white;
  static const Color errorColor = AppColors.error;
  static const Color successColor = AppColors.success;
  static const Color warningColor = AppColors.warning;
  static const Color offlineColor = AppColors.grey500;

  // Light Theme
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.electricGreen,
      onPrimary: AppColors.black,
      secondary: AppColors.grey600,
      onSecondary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.textPrimary,
    );

    final baseTextTheme = ThemeData.light().textTheme;
    // In tests we disable runtime fetching for GoogleFonts; if the font isn't bundled as an asset,
    // GoogleFonts will throw. Fall back to the base TextTheme in that case.
    final textTheme = GoogleFonts.config.allowRuntimeFetching
        ? GoogleFonts.interTextTheme(baseTextTheme)
        : baseTextTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: const <ThemeExtension<dynamic>>[
        AppSpacing(),
        AppRadius(),
        AppMotion(),
        PortalTokens(),
      ],
      scaffoldBackgroundColor: AppColors.white,
      textTheme: textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.transparent,
        centerTitle: true,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.black,
        contentTextStyle: TextStyle(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.grey200,
          foregroundColor: AppColors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.grey300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.grey200,
        selectedColor: AppColors.electricGreen,
        disabledColor: AppColors.grey200,
        secondarySelectedColor: AppColors.electricGreen,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        labelStyle: TextStyle(color: AppColors.textPrimary),
        secondaryLabelStyle: TextStyle(color: AppColors.black),
        brightness: Brightness.light,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.electricGreen,
        unselectedItemColor: AppColors.grey600,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x14000000),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x26000000)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x26000000)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),
      cardTheme: const CardThemeData(
        color: Color(0x1A000000),
        elevation: 0,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: Color(0x26000000)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xCC0B0B0B),
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0x33FFFFFF)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xCC0B0B0B),
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),
      dividerColor: AppColors.grey200,
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.electricGreen,
      onPrimary: AppColors.black,
      secondary: AppColors.grey600,
      onSecondary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      surface: AppColors.grey900,
      onSurface: AppColors.white,
    );

    final baseTextTheme = ThemeData.dark().textTheme;
    final textTheme = GoogleFonts.config.allowRuntimeFetching
        ? GoogleFonts.interTextTheme(baseTextTheme)
        : baseTextTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: const <ThemeExtension<dynamic>>[
        AppSpacing(),
        AppRadius(),
        AppMotion(),
        PortalTokens(),
      ],
      scaffoldBackgroundColor: AppColors.grey900,
      textTheme: textTheme.apply(
        bodyColor: AppColors.white,
        displayColor: AppColors.white,
      ),
      iconTheme: const IconThemeData(color: AppColors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.transparent,
        foregroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.transparent,
        centerTitle: true,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.black,
        contentTextStyle: TextStyle(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.grey200,
          foregroundColor: AppColors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.grey700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.grey800,
        selectedColor: AppColors.electricGreen,
        disabledColor: AppColors.grey800,
        secondarySelectedColor: AppColors.electricGreen,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        labelStyle: TextStyle(color: AppColors.white),
        secondaryLabelStyle: TextStyle(color: AppColors.black),
        brightness: Brightness.dark,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.grey900,
        selectedItemColor: AppColors.electricGreen,
        unselectedItemColor: AppColors.grey600,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x1AFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),
      cardTheme: const CardThemeData(
        color: Color(0x14FFFFFF),
        elevation: 0,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: Color(0x33FFFFFF)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xCC0B0B0B),
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0x33FFFFFF)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xCC0B0B0B),
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),
      dividerColor: AppColors.grey800,
    );
  }
}
