class ReplayEntityIdentity {
  const ReplayEntityIdentity({
    required this.normalizedEntityId,
    required this.entityType,
    required this.canonicalName,
    this.sourceAliases = const <String>[],
    this.sourceRefs = const <String>[],
    this.dedupeKeys = const <String, String>{},
    this.localityAnchor,
    this.metadata = const <String, dynamic>{},
  });

  final String normalizedEntityId;
  final String entityType;
  final String canonicalName;
  final List<String> sourceAliases;
  final List<String> sourceRefs;
  final Map<String, String> dedupeKeys;
  final String? localityAnchor;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return {
      'normalizedEntityId': normalizedEntityId,
      'entityType': entityType,
      'canonicalName': canonicalName,
      'sourceAliases': sourceAliases,
      'sourceRefs': sourceRefs,
      'dedupeKeys': dedupeKeys,
      'localityAnchor': localityAnchor,
      'metadata': metadata,
    };
  }

  factory ReplayEntityIdentity.fromJson(Map<String, dynamic> json) {
    return ReplayEntityIdentity(
      normalizedEntityId: json['normalizedEntityId'] as String? ?? '',
      entityType: json['entityType'] as String? ?? 'unknown',
      canonicalName: json['canonicalName'] as String? ?? '',
      sourceAliases: (json['sourceAliases'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      sourceRefs: (json['sourceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      dedupeKeys: (json['dedupeKeys'] as Map?)
              ?.map((key, value) => MapEntry(key.toString(), value.toString())) ??
          const <String, String>{},
      localityAnchor: json['localityAnchor'] as String?,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
