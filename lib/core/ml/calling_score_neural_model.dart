// Calling Score Neural Model for Phase 12: Neural Network Implementation
// Section 2.1: Calling Score Prediction Model
// Manages neural network model for calling score prediction

import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:avrai/core/ml/model_version_registry.dart';

/// Calling Score Neural Model
/// 
/// Manages the neural network model for calling score prediction.
/// 
/// Phase 12 Section 2.1: Calling Score Prediction Model
/// 
/// **Model Architecture:**
/// - Input: 39 features
///   - User vibe dimensions (12D)
///   - Spot vibe dimensions (12D)
///   - Context features (10 features)
///   - Timing features (5 features)
/// - Architecture: Multi-layer perceptron (MLP)
///   - Input (39) → Hidden (128) → Hidden (64) → Output (1)
/// - Output: Calling score (0.0-1.0)
/// 
/// **Training:**
/// - Models are trained in Python (PyTorch/TensorFlow)
/// - Exported to ONNX format for mobile deployment
/// - Models are loaded from assets or downloaded from server
class CallingScoreNeuralModel {
  static const String _logName = 'CallingScoreNeuralModel';
  
  // Model configuration
  static const int inputSize = 39; // User vibe (12) + Spot vibe (12) + Context (10) + Timing (5)
  static const List<int> hiddenSizes = [128, 64];
  static const int outputSize = 1;
  
  // Model state
  bool _isLoaded = false;
  String? _modelVersion;
  DateTime? _modelLoadedAt;
  
  // ONNX runtime
  OrtSession? _session;
  bool _useOnnx = false; // Whether ONNX model is actually loaded and usable
  
  // Model configuration
  static const String defaultModelPath = 'assets/models/calling_score_model.onnx';
  static const String defaultInputName = 'input';
  static const String defaultOutputName = 'output';
  
  /// Initialize and load the neural network model
  /// 
  /// **Parameters:**
  /// - `version`: Model version to load (e.g., 'v1.0-hybrid'). If null, uses active version from registry.
  /// - `modelPath`: Direct path to ONNX model file (overrides version if provided)
  /// 
  /// Returns true if model loaded successfully
  Future<bool> loadModel({String? version, String? modelPath}) async {
    try {
      developer.log('Loading calling score neural model...', name: _logName);
      
      // Determine which model to load
      String actualModelPath;
      String actualVersion;
      
      if (modelPath != null) {
        // Direct path provided, use it
        actualModelPath = modelPath;
        actualVersion = 'custom';
      } else if (version != null) {
        // Specific version requested
        final versionInfo = ModelVersionRegistry.getCallingScoreVersion(version);
        if (versionInfo == null) {
          developer.log(
            'Version $version not found in registry, using default path',
            name: _logName,
          );
          actualModelPath = defaultModelPath;
          actualVersion = version;
        } else {
          actualModelPath = versionInfo.modelPath;
          actualVersion = version;
        }
      } else {
        // Use active version from registry
        final activeVersionInfo = ModelVersionRegistry.getActiveCallingScoreVersion();
        if (activeVersionInfo != null) {
          actualModelPath = activeVersionInfo.modelPath;
          actualVersion = activeVersionInfo.version;
        } else {
          // Fallback to default
          actualModelPath = defaultModelPath;
          actualVersion = 'default';
        }
      }
      
      // Try to load model from assets
      Uint8List? modelBytes;
      try {
        final assetBundle = rootBundle;
        final byteData = await assetBundle.load(actualModelPath);
        modelBytes = byteData.buffer.asUint8List();
        developer.log('Model file loaded from assets: $actualModelPath (version: $actualVersion)', name: _logName);
      } catch (e) {
        developer.log(
          'Model file not found at $actualModelPath. Using rule-based fallback: $e',
          name: _logName,
        );
        _useOnnx = false;
        _isLoaded = true;
        _modelVersion = '$actualVersion-placeholder';
        _modelLoadedAt = DateTime.now();
        return true;
      }
      
      // Initialize ONNX runtime and create session
      try {
        // Initialize environment
        OrtEnv.instance.init();
        
        // Create session options
        final sessionOptions = OrtSessionOptions();
        
        // Create session from model bytes
        _session = OrtSession.fromBuffer(modelBytes, sessionOptions);
        
        sessionOptions.release();
        
        _useOnnx = true;
        _isLoaded = true;
        _modelVersion = actualVersion;
        _modelLoadedAt = DateTime.now();
        
        developer.log(
          '✅ Calling score neural model loaded successfully (ONNX)',
          name: _logName,
        );
        
        return true;
      } catch (e, stackTrace) {
        developer.log(
          'Error creating ONNX session, using rule-based fallback: $e',
          name: _logName,
          error: e,
          stackTrace: stackTrace,
        );
        _useOnnx = false;
        _isLoaded = true;
        _modelVersion = '1.0.0-placeholder';
        _modelLoadedAt = DateTime.now();
        return true; // Return true to allow rule-based fallback
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error loading neural model: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Fallback to rule-based prediction
      _useOnnx = false;
      _isLoaded = true;
      _modelVersion = '1.0.0-placeholder';
      _modelLoadedAt = DateTime.now();
      return true; // Return true to allow rule-based fallback
    }
  }
  
  /// Predict calling score using neural network model
  /// 
  /// **Parameters:**
  /// - `features`: Input features (39D vector)
  ///   - [0-11]: User vibe dimensions (12D)
  ///   - [12-23]: Spot vibe dimensions (12D)
  ///   - [24-33]: Context features (10 features)
  ///   - [34-38]: Timing features (5 features)
  /// 
  /// **Returns:**
  /// Calling score (0.0-1.0)
  Future<double> predict(List<double> features) async {
    if (!_isLoaded) {
      await loadModel();
    }
    
    try {
      // Validate input size
      if (features.length != inputSize) {
        throw ArgumentError(
          'Expected $inputSize features, got ${features.length}',
        );
      }
      
      // Use ONNX model if available, otherwise use rule-based fallback
      if (_useOnnx && _session != null) {
        try {
          return await _onnxPrediction(features);
        } catch (e, stackTrace) {
          developer.log(
            'ONNX prediction failed, using rule-based fallback: $e',
            name: _logName,
            error: e,
            stackTrace: stackTrace,
          );
          // Fallback to rule-based prediction
          return _ruleBasedPrediction(features);
        }
      } else {
        // No ONNX model loaded, use rule-based fallback
        return _ruleBasedPrediction(features);
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error predicting calling score: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Return neutral score on error
      return 0.5;
    }
  }
  
  /// ONNX-based prediction
  /// 
  /// Uses actual ONNX model for inference
  Future<double> _onnxPrediction(List<double> features) async {
    if (_session == null) {
      throw StateError('ONNX session not initialized');
    }
    
    OrtValue? inputTensor;
    OrtRunOptions? runOptions;
    
    try {
      // Convert features to Float32List for ONNX
      final inputData = Float32List.fromList(features);
      
      // Create input tensor: shape [1, 39] (batch size 1, 39 features)
      final inputShape = [1, inputSize];
      
      // Create input tensor using the correct API
      inputTensor = OrtValueTensor.createTensorWithDataList(inputData, inputShape);
      
      // Prepare inputs map
      final inputs = {defaultInputName: inputTensor};
      
      // Create run options
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
      
      // Get output data
      final outputValue = outputTensor.value;
      double score;
      if (outputValue is List) {
        score = (outputValue.isNotEmpty && outputValue.first is num)
            ? (outputValue.first as num).toDouble()
            : 0.5;
      } else if (outputValue is num) {
        score = outputValue.toDouble();
      } else {
        throw StateError('Unexpected output type: ${outputValue.runtimeType}');
      }
      
      // Clean up
      inputTensor.release();
      runOptions.release();
      for (final output in outputs) {
        output?.release();
      }
      
      // Clamp score to [0.0, 1.0]
      return score.clamp(0.0, 1.0);
    } catch (e, stackTrace) {
      // Clean up on error
      inputTensor?.release();
      runOptions?.release();
      developer.log(
        'ONNX prediction error: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Rule-based prediction (fallback when ONNX model not available)
  /// 
  /// Uses simple heuristics based on feature values
  double _ruleBasedPrediction(List<double> features) {
    // Extract feature groups
    final userVibe = features.sublist(0, 12);
    final spotVibe = features.sublist(12, 24);
    final contextFeatures = features.sublist(24, 34);
    final timingFeatures = features.sublist(34, 39);
    
    // Calculate vibe compatibility (average similarity)
    double vibeCompatibility = 0.0;
    for (int i = 0; i < 12; i++) {
      final similarity = 1.0 - (userVibe[i] - spotVibe[i]).abs();
      vibeCompatibility += similarity;
    }
    vibeCompatibility /= 12.0;
    
    // Calculate context factor (average of context features)
    final contextFactor = contextFeatures.reduce((a, b) => a + b) / contextFeatures.length;
    
    // Calculate timing factor (average of timing features)
    final timingFactor = timingFeatures.reduce((a, b) => a + b) / timingFeatures.length;
    
    // Weighted combination (similar to formula-based approach)
    final score = (
      vibeCompatibility * 0.50 +
      contextFactor * 0.30 +
      timingFactor * 0.20
    ).clamp(0.0, 1.0);
    
    return score;
  }
  
  /// Prepare features from training data record
  /// 
  /// Converts a training data record into a feature vector for the model
  /// 
  /// **Parameters:**
  /// - `record`: Training data record from database
  /// 
  /// **Returns:**
  /// Feature vector (39D)
  List<double> prepareFeatures(Map<String, dynamic> record) {
    final features = <double>[];
    
    // Extract user vibe dimensions (12D)
    final userVibeDimensions = record['user_vibe_dimensions'] as Map<String, dynamic>? ?? {};
    for (final dimension in [
      'exploration_eagerness',
      'community_orientation',
      'location_adventurousness',
      'authenticity_preference',
      'trust_network_reliance',
      'temporal_flexibility',
      'energy_preference',
      'novelty_seeking',
      'value_orientation',
      'crowd_tolerance',
      'social_preference',
      'overall_energy',
    ]) {
      features.add((userVibeDimensions[dimension] as num?)?.toDouble() ?? 0.5);
    }
    
    // Extract spot vibe dimensions (12D)
    final spotVibeDimensions = record['spot_vibe_dimensions'] as Map<String, dynamic>? ?? {};
    for (final dimension in [
      'exploration_eagerness',
      'community_orientation',
      'location_adventurousness',
      'authenticity_preference',
      'trust_network_reliance',
      'temporal_flexibility',
      'energy_preference',
      'novelty_seeking',
      'value_orientation',
      'crowd_tolerance',
      'social_preference',
      'overall_energy',
    ]) {
      features.add((spotVibeDimensions[dimension] as num?)?.toDouble() ?? 0.5);
    }
    
    // Extract context features (10 features)
    final contextFeatures = record['context_features'] as Map<String, dynamic>? ?? {};
    features.add((contextFeatures['location_proximity'] as num?)?.toDouble() ?? 0.5);
    features.add((contextFeatures['journey_alignment'] as num?)?.toDouble() ?? 0.5);
    features.add((contextFeatures['user_receptivity'] as num?)?.toDouble() ?? 0.5);
    features.add((contextFeatures['opportunity_availability'] as num?)?.toDouble() ?? 0.5);
    features.add((contextFeatures['network_effects'] as num?)?.toDouble() ?? 0.5);
    features.add((contextFeatures['community_patterns'] as num?)?.toDouble() ?? 0.5);
    // Add 4 more context features (can be extended)
    features.add(0.5); // Placeholder
    features.add(0.5); // Placeholder
    features.add(0.5); // Placeholder
    features.add(0.5); // Placeholder
    
    // Extract timing features (5 features)
    final timingFeatures = record['timing_features'] as Map<String, dynamic>? ?? {};
    features.add((timingFeatures['optimal_time_of_day'] as num?)?.toDouble() ?? 0.5);
    features.add((timingFeatures['optimal_day_of_week'] as num?)?.toDouble() ?? 0.5);
    features.add((timingFeatures['user_patterns'] as num?)?.toDouble() ?? 0.5);
    features.add((timingFeatures['opportunity_timing'] as num?)?.toDouble() ?? 0.5);
    features.add(0.5); // Placeholder for 5th timing feature
    
    // Ensure we have exactly 39 features
    while (features.length < inputSize) {
      features.add(0.5);
    }
    features.removeRange(inputSize, features.length);
    
    return features;
  }
  
  /// Check if model is loaded
  bool get isLoaded => _isLoaded;
  
  /// Get model version
  String? get modelVersion => _modelVersion;
  
  /// Get model loaded timestamp
  DateTime? get modelLoadedAt => _modelLoadedAt;
  
  /// Check if ONNX model is being used
  bool get isUsingOnnx => _useOnnx;
  
  /// Dispose resources
  void dispose() {
    _session?.release();
    _session = null;
    // Note: OrtEnv.instance is a singleton and doesn't need to be released here
    _isLoaded = false;
    _useOnnx = false;
  }
}
