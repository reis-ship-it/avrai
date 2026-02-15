import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:avrai/core/design/component_tokens.dart';
import 'package:avrai/core/navigation/app_page_transitions.dart';
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
  static const ButtonTokens buttonTokens = ButtonTokens();
  static const InputTokens inputTokens = InputTokens();
  static const CardTokens cardTokens = CardTokens();
  static const ChipTokens chipTokens = ChipTokens();
  static const OverlayTokens overlayTokens = OverlayTokens();
  static const IconTokens iconTokens = IconTokens();
  static const FeedbackTokens feedbackTokens = FeedbackTokens();

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
        AppTypography(),
        AppRadius(),
        AppMotion(),
        PortalTokens(),
        ButtonTokens(),
        InputTokens(),
        CardTokens(),
        ChipTokens(),
        OverlayTokens(),
        IconTokens(),
        FeedbackTokens(),
      ],
      scaffoldBackgroundColor: AppColors.white,
      textTheme: textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      pageTransitionsTheme: AppPageTransitions.pageTransitionsTheme,
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
          minimumSize: Size.fromHeight(buttonTokens.minHeight),
          padding: buttonTokens.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonTokens.cornerRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: Size.fromHeight(buttonTokens.minHeight),
          padding: buttonTokens.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonTokens.cornerRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.grey300),
          minimumSize: Size.fromHeight(buttonTokens.minHeight),
          padding: buttonTokens.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonTokens.cornerRadius),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.grey200,
        selectedColor: AppColors.electricGreen,
        disabledColor: AppColors.grey200,
        secondarySelectedColor: AppColors.electricGreen,
        padding: chipTokens.padding,
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
          borderRadius: BorderRadius.circular(inputTokens.cornerRadius),
          borderSide: const BorderSide(color: Color(0x26000000)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputTokens.cornerRadius),
          borderSide: const BorderSide(color: Color(0x26000000)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputTokens.cornerRadius),
          borderSide: BorderSide(
            color: primaryColor,
            width: inputTokens.focusedBorderWidth,
          ),
        ),
        contentPadding: inputTokens.contentPadding,
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),
      cardTheme: CardThemeData(
        color: Color(0x1A000000),
        elevation: 0,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(cardTokens.cornerRadius)),
          side: BorderSide(color: Color(0x26000000)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Color(0xCC0B0B0B),
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(overlayTokens.dialogRadius)),
          side: BorderSide(color: Color(0x33FFFFFF)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Color(0xCC0B0B0B),
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(overlayTokens.bottomSheetTopRadius),
            topRight: Radius.circular(overlayTokens.bottomSheetTopRadius),
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
        AppTypography(),
        AppRadius(),
        AppMotion(),
        PortalTokens(),
        ButtonTokens(),
        InputTokens(),
        CardTokens(),
        ChipTokens(),
        OverlayTokens(),
        IconTokens(),
        FeedbackTokens(),
      ],
      scaffoldBackgroundColor: AppColors.grey900,
      textTheme: textTheme.apply(
        bodyColor: AppColors.white,
        displayColor: AppColors.white,
      ),
      iconTheme: const IconThemeData(color: AppColors.white),
      pageTransitionsTheme: AppPageTransitions.pageTransitionsTheme,
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
          minimumSize: Size.fromHeight(buttonTokens.minHeight),
          padding: buttonTokens.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonTokens.cornerRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.white,
          minimumSize: Size.fromHeight(buttonTokens.minHeight),
          padding: buttonTokens.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonTokens.cornerRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.grey700),
          minimumSize: Size.fromHeight(buttonTokens.minHeight),
          padding: buttonTokens.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonTokens.cornerRadius),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.grey800,
        selectedColor: AppColors.electricGreen,
        disabledColor: AppColors.grey800,
        secondarySelectedColor: AppColors.electricGreen,
        padding: chipTokens.padding,
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
          borderRadius: BorderRadius.circular(inputTokens.cornerRadius),
          borderSide: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputTokens.cornerRadius),
          borderSide: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputTokens.cornerRadius),
          borderSide: BorderSide(
            color: primaryColor,
            width: inputTokens.focusedBorderWidth,
          ),
        ),
        contentPadding: inputTokens.contentPadding,
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),
      cardTheme: CardThemeData(
        color: Color(0x14FFFFFF),
        elevation: 0,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(cardTokens.cornerRadius)),
          side: BorderSide(color: Color(0x33FFFFFF)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Color(0xCC0B0B0B),
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(overlayTokens.dialogRadius)),
          side: BorderSide(color: Color(0x33FFFFFF)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Color(0xCC0B0B0B),
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(overlayTokens.bottomSheetTopRadius),
            topRight: Radius.circular(overlayTokens.bottomSheetTopRadius),
          ),
        ),
      ),
      dividerColor: AppColors.grey800,
    );
  }
}
