import 'package:equatable/equatable.dart';

import 'signature_dimensions.dart';

enum SignatureEntityKind {
  user,
  spot,
  community,
  event,
  bundle,
}

enum SignatureSourceKind {
  personality,
  vibe,
  knot,
  locality,
  timing,
  intake,
  bundle,
  derived,
}

class SignatureSourceTrace extends Equatable {
  final SignatureSourceKind kind;
  final String label;
  final String? sourceId;
  final double weight;

  const SignatureSourceTrace({
    required this.kind,
    required this.label,
    this.sourceId,
    this.weight = 1.0,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'kind': kind.name,
      'label': label,
      'sourceId': sourceId,
      'weight': weight,
    };
  }

  factory SignatureSourceTrace.fromJson(Map<String, dynamic> json) {
    return SignatureSourceTrace(
      kind: SignatureSourceKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => SignatureSourceKind.derived,
      ),
      label: json['label'] as String? ?? 'unknown',
      sourceId: json['sourceId'] as String?,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  List<Object?> get props => [kind, label, sourceId, weight];
}

class EntitySignature extends Equatable {
  final String signatureId;
  final String entityId;
  final SignatureEntityKind entityKind;
  final Map<String, double> dna;
  final Map<String, double> pheromones;
  final double confidence;
  final double freshness;
  final DateTime updatedAt;
  final String? cityCode;
  final String? localityCode;
  final String summary;
  final List<SignatureSourceTrace> sourceTrace;
  final List<String> bundleEntityIds;

  const EntitySignature({
    required this.signatureId,
    required this.entityId,
    required this.entityKind,
    required this.dna,
    required this.pheromones,
    required this.confidence,
    required this.freshness,
    required this.updatedAt,
    required this.summary,
    this.cityCode,
    this.localityCode,
    this.sourceTrace = const <SignatureSourceTrace>[],
    this.bundleEntityIds = const <String>[],
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'signatureId': signatureId,
      'entityId': entityId,
      'entityKind': entityKind.name,
      'dna': SignatureDimensions.normalize(dna),
      'pheromones': SignatureDimensions.normalize(pheromones),
      'confidence': confidence,
      'freshness': freshness,
      'updatedAt': updatedAt.toIso8601String(),
      'cityCode': cityCode,
      'localityCode': localityCode,
      'summary': summary,
      'sourceTrace': sourceTrace.map((item) => item.toJson()).toList(),
      'bundleEntityIds': bundleEntityIds,
    };
  }

  factory EntitySignature.fromJson(Map<String, dynamic> json) {
    Map<String, double> parseDimensions(Object? raw) {
      if (raw is! Map) {
        return SignatureDimensions.normalize(const <String, double>{});
      }
      final parsed = <String, double>{};
      for (final entry in raw.entries) {
        final value = entry.value;
        if (value is num) {
          parsed[entry.key.toString()] = value.toDouble();
        }
      }
      return SignatureDimensions.normalize(parsed);
    }

    final trace = json['sourceTrace'];
    return EntitySignature(
      signatureId: json['signatureId'] as String? ?? '',
      entityId: json['entityId'] as String? ?? '',
      entityKind: SignatureEntityKind.values.firstWhere(
        (value) => value.name == json['entityKind'],
        orElse: () => SignatureEntityKind.bundle,
      ),
      dna: parseDimensions(json['dna']),
      pheromones: parseDimensions(json['pheromones']),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      freshness: (json['freshness'] as num?)?.toDouble() ?? 0.5,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      cityCode: json['cityCode'] as String?,
      localityCode: json['localityCode'] as String?,
      summary: json['summary'] as String? ?? '',
      sourceTrace: trace is List
          ? trace
              .whereType<Map>()
              .map((item) => SignatureSourceTrace.fromJson(
                  Map<String, dynamic>.from(item)))
              .toList()
          : const <SignatureSourceTrace>[],
      bundleEntityIds: List<String>.from(
          json['bundleEntityIds'] as List? ?? const <String>[]),
    );
  }

  EntitySignature copyWith({
    String? signatureId,
    String? entityId,
    SignatureEntityKind? entityKind,
    Map<String, double>? dna,
    Map<String, double>? pheromones,
    double? confidence,
    double? freshness,
    DateTime? updatedAt,
    Object? cityCode = _sentinel,
    Object? localityCode = _sentinel,
    String? summary,
    List<SignatureSourceTrace>? sourceTrace,
    List<String>? bundleEntityIds,
  }) {
    return EntitySignature(
      signatureId: signatureId ?? this.signatureId,
      entityId: entityId ?? this.entityId,
      entityKind: entityKind ?? this.entityKind,
      dna: SignatureDimensions.normalize(dna ?? this.dna),
      pheromones: SignatureDimensions.normalize(pheromones ?? this.pheromones),
      confidence: confidence ?? this.confidence,
      freshness: freshness ?? this.freshness,
      updatedAt: updatedAt ?? this.updatedAt,
      cityCode: cityCode == _sentinel ? this.cityCode : cityCode as String?,
      localityCode: localityCode == _sentinel
          ? this.localityCode
          : localityCode as String?,
      summary: summary ?? this.summary,
      sourceTrace: sourceTrace ?? this.sourceTrace,
      bundleEntityIds: bundleEntityIds ?? this.bundleEntityIds,
    );
  }

  @override
  List<Object?> get props => [
        signatureId,
        entityId,
        entityKind,
        dna,
        pheromones,
        confidence,
        freshness,
        updatedAt,
        cityCode,
        localityCode,
        summary,
        sourceTrace,
        bundleEntityIds,
      ];
}

const Object _sentinel = Object();
