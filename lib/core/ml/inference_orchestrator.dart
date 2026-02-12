// Inference Orchestrator for Phase 11: User-AI Interaction Update
// Layered inference path: ONNX for dimension scoring, Gemini for complex reasoning

import 'dart:developer' as developer;
import 'package:avrai/core/services/ai_infrastructure/llm_service.dart';
import 'package:avrai/core/services/infrastructure/config_service.dart';
import 'package:avrai/core/ml/onnx_dimension_scorer.dart';

/// Orchestrates inference based on strategy
/// Device-first: ONNX for dimension math, Gemini for reasoning
/// Edge-prefetch: Edge cache + device
/// Cloud-only: Pure cloud (fallback)
class InferenceOrchestrator {
  static const String _logName = 'InferenceOrchestrator';
  
  final OnnxDimensionScorer? onnxScorer;
  final LLMService llmService;
  final ConfigService config;
  
  InferenceOrchestrator({
    this.onnxScorer,
    required this.llmService,
    required this.config,
  });
  
  /// Orchestrates inference based on strategy
  Future<InferenceResult> infer({
    required Map<String, dynamic> input,
    required InferenceStrategy strategy,
  }) async {
    switch (strategy) {
      case InferenceStrategy.deviceFirst:
        return await _deviceFirstInference(input);
      case InferenceStrategy.edgePrefetch:
        return await _edgePrefetchInference(input);
      case InferenceStrategy.cloudOnly:
        return await _cloudOnlyInference(input);
    }
  }
  
  /// Device-first: ONNX for dimension scoring, Gemini for reasoning
  Future<InferenceResult> _deviceFirstInference(Map<String, dynamic> input) async {
    try {
      // Step 1: ONNX dimension scoring (privacy-sensitive, fast)
      Map<String, double> dimensionScores = {};
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
        // Fallback to rule-based scoring
        dimensionScores = _ruleBasedDimensionScoring(input);
      }
      
      // Step 2: Check if Gemini expansion needed
      final needsExpansion = _needsGeminiExpansion(input, dimensionScores);
      
      if (needsExpansion) {
        // Step 3: Prepare structured context for Gemini
        final structuredContext = _prepareStructuredContext(input, dimensionScores);
        
        // Step 4: Call Gemini with distilled context
        try {
          final geminiResponse = await llmService.chat(
            messages: [
              ChatMessage(
                role: ChatRole.system,
                content: 'You are a helpful assistant for SPOTS. Use the provided dimension scores and context to provide recommendations.',
              ),
              ChatMessage(
                role: ChatRole.user,
                content: _buildPrompt(input, structuredContext),
              ),
            ],
            context: _buildLLMContext(structuredContext),
          );
          
          return InferenceResult(
            dimensionScores: dimensionScores,
            reasoning: geminiResponse,
            source: InferenceSource.hybrid, // ONNX + Gemini
          );
        } catch (e) {
          developer.log(
            'Gemini expansion failed, returning ONNX-only result: $e',
            name: _logName,
          );
          // Fallback to ONNX-only result if Gemini fails
          return InferenceResult(
            dimensionScores: dimensionScores,
            reasoning: null,
            source: InferenceSource.device, // ONNX only
          );
        }
      } else {
        // ONNX-only result
        return InferenceResult(
          dimensionScores: dimensionScores,
          reasoning: null,
          source: InferenceSource.device, // ONNX only
        );
      }
    } catch (e) {
      developer.log(
        'Device-first inference failed, falling back to cloud: $e',
        name: _logName,
      );
      // Fallback to cloud-only
      return await _cloudOnlyInference(input);
    }
  }
  
  /// Check if Gemini expansion is needed
  bool _needsGeminiExpansion(Map<String, dynamic> input, Map<String, double> scores) {
    // Heuristics for when to use Gemini:
    // 1. Complex query (natural language, multiple intents)
    // 2. Low confidence scores (need reasoning)
    // 3. User explicitly requests narrative/explanation
    // 4. Context requires social/community insights
    
    final query = input['query'] as String? ?? '';
    final hasComplexQuery = query.length > 50 || query.contains('?');
    final hasLowConfidence = scores.values.any((s) => s < 0.3);
    final needsNarrative = input['needs_narrative'] as bool? ?? false;
    
    return hasComplexQuery || hasLowConfidence || needsNarrative;
  }
  
  /// Prepare structured context for Gemini
  Map<String, dynamic> _prepareStructuredContext(
    Map<String, dynamic> input,
    Map<String, double> scores,
  ) {
    // Convert to structured facts for Gemini
    return {
      'dimension_scores': scores,
      'traits': _scoresToTraits(scores),
      'places': input['places'] ?? [],
      'social_graph': input['social_graph'] ?? [],
      'onboarding_data': input['onboarding_data'] ?? {},
    };
  }
  
  /// Convert dimension scores to human-readable traits
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
  
  /// Build prompt for Gemini
  String _buildPrompt(Map<String, dynamic> input, Map<String, dynamic> context) {
    final query = input['query'] as String? ?? '';
    final traits = (context['traits'] as List?)?.join(', ') ?? '';
    
    return '''
User query: $query
User traits: $traits
Dimension scores: ${context['dimension_scores']}

Provide a helpful recommendation based on this context.
''';
  }
  
  /// Build LLMContext for LLMService
  LLMContext _buildLLMContext(Map<String, dynamic> structuredContext) {
    // Extract preferences from onboarding data
    final preferences = (structuredContext['onboarding_data'] as Map<String, dynamic>?)?['preferences'] as Map<String, dynamic>?;
    
    return LLMContext(
      location: null, // Can be added from input if available
      preferences: preferences,
    );
  }
  
  /// Rule-based dimension scoring (fallback when ONNX unavailable)
  Map<String, double> _ruleBasedDimensionScoring(Map<String, dynamic> input) {
    // Fallback rule-based scoring when ONNX unavailable
    // This provides basic dimension scores based on input data
    final scores = <String, double>{};
    
    // Extract basic signals from input
    final places = input['places'] as List? ?? [];
    final socialGraph = input['social_graph'] as List? ?? [];
    
    // Basic heuristics for dimension scoring
    if (places.isNotEmpty) {
      scores['location_adventurousness'] = 0.6;
      scores['exploration_eagerness'] = 0.7;
    }
    
    if (socialGraph.isNotEmpty) {
      scores['community_orientation'] = 0.7;
      scores['trust_network_reliance'] = 0.6;
    }
    
    // Default values for missing dimensions
    scores['exploration_eagerness'] ??= 0.5;
    scores['community_orientation'] ??= 0.5;
    scores['location_adventurousness'] ??= 0.5;
    scores['authenticity_preference'] ??= 0.5;
    scores['trust_network_reliance'] ??= 0.5;
    scores['temporal_flexibility'] ??= 0.5;
    
    return scores;
  }
  
  /// Edge-prefetch inference (similar to device-first but prefetches from edge)
  Future<InferenceResult> _edgePrefetchInference(Map<String, dynamic> input) async {
    // For now, similar to device-first
    // TODO: Add edge cache prefetching
    return await _deviceFirstInference(input);
  }
  
  /// Pure cloud inference (current implementation)
  Future<InferenceResult> _cloudOnlyInference(Map<String, dynamic> input) async {
    try {
      final query = input['query'] as String? ?? '';
      final response = await llmService.chat(
        messages: [
          ChatMessage(
            role: ChatRole.user,
            content: query.isNotEmpty ? query : 'Provide recommendations',
          ),
        ],
      );
      
      return InferenceResult(
        dimensionScores: {},
        reasoning: response,
        source: InferenceSource.cloud,
      );
    } catch (e) {
      developer.log('Cloud-only inference failed: $e', name: _logName);
      // Return empty result if cloud fails
      return InferenceResult(
        dimensionScores: {},
        reasoning: null,
        source: InferenceSource.cloud,
      );
    }
  }
}

/// Inference strategy
enum InferenceStrategy {
  deviceFirst, // ONNX for math, Gemini for reasoning
  edgePrefetch, // Edge cache + device
  cloudOnly, // Pure cloud (fallback)
}

/// Inference source
enum InferenceSource {
  device, // ONNX only
  hybrid, // ONNX + Gemini
  cloud, // Cloud only
}

/// Inference result
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
