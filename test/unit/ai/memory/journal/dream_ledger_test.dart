import 'package:avrai/core/ai/memory/journal/dream_ledger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DreamLedgerEntry', () {
    test('validates required dream ledger fields', () {
      final entry = DreamLedgerEntry(
        dreamId: 'dream-1',
        modelFamily: DreamModelFamily.worldModel,
        assumptions: const ['assume weekend music demand rises'],
        simulatorVersion: 'sim-v3.2.1',
        hypothesisRefs: const ['hyp-17', 'hyp-22'],
        predictedDeltas: const {'conversion_rate': 0.08, 'bounce_rate': -0.04},
        falsificationPlanId: 'plan-falsify-9',
        createdAt: DateTime.utc(2026, 2, 20, 15),
      );

      expect(entry.isValid, isTrue);
    });

    test('round-trips through json contract', () {
      final entry = DreamLedgerEntry(
        dreamId: 'dream-2',
        modelFamily: DreamModelFamily.universeModel,
        assumptions: const ['assume localized novelty uplift'],
        simulatorVersion: 'sim-v3.2.2',
        hypothesisRefs: const ['hyp-31'],
        predictedDeltas: const {'novelty_score': 0.12},
        falsificationPlanId: 'plan-falsify-11',
        createdAt: DateTime.utc(2026, 2, 20, 16),
      );

      final decoded = DreamLedgerEntry.fromJson(entry.toJson());

      expect(decoded.dreamId, entry.dreamId);
      expect(decoded.modelFamily, entry.modelFamily);
      expect(decoded.assumptions, entry.assumptions);
      expect(decoded.simulatorVersion, entry.simulatorVersion);
      expect(decoded.hypothesisRefs, entry.hypothesisRefs);
      expect(decoded.predictedDeltas, entry.predictedDeltas);
      expect(decoded.falsificationPlanId, entry.falsificationPlanId);
      expect(decoded.createdAt, entry.createdAt);
    });

    test('throws on unknown model family', () {
      expect(
        () => DreamLedgerEntry.fromJson({
          'dream_id': 'dream-x',
          'model_family': 'bad_family',
          'assumptions': const ['a'],
          'simulator_version': 'sim',
          'hypothesis_refs': const ['h'],
          'predicted_deltas': const {'x': 1},
          'falsification_plan_id': 'p',
          'created_at': DateTime.utc(2026, 2, 20).toIso8601String(),
        }),
        throwsFormatException,
      );
    });

    test('throws on non-numeric predicted delta values', () {
      expect(
        () => DreamLedgerEntry.fromJson({
          'dream_id': 'dream-x',
          'model_family': DreamModelFamily.realityModel.name,
          'assumptions': const ['a'],
          'simulator_version': 'sim',
          'hypothesis_refs': const ['h'],
          'predicted_deltas': const {'x': 'not_number'},
          'falsification_plan_id': 'p',
          'created_at': DateTime.utc(2026, 2, 20).toIso8601String(),
        }),
        throwsFormatException,
      );
    });
  });

  group('DreamLedger', () {
    test('appends entries and supports deterministic lookup', () {
      final ledger = DreamLedger();
      final entryA = DreamLedgerEntry(
        dreamId: 'dream-a',
        modelFamily: DreamModelFamily.realityModel,
        assumptions: const ['a'],
        simulatorVersion: 'sim',
        hypothesisRefs: const ['h-a'],
        predictedDeltas: const {'delta': 0.1},
        falsificationPlanId: 'p-a',
        createdAt: DateTime.utc(2026, 2, 20, 18),
      );
      final entryB = DreamLedgerEntry(
        dreamId: 'dream-b',
        modelFamily: DreamModelFamily.worldModel,
        assumptions: const ['b'],
        simulatorVersion: 'sim',
        hypothesisRefs: const ['h-b'],
        predictedDeltas: const {'delta': -0.2},
        falsificationPlanId: 'p-b',
        createdAt: DateTime.utc(2026, 2, 20, 19),
      );

      ledger.append(entryA);
      ledger.append(entryB);

      expect(ledger.snapshot(), hasLength(2));
      expect(ledger.byDreamId('dream-b')?.falsificationPlanId, 'p-b');
      expect(ledger.byModelFamily(DreamModelFamily.worldModel), hasLength(1));
    });
  });
}
