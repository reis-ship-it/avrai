import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

const List<String> _bundleArtifactFiles = <String>[
  'ledger_rows.csv',
  'ledger_rows.jsonl',
  'background_wake_runs.json',
  'field_validation_proofs.json',
  'ambient_social_diagnostics.json',
];

Future<void> main() async {
  if (!Platform.environment.containsKey('VM_SERVICE_URL')) {
    return;
  }

  final responsePath = Platform.environment['SIMULATED_SMOKE_RESPONSE_PATH'];
  await integrationDriver(
    responseDataCallback: (Map<String, dynamic>? data) async {
      if (responsePath == null || responsePath.isEmpty) {
        return;
      }
      final file = File(responsePath);
      await file.parent.create(recursive: true);
      await _copyBundleArtifactsIfAvailable(
        data: data,
        destinationDirectory: file.parent,
      );
      await file.writeAsString(jsonEncode(data ?? <String, dynamic>{}));
    },
  );
}

Future<void> _copyBundleArtifactsIfAvailable({
  required Map<String, dynamic>? data,
  required Directory destinationDirectory,
}) async {
  final exportDirectoryPath = data?['export_directory_path']?.toString();
  if (exportDirectoryPath == null || exportDirectoryPath.isEmpty) {
    return;
  }
  final exportDirectory = Directory(exportDirectoryPath);
  if (exportDirectory.existsSync()) {
    for (final fileName in _bundleArtifactFiles) {
      final source = File('${exportDirectory.path}/$fileName');
      if (!source.existsSync()) {
        continue;
      }
      await source.copy('${destinationDirectory.path}/$fileName');
    }
    return;
  }
  final platformMode = data?['platform_mode']?.toString();
  if (platformMode == 'android') {
    await _copyAndroidBundleArtifacts(
      exportDirectoryPath: exportDirectoryPath,
      destinationDirectory: destinationDirectory,
    );
  }
}

Future<void> _copyAndroidBundleArtifacts({
  required String exportDirectoryPath,
  required Directory destinationDirectory,
}) async {
  final deviceId = Platform.environment['SIMULATED_SMOKE_DEVICE_ID'];
  if (deviceId == null || deviceId.isEmpty) {
    return;
  }
  final adbBin = Platform.environment['SIMULATED_SMOKE_ADB_BIN'];
  if (adbBin == null || adbBin.isEmpty) {
    return;
  }
  final packageId = _androidPackageIdFromExportPath(exportDirectoryPath);
  if (packageId == null || packageId.isEmpty) {
    return;
  }
  for (final fileName in _bundleArtifactFiles) {
    final remoteFilePath = '$exportDirectoryPath/$fileName';
    final process = await Process.start(adbBin, <String>[
      '-s',
      deviceId,
      'exec-out',
      'run-as',
      packageId,
      'sh',
      '-c',
      "cat '$remoteFilePath'",
    ]);
    final stdoutBytes = await process.stdout.fold<List<int>>(<int>[], (
      buffer,
      chunk,
    ) {
      buffer.addAll(chunk);
      return buffer;
    });
    final stderrText = await utf8.decoder.bind(process.stderr).join();
    final exitCode = await process.exitCode;
    if (exitCode != 0 || stdoutBytes.isEmpty || stderrText.isNotEmpty) {
      continue;
    }
    final destinationFile = File('${destinationDirectory.path}/$fileName');
    await destinationFile.writeAsBytes(stdoutBytes, flush: true);
  }
}

String? _androidPackageIdFromExportPath(String exportDirectoryPath) {
  final marker = '/data/user/0/';
  final markerIndex = exportDirectoryPath.indexOf(marker);
  if (markerIndex == -1) {
    return null;
  }
  final remainder = exportDirectoryPath.substring(markerIndex + marker.length);
  final separatorIndex = remainder.indexOf('/');
  if (separatorIndex == -1) {
    return null;
  }
  return remainder.substring(0, separatorIndex);
}
