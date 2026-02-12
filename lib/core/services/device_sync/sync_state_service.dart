import 'dart:async';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:avrai/core/crypto/signal/device_registration_service.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/data/database/app_database.dart';

/// Sync State Service
///
/// Broadcasts state changes (read receipts, typing indicators, drafts)
/// to all of a user's devices in real-time.
///
/// Phase 26: Multi-Device Sync - State Broadcasting
///
/// **Supported State Types:**
/// - `read_receipt`: Message marked as read
/// - `typing`: User is typing in a chat
/// - `draft`: Draft message saved
/// - `presence`: Device online/offline status
/// - `notification_read`: Notification dismissed
class SyncStateService {
  static const String _logName = 'SyncStateService';
  static const String _userSyncChannelPrefix = 'user_sync:';
  // ignore: unused_field - Phase 26: sync state persistence to Supabase table
  static const String _syncStateTable = 'device_sync_state';

  final SupabaseService _supabaseService;
  final DeviceRegistrationService _deviceRegistrationService;
  final AppDatabase? _database;

  // Realtime subscription
  RealtimeChannel? _syncChannel;
  String? _currentUserId;

  // Callbacks for state changes
  void Function(SyncStateEvent)? onStateReceived;
  void Function(List<String> messageIds)? onMessagesRead;
  void Function(String chatId, bool isTyping)? onTypingIndicator;

  SyncStateService({
    required SupabaseService supabaseService,
    required DeviceRegistrationService deviceRegistrationService,
    AppDatabase? database,
  })  : _supabaseService = supabaseService,
        _deviceRegistrationService = deviceRegistrationService,
        _database = database;

  /// Start listening for state sync events
  Future<void> startListening(String userId) async {
    _currentUserId = userId;
    final channel = '$_userSyncChannelPrefix$userId';

    _syncChannel = _supabaseService.client
        .channel(channel)
        .onBroadcast(
          event: 'sync_state',
          callback: (payload) {
            _handleSyncEvent(payload);
          },
        )
        .subscribe();

    developer.log('Started listening for sync events: $channel', name: _logName);
  }

  /// Stop listening for state sync events
  Future<void> stopListening() async {
    await _syncChannel?.unsubscribe();
    _syncChannel = null;
    _currentUserId = null;
  }

  /// Broadcast a state change to all devices
  Future<void> broadcastState(SyncStateEvent event) async {
    if (_currentUserId == null) return;

    final channel = '$_userSyncChannelPrefix$_currentUserId';
    final currentDevice = _deviceRegistrationService.currentDevice;

    try {
      await _supabaseService.client.channel(channel).sendBroadcastMessage(
        event: 'sync_state',
        payload: {
          ...event.toJson(),
          'source_device_id': currentDevice?.deviceId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      developer.log(
        'Broadcast ${event.type.name} to all devices',
        name: _logName,
      );
    } catch (e) {
      developer.log('Failed to broadcast state: $e', name: _logName);
    }
  }

  /// Mark messages as read and sync across devices
  Future<void> markMessagesRead(List<String> messageIds) async {
    if (messageIds.isEmpty) return;

    // Update local database
    if (_database != null) {
      await _database.markMessagesAsRead(messageIds);
    }

    // Broadcast to other devices
    await broadcastState(SyncStateEvent(
      type: SyncStateType.readReceipt,
      data: {'message_ids': messageIds},
    ));
  }

  /// Send typing indicator
  Future<void> sendTypingIndicator({
    required String chatId,
    required bool isTyping,
  }) async {
    await broadcastState(SyncStateEvent(
      type: SyncStateType.typing,
      data: {
        'chat_id': chatId,
        'is_typing': isTyping,
      },
    ));
  }

  /// Save and sync draft message
  Future<void> syncDraft({
    required String chatId,
    required String content,
  }) async {
    await broadcastState(SyncStateEvent(
      type: SyncStateType.draft,
      data: {
        'chat_id': chatId,
        'content': content,
      },
    ));
  }

  /// Update presence status
  Future<void> updatePresence(bool isOnline) async {
    await broadcastState(SyncStateEvent(
      type: SyncStateType.presence,
      data: {
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      },
    ));
  }

  /// Handle incoming sync event
  void _handleSyncEvent(Map<String, dynamic> payload) {
    try {
      final currentDeviceId = _deviceRegistrationService.currentDevice?.deviceId;
      final sourceDeviceIdRaw = payload['source_device_id'];
      final sourceDeviceId = sourceDeviceIdRaw is int
          ? sourceDeviceIdRaw.toString()
          : sourceDeviceIdRaw as String?;

      // Ignore events from self
      if (sourceDeviceId != null &&
          currentDeviceId != null &&
          sourceDeviceId == currentDeviceId.toString()) {
        return;
      }

      final event = SyncStateEvent.fromJson(payload);

      developer.log(
        'Received ${event.type.name} from device: $sourceDeviceId',
        name: _logName,
      );

      // Notify callback
      onStateReceived?.call(event);

      // Handle specific event types
      switch (event.type) {
        case SyncStateType.readReceipt:
          _handleReadReceipt(event);
          break;
        case SyncStateType.typing:
          _handleTypingIndicator(event);
          break;
        case SyncStateType.draft:
          _handleDraftSync(event);
          break;
        case SyncStateType.presence:
          _handlePresenceUpdate(event);
          break;
        case SyncStateType.notificationRead:
          _handleNotificationRead(event);
          break;
      }
    } catch (e) {
      developer.log('Failed to handle sync event: $e', name: _logName);
    }
  }

  void _handleReadReceipt(SyncStateEvent event) {
    final messageIds = (event.data['message_ids'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    if (messageIds.isEmpty) return;

    // Update local database
    _database?.markMessagesAsRead(messageIds);

    // Notify callback
    onMessagesRead?.call(messageIds);
  }

  void _handleTypingIndicator(SyncStateEvent event) {
    final chatId = event.data['chat_id'] as String?;
    final isTyping = event.data['is_typing'] as bool? ?? false;

    if (chatId != null) {
      onTypingIndicator?.call(chatId, isTyping);
    }
  }

  void _handleDraftSync(SyncStateEvent event) {
    // Could update local draft storage
    developer.log('Draft synced: ${event.data}', name: _logName);
  }

  void _handlePresenceUpdate(SyncStateEvent event) {
    // Could update device presence in UI
    developer.log('Presence updated: ${event.data}', name: _logName);
  }

  void _handleNotificationRead(SyncStateEvent event) {
    // Could dismiss notification on this device
    developer.log('Notification read: ${event.data}', name: _logName);
  }
}

/// Sync state event types
enum SyncStateType {
  readReceipt,
  typing,
  draft,
  presence,
  notificationRead,
}

/// Sync state event
class SyncStateEvent {
  final SyncStateType type;
  final Map<String, dynamic> data;
  final DateTime? timestamp;
  final String? sourceDeviceId;

  SyncStateEvent({
    required this.type,
    required this.data,
    this.timestamp,
    this.sourceDeviceId,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'data': data,
      };

  factory SyncStateEvent.fromJson(Map<String, dynamic> json) {
    return SyncStateEvent(
      type: SyncStateType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => SyncStateType.presence,
      ),
      data: json['data'] as Map<String, dynamic>? ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      sourceDeviceId: json['source_device_id'] as String?,
    );
  }
}
