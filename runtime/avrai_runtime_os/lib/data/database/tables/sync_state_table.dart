import 'package:drift/drift.dart';

/// Sync state table for Drift database
///
/// Tracks cross-device sync state for various data types.
///
/// Phase 26: Multi-Device Storage Migration
@TableIndex(name: 'idx_sync_entity', columns: {#entityType, #entityId})
@TableIndex(name: 'idx_sync_pending', columns: {#syncStatus})
class SyncState extends Table {
  /// Auto-incrementing ID
  IntColumn get id => integer().autoIncrement()();

  /// Entity type (message, spot, list, preference, etc.)
  TextColumn get entityType => text()();

  /// Entity ID
  TextColumn get entityId => text()();

  /// Sync status (pending, synced, conflict, failed)
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  /// Local version number
  IntColumn get localVersion => integer().withDefault(const Constant(1))();

  /// Remote version number
  IntColumn get remoteVersion => integer().nullable()();

  /// When entity was locally modified
  DateTimeColumn get localModifiedAt => dateTime()();

  /// When entity was synced to cloud
  DateTimeColumn get cloudSyncedAt => dateTime().nullable()();

  /// When sync was broadcast to other devices
  DateTimeColumn get deviceSyncedAt => dateTime().nullable()();

  /// Device ID that made the last change
  TextColumn get lastModifiedByDevice => text().nullable()();

  /// Conflict resolution strategy applied
  TextColumn get conflictResolution => text().nullable()();

  /// Hash of entity content for change detection
  TextColumn get contentHash => text().nullable()();
}

/// Pending sync operations queue
@TableIndex(name: 'idx_sync_queue_status', columns: {#status})
@TableIndex(name: 'idx_sync_queue_priority', columns: {#priority, #createdAt})
class SyncQueue extends Table {
  /// Auto-incrementing ID
  IntColumn get id => integer().autoIncrement()();

  /// Operation type (create, update, delete, sync_read)
  TextColumn get operationType => text()();

  /// Entity type
  TextColumn get entityType => text()();

  /// Entity ID
  TextColumn get entityId => text()();

  /// Payload as JSON
  TextColumn get payload => text()();

  /// Priority (higher = more urgent)
  IntColumn get priority => integer().withDefault(const Constant(0))();

  /// Queue status (pending, processing, completed, failed)
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Retry count
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Max retries before giving up
  IntColumn get maxRetries => integer().withDefault(const Constant(3))();

  /// Last error message
  TextColumn get lastError => text().nullable()();

  /// When operation was queued
  DateTimeColumn get createdAt => dateTime()();

  /// When operation was last attempted
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  /// When operation completed
  DateTimeColumn get completedAt => dateTime().nullable()();
}
