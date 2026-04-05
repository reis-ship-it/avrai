import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:avrai_runtime_os/controllers/business_onboarding_controller.dart';
import 'package:avrai_runtime_os/services/business/business_account_service.dart';
import 'package:avrai_runtime_os/services/business/business_shared_agent_service.dart';
import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_core/models/business/business_expert_preferences.dart';
import 'package:avrai_core/models/business/business_patron_preferences.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_bootstrap_service.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

import '../../helpers/platform_channel_helper.dart';
import 'business_onboarding_controller_test.mocks.dart';

@GenerateMocks([
  BusinessAccountService,
  BusinessSharedAgentService,
])
void main() {
  group('BusinessOnboardingController', () {
    late BusinessOnboardingController controller;
    late MockBusinessAccountService mockBusinessAccountService;
    late MockBusinessSharedAgentService mockSharedAgentService;

    late BusinessAccount testBusinessAccount;
    final DateTime now = DateTime.now();

    setUp(() {
      mockBusinessAccountService = MockBusinessAccountService();
      mockSharedAgentService = MockBusinessSharedAgentService();

      controller = BusinessOnboardingController(
        businessAccountService: mockBusinessAccountService,
        sharedAgentService: mockSharedAgentService,
      );

      testBusinessAccount = BusinessAccount(
        id: 'business_123',
        name: 'Test Business',
        email: 'test@business.com',
        businessType: 'Restaurant',
        createdAt: now,
        updatedAt: now,
        createdBy: 'user_123',
        isActive: true,
        isVerified: false,
        connectedExpertIds: const [],
        members: const [],
      );
    });

    group('validate', () {
      test('should return valid result for valid input', () {
        // Arrange
        final data = BusinessOnboardingData(
          businessId: 'business_123',
          setupSharedAgent: false,
        );

        // Act
        final result = controller.validate(data);

        // Assert
        expect(result.isValid, isTrue);
      });

      test(
          'should return valid result with warning for shared agent without team members',
          () {
        // Arrange
        final data = BusinessOnboardingData(
          businessId: 'business_123',
          setupSharedAgent: true,
          teamMembers: [],
        );

        // Act
        final result = controller.validate(data);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.warnings,
            contains('Shared agent enabled but no team members added'));
      });

      test('should return valid result for shared agent with team members', () {
        // Arrange
        final data = BusinessOnboardingData(
          businessId: 'business_123',
          setupSharedAgent: true,
          teamMembers: ['user_1', 'user_2'],
        );

        // Act
        final result = controller.validate(data);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.warnings, isEmpty);
      });
    });

    group('completeBusinessOnboarding', () {
      test('should successfully complete onboarding without shared agent',
          () async {
        // Arrange
        const expertPrefs = BusinessExpertPreferences(
          preferredExpertiseCategories: ['Coffee'],
          minExpertLevel: 3,
        );
        const patronPrefs = BusinessPatronPreferences(
          preferredVibePreferences: ['Cozy', 'Social'],
        );

        final data = BusinessOnboardingData(
          expertPreferences: expertPrefs,
          patronPreferences: patronPrefs,
          setupSharedAgent: false,
        );

        final updatedAccount = testBusinessAccount.copyWith(
          expertPreferences: expertPrefs,
          patronPreferences: patronPrefs,
          updatedAt: now,
        );

        when(mockBusinessAccountService.getBusinessAccount('business_123'))
            .thenAnswer((_) async => testBusinessAccount);
        when(mockBusinessAccountService.updateBusinessAccount(
          testBusinessAccount,
          expertPreferences: expertPrefs,
          patronPreferences: patronPrefs,
          requiredExpertise: null,
          preferredCommunities: null,
        )).thenAnswer((_) async => updatedAccount);

        // Act
        final result = await controller.completeBusinessOnboarding(
          businessId: 'business_123',
          data: data,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.businessAccount, isNotNull);
        expect(result.businessAccount?.expertPreferences, equals(expertPrefs));
        expect(result.businessAccount?.patronPreferences, equals(patronPrefs));
        expect(result.sharedAgentId, isNull);

        verify(mockBusinessAccountService.getBusinessAccount('business_123'))
            .called(1);
        verify(mockBusinessAccountService.updateBusinessAccount(
          testBusinessAccount,
          expertPreferences: expertPrefs,
          patronPreferences: patronPrefs,
          requiredExpertise: null,
          preferredCommunities: null,
        )).called(1);
        verifyNever(mockSharedAgentService.initializeSharedAgent(any));
      });

      test('should successfully complete onboarding with shared agent',
          () async {
        // Arrange
        final data = BusinessOnboardingData(
          setupSharedAgent: true,
          teamMembers: ['user_1', 'user_2'],
        );

        final updatedAccount = testBusinessAccount.copyWith(
          updatedAt: now,
        );

        when(mockBusinessAccountService.getBusinessAccount('business_123'))
            .thenAnswer((_) async => testBusinessAccount);
        when(mockBusinessAccountService.updateBusinessAccount(
          testBusinessAccount,
          expertPreferences: null,
          patronPreferences: null,
          requiredExpertise: null,
          preferredCommunities: null,
        )).thenAnswer((_) async => updatedAccount);
        when(mockSharedAgentService.initializeSharedAgent('business_123'))
            .thenAnswer((_) async => 'agent_456');

        // Act
        final result = await controller.completeBusinessOnboarding(
          businessId: 'business_123',
          data: data,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.businessAccount, isNotNull);
        expect(result.sharedAgentId, equals('agent_456'));

        verify(mockSharedAgentService.initializeSharedAgent('business_123'))
            .called(1);
      });

      test('should attach OS-first artifacts on successful onboarding',
          () async {
        final fakeHeadlessHost = _FakeBusinessHeadlessAvraiOsHost();
        controller = BusinessOnboardingController(
          businessAccountService: mockBusinessAccountService,
          sharedAgentService: mockSharedAgentService,
          headlessOsHost: fakeHeadlessHost,
        );

        final data = BusinessOnboardingData(
          setupSharedAgent: true,
          teamMembers: const <String>['user_1'],
          preferredCommunities: const <String>['River North'],
        );

        final updatedAccount = testBusinessAccount.copyWith(
          updatedAt: now,
        );

        when(mockBusinessAccountService.getBusinessAccount('business_123'))
            .thenAnswer((_) async => testBusinessAccount);
        when(mockBusinessAccountService.updateBusinessAccount(
          testBusinessAccount,
          expertPreferences: null,
          patronPreferences: null,
          requiredExpertise: null,
          preferredCommunities: data.preferredCommunities,
        )).thenAnswer((_) async => updatedAccount);
        when(mockSharedAgentService.initializeSharedAgent('business_123'))
            .thenAnswer((_) async => 'agent_456');

        final result = await controller.completeBusinessOnboarding(
          businessId: 'business_123',
          data: data,
        );

        expect(result.success, isTrue);
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
        final fakeHeadlessHost = _FakeBusinessHeadlessAvraiOsHost();
        final prefs = await SharedPreferencesCompat.getInstance(
          storage: getTestStorage(
            boxName: 'business_onboarding_restored_bootstrap',
          ),
        );
        final seedingBootstrap = HeadlessAvraiOsBootstrapService(
          host: fakeHeadlessHost,
          prefs: prefs,
        );
        await seedingBootstrap.initialize();
        final restoredBootstrap = HeadlessAvraiOsBootstrapService(
          host: _FakeBusinessHeadlessAvraiOsHost(),
          prefs: prefs,
        );
        await restoredBootstrap.restorePersistedSnapshot();

        controller = BusinessOnboardingController(
          businessAccountService: mockBusinessAccountService,
          sharedAgentService: mockSharedAgentService,
          headlessOsHost: fakeHeadlessHost,
          headlessOsBootstrapService: restoredBootstrap,
        );

        final data = BusinessOnboardingData(
          setupSharedAgent: false,
        );

        final updatedAccount = testBusinessAccount.copyWith(updatedAt: now);

        when(mockBusinessAccountService.getBusinessAccount('business_123'))
            .thenAnswer((_) async => testBusinessAccount);
        when(mockBusinessAccountService.updateBusinessAccount(
          testBusinessAccount,
          expertPreferences: null,
          patronPreferences: null,
          requiredExpertise: null,
          preferredCommunities: null,
        )).thenAnswer((_) async => updatedAccount);

        final result = await controller.completeBusinessOnboarding(
          businessId: 'business_123',
          data: data,
        );

        expect(result.success, isTrue);
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

      test('should return failure for non-existent business account', () async {
        // Arrange
        final data = BusinessOnboardingData();

        when(mockBusinessAccountService.getBusinessAccount('business_123'))
            .thenAnswer((_) async => null);

        // Act
        final result = await controller.completeBusinessOnboarding(
          businessId: 'business_123',
          data: data,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Business account not found'));
        expect(result.errorCode, equals('BUSINESS_NOT_FOUND'));

        verify(mockBusinessAccountService.getBusinessAccount('business_123'))
            .called(1);
        verifyNever(mockBusinessAccountService.updateBusinessAccount(
          any,
          expertPreferences: anyNamed('expertPreferences'),
          patronPreferences: anyNamed('patronPreferences'),
          requiredExpertise: anyNamed('requiredExpertise'),
          preferredCommunities: anyNamed('preferredCommunities'),
        ));
      });

      test('should return failure when update business account fails',
          () async {
        // Arrange
        final data = BusinessOnboardingData(
          expertPreferences: const BusinessExpertPreferences(),
        );

        when(mockBusinessAccountService.getBusinessAccount('business_123'))
            .thenAnswer((_) async => testBusinessAccount);
        when(mockBusinessAccountService.updateBusinessAccount(
          testBusinessAccount,
          expertPreferences: anyNamed('expertPreferences'),
          patronPreferences: null,
          requiredExpertise: null,
          preferredCommunities: null,
        )).thenThrow(Exception('Update failed'));

        // Act
        final result = await controller.completeBusinessOnboarding(
          businessId: 'business_123',
          data: data,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Failed to update business account'));
        expect(result.errorCode, equals('UPDATE_FAILED'));
      });

      test(
          'should return partial success when shared agent initialization fails',
          () async {
        // Arrange
        final data = BusinessOnboardingData(
          setupSharedAgent: true,
        );

        final updatedAccount = testBusinessAccount.copyWith(
          updatedAt: now,
        );

        when(mockBusinessAccountService.getBusinessAccount('business_123'))
            .thenAnswer((_) async => testBusinessAccount);
        when(mockBusinessAccountService.updateBusinessAccount(
          testBusinessAccount,
          expertPreferences: null,
          patronPreferences: null,
          requiredExpertise: null,
          preferredCommunities: null,
        )).thenAnswer((_) async => updatedAccount);
        when(mockSharedAgentService.initializeSharedAgent('business_123'))
            .thenThrow(Exception('Agent init failed'));

        // Act
        final result = await controller.completeBusinessOnboarding(
          businessId: 'business_123',
          data: data,
        );

        // Assert
        expect(result.success, isTrue); // Still success, but with warning
        expect(result.businessAccount, isNotNull);
        expect(result.sharedAgentId, isNull);
        expect(result.warning, contains('shared AI agent setup failed'));
      });

      test(
          'should update business account with required expertise and preferred communities',
          () async {
        // Arrange
        final data = BusinessOnboardingData(
          requiredExpertise: ['Coffee', 'Food'],
          preferredCommunities: ['community_1', 'community_2'],
        );

        final updatedAccount = testBusinessAccount.copyWith(
          requiredExpertise: ['Coffee', 'Food'],
          preferredCommunities: ['community_1', 'community_2'],
          updatedAt: now,
        );

        when(mockBusinessAccountService.getBusinessAccount('business_123'))
            .thenAnswer((_) async => testBusinessAccount);
        when(mockBusinessAccountService.updateBusinessAccount(
          testBusinessAccount,
          expertPreferences: null,
          patronPreferences: null,
          requiredExpertise: ['Coffee', 'Food'],
          preferredCommunities: ['community_1', 'community_2'],
        )).thenAnswer((_) async => updatedAccount);

        // Act
        final result = await controller.completeBusinessOnboarding(
          businessId: 'business_123',
          data: data,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.businessAccount?.requiredExpertise,
            containsAll(['Coffee', 'Food']));
        expect(result.businessAccount?.preferredCommunities,
            containsAll(['community_1', 'community_2']));
      });
    });

    group('execute (WorkflowController interface)', () {
      test('should execute workflow via execute method', () async {
        // Arrange
        final data = BusinessOnboardingData(
          businessId: 'business_123',
          setupSharedAgent: false,
        );

        final updatedAccount = testBusinessAccount.copyWith(updatedAt: now);

        when(mockBusinessAccountService.getBusinessAccount('business_123'))
            .thenAnswer((_) async => testBusinessAccount);
        when(mockBusinessAccountService.updateBusinessAccount(
          testBusinessAccount,
          expertPreferences: null,
          patronPreferences: null,
          requiredExpertise: null,
          preferredCommunities: null,
        )).thenAnswer((_) async => updatedAccount);

        // Act
        final result = await controller.execute(data);

        // Assert
        expect(result.success, isTrue);
        expect(result.businessAccount, isNotNull);
      });

      test('should return failure when businessId is missing', () async {
        // Arrange
        final data = BusinessOnboardingData(
            // businessId is null
            );

        // Act
        final result = await controller.execute(data);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Business ID is required'));
        expect(result.errorCode, equals('VALIDATION_ERROR'));
      });
    });

    group('rollback', () {
      test('should not throw when rollback is called', () async {
        // Arrange
        final result = BusinessOnboardingResult.success(
          businessAccount: testBusinessAccount,
        );

        // Act & Assert
        expect(() => controller.rollback(result), returnsNormally);
        await controller.rollback(result);
      });
    });
  });
}

class _FakeBusinessHeadlessAvraiOsHost implements HeadlessAvraiOsHost {
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
      summary: 'business onboarding host',
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
      what: const WhatRealityProjection(summary: 'what', confidence: 0.84),
      when: const WhenRealityProjection(summary: 'when', confidence: 0.86),
      where: const WhereRealityProjection(
        summary: 'where',
        confidence: 0.9,
        payload: <String, dynamic>{'locality_contained_in_where': true},
      ),
      why: const WhyRealityProjection(summary: 'why', confidence: 0.83),
      how: const HowRealityProjection(summary: 'how', confidence: 0.82),
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
          summary: 'business locality remains inside where',
          confidence: 0.9,
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
          primaryActor: 'business_123',
          affectedActor: 'business_123',
          companionActors: <String>['agent_456'],
          actorRoles: <String>['business'],
          trustScope: 'shared',
          cohortRefs: <String>[],
          identityConfidence: 0.9,
        ),
        what: const WhatKernelSnapshot(
          actionType: 'complete_business_onboarding',
          targetEntityType: 'business_account',
          targetEntityId: 'business_123',
          stateTransitionType: 'initialized',
          outcomeType: 'completed',
          semanticTags: <String>['business_onboarding'],
          taxonomyConfidence: 0.88,
        ),
        when: WhenKernelSnapshot(
          observedAt: DateTime.utc(2026, 3, 6),
          freshness: 1.0,
          recencyBucket: 'current',
          timingConflictFlags: const <String>[],
          temporalConfidence: 0.94,
        ),
        where: const WhereKernelSnapshot(
          localityToken: 'where:locality:business',
          cityCode: 'chi',
          localityCode: 'river_north',
          projection: <String, dynamic>{'locality_contained_in_where': true},
          boundaryTension: 0.14,
          spatialConfidence: 0.89,
          travelFriction: 0.2,
          placeFitFlags: <String>['locality_contained_in_where'],
        ),
        how: const HowKernelSnapshot(
          executionPath:
              'business_onboarding_controller.completeBusinessOnboarding',
          workflowStage: 'business_onboarding',
          transportMode: 'in_process',
          plannerMode: 'workflow',
          modelFamily: 'headless_os',
          interventionChain: <String>['load', 'update', 'initialize'],
          failureMechanism: 'none',
          mechanismConfidence: 0.9,
        ),
        why: WhyKernelSnapshot(
          goal: 'bootstrap_business_runtime',
          summary: 'business onboarding completed',
          rootCauseType: WhyRootCauseType.contextDriven,
          confidence: 0.87,
          drivers: const <WhySignal>[
            WhySignal(label: 'business_account_persisted', weight: 0.9),
          ],
          inhibitors: const <WhySignal>[],
          counterfactuals: const <WhyCounterfactual>[],
          createdAtUtc: DateTime.utc(2026, 3, 6),
        ),
      );
}
