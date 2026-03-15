class MeshPacketEnvelope {
  const MeshPacketEnvelope({
    required this.version,
    required this.type,
    required this.senderId,
    this.recipientId,
    required this.timestamp,
    required this.payload,
  });

  final String version;
  final MeshPacketType type;
  final String senderId;
  final String? recipientId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;

  MeshPacketEnvelope copyWith({
    String? version,
    MeshPacketType? type,
    String? senderId,
    Object? recipientId = _missingRecipientId,
    DateTime? timestamp,
    Map<String, dynamic>? payload,
  }) {
    return MeshPacketEnvelope(
      version: version ?? this.version,
      type: type ?? this.type,
      senderId: senderId ?? this.senderId,
      recipientId: identical(recipientId, _missingRecipientId)
          ? this.recipientId
          : recipientId as String?,
      timestamp: timestamp ?? this.timestamp,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'type': type.name,
      'senderId': senderId,
      'recipientId': recipientId,
      'timestamp': timestamp.toIso8601String(),
      'payload': payload,
    };
  }

  factory MeshPacketEnvelope.fromJson(Map<String, dynamic> json) {
    return MeshPacketEnvelope(
      version: json['version'] as String? ?? '1.0',
      type: MeshPacketType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => MeshPacketType.heartbeat,
      ),
      senderId: json['senderId'] as String? ?? 'unknown_sender',
      recipientId: json['recipientId'] as String?,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      payload: Map<String, dynamic>.from(
        json['payload'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

enum MeshPacketType {
  connectionRequest,
  connectionResponse,
  learningExchange,
  learningInsight,
  heartbeat,
  disconnect,
  vibeExchange,
  personalityExchange,
  fragmentStart,
  fragmentContinue,
  fragmentEnd,
  userChat,
  deliveryAck,
  readReceipt,
}

const Object _missingRecipientId = Object();
