// Markov Transition Store
//
// Phase 1.5E: Beta Markov Engagement Predictor (Bridge to Phase 5)
//
// On-device SharedPreferences persistence for per-agent Markov transition counts.
// Blends synthetic swarm-seeded priors (city-stratified) with real user observations.
// The synthetic prior starts at weight 100 (equivalent to 100 synthetic observations)
// and decays in relative influence as real observations accumulate.
//
// See: MASTER_PLAN.md Phase 1.5E, SwarmPriorLoader

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import 'engagement_phase_predictor.dart';
import 'swarm_prior_loader.dart';

/// Stores and retrieves Markov transition counts for engagement phase prediction.
///
/// Storage key per agent: `markov_transitions_{agentId}`
/// Schema: JSON Map<String, int> where key = "fromPhase:toPhase"
///
/// Blending: total_count[from][to] = real_count[from][to] + prior_count[from][to]
/// where prior_count comes from [SwarmPriorLoader] city-stratified priors.
/// Prior weight = 100 synthetic observations per row. Decays naturally as real
/// data accumulates (after 200 real observations, prior is < 33% of weight).
class MarkovTransitionStore {
  static const String _logName = 'MarkovTransitionStore';
  static const String _keyPrefix = 'markov_transitions_';
  static const String _cityKeyPrefix = 'markov_city_';

  // The synthetic prior weight per phase row (equivalent to N synthetic observations)
  static const int _syntheticPriorWeight = 100;

  final SharedPreferences _prefs;
  final SwarmPriorLoader _priorLoader;

  MarkovTransitionStore({
    required SharedPreferences prefs,
    required SwarmPriorLoader priorLoader,
  })  : _prefs = prefs,
        _priorLoader = priorLoader;

  /// Records a phase transition for a specific agent.
  ///
  /// Increments the real observation count for the (from, to) transition.
  /// Also records the city association on first call so the right prior is loaded.
  Future<void> recordTransition(
    UserEngagementPhase from,
    UserEngagementPhase to,
    String agentId, {
    String? city,
  }) async {
    try {
      final key = '$_keyPrefix$agentId';
      final raw = _prefs.getString(key);
      final counts = raw != null
          ? Map<String, int>.from(jsonDecode(raw) as Map)
          : <String, int>{};

      final transitionKey = '${from.name}:${to.name}';
      counts[transitionKey] = (counts[transitionKey] ?? 0) + 1;

      await _prefs.setString(key, jsonEncode(counts));

      // Persist city association for prior selection (first write wins)
      if (city != null) {
        final cityKey = '$_cityKeyPrefix$agentId';
        if (_prefs.getString(cityKey) == null) {
          await _prefs.setString(cityKey, city);
        }
      }

      developer.log(
        'Recorded transition ${from.name}→${to.name} for agent $agentId '
        '(total for key: ${counts[transitionKey]})',
        name: _logName,
      );
    } catch (e, st) {
      developer.log(
        'Error recording transition: $e',
        error: e,
        stackTrace: st,
        name: _logName,
      );
    }
  }

  /// Returns a blended transition probability matrix for a given agent.
  ///
  /// For each (from, to) pair:
  ///   probability = (real_count + prior_count) / (total_real_from + prior_weight)
  ///
  /// Falls back to pure population prior when no real observations exist.
  Future<Map<UserEngagementPhase, Map<UserEngagementPhase, double>>>
      getTransitionMatrix(String agentId) async {
    final realCounts = await _getRealCounts(agentId);
    final city = _prefs.getString('$_cityKeyPrefix$agentId');
    final prior = _priorLoader.getPriorForCity(city ?? 'default');

    final matrix = <UserEngagementPhase, Map<UserEngagementPhase, double>>{};

    for (final from in UserEngagementPhase.values) {
      final row = <UserEngagementPhase, double>{};
      double rowTotal = _syntheticPriorWeight.toDouble();

      // Add real observation counts to the denominator
      for (final to in UserEngagementPhase.values) {
        final realCount = realCounts['${from.name}:${to.name}'] ?? 0;
        rowTotal += realCount;
      }

      double rowSum = 0.0;
      for (final to in UserEngagementPhase.values) {
        final realCount = realCounts['${from.name}:${to.name}'] ?? 0;
        final priorCount = prior[from]?[to] ?? 0;
        row[to] = (realCount + priorCount) / rowTotal;
        rowSum += row[to]!;
      }

      // Normalize to handle floating point drift
      if (rowSum > 0) {
        for (final to in row.keys) {
          row[to] = row[to]! / rowSum;
        }
      } else {
        // Uniform fallback if somehow all zeros
        final uniform = 1.0 / UserEngagementPhase.values.length;
        for (final to in UserEngagementPhase.values) {
          row[to] = uniform;
        }
      }

      matrix[from] = row;
    }

    return matrix;
  }

  /// Returns the raw real observation counts for an agent (unsorted).
  Future<Map<String, int>> _getRealCounts(String agentId) async {
    final raw = _prefs.getString('$_keyPrefix$agentId');
    if (raw == null) return {};
    try {
      return Map<String, int>.from(jsonDecode(raw) as Map);
    } catch (e) {
      developer.log('Error parsing counts for $agentId: $e', name: _logName);
      return {};
    }
  }

  /// Total real observations for an agent (across all transition types).
  /// Used for cold-start quality metrics (Phase 1.5E.10).
  Future<int> totalRealObservations(String agentId) async {
    final counts = await _getRealCounts(agentId);
    return counts.values.fold<int>(0, (sum, v) => sum + v);
  }
}
