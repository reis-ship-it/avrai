import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/saved_discovery_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/recommendations/saved_discovery_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/mock_storage_service.dart';

void main() {
  group('SavedDiscoveryService', () {
    late SharedPreferencesCompat prefs;
    late UniversalIntakeRepository intakeRepository;
    late GovernedUpwardLearningIntakeService upwardService;
    late SavedDiscoveryFollowUpPromptPlannerService plannerService;
    late SavedDiscoveryService service;

    setUp(() async {
      MockGetStorage.reset();
      prefs = await SharedPreferencesCompat.getInstance(
        storage: MockGetStorage.getInstance(boxName: 'saved_discovery_test'),
      );
      intakeRepository = UniversalIntakeRepository();
      upwardService = GovernedUpwardLearningIntakeService(
        intakeRepository: intakeRepository,
        atomicClockService: AtomicClockService(),
      );
      plannerService = SavedDiscoveryFollowUpPromptPlannerService(prefs: prefs);
      service = SavedDiscoveryService(
        prefs: prefs,
        governedUpwardLearningIntakeService: upwardService,
        followUpPlannerService: plannerService,
      );
    });

    test('stages save behavior into governed upward curation intake', () async {
      const entity = DiscoveryEntityReference(
        type: DiscoveryEntityType.spot,
        id: 'spot_123',
        title: 'Night Owl Cafe',
        localityLabel: 'downtown',
      );

      await service.save(
        userId: 'user_123',
        entity: entity,
        sourceSurface: 'explore',
        attribution: const RecommendationAttribution(
          why: 'Strong local fit',
          whyDetails: 'Matches recent quiet cafe signals',
          projectedEnjoyabilityPercent: 81,
          recommendationSource: 'place_intelligence_lane',
          confidence: 0.82,
        ),
      );

      final reviews = await intakeRepository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
        reviews.single.payload['sourceKind'],
        'saved_discovery_curation_intake',
      );
      expect(reviews.single.payload['action'], 'save');
      expect(
        reviews.single.payload['convictionTier'],
        'saved_discovery_positive_curation_signal',
      );
      final plans = await plannerService.listPlans('user_123');
      expect(plans, hasLength(1));
      expect(plans.single.action, 'save');
    });

    test('stages unsave behavior into governed upward curation intake',
        () async {
      const entity = DiscoveryEntityReference(
        type: DiscoveryEntityType.list,
        id: 'list_123',
        title: 'Late Night Food',
        localityLabel: 'southside',
      );

      await service.save(
        userId: 'user_123',
        entity: entity,
        sourceSurface: 'explore',
      );

      await service.unsave(
        userId: 'user_123',
        entity: entity,
      );

      final reviews = await intakeRepository.getAllReviewItems();
      expect(reviews, hasLength(2));
      final unsaveReview = reviews.firstWhere(
        (review) => review.payload['action'] == 'unsave',
      );
      expect(
        unsaveReview.payload['sourceKind'],
        'saved_discovery_curation_intake',
      );
      expect(unsaveReview.payload['action'], 'unsave');
      expect(
        unsaveReview.payload['convictionTier'],
        'saved_discovery_negative_curation_signal',
      );
      final plans = await plannerService.listPlans('user_123');
      expect(plans, hasLength(2));
      expect(
        plans.map((plan) => plan.action),
        containsAll(const <String>['save', 'unsave']),
      );
    });
  });
}
