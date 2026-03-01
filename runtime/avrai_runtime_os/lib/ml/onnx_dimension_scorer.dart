// ONNX Dimension Scorer for Phase 11: User-AI Interaction Update
// Provides fast, privacy-sensitive dimension scoring using ONNX models

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_dimension_mapper.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/ai2ai/embedding_delta_collector.dart';

/// Scores personality dimensions from onboarding inputs
/// Uses ONNX model for fast, privacy-sensitive scoring
class OnnxDimensionScorer {
  static const String _logName = 'OnnxDimensionScorer';

  // --------------------------------------------------------------------------
  // Federated personalization overlay (workable now, real ONNX weight updates later)
  // --------------------------------------------------------------------------
  static const String _biasStorageKey = 'onnx_dimension_scorer_bias_v1';
  static const double _maxAbsBias = 0.20; // max additive shift per dimension
  static const double _deltaToBiasRate =
      0.15; // scales avg delta into bias update

  bool _biasLoaded = false;
  DateTime? _biasUpdatedAt;
  final Map<String, double> _biasByDimension = <String, double>{};

  // TODO: Add ONNX runtime instance when ONNX backend is fully integrated
  // For now, this is a placeholder that provides rule-based scoring
  bool _isInitialized = false;

  /// Initialize the ONNX scorer
  Future<void> initialize() async {
    // TODO: Load ONNX model when ONNX backend is available
    // For now, mark as initialized with rule-based fallback
    await _loadBiasFromStorageIfPossible();
    _isInitialized = true;
    developer.log(
      'ONNX Dimension Scorer initialized (using rule-based fallback)',
      name: _logName,
    );
  }

  /// Scores personality dimensions from input data
  ///
  /// **Parameters:**
  /// - `input`: Map containing onboarding data, places, social graph, etc.
  ///
  /// **Returns:**
  /// Map of dimension names to scores (0.0-1.0)
  Future<Map<String, double>> scoreDimensions(
      Map<String, dynamic> input) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // TODO: Use ONNX model for scoring when available
      // For now, use rule-based scoring as placeholder
      final base = _ruleBasedScoring(input);
      return _applyPersonalizationOverlay(base);
    } catch (e) {
      developer.log(
        'Error scoring dimensions: $e',
        name: _logName,
        error: e,
      );
      // Return default scores on error
      return _applyPersonalizationOverlay(_getDefaultScores());
    }
  }

  /// Rule-based scoring (fallback when ONNX model not available)
  Map<String, double> _ruleBasedScoring(Map<String, dynamic> input) {
    // Start from canonical defaults for all 12 dimensions.
    final scores = _getDefaultScores();

    // Extract input data
    final onboardingData =
        input['onboarding_data'] as Map<String, dynamic>? ?? {};
    final places = input['places'] as List? ?? [];
    final socialGraph = input['social_graph'] as List? ?? [];

    // Device-first source of truth: reuse the onboarding mapper (mirrors PersonalityLearning).
    final mapper = OnboardingDimensionMapper();
    final onboardingInsights = mapper.mapOnboardingToDimensions(onboardingData);
    for (final entry in onboardingInsights.entries) {
      scores[entry.key] = entry.value.clamp(0.0, 1.0);
    }

    // Lightweight additional signals beyond onboarding answers (still on-device).
    if (places.length >= 8) {
      scores['exploration_eagerness'] =
          ((scores['exploration_eagerness'] ?? 0.5) + 0.08).clamp(0.0, 1.0);
      scores['novelty_seeking'] =
          ((scores['novelty_seeking'] ?? 0.5) + 0.06).clamp(0.0, 1.0);
    }

    if (socialGraph.length >= 8) {
      scores['community_orientation'] =
          ((scores['community_orientation'] ?? 0.5) + 0.08).clamp(0.0, 1.0);
      scores['trust_network_reliance'] =
          ((scores['trust_network_reliance'] ?? 0.5) + 0.05).clamp(0.0, 1.0);
    }

    return scores;
  }

  /// Get default dimension scores
  Map<String, double> _getDefaultScores() {
    final scores = <String, double>{};
    for (final d in VibeConstants.coreDimensions) {
      scores[d] = VibeConstants.defaultDimensionValue;
    }
    return scores;
  }

  /// Validate dimension scores for safety
  ///
  /// **Parameters:**
  /// - `scores`: Map of dimension names to scores
  ///
  /// **Returns:**
  /// true if scores are safe (within valid ranges), false otherwise
  bool validateScores(Map<String, double> scores) {
    // Check for extreme values
    for (final entry in scores.entries) {
      final score = entry.value;
      if (score < 0.0 || score > 1.0) {
        developer.log(
          'Invalid score for ${entry.key}: $score (must be 0.0-1.0)',
          name: _logName,
        );
        return false;
      }
    }

    // Check for all-zero or all-one scores (suspicious)
    final allZero = scores.values.every((s) => s == 0.0);
    final allOne = scores.values.every((s) => s == 1.0);

    if (allZero || allOne) {
      developer.log(
        'Suspicious scores detected: all ${allZero ? "zero" : "one"}',
        name: _logName,
      );
      return false;
    }

    return true;
  }

  /// Update ONNX model with federated deltas
  ///
  /// Phase 11 Section 7: Federated Learning Hooks
  /// Applies anonymized embedding deltas from AI2AI connections to the
  /// on-device model for continuous learning.
  ///
  /// [deltas] - List of anonymized embedding deltas from AI2AI connections
  ///
  /// Note: This is a lightweight update (not full retraining).
  /// The deltas are applied incrementally to keep personalization fresh.
  Future<void> updateWithDeltas(List<EmbeddingDelta> deltas) async {
    try {
      developer.log(
        'Updating ONNX model with ${deltas.length} federated deltas',
        name: _logName,
      );

      if (deltas.isEmpty) {
        developer.log('No deltas to apply', name: _logName);
        return;
      }

      if (!_isInitialized) {
        await initialize();
      } else {
        await _loadBiasFromStorageIfPossible();
      }

      // Aggregate deltas by category
      final deltasByCategory = <String, List<EmbeddingDelta>>{};
      for (final delta in deltas) {
        final category = delta.category ?? 'general';
        deltasByCategory.putIfAbsent(category, () => []).add(delta);
      }

      developer.log(
        'Deltas by category: ${deltasByCategory.keys.join(", ")}',
        name: _logName,
      );

      // Calculate average delta per category
      for (final entry in deltasByCategory.entries) {
        final category = entry.key;
        final categoryDeltas = entry.value;

        if (categoryDeltas.isEmpty) continue;

        // Calculate average delta vector
        final avgDelta = _calculateAverageDelta(categoryDeltas);
        final avgMagnitude = _calculateDeltaMagnitude(avgDelta);

        developer.log(
          'Category: $category, avg magnitude: ${avgMagnitude.toStringAsFixed(3)}, deltas: ${categoryDeltas.length}',
          name: _logName,
        );

        // Workable now: apply a bounded personalization overlay (bias) on top of
        // model/rule-based outputs. This keeps "federated learning" real without
        // requiring ONNX weight mutation yet.
        _applyDeltaVectorToBias(avgDelta);
      }

      await _persistBiasToStorageIfPossible();

      developer.log(
        'Federated delta update complete (personalization overlay updated)',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error updating model with deltas: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - delta update failure shouldn't break the app
    }
  }

  /// Calculate average delta vector from multiple deltas
  List<double> _calculateAverageDelta(List<EmbeddingDelta> deltas) {
    if (deltas.isEmpty) return [];

    // Find the maximum length delta
    int maxLength = 0;
    for (final delta in deltas) {
      if (delta.delta.length > maxLength) {
        maxLength = delta.delta.length;
      }
    }

    // Calculate average for each dimension
    final avgDelta = List<double>.filled(maxLength, 0.0);
    for (final delta in deltas) {
      for (int i = 0; i < delta.delta.length && i < maxLength; i++) {
        avgDelta[i] += delta.delta[i];
      }
    }

    // Divide by count to get average
    for (int i = 0; i < avgDelta.length; i++) {
      avgDelta[i] /= deltas.length;
    }

    return avgDelta;
  }

  /// Calculate magnitude of delta vector
  double _calculateDeltaMagnitude(List<double> delta) {
    if (delta.isEmpty) return 0.0;

    double sum = 0.0;
    for (final value in delta) {
      sum += value * value;
    }
    return math.sqrt(sum / delta.length);
  }

  Map<String, double> _applyPersonalizationOverlay(Map<String, double> base) {
    if (!_biasLoaded || _biasByDimension.isEmpty) return base;

    final adjusted = <String, double>{};
    for (final d in VibeConstants.coreDimensions) {
      final v = base[d] ?? VibeConstants.defaultDimensionValue;
      final bias = _biasByDimension[d] ?? 0.0;
      adjusted[d] = (v + bias).clamp(0.0, 1.0);
    }
    return adjusted;
  }

  void _applyDeltaVectorToBias(List<double> avgDelta) {
    if (avgDelta.isEmpty) return;

    for (var i = 0; i < VibeConstants.coreDimensions.length; i++) {
      if (i >= avgDelta.length) break;
      final dim = VibeConstants.coreDimensions[i];
      final raw = avgDelta[i];

      // Scale and bound per update so a single batch can't swing things wildly.
      final update = (raw * _deltaToBiasRate).clamp(-0.05, 0.05);
      final next = ((_biasByDimension[dim] ?? 0.0) + update)
          .clamp(-_maxAbsBias, _maxAbsBias);
      _biasByDimension[dim] = next;
    }

    _biasLoaded = true;
    _biasUpdatedAt = DateTime.now();
  }

  Future<void> _loadBiasFromStorageIfPossible() async {
    if (_biasLoaded) return;

    try {
      final raw = StorageService.instance.aiStorage.read(_biasStorageKey);
      if (raw is! String || raw.isEmpty) {
        _biasLoaded = true;
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        _biasLoaded = true;
        return;
      }

      final bias = decoded['bias'];
      final updatedAtStr = decoded['updated_at'];
      if (updatedAtStr is String) {
        _biasUpdatedAt = DateTime.tryParse(updatedAtStr);
      }

      if (bias is Map) {
        for (final d in VibeConstants.coreDimensions) {
          final v = bias[d];
          if (v is num) {
            _biasByDimension[d] = v.toDouble().clamp(-_maxAbsBias, _maxAbsBias);
          }
        }
      }

      _biasLoaded = true;
    } catch (_) {
      // Storage not initialized or invalid JSON. Degrade gracefully.
      _biasLoaded = true;
    }
  }

  Future<void> _persistBiasToStorageIfPossible() async {
    try {
      final payload = <String, dynamic>{
        'updated_at': (_biasUpdatedAt ?? DateTime.now()).toIso8601String(),
        'bias': _biasByDimension,
      };
      await StorageService.instance.aiStorage.write(
        _biasStorageKey,
        jsonEncode(payload),
      );
    } catch (_) {
      // Storage not initialized; best-effort only.
    }
  }
}
