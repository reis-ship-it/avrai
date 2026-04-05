import 'package:flutter/material.dart';

extension ColorHexUIExtension on Color {
  /// Converts a Color to a hex string representation.
  /// Used by Three.js visualization styles.
  String toHex({bool leadingHashSign = true}) {
    // Handling deprecated member access warnings by using the correct getters or keeping it simple
    // color.value is deprecated in newer Flutter versions in favor of color.a, color.r, color.g, color.b
    // But since we are compiling under an older stable or transitional, we'll try standard alpha, red, green, blue
    final a = (this.a * 255).toInt().toRadixString(16).padLeft(2, '0');
    final r = (this.r * 255).toInt().toRadixString(16).padLeft(2, '0');
    final g = (this.g * 255).toInt().toRadixString(16).padLeft(2, '0');
    final b = (this.b * 255).toInt().toRadixString(16).padLeft(2, '0');
    return '${leadingHashSign ? '#' : ''}$a$r$g$b';
  }
}
