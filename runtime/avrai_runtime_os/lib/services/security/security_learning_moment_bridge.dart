import 'dart:convert';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/security/security_autonomy_impact_policy.dart';

class SecurityAutonomyRiskSignal {
  const SecurityAutonomyRiskSignal({
    required this.id,
    required this.runId,
    required this.truthScope,
    required this.disposition,
    required this.riskScore,
    required this.budgetMultiplier,
    required this.freezePromotion,
    required this.createdAt,
    required this.summary,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String runId;
  final TruthScopeDescriptor truthScope;
  final SecurityInterventionDisposition disposition;
  final double riskScore;
  final double budgetMultiplier;
  final bool freezePromotion;
  final DateTime createdAt;
  final String summary;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'runId': runId,
        'truthScope': truthScope.toJson(),
        'disposition': disposition.name,
        'riskScore': riskScore,
        'budgetMultiplier': budgetMultiplier,
        'freezePromotion': freezePromotion,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'summary': summary,
        'metadata': metadata,
      };

  factory SecurityAutonomyRiskSignal.fromJson(Map<String, dynamic> json) {
    return SecurityAutonomyRiskSignal(
      id: json['id']?.toString() ?? '',
      runId: json['runId']?.toString() ?? '',
      truthScope: TruthScopeDescriptor.fromJson(
        Map<String, dynamic>.from(
          json['truthScope'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      disposition: SecurityInterventionDisposition.values.firstWhere(
        (entry) => entry.name == json['disposition'],
        orElse: () => SecurityInterventionDisposition.observe,
      ),
      riskScore: (json['riskScore'] as num?)?.toDouble() ?? 0.0,
      budgetMultiplier: (json['budgetMultiplier'] as num?)?.toDouble() ?? 1.0,
      freezePromotion: json['freezePromotion'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
      summary: json['summary']?.toString() ?? '',
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class SecurityLearningMomentBridge {
  SecurityLearningMomentBridge({
    SharedPreferencesCompat? prefs,
    SecurityAutonomyImpactPolicy? impactPolicy,
    DateTime Function()? nowProvider,
  })  : _prefs = prefs,
        _impactPolicy = impactPolicy ?? const SecurityAutonomyImpactPolicy(),
        _nowProvider = nowProvider ?? (() => DateTime.now().toUtc());

  static const String _signalsKey = 'security.autonomy_risk_signals.v1';
  static const int _maxSignals = 128;

  final SharedPreferencesCompat? _prefs;
  final SecurityAutonomyImpactPolicy _impactPolicy;
  final DateTime Function() _nowProvider;

  Future<SecurityAutonomyRiskSignal> recordMoment(
    SecurityLearningMoment moment,
  ) async {
    final impact = _impactPolicy.evaluate(
      disposition: moment.disposition,
      currentEnvironment: GovernedRunEnvironment.shadow,
    );
    final recurrencePenalty = (moment.recurrenceCount * 0.08).clamp(0.0, 0.24);
    final signal = SecurityAutonomyRiskSignal(
      id: 'risk_${moment.id}',
      runId: moment.runId,
      truthScope: moment.truthScope,
      disposition: moment.disposition,
      riskScore:
          (1.0 - impact.budgetMultiplier + recurrencePenalty).clamp(0.0, 1.0),
      budgetMultiplier: impact.budgetMultiplier,
      freezePromotion: impact.freezePromotion,
      createdAt: _nowProvider(),
      summary: moment.summary,
      metadata: <String, dynamic>{
        'moment_id': moment.id,
        'moment_kind': moment.kind.name,
        ...moment.metadata,
      },
    );
    await _writeSignal(signal);
    return signal;
  }

  List<SecurityAutonomyRiskSignal> latestSignals({int limit = 20}) {
    final signals = _readSignals();
    final normalizedLimit = limit.clamp(0, signals.length);
    if (normalizedLimit == 0) {
      return const <SecurityAutonomyRiskSignal>[];
    }
    return signals.take(normalizedLimit).toList(growable: false);
  }

  double budgetMultiplierForScope(TruthScopeDescriptor scope) {
    final matching = _readSignals().where(
      (entry) =>
          entry.truthScope.tenantScope == scope.tenantScope &&
          (entry.truthScope.tenantId ?? '') == (scope.tenantId ?? '') &&
          (entry.truthScope.familyId == scope.familyId ||
              entry.truthScope.sphereId == scope.sphereId),
    );
    if (matching.isEmpty) {
      return 1.0;
    }
    return matching
        .map((entry) => entry.budgetMultiplier)
        .reduce((left, right) => left < right ? left : right);
  }

  bool freezePromotionForScope(TruthScopeDescriptor scope) {
    return _readSignals().any(
      (entry) =>
          entry.freezePromotion &&
          entry.truthScope.tenantScope == scope.tenantScope &&
          (entry.truthScope.tenantId ?? '') == (scope.tenantId ?? '') &&
          (entry.truthScope.familyId == scope.familyId ||
              entry.truthScope.sphereId == scope.sphereId),
    );
  }

  Future<void> _writeSignal(SecurityAutonomyRiskSignal signal) async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    final signals = _readSignals().toList(growable: true);
    signals.removeWhere((entry) => entry.id == signal.id);
    signals.insert(0, signal);
    if (signals.length > _maxSignals) {
      signals.removeRange(_maxSignals, signals.length);
    }
    await prefs.setString(
      _signalsKey,
      jsonEncode(signals.map((entry) => entry.toJson()).toList()),
    );
  }

  List<SecurityAutonomyRiskSignal> _readSignals() {
    final prefs = _prefs;
    if (prefs == null) {
      return const <SecurityAutonomyRiskSignal>[];
    }
    final raw = prefs.getString(_signalsKey);
    if (raw == null || raw.isEmpty) {
      return const <SecurityAutonomyRiskSignal>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <SecurityAutonomyRiskSignal>[];
    }
    return decoded
        .whereType<Map>()
        .map(
          (entry) => SecurityAutonomyRiskSignal.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList(growable: false);
  }
}
