enum ArtifactLifecycleClass {
  canonical,
  archive,
  staging,
  temporary,
  quarantine;

  String toWireValue() {
    return switch (this) {
      ArtifactLifecycleClass.canonical => 'canonical',
      ArtifactLifecycleClass.archive => 'archive',
      ArtifactLifecycleClass.staging => 'staging',
      ArtifactLifecycleClass.temporary => 'temporary',
      ArtifactLifecycleClass.quarantine => 'quarantine',
    };
  }

  static ArtifactLifecycleClass fromWireValue(String value) {
    return tryFromWireValue(value) ?? ArtifactLifecycleClass.temporary;
  }

  static ArtifactLifecycleClass? tryFromWireValue(String value) {
    final trimmed = value.trim();
    for (final entry in ArtifactLifecycleClass.values) {
      if (entry.toWireValue() == trimmed) {
        return entry;
      }
    }
    return null;
  }
}

enum ArtifactLifecycleState {
  candidate,
  accepted,
  rejected,
  superseded,
  expired;

  String toWireValue() {
    return switch (this) {
      ArtifactLifecycleState.candidate => 'candidate',
      ArtifactLifecycleState.accepted => 'accepted',
      ArtifactLifecycleState.rejected => 'rejected',
      ArtifactLifecycleState.superseded => 'superseded',
      ArtifactLifecycleState.expired => 'expired',
    };
  }

  static ArtifactLifecycleState fromWireValue(String value) {
    return tryFromWireValue(value) ?? ArtifactLifecycleState.candidate;
  }

  static ArtifactLifecycleState? tryFromWireValue(String value) {
    final trimmed = value.trim();
    for (final entry in ArtifactLifecycleState.values) {
      if (entry.toWireValue() == trimmed) {
        return entry;
      }
    }
    return null;
  }
}

enum ArtifactRetentionMode {
  keepForever,
  archive,
  ttlDelete,
  userControlled;

  String toWireValue() {
    return switch (this) {
      ArtifactRetentionMode.keepForever => 'keep_forever',
      ArtifactRetentionMode.archive => 'archive',
      ArtifactRetentionMode.ttlDelete => 'ttl_delete',
      ArtifactRetentionMode.userControlled => 'user_controlled',
    };
  }

  static ArtifactRetentionMode fromWireValue(String value) {
    return tryFromWireValue(value) ?? ArtifactRetentionMode.keepForever;
  }

  static ArtifactRetentionMode? tryFromWireValue(String value) {
    final trimmed = value.trim();
    for (final entry in ArtifactRetentionMode.values) {
      if (entry.toWireValue() == trimmed) {
        return entry;
      }
    }
    return null;
  }
}

class ArtifactRetentionPolicy {
  const ArtifactRetentionPolicy({
    required this.mode,
    this.ttlDays,
    this.deleteWhenSuperseded = false,
  });

  final ArtifactRetentionMode mode;
  final int? ttlDays;
  final bool deleteWhenSuperseded;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'mode': mode.toWireValue(),
        'ttlDays': ttlDays,
        'deleteWhenSuperseded': deleteWhenSuperseded,
      };

  factory ArtifactRetentionPolicy.fromJson(Map<String, dynamic> json) {
    final ttlValue = json['ttlDays'];
    return ArtifactRetentionPolicy(
      mode: ArtifactRetentionMode.fromWireValue(
        json['mode']?.toString() ?? '',
      ),
      ttlDays: ttlValue is num ? ttlValue.toInt() : null,
      deleteWhenSuperseded: json['deleteWhenSuperseded'] as bool? ?? false,
    );
  }
}

class ArtifactLifecycleMetadata {
  const ArtifactLifecycleMetadata({
    required this.artifactClass,
    required this.artifactState,
    required this.retentionPolicy,
    this.artifactFamily,
    this.sourceScope,
    this.provenanceRefs = const <String>[],
    this.evaluationRefs = const <String>[],
    this.promotionRefs = const <String>[],
    this.containsRawPersonalPayload = false,
    this.containsMessageContent = false,
  });

  final ArtifactLifecycleClass artifactClass;
  final ArtifactLifecycleState artifactState;
  final ArtifactRetentionPolicy retentionPolicy;
  final String? artifactFamily;
  final String? sourceScope;
  final List<String> provenanceRefs;
  final List<String> evaluationRefs;
  final List<String> promotionRefs;
  final bool containsRawPersonalPayload;
  final bool containsMessageContent;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'artifactClass': artifactClass.toWireValue(),
        'artifactState': artifactState.toWireValue(),
        'retentionPolicy': retentionPolicy.toJson(),
        'artifactFamily': artifactFamily,
        'sourceScope': sourceScope,
        'provenanceRefs': provenanceRefs,
        'evaluationRefs': evaluationRefs,
        'promotionRefs': promotionRefs,
        'containsRawPersonalPayload': containsRawPersonalPayload,
        'containsMessageContent': containsMessageContent,
      };

  factory ArtifactLifecycleMetadata.fromJson(Map<String, dynamic> json) {
    return ArtifactLifecycleMetadata(
      artifactClass: ArtifactLifecycleClass.fromWireValue(
        json['artifactClass']?.toString() ?? '',
      ),
      artifactState: ArtifactLifecycleState.fromWireValue(
        json['artifactState']?.toString() ?? '',
      ),
      retentionPolicy: json['retentionPolicy'] is Map
          ? ArtifactRetentionPolicy.fromJson(
              Map<String, dynamic>.from(json['retentionPolicy'] as Map),
            )
          : const ArtifactRetentionPolicy(
              mode: ArtifactRetentionMode.keepForever,
            ),
      artifactFamily: json['artifactFamily']?.toString(),
      sourceScope: json['sourceScope']?.toString(),
      provenanceRefs: _stringList(json['provenanceRefs']),
      evaluationRefs: _stringList(json['evaluationRefs']),
      promotionRefs: _stringList(json['promotionRefs']),
      containsRawPersonalPayload:
          json['containsRawPersonalPayload'] as bool? ?? false,
      containsMessageContent: json['containsMessageContent'] as bool? ?? false,
    );
  }
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.map((entry) => entry.toString()).toList(growable: false);
  }
  return const <String>[];
}
