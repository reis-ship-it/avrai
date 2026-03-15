import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/controllers/onboarding_flow_controller.dart';
import 'package:avrai_core/models/user/onboarding_data.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_data_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/misc/legal_document_service.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_bootstrap_service.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../helpers/platform_channel_helper.dart';
import 'onboarding_flow_controller_test.mocks.dart';

@GenerateMocks([
  OnboardingDataService,
  AgentIdService,
  LegalDocumentService,
])
void main() {
  group('OnboardingFlowController', () {
    late OnboardingFlowController controller;
    late MockOnboardingDataService mockOnboardingService;
    late MockAgentIdService mockAgentIdService;
    late MockLegalDocumentService mockLegalService;

    setUp(() {
      mockOnboardingService = MockOnboardingDataService();
      mockAgentIdService = MockAgentIdService();
      mockLegalService = MockLegalDocumentService();

      controller = OnboardingFlowController(
        onboardingDataService: mockOnboardingService,
        agentIdService: mockAgentIdService,
        legalDocumentService: mockLegalService,
      );
    });

    group('validate', () {
      test('should return valid for correct onboarding data', () {
        final data = OnboardingData(
          agentId: 'agent_test123456789012345678901234567890',
          age: 25,
          homebase: 'New York',
          favoritePlaces: ['Central Park'],
          preferences: {
            'Food': ['Coffee']
          },
          completedAt: DateTime.now(),
        );

        final result = controller.validate(data);

        expect(result.isValid, isTrue);
        expect(result.allErrors, isEmpty);
      });

      test('should return invalid for missing agentId', () {
        final data = OnboardingData(
          agentId: '',
          completedAt: DateTime.now(),
        );

        final result = controller.validate(data);

        expect(result.isValid, isFalse);
        expect(result.fieldErrors['agentId'], isNotNull);
      });

      test('should return invalid for invalid age', () {
        final data = OnboardingData(
          agentId: 'agent_test123456789012345678901234567890',
          age: 5, // Too young
          completedAt: DateTime.now(),
        );

        final result = controller.validate(data);

        expect(result.isValid, isFalse);
        expect(result.fieldErrors['age'], isNotNull);
      });

      test('should return invalid for future birthday', () {
        final data = OnboardingData(
          agentId: 'agent_test123456789012345678901234567890',
          birthday: DateTime.now().add(const Duration(days: 1)),
          completedAt: DateTime.now(),
        );

        final result = controller.validate(data);

        expect(result.isValid, isFalse);
        expect(result.fieldErrors['birthday'], isNotNull);
      });
    });

    group('completeOnboarding', () {
      test('should complete onboarding successfully', () async {
        final data = OnboardingData(
          agentId: 'agent_test123456789012345678901234567890',
          age: 25,
          homebase: 'New York',
          completedAt: DateTime.now(),
        );
        const userId = 'user123';
        const agentId = 'agent_test123456789012345678901234567890';

        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockLegalService.hasAcceptedTerms(userId))
            .thenAnswer((_) async => true);
        when(mockLegalService.hasAcceptedPrivacyPolicy(userId))
            .thenAnswer((_) async => true);
        when(mockOnboardingService.saveOnboardingData(userId, any))
            .thenAnswer((_) async => {});

        final result = await controller.completeOnboarding(
          data: data,
          userId: userId,
        );

        expect(result.isSuccess, isTrue);
        expect(result.agentId, equals(agentId));
        expect(result.onboardingData, isNotNull);
        verify(mockAgentIdService.getUserAgentId(userId)).called(1);
        verify(mockOnboardingService.saveOnboardingData(userId, any)).called(1);
      });

      test('should attach OS-first model truth and governance artifacts',
          () async {
        final data = OnboardingData(
          agentId: 'agent_test123456789012345678901234567890',
          age: 25,
          homebase: 'New York',
          preferences: const <String, List<String>>{
            'Food': <String>['Coffee'],
          },
          completedAt: DateTime.now(),
        );
        const userId = 'user123';
        const agentId = 'agent_test123456789012345678901234567890';
        final fakeHeadlessHost = _FakeHeadlessAvraiOsHost();

        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockLegalService.hasAcceptedTerms(userId))
            .thenAnswer((_) async => true);
        when(mockLegalService.hasAcceptedPrivacyPolicy(userId))
            .thenAnswer((_) async => true);
        when(mockOnboardingService.saveOnboardingData(userId, any))
            .thenAnswer((_) async => {});

        controller = OnboardingFlowController(
          onboardingDataService: mockOnboardingService,
          agentIdService: mockAgentIdService,
          legalDocumentService: mockLegalService,
          headlessOsHost: fakeHeadlessHost,
        );

        final result = await controller.completeOnboarding(
          data: data,
          userId: userId,
        );

        expect(result.isSuccess, isTrue);
        expect(result.realityKernelFusionInput, isNotNull);
        expect(result.kernelGovernanceReport, isNotNull);
        expect(
            result.realityKernelFusionInput!.localityContainedInWhere, isTrue);
        expect(result.metadata?['modelTruthReady'], isTrue);
        expect(result.metadata?['localityContainedInWhere'], isTrue);
        expect(result.metadata?['governanceDomains'], contains('where'));
        expect(fakeHeadlessHost.startCalls, 1);
        expect(fakeHeadlessHost.runtimeCalls, 1);
        expect(fakeHeadlessHost.modelTruthCalls, 1);
        expect(fakeHeadlessHost.governanceCalls, 1);
      });

      test('should expose restored headless OS bootstrap state in result',
          () async {
        final data = OnboardingData(
          agentId: 'agent_test123456789012345678901234567890',
          age: 25,
          homebase: 'New York',
          completedAt: DateTime.now(),
        );
        const userId = 'user123';
        const agentId = 'agent_test123456789012345678901234567890';
        final fakeHeadlessHost = _FakeHeadlessAvraiOsHost();
        final prefs = await SharedPreferencesCompat.getInstance(
          storage: getTestStorage(
            boxName: 'onboarding_flow_controller_restored_bootstrap',
          ),
        );
        final seedingBootstrap = HeadlessAvraiOsBootstrapService(
          host: fakeHeadlessHost,
          prefs: prefs,
        );
        await seedingBootstrap.initialize();
        final restoredBootstrap = HeadlessAvraiOsBootstrapService(
          host: _FakeHeadlessAvraiOsHost(),
          prefs: prefs,
        );
        await restoredBootstrap.restorePersistedSnapshot();

        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockLegalService.hasAcceptedTerms(userId))
            .thenAnswer((_) async => true);
        when(mockLegalService.hasAcceptedPrivacyPolicy(userId))
            .thenAnswer((_) async => true);
        when(mockOnboardingService.saveOnboardingData(userId, any))
            .thenAnswer((_) async => {});

        controller = OnboardingFlowController(
          onboardingDataService: mockOnboardingService,
          agentIdService: mockAgentIdService,
          legalDocumentService: mockLegalService,
          headlessOsHost: fakeHeadlessHost,
          headlessOsBootstrapService: restoredBootstrap,
        );

        final result = await controller.completeOnboarding(
          data: data,
          userId: userId,
        );

        expect(result.isSuccess, isTrue);
        expect(result.restoredHeadlessOsBootstrapSnapshot, isNotNull);
        expect(
          result.restoredHeadlessOsBootstrapSnapshot!.restoredFromPersistence,
          isTrue,
        );
        expect(
            result.metadata?['restoredHeadlessOsBootstrapAvailable'], isTrue);
        expect(
          result.metadata?['restoredHeadlessOsLocalityContainedInWhere'],
          isTrue,
        );
      });

      test('should fail if legal documents not accepted', () async {
        final data = OnboardingData(
          agentId: 'agent_test123456789012345678901234567890',
          completedAt: DateTime.now(),
        );
        const userId = 'user123';
        const agentId = 'agent_test123456789012345678901234567890';

        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockLegalService.hasAcceptedTerms(userId))
            .thenAnswer((_) async => false);
        when(mockLegalService.hasAcceptedPrivacyPolicy(userId))
            .thenAnswer((_) async => true);

        final result = await controller.completeOnboarding(
          data: data,
          userId: userId,
        );

        expect(result.isSuccess, isFalse);
        expect(result.requiresLegalAcceptance, isTrue);
        expect(result.error, contains('Legal documents'));
      });

      test('should fail if agentId cannot be retrieved', () async {
        final data = OnboardingData(
          agentId: 'agent_test123456789012345678901234567890',
          completedAt: DateTime.now(),
        );
        const userId = 'user123';

        when(mockLegalService.hasAcceptedTerms(userId))
            .thenAnswer((_) async => true);
        when(mockLegalService.hasAcceptedPrivacyPolicy(userId))
            .thenAnswer((_) async => true);
        when(mockAgentIdService.getUserAgentId(userId))
            .thenThrow(Exception('Agent ID service unavailable'));

        final result = await controller.completeOnboarding(
          data: data,
          userId: userId,
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('AGENT_ID_ERROR'));
      });

      test('should fail if data save fails', () async {
        final data = OnboardingData(
          agentId: 'agent_test123456789012345678901234567890',
          completedAt: DateTime.now(),
        );
        const userId = 'user123';
        const agentId = 'agent_test123456789012345678901234567890';

        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockLegalService.hasAcceptedTerms(userId))
            .thenAnswer((_) async => true);
        when(mockLegalService.hasAcceptedPrivacyPolicy(userId))
            .thenAnswer((_) async => true);
        when(mockOnboardingService.saveOnboardingData(userId, any))
            .thenThrow(Exception('Database error'));

        final result = await controller.completeOnboarding(
          data: data,
          userId: userId,
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('SAVE_ERROR'));
      });

      test('should skip legal check in integration tests', () async {
        final data = OnboardingData(
          agentId: 'agent_test123456789012345678901234567890',
          completedAt: DateTime.now(),
        );
        const userId = 'user123';
        const agentId = 'agent_test123456789012345678901234567890';

        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockOnboardingService.saveOnboardingData(userId, any))
            .thenAnswer((_) async => {});
        // Stub legal service methods (they may be called but errors are caught)
        when(mockLegalService.hasAcceptedTerms(userId))
            .thenAnswer((_) async => true);
        when(mockLegalService.hasAcceptedPrivacyPolicy(userId))
            .thenAnswer((_) async => true);

        // Note: In test environment, FLUTTER_TEST is set, so legal check is skipped
        // But the code may still call the service - we just don't fail if it errors
        final result = await controller.completeOnboarding(
          data: data,
          userId: userId,
        );

        expect(result.isSuccess, isTrue);
        // Legal service may or may not be called depending on FLUTTER_TEST environment
        // The important thing is that the workflow succeeds even if legal check fails
      });
    });
  });
}

class _FakeHeadlessAvraiOsHost implements HeadlessAvraiOsHost {
  int startCalls = 0;
  int runtimeCalls = 0;
  int modelTruthCalls = 0;
  int governanceCalls = 0;

  @override
  Future<HeadlessAvraiOsHostState> start() async {
    startCalls += 1;
    return HeadlessAvraiOsHostState(
      started: true,
      startedAtUtc: DateTime.utc(2026, 3, 6),
      localityContainedInWhere: true,
      summary: 'test onboarding host',
    );
  }

  @override
  Future<RealityKernelFusionInput> buildModelTruth({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    modelTruthCalls += 1;
    return RealityKernelFusionInput(
      envelope: envelope,
      bundle: _bundle,
      who: const WhoRealityProjection(summary: 'who', confidence: 0.8),
      what: const WhatRealityProjection(summary: 'what', confidence: 0.8),
      when: const WhenRealityProjection(summary: 'when', confidence: 0.8),
      where: const WhereRealityProjection(
        summary: 'where',
        confidence: 0.9,
        payload: <String, dynamic>{'locality_contained_in_where': true},
      ),
      why: const WhyRealityProjection(summary: 'why', confidence: 0.8),
      how: const HowRealityProjection(summary: 'how', confidence: 0.8),
      generatedAtUtc: DateTime.utc(2026, 3, 6),
    );
  }

  @override
  Future<List<KernelHealthReport>> healthCheck() async =>
      const <KernelHealthReport>[];

  @override
  Future<KernelGovernanceReport> inspectGovernance({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    governanceCalls += 1;
    return KernelGovernanceReport(
      envelope: envelope,
      bundle: _bundle,
      projections: const <KernelGovernanceProjection>[
        KernelGovernanceProjection(
          domain: KernelDomain.where,
          summary: 'locality stays inside where',
          confidence: 0.94,
        ),
      ],
      generatedAtUtc: DateTime.utc(2026, 3, 6),
    );
  }

  @override
  Future<KernelContextBundle> resolveRuntimeExecution({
    required KernelEventEnvelope envelope,
  }) async {
    runtimeCalls += 1;
    return _bundle;
  }

  KernelContextBundle get _bundle => KernelContextBundle(
        who: const WhoKernelSnapshot(
          primaryActor: 'agent_test123456789012345678901234567890',
          affectedActor: 'agent_test123456789012345678901234567890',
          companionActors: <String>[],
          actorRoles: <String>['user'],
          trustScope: 'private',
          cohortRefs: <String>[],
          identityConfidence: 0.94,
        ),
        what: const WhatKernelSnapshot(
          actionType: 'complete_onboarding',
          targetEntityType: 'agent',
          targetEntityId: 'agent_test123456789012345678901234567890',
          stateTransitionType: 'persisted',
          outcomeType: 'saved',
          semanticTags: <String>['onboarding'],
          taxonomyConfidence: 0.9,
        ),
        when: WhenKernelSnapshot(
          observedAt: DateTime.utc(2026, 3, 6),
          freshness: 1.0,
          recencyBucket: 'current',
          timingConflictFlags: const <String>[],
          temporalConfidence: 0.95,
        ),
        where: const WhereKernelSnapshot(
          localityToken: 'where:locality:onboarding',
          cityCode: 'nyc',
          localityCode: 'new_york',
          projection: <String, dynamic>{'locality_contained_in_where': true},
          boundaryTension: 0.1,
          spatialConfidence: 0.92,
          travelFriction: 0.15,
          placeFitFlags: <String>['locality_contained_in_where'],
        ),
        how: const HowKernelSnapshot(
          executionPath: 'onboarding_flow_controller.completeOnboarding',
          workflowStage: 'onboarding',
          transportMode: 'in_process',
          plannerMode: 'workflow',
          modelFamily: 'headless_os',
          interventionChain: <String>['validate', 'persist'],
          failureMechanism: 'none',
          mechanismConfidence: 0.9,
        ),
        why: WhyKernelSnapshot(
          goal: 'persist_onboarding_state',
          summary: 'onboarding saved',
          rootCauseType: WhyRootCauseType.contextDriven,
          confidence: 0.88,
          drivers: const <WhySignal>[
            WhySignal(label: 'preferences_present', weight: 0.8),
          ],
          inhibitors: const <WhySignal>[],
          counterfactuals: const <WhyCounterfactual>[],
          createdAtUtc: DateTime.utc(2026, 3, 6),
        ),
      );
}
