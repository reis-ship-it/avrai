import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// Service for tracking app usage/screen time for AI learning (Android only)
///
/// Uses Android's UsageStatsManager to understand:
/// - What apps the user spends time in
/// - App usage patterns (time of day, duration)
/// - App categories (social, fitness, productivity, etc.)
///
/// Platform limitations:
/// - iOS: Not supported (Apple blocks this API)
/// - Android: Requires PACKAGE_USAGE_STATS permission (user must enable in Settings)
///
/// All data is processed locally on-device per avrai privacy philosophy.
class AppUsageService {
  static const String _logName = 'AppUsageService';
  static const _channel = MethodChannel('com.avrai.app_usage');

  bool _isInitialized = false;
  bool _hasPermission = false;

  AppUsageService();

  /// Initialize the app usage service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Only supported on Android
      if (!Platform.isAndroid) {
        developer.log(
          'AppUsageService only supported on Android',
          name: _logName,
        );
        _isInitialized = true;
        _hasPermission = false;
        return;
      }

      // Check if permission is granted
      _hasPermission = await _checkPermission();

      _isInitialized = true;

      developer.log(
        'AppUsageService initialized. Permission: $_hasPermission',
        name: _logName,
      );
    } catch (e, st) {
      developer.log(
        'Error initializing AppUsageService',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      _isInitialized = true;
      _hasPermission = false;
    }
  }

  /// Check if app usage stats permission is granted
  Future<bool> _checkPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Error checking app usage permission: ${e.message}',
        name: _logName,
      );
      return false;
    } on MissingPluginException {
      // Platform channel not implemented yet
      developer.log(
        'App usage platform channel not implemented',
        name: _logName,
      );
      return false;
    }
  }

  /// Request the user to enable app usage stats permission
  ///
  /// Opens the system Settings page where user can enable the permission.
  Future<void> requestPermission() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod<void>('requestPermission');
    } on PlatformException catch (e) {
      developer.log(
        'Error requesting app usage permission: ${e.message}',
        name: _logName,
      );
    } on MissingPluginException {
      developer.log(
        'App usage platform channel not implemented',
        name: _logName,
      );
    }
  }

  /// Check if app usage tracking is available
  bool get isAvailable =>
      _isInitialized && _hasPermission && Platform.isAndroid;

  /// Collect app usage data for AI learning
  ///
  /// Returns aggregated app usage data for the specified time range.
  Future<Map<String, dynamic>> collectAppUsageData({
    Duration range = const Duration(days: 7),
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_hasPermission || !Platform.isAndroid) {
      return {'has_data': false, 'reason': 'not_available'};
    }

    try {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final startTime = endTime - range.inMilliseconds;

      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getUsageStats',
        {
          'startTime': startTime,
          'endTime': endTime,
        },
      );

      if (result == null || result.isEmpty) {
        return {'has_data': false, 'reason': 'no_data'};
      }

      // Process and categorize the usage data
      final usageData = _processUsageData(Map<String, dynamic>.from(result));

      return {
        'has_data': true,
        'range_days': range.inDays,
        ...usageData,
        'learning_signals': _deriveLearningSignals(usageData),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } on PlatformException catch (e) {
      developer.log(
        'Error collecting app usage data: ${e.message}',
        name: _logName,
      );
      return {'has_data': false, 'reason': 'error', 'error': e.message};
    } on MissingPluginException {
      // Platform channel not implemented - use fallback data
      return _getFallbackData();
    }
  }

  /// Process raw usage data from the platform
  Map<String, dynamic> _processUsageData(Map<String, dynamic> rawData) {
    final apps = rawData['apps'] as List<dynamic>? ?? [];

    // Categorize apps
    final categoryUsage = <String, int>{};
    final topApps = <Map<String, dynamic>>[];
    int totalUsageMinutes = 0;

    for (final app in apps) {
      if (app is! Map) continue;

      final packageName = app['packageName'] as String? ?? '';
      final usageMinutes = (app['totalTimeInForeground'] as int? ?? 0) ~/ 60000;

      if (usageMinutes < 1) continue; // Skip apps with < 1 minute usage

      totalUsageMinutes += usageMinutes;

      final category = _categorizeApp(packageName);
      categoryUsage[category] = (categoryUsage[category] ?? 0) + usageMinutes;

      topApps.add({
        'package': packageName,
        'app_name': _getAppName(packageName),
        'usage_minutes': usageMinutes,
        'category': category,
      });
    }

    // Sort by usage and take top 10
    topApps.sort((a, b) =>
        (b['usage_minutes'] as int).compareTo(a['usage_minutes'] as int));
    final topTenApps = topApps.take(10).toList();

    // Find top category
    String? topCategory;
    int maxCategoryUsage = 0;
    for (final entry in categoryUsage.entries) {
      if (entry.value > maxCategoryUsage) {
        maxCategoryUsage = entry.value;
        topCategory = entry.key;
      }
    }

    return {
      'total_usage_minutes': totalUsageMinutes,
      'total_usage_hours': (totalUsageMinutes / 60).toStringAsFixed(1),
      'category_usage': categoryUsage,
      'top_category': topCategory,
      'top_apps': topTenApps,
      'apps_used_count': topApps.length,
    };
  }

  /// Categorize an app based on its package name
  String _categorizeApp(String packageName) {
    final pkg = packageName.toLowerCase();

    // Social media
    if (_containsAny(pkg, [
      'facebook',
      'instagram',
      'twitter',
      'tiktok',
      'snapchat',
      'linkedin',
      'reddit',
      'pinterest',
      'tumblr',
      'threads',
    ])) {
      return 'social';
    }

    // Messaging
    if (_containsAny(pkg, [
      'whatsapp',
      'messenger',
      'telegram',
      'signal',
      'discord',
      'slack',
      'wechat',
      'viber',
      'line',
      'sms',
      'messages',
    ])) {
      return 'messaging';
    }

    // Fitness & Health
    if (_containsAny(pkg, [
      'strava',
      'nike',
      'fitness',
      'health',
      'workout',
      'peloton',
      'myfitnesspal',
      'headspace',
      'calm',
      'sleep',
      'meditation',
      'fitbit',
      'garmin',
    ])) {
      return 'fitness';
    }

    // Entertainment
    if (_containsAny(pkg, [
      'netflix',
      'youtube',
      'spotify',
      'hulu',
      'disney',
      'hbo',
      'twitch',
      'tubi',
      'amazon.video',
      'primevideo',
      'music',
      'podcast',
      'audible',
    ])) {
      return 'entertainment';
    }

    // Gaming
    if (_containsAny(pkg, [
      'games',
      'gaming',
      'roblox',
      'minecraft',
      'supercell',
      'king.com',
      'rovio',
      'niantic',
      'pokemon',
      'candy',
      'clash',
    ])) {
      return 'gaming';
    }

    // Productivity
    if (_containsAny(pkg, [
      'google.docs',
      'google.sheets',
      'google.slides',
      'microsoft.office',
      'notion',
      'trello',
      'asana',
      'todoist',
      'evernote',
      'notes',
      'calendar',
    ])) {
      return 'productivity';
    }

    // News & Reading
    if (_containsAny(pkg, [
      'news',
      'nytimes',
      'cnn',
      'bbc',
      'medium',
      'flipboard',
      'kindle',
      'books',
      'pocket',
      'feedly',
    ])) {
      return 'news';
    }

    // Shopping
    if (_containsAny(pkg, [
      'amazon',
      'ebay',
      'etsy',
      'walmart',
      'target',
      'shop',
      'store',
      'wish',
      'shein',
    ])) {
      return 'shopping';
    }

    // Food & Dining
    if (_containsAny(pkg, [
      'doordash',
      'uber.eats',
      'grubhub',
      'yelp',
      'opentable',
      'resy',
      'postmates',
      'instacart',
    ])) {
      return 'food';
    }

    // Travel & Navigation
    if (_containsAny(pkg, [
      'maps',
      'waze',
      'uber',
      'lyft',
      'airbnb',
      'booking',
      'expedia',
      'tripadvisor',
    ])) {
      return 'travel';
    }

    // Finance
    if (_containsAny(pkg, [
      'bank',
      'venmo',
      'paypal',
      'cashapp',
      'mint',
      'robinhood',
      'coinbase',
      'finance',
    ])) {
      return 'finance';
    }

    // Dating
    if (_containsAny(pkg, [
      'tinder',
      'bumble',
      'hinge',
      'match',
      'okcupid',
      'grindr',
      'coffee.meets',
    ])) {
      return 'dating';
    }

    // Photos
    if (_containsAny(pkg, [
      'photos',
      'gallery',
      'camera',
      'snapseed',
      'vsco',
      'lightroom',
    ])) {
      return 'photos';
    }

    return 'other';
  }

  /// Get a friendly app name from package name
  String _getAppName(String packageName) {
    // Extract the last component of the package name
    final parts = packageName.split('.');
    if (parts.length >= 2) {
      // Try to get a meaningful name from the package
      final lastPart = parts.last;
      if (lastPart.length > 2) {
        return _capitalize(lastPart);
      }
      // Use second-to-last if last is too short
      if (parts.length >= 3) {
        return _capitalize(parts[parts.length - 2]);
      }
    }
    return packageName;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Derive learning signals from app usage data
  Map<String, dynamic> _deriveLearningSignals(Map<String, dynamic> usageData) {
    final categoryUsage =
        usageData['category_usage'] as Map<String, int>? ?? {};
    final topCategory = usageData['top_category'] as String?;
    final totalMinutes = usageData['total_usage_minutes'] as int? ?? 0;

    // Calculate percentages
    final socialPercent = _getPercent(categoryUsage['social'], totalMinutes);
    final fitnessPercent = _getPercent(categoryUsage['fitness'], totalMinutes);
    final entertainmentPercent =
        _getPercent(categoryUsage['entertainment'], totalMinutes);
    final productivityPercent =
        _getPercent(categoryUsage['productivity'], totalMinutes);
    final gamingPercent = _getPercent(categoryUsage['gaming'], totalMinutes);

    return {
      // Category preferences
      'is_social_heavy': socialPercent > 25,
      'is_fitness_oriented': fitnessPercent > 10,
      'is_entertainment_focused': entertainmentPercent > 30,
      'is_productivity_focused': productivityPercent > 15,
      'is_gamer': gamingPercent > 20,

      // Venue suggestion signals based on app usage
      'suggest_social_venues': socialPercent > 20,
      'suggest_fitness_spots': fitnessPercent > 10,
      'suggest_entertainment_venues': entertainmentPercent > 25,
      'suggest_quiet_workspaces': productivityPercent > 20,
      'suggest_gaming_venues': gamingPercent > 15,

      // Dating app usage suggests social/nightlife venues
      'dating_app_user': categoryUsage.containsKey('dating'),

      // Food app usage suggests restaurant suggestions
      'food_app_user': categoryUsage.containsKey('food'),

      // Top category for general preference
      'primary_digital_interest': topCategory,

      // Usage intensity
      'heavy_phone_user': totalMinutes > 240 * 7, // >4 hrs/day average
      'moderate_phone_user': totalMinutes > 120 * 7 && totalMinutes <= 240 * 7,
      'light_phone_user': totalMinutes <= 120 * 7,
    };
  }

  double _getPercent(int? value, int total) {
    if (value == null || total == 0) return 0.0;
    return (value / total) * 100;
  }

  bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  /// Get fallback data when platform channel is not available
  ///
  /// Returns empty data structure indicating feature is not available.
  Map<String, dynamic> _getFallbackData() {
    developer.log(
      'Using fallback data - platform channel not implemented',
      name: _logName,
    );
    return {
      'has_data': false,
      'reason': 'platform_not_implemented',
      'message': 'App usage tracking requires native Android implementation',
    };
  }

  /// Get app usage patterns for long-term learning
  Future<Map<String, dynamic>> getAppUsagePatterns() async {
    // Get 30-day data for pattern analysis
    return collectAppUsageData(range: const Duration(days: 30));
  }
}
