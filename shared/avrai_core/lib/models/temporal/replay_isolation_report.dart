class ReplayIsolationReport {
  const ReplayIsolationReport({
    required this.environmentId,
    required this.passed,
    required this.violations,
    required this.policySnapshot,
    this.notes = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String environmentId;
  final bool passed;
  final List<String> violations;
  final Map<String, String> policySnapshot;
  final List<String> notes;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'passed': passed,
      'violations': violations,
      'policySnapshot': policySnapshot,
      'notes': notes,
      'metadata': metadata,
    };
  }

  factory ReplayIsolationReport.fromJson(Map<String, dynamic> json) {
    return ReplayIsolationReport(
      environmentId: json['environmentId'] as String? ?? '',
      passed: json['passed'] as bool? ?? false,
      violations: (json['violations'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      policySnapshot: (json['policySnapshot'] as Map?)
              ?.map((key, value) => MapEntry(key.toString(), value.toString())) ??
          const <String, String>{},
      notes: (json['notes'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
