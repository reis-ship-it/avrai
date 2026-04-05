import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/user/onboarding_suggestion_event.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_suggestion_event_store.dart';

/// Unit tests for OnboardingSuggestionEventStore
///
/// Focus: append + read round-trip.
void main() {
  group('OnboardingSuggestionEventStore', () {
    setUp(() async {
      // No-op: Sembast removed in Phase 26
    });

    test('appendForUser then getAllForUser returns stored events', () async {
      final store = OnboardingSuggestionEventStore(
        // Use default AgentIdService; it falls back to deterministic IDs when
        // Supabase is not initialized.
        agentIdService: AgentIdService(),
      );

      const userId = 'user_1';
      final evt = OnboardingSuggestionEvent(
        eventId: OnboardingSuggestionEvent.newEventId(nowMicros: 123),
        createdAtMs: 456,
        surface: 'baseline_lists',
        provenance: OnboardingSuggestionProvenance.heuristic,
        promptCategory: 'baseline_lists_quick_suggestions',
        suggestions: const [
          OnboardingSuggestionItem(
            id: 'Coffee & Tea Spots',
            label: 'Coffee & Tea Spots',
          ),
        ],
        userAction: const OnboardingSuggestionUserAction(
          type: OnboardingSuggestionActionType.shown,
        ),
      );

      await store.appendForUser(userId: userId, event: evt);
      final loaded = await store.getAllForUser(userId);

      expect(loaded, isNotEmpty);
      expect(loaded.last.surface, equals('baseline_lists'));
      expect(
        loaded.last.provenance,
        equals(OnboardingSuggestionProvenance.heuristic),
      );
      expect(loaded.last.suggestions, isNotEmpty);
    });
  });
}
