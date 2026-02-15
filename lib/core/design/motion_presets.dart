import 'package:flutter/material.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';

class MotionPresets {
  const MotionPresets._();

  static Curve get emphasized => Curves.easeOutCubic;
  static Curve get standard => Curves.easeOut;
  static Curve get entering => Curves.easeOutCubic;
  static Curve get exiting => Curves.easeInCubic;

  static Duration quick(BuildContext context) => context.motion.fast;
  static Duration normal(BuildContext context) => context.motion.normal;
  static Duration slow(BuildContext context) => context.motion.slow;

  static Duration routeForward(BuildContext context) => context.motion.normal;
  static Duration routeReverse(BuildContext context) => context.motion.fast;
}
