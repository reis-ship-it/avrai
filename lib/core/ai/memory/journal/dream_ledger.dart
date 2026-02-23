enum DreamModelFamily {
  realityModel,
  universeModel,
  worldModel,
}

class DreamLedgerEntry {
  final String dreamId;
  final DreamModelFamily modelFamily;
  final List<String> assumptions;
  final String simulatorVersion;
  final List<String> hypothesisRefs;
  final Map<String, double> predictedDeltas;
  final String falsificationPlanId;
  final DateTime createdAt;

  const DreamLedgerEntry({
    required this.dreamId,
    required this.modelFamily,
    required this.assumptions,
    required this.simulatorVersion,
    required this.hypothesisRefs,
    required this.predictedDeltas,
    required this.falsificationPlanId,
    required this.createdAt,
  });

  bool get isValid {
    if (dreamId.trim().isEmpty) return false;
    if (assumptions.isEmpty) return false;
    if (simulatorVersion.trim().isEmpty) return false;
    if (hypothesisRefs.isEmpty) return false;
    if (predictedDeltas.isEmpty) return false;
    if (falsificationPlanId.trim().isEmpty) return false;
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'dream_id': dreamId,
      'model_family': modelFamily.name,
      'assumptions': assumptions,
      'simulator_version': simulatorVersion,
      'hypothesis_refs': hypothesisRefs,
      'predicted_deltas': predictedDeltas,
      'falsification_plan_id': falsificationPlanId,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  factory DreamLedgerEntry.fromJson(Map<String, dynamic> json) {
    final modelFamilyName = '${json['model_family']}';
    final modelFamily = DreamModelFamily.values.firstWhere(
      (value) => value.name == modelFamilyName,
      orElse: () => throw FormatException(
        'Unknown model_family "$modelFamilyName".',
      ),
    );

    final rawDeltas = Map<String, dynamic>.from(
      json['predicted_deltas'] as Map? ?? const <String, dynamic>{},
    );
    final parsedDeltas = <String, double>{};
    for (final entry in rawDeltas.entries) {
      final value = entry.value;
      if (value is! num) {
        throw FormatException(
          'predicted_deltas["${entry.key}"] must be numeric.',
        );
      }
      parsedDeltas[entry.key] = value.toDouble();
    }

    return DreamLedgerEntry(
      dreamId: json['dream_id'] as String? ?? '',
      modelFamily: modelFamily,
      assumptions: (json['assumptions'] as List? ?? const [])
          .map((item) => '$item')
          .toList(growable: false),
      simulatorVersion: json['simulator_version'] as String? ?? '',
      hypothesisRefs: (json['hypothesis_refs'] as List? ?? const [])
          .map((item) => '$item')
          .toList(growable: false),
      predictedDeltas: parsedDeltas,
      falsificationPlanId: json['falsification_plan_id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class DreamLedger {
  final List<DreamLedgerEntry> _entries = <DreamLedgerEntry>[];

  void append(DreamLedgerEntry entry) {
    if (!entry.isValid) {
      throw ArgumentError.value(
          entry, 'entry', 'Dream ledger entry is invalid.');
    }
    _entries.add(entry);
  }

  List<DreamLedgerEntry> byModelFamily(DreamModelFamily family) {
    return _entries.where((entry) => entry.modelFamily == family).toList();
  }

  DreamLedgerEntry? byDreamId(String dreamId) {
    for (final entry in _entries) {
      if (entry.dreamId == dreamId) {
        return entry;
      }
    }
    return null;
  }

  List<DreamLedgerEntry> snapshot() =>
      List<DreamLedgerEntry>.unmodifiable(_entries);
}
