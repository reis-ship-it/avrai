// Outcome Prediction Model for Phase 12: Neural Network Implementation
// Section 3.1: Outcome Prediction Model
// Binary classifier to predict probability of positive outcome

import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:avrai/core/ml/model_version_registry.dart';

/// Outcome Prediction Model
/// 
/// Binary classifier that predicts the probability of a positive outcome
/// before calling a user. This helps filter out low-quality recommendations.
/// 
/// Phase 12 Section 3.1: Outcome Prediction Model
/// 
/// **Model Architecture:**
/// - Input: ~45 features
///   - Base features (39): User vibe (12D) + Spot vibe (12D) + Context (10) + Timing (5)
///   - History features (~6): Past outcome rates, engagement, activity patterns
/// - Architecture: Multi-layer perceptron (MLP)
///   - Input (~45) → Hidden (128) → Hidden (64) → Hidden (32) → Output (1)
/// - Output: Probability of positive outcome (0.0-1.0)
/// 
/// **Training:**
/// - Models are trained in Python (PyTorch/TensorFlow)
/// - Exported to ONNX format for mobile deployment
/// - Models are loaded from assets or downloaded from server
class OutcomePredictionModel {
  static const String _logName = 'OutcomePredictionModel';
  
  // Model configuration
  static const int baseInputSize = 39; // Same as calling score model
  static const int historyFeatureSize = 6; // User history features
  static const int totalInputSize = baseInputSize + historyFeatureSize; // ~45 features
  static const List<int> hiddenSizes = [128, 64, 32];
  static const int outputSize = 1;
  
  // Outcome threshold (only call if probability > threshold)
  static const double outcomeThreshold = 0.7;
  
  // Model state
  bool _isLoaded = false;
  String? _modelVersion;
  DateTime? _modelLoadedAt;
  
  // ONNX runtime
  OrtSession? _session;
  bool _useOnnx = false;
  
  // Model configuration
  static const String defaultModelPath = 'assets/models/outcome_prediction_model.onnx';
  static const String defaultInputName = 'input';
  static const String defaultOutputName = 'output';
  
  /// Initialize and load the outcome prediction model
  /// 
  /// **Parameters:**
  /// - `version`: Model version to load (e.g., 'v1.0-hybrid'). If null, uses active version from registry.
  /// - `modelPath`: Direct path to ONNX model file (overrides version if provided)
  /// 
  /// Returns true if model loaded successfully
  Future<bool> loadModel({String? version, String? modelPath}) async {
    try {
      developer.log('Loading outcome prediction model...', name: _logName);
      
      // Determine which model to load
      String actualModelPath;
      String actualVersion;
      
      if (modelPath != null) {
        // Direct path provided, use it
        actualModelPath = modelPath;
        actualVersion = 'custom';
      } else if (version != null) {
        // Specific version requested
        final versionInfo = ModelVersionRegistry.getOutcomeVersion(version);
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
        final activeVersionInfo = ModelVersionRegistry.getActiveOutcomeVersion();
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
          '✅ Outcome prediction model loaded successfully (ONNX)',
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
        'Error loading outcome prediction model: $e',
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
  
  /// Predict probability of positive outcome
  /// 
  /// **Parameters:**
  /// - `baseFeatures`: Base features (39D) - same as calling score model
  ///   - [0-11]: User vibe dimensions (12D)
  ///   - [12-23]: Spot vibe dimensions (12D)
  ///   - [24-33]: Context features (10 features)
  ///   - [34-38]: Timing features (5 features)
  /// - `historyFeatures`: User history features (~6D)
  ///   - Past positive outcome rate
  ///   - Past negative outcome rate
  ///   - Average engagement score
  ///   - Number of previous interactions
  ///   - Time since last positive outcome (normalized)
  ///   - User activity level
  /// 
  /// **Returns:**
  /// Probability of positive outcome (0.0-1.0)
  Future<double> predict({
    required List<double> baseFeatures,
    required List<double> historyFeatures,
  }) async {
    if (!_isLoaded) {
      await loadModel();
    }
    
    try {
      // Validate input sizes
      if (baseFeatures.length != baseInputSize) {
        throw ArgumentError(
          'Expected $baseInputSize base features, got ${baseFeatures.length}',
        );
      }
      if (historyFeatures.length != historyFeatureSize) {
        throw ArgumentError(
          'Expected $historyFeatureSize history features, got ${historyFeatures.length}',
        );
      }
      
      // Combine features
      final allFeatures = <double>[...baseFeatures, ...historyFeatures];
      
      // Use ONNX model if available, otherwise use rule-based fallback
      if (_useOnnx && _session != null) {
        try {
          return await _onnxPrediction(allFeatures);
        } catch (e, stackTrace) {
          developer.log(
            'ONNX prediction failed, using rule-based fallback: $e',
            name: _logName,
            error: e,
            stackTrace: stackTrace,
          );
          // Fallback to rule-based prediction
          return _ruleBasedPrediction(baseFeatures, historyFeatures);
        }
      } else {
        // No ONNX model loaded, use rule-based fallback
        return _ruleBasedPrediction(baseFeatures, historyFeatures);
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error predicting outcome: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Return neutral probability on error
      return 0.5;
    }
  }
  
  /// Check if outcome probability is above threshold
  /// 
  /// Only call user if probability > threshold (default: 0.7)
  Future<bool> shouldCall({
    required List<double> baseFeatures,
    required List<double> historyFeatures,
  }) async {
    final probability = await predict(
      baseFeatures: baseFeatures,
      historyFeatures: historyFeatures,
    );
    return probability > outcomeThreshold;
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
      
      // Create input tensor: shape [1, totalInputSize] (batch size 1, features)
      final inputShape = [1, features.length];
      
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
      double probability;
      if (outputValue is List) {
        probability = (outputValue.isNotEmpty && outputValue.first is num)
            ? (outputValue.first as num).toDouble()
            : 0.5;
      } else if (outputValue is num) {
        probability = outputValue.toDouble();
      } else {
        throw StateError('Unexpected output type: ${outputValue.runtimeType}');
      }
      
      // Clean up
      inputTensor.release();
      runOptions.release();
      for (final output in outputs) {
        output?.release();
      }
      
      // Clamp probability to [0.0, 1.0]
      return probability.clamp(0.0, 1.0);
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
  double _ruleBasedPrediction(
    List<double> baseFeatures,
    List<double> historyFeatures,
  ) {
    // Extract base feature groups
    final userVibe = baseFeatures.sublist(0, 12);
    final spotVibe = baseFeatures.sublist(12, 24);
    final contextFeatures = baseFeatures.sublist(24, 34);
    final timingFeatures = baseFeatures.sublist(34, 39);
    
    // Calculate vibe compatibility
    double vibeCompatibility = 0.0;
    for (int i = 0; i < 12; i++) {
      final similarity = 1.0 - (userVibe[i] - spotVibe[i]).abs();
      vibeCompatibility += similarity;
    }
    vibeCompatibility /= 12.0;
    
    // Calculate context factor
    final contextFactor = contextFeatures.reduce((a, b) => a + b) / contextFeatures.length;
    
    // Calculate timing factor
    final timingFactor = timingFeatures.reduce((a, b) => a + b) / timingFeatures.length;
    
    // Extract history features
    final pastPositiveRate = historyFeatures.isNotEmpty ? historyFeatures[0] : 0.5;
    final averageEngagement = historyFeatures.length > 2 ? historyFeatures[2] : 0.5;
    
    // Weighted combination
    final score = (
      vibeCompatibility * 0.30 +
      contextFactor * 0.20 +
      timingFactor * 0.15 +
      pastPositiveRate * 0.25 +
      averageEngagement * 0.10
    ).clamp(0.0, 1.0);
    
    return score;
  }
  
  /// Check if model is loaded
  bool get isLoaded => _isLoaded;
  
  /// Get model version
  String? get modelVersion => _modelVersion;
  
  /// Get model loaded timestamp
  DateTime? get modelLoadedAt => _modelLoadedAt;
  
  /// Check if ONNX model is being used
  bool get isUsingOnnx => _useOnnx;
  
  /// Get outcome threshold
  double get threshold => outcomeThreshold;
  
  /// Dispose resources
  void dispose() {
    _session?.release();
    _session = null;
    _isLoaded = false;
    _useOnnx = false;
  }
}
