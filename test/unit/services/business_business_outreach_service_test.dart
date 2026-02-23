import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/business/business_business_outreach_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BusinessBusinessOutreachService', () {
    test('records business partnership outcome tuple', () async {
      final episodicStore = EpisodicMemoryStore();
      await episodicStore.clearForTesting();
      final service = BusinessBusinessOutreachService(
        episodicMemoryStore: episodicStore,
      );

      await service.recordPartnershipOutcome(
        businessAId: 'business-a',
        businessBId: 'business-b',
        partnershipId: 'bb-partnership-1',
        jointEventSuccessScore: 0.88,
        crossReferralRate: 0.42,
        partnershipRenewed: true,
        jointEventCount: 3,
      );

      final tuples = await episodicStore.getRecent(agentId: 'business-a');
      expect(tuples, hasLength(1));
      expect(tuples.first.actionType, equals('partner_with'));
      expect(tuples.first.outcome.type, equals('business_partnership_outcome'));
      expect(
        tuples.first.actionPayload['business_b_features']['business_id'],
        equals('business-b'),
      );
      expect(
        tuples.first.nextState['partnership_outcome']['partnership_renewed'],
        isTrue,
      );
    });

    test('is safe when episodic store is not available', () async {
      final service = BusinessBusinessOutreachService();
      await service.recordPartnershipOutcome(
        businessAId: 'business-a',
        businessBId: 'business-b',
        partnershipId: 'bb-partnership-1',
        jointEventSuccessScore: 0.9,
        crossReferralRate: 0.5,
        partnershipRenewed: false,
      );
    });
  });
}
