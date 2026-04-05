import 'dart:convert';
import 'dart:io';

import 'package:avrai_runtime_os/services/prediction/bham_public_catalog_historicalization_candidate_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_source_pack_service.dart';

const _defaultInputPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/22_BHAM_REPLAY_SOURCE_PACK_2023_AUTOMATED.json';
const _defaultMarkdownOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/29_BHAM_PUBLIC_CATALOG_HISTORICALIZATION_CANDIDATES_2023.md';
const _defaultJsonOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/29_BHAM_PUBLIC_CATALOG_HISTORICALIZATION_CANDIDATES_2023.json';

Future<void> main(List<String> args) async {
  final inputPath = _readFlag(args, '--input') ?? _defaultInputPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    stderr.writeln('Missing replay source pack: $inputPath');
    exit(1);
  }

  final pack = const BhamReplaySourcePackService().parsePackJson(
    inputFile.readAsStringSync(),
  );
  final candidates =
      const BhamPublicCatalogHistoricalizationCandidateService().buildCandidates(
    pack,
  );

  final jsonObject = <String, dynamic>{
    'replayYear': pack.replayYear,
    'candidateCount': candidates.length,
    'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
    'candidates': candidates,
  };
  final jsonPretty = const JsonEncoder.withIndent('  ').convert(jsonObject);

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(pack.replayYear, candidates));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync('$jsonPretty\n');

  stdout.writeln(
    'Built BHAM public catalog historicalization candidates for ${pack.replayYear}.',
  );
  stdout.writeln('Wrote $markdownOut and $jsonOut');
}

String _buildMarkdown(int replayYear, List<Map<String, dynamic>> candidates) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Public Catalog Historicalization Candidates')
    ..writeln()
    ..writeln('- Replay year: `$replayYear`')
    ..writeln('- Candidate sources: `${candidates.length}`')
    ..writeln()
    ..writeln('These sources are operational in the automated replay path,')
    ..writeln('but are still current/public catalogs rather than governed 2023 historical truth.')
    ..writeln();

  for (final candidate in candidates) {
    buffer
      ..writeln('## ${candidate['sourceName']}')
      ..writeln()
      ..writeln('- Coverage status: `${candidate['coverageStatus']}`')
      ..writeln('- Record count: `${candidate['recordCount']}`')
      ..writeln('- Source URI: `${candidate['sourceUri']}`')
      ..writeln('- Historicalization target: ${candidate['historicalizationTarget']}')
      ..writeln()
      ..writeln('### Sample Records')
      ..writeln();
    final samples =
        (candidate['sampleRecords'] as List?)?.whereType<Map>().toList() ?? const <Map>[];
    for (final sample in samples) {
      buffer.writeln(
        '- `${sample['entityType']}` ${sample['name']}'
        ' (`${sample['locality'] ?? 'unknown'}`)',
      );
    }
    buffer.writeln();
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
