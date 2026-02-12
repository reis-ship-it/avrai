import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sync_status.g.dart';

/// Synchronization status for offline-first functionality
@JsonSerializable()
class SyncStatus extends Equatable {
  final String entityId;
  final String entityType;
  final SyncState state;
  final DateTime lastSyncAttempt;
  final DateTime? lastSuccessfulSync;
  final String? error;
  final int retryCount;
  final Map<String, dynamic> pendingChanges;
  
  const SyncStatus({
    required this.entityId,
    required this.entityType,
    required this.state,
    required this.lastSyncAttempt,
    this.lastSuccessfulSync,
    this.error,
    this.retryCount = 0,
    this.pendingChanges = const {},
  });
  
  /// Create initial pending sync status
  factory SyncStatus.pending(String entityId, String entityType) {
    return SyncStatus(
      entityId: entityId,
      entityType: entityType,
      state: SyncState.pending,
      lastSyncAttempt: DateTime.now(),
    );
  }
  
  /// Create syncing status
  SyncStatus startSync() {
    return copyWith(
      state: SyncState.syncing,
      lastSyncAttempt: DateTime.now(),
    );
  }
  
  /// Create successful sync status
  SyncStatus syncSuccess() {
    return copyWith(
      state: SyncState.synced,
      lastSuccessfulSync: DateTime.now(),
      error: null,
      retryCount: 0,
      pendingChanges: {},
    );
  }
  
  /// Create failed sync status
  SyncStatus syncFailed(String error) {
    return copyWith(
      state: SyncState.failed,
      error: error,
      retryCount: retryCount + 1,
    );
  }
  
  /// Create conflict status
  SyncStatus syncConflict(Map<String, dynamic> conflictData) {
    return copyWith(
      state: SyncState.conflict,
      pendingChanges: conflictData,
    );
  }
  
  /// Check if sync is needed
  bool get needsSync => state != SyncState.synced;
  
  /// Check if currently syncing
  bool get isSyncing => state == SyncState.syncing;
  
  /// Check if sync failed
  bool get hasFailed => state == SyncState.failed;
  
  /// Check if there's a conflict
  bool get hasConflict => state == SyncState.conflict;
  
  /// Check if should retry sync
  bool get shouldRetry => hasFailed && retryCount < 3;
  
  /// Get time since last sync attempt
  Duration get timeSinceLastAttempt => DateTime.now().difference(lastSyncAttempt);
  
  /// Get time since last successful sync
  Duration? get timeSinceLastSuccess => lastSuccessfulSync != null
      ? DateTime.now().difference(lastSuccessfulSync!)
      : null;
  
  factory SyncStatus.fromJson(Map<String, dynamic> json) =>
      _$SyncStatusFromJson(json);
  Map<String, dynamic> toJson() => _$SyncStatusToJson(this);
  
  SyncStatus copyWith({
    String? entityId,
    String? entityType,
    SyncState? state,
    DateTime? lastSyncAttempt,
    DateTime? lastSuccessfulSync,
    String? error,
    int? retryCount,
    Map<String, dynamic>? pendingChanges,
  }) {
    return SyncStatus(
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      state: state ?? this.state,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      lastSuccessfulSync: lastSuccessfulSync ?? this.lastSuccessfulSync,
      error: error,
      retryCount: retryCount ?? this.retryCount,
      pendingChanges: pendingChanges ?? this.pendingChanges,
    );
  }
  
  @override
  List<Object?> get props => [
    entityId, entityType, state, lastSyncAttempt, lastSuccessfulSync,
    error, retryCount, pendingChanges,
  ];
}

/// Synchronization states
enum SyncState {
  pending,   // Waiting to be synced
  syncing,   // Currently syncing
  synced,    // Successfully synced
  failed,    // Sync failed
  conflict,  // Sync conflict needs resolution
}

extension SyncStateExtension on SyncState {
  String get displayName {
    switch (this) {
      case SyncState.pending:
        return 'Pending';
      case SyncState.syncing:
        return 'Syncing';
      case SyncState.synced:
        return 'Synced';
      case SyncState.failed:
        return 'Failed';
      case SyncState.conflict:
        return 'Conflict';
    }
  }
  
  String get description {
    switch (this) {
      case SyncState.pending:
        return 'Waiting to sync with server';
      case SyncState.syncing:
        return 'Syncing with server';
      case SyncState.synced:
        return 'Up to date with server';
      case SyncState.failed:
        return 'Failed to sync with server';
      case SyncState.conflict:
        return 'Conflict detected, manual resolution needed';
    }
  }
  
  bool get isActive => this == SyncState.pending || this == SyncState.syncing;
  bool get isComplete => this == SyncState.synced;
  bool get hasIssue => this == SyncState.failed || this == SyncState.conflict;
}

/// Sync queue manager for handling offline operations
@JsonSerializable()
class SyncQueue extends Equatable {
  final List<SyncOperation> operations;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const SyncQueue({
    required this.operations,
    required this.createdAt,
    required this.updatedAt,
  });
  
  /// Create empty sync queue
  factory SyncQueue.empty() {
    final now = DateTime.now();
    return SyncQueue(
      operations: const [],
      createdAt: now,
      updatedAt: now,
    );
  }
  
  /// Add operation to queue
  SyncQueue addOperation(SyncOperation operation) {
    return copyWith(
      operations: [...operations, operation],
      updatedAt: DateTime.now(),
    );
  }
  
  /// Remove operation from queue
  SyncQueue removeOperation(String operationId) {
    return copyWith(
      operations: operations.where((op) => op.id != operationId).toList(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Get pending operations
  List<SyncOperation> get pendingOperations =>
      operations.where((op) => op.status.needsSync).toList();
  
  /// Check if queue is empty
  bool get isEmpty => operations.isEmpty;
  
  /// Check if has pending operations
  bool get hasPending => pendingOperations.isNotEmpty;
  
  factory SyncQueue.fromJson(Map<String, dynamic> json) =>
      _$SyncQueueFromJson(json);
  Map<String, dynamic> toJson() => _$SyncQueueToJson(this);
  
  SyncQueue copyWith({
    List<SyncOperation>? operations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SyncQueue(
      operations: operations ?? this.operations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  List<Object?> get props => [operations, createdAt, updatedAt];
}

/// Individual sync operation
@JsonSerializable()
class SyncOperation extends Equatable {
  final String id;
  final String entityId;
  final String entityType;
  final SyncOperationType type;
  final Map<String, dynamic> data;
  final SyncStatus status;
  final DateTime createdAt;
  
  const SyncOperation({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.type,
    required this.data,
    required this.status,
    required this.createdAt,
  });
  
  factory SyncOperation.fromJson(Map<String, dynamic> json) =>
      _$SyncOperationFromJson(json);
  Map<String, dynamic> toJson() => _$SyncOperationToJson(this);
  
  @override
  List<Object?> get props => [
    id, entityId, entityType, type, data, status, createdAt,
  ];
}

/// Types of sync operations
enum SyncOperationType {
  create,
  update,
  delete,
}

extension SyncOperationTypeExtension on SyncOperationType {
  String get name {
    switch (this) {
      case SyncOperationType.create:
        return 'create';
      case SyncOperationType.update:
        return 'update';
      case SyncOperationType.delete:
        return 'delete';
    }
  }
}
