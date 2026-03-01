// List Notification Service
//
// Phase 2.2: Push Notifications for Suggested Lists
//
// Purpose: Notify users when new AI-suggested lists are generated

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:avrai_runtime_os/ai/perpetual_list/models/models.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:get_it/get_it.dart';

// Optional FCM import (graceful degradation if not available)
import 'package:firebase_messaging/firebase_messaging.dart' as fcm;

/// List notification type
enum ListNotificationType {
  /// New suggested lists available
  newSuggestions,

  /// Reminder about unseen suggestions
  reminderUnseen,

  /// List saved confirmation
  listSaved,

  /// Place visited from list
  placeVisited,
}

/// List Notification Service
///
/// **Purpose:** Send notifications when AI generates new list suggestions
///
/// **Notification Types:**
/// - New suggestions available
/// - Reminder about unseen suggestions
/// - List saved confirmation
/// - Place visited acknowledgment
///
/// **Offline-First:** Uses local notifications as fallback when FCM unavailable
///
/// Part of Phase 2.2: Push Notifications

class ListNotificationService {
  static const String _logName = 'ListNotificationService';

  /// Notification channel IDs
  static const String _channelId = 'suggested_lists';
  static const String _channelName = 'Suggested Lists';
  static const String _channelDescription = 'AI-suggested list notifications';

  /// Preference keys
  static const String _prefsEnabledKey = 'list_notif_enabled';
  static const String _prefsSoundKey = 'list_notif_sound';
  static const String _prefsVibrationKey = 'list_notif_vibration';
  static const String _fcmTokenKey = 'list_notif_fcm_token';

  final StorageService _storageService;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _localNotificationsInitialized = false;

  // Optional FCM (Firebase Cloud Messaging) for push notifications
  fcm.FirebaseMessaging? _firebaseMessaging;
  String? _fcmToken;
  bool _fcmInitialized = false;
  bool _userOptedIntoPush = true; // Default to true, user can disable

  // Notification preferences
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  // Initialization state
  bool _initialized = false;
  final bool _enableFCM;

  ListNotificationService({
    StorageService? storageService,
    bool enableFCM = true,
  })  : _storageService = storageService ?? GetIt.instance<StorageService>(),
        _enableFCM = enableFCM;

  /// Initialize the notification service
  ///
  /// Must be called before sending notifications.
  /// Safe to call multiple times - subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_initialized) return;

    await _initializeLocalNotifications();
    if (_enableFCM) {
      await _initializeFCM();
    }
    await _loadPreferences();

    _initialized = true;
    developer.log('ListNotificationService initialized', name: _logName);
  }

  /// Check if service is initialized
  bool get isInitialized => _initialized;

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final result = await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _localNotificationsInitialized = result ?? false;
      developer.log(
        'Local notifications initialized: $_localNotificationsInitialized',
        name: _logName,
      );
    } catch (e) {
      developer.log(
        'Error initializing local notifications: $e',
        name: _logName,
      );
    }
  }

  /// Initialize FCM (Firebase Cloud Messaging)
  Future<void> _initializeFCM() async {
    if (_fcmInitialized) return;

    try {
      _firebaseMessaging = fcm.FirebaseMessaging.instance;

      // Request permission
      final settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == fcm.AuthorizationStatus.authorized ||
          settings.authorizationStatus == fcm.AuthorizationStatus.provisional) {
        _userOptedIntoPush = true;

        // Get FCM token
        _fcmToken = await _firebaseMessaging!.getToken();
        if (_fcmToken != null) {
          await _persistFcmToken(_fcmToken!);
          developer.log('FCM token obtained: ${_fcmToken?.substring(0, 20)}...',
              name: _logName);
        }

        // Listen for token refresh
        _firebaseMessaging!.onTokenRefresh.listen((token) async {
          _fcmToken = token;
          await _persistFcmToken(token);
          developer.log('FCM token refreshed', name: _logName);
        });

        // Handle foreground messages
        fcm.FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        _fcmInitialized = true;
        developer.log('FCM initialized successfully', name: _logName);
      } else {
        _userOptedIntoPush = false;
        developer.log('User declined push notifications', name: _logName);
      }
    } catch (e) {
      developer.log('Error initializing FCM: $e', name: _logName);
    }
  }

  /// Load notification preferences from storage
  Future<void> _loadPreferences() async {
    try {
      _notificationsEnabled = _storageService.getBool(_prefsEnabledKey) ?? true;
      _soundEnabled = _storageService.getBool(_prefsSoundKey) ?? true;
      _vibrationEnabled = _storageService.getBool(_prefsVibrationKey) ?? true;

      // Load persisted FCM token
      final savedToken = _storageService.getString(_fcmTokenKey);
      if (savedToken != null && _fcmToken == null) {
        _fcmToken = savedToken;
      }
    } catch (e) {
      developer.log('Error loading notification preferences: $e',
          name: _logName);
    }
  }

  /// Persist FCM token locally
  ///
  /// TODO(Phase 2.2): Also sync token to backend for server-side push
  /// See docs/plans/perpetual_list/push_notification_backend.md
  Future<void> _persistFcmToken(String token) async {
    try {
      await _storageService.setString(_fcmTokenKey, token);
      developer.log('FCM token persisted', name: _logName);
    } catch (e) {
      developer.log('Error persisting FCM token: $e', name: _logName);
    }
  }

  /// Save notification preferences
  Future<void> savePreferences({
    bool? enabled,
    bool? sound,
    bool? vibration,
  }) async {
    try {
      if (enabled != null) {
        _notificationsEnabled = enabled;
        await _storageService.setBool(_prefsEnabledKey, enabled);
      }
      if (sound != null) {
        _soundEnabled = sound;
        await _storageService.setBool(_prefsSoundKey, sound);
      }
      if (vibration != null) {
        _vibrationEnabled = vibration;
        await _storageService.setBool(_prefsVibrationKey, vibration);
      }

      developer.log('Notification preferences saved', name: _logName);
    } catch (e) {
      developer.log('Error saving notification preferences: $e',
          name: _logName);
    }
  }

  /// Notify user about new suggested lists
  Future<void> notifyNewSuggestions({
    required List<SuggestedList> lists,
    required String userId,
  }) async {
    if (!_initialized) await initialize();
    if (!_notificationsEnabled || lists.isEmpty) return;

    developer.log(
      'Sending notification for ${lists.length} new suggestions',
      name: _logName,
    );

    final title = lists.length == 1
        ? 'New List Suggestion'
        : '${lists.length} New List Suggestions';

    final body = lists.length == 1
        ? lists.first.title
        : 'Check out ${lists.first.title} and more!';

    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: 'suggested_lists:${lists.map((l) => l.id).join(',')}',
      type: ListNotificationType.newSuggestions,
    );
  }

  /// Notify about unseen suggestions (reminder)
  Future<void> notifyUnseenSuggestions({
    required int count,
    required String userId,
  }) async {
    if (!_notificationsEnabled || count == 0) return;

    await _showNotification(
      id: 'unseen_reminder'.hashCode,
      title: 'Don\'t miss out!',
      body: 'You have $count personalized list suggestions waiting for you.',
      payload: 'suggested_lists:all',
      type: ListNotificationType.reminderUnseen,
    );
  }

  /// Notify that a list was saved
  Future<void> notifyListSaved({
    required SuggestedList list,
    required String userId,
  }) async {
    if (!_notificationsEnabled) return;

    await _showNotification(
      id: list.id.hashCode,
      title: 'List Saved!',
      body: '"${list.title}" has been added to your collection.',
      payload: 'list_saved:${list.id}',
      type: ListNotificationType.listSaved,
    );
  }

  /// Show a notification (local fallback if FCM unavailable)
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    required ListNotificationType type,
  }) async {
    if (!_localNotificationsInitialized) {
      await _initializeLocalNotifications();
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: _vibrationEnabled,
        playSound: _soundEnabled,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );

      developer.log(
        'Notification shown: $title (type: ${type.name})',
        name: _logName,
      );
    } catch (e) {
      developer.log('Error showing notification: $e', name: _logName);
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    developer.log('Notification tapped: $payload', name: _logName);

    // Parse payload and navigate
    if (payload != null) {
      final parts = payload.split(':');
      if (parts.length >= 2) {
        final type = parts[0];
        final data = parts.sublist(1).join(':');

        switch (type) {
          case 'suggested_lists':
            _navigateToSuggestedLists(data);
            break;
          case 'list_saved':
            _navigateToSavedList(data);
            break;
        }
      }
    }
  }

  /// Handle foreground FCM message
  void _handleForegroundMessage(fcm.RemoteMessage message) {
    developer.log(
      'Received foreground FCM message: ${message.notification?.title}',
      name: _logName,
    );

    // Show as local notification when in foreground
    final notification = message.notification;
    if (notification != null) {
      _showNotification(
        id: message.hashCode,
        title: notification.title ?? 'avrai',
        body: notification.body ?? '',
        payload: 'fcm:${message.data}',
        type: ListNotificationType.newSuggestions,
      );
    }
  }

  /// Navigate to suggested lists page
  void _navigateToSuggestedLists(String listIds) {
    // TODO(Phase 2.2): Implement navigation via GoRouter
    developer.log('Navigate to suggested lists: $listIds', name: _logName);
  }

  /// Navigate to saved list
  void _navigateToSavedList(String listId) {
    // TODO(Phase 2.2): Implement navigation via GoRouter
    developer.log('Navigate to saved list: $listId', name: _logName);
  }

  /// Check if notifications are enabled
  bool get isEnabled => _notificationsEnabled;

  /// Check if FCM is available
  bool get hasFCM => _fcmInitialized;

  /// Check if user opted into push notifications
  bool get userOptedIn => _userOptedIntoPush;

  /// Get FCM token for server registration
  String? get fcmToken => _fcmToken;

  /// Dispose resources
  void dispose() {
    // Cleanup if needed
  }
}
