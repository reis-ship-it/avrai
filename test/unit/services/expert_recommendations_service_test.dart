import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/expertise/expert_recommendations_service.dart';
import 'package:avrai/core/controllers/urk_runtime_activation_receipt_dispatcher.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/services/admin/urk_kernel_control_plane_service.dart';
import 'package:avrai/core/services/admin/urk_kernel_registry_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import '../../fixtures/model_factories.dart';
import '../../helpers/platform_channel_helper.dart';
import '../../mocks/mock_storage_service.dart';

class _ExpertRuntimeKernelRegistryService extends UrkKernelRegistryService {
  const _ExpertRuntimeKernelRegistryService();

  @override
  Future<UrkKernelRegistrySnapshot> loadSnapshot() async {
    return UrkKernelRegistrySnapshot(
      version: 'v1',
      updatedAt: '2026-02-28',
      byProng: const {'runtime_core': 1},
      byMode: const {'private_mesh': 1},
      byImpactTier: const {'L3': 1},
      kernels: const [
        UrkKernelRecord(
          kernelId: 'k_expert_runtime',
          title: 'Expert Runtime',
          purpose: 'Expert runtime service dispatch',
          runtimeScope: ['expert_services_runtime'],
          prongScope: 'runtime_core',
          privacyModes: ['private_mesh'],
          impactTier: 'L3',
          localityScope: ['mesh'],
          activationTriggers: ['expert_runtime_request'],
          authorityMode: 'enforced',
          dependencies: ['M8-P11-2'],
          lifecycleState: 'enforced',
          owner: 'AP',
          approver: 'GOV',
          milestoneId: 'M8-P11-2',
          status: 'done',
        ),
      ],
    );
  }
}

/// Expert Recommendations Service Tests
/// Tests expert-based recommendation functionality
void main() {
  group('ExpertRecommendationsService Tests', () {
    late ExpertRecommendationsService service;
    late UnifiedUser user;

    setUp(() {
      service = ExpertRecommendationsService();
      user = ModelFactories.createTestUser(
        id: 'user-123',
        tags: ['food'],
      ).copyWith(
        expertiseMap: {'food': 'city'},
      );
    });

    // Removed: Property assignment tests
    // Expert recommendations tests focus on business logic (recommendations, curated lists, validated spots), not property assignment

    group('getExpertRecommendations', () {
      test(
          'should return recommendations for user with expertise, return general recommendations when user has no expertise, respect maxResults parameter, use user expertise categories when category not specified, or return recommendations sorted by score',
          () async {
        // Test business logic: expert recommendation retrieval
        final recommendations1 = await service.getExpertRecommendations(
          user,
          category: 'food',
        );
        expect(recommendations1, isA<List<ExpertRecommendation>>());
        for (var i = 0; i < recommendations1.length - 1; i++) {
          expect(
            recommendations1[i].recommendationScore,
            greaterThanOrEqualTo(recommendations1[i + 1].recommendationScore),
          );
        }

        final userWithoutExpertise = ModelFactories.createTestUser(
          id: 'user-456',
        ).copyWith(expertiseMap: {});
        final recommendations2 = await service.getExpertRecommendations(
          userWithoutExpertise,
        );
        expect(recommendations2, isA<List<ExpertRecommendation>>());

        final recommendations3 = await service.getExpertRecommendations(
          user,
          category: 'food',
          maxResults: 10,
        );
        expect(recommendations3.length, lessThanOrEqualTo(10));

        final recommendations4 = await service.getExpertRecommendations(
          user,
          maxResults: 20,
        );
        expect(recommendations4, isA<List<ExpertRecommendation>>());
      });

      test('emits URK activation receipt from expert recommendations flow',
          () async {
        MockGetStorage.reset();
        final storage = getTestStorage(boxName: 'expert_reco_urk');
        final prefs =
            await SharedPreferencesCompat.getInstance(storage: storage);
        final controlPlane = UrkKernelControlPlaneService(
          prefs: prefs,
          registryService: const _ExpertRuntimeKernelRegistryService(),
        );
        final dispatcher = UrkRuntimeActivationReceiptDispatcher(
          controlPlaneService: controlPlane,
          registryService: const _ExpertRuntimeKernelRegistryService(),
        );
        service = ExpertRecommendationsService(
          activationDispatcher: dispatcher,
        );

        await service.getExpertRecommendations(user, category: 'food');

        final lineage = await controlPlane.getKernelLineage('k_expert_runtime');
        expect(
          lineage.where((event) => event.eventType == 'activation_receipt'),
          isNotEmpty,
        );
      });
    });

    group('getExpertCuratedLists', () {
      test(
          'should return expert-curated lists, respect maxResults parameter, or filter by category when provided',
          () async {
        // Test business logic: expert-curated list retrieval
        final lists1 = await service.getExpertCuratedLists(
          user,
          category: 'food',
        );
        expect(lists1, isA<List<ExpertCuratedList>>());
        for (final list in lists1) {
          expect(list.category, equals('food'));
        }

        final lists2 = await service.getExpertCuratedLists(
          user,
          category: 'food',
          maxResults: 5,
        );
        expect(lists2.length, lessThanOrEqualTo(5));
      });
    });

    group('getExpertValidatedSpots', () {
      test(
          'should return expert-validated spots, respect maxResults parameter, or filter by location when provided',
          () async {
        // Test business logic: expert-validated spot retrieval
        final spots1 = await service.getExpertValidatedSpots(
          category: 'food',
          location: 'San Francisco',
        );
        expect(spots1, isA<List>());

        final spots2 = await service.getExpertValidatedSpots(
          category: 'food',
          maxResults: 10,
        );
        expect(spots2.length, lessThanOrEqualTo(10));

        final spots3 = await service.getExpertValidatedSpots(
          category: 'coffee',
          location: 'New York',
        );
        expect(spots3, isA<List>());
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
