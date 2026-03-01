// Foundation Models Service
//
// Dart interface for Apple's Foundation Models framework (iOS 26+).
// Provides on-device LLM capabilities for text generation, streaming,
// and structured output generation.
//
// Features:
// - Check model availability
// - Single-shot text generation
// - Streaming text generation
// - Structured output with guided generation
//
// Usage:
//   final service = FoundationModelsService();
//   if (await service.isAvailable) {
//     final response = await service.generate('Hello');
//   }

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';

/// Dart interface for Apple's Foundation Models framework.
///
/// Provides on-device LLM capabilities available on iOS 26+ devices
/// with Apple Silicon. All processing happens locally for privacy.
class FoundationModelsService {
  static const String _logName = 'FoundationModelsService';

  /// Method channel for single-shot operations
  static const MethodChannel _channel = MethodChannel('avra/foundation_models');

  /// Event channel for streaming responses
  static const EventChannel _streamChannel =
      EventChannel('avra/foundation_models_stream');

  /// Singleton instance
  static final FoundationModelsService _instance =
      FoundationModelsService._internal();

  factory FoundationModelsService() => _instance;

  FoundationModelsService._internal();

  /// Current streaming subscription
  StreamSubscription<dynamic>? _streamSubscription;

  /// Stream controller for current generation
  StreamController<String>? _currentStreamController;

  /// Check if Foundation Models is available on this device.
  ///
  /// Returns true only on iOS 26+ devices with Apple Silicon
  /// that have the on-device LLM model available.
  Future<bool> get isAvailable async {
    if (!Platform.isIOS) {
      developer.log(
        'Foundation Models only available on iOS',
        name: _logName,
      );
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Error checking Foundation Models availability: ${e.message}',
        error: e,
        name: _logName,
      );
      return false;
    } catch (e) {
      developer.log(
        'Unexpected error checking availability: $e',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  /// Generate text from a prompt using the on-device LLM.
  ///
  /// [prompt] - The user's input prompt
  /// [instructions] - Optional system instructions to guide the model
  ///
  /// Returns the complete generated text, or null if generation failed.
  Future<String?> generate(
    String prompt, {
    String? instructions,
  }) async {
    if (!Platform.isIOS) {
      developer.log(
        'Foundation Models only available on iOS',
        name: _logName,
      );
      return null;
    }

    try {
      final result = await _channel.invokeMethod<String>('generate', {
        'prompt': prompt,
        if (instructions != null) 'instructions': instructions,
      });
      return result;
    } on PlatformException catch (e) {
      developer.log(
        'Error generating text: ${e.message}',
        error: e,
        name: _logName,
      );
      return null;
    } catch (e) {
      developer.log(
        'Unexpected error generating text: $e',
        error: e,
        name: _logName,
      );
      return null;
    }
  }

  /// Stream text generation from a prompt.
  ///
  /// Returns a stream that emits partial text as the model generates.
  /// Each emission contains the cumulative generated text so far.
  ///
  /// [prompt] - The user's input prompt
  /// [instructions] - Optional system instructions to guide the model
  Stream<String> streamGenerate(
    String prompt, {
    String? instructions,
  }) {
    if (!Platform.isIOS) {
      developer.log(
        'Foundation Models only available on iOS',
        name: _logName,
      );
      return const Stream.empty();
    }

    // Cancel any existing stream
    _cancelCurrentStream();

    // Create new stream controller
    _currentStreamController = StreamController<String>.broadcast(
      onCancel: _cancelCurrentStream,
    );

    // Start the generation on native side
    _channel.invokeMethod('startStream', {
      'prompt': prompt,
      if (instructions != null) 'instructions': instructions,
    }).catchError((e) {
      developer.log(
        'Error starting stream: $e',
        error: e,
        name: _logName,
      );
      _currentStreamController?.addError(e);
      _currentStreamController?.close();
    });

    // Listen to the event channel
    _streamSubscription = _streamChannel.receiveBroadcastStream().listen(
      (data) {
        if (data is String) {
          _currentStreamController?.add(data);
        } else if (data is Map && data['done'] == true) {
          _currentStreamController?.close();
        }
      },
      onError: (error) {
        developer.log(
          'Stream error: $error',
          error: error,
          name: _logName,
        );
        _currentStreamController?.addError(error);
        _currentStreamController?.close();
      },
      onDone: () {
        _currentStreamController?.close();
      },
    );

    return _currentStreamController!.stream;
  }

  /// Stop any ongoing streaming generation.
  Future<void> stopStream() async {
    _cancelCurrentStream();

    try {
      await _channel.invokeMethod('stopStream');
    } catch (e) {
      developer.log(
        'Error stopping stream: $e',
        error: e,
        name: _logName,
      );
    }
  }

  /// Cancel the current stream subscription
  void _cancelCurrentStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _currentStreamController?.close();
    _currentStreamController = null;
  }

  /// Generate structured output using guided generation.
  ///
  /// [prompt] - The user's input prompt
  /// [schema] - JSON schema describing the expected output structure
  /// [instructions] - Optional system instructions
  ///
  /// Returns a JSON string matching the provided schema.
  Future<String?> generateStructured(
    String prompt, {
    required Map<String, dynamic> schema,
    String? instructions,
  }) async {
    if (!Platform.isIOS) {
      developer.log(
        'Foundation Models only available on iOS',
        name: _logName,
      );
      return null;
    }

    try {
      final result = await _channel.invokeMethod<String>('generateStructured', {
        'prompt': prompt,
        'schema': schema,
        if (instructions != null) 'instructions': instructions,
      });
      return result;
    } on PlatformException catch (e) {
      developer.log(
        'Error generating structured output: ${e.message}',
        error: e,
        name: _logName,
      );
      return null;
    } catch (e) {
      developer.log(
        'Unexpected error generating structured output: $e',
        error: e,
        name: _logName,
      );
      return null;
    }
  }

  /// Generate a personality insight from a user's knot.
  ///
  /// Uses the on-device LLM to generate a human-readable description
  /// of the user's personality based on their knot characteristics.
  Future<String?> generateKnotInsight({
    required Map<String, dynamic> knotData,
  }) async {
    const instructions = '''
You are a personality insight assistant for AVRAI. 
Given a user's personality knot data, provide a brief, insightful, 
and positive description of their personality traits.
Be warm, encouraging, and focus on strengths.
Keep the response to 2-3 sentences.
''';

    final prompt = '''
Describe this person's personality based on their knot:
- Crossing number: ${knotData['crossingNumber']}
- Writhe: ${knotData['writhe']}
- Bridge number: ${knotData['bridgeNumber']}
- Unknotting number: ${knotData['unknottingNumber']}
''';

    return generate(prompt, instructions: instructions);
  }

  /// Generate spot recommendations based on user preferences.
  Future<String?> generateSpotRecommendation({
    required String query,
    required List<Map<String, dynamic>> nearbySpots,
  }) async {
    const instructions = '''
You are a location recommendation assistant for AVRAI.
Given a user's query and a list of nearby spots, recommend the best match.
Be concise and helpful. Explain why the spot is a good match.
''';

    final spotsDescription = nearbySpots
        .map((s) => '- ${s['name']}: ${s['category']}, ${s['distance']} mi')
        .join('\n');

    final prompt = '''
User is looking for: $query

Nearby options:
$spotsDescription

Which spot would you recommend and why?
''';

    return generate(prompt, instructions: instructions);
  }

  /// Dispose of resources
  void dispose() {
    _cancelCurrentStream();
  }
}
