import 'package:avrai_core/models/temporal/replay_simulation_artifacts.dart';
import 'package:test/test.dart';

void main() {
  test('ReplayScenarioPacket preserves non-BHAM city and replay year', () {
    final packet = ReplayScenarioPacket(
      scenarioId: 'atx-citywide-weather',
      name: 'Austin weather pressure',
      description: 'Generic replay packet for a non-BHAM environment.',
      cityCode: 'atx',
      baseReplayYear: 2024,
      scenarioKind: ReplayScenarioKind.weather,
      scope: ReplayScopeKind.city,
      seedEntityRefs: const <String>['event:citywide_series'],
      seedLocalityCodes: const <String>['atx_downtown'],
      seedObservationRefs: const <String>['obs:atx_seed'],
      interventions: const <ReplayScenarioIntervention>[],
      expectedQuestions: const <String>['What degrades first?'],
      createdAt: DateTime.utc(2026, 3, 31, 22),
      createdBy: 'test',
    );

    final normalized = packet.normalized();
    final decoded = ReplayScenarioPacket.fromJson(normalized.toJson());

    expect(normalized.cityCode, 'atx');
    expect(normalized.baseReplayYear, 2024);
    expect(decoded.cityCode, 'atx');
    expect(decoded.baseReplayYear, 2024);
    expect(decoded.isReplayValid, isTrue);
    expect(decoded.isValidForPhase1, isFalse);
  });

  test('ReplayScenarioPacket falls back to a generic simulation city code', () {
    final decoded = ReplayScenarioPacket.fromJson(<String, dynamic>{
      'scenarioId': 'generic-seed',
      'name': 'Generic simulation seed',
      'description': 'Fallback packet without explicit city identity.',
      'baseReplayYear': 2024,
      'scenarioKind': ReplayScenarioKind.eventOps.name,
      'scope': ReplayScopeKind.city.name,
      'createdAt': DateTime.utc(2026, 4, 1).toIso8601String(),
      'createdBy': 'test',
      'isReplayOnly': true,
    });

    expect(decoded.cityCode, ReplayScenarioPacket.defaultSimulationCityCode);
    expect(decoded.baseReplayYear, 2024);
    expect(decoded.isReplayValid, isTrue);
    expect(decoded.isValidForPhase1, isFalse);
  });
}
