// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:avrai/core/ml/model_version_registry.dart';
import 'package:avrai/core/services/ai_infrastructure/kernel_governance_gate.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai/core/services/local_llm/model_pack_manager.dart';

/// Guards model rollouts using user-facing quality signals ("agent happiness").
///
/// This is the “protect from above” layer:
/// - we can try new model versions
/// - but we automatically revert if the agent’s happiness drops meaningfully
class ModelSafetySupervisor {
  static const String _logName = 'ModelSafetySupervisor';

  static const String _prefsKeyHappinessSignals = 'agent_happiness_signals_v1';
  static const String _prefsKeyRollbackEvents =
      'model_rollout_rollback_events_v1';
  static const int _maxRollbackEvents = 50;

  // Conservative defaults (avoid flapping on sparse feedback).
  static const int _baselineWindow = 20;
  static const int _minBaselineSamples = 8;
  static const int _minPostSamples = 12;
  static const double _rollbackDelta = 0.12; // 12-point drop (0..1 scale)

  final SharedPreferencesCompat _prefs;
  final KernelGovernanceGate? _kernelGovernanceGate;

  ModelSafetySupervisor({
    required SharedPreferencesCompat prefs,
    KernelGovernanceGate? kernelGovernanceGate,
  })  : _prefs = prefs,
        _kernelGovernanceGate = kernelGovernanceGate;

  static String _candidateKeyForType(String modelType) {
    // Keep keys simple and stable.
    final safe = modelType.replaceAll(RegExp(r'[^a-zA-Z0-9_]+'), '_');
    return 'model_rollout_candidate_${safe}_v1';
  }

  Future<void> startRolloutCandidate({
    required String modelType, // 'calling_score' | 'outcome'
    required String fromVersion,
    required String toVersion,
  }) async {
    // Only track one candidate at a time (simple baseline).
    try {
      final correlationId =
          'mss_rollout_${DateTime.now().toUtc().microsecondsSinceEpoch}';
      final gateDecision = await _evaluateGovernance(
        KernelGovernanceRequest(
          action: KernelGovernanceAction.rolloutCandidateStart,
          modelType: modelType,
          fromVersion: fromVersion,
          toVersion: toVersion,
          correlationId: correlationId,
        ),
      );
      if (!gateDecision.servingAllowed) {
        developer.log(
          'Blocked rollout candidate start for $modelType: '
          '${gateDecision.reasonCodes.join(",")} decision_id=${gateDecision.decisionId} corr=$correlationId',
          name: _logName,
        );
        return;
      }

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final baseline = _computeBaselineAvg(nowMs: nowMs);

      final candidate = <String, dynamic>{
        'model_type': modelType,
        'from_version': fromVersion,
        'to_version': toVersion,
        'started_at_ms': nowMs,
        'baseline_avg': baseline.avg,
        'baseline_n': baseline.count,
        'min_post_n': _minPostSamples,
        'rollback_delta': _rollbackDelta,
      };
      await _prefs.setString(
          _candidateKeyForType(modelType), jsonEncode(candidate));

      developer.log(
        'Rollout candidate started: $modelType $fromVersion → $toVersion '
        '(baseline=${baseline.avg.toStringAsFixed(3)}, n=${baseline.count}) '
        'decision_id=${gateDecision.decisionId} corr=$correlationId',
        name: _logName,
      );
    } catch (e, st) {
      developer.log(
        'Failed to start rollout candidate',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Evaluate current rollout candidate (if any) and rollback if needed.
  Future<void> evaluateAndRollbackIfNeeded() async {
    // Evaluate known rollout types (kept small on purpose).
    // Note: this is called frequently (on happiness record), so keep it cheap.
    for (final modelType in const <String>[
      'calling_score',
      'outcome',
      'chat_local_llm',
    ]) {
      await _evaluateOne(modelType: modelType);
    }
  }

  Future<void> _evaluateOne({required String modelType}) async {
    try {
      final raw = _prefs.getString(_candidateKeyForType(modelType));
      if (raw == null || raw.isEmpty) return;

      final candidate = jsonDecode(raw) as Map<String, dynamic>;
      final fromVersion = (candidate['from_version'] as String?) ?? '';
      final toVersion = (candidate['to_version'] as String?) ?? '';
      final startedAtMs = (candidate['started_at_ms'] as num?)?.toInt();
      final baselineAvg = (candidate['baseline_avg'] as num?)?.toDouble();
      final baselineN = (candidate['baseline_n'] as num?)?.toInt() ?? 0;
      final minPostN =
          (candidate['min_post_n'] as num?)?.toInt() ?? _minPostSamples;
      final rollbackDelta =
          (candidate['rollback_delta'] as num?)?.toDouble() ?? _rollbackDelta;

      if (modelType.isEmpty ||
          fromVersion.isEmpty ||
          toVersion.isEmpty ||
          startedAtMs == null ||
          baselineAvg == null) {
        await _prefs.remove(_candidateKeyForType(modelType));
        return;
      }

      // Only evaluate if the candidate is still active.
      final current = switch (modelType) {
        'calling_score' => ModelVersionRegistry.activeCallingScoreVersion,
        'outcome' => ModelVersionRegistry.activeOutcomeVersion,
        'chat_local_llm' =>
          _prefs.getString(LocalLlmModelPackManager.prefsKeyActiveModelId) ??
              '',
        _ => '',
      };
      if (current != toVersion) {
        // Candidate no longer active (manual change); clear to avoid surprises.
        await _prefs.remove(_candidateKeyForType(modelType));
        return;
      }

      final post = _computePostAvg(startedAtMs: startedAtMs);
      if (baselineN < _minBaselineSamples || post.count < minPostN) {
        return;
      }

      final drop = baselineAvg - post.avg;
      if (drop >= rollbackDelta) {
        final correlationId =
            'mss_rollback_${DateTime.now().toUtc().microsecondsSinceEpoch}';
        final gateDecision = await _evaluateGovernance(
          KernelGovernanceRequest(
            action: KernelGovernanceAction.modelRollback,
            modelType: modelType,
            fromVersion: toVersion,
            toVersion: fromVersion,
            correlationId: correlationId,
            metadata: <String, dynamic>{
              'drop': drop,
              'baseline_n': baselineN,
              'post_n': post.count,
            },
          ),
        );
        if (!gateDecision.servingAllowed) {
          developer.log(
            'Blocked rollback for $modelType by kernel governance: '
            '${gateDecision.reasonCodes.join(",")} decision_id=${gateDecision.decisionId} corr=$correlationId',
            name: _logName,
          );
          return;
        }

        // Rollback immediately.
        final ok = switch (modelType) {
          'calling_score' =>
            ModelVersionRegistry.setActiveCallingScoreVersion(fromVersion),
          'outcome' =>
            ModelVersionRegistry.setActiveOutcomeVersion(fromVersion),
          'chat_local_llm' => true,
          _ => false,
        };
        if (modelType == 'chat_local_llm') {
          // Local model packs keep explicit last-good pointers; prefer those.
          await LocalLlmModelPackManager().rollbackToLastGoodIfPresent();
        }
        if (ok) {
          await _recordRollbackEvent(
            modelType: modelType,
            fromVersion: fromVersion,
            toVersion: toVersion,
            baselineAvg: baselineAvg,
            baselineN: baselineN,
            postAvg: post.avg,
            postN: post.count,
            drop: drop,
            governanceDecisionId: gateDecision.decisionId,
            governanceCorrelationId: correlationId,
          );
        }

        await _prefs.remove(_candidateKeyForType(modelType));
        developer.log(
          'Rolled back $modelType $toVersion → $fromVersion (drop=${drop.toStringAsFixed(3)}) '
          'decision_id=${gateDecision.decisionId} corr=$correlationId',
          name: _logName,
        );
      }
    } catch (e, st) {
      developer.log(
        'Rollout evaluation failed',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Lightweight list of recent rollback events for UI/debugging.
  List<Map<String, dynamic>> getRollbackEvents() {
    final list =
        _prefs.getStringList(_prefsKeyRollbackEvents) ?? const <String>[];
    final out = <Map<String, dynamic>>[];
    for (final s in list) {
      try {
        out.add(jsonDecode(s) as Map<String, dynamic>);
      } catch (_) {
        // skip
      }
    }
    return out;
  }

  _Avg _computeBaselineAvg({required int nowMs}) {
    // Baseline = avg of last N signals before candidate start.
    final entries = _readSignals();
    final scores = <double>[];
    for (int i = entries.length - 1; i >= 0; i--) {
      final e = entries[i];
      final ts = e.tsMs;
      if (ts == null || ts >= nowMs) continue;
      final v = e.score;
      if (v == null) continue;
      scores.add(v);
      if (scores.length >= _baselineWindow) break;
    }
    if (scores.isEmpty) return const _Avg(avg: 0.5, count: 0);
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    return _Avg(avg: avg.clamp(0.0, 1.0), count: scores.length);
  }

  _Avg _computePostAvg({required int startedAtMs}) {
    final entries = _readSignals();
    final scores = <double>[];
    for (final e in entries) {
      final ts = e.tsMs;
      if (ts == null || ts < startedAtMs) continue;
      final v = e.score;
      if (v == null) continue;
      scores.add(v);
    }
    if (scores.isEmpty) return const _Avg(avg: 0.5, count: 0);
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    return _Avg(avg: avg.clamp(0.0, 1.0), count: scores.length);
  }

  List<_SignalEntry> _readSignals() {
    final list =
        _prefs.getStringList(_prefsKeyHappinessSignals) ?? const <String>[];
    final out = <_SignalEntry>[];
    for (final s in list) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        final tsStr = m['ts'] as String?;
        final ts = tsStr != null ? DateTime.tryParse(tsStr) : null;
        final v = (m['score'] as num?)?.toDouble();
        out.add(
          _SignalEntry(
            tsMs: ts?.toUtc().millisecondsSinceEpoch,
            score: v?.clamp(0.0, 1.0),
          ),
        );
      } catch (_) {
        // skip
      }
    }
    return out;
  }

  Future<void> _recordRollbackEvent({
    required String modelType,
    required String fromVersion,
    required String toVersion,
    required double baselineAvg,
    required int baselineN,
    required double postAvg,
    required int postN,
    required double drop,
    String? governanceDecisionId,
    String? governanceCorrelationId,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final entry = <String, dynamic>{
      'ts': now,
      'model_type': modelType,
      'from_version': fromVersion,
      'to_version': toVersion,
      'baseline_avg': baselineAvg,
      'baseline_n': baselineN,
      'post_avg': postAvg,
      'post_n': postN,
      'drop': drop,
      if (governanceDecisionId != null)
        'governance_decision_id': governanceDecisionId,
      if (governanceCorrelationId != null)
        'governance_correlation_id': governanceCorrelationId,
    };

    final existing =
        _prefs.getStringList(_prefsKeyRollbackEvents) ?? const <String>[];
    final next = <String>[jsonEncode(entry), ...existing];
    final capped = next.length <= _maxRollbackEvents
        ? next
        : next.sublist(0, _maxRollbackEvents);
    await _prefs.setStringList(_prefsKeyRollbackEvents, capped);
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

class _Avg {
  final double avg;
  final int count;
  const _Avg({required this.avg, required this.count});
}

class _SignalEntry {
  final int? tsMs;
  final double? score;
  const _SignalEntry({required this.tsMs, required this.score});
}
