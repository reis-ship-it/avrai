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
class AppTypography extends ThemeExtension<AppTypography> {
  final double display;
  final double heading;
  final double title;
  final double body;
  final double caption;
  final double button;
  final double brandLetterSpacing;

  const AppTypography({
    this.display = 30,
    this.heading = 20,
    this.title = 16,
    this.body = 15,
    this.caption = 12,
    this.button = 16,
    this.brandLetterSpacing = 4,
  });

  @override
  AppTypography copyWith({
    double? display,
    double? heading,
    double? title,
    double? body,
    double? caption,
    double? button,
    double? brandLetterSpacing,
  }) {
    return AppTypography(
      display: display ?? this.display,
      heading: heading ?? this.heading,
      title: title ?? this.title,
      body: body ?? this.body,
      caption: caption ?? this.caption,
      button: button ?? this.button,
      brandLetterSpacing: brandLetterSpacing ?? this.brandLetterSpacing,
    );
  }

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) return this;
    return AppTypography(
      display: lerpDouble(display, other.display, t),
      heading: lerpDouble(heading, other.heading, t),
      title: lerpDouble(title, other.title, t),
      body: lerpDouble(body, other.body, t),
      caption: lerpDouble(caption, other.caption, t),
      button: lerpDouble(button, other.button, t),
      brandLetterSpacing:
          lerpDouble(brandLetterSpacing, other.brandLetterSpacing, t),
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
    this.fast = const Duration(milliseconds: 180),
    this.normal = const Duration(milliseconds: 300),
    this.slow = const Duration(milliseconds: 450),
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
class PortalTokens extends ThemeExtension<PortalTokens> {
  final double slateBlur;
  final double slateCornerRadius;
  final double slateBorderWidth;
  final double surfaceCornerRadius;
  final double surfaceBlur;
  final double surfaceBorderWidth;
  final double surfaceShadowBlur;
  final double surfaceShadowYOffset;
  final double surfaceShadowSpread;
  final double surfaceDayTintAlpha;
  final double surfaceNightTintAlpha;
  final double edgePadding;
  final double recessedMapCornerRadius;
  final double recessedMapBorderWidth;
  final double recessedMapVignetteAlpha;
  final double maxPhoneContentWidth;
  final double maxTabletContentWidth;
  final double maxDesktopContentWidth;

  const PortalTokens({
    this.slateBlur = 25,
    this.slateCornerRadius = 32,
    this.slateBorderWidth = 1.5,
    this.surfaceCornerRadius = 32,
    this.surfaceBlur = 25,
    this.surfaceBorderWidth = 1.5,
    this.surfaceShadowBlur = 40,
    this.surfaceShadowYOffset = 20,
    this.surfaceShadowSpread = -10,
    this.surfaceDayTintAlpha = 0.22,
    this.surfaceNightTintAlpha = 0.08,
    this.edgePadding = 12,
    this.recessedMapCornerRadius = 20,
    this.recessedMapBorderWidth = 1,
    this.recessedMapVignetteAlpha = 0.6,
    this.maxPhoneContentWidth = 480,
    this.maxTabletContentWidth = 760,
    this.maxDesktopContentWidth = 980,
  });

  @override
  PortalTokens copyWith({
    double? slateBlur,
    double? slateCornerRadius,
    double? slateBorderWidth,
    double? surfaceCornerRadius,
    double? surfaceBlur,
    double? surfaceBorderWidth,
    double? surfaceShadowBlur,
    double? surfaceShadowYOffset,
    double? surfaceShadowSpread,
    double? surfaceDayTintAlpha,
    double? surfaceNightTintAlpha,
    double? edgePadding,
    double? recessedMapCornerRadius,
    double? recessedMapBorderWidth,
    double? recessedMapVignetteAlpha,
    double? maxPhoneContentWidth,
    double? maxTabletContentWidth,
    double? maxDesktopContentWidth,
  }) {
    return PortalTokens(
      slateBlur: slateBlur ?? this.slateBlur,
      slateCornerRadius: slateCornerRadius ?? this.slateCornerRadius,
      slateBorderWidth: slateBorderWidth ?? this.slateBorderWidth,
      surfaceCornerRadius: surfaceCornerRadius ?? this.surfaceCornerRadius,
      surfaceBlur: surfaceBlur ?? this.surfaceBlur,
      surfaceBorderWidth: surfaceBorderWidth ?? this.surfaceBorderWidth,
      surfaceShadowBlur: surfaceShadowBlur ?? this.surfaceShadowBlur,
      surfaceShadowYOffset: surfaceShadowYOffset ?? this.surfaceShadowYOffset,
      surfaceShadowSpread: surfaceShadowSpread ?? this.surfaceShadowSpread,
      surfaceDayTintAlpha: surfaceDayTintAlpha ?? this.surfaceDayTintAlpha,
      surfaceNightTintAlpha:
          surfaceNightTintAlpha ?? this.surfaceNightTintAlpha,
      edgePadding: edgePadding ?? this.edgePadding,
      recessedMapCornerRadius:
          recessedMapCornerRadius ?? this.recessedMapCornerRadius,
      recessedMapBorderWidth:
          recessedMapBorderWidth ?? this.recessedMapBorderWidth,
      recessedMapVignetteAlpha:
          recessedMapVignetteAlpha ?? this.recessedMapVignetteAlpha,
      maxPhoneContentWidth: maxPhoneContentWidth ?? this.maxPhoneContentWidth,
      maxTabletContentWidth:
          maxTabletContentWidth ?? this.maxTabletContentWidth,
      maxDesktopContentWidth:
          maxDesktopContentWidth ?? this.maxDesktopContentWidth,
    );
  }

  @override
  PortalTokens lerp(ThemeExtension<PortalTokens>? other, double t) {
    if (other is! PortalTokens) return this;
    return PortalTokens(
      slateBlur: lerpDouble(slateBlur, other.slateBlur, t),
      slateCornerRadius:
          lerpDouble(slateCornerRadius, other.slateCornerRadius, t),
      slateBorderWidth: lerpDouble(slateBorderWidth, other.slateBorderWidth, t),
      surfaceCornerRadius:
          lerpDouble(surfaceCornerRadius, other.surfaceCornerRadius, t),
      surfaceBlur: lerpDouble(surfaceBlur, other.surfaceBlur, t),
      surfaceBorderWidth:
          lerpDouble(surfaceBorderWidth, other.surfaceBorderWidth, t),
      surfaceShadowBlur:
          lerpDouble(surfaceShadowBlur, other.surfaceShadowBlur, t),
      surfaceShadowYOffset:
          lerpDouble(surfaceShadowYOffset, other.surfaceShadowYOffset, t),
      surfaceShadowSpread:
          lerpDouble(surfaceShadowSpread, other.surfaceShadowSpread, t),
      surfaceDayTintAlpha:
          lerpDouble(surfaceDayTintAlpha, other.surfaceDayTintAlpha, t),
      surfaceNightTintAlpha:
          lerpDouble(surfaceNightTintAlpha, other.surfaceNightTintAlpha, t),
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
      maxPhoneContentWidth:
          lerpDouble(maxPhoneContentWidth, other.maxPhoneContentWidth, t),
      maxTabletContentWidth:
          lerpDouble(maxTabletContentWidth, other.maxTabletContentWidth, t),
      maxDesktopContentWidth:
          lerpDouble(maxDesktopContentWidth, other.maxDesktopContentWidth, t),
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
  AppSpacing get spacing =>
      Theme.of(this).extension<AppSpacing>() ?? const AppSpacing();

  AppRadius get radius =>
      Theme.of(this).extension<AppRadius>() ?? const AppRadius();

  AppMotion get motion =>
      Theme.of(this).extension<AppMotion>() ?? const AppMotion();

  PortalTokens get portal =>
      Theme.of(this).extension<PortalTokens>() ?? const PortalTokens();
}
