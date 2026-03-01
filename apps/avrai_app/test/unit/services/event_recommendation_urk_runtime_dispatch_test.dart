import 'package:avrai_runtime_os/kernel/contracts/urk_runtime_activation_receipt_dispatcher.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_kernel_control_plane_service.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_kernel_registry_service.dart';
import 'package:avrai_runtime_os/services/events/event_recommendation_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/matching/user_preference_learning_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';
import '../../mocks/mock_storage_service.dart';

class _EventOpsRuntimeKernelRegistryService extends UrkKernelRegistryService {
  const _EventOpsRuntimeKernelRegistryService();

  @override
  Future<UrkKernelRegistrySnapshot> loadSnapshot() async {
    return UrkKernelRegistrySnapshot(
      version: 'v1',
      updatedAt: '2026-02-28',
      byProng: const {'runtime_core': 1},
      byMode: const {'multi_mode': 1},
      byImpactTier: const {'L3': 1},
      kernels: const [
        UrkKernelRecord(
          kernelId: 'k_event_ops_runtime',
          title: 'Event Ops Runtime',
          purpose: 'General user event recommendation runtime dispatch',
          runtimeScope: ['event_ops_runtime'],
          prongScope: 'runtime_core',
          privacyModes: ['multi_mode'],
          impactTier: 'L3',
          localityScope: ['device', 'mesh', 'cloud'],
          activationTriggers: ['event_ops_shadow_execution'],
          authorityMode: 'shadow',
          dependencies: ['M7-P7-4'],
          lifecycleState: 'enforced',
          owner: 'AP',
          approver: 'GOV',
          milestoneId: 'M7-P7-4',
          status: 'done',
        ),
        UrkKernelRecord(
          kernelId: 'k_user_runtime_learning',
          title: 'User Runtime Learning Intake',
          purpose: 'User-origin realtime learning signal dispatch',
          runtimeScope: ['user_runtime'],
          prongScope: 'model_core',
          privacyModes: ['local_sovereign'],
          impactTier: 'L3',
          localityScope: ['device'],
          activationTriggers: [
            'user_runtime_learning_signal',
            'policy_violation_detected'
          ],
          authorityMode: 'enforced',
          dependencies: ['M11-P3-1'],
          lifecycleState: 'enforced',
          owner: 'AP',
          approver: 'GOV',
          milestoneId: 'M11-P3-1',
          status: 'ready',
        ),
      ],
    );
  }
}

class _EmptyEventService extends ExpertiseEventService {
  @override
  Future<List<ExpertiseEvent>> searchEvents({
    String? category,
    String? location,
    ExpertiseEventType? eventType,
    DateTime? startDate,
    DateTime? endDate,
    int maxResults = 20,
    bool includeCommunityEvents = true,
  }) async {
    return <ExpertiseEvent>[];
  }
}

class _StaticPreferenceService extends UserPreferenceLearningService {
  @override
  Future<UserPreferences> getUserPreferences(
      {required UnifiedUser user}) async {
    return UserPreferences.empty(userId: user.id);
  }
}

void main() {
  group('EventRecommendationService URK runtime dispatch', () {
    test(
        'getPersonalizedRecommendations emits activation receipts for user and event runtime paths',
        () async {
      MockGetStorage.reset();
      final storage = getTestStorage(boxName: 'event_reco_urk_runtime');
      final prefs = await SharedPreferencesCompat.getInstance(storage: storage);
      final controlPlane = UrkKernelControlPlaneService(
        prefs: prefs,
        registryService: const _EventOpsRuntimeKernelRegistryService(),
      );
      final dispatcher = UrkRuntimeActivationReceiptDispatcher(
        controlPlaneService: controlPlane,
        registryService: const _EventOpsRuntimeKernelRegistryService(),
      );

      final service = EventRecommendationService(
        eventService: _EmptyEventService(),
        preferenceService: _StaticPreferenceService(),
        activationDispatcher: dispatcher,
      );
      final user = UnifiedUser(
        id: 'user-general-1',
        email: 'user@example.com',
        displayName: 'General User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.getPersonalizedRecommendations(user: user, maxResults: 5);

      final lineage =
          await controlPlane.getKernelLineage('k_event_ops_runtime');
      expect(
        lineage.where((event) => event.eventType == 'activation_receipt'),
        isNotEmpty,
      );
      final userRuntimeLineage =
          await controlPlane.getKernelLineage('k_user_runtime_learning');
      expect(
        userRuntimeLineage
            .where((event) => event.eventType == 'activation_receipt'),
        isNotEmpty,
      );
    });

    test(
        'getPersonalizedRecommendations respects user-runtime opt-out and suppresses user-runtime learning signal',
        () async {
      MockGetStorage.reset();
      await initializeStorageServiceForTests();
      await StorageService.instance
          .setBool('user_runtime_learning_enabled', false);

      final storage = getTestStorage(boxName: 'event_reco_urk_runtime_opt_out');
      final prefs = await SharedPreferencesCompat.getInstance(storage: storage);
      final controlPlane = UrkKernelControlPlaneService(
        prefs: prefs,
        registryService: const _EventOpsRuntimeKernelRegistryService(),
      );
      final dispatcher = UrkRuntimeActivationReceiptDispatcher(
        controlPlaneService: controlPlane,
        registryService: const _EventOpsRuntimeKernelRegistryService(),
      );

      final service = EventRecommendationService(
        eventService: _EmptyEventService(),
        preferenceService: _StaticPreferenceService(),
        activationDispatcher: dispatcher,
        storageService: StorageService.instance,
      );
      final user = UnifiedUser(
        id: 'user-general-2',
        email: 'user2@example.com',
        displayName: 'General User 2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.getPersonalizedRecommendations(user: user, maxResults: 5);

      final eventOpsLineage =
          await controlPlane.getKernelLineage('k_event_ops_runtime');
      expect(
        eventOpsLineage
            .where((event) => event.eventType == 'activation_receipt'),
        isNotEmpty,
      );
      final userRuntimeLineage =
          await controlPlane.getKernelLineage('k_user_runtime_learning');
      expect(
        userRuntimeLineage.where((event) =>
            event.eventType == 'activation_receipt' &&
            event.reason.contains('user_runtime_learning_intake_accepted')),
        isEmpty,
      );
      expect(
        userRuntimeLineage.where((event) =>
            event.eventType == 'activation_receipt' &&
            event.reason.contains('user_runtime_learning_intake_rejected')),
        isNotEmpty,
      );
    });

    test(
        'getPersonalizedRecommendations still emits user-runtime learning when ai2ai is opt-out but user-runtime is enabled',
        () async {
      MockGetStorage.reset();
      await initializeStorageServiceForTests();
      await StorageService.instance.setBool('ai2ai_learning_enabled', false);
      await StorageService.instance
          .setBool('user_runtime_learning_enabled', true);

      final storage =
          getTestStorage(boxName: 'event_reco_urk_runtime_ai2ai_off');
      final prefs = await SharedPreferencesCompat.getInstance(storage: storage);
      final controlPlane = UrkKernelControlPlaneService(
        prefs: prefs,
        registryService: const _EventOpsRuntimeKernelRegistryService(),
      );
      final dispatcher = UrkRuntimeActivationReceiptDispatcher(
        controlPlaneService: controlPlane,
        registryService: const _EventOpsRuntimeKernelRegistryService(),
      );

      final service = EventRecommendationService(
        eventService: _EmptyEventService(),
        preferenceService: _StaticPreferenceService(),
        activationDispatcher: dispatcher,
        storageService: StorageService.instance,
      );
      final user = UnifiedUser(
        id: 'user-general-3',
        email: 'user3@example.com',
        displayName: 'General User 3',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.getPersonalizedRecommendations(user: user, maxResults: 5);

      final userRuntimeLineage =
          await controlPlane.getKernelLineage('k_user_runtime_learning');
      expect(
        userRuntimeLineage
            .where((event) => event.eventType == 'activation_receipt'),
        isNotEmpty,
      );
    });
  });
}
