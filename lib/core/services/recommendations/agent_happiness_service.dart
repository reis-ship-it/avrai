import 'dart:convert';
import 'dart:developer' as developer;

import 'package:avrai/core/services/ai_infrastructure/kernel_governance_gate.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai/core/services/ai_infrastructure/model_safety_supervisor.dart';

class AgentHappinessSnapshot {
  final double score; // 0..1
  final int count;
  final int p50; // 0..100
  final int p95; // 0..100

  const AgentHappinessSnapshot({
    required this.score,
    required this.count,
    required this.p50,
    required this.p95,
  });
}

/// Records and summarizes “agent happiness” signals.
///
/// This is NOT about controlling the user — it is a safety/quality signal to:
/// - prioritize on-device training when happiness is trending down
/// - prevent upstream/cloud-driven changes from degrading the local agent
class AgentHappinessService {
  static const String _logName = 'AgentHappinessService';
  static const String _prefsKey = 'agent_happiness_signals_v1';
  static const int _maxSignals = 200;

  final SharedPreferencesCompat _prefs;
  final KernelGovernanceGate? _kernelGovernanceGate;

  AgentHappinessService({
    required SharedPreferencesCompat prefs,
    KernelGovernanceGate? kernelGovernanceGate,
  })  : _prefs = prefs,
        _kernelGovernanceGate = kernelGovernanceGate;

  Future<void> recordSignal({
    required String source, // e.g. "chat_rating", "ai2ai_pleasure"
    required double score, // 0..1
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final correlationId =
          'ahs_signal_${DateTime.now().toUtc().microsecondsSinceEpoch}';
      final gateDecision = await _evaluateGovernance(
        KernelGovernanceRequest(
          action: KernelGovernanceAction.happinessSignalIngest,
          correlationId: correlationId,
          metadata: <String, dynamic>{
            'source': source,
            'raw_score': score,
            if (metadata != null) 'meta': metadata,
          },
        ),
      );
      if (!gateDecision.servingAllowed) {
        developer.log(
          'Blocked happiness signal ingest by kernel governance: '
          '${gateDecision.reasonCodes.join(",")} decision_id=${gateDecision.decisionId} corr=$correlationId',
          name: _logName,
        );
        return;
      }

      final now = DateTime.now().toUtc();
      final entry = <String, dynamic>{
        'ts': now.toIso8601String(),
        'source': source,
        'score': score.clamp(0.0, 1.0),
        'governance_decision_id': gateDecision.decisionId,
        'governance_correlation_id': correlationId,
        if (metadata != null) 'meta': metadata,
      };

      final existing = _prefs.getStringList(_prefsKey) ?? const <String>[];
      final next = <String>[...existing, jsonEncode(entry)];
      final capped = next.length <= _maxSignals
          ? next
          : next.sublist(next.length - _maxSignals);
      await _prefs.setStringList(_prefsKey, capped);

      // After recording, evaluate any in-progress rollout candidates and
      // rollback if happiness dropped materially.
      try {
        await ModelSafetySupervisor(
          prefs: _prefs,
          kernelGovernanceGate: _kernelGovernanceGate,
        ).evaluateAndRollbackIfNeeded();
      } catch (_) {
        // Ignore.
      }
    } catch (e, st) {
      developer.log(
        'Failed to record happiness signal',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  AgentHappinessSnapshot getSnapshot() {
    try {
      final list = _prefs.getStringList(_prefsKey) ?? const <String>[];
      final scores = <double>[];
      for (final s in list) {
        try {
          final m = jsonDecode(s) as Map<String, dynamic>;
          final v = (m['score'] as num?)?.toDouble();
          if (v == null) continue;
          scores.add(v.clamp(0.0, 1.0));
        } catch (_) {
          // skip bad entries
        }
      }

      if (scores.isEmpty) {
        return const AgentHappinessSnapshot(
            score: 0.5, count: 0, p50: 50, p95: 50);
      }

      // Average score (simple baseline).
      final avg = scores.reduce((a, b) => a + b) / scores.length;

      // p50/p95 in 0..100 space for UI friendliness.
      final sorted = List<double>.from(scores)..sort();
      int pick(double q) {
        final idx =
            ((sorted.length - 1) * q).round().clamp(0, sorted.length - 1);
        return (sorted[idx] * 100).round();
      }

      return AgentHappinessSnapshot(
        score: avg.clamp(0.0, 1.0),
        count: scores.length,
        p50: pick(0.50),
        p95: pick(0.95),
      );
    } catch (_) {
      return const AgentHappinessSnapshot(
          score: 0.5, count: 0, p50: 50, p95: 50);
    }
  }

  Future<KernelGovernanceDecision> _evaluateGovernance(
    KernelGovernanceRequest request,
  ) async {
    if (_kernelGovernanceGate == null) {
      return KernelGovernanceDecision(
        decisionId: 'kgd_none',
        mode: KernelGovernanceMode.shadow,
        wouldAllow: true,
        servingAllowed: true,
        shadowBypassApplied: false,
        reasonCodes: const <String>['no_kernel_gate_configured'],
        policyVersion: 'none',
        timestamp: DateTime.now().toUtc(),
        correlationId: request.correlationId,
      );
    }
    return _kernelGovernanceGate.evaluate(request);
  }
}
