part of 'reservation_check_in_service.dart';

/// Result of check-in validation and completion.
class CheckInResult {
  final bool success;
  final String? error;
  final Reservation? reservation;
  final double confidenceScore;
  final Map<String, bool> validationLayers;

  const CheckInResult({
    required this.success,
    this.error,
    this.reservation,
    this.confidenceScore = 0.0,
    this.validationLayers = const {},
  });

  factory CheckInResult.success({
    required Reservation reservation,
    required double confidenceScore,
    required Map<String, bool> validationLayers,
  }) {
    return CheckInResult(
      success: true,
      reservation: reservation,
      confidenceScore: confidenceScore,
      validationLayers: validationLayers,
    );
  }

  factory CheckInResult.error(String error) {
    return CheckInResult(
      success: false,
      error: error,
    );
  }
}

/// Payload structure for NFC tag read/write.
class NFCPayload {
  final String reservationId;
  final String spotId;
  final Map<String, dynamic> quantumState;
  final String knotSignature;
  final DateTime timestamp;

  const NFCPayload({
    required this.reservationId,
    required this.spotId,
    required this.quantumState,
    required this.knotSignature,
    required this.timestamp,
  });

  factory NFCPayload.fromJson(Map<String, dynamic> json) {
    return NFCPayload(
      reservationId: json['reservationId'] as String,
      spotId: json['spotId'] as String,
      quantumState: json['quantumState'] as Map<String, dynamic>,
      knotSignature: json['knotSignature'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reservationId': reservationId,
      'spotId': spotId,
      'quantumState': quantumState,
      'knotSignature': knotSignature,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toJson());
}

class _CachedKnotSignature {
  final String signature;
  final DateTime cachedAt;

  _CachedKnotSignature({
    required this.signature,
    required this.cachedAt,
  });
}

class _CachedCompatibility {
  final double score;
  final DateTime cachedAt;

  _CachedCompatibility({
    required this.score,
    required this.cachedAt,
  });
}
