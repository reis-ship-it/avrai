import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/theme/tokens/theme_tokens.dart';

import 'package:gradient_borders/gradient_borders.dart';
import 'package:avrai_runtime_os/config/design_feature_flags.dart';

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
    final immersive = context.immersive;
    final resolvedBlurSigma = blurSigma ?? 15.0; // Reduced from 25.0
    final resolvedBorderRadius = borderRadius ??
        BorderRadius.all(Radius.circular(immersive.slateCornerRadius));

    // Colors based on Day/Night mode
    // Lighter tint for a more effortless, airy feel
    final tintColor = isDark
        ? AppColors.black.withValues(alpha: 0.10) // Was 0.22
        : AppColors.white.withValues(alpha: 0.05); // Was 0.08

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
            color: AppColors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: resolvedBorderRadius,
        child: DesignFeatureFlags.enableHeavyWorldPlaneEffects
            ? BackdropFilter(
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
                      width: immersive.slateBorderWidth,
                    ),
                    borderRadius: resolvedBorderRadius,
                  ),
                  child: child,
                ),
              )
            : Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.black.withValues(alpha: 0.85)
                      : AppColors.white.withValues(alpha: 0.90),
                  border: GradientBoxBorder(
                    gradient: borderGradient,
                    width: immersive.slateBorderWidth,
                  ),
                  borderRadius: resolvedBorderRadius,
                ),
                child: child,
              ),
      ),
    );
  }
}
