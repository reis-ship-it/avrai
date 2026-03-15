import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_admin_service.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_bundle_store.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_root_cause_index.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_telemetry_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kernel store indexes root causes and aggregates telemetry', () async {
    final index = InMemoryKernelRootCauseIndex();
    final telemetry = InMemoryKernelTelemetryService();
    final store = InMemoryKernelBundleStore(
      rootCauseIndex: index,
      telemetryService: telemetry,
    );
    final admin = DefaultKernelAdminService(
      telemetryService: telemetry,
      rootCauseIndex: index,
    );

    await store.put(
      _record(
        'event-1',
        WhyRootCauseType.contextDriven,
        DateTime.utc(2026, 3, 7, 21, 0),
      ),
    );
    await store.put(
      _record(
        'event-2',
        WhyRootCauseType.pheromone,
        DateTime.utc(2026, 3, 7, 21, 1),
      ),
    );

    final summary = admin.summarize();
    expect(summary.telemetry.totalBundles, 2);
    expect(summary.telemetry.completeBundles, 2);
    expect(
      summary.telemetry.rootCauseCounts[WhyRootCauseType.contextDriven],
      1,
    );
    expect(summary.latestEntries.first.eventId, 'event-2');
    expect(
      admin.listByRootCauseType(WhyRootCauseType.pheromone).single.eventId,
      'event-2',
    );
  });
}

KernelBundleRecord _record(
  String eventId,
  WhyRootCauseType rootCauseType,
  DateTime createdAtUtc,
) {
  return KernelBundleRecord(
    recordId: 'record:$eventId',
    eventId: eventId,
    createdAtUtc: createdAtUtc,
    bundle: KernelContextBundle(
      who: const WhoKernelSnapshot(
        primaryActor: 'system',
        affectedActor: 'user',
        companionActors: <String>[],
        actorRoles: <String>['system'],
        trustScope: 'private',
        cohortRefs: <String>[],
        identityConfidence: 1.0,
      ),
      what: const WhatKernelSnapshot(
        actionType: 'test',
        targetEntityType: 'entity',
        targetEntityId: 'id',
        stateTransitionType: 'transition',
        outcomeType: 'outcome',
        semanticTags: <String>['test'],
        taxonomyConfidence: 1.0,
      ),
      when: WhenKernelSnapshot(
        observedAt: createdAtUtc,
        freshness: 1.0,
        recencyBucket: 'immediate',
        timingConflictFlags: const <String>[],
        temporalConfidence: 1.0,
      ),
      where: const WhereKernelSnapshot(
        localityToken: 'where:bootstrap',
        cityCode: 'city',
        localityCode: 'locality',
        projection: <String, dynamic>{},
        boundaryTension: 0.0,
        spatialConfidence: 1.0,
        travelFriction: 0.0,
        placeFitFlags: <String>[],
      ),
      how: const HowKernelSnapshot(
        executionPath: 'test',
        workflowStage: 'test',
        transportMode: 'in_process',
        plannerMode: 'test',
        modelFamily: 'test',
        interventionChain: <String>['test'],
        failureMechanism: 'none',
        mechanismConfidence: 1.0,
      ),
      why: WhyKernelSnapshot(
        goal: 'test',
        summary: 'test',
        rootCauseType: rootCauseType,
        confidence: 0.9,
        drivers: const <WhySignal>[
          WhySignal(label: 'driver', weight: 0.5, source: 'what'),
        ],
        inhibitors: const <WhySignal>[
          WhySignal(label: 'inhibitor', weight: 0.4, source: 'pheromone'),
        ],
        counterfactuals: const <WhyCounterfactual>[],
        createdAtUtc: createdAtUtc,
      ),
    ),
  );
}
