import 'dart:convert';
import 'dart:io';

import 'package:avrai_runtime_os/services/prediction/authoritative_replay_year_selection_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_source_registry_service.dart';
import 'package:avrai_runtime_os/services/prediction/replay_year_completeness_service.dart';

const _defaultInputPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/03_BHAM_SOURCE_REGISTRY_DATA.json';
const _defaultMarkdownOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/06_BHAM_REPLAY_YEAR_SELECTION.md';
const _defaultJsonOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/06_BHAM_REPLAY_YEAR_SELECTION.json';

void main(List<String> args) {
  final inputPath = _readFlag(args, '--input') ?? _defaultInputPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final registry = _loadRegistry(inputPath);
  final selectionService = const AuthoritativeReplayYearSelectionService(
    completenessService: ReplayYearCompletenessService(),
  );
  final selection = selectionService.select(
    candidateYears: registry.selectionCandidateYears,
    sources: registry.sources,
  );

  final nowUtc = DateTime.now().toUtc();
  final sourceStatusCounts = <String, int>{};
  for (final source in registry.sources) {
    sourceStatusCounts.update(
      source.status.name,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }
  final provisional = registry.sources.any((source) => source.status.name != 'ingested');

  final report = <String, dynamic>{
    'generated_at_utc': nowUtc.toIso8601String(),
    'registry_id': registry.registryId,
    'registry_version': registry.registryVersion,
    'registry_generated_at_utc': registry.generatedAtUtc.toUtc().toIso8601String(),
    'registry_status': registry.status,
    'source_count': registry.sources.length,
    'selection_candidate_years': registry.selectionCandidateYears,
    'selected_year': selection.selectedScore.year,
    'selected_score': selection.selectedScore.toJson(),
    'candidate_scores': selection.candidateScores
        .map((score) => score.toJson())
        .toList(growable: false),
    'source_status_counts': sourceStatusCounts,
    'selection_state': provisional ? 'provisional_until_ingest' : 'ingested_authority',
    'notes': <String>[
      ...registry.notes,
      if (provisional)
        'Selection is provisional because one or more contributing sources are approved/candidate rather than fully ingested.',
      '2025 remains the tie-breaker year when registry completeness scores are effectively equal.',
    ],
  };

  final markdown = _buildMarkdown(report);
  final jsonPretty = const JsonEncoder.withIndent('  ').convert(report);

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(markdown);
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync('$jsonPretty\n');

  stdout.writeln(
    'Selected BHAM replay year ${selection.selectedScore.year} '
    '(${selection.selectedScore.overallScore.toStringAsFixed(3)}).',
  );
  stdout.writeln('Wrote $markdownOut and $jsonOut');
}

BhamReplaySourceRegistry _loadRegistry(String inputPath) {
  final file = File(inputPath);
  if (!file.existsSync()) {
    stderr.writeln('Missing BHAM replay source registry: $inputPath');
    exit(1);
  }

  final raw = file.readAsStringSync().trim();
  if (raw.isEmpty) {
    stderr.writeln('BHAM replay source registry is empty: $inputPath');
    exit(1);
  }

  try {
    return const BhamReplaySourceRegistryService().parseRegistryJson(raw);
  } on FormatException catch (error) {
    stderr.writeln('Invalid BHAM replay source registry: ${error.message}');
    exit(1);
  }
}

String _buildMarkdown(Map<String, dynamic> report) {
  final selectedScore =
      Map<String, dynamic>.from(report['selected_score'] as Map);
  final candidateScores = List<Map<String, dynamic>>.from(
    (report['candidate_scores'] as List)
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value))),
  );
  final statusCounts = Map<String, dynamic>.from(
    report['source_status_counts'] as Map,
  );
  final notes =
      List<String>.from(report['notes'] as List? ?? const <String>[]);

  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Year Selection')
    ..writeln()
    ..writeln('- Generated at: `${report['generated_at_utc']}`')
    ..writeln('- Registry: `${report['registry_id']}` (`${report['registry_version']}`)')
    ..writeln('- Registry status: `${report['registry_status']}`')
    ..writeln('- Source count: `${report['source_count']}`')
    ..writeln('- Selection state: `${report['selection_state']}`')
    ..writeln('- Selected year: `${report['selected_year']}`')
    ..writeln(
      '- Selected overall score: `${(selectedScore['overallScore'] as num).toStringAsFixed(3)}`',
    )
    ..writeln()
    ..writeln('## Selected Year Detail')
    ..writeln()
    ..writeln('- Event coverage: `${(selectedScore['eventCoverage'] as num).toStringAsFixed(3)}`')
    ..writeln('- Venue coverage: `${(selectedScore['venueCoverage'] as num).toStringAsFixed(3)}`')
    ..writeln(
      '- Community coverage: `${(selectedScore['communityCoverage'] as num).toStringAsFixed(3)}`',
    )
    ..writeln(
      '- Recurrence fidelity: `${(selectedScore['recurrenceFidelity'] as num).toStringAsFixed(3)}`',
    )
    ..writeln(
      '- Temporal certainty: `${(selectedScore['temporalCertainty'] as num).toStringAsFixed(3)}`',
    )
    ..writeln('- Trust quality: `${(selectedScore['trustQuality'] as num).toStringAsFixed(3)}`')
    ..writeln()
    ..writeln('## Source Status Counts')
    ..writeln();

  for (final entry in statusCounts.entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Candidate Year Scores')
    ..writeln();

  for (final score in candidateScores) {
    buffer.writeln(
      '- `${score['year']}`: `${(score['overallScore'] as num).toStringAsFixed(3)}`'
      ' (events `${(score['eventCoverage'] as num).toStringAsFixed(3)}`,'
      ' venues `${(score['venueCoverage'] as num).toStringAsFixed(3)}`,'
      ' communities `${(score['communityCoverage'] as num).toStringAsFixed(3)}`)',
    );
  }

  buffer
    ..writeln()
    ..writeln('## Notes')
    ..writeln();

  for (final note in notes) {
    buffer.writeln('- $note');
  }

  return '$buffer';
}

String? _readFlag(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) {
    return null;
  }
  return args[index + 1];
}
