import 'package:flutter/material.dart';

@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  const AppSpacing({
    this.xxs = 4,
    this.xs = 8,
    this.sm = 12,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
    this.xxl = 48,
  });

  @override
  AppSpacing copyWith({
    double? xxs,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) {
    return AppSpacing(
      xxs: xxs ?? this.xxs,
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) return this;
    return AppSpacing(
      xxs: lerpDouble(xxs, other.xxs, t),
      xs: lerpDouble(xs, other.xs, t),
      sm: lerpDouble(sm, other.sm, t),
      md: lerpDouble(md, other.md, t),
      lg: lerpDouble(lg, other.lg, t),
      xl: lerpDouble(xl, other.xl, t),
      xxl: lerpDouble(xxl, other.xxl, t),
    );
  }
}

@immutable
class AppRadius extends ThemeExtension<AppRadius> {
  final double sm;
  final double md;
  final double lg;
  final double xl;

  const AppRadius({
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
  });

  @override
  AppRadius copyWith({
    double? sm,
    double? md,
    double? lg,
    double? xl,
  }) {
    return AppRadius(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
    );
  }

  @override
  AppRadius lerp(ThemeExtension<AppRadius>? other, double t) {
    if (other is! AppRadius) return this;
    return AppRadius(
      sm: lerpDouble(sm, other.sm, t),
      md: lerpDouble(md, other.md, t),
      lg: lerpDouble(lg, other.lg, t),
      xl: lerpDouble(xl, other.xl, t),
    );
  }
}

@immutable
class AppMotion extends ThemeExtension<AppMotion> {
  final Duration fast;
  final Duration normal;
  final Duration slow;

  const AppMotion({
    this.fast = const Duration(milliseconds: 160),
    this.normal = const Duration(milliseconds: 240),
    this.slow = const Duration(milliseconds: 360),
  });

  @override
  AppMotion copyWith({
    Duration? fast,
    Duration? normal,
    Duration? slow,
  }) {
    return AppMotion(
      fast: fast ?? this.fast,
      normal: normal ?? this.normal,
      slow: slow ?? this.slow,
    );
  }

  @override
  AppMotion lerp(ThemeExtension<AppMotion>? other, double t) {
    if (other is! AppMotion) return this;
    return AppMotion(
      fast: lerpDuration(fast, other.fast, t),
      normal: lerpDuration(normal, other.normal, t),
      slow: lerpDuration(slow, other.slow, t),
    );
  }
}

@immutable
class AppLayoutTokens extends ThemeExtension<AppLayoutTokens> {
  final double maxPhoneContentWidth;
  final double maxTabletContentWidth;
  final double maxDesktopContentWidth;

  const AppLayoutTokens({
    this.maxPhoneContentWidth = 480,
    this.maxTabletContentWidth = 760,
    this.maxDesktopContentWidth = 980,
  });

  @override
  AppLayoutTokens copyWith({
    double? maxPhoneContentWidth,
    double? maxTabletContentWidth,
    double? maxDesktopContentWidth,
  }) {
    return AppLayoutTokens(
      maxPhoneContentWidth: maxPhoneContentWidth ?? this.maxPhoneContentWidth,
      maxTabletContentWidth:
          maxTabletContentWidth ?? this.maxTabletContentWidth,
      maxDesktopContentWidth:
          maxDesktopContentWidth ?? this.maxDesktopContentWidth,
    );
  }

  @override
  AppLayoutTokens lerp(ThemeExtension<AppLayoutTokens>? other, double t) {
    if (other is! AppLayoutTokens) return this;
    return AppLayoutTokens(
      maxPhoneContentWidth:
          lerpDouble(maxPhoneContentWidth, other.maxPhoneContentWidth, t),
      maxTabletContentWidth:
          lerpDouble(maxTabletContentWidth, other.maxTabletContentWidth, t),
      maxDesktopContentWidth:
          lerpDouble(maxDesktopContentWidth, other.maxDesktopContentWidth, t),
    );
  }
}

@immutable
class AppTypographyTokens extends ThemeExtension<AppTypographyTokens> {
  final double display;
  final double headline;
  final double title;
  final double body;
  final double label;
  final double bodyLineHeight;
  final FontWeight strongWeight;
  final FontWeight regularWeight;

  const AppTypographyTokens({
    this.display = 34,
    this.headline = 28,
    this.title = 20,
    this.body = 16,
    this.label = 13,
    this.bodyLineHeight = 1.45,
    this.strongWeight = FontWeight.w700,
    this.regularWeight = FontWeight.w400,
  });

  @override
  AppTypographyTokens copyWith({
    double? display,
    double? headline,
    double? title,
    double? body,
    double? label,
    double? bodyLineHeight,
    FontWeight? strongWeight,
    FontWeight? regularWeight,
  }) {
    return AppTypographyTokens(
      display: display ?? this.display,
      headline: headline ?? this.headline,
      title: title ?? this.title,
      body: body ?? this.body,
      label: label ?? this.label,
      bodyLineHeight: bodyLineHeight ?? this.bodyLineHeight,
      strongWeight: strongWeight ?? this.strongWeight,
      regularWeight: regularWeight ?? this.regularWeight,
    );
  }

  @override
  AppTypographyTokens lerp(
      ThemeExtension<AppTypographyTokens>? other, double t) {
    if (other is! AppTypographyTokens) return this;
    return AppTypographyTokens(
      display: lerpDouble(display, other.display, t),
      headline: lerpDouble(headline, other.headline, t),
      title: lerpDouble(title, other.title, t),
      body: lerpDouble(body, other.body, t),
      label: lerpDouble(label, other.label, t),
      bodyLineHeight: lerpDouble(bodyLineHeight, other.bodyLineHeight, t),
      strongWeight: t < 0.5 ? strongWeight : other.strongWeight,
      regularWeight: t < 0.5 ? regularWeight : other.regularWeight,
    );
  }
}

@immutable
class AppSurfaceTokens extends ThemeExtension<AppSurfaceTokens> {
  final double defaultBorderWidth;
  final double strongBorderWidth;
  final double shadowBlur;
  final Offset shadowOffset;

  const AppSurfaceTokens({
    this.defaultBorderWidth = 1,
    this.strongBorderWidth = 1.5,
    this.shadowBlur = 12,
    this.shadowOffset = const Offset(0, 4),
  });

  @override
  AppSurfaceTokens copyWith({
    double? defaultBorderWidth,
    double? strongBorderWidth,
    double? shadowBlur,
    Offset? shadowOffset,
  }) {
    return AppSurfaceTokens(
      defaultBorderWidth: defaultBorderWidth ?? this.defaultBorderWidth,
      strongBorderWidth: strongBorderWidth ?? this.strongBorderWidth,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowOffset: shadowOffset ?? this.shadowOffset,
    );
  }

  @override
  AppSurfaceTokens lerp(ThemeExtension<AppSurfaceTokens>? other, double t) {
    if (other is! AppSurfaceTokens) return this;
    return AppSurfaceTokens(
      defaultBorderWidth:
          lerpDouble(defaultBorderWidth, other.defaultBorderWidth, t),
      strongBorderWidth:
          lerpDouble(strongBorderWidth, other.strongBorderWidth, t),
      shadowBlur: lerpDouble(shadowBlur, other.shadowBlur, t),
      shadowOffset: Offset.lerp(shadowOffset, other.shadowOffset, t)!,
    );
  }
}

@immutable
class AppSemanticColorTokens extends ThemeExtension<AppSemanticColorTokens> {
  final Color focus;
  final Color selection;
  final Color success;
  final Color warning;
  final Color error;

  const AppSemanticColorTokens({
    required this.focus,
    required this.selection,
    required this.success,
    required this.warning,
    required this.error,
  });

  @override
  AppSemanticColorTokens copyWith({
    Color? focus,
    Color? selection,
    Color? success,
    Color? warning,
    Color? error,
  }) {
    return AppSemanticColorTokens(
      focus: focus ?? this.focus,
      selection: selection ?? this.selection,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
    );
  }

  @override
  AppSemanticColorTokens lerp(
      ThemeExtension<AppSemanticColorTokens>? other, double t) {
    if (other is! AppSemanticColorTokens) return this;
    return AppSemanticColorTokens(
      focus: Color.lerp(focus, other.focus, t)!,
      selection: Color.lerp(selection, other.selection, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}

@immutable
class AppImmersiveTokens extends ThemeExtension<AppImmersiveTokens> {
  final double slateBlur;
  final double slateCornerRadius;
  final double slateBorderWidth;
  final double edgePadding;
  final double recessedMapCornerRadius;
  final double recessedMapBorderWidth;
  final double recessedMapVignetteAlpha;

  const AppImmersiveTokens({
    this.slateBlur = 18,
    this.slateCornerRadius = 24,
    this.slateBorderWidth = 1.25,
    this.edgePadding = 12,
    this.recessedMapCornerRadius = 18,
    this.recessedMapBorderWidth = 1,
    this.recessedMapVignetteAlpha = 0.55,
  });

  @override
  AppImmersiveTokens copyWith({
    double? slateBlur,
    double? slateCornerRadius,
    double? slateBorderWidth,
    double? edgePadding,
    double? recessedMapCornerRadius,
    double? recessedMapBorderWidth,
    double? recessedMapVignetteAlpha,
  }) {
    return AppImmersiveTokens(
      slateBlur: slateBlur ?? this.slateBlur,
      slateCornerRadius: slateCornerRadius ?? this.slateCornerRadius,
      slateBorderWidth: slateBorderWidth ?? this.slateBorderWidth,
      edgePadding: edgePadding ?? this.edgePadding,
      recessedMapCornerRadius:
          recessedMapCornerRadius ?? this.recessedMapCornerRadius,
      recessedMapBorderWidth:
          recessedMapBorderWidth ?? this.recessedMapBorderWidth,
      recessedMapVignetteAlpha:
          recessedMapVignetteAlpha ?? this.recessedMapVignetteAlpha,
    );
  }

  @override
  AppImmersiveTokens lerp(ThemeExtension<AppImmersiveTokens>? other, double t) {
    if (other is! AppImmersiveTokens) return this;
    return AppImmersiveTokens(
      slateBlur: lerpDouble(slateBlur, other.slateBlur, t),
      slateCornerRadius:
          lerpDouble(slateCornerRadius, other.slateCornerRadius, t),
      slateBorderWidth: lerpDouble(slateBorderWidth, other.slateBorderWidth, t),
      edgePadding: lerpDouble(edgePadding, other.edgePadding, t),
      recessedMapCornerRadius: lerpDouble(
        recessedMapCornerRadius,
        other.recessedMapCornerRadius,
        t,
      ),
      recessedMapBorderWidth: lerpDouble(
        recessedMapBorderWidth,
        other.recessedMapBorderWidth,
        t,
      ),
      recessedMapVignetteAlpha: lerpDouble(
        recessedMapVignetteAlpha,
        other.recessedMapVignetteAlpha,
        t,
      ),
    );
  }
}

double lerpDouble(double a, double b, double t) => a + (b - a) * t;

Duration lerpDuration(Duration a, Duration b, double t) {
  return Duration(
    microseconds:
        (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t).round(),
  );
}

extension ThemeTokenContext on BuildContext {
  AppLayoutTokens get layout =>
      Theme.of(this).extension<AppLayoutTokens>() ?? const AppLayoutTokens();

  AppSpacing get spacing =>
      Theme.of(this).extension<AppSpacing>() ?? const AppSpacing();

  AppRadius get radius =>
      Theme.of(this).extension<AppRadius>() ?? const AppRadius();

  AppMotion get motion =>
      Theme.of(this).extension<AppMotion>() ?? const AppMotion();

  AppTypographyTokens get typography =>
      Theme.of(this).extension<AppTypographyTokens>() ??
      const AppTypographyTokens();

  AppSurfaceTokens get surfaceTokens =>
      Theme.of(this).extension<AppSurfaceTokens>() ?? const AppSurfaceTokens();

  AppSemanticColorTokens get semanticColors =>
      Theme.of(this).extension<AppSemanticColorTokens>() ??
      const AppSemanticColorTokens(
        focus: Colors.black,
        selection: Colors.black54,
        success: Colors.green,
        warning: Colors.orange,
        error: Colors.red,
      );

  AppImmersiveTokens get immersive =>
      Theme.of(this).extension<AppImmersiveTokens>() ??
      const AppImmersiveTokens();
}
