import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';

@immutable
class ButtonTokens extends ThemeExtension<ButtonTokens> {
  final double cornerRadius;
  final EdgeInsetsGeometry padding;
  final double minHeight;

  const ButtonTokens({
    this.cornerRadius = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.minHeight = 44,
  });

  @override
  ButtonTokens copyWith({
    double? cornerRadius,
    EdgeInsetsGeometry? padding,
    double? minHeight,
  }) {
    return ButtonTokens(
      cornerRadius: cornerRadius ?? this.cornerRadius,
      padding: padding ?? this.padding,
      minHeight: minHeight ?? this.minHeight,
    );
  }

  @override
  ButtonTokens lerp(ThemeExtension<ButtonTokens>? other, double t) {
    if (other is! ButtonTokens) return this;
    return ButtonTokens(
      cornerRadius: _lerpDouble(cornerRadius, other.cornerRadius, t),
      padding: EdgeInsetsGeometry.lerp(padding, other.padding, t) ?? padding,
      minHeight: _lerpDouble(minHeight, other.minHeight, t),
    );
  }
}

@immutable
class InputTokens extends ThemeExtension<InputTokens> {
  final double cornerRadius;
  final double focusedBorderWidth;
  final EdgeInsetsGeometry contentPadding;

  const InputTokens({
    this.cornerRadius = 12,
    this.focusedBorderWidth = 2,
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  @override
  InputTokens copyWith({
    double? cornerRadius,
    double? focusedBorderWidth,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputTokens(
      cornerRadius: cornerRadius ?? this.cornerRadius,
      focusedBorderWidth: focusedBorderWidth ?? this.focusedBorderWidth,
      contentPadding: contentPadding ?? this.contentPadding,
    );
  }

  @override
  InputTokens lerp(ThemeExtension<InputTokens>? other, double t) {
    if (other is! InputTokens) return this;
    return InputTokens(
      cornerRadius: _lerpDouble(cornerRadius, other.cornerRadius, t),
      focusedBorderWidth:
          _lerpDouble(focusedBorderWidth, other.focusedBorderWidth, t),
      contentPadding: EdgeInsetsGeometry.lerp(
            contentPadding,
            other.contentPadding,
            t,
          ) ??
          contentPadding,
    );
  }
}

@immutable
class CardTokens extends ThemeExtension<CardTokens> {
  final double cornerRadius;
  final double borderWidth;
  final double elevation;

  const CardTokens({
    this.cornerRadius = 12,
    this.borderWidth = 1,
    this.elevation = 0,
  });

  @override
  CardTokens copyWith({
    double? cornerRadius,
    double? borderWidth,
    double? elevation,
  }) {
    return CardTokens(
      cornerRadius: cornerRadius ?? this.cornerRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      elevation: elevation ?? this.elevation,
    );
  }

  @override
  CardTokens lerp(ThemeExtension<CardTokens>? other, double t) {
    if (other is! CardTokens) return this;
    return CardTokens(
      cornerRadius: _lerpDouble(cornerRadius, other.cornerRadius, t),
      borderWidth: _lerpDouble(borderWidth, other.borderWidth, t),
      elevation: _lerpDouble(elevation, other.elevation, t),
    );
  }
}

@immutable
class ChipTokens extends ThemeExtension<ChipTokens> {
  final EdgeInsetsGeometry padding;
  final double radius;

  const ChipTokens({
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    this.radius = 10,
  });

  @override
  ChipTokens copyWith({
    EdgeInsetsGeometry? padding,
    double? radius,
  }) {
    return ChipTokens(
      padding: padding ?? this.padding,
      radius: radius ?? this.radius,
    );
  }

  @override
  ChipTokens lerp(ThemeExtension<ChipTokens>? other, double t) {
    if (other is! ChipTokens) return this;
    return ChipTokens(
      padding: EdgeInsetsGeometry.lerp(padding, other.padding, t) ?? padding,
      radius: _lerpDouble(radius, other.radius, t),
    );
  }
}

@immutable
class OverlayTokens extends ThemeExtension<OverlayTokens> {
  final Color scrimColor;
  final double dialogRadius;
  final double bottomSheetTopRadius;

  const OverlayTokens({
    this.scrimColor = const Color(0x99000000),
    this.dialogRadius = 16,
    this.bottomSheetTopRadius = 20,
  });

  @override
  OverlayTokens copyWith({
    Color? scrimColor,
    double? dialogRadius,
    double? bottomSheetTopRadius,
  }) {
    return OverlayTokens(
      scrimColor: scrimColor ?? this.scrimColor,
      dialogRadius: dialogRadius ?? this.dialogRadius,
      bottomSheetTopRadius: bottomSheetTopRadius ?? this.bottomSheetTopRadius,
    );
  }

  @override
  OverlayTokens lerp(ThemeExtension<OverlayTokens>? other, double t) {
    if (other is! OverlayTokens) return this;
    return OverlayTokens(
      scrimColor: Color.lerp(scrimColor, other.scrimColor, t) ?? scrimColor,
      dialogRadius: _lerpDouble(dialogRadius, other.dialogRadius, t),
      bottomSheetTopRadius:
          _lerpDouble(bottomSheetTopRadius, other.bottomSheetTopRadius, t),
    );
  }
}

@immutable
class IconTokens extends ThemeExtension<IconTokens> {
  final double xs;
  final double sm;
  final double md;
  final double lg;

  const IconTokens({
    this.xs = 12,
    this.sm = 16,
    this.md = 20,
    this.lg = 24,
  });

  @override
  IconTokens copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
  }) {
    return IconTokens(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
    );
  }

  @override
  IconTokens lerp(ThemeExtension<IconTokens>? other, double t) {
    if (other is! IconTokens) return this;
    return IconTokens(
      xs: _lerpDouble(xs, other.xs, t),
      sm: _lerpDouble(sm, other.sm, t),
      md: _lerpDouble(md, other.md, t),
      lg: _lerpDouble(lg, other.lg, t),
    );
  }
}

@immutable
class FeedbackTokens extends ThemeExtension<FeedbackTokens> {
  final Color infoColor;
  final Color successColor;
  final Color warningColor;
  final Color errorColor;

  const FeedbackTokens({
    this.infoColor = AppColors.electricBlue,
    this.successColor = AppColors.success,
    this.warningColor = AppColors.warning,
    this.errorColor = AppColors.error,
  });

  @override
  FeedbackTokens copyWith({
    Color? infoColor,
    Color? successColor,
    Color? warningColor,
    Color? errorColor,
  }) {
    return FeedbackTokens(
      infoColor: infoColor ?? this.infoColor,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      errorColor: errorColor ?? this.errorColor,
    );
  }

  @override
  FeedbackTokens lerp(ThemeExtension<FeedbackTokens>? other, double t) {
    if (other is! FeedbackTokens) return this;
    return FeedbackTokens(
      infoColor: Color.lerp(infoColor, other.infoColor, t) ?? infoColor,
      successColor:
          Color.lerp(successColor, other.successColor, t) ?? successColor,
      warningColor:
          Color.lerp(warningColor, other.warningColor, t) ?? warningColor,
      errorColor: Color.lerp(errorColor, other.errorColor, t) ?? errorColor,
    );
  }
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
