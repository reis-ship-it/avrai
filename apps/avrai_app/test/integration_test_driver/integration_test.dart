import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test_driver.dart';

void main() {
  // Unit/coverage runs do not expose the driver VM service endpoint.
  if (!Platform.environment.containsKey('VM_SERVICE_URL')) {
    test('integration driver skipped without VM service URL', () {
      expect(true, isTrue);
    });
    return;
  }

  test('integration driver bootstraps with VM service URL', () async {
    await integrationDriver();
  });
}
