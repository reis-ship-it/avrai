// Haptics Service
//
// Centralized haptic feedback service for iOS-native feel.
// Provides consistent haptic patterns across the app.
//
// Usage:
//   HapticsService.light();    // Light tap for selections
//   HapticsService.medium();   // Medium impact for actions
//   HapticsService.success();  // Success feedback
//   HapticsService.error();    // Error feedback

import 'dart:io';

import 'package:flutter/services.dart';

/// Centralized haptic feedback service for consistent iOS-native feel.
///
/// Provides various haptic patterns for different interaction types.
/// Haptics are only triggered on physical devices (not simulators).
class HapticsService {
  /// Whether haptics are enabled (can be toggled in settings)
  static bool _enabled = true;

  /// Enable or disable haptic feedback globally
  static set enabled(bool value) => _enabled = value;

  /// Check if haptics are currently enabled
  static bool get isEnabled => _enabled;

  /// Selection click - for discrete value changes (pickers, toggles)
  ///
  /// Use for: Toggle switches, picker selections, list item selections
  static Future<void> selection() async {
    if (!_shouldTrigger) return;
    await HapticFeedback.selectionClick();
  }

  /// Light impact - for subtle feedback on taps
  ///
  /// Use for: Button taps, nav item selections, card taps
  static Future<void> light() async {
    if (!_shouldTrigger) return;
    await HapticFeedback.lightImpact();
  }

  /// Medium impact - for standard action feedback
  ///
  /// Use for: Important button presses, form submissions, confirmations
  static Future<void> medium() async {
    if (!_shouldTrigger) return;
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact - for significant actions or alerts
  ///
  /// Use for: Errors, warnings, destructive actions, shake gestures
  static Future<void> heavy() async {
    if (!_shouldTrigger) return;
    await HapticFeedback.heavyImpact();
  }

  /// Success feedback - confirms successful action
  ///
  /// Use for: Successful saves, completed tasks, successful submissions
  static Future<void> success() async {
    if (!_shouldTrigger) return;
    await HapticFeedback.mediumImpact();
  }

  /// Error feedback - indicates an error occurred
  ///
  /// Use for: Validation errors, failed actions, network errors
  static Future<void> error() async {
    if (!_shouldTrigger) return;
    await HapticFeedback.heavyImpact();
  }

  /// Warning feedback - alerts user to potential issue
  ///
  /// Use for: Warnings, confirmations before destructive actions
  static Future<void> warning() async {
    if (!_shouldTrigger) return;
    await HapticFeedback.mediumImpact();
  }

  /// Vibrate - standard vibration pattern
  ///
  /// Use for: Notifications, alerts that need attention
  static Future<void> vibrate() async {
    if (!_shouldTrigger) return;
    await HapticFeedback.vibrate();
  }

  /// Knot interaction feedback - for knot-related interactions
  ///
  /// Use for: Tapping on knot, knot animations, knot generation complete
  static Future<void> knotInteraction() async {
    if (!_shouldTrigger) return;
    await HapticFeedback.lightImpact();
  }

  /// Knot evolution feedback - when knot evolves/changes
  ///
  /// Use for: Knot evolution complete, personality update
  static Future<void> knotEvolution() async {
    if (!_shouldTrigger) return;
    await HapticFeedback.mediumImpact();
  }

  /// Navigation feedback - for navigation transitions
  ///
  /// Use for: Page transitions, modal presentations
  static Future<void> navigation() async {
    if (!_shouldTrigger) return;
    await HapticFeedback.selectionClick();
  }

  /// Pull to refresh feedback - when refresh is triggered
  ///
  /// Use for: Pull-to-refresh activation
  static Future<void> pullToRefresh() async {
    if (!_shouldTrigger) return;
    await HapticFeedback.mediumImpact();
  }

  /// Slider feedback - for slider value changes
  ///
  /// Use for: Slider movements at discrete points
  static Future<void> slider() async {
    if (!_shouldTrigger) return;
    await HapticFeedback.selectionClick();
  }

  /// Long press feedback - when long press is recognized
  ///
  /// Use for: Context menu activation, drag start
  static Future<void> longPress() async {
    if (!_shouldTrigger) return;
    await HapticFeedback.mediumImpact();
  }

  /// Check if haptics should trigger
  static bool get _shouldTrigger {
    if (!_enabled) return false;
    // Only trigger on iOS (Android has different haptic patterns)
    // Haptics work on real devices, not simulators
    return Platform.isIOS;
  }
}
