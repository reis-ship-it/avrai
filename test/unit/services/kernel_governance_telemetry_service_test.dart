import 'dart:convert';

import 'package:avrai/core/services/ai_infrastructure/kernel_governance_telemetry_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/mock_storage_service.dart';

void main() {
  setUp(() {
    MockGetStorage.reset();
  });

  Future<KernelGovernanceTelemetryService> buildService({
    Duration retentionWindow = const Duration(days: 30),
    int maxEvents = 2000,
    String boxName = 'kg_telemetry_test',
  }) async {
    final storage = MockGetStorage.getInstance(boxName: boxName);
    final prefs = await SharedPreferencesCompat.getInstance(storage: storage);
    return KernelGovernanceTelemetryService(
      prefs: prefs,
      retentionWindow: retentionWindow,
      maxEvents: maxEvents,
    );
  }

  KernelGovernanceTelemetryEvent buildEvent({
    required String id,
    required DateTime ts,
    String? correlationId,
    bool servingAllowed = true,
  }) {
    return KernelGovernanceTelemetryEvent(
      timestamp: ts,
      decisionId: id,
      action: 'modelSwitch',
      mode: 'enforce',
      wouldAllow: servingAllowed,
      servingAllowed: servingAllowed,
      shadowBypassApplied: false,
      reasonCodes: servingAllowed ? const <String>[] : const <String>['x'],
      policyVersion: 'v-test',
      correlationId: correlationId,
      modelType: 'calling_score',
      fromVersion: 'v1',
      toVersion: 'v2',
    );
  }

  test('listAll returns newest first and preserves ids', () async {
    final service = await buildService();
    final now = DateTime.now().toUtc();
    await service.recordDecision(
        buildEvent(id: 'd1', ts: now.subtract(const Duration(minutes: 2))));
    await service
        .recordDecision(buildEvent(id: 'd2', ts: now, correlationId: 'corr_2'));

    final all = service.listAll();
    expect(all.map((event) => event.decisionId).toList(), <String>['d2', 'd1']);
    expect(all.first.correlationId, 'corr_2');
  });

  test('compact drops expired events and enforces max events', () async {
    final service = await buildService(
      retentionWindow: const Duration(days: 1),
      maxEvents: 2,
    );
    final now = DateTime.now().toUtc();
    await service.recordDecision(
      buildEvent(id: 'expired', ts: now.subtract(const Duration(days: 2))),
    );
    await service.recordDecision(buildEvent(
        id: 'recent1', ts: now.subtract(const Duration(minutes: 3))));
    await service.recordDecision(buildEvent(
        id: 'recent2', ts: now.subtract(const Duration(minutes: 2))));
    await service.recordDecision(buildEvent(
        id: 'recent3', ts: now.subtract(const Duration(minutes: 1))));

    await service.compact();
    final all = service.listAll();

    expect(all.length, 2);
    expect(all.map((event) => event.decisionId).toList(),
        <String>['recent3', 'recent2']);
  });

  test('exportEventsJson exports decision and correlation ids', () async {
    final service = await buildService();
    final now = DateTime.now().toUtc();
    await service.recordDecision(
      buildEvent(id: 'd_export', ts: now, correlationId: 'corr_export'),
    );

    final payload = service.exportEventsJson(service.listAll());
    final decoded = jsonDecode(payload) as List<dynamic>;
    final first = decoded.first as Map<String, dynamic>;
    expect(first['decision_id'], 'd_export');
    expect(first['correlation_id'], 'corr_export');
  });
}
