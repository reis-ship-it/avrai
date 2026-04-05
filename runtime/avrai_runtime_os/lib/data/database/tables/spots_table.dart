import 'package:drift/drift.dart';

/// Spots table for Drift database
///
/// Stores location/venue data with geospatial indexes.
/// Uses @DataClassName to avoid conflict with Spot model class.
///
/// Phase 26: Multi-Device Storage Migration
@DataClassName('SpotData')
@TableIndex(name: 'idx_spots_category', columns: {#category})
@TableIndex(name: 'idx_spots_created_by', columns: {#createdBy})
@TableIndex(name: 'idx_spots_geo', columns: {#latitude, #longitude})
class Spots extends Table {
  /// Unique spot identifier
  TextColumn get id => text()();

  /// Spot name
  TextColumn get name => text()();

  /// Description
  TextColumn get description => text().nullable()();

  /// Latitude coordinate
  RealColumn get latitude => real()();

  /// Longitude coordinate
  RealColumn get longitude => real()();

  /// Category (Coffee, Restaurant, Bar, etc.)
  TextColumn get category => text().withDefault(const Constant(''))();

  /// Rating (0.0 - 5.0)
  RealColumn get rating => real().withDefault(const Constant(0.0))();

  /// User ID who created this spot
  TextColumn get createdBy => text()();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime()();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime()();

  /// Google Place ID (if from Google Places)
  TextColumn get googlePlaceId => text().nullable()();

  /// Apple Maps ID (if from MapKit)
  TextColumn get appleMapId => text().nullable()();

  /// Address string
  TextColumn get address => text().nullable()();

  /// Photo URLs as JSON array
  TextColumn get photoUrls => text().nullable()();

  /// Vibe signature as JSON
  TextColumn get vibeSignature => text().nullable()();

  /// Additional metadata as JSON
  TextColumn get metadata => text().nullable()();

  /// Whether synced to cloud
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
