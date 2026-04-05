import 'package:equatable/equatable.dart';
import 'package:avrai_core/models/air_gap/air_gap_compression_models.dart';
import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';
import 'package:avrai_core/models/truth/truth_evidence_envelope.dart';

enum EventPlanningSourceKind {
  human,
  personalAgent,
}

enum EventSizeIntent {
  intimate,
  standard,
  large,
}

enum EventPriceIntent {
  free,
  lowCost,
  ticketed,
}

enum EventHostGoal {
  community,
  celebration,
  learning,
  networking,
  mixed,
}

enum EventPlanningConfidence {
  low,
  medium,
  high,
}

enum EventAttendanceFillBand {
  low,
  medium,
  high,
}

enum EventLearningSignalKind {
  intentDeclared,
  suggestionAccepted,
  eventCreated,
  eventCompleted,
}

class EventAirGapProvenance extends Equatable {
  final String crossingId;
  final DateTime crossedAt;
  final EventPlanningSourceKind sourceKind;
  final List<String> tupleRefs;
  final EventPlanningConfidence confidence;
  final String extractorVersion;

  const EventAirGapProvenance({
    required this.crossingId,
    required this.crossedAt,
    required this.sourceKind,
    this.tupleRefs = const <String>[],
    required this.confidence,
    this.extractorVersion = 'event_planning_airgap_v1',
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'crossingId': crossingId,
      'crossedAt': crossedAt.toIso8601String(),
      'sourceKind': sourceKind.name,
      'tupleRefs': tupleRefs,
      'confidence': confidence.name,
      'extractorVersion': extractorVersion,
    };
  }

  factory EventAirGapProvenance.fromJson(Map<String, dynamic> json) {
    final crossedAt = json['crossedAt'] == null
        ? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
        : DateTime.parse(json['crossedAt'] as String);
    return EventAirGapProvenance(
      crossingId: json['crossingId'] as String? ??
          'legacy_event_plan_${crossedAt.microsecondsSinceEpoch}',
      crossedAt: crossedAt,
      sourceKind: EventPlanningSourceKind.values.firstWhere(
        (value) => value.name == json['sourceKind'],
        orElse: () => EventPlanningSourceKind.human,
      ),
      tupleRefs: List<String>.from(json['tupleRefs'] as List? ?? const []),
      confidence: EventPlanningConfidence.values.firstWhere(
        (value) => value.name == json['confidence'],
        orElse: () => EventPlanningConfidence.low,
      ),
      extractorVersion:
          json['extractorVersion'] as String? ?? 'event_planning_airgap_v1',
    );
  }

  @override
  List<Object?> get props => <Object?>[
        crossingId,
        crossedAt,
        sourceKind,
        tupleRefs,
        confidence,
        extractorVersion,
      ];
}

/// Transient event-planning input. This type must never be persisted.
class RawEventPlanningInput extends Equatable {
  final EventPlanningSourceKind sourceKind;
  final String purposeText;
  final String vibeText;
  final String targetAudienceText;
  final String candidateLocalityLabel;
  final DateTime? preferredStartDate;
  final DateTime? preferredEndDate;
  final EventSizeIntent sizeIntent;
  final EventPriceIntent priceIntent;
  final EventHostGoal hostGoal;

  const RawEventPlanningInput({
    required this.sourceKind,
    this.purposeText = '',
    this.vibeText = '',
    this.targetAudienceText = '',
    this.candidateLocalityLabel = '',
    this.preferredStartDate,
    this.preferredEndDate,
    this.sizeIntent = EventSizeIntent.standard,
    this.priceIntent = EventPriceIntent.free,
    this.hostGoal = EventHostGoal.community,
  });

  bool get hasMeaningfulInput =>
      purposeText.trim().isNotEmpty ||
      vibeText.trim().isNotEmpty ||
      targetAudienceText.trim().isNotEmpty ||
      candidateLocalityLabel.trim().isNotEmpty ||
      preferredStartDate != null ||
      preferredEndDate != null;

  @override
  List<Object?> get props => <Object?>[
        sourceKind,
        purposeText,
        vibeText,
        targetAudienceText,
        candidateLocalityLabel,
        preferredStartDate,
        preferredEndDate,
        sizeIntent,
        priceIntent,
        hostGoal,
      ];
}

class EventDocketLite extends Equatable {
  final List<String> intentTags;
  final List<String> vibeTags;
  final List<String> audienceTags;
  final String? candidateLocalityLabel;
  final String? candidateLocalityCode;
  final DateTime? preferredStartDate;
  final DateTime? preferredEndDate;
  final EventSizeIntent sizeIntent;
  final EventPriceIntent priceIntent;
  final EventHostGoal hostGoal;
  final EventAirGapProvenance airGapProvenance;

  const EventDocketLite({
    this.intentTags = const <String>[],
    this.vibeTags = const <String>[],
    this.audienceTags = const <String>[],
    this.candidateLocalityLabel,
    this.candidateLocalityCode,
    this.preferredStartDate,
    this.preferredEndDate,
    this.sizeIntent = EventSizeIntent.standard,
    this.priceIntent = EventPriceIntent.free,
    this.hostGoal = EventHostGoal.community,
    required this.airGapProvenance,
  });

  EventDocketLite copyWith({
    List<String>? intentTags,
    List<String>? vibeTags,
    List<String>? audienceTags,
    Object? candidateLocalityLabel = _eventPlanningSentinel,
    Object? candidateLocalityCode = _eventPlanningSentinel,
    Object? preferredStartDate = _eventPlanningSentinel,
    Object? preferredEndDate = _eventPlanningSentinel,
    EventSizeIntent? sizeIntent,
    EventPriceIntent? priceIntent,
    EventHostGoal? hostGoal,
    EventAirGapProvenance? airGapProvenance,
  }) {
    return EventDocketLite(
      intentTags: intentTags ?? this.intentTags,
      vibeTags: vibeTags ?? this.vibeTags,
      audienceTags: audienceTags ?? this.audienceTags,
      candidateLocalityLabel: candidateLocalityLabel == _eventPlanningSentinel
          ? this.candidateLocalityLabel
          : candidateLocalityLabel as String?,
      candidateLocalityCode: candidateLocalityCode == _eventPlanningSentinel
          ? this.candidateLocalityCode
          : candidateLocalityCode as String?,
      preferredStartDate: preferredStartDate == _eventPlanningSentinel
          ? this.preferredStartDate
          : preferredStartDate as DateTime?,
      preferredEndDate: preferredEndDate == _eventPlanningSentinel
          ? this.preferredEndDate
          : preferredEndDate as DateTime?,
      sizeIntent: sizeIntent ?? this.sizeIntent,
      priceIntent: priceIntent ?? this.priceIntent,
      hostGoal: hostGoal ?? this.hostGoal,
      airGapProvenance: airGapProvenance ?? this.airGapProvenance,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'intentTags': intentTags,
      'vibeTags': vibeTags,
      'audienceTags': audienceTags,
      'candidateLocalityLabel': candidateLocalityLabel,
      'candidateLocalityCode': candidateLocalityCode,
      'preferredStartDate': preferredStartDate?.toIso8601String(),
      'preferredEndDate': preferredEndDate?.toIso8601String(),
      'sizeIntent': sizeIntent.name,
      'priceIntent': priceIntent.name,
      'hostGoal': hostGoal.name,
      'airGapProvenance': airGapProvenance.toJson(),
    };
  }

  factory EventDocketLite.fromJson(Map<String, dynamic> json) {
    return EventDocketLite(
      intentTags: List<String>.from(json['intentTags'] as List? ?? const []),
      vibeTags: List<String>.from(json['vibeTags'] as List? ?? const []),
      audienceTags:
          List<String>.from(json['audienceTags'] as List? ?? const []),
      candidateLocalityLabel: json['candidateLocalityLabel'] as String?,
      candidateLocalityCode: json['candidateLocalityCode'] as String?,
      preferredStartDate: json['preferredStartDate'] == null
          ? null
          : DateTime.parse(json['preferredStartDate'] as String),
      preferredEndDate: json['preferredEndDate'] == null
          ? null
          : DateTime.parse(json['preferredEndDate'] as String),
      sizeIntent: EventSizeIntent.values.firstWhere(
        (value) => value.name == json['sizeIntent'],
        orElse: () => EventSizeIntent.standard,
      ),
      priceIntent: EventPriceIntent.values.firstWhere(
        (value) => value.name == json['priceIntent'],
        orElse: () => EventPriceIntent.free,
      ),
      hostGoal: EventHostGoal.values.firstWhere(
        (value) => value.name == json['hostGoal'],
        orElse: () => EventHostGoal.community,
      ),
      airGapProvenance: EventAirGapProvenance.fromJson(
        Map<String, dynamic>.from(
          json['airGapProvenance'] as Map? ?? const <String, dynamic>{},
        ),
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        intentTags,
        vibeTags,
        audienceTags,
        candidateLocalityLabel,
        candidateLocalityCode,
        preferredStartDate,
        preferredEndDate,
        sizeIntent,
        priceIntent,
        hostGoal,
        airGapProvenance,
      ];
}

class EventPlanningAirGapResult extends Equatable {
  final EventDocketLite docket;
  final EventPlanningConfidence confidence;
  final List<String> tupleRefs;
  final EventPlanningSourceKind sourceKind;
  final TruthScopeDescriptor truthScope;
  final TruthEvidenceEnvelope? evidenceEnvelope;
  final SafeArtifactEnvelope? compressedArtifactEnvelope;
  final CompressedKnowledgePacket? compressedKnowledgePacket;
  final CompressionBudgetProfile? compressionBudgetProfile;

  const EventPlanningAirGapResult({
    required this.docket,
    required this.confidence,
    this.tupleRefs = const <String>[],
    required this.sourceKind,
    this.truthScope = const TruthScopeDescriptor.defaultPlanning(),
    this.evidenceEnvelope,
    this.compressedArtifactEnvelope,
    this.compressedKnowledgePacket,
    this.compressionBudgetProfile,
  });

  @override
  List<Object?> get props => <Object?>[
        docket,
        confidence,
        tupleRefs,
        sourceKind,
        truthScope,
        evidenceEnvelope,
        compressedArtifactEnvelope,
        compressedKnowledgePacket,
        compressionBudgetProfile,
      ];
}

class EventCreationSuggestion extends Equatable {
  final DateTime suggestedStartTime;
  final DateTime suggestedEndTime;
  final String? suggestedLocalityLabel;
  final int suggestedMaxAttendees;
  final double? suggestedPrice;
  final EventAttendanceFillBand predictedAttendanceFillBand;
  final EventPlanningConfidence confidence;
  final String explanation;
  final TruthScopeDescriptor truthScope;
  final TruthEvidenceEnvelope? evidenceEnvelope;

  const EventCreationSuggestion({
    required this.suggestedStartTime,
    required this.suggestedEndTime,
    this.suggestedLocalityLabel,
    required this.suggestedMaxAttendees,
    this.suggestedPrice,
    required this.predictedAttendanceFillBand,
    required this.confidence,
    required this.explanation,
    this.truthScope = const TruthScopeDescriptor.defaultPlanning(),
    this.evidenceEnvelope,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'suggestedStartTime': suggestedStartTime.toIso8601String(),
      'suggestedEndTime': suggestedEndTime.toIso8601String(),
      'suggestedLocalityLabel': suggestedLocalityLabel,
      'suggestedMaxAttendees': suggestedMaxAttendees,
      'suggestedPrice': suggestedPrice,
      'predictedAttendanceFillBand': predictedAttendanceFillBand.name,
      'confidence': confidence.name,
      'explanation': explanation,
      'truthScope': truthScope.toJson(),
      'evidenceEnvelope': evidenceEnvelope?.toJson(),
    };
  }

  factory EventCreationSuggestion.fromJson(Map<String, dynamic> json) {
    return EventCreationSuggestion(
      suggestedStartTime: DateTime.parse(json['suggestedStartTime'] as String),
      suggestedEndTime: DateTime.parse(json['suggestedEndTime'] as String),
      suggestedLocalityLabel: json['suggestedLocalityLabel'] as String?,
      suggestedMaxAttendees: json['suggestedMaxAttendees'] as int? ?? 20,
      suggestedPrice: (json['suggestedPrice'] as num?)?.toDouble(),
      predictedAttendanceFillBand: EventAttendanceFillBand.values.firstWhere(
        (value) => value.name == json['predictedAttendanceFillBand'],
        orElse: () => EventAttendanceFillBand.medium,
      ),
      confidence: EventPlanningConfidence.values.firstWhere(
        (value) => value.name == json['confidence'],
        orElse: () => EventPlanningConfidence.low,
      ),
      explanation: json['explanation'] as String? ?? '',
      truthScope: json['truthScope'] is Map
          ? TruthScopeDescriptor.fromJson(
              Map<String, dynamic>.from(json['truthScope'] as Map),
            )
          : const TruthScopeDescriptor.defaultPlanning(),
      evidenceEnvelope: json['evidenceEnvelope'] is Map
          ? TruthEvidenceEnvelope.fromJson(
              Map<String, dynamic>.from(json['evidenceEnvelope'] as Map),
            )
          : null,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        suggestedStartTime,
        suggestedEndTime,
        suggestedLocalityLabel,
        suggestedMaxAttendees,
        suggestedPrice,
        predictedAttendanceFillBand,
        confidence,
        explanation,
        truthScope,
        evidenceEnvelope,
      ];
}

class EventPlanningSnapshot extends Equatable {
  final EventDocketLite docket;
  final EventCreationSuggestion? acceptedSuggestion;
  final DateTime createdAt;
  final TruthScopeDescriptor truthScope;
  final TruthEvidenceEnvelope? evidenceEnvelope;

  const EventPlanningSnapshot({
    required this.docket,
    this.acceptedSuggestion,
    required this.createdAt,
    this.truthScope = const TruthScopeDescriptor.defaultPlanning(),
    this.evidenceEnvelope,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'docket': docket.toJson(),
      'acceptedSuggestion': acceptedSuggestion?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'truthScope': truthScope.toJson(),
      'evidenceEnvelope': evidenceEnvelope?.toJson(),
    };
  }

  factory EventPlanningSnapshot.fromJson(Map<String, dynamic> json) {
    return EventPlanningSnapshot(
      docket: EventDocketLite.fromJson(
        Map<String, dynamic>.from(json['docket'] as Map? ?? const {}),
      ),
      acceptedSuggestion: json['acceptedSuggestion'] is Map<String, dynamic>
          ? EventCreationSuggestion.fromJson(
              Map<String, dynamic>.from(
                json['acceptedSuggestion'] as Map<String, dynamic>,
              ),
            )
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      truthScope: json['truthScope'] is Map
          ? TruthScopeDescriptor.fromJson(
              Map<String, dynamic>.from(json['truthScope'] as Map),
            )
          : const TruthScopeDescriptor.defaultPlanning(),
      evidenceEnvelope: json['evidenceEnvelope'] is Map
          ? TruthEvidenceEnvelope.fromJson(
              Map<String, dynamic>.from(json['evidenceEnvelope'] as Map),
            )
          : null,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        docket,
        acceptedSuggestion,
        createdAt,
        truthScope,
        evidenceEnvelope,
      ];
}

class EventCreationLearningSignal extends Equatable {
  final String signalId;
  final String eventId;
  final String hostUserId;
  final EventLearningSignalKind kind;
  final EventPlanningSnapshot planningSnapshot;
  final List<String> tupleRefs;
  final Map<String, dynamic> boundedPayload;
  final DateTime createdAt;
  final TruthScopeDescriptor truthScope;
  final TruthEvidenceEnvelope? evidenceEnvelope;
  final SafeArtifactEnvelope? compressedArtifactEnvelope;
  final CompressedKnowledgePacket? compressedKnowledgePacket;
  final CompressionBudgetProfile? compressionBudgetProfile;

  const EventCreationLearningSignal({
    required this.signalId,
    required this.eventId,
    required this.hostUserId,
    required this.kind,
    required this.planningSnapshot,
    this.tupleRefs = const <String>[],
    this.boundedPayload = const <String, dynamic>{},
    required this.createdAt,
    this.truthScope = const TruthScopeDescriptor.defaultPlanning(),
    this.evidenceEnvelope,
    this.compressedArtifactEnvelope,
    this.compressedKnowledgePacket,
    this.compressionBudgetProfile,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'signalId': signalId,
      'eventId': eventId,
      'hostUserId': hostUserId,
      'kind': kind.name,
      'planningSnapshot': planningSnapshot.toJson(),
      'tupleRefs': tupleRefs,
      'boundedPayload': boundedPayload,
      'createdAt': createdAt.toIso8601String(),
      'truthScope': truthScope.toJson(),
      'evidenceEnvelope': evidenceEnvelope?.toJson(),
      'compressedArtifactEnvelope': compressedArtifactEnvelope?.toJson(),
      'compressedKnowledgePacket': compressedKnowledgePacket?.toJson(),
      'compressionBudgetProfile': compressionBudgetProfile?.toJson(),
    };
  }

  factory EventCreationLearningSignal.fromJson(Map<String, dynamic> json) {
    return EventCreationLearningSignal(
      signalId: json['signalId'] as String,
      eventId: json['eventId'] as String,
      hostUserId: json['hostUserId'] as String,
      kind: EventLearningSignalKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => EventLearningSignalKind.eventCreated,
      ),
      planningSnapshot: EventPlanningSnapshot.fromJson(
        Map<String, dynamic>.from(
          json['planningSnapshot'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      tupleRefs: List<String>.from(json['tupleRefs'] as List? ?? const []),
      boundedPayload: Map<String, dynamic>.from(
        json['boundedPayload'] as Map? ?? const <String, dynamic>{},
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      truthScope: json['truthScope'] is Map
          ? TruthScopeDescriptor.fromJson(
              Map<String, dynamic>.from(json['truthScope'] as Map),
            )
          : const TruthScopeDescriptor.defaultPlanning(),
      evidenceEnvelope: json['evidenceEnvelope'] is Map
          ? TruthEvidenceEnvelope.fromJson(
              Map<String, dynamic>.from(json['evidenceEnvelope'] as Map),
            )
          : null,
      compressedArtifactEnvelope: json['compressedArtifactEnvelope'] is Map
          ? SafeArtifactEnvelope.fromJson(
              Map<String, dynamic>.from(
                json['compressedArtifactEnvelope'] as Map,
              ),
            )
          : null,
      compressedKnowledgePacket: json['compressedKnowledgePacket'] is Map
          ? CompressedKnowledgePacket.fromJson(
              Map<String, dynamic>.from(
                json['compressedKnowledgePacket'] as Map,
              ),
            )
          : null,
      compressionBudgetProfile: json['compressionBudgetProfile'] is Map
          ? CompressionBudgetProfile.fromJson(
              Map<String, dynamic>.from(
                json['compressionBudgetProfile'] as Map,
              ),
            )
          : null,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        signalId,
        eventId,
        hostUserId,
        kind,
        planningSnapshot,
        tupleRefs,
        boundedPayload,
        createdAt,
        truthScope,
        evidenceEnvelope,
        compressedArtifactEnvelope,
        compressedKnowledgePacket,
        compressionBudgetProfile,
      ];
}

class HostEventDebrief extends Equatable {
  final String eventId;
  final EventAttendanceFillBand? predictedAttendanceFillBand;
  final int actualAttendance;
  final double attendanceRate;
  final double averageRating;
  final double wouldAttendAgainRate;
  final List<String> insightLines;
  final DateTime createdAt;
  final TruthScopeDescriptor truthScope;
  final TruthEvidenceEnvelope? evidenceEnvelope;

  const HostEventDebrief({
    required this.eventId,
    this.predictedAttendanceFillBand,
    required this.actualAttendance,
    required this.attendanceRate,
    required this.averageRating,
    required this.wouldAttendAgainRate,
    this.insightLines = const <String>[],
    required this.createdAt,
    this.truthScope = const TruthScopeDescriptor.defaultPlanning(),
    this.evidenceEnvelope,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'eventId': eventId,
      'predictedAttendanceFillBand': predictedAttendanceFillBand?.name,
      'actualAttendance': actualAttendance,
      'attendanceRate': attendanceRate,
      'averageRating': averageRating,
      'wouldAttendAgainRate': wouldAttendAgainRate,
      'insightLines': insightLines,
      'createdAt': createdAt.toIso8601String(),
      'truthScope': truthScope.toJson(),
      'evidenceEnvelope': evidenceEnvelope?.toJson(),
    };
  }

  factory HostEventDebrief.fromJson(Map<String, dynamic> json) {
    return HostEventDebrief(
      eventId: json['eventId'] as String,
      predictedAttendanceFillBand: json['predictedAttendanceFillBand'] == null
          ? null
          : EventAttendanceFillBand.values.firstWhere(
              (value) => value.name == json['predictedAttendanceFillBand'],
              orElse: () => EventAttendanceFillBand.medium,
            ),
      actualAttendance: json['actualAttendance'] as int? ?? 0,
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      wouldAttendAgainRate:
          (json['wouldAttendAgainRate'] as num?)?.toDouble() ?? 0.0,
      insightLines:
          List<String>.from(json['insightLines'] as List? ?? const []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      truthScope: json['truthScope'] is Map
          ? TruthScopeDescriptor.fromJson(
              Map<String, dynamic>.from(json['truthScope'] as Map),
            )
          : const TruthScopeDescriptor.defaultPlanning(),
      evidenceEnvelope: json['evidenceEnvelope'] is Map
          ? TruthEvidenceEnvelope.fromJson(
              Map<String, dynamic>.from(json['evidenceEnvelope'] as Map),
            )
          : null,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        eventId,
        predictedAttendanceFillBand,
        actualAttendance,
        attendanceRate,
        averageRating,
        wouldAttendAgainRate,
        insightLines,
        createdAt,
        truthScope,
        evidenceEnvelope,
      ];
}

class EventPlanningBoundaryGuard {
  static final RegExp _sanitizedTagPattern = RegExp(r"^[a-z0-9']{2,40}$");
  static final RegExp _localityCodePattern = RegExp(r'^[a-z0-9_:-]{2,64}$');
  static final RegExp _localityLabelPattern =
      RegExp(r"^[A-Za-z0-9 '&./-]{2,80}$");

  static void ensureSanitizedDocket(
    EventDocketLite docket, {
    String context = 'event_planning',
  }) {
    _validateTagGroup(
      label: 'intentTags',
      tags: docket.intentTags,
      context: context,
    );
    _validateTagGroup(
      label: 'vibeTags',
      tags: docket.vibeTags,
      context: context,
    );
    _validateTagGroup(
      label: 'audienceTags',
      tags: docket.audienceTags,
      context: context,
    );

    final localityLabel = docket.candidateLocalityLabel;
    if (localityLabel != null &&
        !_localityLabelPattern.hasMatch(localityLabel.trim())) {
      throw FormatException(
        '$context candidateLocalityLabel must be a bounded locality label.',
      );
    }

    final localityCode = docket.candidateLocalityCode;
    if (localityCode != null &&
        !_localityCodePattern.hasMatch(localityCode.trim())) {
      throw FormatException(
        '$context candidateLocalityCode must be a bounded locality code.',
      );
    }

    final provenance = docket.airGapProvenance;
    if (provenance.crossingId.trim().isEmpty) {
      throw FormatException(
          '$context requires a non-empty air-gap crossingId.');
    }
    if (provenance.tupleRefs.any((ref) => ref.trim().isEmpty)) {
      throw FormatException('$context tupleRefs must be non-empty strings.');
    }
    if (provenance.extractorVersion.trim().isEmpty) {
      throw FormatException('$context requires extractorVersion provenance.');
    }
  }

  static void ensureSanitizedSnapshot(
    EventPlanningSnapshot snapshot, {
    String context = 'event_planning',
  }) {
    ensureSanitizedDocket(snapshot.docket, context: context);
    _ensurePlanningTruthScope(snapshot.truthScope, context: context);
    _ensureEvidenceEnvelopeScope(
      snapshot.evidenceEnvelope,
      truthScope: snapshot.truthScope,
      context: context,
      label: 'snapshot',
    );

    if (snapshot.createdAt
        .isBefore(snapshot.docket.airGapProvenance.crossedAt)) {
      throw FormatException(
        '$context snapshot cannot predate the air-gap crossing.',
      );
    }

    final suggestion = snapshot.acceptedSuggestion;
    if (suggestion == null) {
      return;
    }
    _ensureEvidenceEnvelopeScope(
      suggestion.evidenceEnvelope,
      truthScope: suggestion.truthScope,
      context: context,
      label: 'suggestion',
    );
    if (suggestion.truthScope.scopeKey != snapshot.truthScope.scopeKey) {
      throw FormatException(
        '$context suggestion truthScope must match the snapshot truthScope.',
      );
    }

    final suggestedLocalityLabel = suggestion.suggestedLocalityLabel;
    if (suggestedLocalityLabel != null &&
        !_localityLabelPattern.hasMatch(suggestedLocalityLabel.trim())) {
      throw FormatException(
        '$context suggestedLocalityLabel must be a bounded locality label.',
      );
    }

    if (suggestion.explanation.trim().isEmpty ||
        suggestion.explanation.length > 320) {
      throw FormatException(
        '$context suggestion explanation must be present and bounded.',
      );
    }
  }

  static void _ensurePlanningTruthScope(
    TruthScopeDescriptor truthScope, {
    required String context,
  }) {
    if (truthScope.truthSurfaceKind != TruthSurfaceKind.planning) {
      throw FormatException(
        '$context truthScope must target the planning truth surface.',
      );
    }
  }

  static void _ensureEvidenceEnvelopeScope(
    TruthEvidenceEnvelope? evidenceEnvelope, {
    required TruthScopeDescriptor truthScope,
    required String context,
    required String label,
  }) {
    if (evidenceEnvelope == null) {
      return;
    }
    if (evidenceEnvelope.scope.scopeKey != truthScope.scopeKey) {
      throw FormatException(
        '$context $label evidence envelope must match the planning truth scope.',
      );
    }
  }

  static void _validateTagGroup({
    required String label,
    required List<String> tags,
    required String context,
  }) {
    if (tags.length > 6) {
      throw FormatException('$context $label cannot exceed 6 sanitized tags.');
    }

    for (final tag in tags) {
      final normalized = tag.trim();
      if (!_sanitizedTagPattern.hasMatch(normalized)) {
        throw FormatException(
          '$context $label must contain only bounded sanitized tags.',
        );
      }
    }
  }
}

const Object _eventPlanningSentinel = Object();
