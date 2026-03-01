import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:avrai_runtime_os/ai/knowledge_lifecycle/claim_lifecycle_contract.dart';
import 'package:avrai_runtime_os/controllers/conviction_shadow_gate.dart';

class _InMemoryTelemetryStore implements ConvictionGateTelemetryStore {
  final Map<String, String> _data = <String, String>{};

  @override
  String? getString(String key) => _data[key];

  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }
}

void main() {
  group('SharedPrefsConvictionGateTelemetrySink', () {
    test('persists encoded decision payload', () async {
      final store = _InMemoryTelemetryStore();
      final sink = SharedPrefsConvictionGateTelemetrySink(store: store);

      final decision = ConvictionGateDecision(
        mode: ConvictionGateMode.shadow,
        requestId: 'req-1',
        controllerName: 'CheckoutController',
        subjectId: 'user-1',
        claimState: ClaimLifecycleState.hypothesis,
        isHighImpact: true,
        policyChecksPassed: false,
        wouldAllow: false,
        servingAllowed: true,
        shadowBypassApplied: true,
        reasonCodes: const ['policy_checks_failed'],
        timestamp: DateTime.utc(2026, 2, 27, 12, 0, 0),
      );

      await sink.record(decision);

      final encoded = store.getString('conviction_gate_shadow_decisions_v1');
      expect(encoded, isNotNull);

      final decoded = jsonDecode(encoded!) as List<dynamic>;
      expect(decoded.length, 1);
      expect(decoded.first['requestId'], 'req-1');
      expect(decoded.first['controllerName'], 'CheckoutController');
      expect(decoded.first['subjectId'], 'user-1');
      expect(decoded.first['shadowBypassApplied'], isTrue);
    });

    test('keeps only maxEvents most recent records', () async {
      final store = _InMemoryTelemetryStore();
      final sink = SharedPrefsConvictionGateTelemetrySink(
        store: store,
        maxEvents: 2,
      );

      Future<void> recordAt(int n) {
        return sink.record(
          ConvictionGateDecision(
            mode: ConvictionGateMode.shadow,
            requestId: 'req-$n',
            controllerName: 'AIRecommendationController',
            subjectId: 'user-$n',
            claimState: ClaimLifecycleState.canonical,
            isHighImpact: false,
            policyChecksPassed: true,
            wouldAllow: true,
            servingAllowed: true,
            shadowBypassApplied: false,
            reasonCodes: const <String>[],
            timestamp: DateTime.utc(2026, 2, 27, 12, 0, n),
          ),
        );
      }

      await recordAt(1);
      await recordAt(2);
      await recordAt(3);

      final encoded = store.getString('conviction_gate_shadow_decisions_v1');
      final decoded = jsonDecode(encoded!) as List<dynamic>;

      expect(decoded.length, 2);
      expect(decoded.first['requestId'], 'req-2');
      expect(decoded.last['requestId'], 'req-3');
    });
  });
}
