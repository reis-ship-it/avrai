import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() async {
  if (!Platform.environment.containsKey('VM_SERVICE_URL')) {
    return;
  }

  final responsePath =
      Platform.environment['EVENT_PLANNING_SMOKE_RESPONSE_PATH'];
  await integrationDriver(
    responseDataCallback: (Map<String, dynamic>? data) async {
      if (responsePath == null || responsePath.isEmpty) {
        return;
      }
      final file = File(responsePath);
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(data ?? <String, dynamic>{}));
    },
  );
}
