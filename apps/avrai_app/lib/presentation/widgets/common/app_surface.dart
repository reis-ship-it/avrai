import 'package:flutter/material.dart';

import 'package:avrai/theme/colors.dart';
import 'package:avrai/theme/tokens/theme_tokens.dart';

/// Generic surface primitive for sections, cards, and grouped content.
class AppSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double? radius;

  const AppSurface({
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
    final surfaceTokens = context.surfaceTokens;
    final resolvedColor = color ??
        (isDark
            ? AppColors.grey800.withValues(alpha: 0.92)
            : AppColors.surface);
    final resolvedBorderColor =
        borderColor ?? (isDark ? AppColors.grey700 : AppColors.borderSubtle);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: BorderRadius.circular(resolvedRadius),
        border: Border.all(
          color: resolvedBorderColor,
          width: surfaceTokens.defaultBorderWidth,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: surfaceTokens.shadowBlur,
                  offset: surfaceTokens.shadowOffset,
                ),
              ],
      ),
      child: child,
    );
  }
}
