import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';

import 'package:gradient_borders/gradient_borders.dart';

/// A high-tech glass container with a chamfered metal edge.
///
/// This is the primary container for the Portal Design System.
/// It uses a high-blur BackdropFilter and a gradient border to simulate
/// a physical slate of glass floating in the world.
class GlassSlate extends StatelessWidget {
  final Widget child;
  final bool isDark; // True = Smoked Glass (Day), False = Mist Glass (Night)
  final double? blurSigma;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  const GlassSlate({
    super.key,
    required this.child,
    this.isDark = true,
    this.blurSigma,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final portal = context.portal;
    final resolvedBlurSigma = blurSigma ?? portal.slateBlur;
    final resolvedBorderRadius = borderRadius ??
        BorderRadius.all(Radius.circular(portal.slateCornerRadius));

    // Colors based on Day/Night mode
    // Make the glass clearer (less tinted) so the background world reads as "behind glass"
    // instead of being painted over. Keep a hint of tint for legibility.
    final tintColor = isDark
        ? AppColors.black.withValues(alpha: 0.22) // Smoked, but clearer
        : AppColors.white.withValues(alpha: 0.08); // Mist glass

    final borderGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x99FFFFFF), // White Highlight (Top Left)
              Color(0x1AFFFFFF), // Transparent Mid
              Color(0x66000000), // Shadow (Bottom Right)
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xCCFFFFFF), // Pearl Highlight
              Color(0x33FFFFFF),
              Color(0x66404040), // Charcoal Shadow
            ],
          );

    return Container(
      // The heavy drop shadow that lifts the slate off the world
      decoration: BoxDecoration(
        borderRadius: resolvedBorderRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.45),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: resolvedBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: resolvedBlurSigma,
            sigmaY: resolvedBlurSigma,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: tintColor,
              border: GradientBoxBorder(
                gradient: borderGradient,
                width: portal.slateBorderWidth,
              ),
              borderRadius: resolvedBorderRadius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
