import 'package:drift/drift.dart';

/// SpotLists table for Drift database
///
/// Stores user-created lists of spots.
/// Named SpotLists (not Lists) to avoid shadowing dart:core's List type.
/// Uses @DataClassName to avoid conflict with SpotList model class.
///
/// Phase 26: Multi-Device Storage Migration
@DataClassName('SpotListData')
@TableIndex(name: 'idx_spot_lists_owner', columns: {#ownerId})
@TableIndex(name: 'idx_spot_lists_type', columns: {#listType})
class SpotLists extends Table {
  /// Unique list identifier
  TextColumn get id => text()();

  /// List name
  TextColumn get name => text()();

  /// List description
  TextColumn get description => text().nullable()();

  /// Owner's user ID
  TextColumn get ownerId => text()();

  /// List type (personal, shared, suggested, etc.)
  TextColumn get listType => text().withDefault(const Constant('personal'))();

  /// Whether list is public
  BoolColumn get isPublic => boolean().withDefault(const Constant(false))();

  /// Cover image URL
  TextColumn get coverImageUrl => text().nullable()();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime()();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime()();

  /// Sort order for display
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Additional metadata as JSON
  TextColumn get metadata => text().nullable()();

  /// Whether synced to cloud
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Junction table for list-spot relationships
@TableIndex(name: 'idx_list_spots_list', columns: {#listId})
@TableIndex(name: 'idx_list_spots_spot', columns: {#spotId})
class ListSpots extends Table {
  /// List ID
  TextColumn get listId => text()();

  /// Spot ID
  TextColumn get spotId => text()();

  /// Order within list
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// When added to list
  DateTimeColumn get addedAt => dateTime()();

  /// Notes about this spot in this list
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {listId, spotId};
}
