import 'package:drift/drift.dart';

/// Transfer progress table for Drift database
///
/// Tracks history transfer progress between devices for resume support.
///
/// Phase 26: Multi-Device Storage Migration
@TableIndex(name: 'idx_transfer_status', columns: {#status})
@TableIndex(
    name: 'idx_transfer_devices', columns: {#sourceDeviceId, #targetDeviceId})
class TransferProgress extends Table {
  /// Unique transfer session identifier
  TextColumn get transferId => text()();

  /// Source device ID (sending history)
  TextColumn get sourceDeviceId => text()();

  /// Target device ID (receiving history)
  TextColumn get targetDeviceId => text()();

  /// Transfer type (messages, spots, lists, all)
  TextColumn get transferType => text()();

  /// Last successfully transferred chunk index
  IntColumn get lastChunkIndex => integer().withDefault(const Constant(-1))();

  /// Total chunks expected
  IntColumn get totalChunks => integer().nullable()();

  /// Total messages/items transferred
  IntColumn get itemsTransferred => integer().withDefault(const Constant(0))();

  /// Total items expected
  IntColumn get totalItems => integer().nullable()();

  /// Bytes transferred
  IntColumn get bytesTransferred => integer().withDefault(const Constant(0))();

  /// Transfer status (in_progress, completed, failed, paused)
  TextColumn get status => text().withDefault(const Constant('in_progress'))();

  /// Error message if failed
  TextColumn get errorMessage => text().nullable()();

  /// When transfer started
  DateTimeColumn get startedAt => dateTime()();

  /// Last activity timestamp
  DateTimeColumn get lastUpdateAt => dateTime()();

  /// When transfer completed
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Shared secret hash for verification
  TextColumn get sharedSecretHash => text().nullable()();

  @override
  Set<Column> get primaryKey => {transferId};
}
