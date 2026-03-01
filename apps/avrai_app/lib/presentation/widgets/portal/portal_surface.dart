import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/theme/tokens/theme_tokens.dart';

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

  const PortalSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.borderColor,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedRadius = radius ?? context.radius.lg;
    final resolvedColor = color ??
        (isDark
            ? AppColors.white.withValues(alpha: 0.06)
            : AppColors.black.withValues(alpha: 0.04));
    final resolvedBorderColor = borderColor ??
        (isDark
            ? AppColors.white.withValues(alpha: 0.12)
            : AppColors.black.withValues(alpha: 0.08));

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: BorderRadius.circular(resolvedRadius),
        border: Border.all(color: resolvedBorderColor),
      ),
      child: child,
    );
  }
}
