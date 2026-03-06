import 'dart:convert';
import 'package:avrai_core/utils/vibe_constants.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/llm_service.dart';
import 'dart:developer' as developer;

/// An Air-Gapped SLM service that translates raw open-ended onboarding
/// responses into an initial 12D personality vector (DNA).
/// By using LLMBackend.local, it ensures the raw text never leaves the device.
class InitialDNASynthesisService {
  final LLMService _llmService;

  InitialDNASynthesisService({required LLMService llmService})
      : _llmService = llmService;

  /// Parses the user's open responses and returns a map of dimension names to values (0.0 to 1.0).
  Future<Map<String, double>> synthesizeInitialDNA(
      Map<String, String> openResponses) async {
    if (openResponses.isEmpty) {
      return _getFallbackDNA();
    }

    try {
      final jsonSchema = '''{
  "type": "object",
  "properties": {
    "dimensions": {
      "type": "object",
      "description": "A map of personality dimension names to their values (between 0.0 and 1.0). Must include all 12 core dimensions.",
      "additionalProperties": { "type": "number" }
    }
  },
  "required": ["dimensions"]
}''';

      // Build the context from their answers
      final buffer = StringBuffer();
      for (final entry in openResponses.entries) {
        if (entry.value.trim().isNotEmpty) {
          buffer.writeln("- ${entry.key}: ${entry.value}");
        }
      }
      final userContext = buffer.toString();

      if (userContext.isEmpty) {
        return _getFallbackDNA();
      }

      final prompt = '''
You are a core component of AVRAI's Aspirational DNA engine.
The user has provided some open-ended answers about who they are and what they like.
Your job is to translate these natural language answers into a baseline personality profile across our 12 core dimensions.

The 12 dimensions are:
${VibeConstants.coreDimensions.join(', ')}

User's Answers:
$userContext

Analyze the text and determine the baseline value for each dimension.
Values must be between 0.0 (very low/opposite) and 1.0 (very high/strong). 0.5 is neutral.
Provide only the JSON mapping the dimension name to the value. Do not include markdown formatting.
''';

      final responseStr = await _llmService.chat(
        messages: [ChatMessage(role: ChatRole.user, content: prompt)],
        temperature: 0.2,
        maxTokens: 600,
        responseFormat: jsonSchema,
      );

      final cleanJson =
          responseStr.replaceAll('```json', '').replaceAll('```', '').trim();
      final decoded = jsonDecode(cleanJson) as Map<String, dynamic>;

      final Map<String, double> dnaVector = {};

      if (decoded.containsKey('dimensions') && decoded['dimensions'] != null) {
        final dims = decoded['dimensions'] as Map<String, dynamic>;
        for (final dimName in VibeConstants.coreDimensions) {
          if (dims.containsKey(dimName)) {
            dnaVector[dimName] =
                (dims[dimName] as num).toDouble().clamp(0.0, 1.0);
          } else {
            dnaVector[dimName] = 0.5; // Neutral fallback
          }
        }
      } else {
        return _getFallbackDNA();
      }

      developer.log('Synthesized initial DNA vector: $dnaVector',
          name: 'InitialDNASynthesisService');
      return dnaVector;
    } catch (e, st) {
      developer.log('Failed to synthesize DNA, falling back: $e',
          error: e, stackTrace: st, name: 'InitialDNASynthesisService');
      return _getFallbackDNA();
    }
  }

  Map<String, double> _getFallbackDNA() {
    final Map<String, double> fallback = {};
    for (final dim in VibeConstants.coreDimensions) {
      fallback[dim] = 0.5; // Neutral everywhere
    }
    return fallback;
  }
}
