// Motion Settings Widget
//
// User-configurable settings for motion-reactive 3D visualizations.
// Part of Motion-Reactive 3D Visualization System.
//
// Settings:
// - Motion sensitivity (0-100%)
// - Disable device motion (accessibility)
// - Reduce motion (for motion sickness)
// - Bubble effects on/off
// - Adaptive quality on/off

import 'dart:developer' as developer;
import 'package:avrai/presentation/presentation_spacing.dart';

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avrai/core/services/device/device_motion_service.dart';

/// Settings keys for motion preferences
class MotionSettingsKeys {
  static const String motionEnabled = 'motion_enabled';
  static const String motionSensitivity = 'motion_sensitivity';
  static const String reduceMotion = 'reduce_motion';
  static const String bubbleEffects = 'bubble_effects';
  static const String adaptiveQuality = 'adaptive_quality';
}

/// Widget for motion-related settings
class MotionSettingsWidget extends StatefulWidget {
  const MotionSettingsWidget({super.key});

  @override
  State<MotionSettingsWidget> createState() => _MotionSettingsWidgetState();
}

class _MotionSettingsWidgetState extends State<MotionSettingsWidget> {
  static const String _logName = 'MotionSettingsWidget';

  bool _motionEnabled = true;
  double _motionSensitivity = 0.7;
  bool _reduceMotion = false;
  bool _bubbleEffects = true;
  bool _adaptiveQuality = true;

  DeviceMotionService? _motionService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initMotionService();
  }

  void _initMotionService() {
    try {
      _motionService = GetIt.I<DeviceMotionService>();
    } catch (e) {
      developer.log('DeviceMotionService not available', name: _logName);
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _motionEnabled = prefs.getBool(MotionSettingsKeys.motionEnabled) ?? true;
      _motionSensitivity =
          prefs.getDouble(MotionSettingsKeys.motionSensitivity) ?? 0.7;
      _reduceMotion = prefs.getBool(MotionSettingsKeys.reduceMotion) ?? false;
      _bubbleEffects = prefs.getBool(MotionSettingsKeys.bubbleEffects) ?? true;
      _adaptiveQuality =
          prefs.getBool(MotionSettingsKeys.adaptiveQuality) ?? true;
      _isLoading = false;
    });

    _applySettings();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(MotionSettingsKeys.motionEnabled, _motionEnabled);
    await prefs.setDouble(
        MotionSettingsKeys.motionSensitivity, _motionSensitivity);
    await prefs.setBool(MotionSettingsKeys.reduceMotion, _reduceMotion);
    await prefs.setBool(MotionSettingsKeys.bubbleEffects, _bubbleEffects);
    await prefs.setBool(MotionSettingsKeys.adaptiveQuality, _adaptiveQuality);

    _applySettings();
  }

  void _applySettings() {
    if (_motionService == null) return;

    // Apply motion enabled/disabled
    _motionService!.setMotionEnabled(_motionEnabled && !_reduceMotion);

    // Apply sensitivity
    final effectiveSensitivity =
        _reduceMotion ? _motionSensitivity * 0.3 : _motionSensitivity;
    _motionService!.setSensitivity(effectiveSensitivity);

    // Apply adaptive quality
    _motionService!.setAdaptiveQualityEnabled(_adaptiveQuality);

    developer.log(
      'Applied motion settings: enabled=$_motionEnabled, '
      'sensitivity=$effectiveSensitivity, reduce=$_reduceMotion',
      name: _logName,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Motion Effects'),
        _buildMotionEnabledSwitch(),
        if (_motionEnabled) ...[
          _buildSensitivitySlider(),
          _buildReduceMotionSwitch(),
        ],
        const SizedBox(height: 16),
        _buildSectionHeader('Visual Effects'),
        _buildBubbleEffectsSwitch(),
        const SizedBox(height: 16),
        _buildSectionHeader('Performance'),
        _buildAdaptiveQualitySwitch(),
        _buildAdaptiveStatusInfo(),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
          left: kSpaceMd, top: kSpaceMd, bottom: kSpaceXs),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
      ),
    );
  }

  Widget _buildMotionEnabledSwitch() {
    return SwitchListTile(
      title: Text('Device Motion'),
      subtitle: Text('Respond to device tilt and shake'),
      value: _motionEnabled,
      onChanged: (value) {
        setState(() => _motionEnabled = value);
        _saveSettings();
      },
      secondary: Icon(
        Icons.screen_rotation,
        color: _motionEnabled ? AppColors.primary : AppColors.grey400,
      ),
    );
  }

  Widget _buildSensitivitySlider() {
    return ListTile(
      title: Text('Motion Sensitivity'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Low', style: Theme.of(context).textTheme.bodySmall),
              Expanded(
                child: Slider(
                  value: _motionSensitivity,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: '${(_motionSensitivity * 100).round()}%',
                  onChanged: (value) {
                    setState(() => _motionSensitivity = value);
                  },
                  onChangeEnd: (value) {
                    _saveSettings();
                  },
                ),
              ),
              Text('High', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
      leading: const Icon(Icons.tune),
    );
  }

  Widget _buildReduceMotionSwitch() {
    return SwitchListTile(
      title: Text('Reduce Motion'),
      subtitle: Text('Minimize motion effects (accessibility)'),
      value: _reduceMotion,
      onChanged: (value) {
        setState(() => _reduceMotion = value);
        _saveSettings();
      },
      secondary: Icon(
        Icons.accessibility,
        color: _reduceMotion ? AppColors.primary : AppColors.grey400,
      ),
    );
  }

  Widget _buildBubbleEffectsSwitch() {
    return SwitchListTile(
      title: Text('Bubble Effects'),
      subtitle: Text('Show glass bubble around knots'),
      value: _bubbleEffects,
      onChanged: (value) {
        setState(() => _bubbleEffects = value);
        _saveSettings();
      },
      secondary: Icon(
        Icons.bubble_chart,
        color: _bubbleEffects ? AppColors.primary : AppColors.grey400,
      ),
    );
  }

  Widget _buildAdaptiveQualitySwitch() {
    return SwitchListTile(
      title: Text('Adaptive Quality'),
      subtitle: Text('Reduce effects when battery is low'),
      value: _adaptiveQuality,
      onChanged: (value) {
        setState(() => _adaptiveQuality = value);
        _saveSettings();
      },
      secondary: Icon(
        Icons.battery_saver,
        color: _adaptiveQuality ? AppColors.primary : AppColors.grey400,
      ),
    );
  }

  Widget _buildAdaptiveStatusInfo() {
    if (_motionService == null) {
      return const SizedBox.shrink();
    }

    final status = _motionService!.adaptiveStatus;

    if (!_adaptiveQuality) {
      return const SizedBox.shrink();
    }

    String statusText;
    Color statusColor;

    if (status.isBackground) {
      statusText = 'Motion paused (app in background)';
      statusColor = AppColors.grey500;
    } else if (status.isLowBattery) {
      statusText = 'Reduced to 30fps (low battery)';
      statusColor = AppColors.warning;
    } else {
      statusText = 'Full quality (60fps)';
      statusColor = AppColors.success;
    }

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: kSpaceMd, vertical: kSpaceXs),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Static helper to load bubble effects preference
class MotionSettings {
  static Future<bool> getBubbleEffectsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(MotionSettingsKeys.bubbleEffects) ?? true;
  }

  static Future<double> getMotionSensitivity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(MotionSettingsKeys.motionSensitivity) ?? 0.7;
  }

  static Future<bool> getReduceMotion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(MotionSettingsKeys.reduceMotion) ?? false;
  }
}
