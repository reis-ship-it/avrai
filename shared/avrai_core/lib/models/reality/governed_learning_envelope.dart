import 'package:avrai_core/models/kernel_graph/kernel_graph_models.dart';

class GovernedLearningAirGapSummary {
  const GovernedLearningAirGapSummary({
    required this.artifactVersion,
    required this.receiptId,
    required this.contentSha256,
    required this.originPlane,
    required this.sourceScope,
    required this.destinationCeiling,
    required this.issuedAtUtc,
    required this.expiresAtUtc,
    this.allowedNextStages = const <String>[],
    this.pseudonymousActorRef,
  });

  final String artifactVersion;
  final String receiptId;
  final String contentSha256;
  final String originPlane;
  final String sourceScope;
  final String destinationCeiling;
  final DateTime issuedAtUtc;
  final DateTime expiresAtUtc;
  final List<String> allowedNextStages;
  final String? pseudonymousActorRef;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'artifactVersion': artifactVersion,
        'receiptId': receiptId,
        'contentSha256': contentSha256,
        'originPlane': originPlane,
        'sourceScope': sourceScope,
        'destinationCeiling': destinationCeiling,
        'issuedAtUtc': issuedAtUtc.toUtc().toIso8601String(),
        'expiresAtUtc': expiresAtUtc.toUtc().toIso8601String(),
        'allowedNextStages': allowedNextStages,
        'pseudonymousActorRef': pseudonymousActorRef,
      };

  factory GovernedLearningAirGapSummary.fromJson(Map<String, dynamic> json) {
    return GovernedLearningAirGapSummary(
      artifactVersion: json['artifactVersion']?.toString() ?? '0.1',
      receiptId: json['receiptId']?.toString() ?? '',
      contentSha256: json['contentSha256']?.toString() ?? '',
      originPlane: json['originPlane']?.toString() ?? 'unknown',
      sourceScope: json['sourceScope']?.toString() ?? 'unknown',
      destinationCeiling:
          json['destinationCeiling']?.toString() ?? 'reality_model_agent',
      issuedAtUtc: _parseDateTime(json['issuedAtUtc']),
      expiresAtUtc: _parseDateTime(json['expiresAtUtc']),
      allowedNextStages: _stringList(json['allowedNextStages']),
      pseudonymousActorRef: json['pseudonymousActorRef']?.toString(),
    );
  }
}

class GovernedLearningEnvelope {
  const GovernedLearningEnvelope({
    required this.id,
    required this.ownerUserId,
    required this.sourceId,
    required this.reviewItemId,
    required this.jobId,
    required this.sourceProvider,
    required this.sourceKind,
    required this.sourceLabel,
    required this.title,
    required this.safeSummary,
    required this.queueKind,
    required this.learningDirection,
    required this.learningPathway,
    required this.convictionTier,
    required this.hierarchyPath,
    required this.occurredAtUtc,
    required this.stagedAtUtc,
    required this.requiresHumanReview,
    required this.temporalLineage,
    this.cityCode,
    this.localityCode,
    this.surface,
    this.channel,
    this.domainHints = const <String>[],
    this.referencedEntities = const <String>[],
    this.questions = const <String>[],
    this.preferenceSignals = const <Map<String, dynamic>>[],
    this.signalTags = const <String>[],
    this.kernelGraphSpecId,
    this.kernelGraphRunId,
    this.kernelGraphStatus,
    this.kernelGraphAdminDigest,
    this.airGap,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String ownerUserId;
  final String sourceId;
  final String reviewItemId;
  final String jobId;
  final String sourceProvider;
  final String sourceKind;
  final String sourceLabel;
  final String title;
  final String safeSummary;
  final String queueKind;
  final String learningDirection;
  final String learningPathway;
  final String convictionTier;
  final List<String> hierarchyPath;
  final DateTime occurredAtUtc;
  final DateTime stagedAtUtc;
  final bool requiresHumanReview;
  final Map<String, dynamic> temporalLineage;
  final String? cityCode;
  final String? localityCode;
  final String? surface;
  final String? channel;
  final List<String> domainHints;
  final List<String> referencedEntities;
  final List<String> questions;
  final List<Map<String, dynamic>> preferenceSignals;
  final List<String> signalTags;
  final String? kernelGraphSpecId;
  final String? kernelGraphRunId;
  final KernelGraphRunStatus? kernelGraphStatus;
  final KernelGraphAdminDigest? kernelGraphAdminDigest;
  final GovernedLearningAirGapSummary? airGap;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'ownerUserId': ownerUserId,
        'sourceId': sourceId,
        'reviewItemId': reviewItemId,
        'jobId': jobId,
        'sourceProvider': sourceProvider,
        'sourceKind': sourceKind,
        'sourceLabel': sourceLabel,
        'title': title,
        'safeSummary': safeSummary,
        'queueKind': queueKind,
        'learningDirection': learningDirection,
        'learningPathway': learningPathway,
        'convictionTier': convictionTier,
        'hierarchyPath': hierarchyPath,
        'occurredAtUtc': occurredAtUtc.toUtc().toIso8601String(),
        'stagedAtUtc': stagedAtUtc.toUtc().toIso8601String(),
        'requiresHumanReview': requiresHumanReview,
        'temporalLineage': temporalLineage,
        'cityCode': cityCode,
        'localityCode': localityCode,
        'surface': surface,
        'channel': channel,
        'domainHints': domainHints,
        'referencedEntities': referencedEntities,
        'questions': questions,
        'preferenceSignals': preferenceSignals,
        'signalTags': signalTags,
        'kernelGraphSpecId': kernelGraphSpecId,
        'kernelGraphRunId': kernelGraphRunId,
        'kernelGraphStatus': kernelGraphStatus?.name,
        'kernelGraphAdminDigest': kernelGraphAdminDigest?.toJson(),
        'airGap': airGap?.toJson(),
        'metadata': metadata,
      };

  factory GovernedLearningEnvelope.fromJson(Map<String, dynamic> json) {
    return GovernedLearningEnvelope(
      id: json['id']?.toString() ?? '',
      ownerUserId: json['ownerUserId']?.toString() ?? '',
      sourceId: json['sourceId']?.toString() ?? '',
      reviewItemId: json['reviewItemId']?.toString() ?? '',
      jobId: json['jobId']?.toString() ?? '',
      sourceProvider: json['sourceProvider']?.toString() ?? '',
      sourceKind: json['sourceKind']?.toString() ?? '',
      sourceLabel: json['sourceLabel']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      safeSummary: json['safeSummary']?.toString() ?? '',
      queueKind: json['queueKind']?.toString() ?? '',
      learningDirection: json['learningDirection']?.toString() ?? '',
      learningPathway: json['learningPathway']?.toString() ?? '',
      convictionTier: json['convictionTier']?.toString() ?? '',
      hierarchyPath: _stringList(json['hierarchyPath']),
      occurredAtUtc: _parseDateTime(json['occurredAtUtc']),
      stagedAtUtc: _parseDateTime(json['stagedAtUtc']),
      requiresHumanReview: json['requiresHumanReview'] as bool? ?? false,
      temporalLineage: _map(json['temporalLineage']),
      cityCode: json['cityCode']?.toString(),
      localityCode: json['localityCode']?.toString(),
      surface: json['surface']?.toString(),
      channel: json['channel']?.toString(),
      domainHints: _stringList(json['domainHints']),
      referencedEntities: _stringList(json['referencedEntities']),
      questions: _stringList(json['questions']),
      preferenceSignals: _mapList(json['preferenceSignals']),
      signalTags: _stringList(json['signalTags']),
      kernelGraphSpecId: json['kernelGraphSpecId']?.toString(),
      kernelGraphRunId: json['kernelGraphRunId']?.toString(),
      kernelGraphStatus: _parseKernelGraphRunStatus(json['kernelGraphStatus']),
      kernelGraphAdminDigest: json['kernelGraphAdminDigest'] is Map
          ? KernelGraphAdminDigest.fromJson(
              Map<String, dynamic>.from(json['kernelGraphAdminDigest'] as Map),
            )
          : null,
      airGap: json['airGap'] is Map
          ? GovernedLearningAirGapSummary.fromJson(
              Map<String, dynamic>.from(json['airGap'] as Map),
            )
          : null,
      metadata: _map(json['metadata']),
    );
  }

  GovernedLearningEnvelope copyWith({
    String? id,
    String? ownerUserId,
    String? sourceId,
    String? reviewItemId,
    String? jobId,
    String? sourceProvider,
    String? sourceKind,
    String? sourceLabel,
    String? title,
    String? safeSummary,
    String? queueKind,
    String? learningDirection,
    String? learningPathway,
    String? convictionTier,
    List<String>? hierarchyPath,
    DateTime? occurredAtUtc,
    DateTime? stagedAtUtc,
    bool? requiresHumanReview,
    Map<String, dynamic>? temporalLineage,
    Object? cityCode = _governedLearningSentinel,
    Object? localityCode = _governedLearningSentinel,
    Object? surface = _governedLearningSentinel,
    Object? channel = _governedLearningSentinel,
    List<String>? domainHints,
    List<String>? referencedEntities,
    List<String>? questions,
    List<Map<String, dynamic>>? preferenceSignals,
    List<String>? signalTags,
    Object? kernelGraphSpecId = _governedLearningSentinel,
    Object? kernelGraphRunId = _governedLearningSentinel,
    Object? kernelGraphStatus = _governedLearningSentinel,
    Object? kernelGraphAdminDigest = _governedLearningSentinel,
    Object? airGap = _governedLearningSentinel,
    Map<String, dynamic>? metadata,
  }) {
    return GovernedLearningEnvelope(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      sourceId: sourceId ?? this.sourceId,
      reviewItemId: reviewItemId ?? this.reviewItemId,
      jobId: jobId ?? this.jobId,
      sourceProvider: sourceProvider ?? this.sourceProvider,
      sourceKind: sourceKind ?? this.sourceKind,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      title: title ?? this.title,
      safeSummary: safeSummary ?? this.safeSummary,
      queueKind: queueKind ?? this.queueKind,
      learningDirection: learningDirection ?? this.learningDirection,
      learningPathway: learningPathway ?? this.learningPathway,
      convictionTier: convictionTier ?? this.convictionTier,
      hierarchyPath: hierarchyPath ?? this.hierarchyPath,
      occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
      stagedAtUtc: stagedAtUtc ?? this.stagedAtUtc,
      requiresHumanReview: requiresHumanReview ?? this.requiresHumanReview,
      temporalLineage: temporalLineage ?? this.temporalLineage,
      cityCode: cityCode == _governedLearningSentinel
          ? this.cityCode
          : cityCode as String?,
      localityCode: localityCode == _governedLearningSentinel
          ? this.localityCode
          : localityCode as String?,
      surface: surface == _governedLearningSentinel
          ? this.surface
          : surface as String?,
      channel: channel == _governedLearningSentinel
          ? this.channel
          : channel as String?,
      domainHints: domainHints ?? this.domainHints,
      referencedEntities: referencedEntities ?? this.referencedEntities,
      questions: questions ?? this.questions,
      preferenceSignals: preferenceSignals ?? this.preferenceSignals,
      signalTags: signalTags ?? this.signalTags,
      kernelGraphSpecId: kernelGraphSpecId == _governedLearningSentinel
          ? this.kernelGraphSpecId
          : kernelGraphSpecId as String?,
      kernelGraphRunId: kernelGraphRunId == _governedLearningSentinel
          ? this.kernelGraphRunId
          : kernelGraphRunId as String?,
      kernelGraphStatus: kernelGraphStatus == _governedLearningSentinel
          ? this.kernelGraphStatus
          : kernelGraphStatus as KernelGraphRunStatus?,
      kernelGraphAdminDigest:
          kernelGraphAdminDigest == _governedLearningSentinel
              ? this.kernelGraphAdminDigest
              : kernelGraphAdminDigest as KernelGraphAdminDigest?,
      airGap: airGap == _governedLearningSentinel
          ? this.airGap
          : airGap as GovernedLearningAirGapSummary?,
      metadata: metadata ?? this.metadata,
    );
  }
}

const Object _governedLearningSentinel = Object();

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.map((entry) => entry.toString()).toList(growable: false);
  }
  return const <String>[];
}

DateTime _parseDateTime(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '')?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

KernelGraphRunStatus? _parseKernelGraphRunStatus(Object? value) {
  final name = value?.toString();
  if (name == null || name.isEmpty) {
    return null;
  }
  for (final status in KernelGraphRunStatus.values) {
    if (status.name == name) {
      return status;
    }
  }
  return null;
}
