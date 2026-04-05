import 'package:avrai_core/models/kernel_graph/kernel_graph_models.dart';
import 'package:avrai_core/models/reality/governed_learning_adoption_receipt.dart';
import 'package:avrai_core/models/reality/governed_learning_chat_observation_receipt.dart';
import 'package:avrai_core/models/reality/governed_learning_usage_receipt.dart';

enum UserGovernedLearningAction {
  showDetails,
  correctRecord,
  forgetRecord,
  stopUsingSignal,
  openDataCenter,
}

class UserVisibleGovernedLearningRecord {
  const UserVisibleGovernedLearningRecord({
    required this.envelopeId,
    required this.sourceId,
    required this.title,
    required this.safeSummary,
    required this.sourceLabel,
    required this.sourceProvider,
    required this.convictionTier,
    required this.occurredAtUtc,
    required this.stagedAtUtc,
    required this.requiresHumanReview,
    this.domainHints = const <String>[],
    this.referencedEntities = const <String>[],
    this.kernelGraphStatus,
    this.futureSignalUseBlocked = false,
    this.usageCount = 0,
    this.lastUsedAtUtc,
    this.appliedDomains = const <String>[],
    this.recentUsageReceipts = const <GovernedLearningUsageReceipt>[],
    this.currentAdoptionStatus,
    this.pendingSurfaces = const <String>[],
    this.surfacedSurfaces = const <String>[],
    this.firstSurfacedAtUtc,
    this.recentAdoptionReceipts = const <GovernedLearningAdoptionReceipt>[],
    this.recentChatObservations =
        const <GovernedLearningChatObservationReceipt>[],
    this.availableActions = const <UserGovernedLearningAction>[],
  });

  final String envelopeId;
  final String sourceId;
  final String title;
  final String safeSummary;
  final String sourceLabel;
  final String sourceProvider;
  final String convictionTier;
  final DateTime occurredAtUtc;
  final DateTime stagedAtUtc;
  final bool requiresHumanReview;
  final List<String> domainHints;
  final List<String> referencedEntities;
  final KernelGraphRunStatus? kernelGraphStatus;
  final bool futureSignalUseBlocked;
  final int usageCount;
  final DateTime? lastUsedAtUtc;
  final List<String> appliedDomains;
  final List<GovernedLearningUsageReceipt> recentUsageReceipts;
  final GovernedLearningAdoptionStatus? currentAdoptionStatus;
  final List<String> pendingSurfaces;
  final List<String> surfacedSurfaces;
  final DateTime? firstSurfacedAtUtc;
  final List<GovernedLearningAdoptionReceipt> recentAdoptionReceipts;
  final List<GovernedLearningChatObservationReceipt> recentChatObservations;
  final List<UserGovernedLearningAction> availableActions;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'envelopeId': envelopeId,
        'sourceId': sourceId,
        'title': title,
        'safeSummary': safeSummary,
        'sourceLabel': sourceLabel,
        'sourceProvider': sourceProvider,
        'convictionTier': convictionTier,
        'occurredAtUtc': occurredAtUtc.toUtc().toIso8601String(),
        'stagedAtUtc': stagedAtUtc.toUtc().toIso8601String(),
        'requiresHumanReview': requiresHumanReview,
        'domainHints': domainHints,
        'referencedEntities': referencedEntities,
        'kernelGraphStatus': kernelGraphStatus?.name,
        'futureSignalUseBlocked': futureSignalUseBlocked,
        'usageCount': usageCount,
        'lastUsedAtUtc': lastUsedAtUtc?.toUtc().toIso8601String(),
        'appliedDomains': appliedDomains,
        'recentUsageReceipts':
            recentUsageReceipts.map((entry) => entry.toJson()).toList(),
        'currentAdoptionStatus': currentAdoptionStatus?.name,
        'pendingSurfaces': pendingSurfaces,
        'surfacedSurfaces': surfacedSurfaces,
        'firstSurfacedAtUtc': firstSurfacedAtUtc?.toUtc().toIso8601String(),
        'recentAdoptionReceipts':
            recentAdoptionReceipts.map((entry) => entry.toJson()).toList(),
        'recentChatObservations':
            recentChatObservations.map((entry) => entry.toJson()).toList(),
        'availableActions':
            availableActions.map((entry) => entry.name).toList(growable: false),
      };

  factory UserVisibleGovernedLearningRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    return UserVisibleGovernedLearningRecord(
      envelopeId: json['envelopeId']?.toString() ?? '',
      sourceId: json['sourceId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      safeSummary: json['safeSummary']?.toString() ?? '',
      sourceLabel: json['sourceLabel']?.toString() ?? '',
      sourceProvider: json['sourceProvider']?.toString() ?? '',
      convictionTier: json['convictionTier']?.toString() ?? '',
      occurredAtUtc: _parseDateTime(json['occurredAtUtc']),
      stagedAtUtc: _parseDateTime(json['stagedAtUtc']),
      requiresHumanReview: json['requiresHumanReview'] as bool? ?? false,
      domainHints: _stringList(json['domainHints']),
      referencedEntities: _stringList(json['referencedEntities']),
      kernelGraphStatus: _parseKernelGraphRunStatus(json['kernelGraphStatus']),
      futureSignalUseBlocked: json['futureSignalUseBlocked'] as bool? ?? false,
      usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
      lastUsedAtUtc: json['lastUsedAtUtc'] != null
          ? _parseDateTime(json['lastUsedAtUtc'])
          : null,
      appliedDomains: _stringList(json['appliedDomains']),
      recentUsageReceipts: _mapList(json['recentUsageReceipts'])
          .map(GovernedLearningUsageReceipt.fromJson)
          .toList(growable: false),
      currentAdoptionStatus: _parseGovernedLearningAdoptionStatusNullable(
        json['currentAdoptionStatus'],
      ),
      pendingSurfaces: _stringList(json['pendingSurfaces']),
      surfacedSurfaces: _stringList(json['surfacedSurfaces']),
      firstSurfacedAtUtc: json['firstSurfacedAtUtc'] != null
          ? _parseDateTime(json['firstSurfacedAtUtc'])
          : null,
      recentAdoptionReceipts: _mapList(json['recentAdoptionReceipts'])
          .map(GovernedLearningAdoptionReceipt.fromJson)
          .toList(growable: false),
      recentChatObservations: _mapList(json['recentChatObservations'])
          .map(GovernedLearningChatObservationReceipt.fromJson)
          .toList(growable: false),
      availableActions: _actionList(json['availableActions']),
    );
  }
}

class UserGovernedLearningExplanation {
  const UserGovernedLearningExplanation({
    required this.summary,
    this.details = const <String>[],
    this.records = const <UserVisibleGovernedLearningRecord>[],
    this.selectedRecord,
    this.suggestedActions = const <UserGovernedLearningAction>[],
  });

  final String summary;
  final List<String> details;
  final List<UserVisibleGovernedLearningRecord> records;
  final UserVisibleGovernedLearningRecord? selectedRecord;
  final List<UserGovernedLearningAction> suggestedActions;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'summary': summary,
        'details': details,
        'records':
            records.map((entry) => entry.toJson()).toList(growable: false),
        'selectedRecord': selectedRecord?.toJson(),
        'suggestedActions':
            suggestedActions.map((entry) => entry.name).toList(growable: false),
      };

  factory UserGovernedLearningExplanation.fromJson(
    Map<String, dynamic> json,
  ) {
    return UserGovernedLearningExplanation(
      summary: json['summary']?.toString() ?? '',
      details: _stringList(json['details']),
      records: _mapList(json['records'])
          .map(UserVisibleGovernedLearningRecord.fromJson)
          .toList(growable: false),
      selectedRecord: _singleMap(json['selectedRecord']) != null
          ? UserVisibleGovernedLearningRecord.fromJson(
              _singleMap(json['selectedRecord'])!,
            )
          : null,
      suggestedActions: _actionList(json['suggestedActions']),
    );
  }
}

DateTime _parseDateTime(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '')?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

KernelGraphRunStatus? _parseKernelGraphRunStatus(Object? value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  for (final status in KernelGraphRunStatus.values) {
    if (status.name == raw) {
      return status;
    }
  }
  return null;
}

GovernedLearningAdoptionStatus? _parseGovernedLearningAdoptionStatusNullable(
  Object? value,
) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  for (final status in GovernedLearningAdoptionStatus.values) {
    if (status.name == raw) {
      return status;
    }
  }
  return null;
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.map((entry) => entry.toString()).toList(growable: false);
  }
  return const <String>[];
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

Map<String, dynamic>? _singleMap(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

List<UserGovernedLearningAction> _actionList(Object? value) {
  final names = _stringList(value);
  return names
      .map(
        (name) => UserGovernedLearningAction.values.firstWhere(
          (entry) => entry.name == name,
          orElse: () => UserGovernedLearningAction.showDetails,
        ),
      )
      .toList(growable: false);
}
