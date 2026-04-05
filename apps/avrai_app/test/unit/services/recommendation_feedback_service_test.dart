import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_feedback_prompt_planner_service.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_feedback_service.dart';
import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/platform_channel_helper.dart';

class MockEntitySignatureService extends Mock
    implements EntitySignatureService {}

void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  test('recommendation feedback stages governed upward intake', () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(boxName: 'recommendation_feedback_prefs'),
    );
    final repository = UniversalIntakeRepository();
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
    );
    final service = RecommendationFeedbackService(
      prefs: prefs,
      governedUpwardLearningIntakeService: upwardService,
    );
    final planner = RecommendationFeedbackPromptPlannerService(prefs: prefs);

    await service.submitFeedback(
      userId: 'user_123',
      entity: const DiscoveryEntityReference(
        type: DiscoveryEntityType.list,
        id: 'list_123',
        title: 'Quiet Coffee Picks',
        localityLabel: 'austin_downtown',
      ),
      action: RecommendationFeedbackAction.save,
      sourceSurface: 'onboarding_recommendations',
      attribution: const RecommendationAttribution(
        why: 'Matches your local coffee preferences',
        whyDetails: 'Built from place and list signals near your homebase',
        projectedEnjoyabilityPercent: 87,
        recommendationSource: 'list_curation_lane',
        confidence: 0.82,
      ),
      metadata: const <String, dynamic>{
        'domains': <String>['place', 'list'],
        'interaction_context': 'initial_seed',
      },
    );

    final events = await service.listEvents('user_123');
    final plans = await planner.listPlans('user_123');
    final reviews = await repository.getAllReviewItems();

    expect(events, hasLength(1));
    expect(plans, hasLength(1));
    expect(reviews, hasLength(1));
    expect(plans.single.channelHint, 'lightweight_in_app_reflection');
    expect(
      plans.single.promptQuestion,
      contains('Quiet Coffee Picks'),
    );
    expect(
      plans.single.boundedContext['why'],
      'Built from place and list signals near your homebase',
    );
    expect(
      plans.single.boundedContext['how'],
      'list_curation_lane via onboarding_recommendations',
    );
    expect(plans.single.boundedContext['where'], 'austin_downtown');
    expect(plans.single.boundedContext['who'], 'owner_user_feedback_actor');
    expect(
        reviews.single.payload['sourceKind'], 'recommendation_feedback_intake');
    expect(reviews.single.payload['airGapRequired'], isTrue);
    expect(reviews.single.payload['airGapReceiptId'], isA<String>());
    expect(
      reviews.single.payload['convictionTier'],
      'recommendation_feedback_positive_signal',
    );
    expect(
      reviews.single.payload['upwardDomainHints'],
      containsAll(const <String>['list', 'locality', 'place']),
    );
  });

  test(
    'negative feedback preserves surfaced evidence-backed explanation wording',
    () async {
      final prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(
          boxName: 'recommendation_feedback_negative_signal_prefs',
        ),
      );
      final entitySignatureService = MockEntitySignatureService();
      String? capturedSubtitle;
      when(
        () => entitySignatureService.recordNegativePreferenceSignal(
          userId: 'user_123',
          title: 'Quiet Coffee Picks',
          subtitle: any(named: 'subtitle'),
          category: 'list',
          tags: const <String>[
            'list',
            'onboarding_recommendations',
            'list_curation_lane',
          ],
          intent: NegativePreferenceIntent.softIgnore,
          entityType: 'list',
        ),
      ).thenAnswer((invocation) async {
        capturedSubtitle = invocation.namedArguments[#subtitle] as String?;
        return EntitySignature(
          signatureId: 'user:user_123',
          entityId: 'user_123',
          entityKind: SignatureEntityKind.user,
          dna: const <String, double>{'openness': 0.5},
          pheromones: const <String, double>{'openness': 0.5},
          confidence: 0.5,
          freshness: 0.5,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
          summary: 'fallback',
        );
      });

      final service = RecommendationFeedbackService(
        prefs: prefs,
        entitySignatureService: entitySignatureService,
      );

      await service.submitFeedback(
        userId: 'user_123',
        entity: const DiscoveryEntityReference(
          type: DiscoveryEntityType.list,
          id: 'list_123',
          title: 'Quiet Coffee Picks',
          localityLabel: 'austin_downtown',
        ),
        action: RecommendationFeedbackAction.dismiss,
        sourceSurface: 'onboarding_recommendations',
        attribution: const RecommendationAttribution(
          why:
              'A recent signal that you prefer louder late-night spots boosted this recommendation',
          whyDetails: 'Built from place and list signals near your homebase',
          projectedEnjoyabilityPercent: 87,
          recommendationSource: 'list_curation_lane',
          confidence: 0.82,
        ),
      );

      expect(
        capturedSubtitle,
        'A recent signal that you prefer louder late-night spots boosted this recommendation',
      );
    },
  );
}
