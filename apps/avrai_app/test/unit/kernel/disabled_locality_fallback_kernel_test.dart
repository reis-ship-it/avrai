import 'package:avrai_runtime_os/kernel/locality/legacy/disabled_locality_fallback_kernel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DisabledLocalityFallbackKernel', () {
    test('fails closed when legacy Dart fallback is disabled', () {
      const kernel = DisabledLocalityFallbackKernel();

      expect(
        () => kernel.snapshot('agent-1'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Dart locality fallback is disabled'),
          ),
        ),
      );
    });
  });
}
