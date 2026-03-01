// TODO(Phase 26): Sembast datasource was removed during the GetStorage migration.
// SpotsSembastDataSource no longer exists. These tests are obsolete.
// Spots data is now stored via StorageService (GetStorage).
// See lib/core/services/infrastructure/storage_service.dart for the replacement.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpotsSembastDataSource [OBSOLETE]', () {
    test('Sembast datasource removed - tests obsolete', () {
      // SpotsSembastDataSource was removed in Phase 26 (Sembast → GetStorage migration).
      // This file is kept as a placeholder. Spots storage tests should target
      // StorageService or the new spots data layer.
      expect(true, isTrue);
    });
  });
}
