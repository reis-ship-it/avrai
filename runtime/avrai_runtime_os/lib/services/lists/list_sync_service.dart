// List Sync Service
//
// Phase 5.6: Cross-device sync for suggested lists
//
// Purpose: Sync list state across user's devices

import 'dart:developer' as developer;
import 'dart:convert';

import 'package:avrai_runtime_os/ai/perpetual_list/models/models.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:get_it/get_it.dart';

/// List Sync Service
///
/// Synchronizes suggested list state across devices.
/// Handles conflict resolution and offline-first operations.
///
/// Part of Phase 5.6: Cross-Device Sync

class ListSyncService {
  static const String _logName = 'ListSyncService';
  static const String _localStorageKey = 'synced_lists';
  static const String _lastSyncKey = 'last_list_sync';
  static const String _pendingOpsKey = 'pending_sync_operations';
  static const String _tableName = 'user_suggested_lists';

  final SupabaseService _supabaseService;
  final StorageService _storageService;

  /// Pending sync operations (for offline handling)
  final List<SyncOperation> _pendingOperations = [];

  /// Whether pending operations have been loaded from storage
  bool _pendingOpsLoaded = false;

  ListSyncService({
    SupabaseService? supabaseService,
    StorageService? storageService,
  })  : _supabaseService = supabaseService ?? GetIt.instance<SupabaseService>(),
        _storageService = storageService ?? GetIt.instance<StorageService>();

  /// Initialize service and load pending operations
  Future<void> initialize() async {
    await _loadPendingOperations();
  }

  /// Sync lists from server
  Future<List<SuggestedListState>> syncFromServer({
    required String userId,
  }) async {
    // Ensure pending ops are loaded
    if (!_pendingOpsLoaded) {
      await _loadPendingOperations();
    }

    try {
      developer.log('Syncing lists from server for user: $userId',
          name: _logName);

      final lastSync = await _getLastSyncTime();

      // Fetch updated lists from server
      final response = await _supabaseService.client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .gt('updated_at', lastSync?.toIso8601String() ?? '1970-01-01')
          .order('updated_at', ascending: false);

      // Parse server lists (response is always List from Supabase select())
      final serverLists = (response as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((json) => SuggestedListState.fromJson(json))
          .toList();

      // Merge with local lists
      final localLists = await _getLocalLists(userId);
      final mergedLists = _mergeLists(localLists, serverLists);

      // Save merged lists locally
      await _saveLocalLists(userId, mergedLists);

      // Update last sync time
      await _setLastSyncTime(DateTime.now());

      // Process pending operations
      await _processPendingOperations();

      developer.log(
        'Synced ${serverLists.length} lists from server',
        name: _logName,
      );

      return mergedLists;
    } catch (e, stackTrace) {
      developer.log(
        'Error syncing from server',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      // Return local lists on error
      return await _getLocalLists(userId);
    }
  }

  /// Sync a list state change to server
  Future<void> syncListState({
    required String userId,
    required String listId,
    required SuggestedListState state,
  }) async {
    try {
      developer.log('Syncing list state: $listId', name: _logName);

      // Save locally first
      await _saveLocalListState(userId, state);

      // Try to sync to server
      await _supabaseService.client.from(_tableName).upsert({
        'user_id': userId,
        'list_id': listId,
        'is_saved': state.isSaved,
        'is_dismissed': state.isDismissed,
        'is_pinned': state.isPinned,
        'interactions': state.interactions.map((i) => i.toJson()).toList(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      developer.log('List state synced to server', name: _logName);
    } catch (e) {
      developer.log('Error syncing to server, queuing operation: $e',
          name: _logName);

      // Queue for later sync (persisted to survive app restart)
      _pendingOperations.add(SyncOperation(
        type: SyncOperationType.update,
        userId: userId,
        listId: listId,
        state: state,
        timestamp: DateTime.now(),
      ));
      await _savePendingOperations();
    }
  }

  /// Mark a list as saved
  Future<void> markListSaved({
    required String userId,
    required String listId,
    required bool isSaved,
  }) async {
    final currentState = await _getLocalListState(userId, listId);
    final newState = currentState?.copyWith(isSaved: isSaved) ??
        SuggestedListState(
          listId: listId,
          isSaved: isSaved,
          isDismissed: false,
          isPinned: false,
          interactions: [],
        );

    await syncListState(userId: userId, listId: listId, state: newState);
  }

  /// Mark a list as dismissed
  Future<void> markListDismissed({
    required String userId,
    required String listId,
  }) async {
    final currentState = await _getLocalListState(userId, listId);
    final newState = currentState?.copyWith(isDismissed: true) ??
        SuggestedListState(
          listId: listId,
          isSaved: false,
          isDismissed: true,
          isPinned: false,
          interactions: [],
        );

    await syncListState(userId: userId, listId: listId, state: newState);
  }

  /// Mark a list as pinned
  Future<void> markListPinned({
    required String userId,
    required String listId,
    required bool isPinned,
  }) async {
    final currentState = await _getLocalListState(userId, listId);
    final newState = currentState?.copyWith(isPinned: isPinned) ??
        SuggestedListState(
          listId: listId,
          isSaved: false,
          isDismissed: false,
          isPinned: isPinned,
          interactions: [],
        );

    await syncListState(userId: userId, listId: listId, state: newState);
  }

  /// Record an interaction with a list
  Future<void> recordInteraction({
    required String userId,
    required String listId,
    required ListInteraction interaction,
  }) async {
    final currentState = await _getLocalListState(userId, listId);
    final interactions = List<ListInteraction>.from(
      currentState?.interactions ?? [],
    )..add(interaction);

    final newState = currentState?.copyWith(interactions: interactions) ??
        SuggestedListState(
          listId: listId,
          isSaved: false,
          isDismissed: false,
          isPinned: false,
          interactions: interactions,
        );

    await syncListState(userId: userId, listId: listId, state: newState);
  }

  /// Get local lists for a user
  Future<List<SuggestedListState>> _getLocalLists(String userId) async {
    try {
      final key = '$_localStorageKey:$userId';
      final json = _storageService.getString(key);
      if (json == null) return [];

      final list = jsonDecode(json) as List;
      return list
          .map((j) => SuggestedListState.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save local lists
  Future<void> _saveLocalLists(
    String userId,
    List<SuggestedListState> lists,
  ) async {
    try {
      final key = '$_localStorageKey:$userId';
      final json = jsonEncode(lists.map((l) => l.toJson()).toList());
      await _storageService.setString(key, json);
    } catch (e) {
      developer.log('Error saving local lists: $e', name: _logName);
    }
  }

  /// Get local list state
  Future<SuggestedListState?> _getLocalListState(
    String userId,
    String listId,
  ) async {
    final lists = await _getLocalLists(userId);
    return lists.where((l) => l.listId == listId).firstOrNull;
  }

  /// Save local list state
  Future<void> _saveLocalListState(
    String userId,
    SuggestedListState state,
  ) async {
    final lists = await _getLocalLists(userId);
    final index = lists.indexWhere((l) => l.listId == state.listId);

    if (index >= 0) {
      lists[index] = state;
    } else {
      lists.add(state);
    }

    await _saveLocalLists(userId, lists);
  }

  /// Merge local and server lists (server wins on conflict)
  List<SuggestedListState> _mergeLists(
    List<SuggestedListState> local,
    List<SuggestedListState> server,
  ) {
    final merged = <String, SuggestedListState>{};

    // Add all local lists
    for (final list in local) {
      merged[list.listId] = list;
    }

    // Server lists override local (last-write-wins)
    for (final list in server) {
      merged[list.listId] = list;
    }

    return merged.values.toList();
  }

  /// Get last sync time
  Future<DateTime?> _getLastSyncTime() async {
    final timestamp = _storageService.getString(_lastSyncKey);
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  /// Set last sync time
  Future<void> _setLastSyncTime(DateTime time) async {
    await _storageService.setString(_lastSyncKey, time.toIso8601String());
  }

  /// Process pending sync operations
  Future<void> _processPendingOperations() async {
    if (_pendingOperations.isEmpty) return;

    developer.log(
      'Processing ${_pendingOperations.length} pending operations',
      name: _logName,
    );

    final operations = List<SyncOperation>.from(_pendingOperations);
    _pendingOperations.clear();
    await _savePendingOperations(); // Persist cleared state

    for (final op in operations) {
      try {
        await _supabaseService.client.from(_tableName).upsert({
          'user_id': op.userId,
          'list_id': op.listId,
          'is_saved': op.state.isSaved,
          'is_dismissed': op.state.isDismissed,
          'is_pinned': op.state.isPinned,
          'interactions': op.state.interactions.map((i) => i.toJson()).toList(),
          'updated_at': op.timestamp.toIso8601String(),
        });
      } catch (e) {
        developer.log('Failed to process pending operation: $e',
            name: _logName);
        _pendingOperations.add(op);
        await _savePendingOperations(); // Persist failed operation
      }
    }
  }

  /// Load pending operations from storage (survives app restart)
  Future<void> _loadPendingOperations() async {
    if (_pendingOpsLoaded) return;

    try {
      final json = _storageService.getString(_pendingOpsKey);
      if (json != null) {
        final list = jsonDecode(json) as List;
        _pendingOperations.addAll(
          list.map((j) => SyncOperation.fromJson(j as Map<String, dynamic>)),
        );
        developer.log(
          'Loaded ${_pendingOperations.length} pending operations from storage',
          name: _logName,
        );
      }
    } catch (e) {
      developer.log('Error loading pending operations: $e', name: _logName);
    }
    _pendingOpsLoaded = true;
  }

  /// Save pending operations to storage
  Future<void> _savePendingOperations() async {
    try {
      final json = jsonEncode(
        _pendingOperations.map((op) => op.toJson()).toList(),
      );
      await _storageService.setString(_pendingOpsKey, json);
    } catch (e) {
      developer.log('Error saving pending operations: $e', name: _logName);
    }
  }
}

/// Suggested list state (synced across devices)
class SuggestedListState {
  final String listId;
  final bool isSaved;
  final bool isDismissed;
  final bool isPinned;
  final List<ListInteraction> interactions;

  const SuggestedListState({
    required this.listId,
    required this.isSaved,
    required this.isDismissed,
    required this.isPinned,
    required this.interactions,
  });

  SuggestedListState copyWith({
    bool? isSaved,
    bool? isDismissed,
    bool? isPinned,
    List<ListInteraction>? interactions,
  }) {
    return SuggestedListState(
      listId: listId,
      isSaved: isSaved ?? this.isSaved,
      isDismissed: isDismissed ?? this.isDismissed,
      isPinned: isPinned ?? this.isPinned,
      interactions: interactions ?? this.interactions,
    );
  }

  Map<String, dynamic> toJson() => {
        'list_id': listId,
        'is_saved': isSaved,
        'is_dismissed': isDismissed,
        'is_pinned': isPinned,
        'interactions': interactions.map((i) => i.toJson()).toList(),
      };

  factory SuggestedListState.fromJson(Map<String, dynamic> json) {
    return SuggestedListState(
      listId: json['list_id'] as String,
      isSaved: json['is_saved'] as bool? ?? false,
      isDismissed: json['is_dismissed'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      interactions: (json['interactions'] as List?)
              ?.map((i) => ListInteraction.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Sync operation type
enum SyncOperationType { create, update, delete }

/// Pending sync operation
class SyncOperation {
  final SyncOperationType type;
  final String userId;
  final String listId;
  final SuggestedListState state;
  final DateTime timestamp;

  const SyncOperation({
    required this.type,
    required this.userId,
    required this.listId,
    required this.state,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'user_id': userId,
        'list_id': listId,
        'state': state.toJson(),
        'timestamp': timestamp.toIso8601String(),
      };

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      type: SyncOperationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => SyncOperationType.update,
      ),
      userId: json['user_id'] as String,
      listId: json['list_id'] as String,
      state: SuggestedListState.fromJson(json['state'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
