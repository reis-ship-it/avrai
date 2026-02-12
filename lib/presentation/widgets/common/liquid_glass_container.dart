// Liquid Glass Container Widget
//
// iOS 26-style glass container with blur effect and translucent appearance.
// Provides the "Liquid Glass" aesthetic for navigation bars, cards, and containers.
//
// Features:
// - BackdropFilter with configurable blur
// - Dark/light mode adaptive colors
// - Optional tint color
// - Configurable border radius and shape
// - Motion-reactive option for parallax effects
//
// Usage:
//   LiquidGlassContainer(
//     child: Text('Hello'),
//     borderRadius: 16,
//     blurSigma: 15,
//   )

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';


/// iOS 26-style Liquid Glass container with blur and translucent appearance.
///
/// Creates a frosted glass effect that adapts to light and dark themes.
/// Use for navigation bars, cards, modal sheets, and profile bubbles.
class LiquidGlassContainer extends StatelessWidget {
  /// Child widget to display inside the glass container
  final Widget child;

  /// Border radius for the container (default: 16)
  final double borderRadius;

  /// Blur sigma for the frosted glass effect (default: 15)
  final double blurSigma;

  /// Optional tint color for the glass (default: based on theme)
  final Color? tintColor;

  /// Opacity of the tint (default: 0.1 for light, 0.08 for dark)
  final double? tintOpacity;

  /// Whether to show a border around the glass (default: true)
  final bool showBorder;

  /// Border color (default: white with low opacity)
  final Color? borderColor;

  /// Border width (default: 0.5)
  final double borderWidth;

  /// Whether to show a subtle shadow (default: true)
  final bool showShadow;

  /// Padding inside the container
  final EdgeInsetsGeometry? padding;

  /// Margin outside the container
  final EdgeInsetsGeometry? margin;

  /// Use circular shape instead of rounded rect
  final bool isCircular;

  /// Width of the container (null = intrinsic)
  final double? width;

  /// Height of the container (null = intrinsic)
  final double? height;

  /// Callback when tapped
  final VoidCallback? onTap;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blurSigma = 15,
    this.tintColor,
    this.tintOpacity,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 0.5,
    this.showShadow = true,
    this.padding,
    this.margin,
    this.isCircular = false,
    this.width,
    this.height,
    this.onTap,
  });

  /// Create a glass container optimized for navigation bars
  factory LiquidGlassContainer.navigationBar({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return LiquidGlassContainer(
      borderRadius: 0,
      blurSigma: 20,
      showBorder: false,
      showShadow: false,
      padding: padding,
      child: child,
    );
  }

  /// Create a glass container optimized for cards
  factory LiquidGlassContainer.card({
    required Widget child,
    double borderRadius = 16,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return LiquidGlassContainer(
      borderRadius: borderRadius,
      blurSigma: 12,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }

  /// Create a glass container optimized for modal sheets
  factory LiquidGlassContainer.modalSheet({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return LiquidGlassContainer(
      borderRadius: 24,
      blurSigma: 25,
      showShadow: true,
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    );
  }

  /// Create a circular glass container for profile images
  factory LiquidGlassContainer.circular({
    required Widget child,
    double size = 60,
    VoidCallback? onTap,
  }) {
    return LiquidGlassContainer(
      isCircular: true,
      width: size,
      height: size,
      blurSigma: 10,
      onTap: onTap,
      child: child,
    );
  }

  /// Create a glass container for the knot visualization
  factory LiquidGlassContainer.knot({
    required Widget child,
    double size = 80,
    VoidCallback? onTap,
  }) {
    return LiquidGlassContainer(
      isCircular: true,
      width: size,
      height: size,
      blurSigma: 12,
      tintColor: AppColors.electricGreen,
      tintOpacity: 0.05,
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine colors based on theme
    final effectiveTintColor =
        tintColor ?? (isDark ? AppColors.white : AppColors.white);
    // Default glass should be clearer (less milky) so the background world shows through.
    // We keep a small amount of tint so text/icons remain readable.
    final effectiveTintOpacity = tintOpacity ?? (isDark ? 0.05 : 0.07);
    final effectiveBorderColor =
        borderColor ?? AppColors.white.withValues(alpha: isDark ? 0.15 : 0.25);

    // Build the shape
    final shape = isCircular ? BoxShape.circle : BoxShape.rectangle;

    final borderRadiusValue =
        isCircular ? null : BorderRadius.circular(borderRadius);

    Widget container = ClipRRect(
      borderRadius:
          isCircular ? BorderRadius.circular(1000) : borderRadiusValue!,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: isCircular ? null : borderRadiusValue,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                effectiveTintColor.withValues(alpha: effectiveTintOpacity),
                effectiveTintColor.withValues(
                    alpha: effectiveTintOpacity * 0.5),
              ],
            ),
            border: showBorder
                ? Border.all(
                    color: effectiveBorderColor,
                    width: borderWidth,
                  )
                : null,
            boxShadow: showShadow
                ? [
                    BoxShadow(
                      color:
                          AppColors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );

    // Add margin if specified
    if (margin != null) {
      container = Padding(padding: margin!, child: container);
    }

    // Add tap handling if callback provided
    if (onTap != null) {
      container = GestureDetector(
        onTap: onTap,
        child: container,
      );
    }

    return container;
  }
}

/// A glass-effect bottom navigation bar container
class LiquidGlassNavigationBar extends StatelessWidget {
  final Widget child;
  final double height;
  final EdgeInsetsGeometry? padding;

  const LiquidGlassNavigationBar({
    super.key,
    required this.child,
    this.height = 80,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: height,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.white.withValues(alpha: 0.1),
                AppColors.white.withValues(alpha: 0.05),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: AppColors.white.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A glass-effect app bar container
class LiquidGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  final double height;
  final bool showBorder;

  const LiquidGlassAppBar({
    super.key,
    this.leading,
    this.title,
    this.actions,
    this.height = kToolbarHeight + 44,
    this.showBorder = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: height + statusBarHeight,
          padding: EdgeInsets.only(top: statusBarHeight),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.white.withValues(alpha: 0.12),
                AppColors.white.withValues(alpha: 0.08),
              ],
            ),
            border: showBorder
                ? Border(
                    bottom: BorderSide(
                      color: AppColors.white.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  )
                : null,
          ),
          child: NavigationToolbar(
            leading: leading,
            middle: title,
            trailing: actions != null
                ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
                : null,
          ),
        ),
      ),
    );
  }
}
