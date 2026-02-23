import 'package:avrai/core/ai/memory/journal/dwell_budget_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DwellBudgetPolicy', () {
    test('round-trips via JSON', () {
      const policy = DwellBudgetPolicy(
        issueClass: DwellIssueClass.rankingRegression,
        maxActiveAttempts: 3,
        maxWallClockDwell: Duration(minutes: 90),
        forcedEscalationPath: ForcedEscalationPath.experiment,
      );

      final decoded = DwellBudgetPolicy.fromJson(policy.toJson());

      expect(decoded.issueClass, DwellIssueClass.rankingRegression);
      expect(decoded.maxActiveAttempts, 3);
      expect(decoded.maxWallClockDwell, const Duration(minutes: 90));
      expect(decoded.forcedEscalationPath, ForcedEscalationPath.experiment);
      expect(decoded.isValid, isTrue);
    });

    test('rejects unknown enum values', () {
      expect(
        () => DwellBudgetPolicy.fromJson({
          'issue_class': 'not_real',
          'max_active_attempts': 2,
          'max_wall_clock_dwell_seconds': 60,
          'forced_escalation_path': 'fix',
        }),
        throwsFormatException,
      );
    });
  });

  group('DwellBudgetPolicyRegistry', () {
    test('escalates when active attempts budget is exhausted', () {
      final registry = DwellBudgetPolicyRegistry();
      registry.upsert(
        const DwellBudgetPolicy(
          issueClass: DwellIssueClass.retrievalQuality,
          maxActiveAttempts: 2,
          maxWallClockDwell: Duration(hours: 2),
          forcedEscalationPath: ForcedEscalationPath.fix,
        ),
      );

      final decision = registry.evaluate(
        issueClass: DwellIssueClass.retrievalQuality,
        activeAttempts: 2,
        issueOpenedAt: DateTime.utc(2026, 2, 20, 8),
        now: DateTime.utc(2026, 2, 20, 8, 30),
      );

      expect(decision.attemptsExceeded, isTrue);
      expect(decision.wallClockExceeded, isFalse);
      expect(decision.shouldEscalate, isTrue);
      expect(decision.escalationPath, ForcedEscalationPath.fix);
    });

    test('escalates when wall-clock dwell budget is exceeded', () {
      final registry = DwellBudgetPolicyRegistry();
      registry.upsert(
        const DwellBudgetPolicy(
          issueClass: DwellIssueClass.policyDrift,
          maxActiveAttempts: 5,
          maxWallClockDwell: Duration(minutes: 45),
          forcedEscalationPath: ForcedEscalationPath.escalate,
        ),
      );

      final decision = registry.evaluate(
        issueClass: DwellIssueClass.policyDrift,
        activeAttempts: 1,
        issueOpenedAt: DateTime.utc(2026, 2, 20, 8, 0),
        now: DateTime.utc(2026, 2, 20, 8, 50),
      );

      expect(decision.attemptsExceeded, isFalse);
      expect(decision.wallClockExceeded, isTrue);
      expect(decision.shouldEscalate, isTrue);
      expect(decision.escalationPath, ForcedEscalationPath.escalate);
    });

    test('does not escalate when issue is within policy budgets', () {
      final registry = DwellBudgetPolicyRegistry();
      registry.upsert(
        const DwellBudgetPolicy(
          issueClass: DwellIssueClass.infraReliability,
          maxActiveAttempts: 4,
          maxWallClockDwell: Duration(hours: 6),
          forcedEscalationPath: ForcedEscalationPath.experiment,
        ),
      );

      final decision = registry.evaluate(
        issueClass: DwellIssueClass.infraReliability,
        activeAttempts: 1,
        issueOpenedAt: DateTime.utc(2026, 2, 20, 8, 0),
        now: DateTime.utc(2026, 2, 20, 8, 45),
      );

      expect(decision.attemptsExceeded, isFalse);
      expect(decision.wallClockExceeded, isFalse);
      expect(decision.shouldEscalate, isFalse);
      expect(decision.escalationPath, isNull);
    });
  });
}
