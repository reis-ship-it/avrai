import 'package:avrai_core/avra_core.dart';

/// Real-time backend interface for live updates and subscriptions
/// Handles real-time data synchronization and live features
abstract class RealtimeBackend {
  /// Subscribe to user changes
  Stream<User?> subscribeToUser(String userId);
  
  /// Subscribe to spot changes
  Stream<Spot?> subscribeToSpot(String spotId);
  
  /// Subscribe to spot list changes
  Stream<SpotList?> subscribeToSpotList(String listId);
  
  /// Subscribe to spots in a list
  Stream<List<Spot>> subscribeToSpotsInList(String listId);
  
  /// Subscribe to nearby spots (location-based)
  Stream<List<Spot>> subscribeToNearbySpots(
    double latitude,
    double longitude,
    double radiusKm,
  );
  
  /// Subscribe to user's followed lists
  Stream<List<SpotList>> subscribeToUserLists(String userId);
  
  /// Subscribe to user's respected spots
  Stream<List<Spot>> subscribeToUserRespectedSpots(String userId);
  
  /// Subscribe to collection changes
  Stream<List<T>> subscribeToCollection<T>(
    String collection,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? filters,
    String? orderBy,
    bool? descending,
    int? limit,
  });
  
  /// Subscribe to document changes
  Stream<T?> subscribeToDocument<T>(
    String collection,
    String documentId,
    T Function(Map<String, dynamic>) fromJson,
  );
  
  /// Real-time presence (who's online)
  Stream<List<UserPresence>> subscribeToPresence(String channelId);
  Future<void> updatePresence(String channelId, UserPresence presence);
  Future<void> removePresence(String channelId);
  
  /// Real-time messaging/notifications
  Stream<RealtimeMessage> subscribeToMessages(String channelId);
  Future<void> sendMessage(String channelId, RealtimeMessage message);
  
  /// Live collaborative features
  Stream<List<LiveCursor>> subscribeToLiveCursors(String documentId);
  Future<void> updateLiveCursor(String documentId, LiveCursor cursor);
  
  /// Manage subscriptions
  Future<void> unsubscribe(String subscriptionId);
  Future<void> unsubscribeAll();
  
  /// Connection status
  Stream<RealtimeConnectionStatus> get connectionStatus;
  Future<void> connect();
  Future<void> disconnect();
  
  /// Channel management
  Future<void> joinChannel(String channelId);
  Future<void> leaveChannel(String channelId);
  
  /// Real-time analytics
  Future<void> trackRealtimeEvent(String eventName, Map<String, dynamic> data);
}

/// User presence information for real-time features
class UserPresence {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final DateTime lastSeen;
  final bool isOnline;
  final Map<String, dynamic> metadata;
  
  const UserPresence({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.lastSeen,
    required this.isOnline,
    this.metadata = const {},
  });
  
  factory UserPresence.fromJson(Map<String, dynamic> json) {
    return UserPresence(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      isOnline: json['isOnline'] as bool,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'avatarUrl': avatarUrl,
      'lastSeen': lastSeen.toIso8601String(),
      'isOnline': isOnline,
      'metadata': metadata,
    };
  }
}

/// Real-time message for live communication
class RealtimeMessage {
  final String id;
  final String senderId;
  final String content;
  final String type; // 'text', 'system', 'notification', etc.
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  
  const RealtimeMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.metadata = const {},
  });
  
  factory RealtimeMessage.fromJson(Map<String, dynamic> json) {
    return RealtimeMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      type: json['type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'content': content,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Live cursor for collaborative editing
class LiveCursor {
  final String userId;
  final String userName;
  final double x;
  final double y;
  final String? selection;
  final DateTime lastUpdate;
  
  const LiveCursor({
    required this.userId,
    required this.userName,
    required this.x,
    required this.y,
    this.selection,
    required this.lastUpdate,
  });
  
  factory LiveCursor.fromJson(Map<String, dynamic> json) {
    return LiveCursor(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      x: json['x'] as double,
      y: json['y'] as double,
      selection: json['selection'] as String?,
      lastUpdate: DateTime.parse(json['lastUpdate'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'x': x,
      'y': y,
      'selection': selection,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }
}

/// Real-time connection status
enum RealtimeConnectionStatus {
  connecting,
  connected,
  disconnecting,
  disconnected,
  reconnecting,
  error,
}

extension RealtimeConnectionStatusExtension on RealtimeConnectionStatus {
  bool get isConnected => this == RealtimeConnectionStatus.connected;
  bool get isDisconnected => this == RealtimeConnectionStatus.disconnected;
  bool get isConnecting => 
      this == RealtimeConnectionStatus.connecting || 
      this == RealtimeConnectionStatus.reconnecting;
}
