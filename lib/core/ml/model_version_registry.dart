// Model Version Registry for Phase 12: Neural Network Implementation
// Section 3.2.2: Model Versioning
// Manages model versions, metadata, and configuration

import 'package:avrai/core/ml/model_version_info.dart';

/// Model Version Registry
/// 
/// Central registry for all neural network model versions.
/// Tracks available versions, active version, and version-specific configurations.
class ModelVersionRegistry {
  
  /// Registry of all available model versions
  /// 
  /// Key: Version string (e.g., 'v1.0-synthetic', 'v2.0-real')
  /// Value: Model version information
  static final Map<String, ModelVersionInfo> _versions = {
    'v1.0-hybrid': ModelVersionInfo(
      version: 'v1.0-hybrid',
      modelPath: 'assets/models/calling_score_model_v1_hybrid.onnx',
      defaultWeight: 0.1, // Start with low weight for hybrid model
      dataSource: 'hybrid_big_five',
      trainedDate: DateTime(2025, 12, 28),
      status: ModelStatus.staging,
      description: 'v1.0 hybrid model (Big Five personality + synthetic spots/context/timing)',
      trainingMetrics: {
        'test_loss': 0.0267,
        'early_stopping_epoch': 42,
        'training_samples': 10000,
      },
    ),
    'v1.1-hybrid': ModelVersionInfo(
      version: 'v1.1-hybrid',
      modelPath: 'assets/models/optimized/calling_score_model_v1_1_batch_128.onnx',
      defaultWeight: 0.1, // Start with low weight, will increase after A/B test validation
      dataSource: 'hybrid_big_five',
      trainedDate: DateTime(2025, 12, 28),
      status: ModelStatus.staging,
      description: 'v1.1 optimized hybrid model (batch_size=128, +3.75% improvement vs v1.0)',
      trainingMetrics: {
        'test_loss': 0.0257,
        'val_loss': 0.0279,
        'improvement_vs_baseline': 3.75,
        'best_epoch': 22,
        'training_time_seconds': 5.4,
        'model_size_kb': 10.0,
        'parameters': 13248,
        'training_samples': 10000,
        'optimization_date': '2025-12-28',
        'hyperparameters': {
          'learning_rate': 0.001,
          'batch_size': 128,
          'architecture': [128, 64],
          'dropout': 0.2,
        },
      },
    ),
  };
  
  /// Registry for outcome prediction models
  static final Map<String, ModelVersionInfo> _outcomeVersions = {
    'v1.0-hybrid': ModelVersionInfo(
      version: 'v1.0-hybrid',
      modelPath: 'assets/models/outcome_prediction_model_v1_hybrid.onnx',
      defaultWeight: 0.1, // Start with low weight
      dataSource: 'hybrid_big_five',
      trainedDate: DateTime(2025, 12, 28),
      status: ModelStatus.staging,
      description: 'v1.0 hybrid outcome prediction model',
      trainingMetrics: {
        'test_accuracy': 0.8807,
        'test_loss': 0.6882,
        'early_stopping_epoch': 24,
        'training_samples': 10000,
      },
    ),
  };
  
  /// Active version for calling score model
  static String _activeCallingScoreVersion = 'v1.0-hybrid';
  
  /// Active version for outcome prediction model
  static String _activeOutcomeVersion = 'v1.0-hybrid';
  
  /// Get active calling score version
  static String get activeCallingScoreVersion => _activeCallingScoreVersion;
  
  /// Get active outcome prediction version
  static String get activeOutcomeVersion => _activeOutcomeVersion;
  
  /// Get version info for calling score model
  static ModelVersionInfo? getCallingScoreVersion(String version) {
    return _versions[version];
  }
  
  /// Get version info for outcome prediction model
  static ModelVersionInfo? getOutcomeVersion(String version) {
    return _outcomeVersions[version];
  }
  
  /// Get active calling score version info
  static ModelVersionInfo? getActiveCallingScoreVersion() {
    return _versions[_activeCallingScoreVersion];
  }
  
  /// Get active outcome prediction version info
  static ModelVersionInfo? getActiveOutcomeVersion() {
    return _outcomeVersions[_activeOutcomeVersion];
  }
  
  /// Get all available calling score versions
  static List<String> getAvailableCallingScoreVersions() {
    return _versions.keys.toList()..sort();
  }
  
  /// Get all available outcome prediction versions
  static List<String> getAvailableOutcomeVersions() {
    return _outcomeVersions.keys.toList()..sort();
  }
  
  /// Register a new calling score model version
  static void registerCallingScoreVersion(ModelVersionInfo versionInfo) {
    _versions[versionInfo.version] = versionInfo;
  }
  
  /// Register a new outcome prediction model version
  static void registerOutcomeVersion(ModelVersionInfo versionInfo) {
    _outcomeVersions[versionInfo.version] = versionInfo;
  }
  
  /// Set active calling score version
  /// 
  /// Returns true if version exists and was set, false otherwise
  static bool setActiveCallingScoreVersion(String version) {
    if (_versions.containsKey(version)) {
      _activeCallingScoreVersion = version;
      return true;
    }
    return false;
  }
  
  /// Set active outcome prediction version
  /// 
  /// Returns true if version exists and was set, false otherwise
  static bool setActiveOutcomeVersion(String version) {
    if (_outcomeVersions.containsKey(version)) {
      _activeOutcomeVersion = version;
      return true;
    }
    return false;
  }
  
  /// Get version weight (can be overridden by remote config)
  static double getVersionWeight(String version, {String modelType = 'calling_score'}) {
    final versionInfo = modelType == 'calling_score'
        ? _versions[version]
        : _outcomeVersions[version];
    
    if (versionInfo == null) {
      return 0.0; // Default to 0 if version not found
    }
    
    // Return configured weight (can be overridden by remote config later)
    return versionInfo.currentWeight ?? versionInfo.defaultWeight;
  }
  
  /// Check if version exists
  static bool hasVersion(String version, {String modelType = 'calling_score'}) {
    return modelType == 'calling_score'
        ? _versions.containsKey(version)
        : _outcomeVersions.containsKey(version);
  }
}
