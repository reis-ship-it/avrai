part of 'quantum_matching_ai_learning_service.dart';

/// Pending learning insight for batch propagation.
class _PendingLearningInsight {
  final String userId;
  final String agentId;
  final AI2AILearningInsight insight;
  final MatchingResult matchingResult;
  final ExpertiseEvent? event;
  final String geographicScope;
  final ExpertiseLevel? userExpertise;
  final AtomicTimestamp timestamp;

  _PendingLearningInsight({
    required this.userId,
    required this.agentId,
    required this.insight,
    required this.matchingResult,
    this.event,
    required this.geographicScope,
    this.userExpertise,
    required this.timestamp,
  });
}

/// Offline match for sync when online.
class _OfflineMatch {
  final String userId;
  final MatchingResult result;
  final ExpertiseEvent? event;
  final AtomicTimestamp timestamp;

  _OfflineMatch({
    required this.userId,
    required this.result,
    this.event,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'result': result.toJson(),
      'event': event?.toJson(),
      'timestamp': timestamp.toJson(),
    };
  }

  factory _OfflineMatch.fromJson(Map<String, dynamic> json) {
    return _OfflineMatch(
      userId: json['userId'] as String,
      result: MatchingResult.fromJson(json['result'] as Map<String, dynamic>),
      event: json['event'] != null
          ? ExpertiseEvent.fromJson(
              json['event'] as Map<String, dynamic>,
              UnifiedUser(
                id: '',
                email: '',
                displayName: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            )
          : null,
      timestamp: AtomicTimestamp.fromJson(
        json['timestamp'] as Map<String, dynamic>,
      ),
    );
  }
}
