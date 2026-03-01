import 'package:avrai_core/models/misc/world_plane_view_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorldPlaneViewState', () {
    test('unavailable factory builds safe fallback state', () {
      final state = WorldPlaneViewState.unavailable(
        reason: 'not ready',
      );

      expect(state.isAvailable, isFalse);
      expect(state.worldsheet, isNull);
      expect(state.confidence, 0.0);
      expect(state.fallbackReason, 'not ready');
      expect(state.generatedAt, isNotNull);
    });
  });
}
