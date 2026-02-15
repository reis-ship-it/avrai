import 'dart:ui';
import 'package:avrai/presentation/presentation_spacing.dart';

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:gradient_borders/gradient_borders.dart';

/// Reusable portal-style surface for cards/sections inside the slate.
///
/// Use this instead of ad-hoc `Container + BoxDecoration` when you want
/// consistent portal styling that can be tuned from shared tokens/theme.
class PortalSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double? radius;
  final double? elevation;
  final ShapeBorder? shape;

  const PortalSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(kSpaceMd),
    this.margin,
    this.color,
    this.borderColor,
    this.radius,
    this.elevation,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final portal = context.portal;
    BorderRadius resolvedBorderRadius =
        BorderRadius.circular(radius ?? portal.surfaceCornerRadius);
    BorderSide? shapeSide;
    if (shape is RoundedRectangleBorder) {
      final roundedShape = shape as RoundedRectangleBorder;
      if (roundedShape.borderRadius is BorderRadius) {
        resolvedBorderRadius = roundedShape.borderRadius as BorderRadius;
      }
      if (roundedShape.side.style != BorderStyle.none &&
          roundedShape.side.width > 0) {
        shapeSide = roundedShape.side;
      }
    }

    final resolvedColor = color ??
        (isDark
            ? AppColors.white.withValues(alpha: portal.surfaceNightTintAlpha)
            : AppColors.black.withValues(alpha: portal.surfaceDayTintAlpha));
    final resolvedBorderColor = borderColor ??
        shapeSide?.color ??
        (isDark
            ? AppColors.white.withValues(alpha: 0.12)
            : AppColors.black.withValues(alpha: 0.08));
    final resolvedBorderWidth = shapeSide?.width ?? portal.surfaceBorderWidth;
    final isGradientBorder = borderColor == null && shapeSide == null;
    final resolvedElevation = elevation ?? 1;

    final border = isGradientBorder
        ? GradientBoxBorder(
            width: resolvedBorderWidth,
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.portalNightBorderStart,
                      AppColors.portalNightBorderMid,
                      AppColors.portalNightBorderEnd,
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.portalDayBorderStart,
                      AppColors.portalDayBorderMid,
                      AppColors.portalDayBorderEnd,
                    ],
                  ),
          )
        : Border.all(
            color: resolvedBorderColor,
            width: resolvedBorderWidth,
          );

    final BoxShadow? surfaceShadow = resolvedElevation <= 0
        ? null
        : BoxShadow(
            color: AppColors.portalShadow,
            blurRadius: portal.surfaceShadowBlur * resolvedElevation,
            offset: Offset(0, portal.surfaceShadowYOffset * resolvedElevation),
            spreadRadius: portal.surfaceShadowSpread,
          );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: resolvedBorderRadius,
        boxShadow: surfaceShadow == null ? null : [surfaceShadow],
      ),
      child: ClipRRect(
        borderRadius: resolvedBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: portal.surfaceBlur,
            sigmaY: portal.surfaceBlur,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: resolvedColor,
              borderRadius: resolvedBorderRadius,
              border: border,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
