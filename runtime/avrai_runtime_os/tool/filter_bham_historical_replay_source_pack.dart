import 'dart:convert';
import 'dart:io';

import 'package:avrai_runtime_os/services/prediction/bham_replay_source_pack_service.dart';
import 'package:avrai_runtime_os/services/prediction/historical_replay_source_pack_filter_service.dart';

const _defaultInputPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/22_BHAM_REPLAY_SOURCE_PACK_2023_AUTOMATED.json';
const _defaultJsonOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/23_BHAM_REPLAY_HISTORICALIZED_SOURCE_PACK_2023_AUTOMATED.json';

Future<void> main(List<String> args) async {
  final inputPath = _readFlag(args, '--input') ?? _defaultInputPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    stderr.writeln('Missing replay source pack: $inputPath');
    exit(1);
  }

  final pack = const BhamReplaySourcePackService().parsePackJson(
    inputFile.readAsStringSync(),
  );
  final filtered =
      const HistoricalReplaySourcePackFilterService().filterHistoricalReady(pack);
  final jsonPretty = const JsonEncoder.withIndent('  ').convert(filtered.toJson());

  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync('$jsonPretty\n');

  stdout.writeln(
    'Filtered BHAM replay source pack ${pack.packId} to ${filtered.datasets.length} historical datasets.',
  );
  stdout.writeln('Wrote $jsonOut');
}

String? _readFlag(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) {
    return null;
  }
  return args[index + 1];
}
