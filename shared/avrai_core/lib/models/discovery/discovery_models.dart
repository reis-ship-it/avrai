enum DiscoveryEntityType {
  spot,
  list,
  event,
  club,
  community,
}

class DiscoveryEntityReference {
  final DiscoveryEntityType type;
  final String id;
  final String title;
  final String? routePath;
  final double? latitude;
  final double? longitude;
  final String? localityLabel;

  const DiscoveryEntityReference({
    required this.type,
    required this.id,
    required this.title,
    this.routePath,
    this.latitude,
    this.longitude,
    this.localityLabel,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.name,
      'id': id,
      'title': title,
      'routePath': routePath,
      'latitude': latitude,
      'longitude': longitude,
      'localityLabel': localityLabel,
    };
  }

  factory DiscoveryEntityReference.fromJson(Map<String, dynamic> json) {
    return DiscoveryEntityReference(
      type: DiscoveryEntityType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => DiscoveryEntityType.spot,
      ),
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      routePath: json['routePath'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      localityLabel: json['localityLabel'] as String?,
    );
  }
}

class RecommendationAttribution {
  final String why;
  final String? whyDetails;
  final int projectedEnjoyabilityPercent;
  final String recommendationSource;
  final double confidence;

  const RecommendationAttribution({
    required this.why,
    this.whyDetails,
    required this.projectedEnjoyabilityPercent,
    required this.recommendationSource,
    this.confidence = 0.7,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'why': why,
      'whyDetails': whyDetails,
      'projectedEnjoyabilityPercent': projectedEnjoyabilityPercent,
      'recommendationSource': recommendationSource,
      'confidence': confidence,
    };
  }

  factory RecommendationAttribution.fromJson(Map<String, dynamic> json) {
    return RecommendationAttribution(
      why: json['why'] as String? ?? 'Recommended for you',
      whyDetails: json['whyDetails'] as String?,
      projectedEnjoyabilityPercent:
          (json['projectedEnjoyabilityPercent'] as num?)?.toInt() ?? 50,
      recommendationSource:
          json['recommendationSource'] as String? ?? 'beta_runtime',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.7,
    );
  }
}

enum RecommendationFeedbackAction {
  save,
  dismiss,
  moreLikeThis,
  lessLikeThis,
  whyDidYouShowThis,
  meaningful,
  fun,
  opened,
}

class SavedDiscoveryEntity {
  final String userId;
  final DiscoveryEntityReference entity;
  final DateTime savedAtUtc;
  final String sourceSurface;
  final RecommendationAttribution? attribution;

  const SavedDiscoveryEntity({
    required this.userId,
    required this.entity,
    required this.savedAtUtc,
    required this.sourceSurface,
    this.attribution,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'entity': entity.toJson(),
      'savedAtUtc': savedAtUtc.toUtc().toIso8601String(),
      'sourceSurface': sourceSurface,
      'attribution': attribution?.toJson(),
    };
  }

  factory SavedDiscoveryEntity.fromJson(Map<String, dynamic> json) {
    return SavedDiscoveryEntity(
      userId: json['userId'] as String? ?? '',
      entity: DiscoveryEntityReference.fromJson(
        Map<String, dynamic>.from(
          json['entity'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      savedAtUtc:
          DateTime.tryParse(json['savedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      sourceSurface: json['sourceSurface'] as String? ?? 'unknown',
      attribution: json['attribution'] is Map
          ? RecommendationAttribution.fromJson(
              Map<String, dynamic>.from(json['attribution'] as Map),
            )
          : null,
    );
  }
}
