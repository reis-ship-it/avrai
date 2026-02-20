enum PurposeGoal {
  understandHumanCondition,
  testAndProveConvictions,
  learnFromMistakesAndFixes,
  improveUserAndAgentHappiness,
  discoverNewGoalsWithinSafetyBounds,
}

class PurposeKernelSchema {
  static const List<PurposeGoal> requiredInitialGoals = <PurposeGoal>[
    PurposeGoal.understandHumanCondition,
    PurposeGoal.testAndProveConvictions,
    PurposeGoal.learnFromMistakesAndFixes,
    PurposeGoal.improveUserAndAgentHappiness,
    PurposeGoal.discoverNewGoalsWithinSafetyBounds,
  ];

  final String kernelId;
  final String version;
  final List<PurposeGoal> initialGoals;
  final bool safetyBoundedGoalDiscovery;
  final bool legalBoundedGoalDiscovery;
  final DateTime issuedAt;
  final Map<String, Object?> metadata;

  const PurposeKernelSchema({
    required this.kernelId,
    required this.version,
    required this.initialGoals,
    this.safetyBoundedGoalDiscovery = true,
    this.legalBoundedGoalDiscovery = true,
    required this.issuedAt,
    this.metadata = const {},
  });

  bool get isValid {
    if (kernelId.trim().isEmpty) return false;
    if (version.trim().isEmpty) return false;
    if (initialGoals.isEmpty) return false;
    if (initialGoals.toSet().length != initialGoals.length) return false;
    for (final goal in requiredInitialGoals) {
      if (!initialGoals.contains(goal)) return false;
    }
    if (!safetyBoundedGoalDiscovery) return false;
    if (!legalBoundedGoalDiscovery) return false;
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'kernel_id': kernelId,
      'version': version,
      'initial_goals': initialGoals.map((g) => g.name).toList(growable: false),
      'safety_bounded_goal_discovery': safetyBoundedGoalDiscovery,
      'legal_bounded_goal_discovery': legalBoundedGoalDiscovery,
      'issued_at': issuedAt.toUtc().toIso8601String(),
      'metadata': metadata,
    };
  }

  factory PurposeKernelSchema.fromJson(Map<String, dynamic> json) {
    final rawGoals = (json['initial_goals'] as List? ?? const <Object?>[])
        .map((e) => '$e')
        .toList(growable: false);

    final parsedGoals = rawGoals
        .map((name) => PurposeGoal.values.firstWhere(
              (goal) => goal.name == name,
              orElse: () => throw FormatException(
                'Unknown purpose goal "$name".',
              ),
            ))
        .toList(growable: false);

    return PurposeKernelSchema(
      kernelId: json['kernel_id'] as String? ?? '',
      version: json['version'] as String? ?? '',
      initialGoals: parsedGoals,
      safetyBoundedGoalDiscovery:
          json['safety_bounded_goal_discovery'] as bool? ?? true,
      legalBoundedGoalDiscovery:
          json['legal_bounded_goal_discovery'] as bool? ?? true,
      issuedAt: DateTime.tryParse(json['issued_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      metadata: Map<String, Object?>.from(
        json['metadata'] as Map? ?? const <String, Object?>{},
      ),
    );
  }
}
