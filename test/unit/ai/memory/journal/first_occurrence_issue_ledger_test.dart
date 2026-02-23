import 'package:avrai/core/ai/memory/journal/first_occurrence_issue_ledger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirstOccurrenceIssueLedger', () {
    test('creates deterministic triage entry on first-seen signature', () {
      final ledger = FirstOccurrenceIssueLedger();
      final detectedAt = DateTime.utc(2026, 2, 20, 11, 30);

      final entry = ledger.recordFirstSeen(
        issueSignature: 'retrieval:zero-results:music',
        severity: IssueSeverity.low,
        impactRadius: IssueImpactRadius.singleUser,
        detectedAt: detectedAt,
        subsystem: 'retrieval',
      );

      expect(entry.issueSignature, 'retrieval:zero-results:music');
      expect(entry.severity, IssueSeverity.low);
      expect(entry.impactRadius, IssueImpactRadius.singleUser);
      expect(entry.nextAction, IssueNextAction.fix);
      expect(entry.firstSeenAt, detectedAt);
      expect(ledger.hasSeen('retrieval:zero-results:music'), isTrue);
      expect(ledger.snapshot(), hasLength(1));
    });

    test('does not overwrite first-seen triage entry for repeated signature',
        () {
      final ledger = FirstOccurrenceIssueLedger();
      final first = ledger.recordFirstSeen(
        issueSignature: 'policy:drift:confidence-spike',
        severity: IssueSeverity.high,
        impactRadius: IssueImpactRadius.subsystem,
        detectedAt: DateTime.utc(2026, 2, 20, 8, 0),
        subsystem: 'policy',
      );

      final repeated = ledger.recordFirstSeen(
        issueSignature: 'policy:drift:confidence-spike',
        severity: IssueSeverity.critical,
        impactRadius: IssueImpactRadius.global,
        detectedAt: DateTime.utc(2026, 2, 20, 9, 0),
        subsystem: 'policy',
      );

      expect(identical(first, repeated), isTrue);
      expect(repeated.severity, IssueSeverity.high);
      expect(repeated.impactRadius, IssueImpactRadius.subsystem);
      expect(repeated.nextAction, IssueNextAction.experiment);
      expect(ledger.snapshot(), hasLength(1));
    });

    test('escalates triage action for critical or global impact signatures',
        () {
      expect(
        FirstOccurrenceIssueLedger.determineNextAction(
          severity: IssueSeverity.critical,
          impactRadius: IssueImpactRadius.singleUser,
        ),
        IssueNextAction.escalate,
      );

      expect(
        FirstOccurrenceIssueLedger.determineNextAction(
          severity: IssueSeverity.medium,
          impactRadius: IssueImpactRadius.global,
        ),
        IssueNextAction.escalate,
      );
    });
  });

  group('FirstOccurrenceIssueEntry', () {
    test('round-trips via JSON', () {
      final entry = FirstOccurrenceIssueEntry(
        issueSignature: 'learning:oscillation:model-v2',
        severity: IssueSeverity.medium,
        impactRadius: IssueImpactRadius.cohort,
        nextAction: IssueNextAction.experiment,
        firstSeenAt: DateTime.utc(2026, 2, 20, 12),
        subsystem: 'learning',
        metadata: const {'attempt': 1},
      );

      final decoded = FirstOccurrenceIssueEntry.fromJson(entry.toJson());

      expect(decoded.issueSignature, entry.issueSignature);
      expect(decoded.severity, entry.severity);
      expect(decoded.impactRadius, entry.impactRadius);
      expect(decoded.nextAction, entry.nextAction);
      expect(decoded.firstSeenAt, entry.firstSeenAt);
      expect(decoded.subsystem, entry.subsystem);
      expect(decoded.metadata['attempt'], 1);
    });

    test('throws format exception for unknown enum values', () {
      expect(
        () => FirstOccurrenceIssueEntry.fromJson({
          'issue_signature': 'x',
          'severity': 'unknown',
          'impact_radius': 'singleUser',
          'next_action': 'fix',
          'first_seen_at': DateTime.utc(2026, 2, 20).toIso8601String(),
          'subsystem': 'x',
        }),
        throwsFormatException,
      );
    });
  });
}
