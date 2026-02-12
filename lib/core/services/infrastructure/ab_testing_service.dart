// A/B Testing Service
//
// Phase 4.1: A/B Testing for list suggestion optimization
//
// Purpose: Run experiments on list generation parameters

import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:get_it/get_it.dart';

/// A/B Testing Service
///
/// Manages A/B experiments for optimizing list suggestions.
/// Enables testing different thresholds, algorithms, and UI variants.
///
/// Part of Phase 4.1: A/B Testing

class ABTestingService {
  static const String _logName = 'ABTestingService';
  static const String _storagePrefix = 'ab_experiment_';

  final StorageService _storageService;
  final math.Random _random = math.Random();

  /// Active experiments
  final Map<String, ABExperiment> _experiments = {};

  /// User variant assignments (cached)
  final Map<String, Map<String, String>> _userAssignments = {};

  ABTestingService({
    StorageService? storageService,
  }) : _storageService = storageService ?? GetIt.instance<StorageService>();

  /// Register an experiment
  void registerExperiment(ABExperiment experiment) {
    _experiments[experiment.id] = experiment;
    developer.log(
      'Registered experiment: ${experiment.id} with ${experiment.variants.length} variants',
      name: _logName,
    );
  }

  /// Get the variant for a user in an experiment
  ///
  /// Returns null if experiment not found or not active
  Future<String?> getVariant({
    required String experimentId,
    required String userId,
  }) async {
    final experiment = _experiments[experimentId];
    if (experiment == null || !experiment.isActive) {
      return null;
    }

    // Check cached assignment
    if (_userAssignments[userId]?.containsKey(experimentId) == true) {
      return _userAssignments[userId]![experimentId];
    }

    // Check stored assignment
    final storedVariant = await _getStoredVariant(userId, experimentId);
    if (storedVariant != null) {
      _cacheAssignment(userId, experimentId, storedVariant);
      return storedVariant;
    }

    // Assign new variant
    final variant = _assignVariant(userId, experiment);
    await _storeVariant(userId, experimentId, variant);
    _cacheAssignment(userId, experimentId, variant);

    developer.log(
      'Assigned user $userId to variant $variant in experiment $experimentId',
      name: _logName,
    );

    return variant;
  }

  /// Get experiment parameter value for a user
  ///
  /// Returns the parameter value for the user's assigned variant
  Future<T?> getParameterValue<T>({
    required String experimentId,
    required String parameterName,
    required String userId,
  }) async {
    final variant = await getVariant(experimentId: experimentId, userId: userId);
    if (variant == null) return null;

    final experiment = _experiments[experimentId];
    if (experiment == null) return null;

    final variantConfig = experiment.variants.firstWhere(
      (v) => v.id == variant,
      orElse: () => experiment.variants.first,
    );

    return variantConfig.parameters[parameterName] as T?;
  }

  /// Track a conversion event for an experiment
  Future<void> trackConversion({
    required String experimentId,
    required String userId,
    required String eventName,
    Map<String, dynamic>? metadata,
  }) async {
    final variant = await getVariant(experimentId: experimentId, userId: userId);
    if (variant == null) return;

    developer.log(
      'Tracked conversion: $eventName for experiment $experimentId, variant $variant',
      name: _logName,
    );

    // TODO(Phase 4.1): Send to analytics service
  }

  /// Check if user is in a specific variant
  Future<bool> isInVariant({
    required String experimentId,
    required String userId,
    required String variantId,
  }) async {
    final assignedVariant = await getVariant(
      experimentId: experimentId,
      userId: userId,
    );
    return assignedVariant == variantId;
  }

  /// Assign a variant based on experiment traffic allocation
  String _assignVariant(String userId, ABExperiment experiment) {
    // Use user ID hash for consistent assignment
    final hash = (userId.hashCode + experiment.id.hashCode).abs();
    final bucket = hash % 100;

    // Check if user should be in experiment based on traffic allocation
    if (bucket >= experiment.trafficPercentage) {
      return experiment.controlVariant;
    }

    // Assign to variant based on weights
    final totalWeight = experiment.variants.fold<double>(
      0,
      (sum, v) => sum + v.weight,
    );

    final randomValue = _random.nextDouble() * totalWeight;
    double cumulative = 0;

    for (final variant in experiment.variants) {
      cumulative += variant.weight;
      if (randomValue <= cumulative) {
        return variant.id;
      }
    }

    return experiment.controlVariant;
  }

  void _cacheAssignment(String userId, String experimentId, String variant) {
    _userAssignments[userId] ??= {};
    _userAssignments[userId]![experimentId] = variant;
  }

  Future<String?> _getStoredVariant(String userId, String experimentId) async {
    final key = '$_storagePrefix${userId}_$experimentId';
    return _storageService.getString(key);
  }

  Future<void> _storeVariant(
    String userId,
    String experimentId,
    String variant,
  ) async {
    final key = '$_storagePrefix${userId}_$experimentId';
    await _storageService.setString(key, variant);
  }

  /// Get all active experiments
  List<ABExperiment> get activeExperiments {
    return _experiments.values.where((e) => e.isActive).toList();
  }

  /// Get experiment by ID
  ABExperiment? getExperiment(String id) => _experiments[id];
}

/// A/B Experiment Configuration
class ABExperiment {
  /// Unique identifier for the experiment
  final String id;

  /// Human-readable name
  final String name;

  /// Description of what's being tested
  final String description;

  /// Variants in this experiment
  final List<ExperimentVariant> variants;

  /// Control variant ID (for comparison)
  final String controlVariant;

  /// Percentage of traffic to include (0-100)
  final double trafficPercentage;

  /// Whether the experiment is currently active
  final bool isActive;

  /// Start date for the experiment
  final DateTime? startDate;

  /// End date for the experiment
  final DateTime? endDate;

  const ABExperiment({
    required this.id,
    required this.name,
    required this.description,
    required this.variants,
    required this.controlVariant,
    this.trafficPercentage = 100.0,
    this.isActive = true,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'variants': variants.map((v) => v.toJson()).toList(),
        'controlVariant': controlVariant,
        'trafficPercentage': trafficPercentage,
        'isActive': isActive,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      };

  factory ABExperiment.fromJson(Map<String, dynamic> json) {
    return ABExperiment(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      variants: (json['variants'] as List)
          .map((v) => ExperimentVariant.fromJson(v as Map<String, dynamic>))
          .toList(),
      controlVariant: json['controlVariant'] as String,
      trafficPercentage: (json['trafficPercentage'] as num?)?.toDouble() ?? 100.0,
      isActive: json['isActive'] as bool? ?? true,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
    );
  }
}

/// Variant in an A/B experiment
class ExperimentVariant {
  /// Unique identifier for the variant
  final String id;

  /// Human-readable name
  final String name;

  /// Description of this variant
  final String description;

  /// Weight for random assignment (higher = more likely)
  final double weight;

  /// Parameters specific to this variant
  final Map<String, dynamic> parameters;

  const ExperimentVariant({
    required this.id,
    required this.name,
    this.description = '',
    this.weight = 1.0,
    this.parameters = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'weight': weight,
        'parameters': parameters,
      };

  factory ExperimentVariant.fromJson(Map<String, dynamic> json) {
    return ExperimentVariant(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      parameters: Map<String, dynamic>.from(json['parameters'] as Map? ?? {}),
    );
  }
}

/// Predefined experiments for list suggestions
class ListExperiments {
  /// Experiment: Test different minimum compatibility thresholds
  static final compatibilityThreshold = ABExperiment(
    id: 'list_compatibility_threshold',
    name: 'Compatibility Threshold',
    description: 'Test different minimum compatibility scores for list inclusion',
    controlVariant: 'control',
    variants: [
      const ExperimentVariant(
        id: 'control',
        name: 'Control (0.4)',
        parameters: {'minCompatibilityScore': 0.4},
      ),
      const ExperimentVariant(
        id: 'lower',
        name: 'Lower (0.3)',
        parameters: {'minCompatibilityScore': 0.3},
      ),
      const ExperimentVariant(
        id: 'higher',
        name: 'Higher (0.5)',
        parameters: {'minCompatibilityScore': 0.5},
      ),
    ],
  );

  /// Experiment: Test different list sizes
  static final listSize = ABExperiment(
    id: 'list_size',
    name: 'List Size',
    description: 'Test different maximum places per list',
    controlVariant: 'control',
    variants: [
      const ExperimentVariant(
        id: 'control',
        name: 'Control (8)',
        parameters: {'maxPlacesPerList': 8},
      ),
      const ExperimentVariant(
        id: 'smaller',
        name: 'Smaller (5)',
        parameters: {'maxPlacesPerList': 5},
      ),
      const ExperimentVariant(
        id: 'larger',
        name: 'Larger (12)',
        parameters: {'maxPlacesPerList': 12},
      ),
    ],
  );

  /// Experiment: Test different frequency of suggestions
  static final suggestionFrequency = ABExperiment(
    id: 'list_suggestion_frequency',
    name: 'Suggestion Frequency',
    description: 'Test different intervals between list suggestions',
    controlVariant: 'control',
    variants: [
      const ExperimentVariant(
        id: 'control',
        name: 'Control (8h)',
        parameters: {'minIntervalHours': 8},
      ),
      const ExperimentVariant(
        id: 'more_frequent',
        name: 'More Frequent (4h)',
        parameters: {'minIntervalHours': 4},
      ),
      const ExperimentVariant(
        id: 'less_frequent',
        name: 'Less Frequent (12h)',
        parameters: {'minIntervalHours': 12},
      ),
    ],
  );

  /// All predefined experiments
  static List<ABExperiment> get all => [
        compatibilityThreshold,
        listSize,
        suggestionFrequency,
      ];
}
