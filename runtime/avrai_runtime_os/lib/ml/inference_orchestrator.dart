import 'dart:developer' as developer;

import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/config_service.dart';
import 'package:avrai_runtime_os/ml/onnx_dimension_scorer.dart';
import 'package:avrai_core/models/expression/expression_models.dart';
import 'package:avrai_core/models/vibe/vibe_models.dart';
import 'package:reality_engine/reality_engine.dart';

/// Orchestrates inference based on strategy.
///
/// Device-first uses local scoring for structured signals and the expression
/// kernel for the final reasoning layer. The mouth expresses only what the
/// orchestrator has already grounded.
class InferenceOrchestrator {
  static const String _logName = 'InferenceOrchestrator';

  final OnnxDimensionScorer? onnxScorer;
  final ConfigService config;
  final LanguageKernelOrchestratorService _languageKernelOrchestrator;
  final VibeKernel _vibeKernel;

  InferenceOrchestrator({
    this.onnxScorer,
    required this.config,
    LanguageKernelOrchestratorService? languageKernelOrchestrator,
    VibeKernel? vibeKernel,
  }) : _languageKernelOrchestrator =
            languageKernelOrchestrator ?? LanguageKernelOrchestratorService(),
        _vibeKernel = vibeKernel ?? VibeKernel();

  Future<InferenceResult> infer({
    required Map<String, dynamic> input,
    required InferenceStrategy strategy,
  }) async {
    switch (strategy) {
      case InferenceStrategy.deviceFirst:
        return _deviceFirstInference(input);
      case InferenceStrategy.edgePrefetch:
        return _edgePrefetchInference(input);
      case InferenceStrategy.cloudOnly:
        return _cloudOnlyInference(input);
    }
  }

  Future<InferenceResult> _deviceFirstInference(
    Map<String, dynamic> input,
  ) async {
    try {
      Map<String, double> dimensionScores = <String, double>{};
      if (onnxScorer != null) {
        try {
          dimensionScores = await onnxScorer!.scoreDimensions(input);
        } catch (e) {
          developer.log(
            'ONNX scoring failed, using rule-based fallback: $e',
            name: _logName,
          );
          dimensionScores = _ruleBasedDimensionScoring(input);
        }
      } else {
        dimensionScores = _ruleBasedDimensionScoring(input);
      }

      final needsReasoningExpansion =
          _needsReasoningExpansion(input, dimensionScores);
      final reasoning = needsReasoningExpansion
          ? _renderGroundedReasoning(
              input: input,
              dimensionScores: dimensionScores,
              source: InferenceSource.hybrid,
            )
          : null;

      return InferenceResult(
        dimensionScores: dimensionScores,
        reasoning: reasoning,
        source:
            reasoning == null ? InferenceSource.device : InferenceSource.hybrid,
      );
    } catch (e) {
      developer.log(
        'Device-first inference failed, falling back to grounded cloud mode: '
        '$e',
        name: _logName,
      );
      return _cloudOnlyInference(input);
    }
  }

  bool _needsReasoningExpansion(
    Map<String, dynamic> input,
    Map<String, double> scores,
  ) {
    final query = input['query'] as String? ?? '';
    final hasComplexQuery = query.length > 50 || query.contains('?');
    final hasLowConfidence = scores.values.any((score) => score < 0.3);
    final needsNarrative = input['needs_narrative'] as bool? ?? false;

    return hasComplexQuery || hasLowConfidence || needsNarrative;
  }

  Map<String, dynamic> _prepareStructuredContext(
    Map<String, dynamic> input,
    Map<String, double> scores,
  ) {
    return <String, dynamic>{
      'dimension_scores': scores,
      'traits': _scoresToTraits(scores),
      'places': input['places'] ?? const <dynamic>[],
      'social_graph': input['social_graph'] ?? const <dynamic>[],
      'onboarding_data': input['onboarding_data'] ?? const <String, dynamic>{},
    };
  }

  List<String> _scoresToTraits(Map<String, double> scores) {
    final traits = <String>[];
    if ((scores['exploration_eagerness'] ?? 0.0) > 0.7) {
      traits.add('explorer');
    }
    if ((scores['community_orientation'] ?? 0.0) > 0.7) {
      traits.add('community-focused');
    }
    if ((scores['location_adventurousness'] ?? 0.0) > 0.7) {
      traits.add('adventurous');
    }
    if ((scores['authenticity_preference'] ?? 0.0) > 0.7) {
      traits.add('authentic');
    }
    if ((scores['trust_network_reliance'] ?? 0.0) > 0.7) {
      traits.add('trusts-network');
    }
    return traits;
  }

  String _renderGroundedReasoning({
    required Map<String, dynamic> input,
    required Map<String, double> dimensionScores,
    required InferenceSource source,
  }) {
    final structuredContext = _prepareStructuredContext(input, dimensionScores);
    final query = (input['query'] as String? ?? '').trim();
    final traits = ((structuredContext['traits'] as List?) ?? const <dynamic>[])
        .whereType<String>();
    final topDimensions = _topDimensions(dimensionScores);

    final claims = <String>[
      if (query.isNotEmpty)
        'AVRAI grounded this reasoning in the current query and runtime context.',
      if (topDimensions.isNotEmpty)
        'Strongest local signals: '
            '${topDimensions.map(_formatDimensionSignal).join(', ')}.',
      if (traits.isNotEmpty)
        'Current local scoring points toward ${traits.take(3).join(', ')}.',
      if (source == InferenceSource.hybrid)
        'This pass combines local scoring with a governed expression layer.',
      if (query.isEmpty && topDimensions.isEmpty)
        'AVRAI is using only the currently available runtime context.',
    ];

    final rendered = _languageKernelOrchestrator.renderGroundedOutput(
      speechAct: ExpressionSpeechAct.explain,
      audience: ExpressionAudience.userSafe,
      surfaceShape: ExpressionSurfaceShape.card,
      subjectLabel: 'Inference reasoning',
      allowedClaims: claims,
      confidenceBand: topDimensions.isEmpty ? 'low' : 'medium',
      vibeContext: _safeExpressionContext(input),
      uncertaintyNotice: topDimensions.isEmpty
          ? 'No strong local dimension signal was available for this pass.'
          : null,
      toneProfile: 'clear_direct',
    );
    return rendered.text;
  }

  VibeExpressionContext? _safeExpressionContext(Map<String, dynamic> input) {
    final subjectId =
        input['agentId'] as String? ?? input['userId'] as String? ?? input['subjectId'] as String?;
    if (subjectId == null || subjectId.trim().isEmpty) {
      return null;
    }
    try {
      return _vibeKernel.getExpressionContext(subjectId);
    } catch (_) {
      return null;
    }
  }

  List<MapEntry<String, double>> _topDimensions(Map<String, double> scores) {
    final ranked = scores.entries
        .where((entry) => (entry.value - 0.5).abs() >= 0.05)
        .toList()
      ..sort((left, right) =>
          (right.value - 0.5).abs().compareTo((left.value - 0.5).abs()));
    return ranked.take(3).toList(growable: false);
  }

  String _formatDimensionSignal(MapEntry<String, double> entry) {
    final label = entry.key.replaceAll('_', ' ');
    return '$label ${entry.value.toStringAsFixed(2)}';
  }

  Map<String, double> _ruleBasedDimensionScoring(Map<String, dynamic> input) {
    final scores = <String, double>{};
    final places = input['places'] as List? ?? const <dynamic>[];
    final socialGraph = input['social_graph'] as List? ?? const <dynamic>[];

    if (places.isNotEmpty) {
      scores['location_adventurousness'] = 0.6;
      scores['exploration_eagerness'] = 0.7;
    }

    if (socialGraph.isNotEmpty) {
      scores['community_orientation'] = 0.7;
      scores['trust_network_reliance'] = 0.6;
    }

    scores['exploration_eagerness'] ??= 0.5;
    scores['community_orientation'] ??= 0.5;
    scores['location_adventurousness'] ??= 0.5;
    scores['authenticity_preference'] ??= 0.5;
    scores['trust_network_reliance'] ??= 0.5;
    scores['temporal_flexibility'] ??= 0.5;

    return scores;
  }

  Future<InferenceResult> _edgePrefetchInference(
    Map<String, dynamic> input,
  ) async {
    return _deviceFirstInference(input);
  }

  Future<InferenceResult> _cloudOnlyInference(
    Map<String, dynamic> input,
  ) async {
    try {
      final reasoning = _renderGroundedReasoning(
        input: input,
        dimensionScores: const <String, double>{},
        source: InferenceSource.cloud,
      );
      return InferenceResult(
        dimensionScores: const <String, double>{},
        reasoning: reasoning,
        source: InferenceSource.cloud,
      );
    } catch (e) {
      developer.log('Cloud-only inference failed: $e', name: _logName);
      return InferenceResult(
        dimensionScores: const <String, double>{},
        reasoning: null,
        source: InferenceSource.cloud,
      );
    }
  }
}

enum InferenceStrategy {
  deviceFirst,
  edgePrefetch,
  cloudOnly,
}

enum InferenceSource {
  device,
  hybrid,
  cloud,
}

class InferenceResult {
  final Map<String, double> dimensionScores;
  final String? reasoning;
  final InferenceSource source;

  InferenceResult({
    required this.dimensionScores,
    this.reasoning,
    required this.source,
  });
}
