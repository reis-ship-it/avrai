// Quantum Entanglement ML Service
//
// ML-based quantum entanglement detection using ONNX Runtime
// Replaces hardcoded dimension groups with learned patterns
// Part of Medium Priority Improvements
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/utils/vibe_constants.dart';

/// ML-based quantum entanglement detection service
///
/// Uses machine learning to detect complex entanglement patterns
/// between personality dimensions, replacing hardcoded groups.
///
/// **Model Input:**
/// - 12-dimensional personality profile (avrai dimensions)
/// - Dimension values (0.0-1.0)
///
/// **Model Output:**
/// - Entanglement groups (which dimensions entangle)
/// - Correlation strengths (0.0-1.0)
///
/// **Fallback:**
/// - If ML model unavailable, falls back to hardcoded groups
class QuantumEntanglementMLService {
  static const String _logName = 'QuantumEntanglementMLService';

  // Model configuration
  static const int inputSize = 12; // 12 avrai dimensions
  static const String defaultModelPath =
      'assets/models/entanglement_model.onnx';
  static const String defaultInputName = 'input';

  // Model state
  bool _isLoaded = false;
  bool _useOnnx = false;
  OrtSession? _session;

  /// Whether the ONNX model is loaded and being used
  bool get isUsingOnnx => _useOnnx;

  /// Whether initialization has completed (model or fallback)
  bool get isLoaded => _isLoaded;

  /// Get diagnostic info about this model's ONNX status
  Map<String, dynamic> getDiagnostics() {
    return {
      'model': 'entanglement',
      'isLoaded': _isLoaded,
      'isUsingOnnx': _useOnnx,
      'modelPath': defaultModelPath,
      'status': _useOnnx
          ? 'ONNX model active'
          : (_isLoaded ? 'Hardcoded fallback' : 'Not initialized'),
    };
  }

  /// Initialize and load ML model
  Future<bool> initialize() async {
    if (_isLoaded) {
      return _useOnnx;
    }

    try {
      developer.log(
        'Loading entanglement ML model from $defaultModelPath',
        name: _logName,
      );

      // Load model from assets
      final ByteData modelData;
      try {
        modelData = await rootBundle.load(defaultModelPath);
      } catch (e) {
        developer.log(
          'Model file not found at $defaultModelPath. Using hardcoded fallback: $e',
          name: _logName,
        );
        _useOnnx = false;
        _isLoaded = true;
        return false; // Fallback to hardcoded
      }

      final modelBytes = modelData.buffer.asUint8List();

      // Initialize ONNX runtime
      try {
        OrtEnv.instance.init();

        final sessionOptions = OrtSessionOptions();
        _session = OrtSession.fromBuffer(modelBytes, sessionOptions);
        sessionOptions.release();

        _useOnnx = true;
        _isLoaded = true;

        developer.log(
          '✅ Entanglement ML model loaded successfully (ONNX)',
          name: _logName,
        );

        return true;
      } catch (e, stackTrace) {
        developer.log(
          'Error creating ONNX session, using hardcoded fallback: $e',
          error: e,
          stackTrace: stackTrace,
          name: _logName,
        );
        _useOnnx = false;
        _isLoaded = true;
        return false; // Fallback to hardcoded
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error loading entanglement ML model: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      _useOnnx = false;
      _isLoaded = true;
      return false; // Fallback to hardcoded
    }
  }

  /// Detect entanglement patterns using ML
  ///
  /// Returns map of dimension pairs to correlation strengths
  /// Format: {'dimension1:dimension2': correlationStrength}
  ///
  /// **Note:** For now, this uses a fallback approach since we need
  /// the actual ML model to be trained. The service structure is ready
  /// for ML integration once the model is available.
  Future<Map<String, double>> detectEntanglementPatterns(
    PersonalityProfile profile,
  ) async {
    if (!_isLoaded) {
      await initialize();
    }

    if (!_useOnnx || _session == null) {
      // Fallback to hardcoded groups
      return _getHardcodedEntanglements(profile);
    }

    try {
      // Prepare input features (12 dimensions)
      final features = <double>[];
      for (final dimension in VibeConstants.coreDimensions) {
        features.add(profile.dimensions[dimension] ?? 0.5);
      }

      // Run ML inference
      // Note: This will work once the ONNX model is trained and available
      // For now, falls back to hardcoded groups
      final predictions = await _onnxPrediction(features);

      // Convert predictions to entanglement map
      return _parseEntanglementPredictions(predictions);
    } catch (e, stackTrace) {
      developer.log(
        'Error in ML entanglement detection, using fallback: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return _getHardcodedEntanglements(profile);
    }
  }

  /// Run ONNX inference
  Future<List<double>> _onnxPrediction(List<double> features) async {
    if (_session == null) {
      throw StateError('ONNX session not initialized');
    }

    OrtValue? inputTensor;
    OrtRunOptions? runOptions;

    try {
      // Convert to Float32List
      final inputData = Float32List.fromList(features);
      final inputShape = [1, inputSize]; // Batch size 1, 12 features

      // Create input tensor
      inputTensor =
          OrtValueTensor.createTensorWithDataList(inputData, inputShape);

      // Prepare inputs
      final inputs = {defaultInputName: inputTensor};
      runOptions = OrtRunOptions();

      // Run inference
      final outputs = _session!.run(runOptions, inputs);

      // Extract output
      if (outputs.isEmpty) {
        throw StateError('No output from model');
      }

      final outputTensor = outputs[0];
      if (outputTensor == null) {
        throw StateError('Output tensor is null');
      }

      // Get output data (expected: list of correlation values)
      final outputValue = outputTensor.value;
      List<double> predictions;

      if (outputValue is List) {
        predictions = outputValue
            .map((v) => (v as num).toDouble().clamp(0.0, 1.0))
            .toList();
      } else if (outputValue is num) {
        predictions = [outputValue.toDouble().clamp(0.0, 1.0)];
      } else {
        throw StateError('Unexpected output type: ${outputValue.runtimeType}');
      }

      // Clean up
      inputTensor.release();
      runOptions.release();
      for (final output in outputs) {
        output?.release();
      }

      return predictions;
    } catch (e, stackTrace) {
      // Clean up on error
      inputTensor?.release();
      runOptions?.release();
      developer.log(
        'ONNX inference error: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Parse ML predictions into entanglement map
  ///
  /// Model output format: [correlation_0_1, correlation_0_2, ..., correlation_10_11]
  /// For 12 dimensions, we have 12*11/2 = 66 pairs
  Map<String, double> _parseEntanglementPredictions(List<double> predictions) {
    final entanglements = <String, double>{};
    final dimensions = VibeConstants.coreDimensions;

    int predictionIndex = 0;
    for (int i = 0; i < dimensions.length; i++) {
      for (int j = i + 1; j < dimensions.length; j++) {
        if (predictionIndex < predictions.length) {
          final correlation = predictions[predictionIndex];
          // Only include correlations above threshold
          if (correlation > 0.2) {
            entanglements['${dimensions[i]}:${dimensions[j]}'] = correlation;
          }
        }
        predictionIndex++;
      }
    }

    return entanglements;
  }

  /// Fallback: Get hardcoded entanglement groups
  ///
  /// This matches the current implementation in QuantumVibeEngine
  Map<String, double> _getHardcodedEntanglements(PersonalityProfile profile) {
    final entanglements = <String, double>{};

    // Exploration-related dimensions
    final explorationDimensions = [
      'exploration_eagerness',
      'location_adventurousness',
      'novelty_seeking',
    ];
    _addGroupEntanglements(entanglements, explorationDimensions, 0.3);

    // Social-related dimensions
    final socialDimensions = [
      'social_discovery_style',
      'community_orientation',
      'trust_network_reliance',
    ];
    _addGroupEntanglements(entanglements, socialDimensions, 0.3);

    // Temporal dimensions (note: some may not exist in VibeConstants)
    final temporalDimensions = ['temporal_flexibility'];
    // Only add if dimension exists
    final validTemporal = temporalDimensions
        .where((d) => VibeConstants.coreDimensions.contains(d))
        .toList();
    if (validTemporal.length >= 2) {
      _addGroupEntanglements(entanglements, validTemporal, 0.4);
    }

    return entanglements;
  }

  /// Add entanglements for a group of dimensions
  void _addGroupEntanglements(
    Map<String, double> entanglements,
    List<String> dimensions,
    double correlation,
  ) {
    for (int i = 0; i < dimensions.length; i++) {
      for (int j = i + 1; j < dimensions.length; j++) {
        if (VibeConstants.coreDimensions.contains(dimensions[i]) &&
            VibeConstants.coreDimensions.contains(dimensions[j])) {
          entanglements['${dimensions[i]}:${dimensions[j]}'] = correlation;
        }
      }
    }
  }

  /// Calculate optimal correlations for dimension pairs
  ///
  /// Uses ML to predict correlation strength between two dimensions
  Future<double> predictEntanglementStrength(
    String dim1,
    String dim2,
    PersonalityProfile profile,
  ) async {
    final patterns = await detectEntanglementPatterns(profile);
    return patterns['$dim1:$dim2'] ?? patterns['$dim2:$dim1'] ?? 0.0;
  }

  /// Dispose resources
  void dispose() {
    _session?.release();
    _session = null;
    _isLoaded = false;
    _useOnnx = false;
  }
}
