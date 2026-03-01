import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/messages_table.dart';
import 'tables/spots_table.dart';
import 'tables/lists_table.dart';
import 'tables/users_table.dart';
import 'tables/linked_devices_table.dart';
import 'tables/transfer_progress_table.dart';
import 'tables/sync_state_table.dart';

part 'app_database.g.dart';

/// Main Drift database for AVRAI
///
/// Replaces Sembast for relational data storage with proper indexing,
/// efficient queries, and multi-device sync support.
///
/// Phase 26: Multi-Device Storage Migration
@DriftDatabase(tables: [
  Messages,
  Spots,
  SpotLists,
  ListSpots,
  Users,
  LinkedDevices,
  DeviceLinkRequests,
  TransferProgress,
  SyncState,
  SyncQueue,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for testing with custom executor
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future schema migrations here
      },
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ============================================================
  // MESSAGE OPERATIONS
  // ============================================================

  /// Insert or update a message
  Future<void> upsertMessage(MessagesCompanion message) async {
    await into(messages).insertOnConflictUpdate(message);
  }

  /// Get messages for a chat with pagination
  Future<List<Message>> getMessagesForChat(
    String chatId, {
    int limit = 50,
    int offset = 0,
  }) async {
    return (select(messages)
          ..where((m) => m.chatId.equals(chatId))
          ..orderBy([(m) => OrderingTerm.desc(m.timestamp)])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Get unread message count for a recipient
  Future<int> getUnreadCount(String recipientId) async {
    final result = await (selectOnly(messages)
          ..addColumns([messages.messageId.count()])
          ..where(messages.recipientId.equals(recipientId) &
              messages.isRead.equals(false)))
        .getSingle();
    return result.read(messages.messageId.count()) ?? 0;
  }

  /// Mark messages as read
  Future<int> markMessagesAsRead(List<String> messageIds) async {
    return (update(messages)..where((m) => m.messageId.isIn(messageIds)))
        .write(MessagesCompanion(
      isRead: const Value(true),
      readAt: Value(DateTime.now()),
    ));
  }

  /// Get messages needing sync
  Future<List<Message>> getUnsyncedMessages() async {
    return (select(messages)..where((m) => m.syncedAt.isNull())).get();
  }

  /// Stream messages for a chat (reactive updates)
  Stream<List<Message>> watchMessagesForChat(String chatId, {int limit = 50}) {
    return (select(messages)
          ..where((m) => m.chatId.equals(chatId))
          ..orderBy([(m) => OrderingTerm.desc(m.timestamp)])
          ..limit(limit))
        .watch();
  }

  // ============================================================
  // SPOT OPERATIONS
  // ============================================================

  /// Insert or update a spot
  Future<void> upsertSpot(SpotsCompanion spot) async {
    await into(spots).insertOnConflictUpdate(spot);
  }

  /// Get all spots
  Future<List<SpotData>> getAllSpots() async {
    return select(spots).get();
  }

  /// Get spot by ID
  Future<SpotData?> getSpotById(String id) async {
    return (select(spots)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  /// Get spots by category
  Future<List<SpotData>> getSpotsByCategory(String category) async {
    return (select(spots)..where((s) => s.category.equals(category))).get();
  }

  /// Search spots by name/description
  Future<List<SpotData>> searchSpots(String query) async {
    final pattern = '%$query%';
    return (select(spots)
          ..where((s) =>
              s.name.like(pattern) |
              s.description.like(pattern) |
              s.category.like(pattern)))
        .get();
  }

  /// Get spots within bounding box
  Future<List<SpotData>> getSpotsInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    return (select(spots)
          ..where((s) =>
              s.latitude.isBetweenValues(minLat, maxLat) &
              s.longitude.isBetweenValues(minLng, maxLng)))
        .get();
  }

  // ============================================================
  // LIST OPERATIONS
  // ============================================================

  /// Insert or update a list
  Future<void> upsertList(SpotListsCompanion list) async {
    await into(spotLists).insertOnConflictUpdate(list);
  }

  /// Get all lists
  Future<List<SpotListData>> getAllLists() async {
    return select(spotLists).get();
  }

  /// Get list by ID
  Future<SpotListData?> getListById(String id) async {
    return (select(spotLists)..where((l) => l.id.equals(id))).getSingleOrNull();
  }

  /// Get lists for a user
  Future<List<SpotListData>> getListsForUser(String userId) async {
    return (select(spotLists)
          ..where((l) => l.ownerId.equals(userId))
          ..orderBy([(l) => OrderingTerm.asc(l.sortOrder)]))
        .get();
  }

  /// Get spots in a list
  Future<List<SpotData>> getSpotsInList(String listId) async {
    final query = select(spots).join([
      innerJoin(listSpots, listSpots.spotId.equalsExp(spots.id)),
    ])
      ..where(listSpots.listId.equals(listId))
      ..orderBy([OrderingTerm.asc(listSpots.sortOrder)]);

    final results = await query.get();
    return results.map((row) => row.readTable(spots)).toList();
  }

  /// Add spot to list
  Future<void> addSpotToList(String listId, String spotId) async {
    await into(listSpots).insert(ListSpotsCompanion(
      listId: Value(listId),
      spotId: Value(spotId),
      addedAt: Value(DateTime.now()),
    ));
  }

  // ============================================================
  // USER OPERATIONS
  // ============================================================

  /// Insert or update a user
  Future<void> upsertUser(UsersCompanion user) async {
    await into(users).insertOnConflictUpdate(user);
  }

  /// Get all users
  Future<List<UserData>> getAllUsers() async {
    return select(users).get();
  }

  /// Get user by ID
  Future<UserData?> getUserById(String id) async {
    return (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();
  }

  /// Get user by email
  Future<UserData?> getUserByEmail(String email) async {
    return (select(users)..where((u) => u.email.equals(email)))
        .getSingleOrNull();
  }

  // ============================================================
  // DEVICE OPERATIONS
  // ============================================================

  /// Register a new device
  Future<void> registerDevice(LinkedDevicesCompanion device) async {
    await into(linkedDevices).insertOnConflictUpdate(device);
  }

  /// Get all devices for a user
  Future<List<LinkedDevice>> getDevicesForUser(String userId) async {
    return (select(linkedDevices)
          ..where((d) => d.userId.equals(userId) & d.status.equals('active'))
          ..orderBy([(d) => OrderingTerm.desc(d.lastSeenAt)]))
        .get();
  }

  /// Get current device
  Future<LinkedDevice?> getCurrentDevice() async {
    return (select(linkedDevices)..where((d) => d.isCurrentDevice.equals(true)))
        .getSingleOrNull();
  }

  /// Update device last seen
  Future<void> updateDeviceLastSeen(String deviceId) async {
    await (update(linkedDevices)..where((d) => d.deviceId.equals(deviceId)))
        .write(LinkedDevicesCompanion(lastSeenAt: Value(DateTime.now())));
  }

  /// Revoke a device
  Future<void> revokeDevice(String deviceId) async {
    await (update(linkedDevices)..where((d) => d.deviceId.equals(deviceId)))
        .write(const LinkedDevicesCompanion(status: Value('revoked')));
  }

  /// Get next device integer ID for a user
  Future<int> getNextDeviceIntId(String userId) async {
    final result = await (selectOnly(linkedDevices)
          ..addColumns([linkedDevices.deviceIntId.max()])
          ..where(linkedDevices.userId.equals(userId)))
        .getSingle();
    return (result.read(linkedDevices.deviceIntId.max()) ?? 0) + 1;
  }

  // ============================================================
  // TRANSFER PROGRESS OPERATIONS
  // ============================================================

  /// Create or update transfer progress
  Future<void> upsertTransferProgress(
      TransferProgressCompanion progress) async {
    await into(transferProgress).insertOnConflictUpdate(progress);
  }

  /// Get active transfer for device pair
  Future<TransferProgressData?> getActiveTransfer(
    String sourceDeviceId,
    String targetDeviceId,
  ) async {
    return (select(transferProgress)
          ..where((t) =>
              t.sourceDeviceId.equals(sourceDeviceId) &
              t.targetDeviceId.equals(targetDeviceId) &
              t.status.equals('in_progress')))
        .getSingleOrNull();
  }

  /// Update transfer chunk progress
  Future<void> updateTransferChunk(
    String transferId,
    int chunkIndex,
    int itemsTransferred,
  ) async {
    await (update(transferProgress)
          ..where((t) => t.transferId.equals(transferId)))
        .write(TransferProgressCompanion(
      lastChunkIndex: Value(chunkIndex),
      itemsTransferred: Value(itemsTransferred),
      lastUpdateAt: Value(DateTime.now()),
    ));
  }

  // ============================================================
  // SYNC STATE OPERATIONS
  // ============================================================

  /// Mark entity as needing sync
  Future<void> markForSync(String entityType, String entityId) async {
    await into(syncState).insertOnConflictUpdate(SyncStateCompanion(
      entityType: Value(entityType),
      entityId: Value(entityId),
      syncStatus: const Value('pending'),
      localModifiedAt: Value(DateTime.now()),
    ));
  }

  /// Get pending sync items
  Future<List<SyncStateData>> getPendingSyncItems() async {
    return (select(syncState)..where((s) => s.syncStatus.equals('pending')))
        .get();
  }

  /// Queue a sync operation
  Future<void> queueSyncOperation({
    required String operationType,
    required String entityType,
    required String entityId,
    required String payload,
    int priority = 0,
  }) async {
    await into(syncQueue).insert(SyncQueueCompanion(
      operationType: Value(operationType),
      entityType: Value(entityType),
      entityId: Value(entityId),
      payload: Value(payload),
      priority: Value(priority),
      createdAt: Value(DateTime.now()),
    ));
  }

  /// Get next sync operation from queue
  Future<SyncQueueData?> getNextSyncOperation() async {
    return (select(syncQueue)
          ..where((s) => s.status.equals('pending'))
          ..orderBy([
            (s) => OrderingTerm.desc(s.priority),
            (s) => OrderingTerm.asc(s.createdAt),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  // ============================================================
  // BATCH OPERATIONS
  // ============================================================

  /// Batch insert messages (for history transfer)
  Future<void> batchInsertMessages(List<MessagesCompanion> messageList) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(messages, messageList);
    });
  }

  /// Batch insert spots
  Future<void> batchInsertSpots(List<SpotsCompanion> spotList) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(spots, spotList);
    });
  }

  /// Get message count
  Future<int> getMessageCount() async {
    final result = await (selectOnly(messages)
          ..addColumns([messages.messageId.count()]))
        .getSingle();
    return result.read(messages.messageId.count()) ?? 0;
  }

  /// Get spot count
  Future<int> getSpotCount() async {
    final result =
        await (selectOnly(spots)..addColumns([spots.id.count()])).getSingle();
    return result.read(spots.id.count()) ?? 0;
  }

  /// Export messages as stream for transfer
  Stream<Message> streamAllMessages() {
    return (select(messages)..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
        .watch()
        .expand((list) => list);
  }

  /// Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(syncQueue).go();
      await delete(syncState).go();
      await delete(transferProgress).go();
      await delete(deviceLinkRequests).go();
      await delete(linkedDevices).go();
      await delete(listSpots).go();
      await delete(spotLists).go();
      await delete(spots).go();
      await delete(messages).go();
      await delete(users).go();
    });
  }
}

/// Opens a connection to the database
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'avrai_drift.db'));
    return NativeDatabase.createInBackground(file);
  });
}
