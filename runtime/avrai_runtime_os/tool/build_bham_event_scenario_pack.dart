import 'dart:convert';
import 'dart:io';

import 'package:avrai_runtime_os/services/prediction/bham_event_scenario_pack_service.dart';

const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/72_BHAM_EVENT_SCENARIO_PACK_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/72_BHAM_EVENT_SCENARIO_PACK_2023.json';

Future<void> main(List<String> args) async {
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;
  final packets = const BhamEventScenarioPackService().buildScenarioPack(
    createdAt: DateTime.utc(2026, 3, 14),
  );

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(packets));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(packets.map((entry) => entry.toJson()).toList())}\n',
    );

  stdout.writeln('Wrote BHAM event scenario pack.');
}

String _buildMarkdown(List<dynamic> packets) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Event Scenario Pack')
    ..writeln()
    ..writeln(
      'Internal Birmingham replay-only scenario pack for phase-1 simulation improvement work.',
    )
    ..writeln();
  for (final packet in packets) {
    buffer
      ..writeln('## ${packet.name}')
      ..writeln()
      ..writeln('- Scenario ID: `${packet.scenarioId}`')
      ..writeln('- Kind: `${packet.scenarioKind.toString().split('.').last}`')
      ..writeln('- Scope: `${packet.scope.toString().split('.').last}`')
      ..writeln('- Localities: `${packet.seedLocalityCodes.join(', ')}`')
      ..writeln(
        '- Interventions: `${packet.interventions.map((entry) => entry.kind.toString().split('.').last).join(', ')}`',
      )
      ..writeln();
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
