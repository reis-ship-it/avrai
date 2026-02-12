/// Unit tests for ConversationPreferences and ConversationPreferenceStore (Phase 6).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/conversation_preferences.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  group('ConversationPreferences', () {
    test('fromJson round-trip', () {
      final p = ConversationPreferences(
        bypassRate: 0.25,
        totalRagTurns: 9,
        totalBypassTurns: 3,
        lastUpdated: DateTime(2025, 1, 1),
      );
      final restored = ConversationPreferences.fromJson(p.toJson());
      expect(restored.bypassRate, p.bypassRate);
      expect(restored.totalRagTurns, p.totalRagTurns);
      expect(restored.totalBypassTurns, p.totalBypassTurns);
    });
  });

  group('ConversationPreferenceStore', () {
    late ConversationPreferenceStore store;

    setUp(() {
      store = ConversationPreferenceStore();
    });

    test('get returns null when empty', () async {
      final got = await store.get('user-cpref-1');
      expect(got, isNull);
    });

    test('updateFromTurn increments RAG then bypass', () async {
      await store.updateFromTurn('user-cpref-2', usedBypass: false);
      var p = await store.get('user-cpref-2');
      expect(p, isNotNull);
      expect(p!.totalRagTurns, 1);
      expect(p.totalBypassTurns, 0);
      expect(p.bypassRate, 0.0);

      await store.updateFromTurn('user-cpref-2', usedBypass: true);
      p = await store.get('user-cpref-2');
      expect(p, isNotNull);
      expect(p!.totalRagTurns, 1);
      expect(p.totalBypassTurns, 1);
      expect(p.bypassRate, closeTo(0.5, 0.01));
    });
  });
}
