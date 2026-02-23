enum DwellIssueClass {
  retrievalQuality,
  rankingRegression,
  safetyViolation,
  policyDrift,
  infraReliability,
  unknown,
}

enum ForcedEscalationPath {
  fix,
  experiment,
  escalate,
}

class DwellBudgetPolicy {
  final DwellIssueClass issueClass;
  final int maxActiveAttempts;
  final Duration maxWallClockDwell;
  final ForcedEscalationPath forcedEscalationPath;

  const DwellBudgetPolicy({
    required this.issueClass,
    required this.maxActiveAttempts,
    required this.maxWallClockDwell,
    required this.forcedEscalationPath,
  });

  bool get isValid {
    if (maxActiveAttempts < 1) return false;
    if (maxWallClockDwell.inSeconds < 1) return false;
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'issue_class': issueClass.name,
      'max_active_attempts': maxActiveAttempts,
      'max_wall_clock_dwell_seconds': maxWallClockDwell.inSeconds,
      'forced_escalation_path': forcedEscalationPath.name,
    };
  }

  factory DwellBudgetPolicy.fromJson(Map<String, dynamic> json) {
    T parse<T extends Enum>(List<T> values, Object? raw, String field) {
      final name = '$raw';
      return values.firstWhere(
        (value) => value.name == name,
        orElse: () => throw FormatException('Unknown $field "$name".'),
      );
    }

    return DwellBudgetPolicy(
      issueClass:
          parse(DwellIssueClass.values, json['issue_class'], 'issue_class'),
      maxActiveAttempts: json['max_active_attempts'] as int? ?? 0,
      maxWallClockDwell: Duration(
        seconds: json['max_wall_clock_dwell_seconds'] as int? ?? 0,
      ),
      forcedEscalationPath: parse(
        ForcedEscalationPath.values,
        json['forced_escalation_path'],
        'forced_escalation_path',
      ),
    );
  }
}

class DwellBudgetDecision {
  final bool attemptsExceeded;
  final bool wallClockExceeded;
  final bool shouldEscalate;
  final ForcedEscalationPath? escalationPath;

  const DwellBudgetDecision({
    required this.attemptsExceeded,
    required this.wallClockExceeded,
    required this.shouldEscalate,
    required this.escalationPath,
  });
}

class DwellBudgetPolicyRegistry {
  final Map<DwellIssueClass, DwellBudgetPolicy> _policyByIssueClass;

  DwellBudgetPolicyRegistry({
    Map<DwellIssueClass, DwellBudgetPolicy>? seedPolicies,
  }) : _policyByIssueClass = {...?seedPolicies};

  void upsert(DwellBudgetPolicy policy) {
    if (!policy.isValid) {
      throw ArgumentError.value(
          policy, 'policy', 'Invalid dwell budget policy.');
    }
    _policyByIssueClass[policy.issueClass] = policy;
  }

  DwellBudgetPolicy? lookup(DwellIssueClass issueClass) {
    return _policyByIssueClass[issueClass];
  }

  DwellBudgetDecision evaluate({
    required DwellIssueClass issueClass,
    required int activeAttempts,
    required DateTime issueOpenedAt,
    required DateTime now,
  }) {
    final policy = _policyByIssueClass[issueClass];
    if (policy == null) {
      return const DwellBudgetDecision(
        attemptsExceeded: false,
        wallClockExceeded: false,
        shouldEscalate: false,
        escalationPath: null,
      );
    }

    final attemptsExceeded = activeAttempts >= policy.maxActiveAttempts;
    final wallClockExceeded = now.toUtc().difference(issueOpenedAt.toUtc()) >=
        policy.maxWallClockDwell;
    final shouldEscalate = attemptsExceeded || wallClockExceeded;

    return DwellBudgetDecision(
      attemptsExceeded: attemptsExceeded,
      wallClockExceeded: wallClockExceeded,
      shouldEscalate: shouldEscalate,
      escalationPath: shouldEscalate ? policy.forcedEscalationPath : null,
    );
  }
}
