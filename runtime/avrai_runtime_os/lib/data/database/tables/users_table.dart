import 'package:drift/drift.dart';

/// Users table for Drift database
///
/// Stores local user profile data.
/// Uses @DataClassName to avoid conflict with User model class.
///
/// Phase 26: Multi-Device Storage Migration
@DataClassName('UserData')
@TableIndex(name: 'idx_users_email', columns: {#email})
@TableIndex(name: 'idx_users_agent_id', columns: {#agentId})
class Users extends Table {
  /// Unique user identifier (from Supabase auth)
  TextColumn get id => text()();

  /// User's email
  TextColumn get email => text().nullable()();

  /// Display name
  TextColumn get displayName => text().nullable()();

  /// Profile photo URL
  TextColumn get photoUrl => text().nullable()();

  /// Agent ID for AI2AI communication
  TextColumn get agentId => text().nullable()();

  /// Account creation timestamp
  DateTimeColumn get createdAt => dateTime()();

  /// Last profile update
  DateTimeColumn get updatedAt => dateTime()();

  /// Last seen online
  DateTimeColumn get lastSeenAt => dateTime().nullable()();

  /// User preferences as JSON
  TextColumn get preferences => text().nullable()();

  /// Personality dimensions as JSON
  TextColumn get personalityDimensions => text().nullable()();

  /// Whether profile is complete
  BoolColumn get isProfileComplete =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
