import 'dart:convert';
import 'dart:io';

import 'package:avrai_runtime_os/services/prediction/bham_replay_manual_import_bundle_service.dart';

const _defaultBundlePath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/11_BHAM_REPLAY_PRIORITY_MANUAL_IMPORT_BUNDLE_2023.json';
const _defaultJsonOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/11_BHAM_REPLAY_PRIORITY_MANUAL_SOURCE_PACK_2023.json';

void main(List<String> args) {
  final bundlePath = _resolvePath(
    _readFlag(args, '--bundle') ?? _defaultBundlePath,
  );
  final jsonOut = _resolvePath(
    _readFlag(args, '--json-out') ?? _defaultJsonOutPath,
  );

  final service = const BhamReplayManualImportBundleService();
  final bundle = service.parseBundleJson(_loadBundleJson(bundlePath));
  final validation = service.validateBundle(bundle);
  if (!validation.isValid) {
    final issueSummary = validation.issues
        .map(
          (issue) =>
              '${issue.sourceName}[${issue.recordIndex}] missing ${issue.missingFields.join(', ')}',
        )
        .join('\n');
    stderr.writeln('Manual-import bundle validation failed:\n$issueSummary');
    exit(1);
  }

  final pack = service.toReplaySourcePack(bundle);
  final jsonPretty = const JsonEncoder.withIndent('  ').convert(pack.toJson());

  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync('$jsonPretty\n');

  stdout.writeln(
    'Converted BHAM manual-import bundle ${bundle.bundleId} to a replay source pack.',
  );
  stdout.writeln('Wrote $jsonOut');
}

String _loadBundleJson(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Missing replay manual-import bundle: $path');
    exit(1);
  }
  final raw = file.readAsStringSync().trim();
  if (raw.isEmpty) {
    stderr.writeln('Replay manual-import bundle is empty: $path');
    exit(1);
  }
  return raw;
}

String? _readFlag(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) {
    return null;
  }
  return args[index + 1];
}

String _resolvePath(String rawPath) {
  final direct = File(rawPath);
  if (direct.existsSync() || direct.parent.existsSync()) {
    return direct.path;
  }

  final runtimeRelative = File('runtime/avrai_runtime_os/$rawPath');
  if (runtimeRelative.existsSync() || runtimeRelative.parent.existsSync()) {
    return runtimeRelative.path;
  }

  return rawPath;
}
