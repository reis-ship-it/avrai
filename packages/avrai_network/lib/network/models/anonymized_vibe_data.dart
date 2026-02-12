/// Anonymized vibe payload for connectionless discovery (BLE/NSD/WebRTC).
///
/// This lives in `spots_network` so the network layer can carry/encode/decode the
/// discovery payload without depending on the main app package.
///
/// **Important:** This is already privacy-scrubbed data. Generation/anonymization
/// happens in the app/AI layer.
class AnonymizedVibeData {
  final Map<String, double> noisyDimensions;
  final AnonymizedVibeMetrics anonymizedMetrics;
  final String temporalContextHash;
  final String vibeSignature;
  final String privacyLevel;
  final double anonymizationQuality;
  final String salt;
  final DateTime createdAt;
  final DateTime expiresAt;

  AnonymizedVibeData({
    required this.noisyDimensions,
    required this.anonymizedMetrics,
    required this.temporalContextHash,
    required this.vibeSignature,
    required this.privacyLevel,
    required this.anonymizationQuality,
    required this.salt,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() {
    return {
      'noisy_dimensions': noisyDimensions,
      'anonymized_metrics': anonymizedMetrics.toJson(),
      'temporal_context_hash': temporalContextHash,
      'vibe_signature': vibeSignature,
      'privacy_level': privacyLevel,
      'anonymization_quality': anonymizationQuality,
      'salt': salt,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  factory AnonymizedVibeData.fromJson(Map<String, dynamic> json) {
    final metricsJson = json['anonymized_metrics'] as Map<String, dynamic>;
    final dimensionsJson = json['noisy_dimensions'] as Map<String, dynamic>;

    final noisyDimensions = <String, double>{};
    dimensionsJson.forEach((key, value) {
      noisyDimensions[key] = (value as num).toDouble();
    });

    return AnonymizedVibeData(
      noisyDimensions: noisyDimensions,
      anonymizedMetrics: AnonymizedVibeMetrics.fromJson(metricsJson),
      temporalContextHash: json['temporal_context_hash'] as String,
      vibeSignature: json['vibe_signature'] as String,
      privacyLevel: json['privacy_level'] as String,
      anonymizationQuality: (json['anonymization_quality'] as num).toDouble(),
      salt: json['salt'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}

class AnonymizedVibeMetrics {
  final double energy;
  final double social;
  final double exploration;

  AnonymizedVibeMetrics({
    required this.energy,
    required this.social,
    required this.exploration,
  });

  Map<String, dynamic> toJson() {
    return {
      'energy': energy,
      'social': social,
      'exploration': exploration,
    };
  }

  factory AnonymizedVibeMetrics.fromJson(Map<String, dynamic> json) {
    return AnonymizedVibeMetrics(
      energy: (json['energy'] as num).toDouble(),
      social: (json['social'] as num).toDouble(),
      exploration: (json['exploration'] as num).toDouble(),
    );
  }
}

