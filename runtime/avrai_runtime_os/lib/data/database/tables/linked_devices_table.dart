import 'package:drift/drift.dart';

/// Linked devices table for Drift database
///
/// Tracks all devices linked to a user account for multi-device sync.
///
/// Phase 26: Multi-Device Storage Migration
@TableIndex(name: 'idx_devices_user', columns: {#userId})
@TableIndex(name: 'idx_devices_status', columns: {#status})
class LinkedDevices extends Table {
  /// Unique device identifier
  TextColumn get deviceId => text()();

  /// User ID who owns this device
  TextColumn get userId => text()();

  /// Device integer ID (for Signal Protocol)
  IntColumn get deviceIntId => integer()();

  /// Human-readable device name (e.g., "iPhone 15 Pro")
  TextColumn get deviceName => text()();

  /// Platform (ios, android, macos, windows, linux, web)
  TextColumn get platform => text()();

  /// Device model
  TextColumn get deviceModel => text().nullable()();

  /// OS version
  TextColumn get osVersion => text().nullable()();

  /// App version on this device
  TextColumn get appVersion => text().nullable()();

  /// Device status (active, suspended, revoked)
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// Public key for this device (base64)
  TextColumn get publicKey => text().nullable()();

  /// Push notification token
  TextColumn get pushToken => text().nullable()();

  /// When device was registered
  DateTimeColumn get registeredAt => dateTime()();

  /// Last activity timestamp
  DateTimeColumn get lastSeenAt => dateTime()();

  /// Whether this is the current device
  BoolColumn get isCurrentDevice =>
      boolean().withDefault(const Constant(false))();

  /// Whether this is the primary device
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  /// Additional metadata as JSON
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {deviceId};
}

/// Device link requests for pairing new devices
@TableIndex(name: 'idx_link_requests_user', columns: {#userId})
@TableIndex(name: 'idx_link_requests_status', columns: {#status})
class DeviceLinkRequests extends Table {
  /// Request identifier
  TextColumn get requestId => text()();

  /// User ID
  TextColumn get userId => text()();

  /// Requesting device ID (new device)
  TextColumn get requestingDeviceId => text()();

  /// Approving device ID (existing device, nullable for bypass)
  TextColumn get approvingDeviceId => text().nullable()();

  /// Link method (same_account, numeric_code, push_approval, secure_bypass)
  TextColumn get linkMethod => text()();

  /// Numeric code hash (if using numeric code method)
  TextColumn get codeHash => text().nullable()();

  /// Ephemeral public key for secure channel
  TextColumn get ephemeralPublicKey => text().nullable()();

  /// Request status (pending, approved, rejected, expired)
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// When request was created
  DateTimeColumn get createdAt => dateTime()();

  /// When request expires
  DateTimeColumn get expiresAt => dateTime()();

  /// When request was resolved
  DateTimeColumn get resolvedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {requestId};
}
