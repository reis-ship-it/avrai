import 'dart:convert';
import 'dart:io';

import 'package:avrai_runtime_os/services/prediction/bham_event_scenario_pack_service.dart';

const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/71_BHAM_REPLAY_SCENARIO_PACKETS_2023.json';

Future<void> main(List<String> args) async {
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;
  final packets = const BhamEventScenarioPackService().buildScenarioPack(
    createdAt: DateTime.utc(2026, 3, 14),
  );
  final file = File(jsonOut)..createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(packets.map((entry) => entry.toJson()).toList())}\n',
  );
  stdout.writeln('Wrote ${packets.length} BHAM replay scenario packets.');
}

String? _readFlag(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) {
    return null;
  }
  return args[index + 1];
}
