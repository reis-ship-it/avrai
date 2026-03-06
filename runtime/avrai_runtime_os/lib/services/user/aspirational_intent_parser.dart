import 'dart:convert';
import 'package:avrai_core/utils/vibe_constants.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/llm_service.dart';
import 'dart:developer' as developer;

/// An SLM service that translates natural language goals into
/// target mathematical vector shifts for the user's Quantum State / DNA.
class AspirationalIntentParser {
  final LLMService _llmService;

  AspirationalIntentParser({required LLMService llmService})
      : _llmService = llmService;

  /// Parses the user's message and returns a map of dimension indices (or names) to their intended shifts.
  /// Positive means increase that dimension, negative means decrease.
  Future<Map<String, double>> parseIntent(String message) async {
    try {
      final jsonSchema = '''{
  "type": "object",
  "properties": {
    "dimensions": {
      "type": "object",
      "description": "A map of personality dimension names to their shift values (between -1.0 and 1.0). Only include dimensions that the user explicitly wants to change.",
      "additionalProperties": { "type": "number" }
    }
  },
  "required": ["dimensions"]
}''';

      final prompt = '''
You are a core component of AVRAI's Aspirational DNA engine.
The user is expressing a desire to change their vibe, personality, or lifestyle.
Your job is to translate their natural language into mathematical shifts across our 12 core dimensions.

The 12 dimensions are:
${VibeConstants.coreDimensions.join(', ')}

Analyze this message: "$message"

Determine which dimensions should shift to match this aspiration.
A positive value (e.g. 0.3 to 0.8) means they want more of that trait.
A negative value (e.g. -0.3 to -0.8) means they want less of that trait.
Provide only the JSON mapping the dimension name to the shift amount. Do not include markdown formatting.
''';

      final responseStr = await _llmService.chat(
        messages: [ChatMessage(role: ChatRole.user, content: prompt)],
        temperature: 0.2,
        maxTokens: 500,
        responseFormat: jsonSchema,
      );

      final cleanJson =
          responseStr.replaceAll('```json', '').replaceAll('```', '').trim();
      final decoded = jsonDecode(cleanJson) as Map<String, dynamic>;

      final Map<String, double> vectorShift = {};

      if (decoded.containsKey('dimensions') && decoded['dimensions'] != null) {
        final dims = decoded['dimensions'] as Map<String, dynamic>;
        for (final entry in dims.entries) {
          if (VibeConstants.coreDimensions.contains(entry.key)) {
            vectorShift[entry.key] = (entry.value as num).toDouble();
          }
        }
      }

      developer.log('Parsed intent into vector shift: $vectorShift',
          name: 'AspirationalIntentParser');
      return vectorShift;
    } catch (e, st) {
      developer.log('Failed to parse intent, falling back to empty shift: $e',
          error: e, stackTrace: st, name: 'AspirationalIntentParser');
      return {};
    }
  }
}
