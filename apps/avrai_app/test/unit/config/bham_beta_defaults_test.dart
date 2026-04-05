import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/config/bham_beta_defaults.dart';

void main() {
  group('BhamBetaDefaults', () {
    test('business account surfaces stay disconnected by default for launch',
        () {
      expect(BhamBetaDefaults.enableBusinessAccountSurfaces, isFalse);
    });

    test('partnership surfaces stay disconnected by default for launch', () {
      expect(BhamBetaDefaults.enablePartnershipSurfaces, isFalse);
    });
  });
}
