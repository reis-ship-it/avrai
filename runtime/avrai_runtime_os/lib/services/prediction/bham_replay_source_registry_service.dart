import 'dart:convert';

import 'package:avrai_core/avra_core.dart';

class BhamReplaySourceRegistry {
  const BhamReplaySourceRegistry({
    required this.registryId,
    required this.registryVersion,
    required this.generatedAtUtc,
    required this.status,
    required this.selectionCandidateYears,
    required this.sources,
    this.notes = const <String>[],
  });

  final String registryId;
  final String registryVersion;
  final DateTime generatedAtUtc;
  final String status;
  final List<int> selectionCandidateYears;
  final List<ReplaySourceDescriptor> sources;
  final List<String> notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'registryId': registryId,
      'registryVersion': registryVersion,
      'generatedAtUtc': generatedAtUtc.toUtc().toIso8601String(),
      'status': status,
      'selectionCandidateYears': selectionCandidateYears,
      'notes': notes,
      'sources': sources.map((source) => source.toJson()).toList(),
    };
  }
}

class BhamReplaySourceRegistryService {
  const BhamReplaySourceRegistryService();

  BhamReplaySourceRegistry parseRegistryJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      throw const FormatException(
        'BHAM replay source registry must decode to a JSON object.',
      );
    }
    return parseRegistryObject(
      decoded.map((key, value) => MapEntry('$key', value)),
    );
  }

  BhamReplaySourceRegistry parseRegistryObject(Map<String, dynamic> json) {
    final candidateYears = (json['selectionCandidateYears'] as List?)
            ?.map((entry) => (entry as num).toInt())
            .toList() ??
        const <int>[];
    final rawSources = (json['sources'] as List?)
            ?.whereType<Map>()
            .map((entry) => entry.map((key, value) => MapEntry('$key', value)))
            .toList() ??
        const <Map<String, dynamic>>[];

    if (candidateYears.isEmpty) {
      throw const FormatException(
        'BHAM replay source registry must declare selectionCandidateYears.',
      );
    }
    if (rawSources.isEmpty) {
      throw const FormatException(
        'BHAM replay source registry must contain at least one source.',
      );
    }

    return BhamReplaySourceRegistry(
      registryId: json['registryId'] as String? ?? 'bham-replay-registry',
      registryVersion: json['registryVersion'] as String? ?? 'unknown',
      generatedAtUtc:
          DateTime.tryParse(json['generatedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      status: json['status'] as String? ?? 'draft',
      selectionCandidateYears: candidateYears,
      notes: (json['notes'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      sources: rawSources
          .map(ReplaySourceDescriptor.fromJson)
          .toList(growable: false),
    );
  }
}
