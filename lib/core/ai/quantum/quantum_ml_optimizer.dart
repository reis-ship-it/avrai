// Quantum ML Optimizer
//
// ML-based optimization service for quantum state calculations
// Optimizes weights, thresholds, and measurement basis
// Part of Medium Priority Improvements
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';

/// Data source for superposition
enum QuantumDataSource {
  personality,
  behavioral,
  relationship,
  temporal,
  contextual,
}

/// Use case for optimization
enum QuantumUseCase {
  matching,
  recommendation,
  compatibility,
  prediction,
  analysis,
}

/// ML-based quantum optimization service
///
/// Uses machine learning to optimize:
/// - Superposition weights for data source combination
/// - Compatibility thresholds for context-specific matching
/// - Measurement basis for optimal state measurement
///
/// **Model Input:**
/// - Quantum entity state (12 dimensions)
/// - Use case context
/// - Data sources available
///
/// **Model Output:**
/// - Optimal weights for data source superposition
/// - Optimal compatibility threshold
/// - Optimal measurement basis
///
/// **Fallback:**
/// - If ML model unavailable, uses default/hardcoded values
class QuantumMLOptimizer {
  static const String _logName = 'QuantumMLOptimizer';

  // Model configuration
  static const int inputSize = 12; // 12 avrai dimensions
  static const String defaultModelPath =
      'assets/models/quantum_optimization_model.onnx';
  static const String defaultInputName = 'input';

  // Model state
  bool _isLoaded = false;
  bool _useOnnx = false;
  OrtSession? _session;

  // Cache for combined model output to avoid multiple calls
  // Format: [weights(5), threshold(1), basis(12)] = 18 values total
  Map<String, List<double>>? _outputCache;
  String? _lastCacheKey;

  /// Whether the ONNX model is loaded and being used
  bool get isUsingOnnx => _useOnnx;

  /// Whether initialization has completed (model or fallback)
  bool get isLoaded => _isLoaded;

  /// Get diagnostic info about this model's ONNX status
  Map<String, dynamic> getDiagnostics() {
    return {
      'model': 'quantum_optimization',
      'isLoaded': _isLoaded,
      'isUsingOnnx': _useOnnx,
      'modelPath': defaultModelPath,
      'status': _useOnnx
          ? 'ONNX model active'
          : (_isLoaded ? 'Default fallback' : 'Not initialized'),
    };
  }

  /// Initialize and load ML model
  Future<bool> initialize() async {
    if (_isLoaded) {
      return _useOnnx;
    }

    try {
      developer.log(
        'Loading quantum optimization ML model from $defaultModelPath',
        name: _logName,
      );

      // Load model from assets
      final ByteData modelData;
      try {
        modelData = await rootBundle.load(defaultModelPath);
      } catch (e) {
        developer.log(
          'Model file not found at $defaultModelPath. Using default values: $e',
          name: _logName,
        );
        _useOnnx = false;
        _isLoaded = true;
        return false; // Fallback to defaults
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
          '✅ Quantum optimization ML model loaded successfully (ONNX)',
          name: _logName,
        );

        return true;
      } catch (e, stackTrace) {
        developer.log(
          'Error creating ONNX session, using default values: $e',
          error: e,
          stackTrace: stackTrace,
          name: _logName,
        );
        _useOnnx = false;
        _isLoaded = true;
        return false; // Fallback to defaults
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to initialize quantum optimization ML model: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      _useOnnx = false;
      _isLoaded = true;
      return false;
    }
  }

  /// Optimize superposition weights for data sources
  ///
  /// **Returns:**
  /// - Map from data source to optimal weight (0.0-1.0)
  /// - Weights are normalized to sum to 1.0
  ///
  /// **Parameters:**
  /// - `state`: Quantum entity state
  /// - `sources`: Available data sources
  /// - `useCase`: Use case context
  Future<Map<QuantumDataSource, double>> optimizeSuperpositionWeights({
    required QuantumEntityState state,
    required List<QuantumDataSource> sources,
    QuantumUseCase useCase = QuantumUseCase.matching,
  }) async {
    if (!_isLoaded) {
      await initialize();
    }

    try {
      if (_useOnnx && _session != null) {
        // ML-based optimization
        final weights = await _onnxOptimizeWeights(
          state: state,
          sources: sources,
          useCase: useCase,
        );

        if (weights != null) {
          return weights;
        }
      }

      // Fallback to default weights
      return _defaultSuperpositionWeights(sources, useCase);
    } catch (e, stackTrace) {
      developer.log(
        'Error optimizing superposition weights, using defaults: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return _defaultSuperpositionWeights(sources, useCase);
    }
  }

  /// Optimize compatibility threshold for use case
  ///
  /// **Returns:**
  /// - Optimal threshold (0.0-1.0) for the use case
  ///
  /// **Parameters:**
  /// - `state`: Quantum entity state
  /// - `useCase`: Use case context
  Future<double> optimizeCompatibilityThreshold({
    required QuantumEntityState state,
    required QuantumUseCase useCase,
  }) async {
    if (!_isLoaded) {
      await initialize();
    }

    try {
      if (_useOnnx && _session != null) {
        // ML-based optimization
        final threshold = await _onnxOptimizeThreshold(
          state: state,
          useCase: useCase,
        );

        if (threshold != null) {
          return threshold.clamp(0.0, 1.0);
        }
      }

      // Fallback to default thresholds
      return _defaultCompatibilityThreshold(useCase);
    } catch (e, stackTrace) {
      developer.log(
        'Error optimizing compatibility threshold, using default: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return _defaultCompatibilityThreshold(useCase);
    }
  }

  /// Predict optimal measurement basis for state
  ///
  /// **Returns:**
  /// - Optimal measurement basis (list of dimension indices to measure)
  ///
  /// **Parameters:**
  /// - `state`: Quantum entity state
  /// - `useCase`: Use case context
  /// - `maxDimensions`: Maximum number of dimensions to measure
  Future<List<int>> predictOptimalMeasurementBasis({
    required QuantumEntityState state,
    required QuantumUseCase useCase,
    int maxDimensions = 5,
  }) async {
    if (!_isLoaded) {
      await initialize();
    }

    try {
      if (_useOnnx && _session != null) {
        // ML-based prediction
        final basis = await _onnxPredictBasis(
          state: state,
          useCase: useCase,
          maxDimensions: maxDimensions,
        );

        if (basis != null && basis.isNotEmpty) {
          return basis;
        }
      }

      // Fallback to default basis (top dimensions by magnitude)
      return _defaultMeasurementBasis(state, maxDimensions);
    } catch (e, stackTrace) {
      developer.log(
        'Error predicting measurement basis, using default: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return _defaultMeasurementBasis(state, maxDimensions);
    }
  }

  /// Get combined model output (cached to avoid multiple calls)
  /// Output format: [weights(5), threshold(1), basis(12)] = 18 values total
  Future<List<double>?> _getCombinedModelOutput({
    required QuantumEntityState state,
    required QuantumUseCase useCase,
  }) async {
    if (_session == null) return null;

    // Create cache key
    final cacheKey = '${state.personalityState.hashCode}_${useCase.index}';

    // Return cached result if available
    if (_lastCacheKey == cacheKey && _outputCache != null) {
      return _outputCache![cacheKey];
    }

    try {
      // Prepare input: 12 dimensions + use case encoding
      final inputValues = Float32List(inputSize + 1);

      // Add personality dimensions
      final personalityValues = state.personalityState.values.toList();
      for (int i = 0; i < inputSize && i < personalityValues.length; i++) {
        inputValues[i] = personalityValues[i].clamp(0.0, 1.0).toDouble();
      }

      // Add use case encoding (0.0-1.0)
      inputValues[inputSize] = useCase.index / QuantumUseCase.values.length;

      // Create input tensor
      final inputTensor = OrtValueTensor.createTensorWithDataList(
        inputValues,
        [1, inputSize + 1],
      );

      // Run inference
      final inputs = {defaultInputName: inputTensor};
      final runOptions = OrtRunOptions();
      final outputs = _session!.run(runOptions, inputs);

      // Extract combined output
      final outputTensor = outputs.isNotEmpty ? outputs[0] : null;
      if (outputTensor == null) {
        inputTensor.release();
        runOptions.release();
        return null;
      }

      final outputValue = outputTensor.value;
      final outputData = outputValue is List
          ? outputValue.map((v) => (v as num).toDouble()).toList()
          : <double>[];

      // Cache the result
      _outputCache ??= {};
      _outputCache![cacheKey] = outputData;
      _lastCacheKey = cacheKey;

      inputTensor.release();
      runOptions.release();
      outputTensor.release();

      return outputData;
    } catch (e, stackTrace) {
      developer.log(
        'Error in ONNX model inference: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// ONNX inference for weight optimization
  /// Uses combined model output: first 5 values = weights
  Future<Map<QuantumDataSource, double>?> _onnxOptimizeWeights({
    required QuantumEntityState state,
    required List<QuantumDataSource> sources,
    required QuantumUseCase useCase,
  }) async {
    if (_session == null) return null;

    try {
      // Get combined model output
      final outputData = await _getCombinedModelOutput(
        state: state,
        useCase: useCase,
      );

      if (outputData == null || outputData.length < 5) {
        return null;
      }

      // Extract weights: first 5 values
      final weightsData = outputData.sublist(0, 5);

      // Map output to data sources
      final weights = <QuantumDataSource, double>{};
      final defaultWeight = 1.0 / sources.length;

      for (int i = 0; i < sources.length && i < weightsData.length; i++) {
        weights[sources[i]] = weightsData[i].clamp(0.0, 1.0);
      }

      // Normalize weights
      final total = weights.values.fold(0.0, (a, b) => a + b);
      if (total > 0.0) {
        for (final key in weights.keys.toList()) {
          weights[key] = weights[key]! / total;
        }
      } else {
        // If all weights are 0, use equal weights
        for (final source in sources) {
          weights[source] = defaultWeight;
        }
      }

      return weights;
    } catch (e, stackTrace) {
      developer.log(
        'Error in ONNX weight optimization: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// ONNX inference for threshold optimization
  /// Uses combined model output: value at index 5 = threshold
  Future<double?> _onnxOptimizeThreshold({
    required QuantumEntityState state,
    required QuantumUseCase useCase,
  }) async {
    if (_session == null) return null;

    try {
      // Get combined model output
      final outputData = await _getCombinedModelOutput(
        state: state,
        useCase: useCase,
      );

      if (outputData == null || outputData.length < 6) {
        return null;
      }

      // Extract threshold: value at index 5 (after 5 weights)
      final threshold = outputData[5].clamp(0.0, 1.0);

      return threshold;
    } catch (e, stackTrace) {
      developer.log(
        'Error in ONNX threshold optimization: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// ONNX inference for measurement basis prediction
  /// Uses combined model output: values at indices 6-17 = basis importance (12 values)
  Future<List<int>?> _onnxPredictBasis({
    required QuantumEntityState state,
    required QuantumUseCase useCase,
    required int maxDimensions,
  }) async {
    if (_session == null) return null;

    try {
      // Get combined model output
      final outputData = await _getCombinedModelOutput(
        state: state,
        useCase: useCase,
      );

      if (outputData == null || outputData.length < 18) {
        return null;
      }

      // Extract basis importance: values at indices 6-17 (after 5 weights + 1 threshold)
      final basisData = outputData.sublist(6, 18);

      // Select top dimensions by importance
      final dimensionScores = <int, double>{};
      for (int i = 0; i < basisData.length && i < inputSize; i++) {
        dimensionScores[i] = basisData[i];
      }

      // Sort by score and take top N
      final sortedDimensions = dimensionScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final basis =
          sortedDimensions.take(maxDimensions).map((e) => e.key).toList();

      return basis;
    } catch (e, stackTrace) {
      developer.log(
        'Error in ONNX basis prediction: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// Default superposition weights (fallback)
  Map<QuantumDataSource, double> _defaultSuperpositionWeights(
    List<QuantumDataSource> sources,
    QuantumUseCase useCase,
  ) {
    // Default weights based on use case
    final defaultWeights = <QuantumDataSource, double>{
      QuantumDataSource.personality: 0.4,
      QuantumDataSource.behavioral: 0.3,
      QuantumDataSource.relationship: 0.2,
      QuantumDataSource.temporal: 0.05,
      QuantumDataSource.contextual: 0.05,
    };

    // Adjust based on use case
    switch (useCase) {
      case QuantumUseCase.matching:
        defaultWeights[QuantumDataSource.personality] = 0.5;
        defaultWeights[QuantumDataSource.behavioral] = 0.3;
        defaultWeights[QuantumDataSource.relationship] = 0.2;
        break;
      case QuantumUseCase.recommendation:
        defaultWeights[QuantumDataSource.personality] = 0.4;
        defaultWeights[QuantumDataSource.contextual] = 0.3;
        defaultWeights[QuantumDataSource.behavioral] = 0.3;
        break;
      case QuantumUseCase.compatibility:
        defaultWeights[QuantumDataSource.personality] = 0.4;
        defaultWeights[QuantumDataSource.relationship] = 0.4;
        defaultWeights[QuantumDataSource.behavioral] = 0.2;
        break;
      case QuantumUseCase.prediction:
        defaultWeights[QuantumDataSource.temporal] = 0.4;
        defaultWeights[QuantumDataSource.behavioral] = 0.3;
        defaultWeights[QuantumDataSource.personality] = 0.3;
        break;
      case QuantumUseCase.analysis:
        defaultWeights[QuantumDataSource.personality] = 0.3;
        defaultWeights[QuantumDataSource.behavioral] = 0.3;
        defaultWeights[QuantumDataSource.relationship] = 0.2;
        defaultWeights[QuantumDataSource.temporal] = 0.1;
        defaultWeights[QuantumDataSource.contextual] = 0.1;
        break;
    }

    // Filter to available sources and normalize
    final availableWeights = <QuantumDataSource, double>{};
    double total = 0.0;

    for (final source in sources) {
      final weight = defaultWeights[source] ?? 0.0;
      if (weight > 0.0) {
        availableWeights[source] = weight;
        total += weight;
      }
    }

    // Normalize
    if (total > 0.0) {
      for (final key in availableWeights.keys.toList()) {
        availableWeights[key] = availableWeights[key]! / total;
      }
    } else {
      // Equal weights if no defaults
      final equalWeight = 1.0 / sources.length;
      for (final source in sources) {
        availableWeights[source] = equalWeight;
      }
    }

    return availableWeights;
  }

  /// Default compatibility threshold (fallback)
  double _defaultCompatibilityThreshold(QuantumUseCase useCase) {
    switch (useCase) {
      case QuantumUseCase.matching:
        return 0.7; // High threshold for matching
      case QuantumUseCase.recommendation:
        return 0.6; // Medium threshold for recommendations
      case QuantumUseCase.compatibility:
        return 0.65; // Medium-high threshold
      case QuantumUseCase.prediction:
        return 0.5; // Lower threshold for predictions
      case QuantumUseCase.analysis:
        return 0.55; // Medium threshold for analysis
    }
  }

  /// Default measurement basis (fallback)
  ///
  /// Returns top dimensions by magnitude
  List<int> _defaultMeasurementBasis(
      QuantumEntityState state, int maxDimensions) {
    final dimensionScores = <int, double>{};

    final personalityValues = state.personalityState.values.toList();
    final personalityKeys = state.personalityState.keys.toList();

    for (int i = 0;
        i < personalityValues.length && i < personalityKeys.length;
        i++) {
      dimensionScores[i] = personalityValues[i].abs();
    }

    // Sort by score and take top N
    final sortedDimensions = dimensionScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedDimensions.take(maxDimensions).map((e) => e.key).toList();
  }
}
