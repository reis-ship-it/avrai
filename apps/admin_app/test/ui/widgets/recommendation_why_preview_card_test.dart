import 'package:avrai_admin_app/ui/widgets/recommendation_why_preview_card.dart';
import 'package:avrai_core/models/why/why_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart'
    as kernel_models;
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/recommendations/recommendation_telemetry_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../helpers/integration_test_helpers.dart';
import '../../mocks/mock_storage_service.dart';

void main() {
  tearDown(() async {
    MockGetStorage.reset();
    if (GetIt.instance.isRegistered<RecommendationTelemetryService>()) {
      await GetIt.instance.unregister<RecommendationTelemetryService>();
    }
    if (GetIt.instance.isRegistered<HeadlessAvraiOsHost>()) {
      await GetIt.instance.unregister<HeadlessAvraiOsHost>();
    }
  });

  testWidgets('renders preview snapshot from injected loader',
      (WidgetTester tester) async {
    final user = IntegrationTestHelpers.createUserWithLocalExpertise(
      id: 'user-1',
      category: 'food',
    );
    final event = IntegrationTestHelpers.createTestEvent(
      id: 'event-1',
      host: user,
      category: 'food',
    ).copyWith(location: 'Austin, TX');
    final preview = RecommendationWhyPreview(
      snapshot: const WhySnapshot(
        goal: 'explain_event_recommendation',
        queryKind: WhyQueryKind.recommendation,
        primaryHypothesis: WhyHypothesis(
          id: 'primary',
          label: 'recommendation attributed to locality preference',
          rootCauseType: WhyRootCauseType.locality,
          confidence: 0.81,
        ),
        drivers: <WhySignal>[
          WhySignal(
            label: 'same locality as user',
            weight: 0.74,
            kernel: WhyEvidenceSourceKernel.where,
          ),
        ],
        inhibitors: <WhySignal>[],
        counterfactuals: <WhyCounterfactual>[],
        confidence: 0.81,
        ambiguity: 0.12,
        rootCauseType: WhyRootCauseType.locality,
        summary: 'recommend_event produced event-1 due to locality signals.',
      ),
      event: event,
      referenceUser: user,
      generatedAt: DateTime.utc(2026, 3, 7, 9),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecommendationWhyPreviewCard(
              previewLoader: () async => preview,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recommendation Why Preview'), findsOneWidget);
    expect(find.textContaining('Canonical Recommendation Why Snapshot'),
        findsOneWidget);
    expect(find.textContaining('reference user user-1'), findsOneWidget);
    expect(find.textContaining('same locality as user'), findsOneWidget);
  });

  testWidgets('default loader prefers recorded recommendation telemetry',
      (WidgetTester tester) async {
    final storage =
        MockGetStorage.getInstance(boxName: 'recommendation_preview');
    final prefs = await SharedPreferencesCompat.getInstance(storage: storage);
    final service = RecommendationTelemetryService(prefs: prefs);
    await service.recordRecommendations(<RecommendationTelemetryRecord>[
      RecommendationTelemetryRecord(
        recordId: 'rec_older',
        timestamp: DateTime.utc(2026, 3, 7, 8),
        userId: 'telemetry-user-older',
        eventId: 'telemetry-event-older',
        eventTitle: 'Telemetry Book Walk',
        category: 'books',
        reason: 'Older recommendation reason',
        relevanceScore: 0.7,
        traceRef: 'user:telemetry-user-older|event:telemetry-event-older',
        location: 'Dallas, TX',
        kernelEventId: 'kernel:older',
        modelTruthReady: false,
        localityContainedInWhere: true,
        governanceSummary: 'older governance summary',
        governanceDomains: const <String>['where'],
        explanation: const WhySnapshot(
          goal: 'explain_event_recommendation',
          queryKind: WhyQueryKind.recommendation,
          drivers: <WhySignal>[
            WhySignal(
              label: 'older telemetry driver',
              weight: 0.7,
              kernel: WhyEvidenceSourceKernel.what,
            ),
          ],
          inhibitors: <WhySignal>[],
          counterfactuals: <WhyCounterfactual>[],
          confidence: 0.7,
          rootCauseType: WhyRootCauseType.contextDriven,
          summary:
              'recommend_event produced telemetry-event-older due to books signals.',
        ),
      ),
      RecommendationTelemetryRecord(
        recordId: 'rec_latest',
        timestamp: DateTime.utc(2026, 3, 7, 9),
        userId: 'telemetry-user',
        eventId: 'telemetry-event',
        eventTitle: 'Telemetry Coffee Walk',
        category: 'food',
        reason: 'Matches your interest in food',
        relevanceScore: 0.9,
        traceRef: 'user:telemetry-user|event:telemetry-event',
        location: 'Austin, TX',
        kernelEventId: 'kernel:latest',
        modelTruthReady: true,
        localityContainedInWhere: true,
        governanceSummary: 'latest governance summary',
        governanceDomains: const <String>['who', 'where', 'how'],
        explanation: const WhySnapshot(
          goal: 'explain_event_recommendation',
          queryKind: WhyQueryKind.recommendation,
          drivers: <WhySignal>[
            WhySignal(
              label: 'telemetry driver',
              weight: 0.9,
              kernel: WhyEvidenceSourceKernel.what,
            ),
          ],
          inhibitors: <WhySignal>[],
          counterfactuals: <WhyCounterfactual>[],
          confidence: 0.9,
          rootCauseType: WhyRootCauseType.contextDriven,
          summary:
              'recommend_event produced telemetry-event due to food signals.',
        ),
      ),
    ]);
    GetIt.instance.registerSingleton<RecommendationTelemetryService>(service);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecommendationWhyPreviewCard(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Telemetry Coffee Walk'), findsWidgets);
    expect(find.textContaining('telemetry-user'), findsWidgets);
    expect(find.textContaining('telemetry driver'), findsOneWidget);
    expect(find.text('model truth ready'), findsOneWidget);
    expect(find.text('locality in where'), findsOneWidget);
    expect(find.textContaining('Kernel Event: kernel:latest'), findsOneWidget);
    expect(find.textContaining('Governance: latest governance summary'),
        findsOneWidget);
    expect(find.text('Recent Recommendation Audits'), findsOneWidget);
    expect(find.textContaining('Telemetry Book Walk'), findsOneWidget);
    expect(find.text('Export Filtered'), findsOneWidget);
    expect(find.textContaining('record rec_latest'), findsOneWidget);
    expect(find.text('Audit Drill-down'), findsOneWidget);

    await tester.tap(find.text('books'));
    await tester.pumpAndSettle();

    expect(find.text('Telemetry Book Walk'), findsOneWidget);
    expect(find.text('Telemetry Coffee Walk'), findsNothing);

    await tester.tap(find.text('Telemetry Book Walk'));
    await tester.pumpAndSettle();

    expect(find.textContaining('telemetry-user-older'), findsWidgets);
    expect(find.textContaining('older telemetry driver'), findsOneWidget);
    expect(find.textContaining('rec_older'), findsWidgets);
    expect(find.textContaining('Kernel Event: kernel:older'), findsOneWidget);
    expect(find.textContaining('Governance: older governance summary'),
        findsOneWidget);
    expect(
        find.textContaining(
            'user:telemetry-user-older|event:telemetry-event-older'),
        findsOneWidget);

    await tester.tap(find.text('Category: All'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'telemetry-user',
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Telemetry Coffee Walk'), findsWidgets);
  });

  testWidgets('default loader falls back to headless OS host context',
      (WidgetTester tester) async {
    final host = _FakeHeadlessAvraiOsHost();
    GetIt.instance.registerSingleton<HeadlessAvraiOsHost>(host);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecommendationWhyPreviewCard(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(host.startCalls, 1);
    expect(host.runtimeCalls, 1);
    expect(host.governanceCalls, 1);
    expect(find.text('Recommendation Why Preview'), findsOneWidget);
    expect(find.textContaining('Canonical Recommendation Why Snapshot'),
        findsOneWidget);
    expect(find.textContaining('reference user admin_reference_user'),
        findsOneWidget);
  });
}

class _FakeHeadlessAvraiOsHost implements HeadlessAvraiOsHost {
  int startCalls = 0;
  int runtimeCalls = 0;
  int governanceCalls = 0;

  @override
  Future<HeadlessAvraiOsHostState> start() async {
    startCalls += 1;
    return HeadlessAvraiOsHostState(
      started: true,
      startedAtUtc: DateTime.utc(2026, 3, 7, 12),
      localityContainedInWhere: true,
      summary: 'headless test host',
    );
  }

  @override
  Future<kernel_models.RealityKernelFusionInput> buildModelTruth({
    required kernel_models.KernelEventEnvelope envelope,
    required kernel_models.KernelWhyRequest whyRequest,
  }) async {
    return kernel_models.RealityKernelFusionInput(
      envelope: envelope,
      bundle: kernel_models.KernelContextBundle(
        who: const kernel_models.WhoKernelSnapshot(
          primaryActor: 'admin_reference_user',
          affectedActor: 'admin_reference_user',
          companionActors: <String>[],
          actorRoles: <String>['admin'],
          trustScope: 'trusted_mesh',
          cohortRefs: <String>['admin'],
          identityConfidence: 0.96,
        ),
        what: const kernel_models.WhatKernelSnapshot(
          actionType: 'recommend_event',
          targetEntityType: 'event',
          targetEntityId: 'admin_reference_event',
          stateTransitionType: 'observation',
          outcomeType: 'preview',
          semanticTags: <String>['preview'],
          taxonomyConfidence: 0.9,
        ),
        when: kernel_models.WhenKernelSnapshot(
          observedAt: DateTime.utc(2026, 3, 7, 12),
          freshness: 0.95,
          recencyBucket: 'recent',
          timingConflictFlags: <String>[],
          temporalConfidence: 0.94,
        ),
        where: const kernel_models.WhereKernelSnapshot(
          localityToken: 'loc-preview',
          cityCode: 'AUS',
          localityCode: 'AUS-CENTRAL',
          projection: <String, dynamic>{'label': 'Austin'},
          boundaryTension: 0.1,
          spatialConfidence: 0.92,
          travelFriction: 0.2,
          placeFitFlags: <String>['homebase_ready'],
        ),
        how: const kernel_models.HowKernelSnapshot(
          executionPath: 'mesh_governed_recommendation',
          workflowStage: 'preview',
          transportMode: 'in_process',
          plannerMode: 'ranked_blend',
          modelFamily: 'event_recommendation',
          interventionChain: <String>['match', 'blend', 'preview'],
          failureMechanism: 'none',
          mechanismConfidence: 0.88,
        ),
      ),
      who: const kernel_models.WhoRealityProjection(
        summary: 'admin actor resolved',
        confidence: 0.96,
      ),
      what: const kernel_models.WhatRealityProjection(
        summary: 'recommendation preview observed',
        confidence: 0.9,
      ),
      when: const kernel_models.WhenRealityProjection(
        summary: 'recent quantum-aligned preview',
        confidence: 0.94,
      ),
      where: const kernel_models.WhereRealityProjection(
        summary: 'locality remains inside where projection',
        confidence: 0.92,
      ),
      why: const kernel_models.WhyRealityProjection(
        summary: 'governed preview explanation',
        confidence: 0.89,
      ),
      how: const kernel_models.HowRealityProjection(
        summary: 'mesh-governed recommendation path',
        confidence: 0.88,
      ),
      generatedAtUtc: DateTime.utc(2026, 3, 7, 12),
      localityContainedInWhere: true,
    );
  }

  @override
  Future<List<kernel_models.KernelHealthReport>> healthCheck() async {
    return const <kernel_models.KernelHealthReport>[];
  }

  @override
  Future<kernel_models.KernelGovernanceReport> inspectGovernance({
    required kernel_models.KernelEventEnvelope envelope,
    required kernel_models.KernelWhyRequest whyRequest,
  }) async {
    governanceCalls += 1;
    return kernel_models.KernelGovernanceReport(
      envelope: envelope,
      bundle: kernel_models.KernelContextBundle(
        who: const kernel_models.WhoKernelSnapshot(
          primaryActor: 'admin_reference_user',
          affectedActor: 'admin_reference_user',
          companionActors: <String>[],
          actorRoles: <String>['admin'],
          trustScope: 'trusted_mesh',
          cohortRefs: <String>['admin'],
          identityConfidence: 0.96,
        ),
        what: const kernel_models.WhatKernelSnapshot(
          actionType: 'recommend_event',
          targetEntityType: 'event',
          targetEntityId: 'admin_reference_event',
          stateTransitionType: 'observation',
          outcomeType: 'preview',
          semanticTags: <String>['preview'],
          taxonomyConfidence: 0.9,
        ),
        when: kernel_models.WhenKernelSnapshot(
          observedAt: DateTime.utc(2026, 3, 7, 12),
          freshness: 0.95,
          recencyBucket: 'recent',
          timingConflictFlags: <String>[],
          temporalConfidence: 0.94,
        ),
        where: const kernel_models.WhereKernelSnapshot(
          localityToken: 'loc-preview',
          cityCode: 'AUS',
          localityCode: 'AUS-CENTRAL',
          projection: <String, dynamic>{'label': 'Austin'},
          boundaryTension: 0.1,
          spatialConfidence: 0.92,
          travelFriction: 0.2,
          placeFitFlags: <String>['homebase_ready'],
        ),
        how: const kernel_models.HowKernelSnapshot(
          executionPath: 'mesh_governed_recommendation',
          workflowStage: 'preview',
          transportMode: 'in_process',
          plannerMode: 'ranked_blend',
          modelFamily: 'event_recommendation',
          interventionChain: <String>['match', 'blend', 'preview'],
          failureMechanism: 'none',
          mechanismConfidence: 0.88,
        ),
      ),
      projections: const <kernel_models.KernelGovernanceProjection>[
        kernel_models.KernelGovernanceProjection(
          domain: kernel_models.KernelDomain.where,
          summary: 'locality inside where kernel',
          confidence: 0.92,
        ),
        kernel_models.KernelGovernanceProjection(
          domain: kernel_models.KernelDomain.how,
          summary: 'mesh-governed kernel path',
          confidence: 0.88,
        ),
      ],
      generatedAtUtc: DateTime.utc(2026, 3, 7, 12),
    );
  }

  @override
  Future<kernel_models.KernelContextBundle> resolveRuntimeExecution({
    required kernel_models.KernelEventEnvelope envelope,
  }) async {
    runtimeCalls += 1;
    return kernel_models.KernelContextBundle(
      who: const kernel_models.WhoKernelSnapshot(
        primaryActor: 'admin_reference_user',
        affectedActor: 'admin_reference_user',
        companionActors: <String>[],
        actorRoles: <String>['admin'],
        trustScope: 'trusted_mesh',
        cohortRefs: <String>['admin'],
        identityConfidence: 0.96,
      ),
      what: const kernel_models.WhatKernelSnapshot(
        actionType: 'recommend_event',
        targetEntityType: 'event',
        targetEntityId: 'admin_reference_event',
        stateTransitionType: 'observation',
        outcomeType: 'preview',
        semanticTags: <String>['preview'],
        taxonomyConfidence: 0.9,
      ),
      when: kernel_models.WhenKernelSnapshot(
        observedAt: DateTime.utc(2026, 3, 7, 12),
        freshness: 0.95,
        recencyBucket: 'recent',
        timingConflictFlags: <String>[],
        temporalConfidence: 0.94,
      ),
      where: const kernel_models.WhereKernelSnapshot(
        localityToken: 'loc-preview',
        cityCode: 'AUS',
        localityCode: 'AUS-CENTRAL',
        projection: <String, dynamic>{'label': 'Austin'},
        boundaryTension: 0.1,
        spatialConfidence: 0.92,
        travelFriction: 0.2,
        placeFitFlags: <String>['homebase_ready'],
      ),
      how: const kernel_models.HowKernelSnapshot(
        executionPath: 'mesh_governed kernel path',
        workflowStage: 'preview',
        transportMode: 'in_process',
        plannerMode: 'ranked_blend',
        modelFamily: 'event_recommendation',
        interventionChain: <String>['match', 'blend', 'preview'],
        failureMechanism: 'none',
        mechanismConfidence: 0.88,
      ),
    );
  }
}
