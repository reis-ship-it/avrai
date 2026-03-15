import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/native_backed_temporal_kernel.dart';
import 'package:avrai_runtime_os/kernel/temporal/system_temporal_kernel.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';
import 'package:avrai_runtime_os/kernel/temporal/when_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/when/when_native_priority.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TemporalInstant buildInstant(DateTime time) {
    return TemporalInstant(
      referenceTime: time.toUtc(),
      civilTime: time,
      timezoneId: 'UTC',
      provenance: const TemporalProvenance(
        authority: TemporalAuthority.device,
        source: 'test',
      ),
      uncertainty: const TemporalUncertainty.zero(),
      monotonicTicks: time.microsecondsSinceEpoch,
    );
  }

  test('native-backed kernel falls back when native bridge is unavailable',
      () async {
    final kernel = NativeBackedTemporalKernel(
      nativeBridge: _UnavailableBridge(),
      fallbackKernel: SystemTemporalKernel(
        clockSource:
            FixedClockSource(buildInstant(DateTime.utc(2026, 3, 6, 12))),
      ),
      policy: const WhenNativeExecutionPolicy(requireNative: false),
    );

    final instant = await kernel.nowCivil();

    expect(instant.referenceTime, DateTime.utc(2026, 3, 6, 12));
  });

  test('native-backed kernel throws when native is required and unavailable',
      () async {
    final kernel = NativeBackedTemporalKernel(
      nativeBridge: _UnavailableBridge(),
      fallbackKernel: SystemTemporalKernel(
        clockSource:
            FixedClockSource(buildInstant(DateTime.utc(2026, 3, 6, 12))),
      ),
      policy: const WhenNativeExecutionPolicy(requireNative: true),
    );

    expect(
      () => kernel.nowCivil(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('Native when kernel is required'),
        ),
      ),
    );
  });

  test('native-backed kernel consumes native compare payload', () async {
    final kernel = NativeBackedTemporalKernel(
      nativeBridge: _StubBridge(<String, dynamic>{
        'payload': <String, dynamic>{
          'ordering': <String, dynamic>{
            'relation': 'before',
            'deltaMicros': -3600000000,
          },
        },
        'handled': true,
      }),
      fallbackKernel: SystemTemporalKernel(
        clockSource:
            FixedClockSource(buildInstant(DateTime.utc(2026, 3, 6, 12))),
      ),
    );
    final left = TemporalSnapshot(
      observedAt: buildInstant(DateTime.utc(2026, 3, 6, 10)),
      recordedAt: buildInstant(DateTime.utc(2026, 3, 6, 10)),
      effectiveAt: buildInstant(DateTime.utc(2026, 3, 6, 10)),
      semanticBand: SemanticTimeBand.morning,
    );
    final right = TemporalSnapshot(
      observedAt: buildInstant(DateTime.utc(2026, 3, 6, 11)),
      recordedAt: buildInstant(DateTime.utc(2026, 3, 6, 11)),
      effectiveAt: buildInstant(DateTime.utc(2026, 3, 6, 11)),
      semanticBand: SemanticTimeBand.morning,
    );

    final result = await kernel.compare(left, right);

    expect(result.relation, TemporalOrderingRelation.before);
    expect(result.delta, const Duration(hours: -1));
  });

  test('native-backed kernel consumes native persistence lookups', () async {
    final instantJson = buildInstant(DateTime.utc(2026, 3, 6, 12)).toJson();
    final evidence = HistoricalTemporalEvidence(
      evidenceId: 'hist-1',
      interval: TemporalInterval(
        start: buildInstant(DateTime.utc(2026, 3, 6, 10)),
        end: buildInstant(DateTime.utc(2026, 3, 6, 11)),
      ),
      granularity: HistoricalTemporalGranularity.hour,
      confidence: 0.9,
      provenance: const TemporalProvenance(
        authority: TemporalAuthority.historicalImport,
        source: 'test',
      ),
      reconstructionMethod: 'manual',
    );
    final claim = ForecastTemporalClaim(
      claimId: 'forecast-1',
      forecastCreatedAt: DateTime.utc(2026, 3, 6, 12),
      targetWindow: TemporalInterval(
        start: buildInstant(DateTime.utc(2026, 3, 7, 10)),
        end: buildInstant(DateTime.utc(2026, 3, 7, 11)),
      ),
      evidenceWindow: TemporalInterval(
        start: buildInstant(DateTime.utc(2026, 3, 6, 10)),
        end: buildInstant(DateTime.utc(2026, 3, 6, 11)),
      ),
      confidence: 0.7,
      modelVersion: 'v1',
      provenance: const TemporalProvenance(
        authority: TemporalAuthority.forecast,
        source: 'test',
      ),
    );
    final kernel = NativeBackedTemporalKernel(
      nativeBridge: _DispatchingBridge({
        'get_historical_evidence': <String, dynamic>{
          'payload': <String, dynamic>{
            'found': true,
            'evidence': evidence.toJson(),
            'instant': instantJson,
          },
          'handled': true,
        },
        'get_forecast': <String, dynamic>{
          'payload': <String, dynamic>{
            'found': true,
            'claim': claim.toJson(),
            'instant': instantJson,
          },
          'handled': true,
        },
      }),
      fallbackKernel: SystemTemporalKernel(
        clockSource:
            FixedClockSource(buildInstant(DateTime.utc(2026, 3, 6, 12))),
      ),
    );

    final storedEvidence = await kernel.getHistoricalEvidence('hist-1');
    final storedClaim = await kernel.getForecast('forecast-1');

    expect(storedEvidence?.evidence.evidenceId, 'hist-1');
    expect(storedClaim?.claim.claimId, 'forecast-1');
  });

  test('native-backed kernel consumes runtime event lookups', () async {
    final instantJson = buildInstant(DateTime.utc(2026, 3, 6, 12)).toJson();
    final event = RuntimeTemporalEvent(
      eventId: 'runtime-1',
      occurredAt: DateTime.utc(2026, 3, 6, 11),
      source: 'ai2ai_protocol',
      eventType: 'heartbeat',
      stage: RuntimeTemporalEventStage.ordered,
      sequenceNumber: 9,
    );
    final kernel = NativeBackedTemporalKernel(
      nativeBridge: _DispatchingBridge({
        'get_runtime_event': <String, dynamic>{
          'payload': <String, dynamic>{
            'found': true,
            'event': event.toJson(),
            'instant': instantJson,
          },
          'handled': true,
        },
      }),
      fallbackKernel: SystemTemporalKernel(
        clockSource:
            FixedClockSource(buildInstant(DateTime.utc(2026, 3, 6, 12))),
      ),
    );

    final stored = await kernel.getRuntimeEvent('runtime-1');

    expect(stored?.event.eventId, 'runtime-1');
    expect(stored?.event.stage, RuntimeTemporalEventStage.ordered);
  });

  test('native-backed kernel consumes runtime event queries', () async {
    final instantJson = buildInstant(DateTime.utc(2026, 3, 6, 12)).toJson();
    final event = RuntimeTemporalEvent(
      eventId: 'runtime-q1',
      occurredAt: DateTime.utc(2026, 3, 6, 11),
      source: 'ai2ai_protocol',
      eventType: 'heartbeat',
      stage: RuntimeTemporalEventStage.ordered,
      peerId: 'peer-1',
    );
    final kernel = NativeBackedTemporalKernel(
      nativeBridge: _DispatchingBridge({
        'query_runtime_events': <String, dynamic>{
          'payload': <String, dynamic>{
            'events': <Map<String, dynamic>>[
              <String, dynamic>{
                'event': event.toJson(),
                'recordedAt': instantJson,
              },
            ],
            'instant': instantJson,
          },
          'handled': true,
        },
      }),
      fallbackKernel: SystemTemporalKernel(
        clockSource:
            FixedClockSource(buildInstant(DateTime.utc(2026, 3, 6, 12))),
      ),
    );

    final results = await kernel.queryRuntimeEvents(
      const RuntimeTemporalEventQuery(source: 'ai2ai_protocol'),
    );

    expect(results, hasLength(1));
    expect(results.first.event.eventId, 'runtime-q1');
  });
}

class _UnavailableBridge implements WhenNativeInvocationBridge {
  @override
  bool get isAvailable => false;

  @override
  void initialize() {}

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    throw UnimplementedError();
  }
}

class _StubBridge implements WhenNativeInvocationBridge {
  _StubBridge(this._response);

  final Map<String, dynamic> _response;

  @override
  bool get isAvailable => true;

  @override
  void initialize() {}

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    return _response;
  }
}

class _DispatchingBridge implements WhenNativeInvocationBridge {
  _DispatchingBridge(this._responses);

  final Map<String, Map<String, dynamic>> _responses;

  @override
  bool get isAvailable => true;

  @override
  void initialize() {}

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    return _responses[syscall] ?? <String, dynamic>{'handled': false};
  }
}
