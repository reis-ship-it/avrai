import 'package:avrai_core/models/temporal/replay_agent_kernel_bundle.dart';

class ReplayActorKernelCoverageRecord {
  const ReplayActorKernelCoverageRecord({
    required this.actorId,
    required this.localityAnchor,
    required this.hasFullBundle,
    required this.attachedKernelIds,
    required this.readyKernelIds,
    required this.activationCountByKernel,
    required this.higherAgentGuidanceCount,
    this.metadata = const <String, dynamic>{},
  });

  final String actorId;
  final String localityAnchor;
  final bool hasFullBundle;
  final List<String> attachedKernelIds;
  final List<String> readyKernelIds;
  final Map<String, int> activationCountByKernel;
  final int higherAgentGuidanceCount;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'actorId': actorId,
      'localityAnchor': localityAnchor,
      'hasFullBundle': hasFullBundle,
      'attachedKernelIds': attachedKernelIds,
      'readyKernelIds': readyKernelIds,
      'activationCountByKernel': activationCountByKernel,
      'higherAgentGuidanceCount': higherAgentGuidanceCount,
      'metadata': metadata,
    };
  }

  factory ReplayActorKernelCoverageRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReplayActorKernelCoverageRecord(
      actorId: json['actorId'] as String? ?? '',
      localityAnchor: json['localityAnchor'] as String? ?? '',
      hasFullBundle: json['hasFullBundle'] as bool? ?? false,
      attachedKernelIds: (json['attachedKernelIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      readyKernelIds: (json['readyKernelIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      activationCountByKernel: (json['activationCountByKernel'] as Map?)
              ?.map(
                (key, value) =>
                    MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
              ) ??
          const <String, int>{},
      higherAgentGuidanceCount:
          (json['higherAgentGuidanceCount'] as num?)?.toInt() ?? 0,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayActorKernelCoverageReport {
  const ReplayActorKernelCoverageReport({
    required this.environmentId,
    required this.replayYear,
    required this.requiredKernelIds,
    required this.actorCount,
    required this.actorsWithFullBundle,
    required this.records,
    required this.traces,
    this.metadata = const <String, dynamic>{},
  });

  final String environmentId;
  final int replayYear;
  final List<String> requiredKernelIds;
  final int actorCount;
  final int actorsWithFullBundle;
  final List<ReplayActorKernelCoverageRecord> records;
  final List<ReplayKernelActivationTrace> traces;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'replayYear': replayYear,
      'requiredKernelIds': requiredKernelIds,
      'actorCount': actorCount,
      'actorsWithFullBundle': actorsWithFullBundle,
      'records': records.map((entry) => entry.toJson()).toList(),
      'traces': traces.map((entry) => entry.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory ReplayActorKernelCoverageReport.fromJson(Map<String, dynamic> json) {
    return ReplayActorKernelCoverageReport(
      environmentId: json['environmentId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      requiredKernelIds: (json['requiredKernelIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      actorCount: (json['actorCount'] as num?)?.toInt() ?? 0,
      actorsWithFullBundle:
          (json['actorsWithFullBundle'] as num?)?.toInt() ?? 0,
      records: (json['records'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayActorKernelCoverageRecord.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayActorKernelCoverageRecord>[],
      traces: (json['traces'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayKernelActivationTrace.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayKernelActivationTrace>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
