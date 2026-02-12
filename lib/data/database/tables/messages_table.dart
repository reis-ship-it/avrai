import 'package:drift/drift.dart';

/// Messages table for Drift database
///
/// Stores all chat messages (friend, community, business) with indexes
/// for efficient querying by chat, timestamp, and read status.
///
/// Phase 26: Multi-Device Storage Migration
@TableIndex(name: 'idx_messages_chat_timestamp', columns: {#chatId, #timestamp})
@TableIndex(name: 'idx_messages_recipient_unread', columns: {#recipientId, #isRead})
@TableIndex(name: 'idx_messages_synced', columns: {#syncedAt})
class Messages extends Table {
  /// Unique message identifier (UUID)
  TextColumn get messageId => text()();

  /// Chat/conversation identifier
  TextColumn get chatId => text()();

  /// Sender's user/agent ID
  TextColumn get senderId => text()();

  /// Recipient's user/agent ID
  TextColumn get recipientId => text()();

  /// Decrypted message content (encrypted at rest by OS)
  TextColumn get content => text()();

  /// Encrypted content for storage (base64)
  TextColumn get encryptedContent => text().nullable()();

  /// Message timestamp
  DateTimeColumn get timestamp => dateTime()();

  /// Whether message has been read
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  /// When message was read
  DateTimeColumn get readAt => dateTime().nullable()();

  /// Message type (text, image, system, etc.)
  TextColumn get messageType =>
      text().withDefault(const Constant('text'))();

  /// Device ID that created this message
  IntColumn get originDeviceId => integer().withDefault(const Constant(1))();

  /// When message was synced to cloud
  DateTimeColumn get syncedAt => dateTime().nullable()();

  /// When read status was synced across devices
  DateTimeColumn get readSyncedAt => dateTime().nullable()();

  /// Local creation timestamp
  DateTimeColumn get localCreatedAt => dateTime()();

  /// Additional metadata as JSON string
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {messageId};
}
