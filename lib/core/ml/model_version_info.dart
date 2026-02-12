// Model Version Info for Phase 12: Neural Network Implementation
// Section 3.2.2: Model Versioning
// Data structure for model version metadata

/// Model Status
enum ModelStatus {
  staging, // In testing/A/B testing
  active, // Active in production
  deprecated, // No longer used but kept for rollback
  archived, // Archived, not available for use
}

/// Model Version Information
/// 
/// Contains metadata about a specific model version including:
/// - Version identifier
/// - Model file path
/// - Training data source
/// - Performance metrics
/// - Status and configuration
class ModelVersionInfo {
  /// Version identifier (e.g., 'v1.0-hybrid', 'v2.0-real')
  final String version;
  
  /// Path to ONNX model file
  final String modelPath;
  
  /// Default weight for this version (0.0-1.0)
  final double defaultWeight;
  
  /// Current weight (can be overridden by remote config)
  double? currentWeight;
  
  /// Data source used for training ('synthetic', 'hybrid_big_five', 'real_data')
  final String dataSource;
  
  /// Date when model was trained
  final DateTime trainedDate;
  
  /// Current status of this version
  final ModelStatus status;
  
  /// Description of this version
  final String description;
  
  /// Training metrics (loss, accuracy, etc.)
  final Map<String, dynamic> trainingMetrics;
  
  /// A/B test traffic percentage (0.0-1.0)
  /// null = not in A/B test, 1.0 = full rollout
  double? abTestTrafficPercentage;
  
  /// A/B test start date
  DateTime? abTestStartDate;
  
  /// Performance metrics from A/B testing
  final Map<String, dynamic> performanceMetrics;
  
  ModelVersionInfo({
    required this.version,
    required this.modelPath,
    required this.defaultWeight,
    this.currentWeight,
    required this.dataSource,
    required this.trainedDate,
    required this.status,
    required this.description,
    this.trainingMetrics = const {},
    this.abTestTrafficPercentage,
    this.abTestStartDate,
    this.performanceMetrics = const {},
  });
  
  /// Create a copy with updated fields
  ModelVersionInfo copyWith({
    String? version,
    String? modelPath,
    double? defaultWeight,
    double? currentWeight,
    String? dataSource,
    DateTime? trainedDate,
    ModelStatus? status,
    String? description,
    Map<String, dynamic>? trainingMetrics,
    double? abTestTrafficPercentage,
    DateTime? abTestStartDate,
    Map<String, dynamic>? performanceMetrics,
  }) {
    return ModelVersionInfo(
      version: version ?? this.version,
      modelPath: modelPath ?? this.modelPath,
      defaultWeight: defaultWeight ?? this.defaultWeight,
      currentWeight: currentWeight ?? this.currentWeight,
      dataSource: dataSource ?? this.dataSource,
      trainedDate: trainedDate ?? this.trainedDate,
      status: status ?? this.status,
      description: description ?? this.description,
      trainingMetrics: trainingMetrics ?? this.trainingMetrics,
      abTestTrafficPercentage: abTestTrafficPercentage ?? this.abTestTrafficPercentage,
      abTestStartDate: abTestStartDate ?? this.abTestStartDate,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
    );
  }
  
  /// Get effective weight (current weight if set, otherwise default)
  double get effectiveWeight => currentWeight ?? defaultWeight;
  
  /// Check if version is active in production
  bool get isActive => status == ModelStatus.active;
  
  /// Check if version is in A/B testing
  bool get isInABTest => abTestTrafficPercentage != null && abTestTrafficPercentage! > 0.0;
  
  /// Check if version is fully rolled out
  bool get isFullyRolledOut => abTestTrafficPercentage == 1.0;
}
