// List Preference Service
//
// Phase 2.3: User preferences for AI-suggested lists
//
// Purpose: Manage user preferences for list generation

import 'dart:developer' as developer;

import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/ai/perpetual_list/models/models.dart';
import 'package:get_it/get_it.dart';

/// List Preference Service
///
/// Manages user preferences for AI-suggested list generation including:
/// - Category preferences (on/off, explicit opt-in for sensitive)
/// - Timing preferences (morning/evening)
/// - Exploration vs familiar balance
/// - Notification settings
///
/// Part of Phase 2.3: Preference Editing

class ListPreferenceService {
  static const String _logName = 'ListPreferenceService';

  // Storage keys
  static const String _enabledCategoriesKey = 'list_pref_enabled_categories';
  static const String _disabledCategoriesKey = 'list_pref_disabled_categories';
  static const String _optInCategoriesKey = 'list_pref_optin_categories';
  static const String _preferredTimeSlotsKey = 'list_pref_time_slots';
  static const String _explorationBalanceKey = 'list_pref_exploration';
  static const String _maxListsPerDayKey = 'list_pref_max_per_day';
  static const String _minIntervalHoursKey = 'list_pref_min_interval';
  static const String _notificationsEnabledKey = 'list_pref_notifications';

  final StorageService _storageService;

  // Cached preferences
  Set<String> _enabledCategories = {};
  Set<String> _disabledCategories = {};
  Set<String> _optInCategories = {};
  Map<TimeSlot, bool> _preferredTimeSlots = {};
  double _explorationBalance = 0.5;
  int _maxListsPerDay = 3;
  int _minIntervalHours = 8;
  bool _notificationsEnabled = true;
  bool _loaded = false;

  ListPreferenceService({
    StorageService? storageService,
  }) : _storageService = storageService ?? GetIt.instance<StorageService>();

  /// Load preferences from storage
  Future<void> loadPreferences() async {
    if (_loaded) return;

    try {
      // Load enabled/disabled categories
      final enabled = _storageService.getStringList(_enabledCategoriesKey);
      if (enabled != null) _enabledCategories = enabled.toSet();

      final disabled = _storageService.getStringList(_disabledCategoriesKey);
      if (disabled != null) _disabledCategories = disabled.toSet();

      final optIn = _storageService.getStringList(_optInCategoriesKey);
      if (optIn != null) _optInCategories = optIn.toSet();

      // Load timing preferences
      final timeSlots = _storageService.getString(_preferredTimeSlotsKey);
      if (timeSlots != null) {
        _preferredTimeSlots = _parseTimeSlots(timeSlots);
      }

      // Load balance and limits
      final exploration = _storageService.getString(_explorationBalanceKey);
      if (exploration != null) {
        _explorationBalance = double.tryParse(exploration) ?? 0.5;
      }

      final maxLists = _storageService.getString(_maxListsPerDayKey);
      if (maxLists != null) {
        _maxListsPerDay = int.tryParse(maxLists) ?? 3;
      }

      final minInterval = _storageService.getString(_minIntervalHoursKey);
      if (minInterval != null) {
        _minIntervalHours = int.tryParse(minInterval) ?? 8;
      }

      _notificationsEnabled = _storageService.getBool(_notificationsEnabledKey) ?? true;

      _loaded = true;
      developer.log('List preferences loaded', name: _logName);
    } catch (e) {
      developer.log('Error loading list preferences: $e', name: _logName);
    }
  }

  /// Save all preferences
  Future<void> savePreferences() async {
    try {
      await _storageService.setStringList(
        _enabledCategoriesKey,
        _enabledCategories.toList(),
      );
      await _storageService.setStringList(
        _disabledCategoriesKey,
        _disabledCategories.toList(),
      );
      await _storageService.setStringList(
        _optInCategoriesKey,
        _optInCategories.toList(),
      );
      await _storageService.setString(
        _preferredTimeSlotsKey,
        _serializeTimeSlots(_preferredTimeSlots),
      );
      await _storageService.setString(
        _explorationBalanceKey,
        _explorationBalance.toString(),
      );
      await _storageService.setString(
        _maxListsPerDayKey,
        _maxListsPerDay.toString(),
      );
      await _storageService.setString(
        _minIntervalHoursKey,
        _minIntervalHours.toString(),
      );
      await _storageService.setBool(_notificationsEnabledKey, _notificationsEnabled);

      developer.log('List preferences saved', name: _logName);
    } catch (e) {
      developer.log('Error saving list preferences: $e', name: _logName);
    }
  }

  // Category preferences

  /// Check if a category is enabled
  bool isCategoryEnabled(String category) {
    if (_disabledCategories.contains(category)) return false;
    return _enabledCategories.isEmpty || _enabledCategories.contains(category);
  }

  /// Enable a category
  Future<void> enableCategory(String category) async {
    _enabledCategories.add(category);
    _disabledCategories.remove(category);
    await savePreferences();
  }

  /// Disable a category
  Future<void> disableCategory(String category) async {
    _disabledCategories.add(category);
    _enabledCategories.remove(category);
    await savePreferences();
  }

  /// Get all disabled categories
  Set<String> get disabledCategories => Set.from(_disabledCategories);

  // Sensitive category opt-in

  /// Check if user has opted into a sensitive category
  bool hasOptedIn(String category) => _optInCategories.contains(category);

  /// Opt into a sensitive category
  Future<void> optInToCategory(String category) async {
    _optInCategories.add(category);
    await savePreferences();
  }

  /// Opt out of a sensitive category
  Future<void> optOutOfCategory(String category) async {
    _optInCategories.remove(category);
    await savePreferences();
  }

  /// Get all opted-in categories
  Set<String> get optInCategories => Set.from(_optInCategories);

  // Time slot preferences

  /// Check if a time slot is preferred
  bool isTimeSlotPreferred(TimeSlot slot) {
    return _preferredTimeSlots[slot] ?? true;
  }

  /// Set time slot preference
  Future<void> setTimeSlotPreference(TimeSlot slot, bool preferred) async {
    _preferredTimeSlots[slot] = preferred;
    await savePreferences();
  }

  /// Get all time slot preferences
  Map<TimeSlot, bool> get timeSlotPreferences => Map.from(_preferredTimeSlots);

  // Exploration balance

  /// Get exploration balance (0.0 = familiar only, 1.0 = explore only)
  double get explorationBalance => _explorationBalance;

  /// Set exploration balance
  Future<void> setExplorationBalance(double balance) async {
    _explorationBalance = balance.clamp(0.0, 1.0);
    await savePreferences();
  }

  // List limits

  /// Get max lists per day
  int get maxListsPerDay => _maxListsPerDay;

  /// Set max lists per day
  Future<void> setMaxListsPerDay(int max) async {
    _maxListsPerDay = max.clamp(1, 10);
    await savePreferences();
  }

  /// Get min interval between generations (hours)
  int get minIntervalHours => _minIntervalHours;

  /// Set min interval between generations (hours)
  Future<void> setMinIntervalHours(int hours) async {
    _minIntervalHours = hours.clamp(1, 24);
    await savePreferences();
  }

  // Notifications

  /// Check if notifications are enabled
  bool get notificationsEnabled => _notificationsEnabled;

  /// Set notification preference
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await savePreferences();
  }

  // Serialization helpers

  Map<TimeSlot, bool> _parseTimeSlots(String serialized) {
    final result = <TimeSlot, bool>{};
    final parts = serialized.split(',');
    for (final part in parts) {
      final kv = part.split(':');
      if (kv.length == 2) {
        try {
          final slot = TimeSlot.values.firstWhere((s) => s.name == kv[0]);
          result[slot] = kv[1] == 'true';
        } catch (_) {
          // Skip invalid entries
        }
      }
    }
    return result;
  }

  String _serializeTimeSlots(Map<TimeSlot, bool> slots) {
    return slots.entries
        .map((e) => '${e.key.name}:${e.value}')
        .join(',');
  }
}
