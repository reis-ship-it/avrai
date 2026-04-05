import 'dart:developer' as developer;
import 'package:avrai_core/models/community/community_validation.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/user/unified_list.dart';
import 'package:avrai_runtime_os/services/community/community_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat, StorageService;
import 'package:get_it/get_it.dart';

/// OUR_GUTS.md: "Community, Not Just Places" - Community-driven quality assurance
/// Service for validating spots and lists through community and expert curation
class CommunityValidationService {
  static const String _logName = 'CommunityValidationService';

  // Storage keys
  static const String _validationsKey = 'community_validations';
  // ignore: unused_field
  static const String _spotValidationsKey = 'spot_validations';
  static const String _listValidationsKey = 'list_validations';

  // ignore: unused_field
  final StorageService _storageService;
  // ignore: unused_field - Reserved for future preferences storage
  final SharedPreferencesCompat _prefs;
  final GovernedUpwardLearningIntakeService?
      _governedUpwardLearningIntakeService;
  final CommunityFollowUpPromptPlannerService? _communityFollowUpPlannerService;

  // In-memory cache
  final Map<String, SpotValidationSummary> _spotValidationCache = {};
  final Map<String, List<CommunityValidation>> _validationCache = {};

  CommunityValidationService({
    required StorageService storageService,
    required SharedPreferencesCompat prefs,
    CommunityFollowUpPromptPlannerService? communityFollowUpPlannerService,
    GovernedUpwardLearningIntakeService? governedUpwardLearningIntakeService,
  })  : _storageService = storageService,
        _prefs = prefs,
        _communityFollowUpPlannerService = communityFollowUpPlannerService ??
            (GetIt.instance
                    .isRegistered<CommunityFollowUpPromptPlannerService>()
                ? GetIt.instance<CommunityFollowUpPromptPlannerService>()
                : null),
        _governedUpwardLearningIntakeService =
            governedUpwardLearningIntakeService ??
                (GetIt.instance
                        .isRegistered<GovernedUpwardLearningIntakeService>()
                    ? GetIt.instance<GovernedUpwardLearningIntakeService>()
                    : null);

  /// Validate a spot
  Future<CommunityValidation> validateSpot({
    required Spot spot,
    required String validatorId,
    required ValidationStatus status,
    required List<ValidationCriteria> criteria,
    String? feedback,
    ValidationLevel? level,
  }) async {
    try {
      developer.log('Validating spot ${spot.id} by validator $validatorId',
          name: _logName);

      // Determine validation level if not provided
      final validationLevel = level ?? ValidationLevel.community;

      // Create validation
      final validation = validationLevel == ValidationLevel.expert
          ? CommunityValidation.fromExpertCurator(
              spotId: spot.id,
              curatorId: validatorId,
              status: status,
              feedback: feedback,
              criteria: criteria,
            )
          : CommunityValidation.fromCommunityMember(
              spotId: spot.id,
              memberId: validatorId,
              status: status,
              feedback: feedback,
              criteria: criteria,
            );

      // Save validation
      await _saveValidation(validation);
      await _stageCommunityValidationBestEffort(
        validation: validation,
        spotName: spot.name,
      );
      await _createCommunityValidationFollowUpPlanBestEffort(
        validation: validation,
        spotName: spot.name,
      );

      // Update cache
      await _updateSpotValidationSummary(spot.id);

      developer.log('Spot validation completed: ${validation.status.name}',
          name: _logName);
      return validation;
    } catch (e) {
      developer.log('Error validating spot: $e', name: _logName);
      rethrow;
    }
  }

  /// Validate a list
  Future<ValidationResult> validateList({
    required UnifiedList list,
    required String validatorId,
    required List<ValidationCriteria> criteria,
    String? feedback,
  }) async {
    try {
      developer.log('Validating list ${list.id} by validator $validatorId',
          name: _logName);

      // Check if list has required spots
      if (list.spotIds.isEmpty) {
        return ValidationResult(
          isValid: false,
          issues: ['List has no spots'],
          confidenceScore: 0.0,
        );
      }

      // Validate all spots in the list
      // ignore: unused_local_variable - Reserved for future validation tracking
      final spotValidations = <CommunityValidation>[];
      int validatedCount = 0;
      int rejectedCount = 0;

      for (final spotId in list.spotIds) {
        final spotSummary = await getSpotValidationSummary(spotId);
        if (spotSummary.isWellValidated) {
          validatedCount++;
        } else if (spotSummary.overallStatus == ValidationStatus.rejected) {
          rejectedCount++;
        }
        // Note: We'd need to get actual validations, but for now use summary
      }

      // Calculate validation score
      final validationScore =
          list.spotIds.isEmpty ? 0.0 : validatedCount / list.spotIds.length;

      // Determine if list is valid
      final isValid = validationScore >= 0.7 && rejectedCount == 0;

      final issues = <String>[];
      if (validationScore < 0.7) {
        issues.add('Less than 70% of spots are validated');
      }
      if (rejectedCount > 0) {
        issues.add('$rejectedCount spot(s) have been rejected');
      }
      if (list.spotIds.length < 3) {
        issues.add('List has fewer than 3 spots');
      }

      final result = ValidationResult(
        isValid: isValid,
        issues: issues,
        confidenceScore: validationScore,
        validatedSpots: validatedCount,
        totalSpots: list.spotIds.length,
      );

      // Save list validation
      await _saveListValidation(list.id, result);

      developer.log(
          'List validation completed: ${result.isValid ? "valid" : "invalid"}',
          name: _logName);
      return result;
    } catch (e) {
      developer.log('Error validating list: $e', name: _logName);
      return ValidationResult(
        isValid: false,
        issues: ['Validation error: $e'],
        confidenceScore: 0.0,
      );
    }
  }

  /// Get validation summary for a spot
  Future<SpotValidationSummary> getSpotValidationSummary(String spotId) async {
    try {
      // Check cache first
      if (_spotValidationCache.containsKey(spotId)) {
        return _spotValidationCache[spotId]!;
      }

      // Load validations for this spot
      final validations = await _getValidationsForSpot(spotId);

      // Create summary
      final summary =
          SpotValidationSummary.fromValidations(spotId, validations);

      // Cache it
      _spotValidationCache[spotId] = summary;

      return summary;
    } catch (e) {
      developer.log('Error getting spot validation summary: $e',
          name: _logName);
      return SpotValidationSummary.unvalidated(spotId);
    }
  }

  /// Get all validations for a spot
  Future<List<CommunityValidation>> getSpotValidations(String spotId) async {
    return await _getValidationsForSpot(spotId);
  }

  /// Check if a spot is validated
  Future<bool> isSpotValidated(String spotId) async {
    final summary = await getSpotValidationSummary(spotId);
    return summary.isWellValidated;
  }

  /// Get validation quality grade for a spot
  Future<String> getSpotValidationGrade(String spotId) async {
    final summary = await getSpotValidationSummary(spotId);
    return summary.validationGrade;
  }

  // Private helper methods

  /// Save validation to storage
  Future<void> _saveValidation(CommunityValidation validation) async {
    try {
      final allValidations = await _loadAllValidations();

      // Add new validation
      allValidations.add(validation);

      // Save to storage
      final validationsJson =
          allValidations.map((v) => _validationToJson(v)).toList();
      await _storageService.setObject(
        _validationsKey,
        validationsJson,
        box: 'spots_user',
      );

      // Update spot-specific cache
      final spotKey = 'spot_${validation.spotId}';
      if (_validationCache.containsKey(spotKey)) {
        _validationCache[spotKey]!.add(validation);
      } else {
        _validationCache[spotKey] = [validation];
      }

      // Clear spot summary cache
      _spotValidationCache.remove(validation.spotId);
    } catch (e) {
      developer.log('Error saving validation: $e', name: _logName);
      rethrow;
    }
  }

  Future<void> _stageCommunityValidationBestEffort({
    required CommunityValidation validation,
    String? spotName,
  }) async {
    final service = _governedUpwardLearningIntakeService;
    if (service == null) {
      return;
    }
    try {
      final occurredAtUtc = validation.validatedAt.toUtc();
      final airGapArtifact = const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'community_validation_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'sourceKind': 'community_validation_intake',
          'validationId': validation.id,
          'spotId': validation.spotId,
          'status': validation.status.name,
          'level': validation.level.name,
          'confidenceScore': validation.confidenceScore,
          'trustScore': validation.trustScore,
          if (spotName?.trim().isNotEmpty ?? false)
            'spotName': spotName!.trim(),
        },
      );
      await service.stageCommunityValidationIntake(
        validation: validation,
        occurredAtUtc: occurredAtUtc,
        airGapArtifact: airGapArtifact,
        spotName: spotName,
      );
    } catch (e) {
      developer.log(
        'Error staging community validation upward learning (non-blocking): $e',
        name: _logName,
      );
    }
  }

  Future<void> _createCommunityValidationFollowUpPlanBestEffort({
    required CommunityValidation validation,
    required String spotName,
  }) async {
    final planner = _communityFollowUpPlannerService;
    if (planner == null || validation.validatorId.trim().isEmpty) {
      return;
    }
    try {
      await planner.createValidationPlan(
        validation: validation,
        spotName: spotName,
      );
    } catch (e) {
      developer.log(
        'Error creating community validation follow-up plan (non-blocking): $e',
        name: _logName,
      );
    }
  }

  /// Load all validations from storage
  Future<List<CommunityValidation>> _loadAllValidations() async {
    try {
      final data = _storageService.getObject<List<dynamic>>(
        _validationsKey,
        box: 'spots_user',
      );

      if (data == null || data.isEmpty) {
        return [];
      }

      return data
          .map((json) => _validationFromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('Error loading validations: $e', name: _logName);
      return [];
    }
  }

  /// Get validations for a specific spot
  Future<List<CommunityValidation>> _getValidationsForSpot(
      String spotId) async {
    try {
      // Check cache first
      final cacheKey = 'spot_$spotId';
      if (_validationCache.containsKey(cacheKey)) {
        return _validationCache[cacheKey]!;
      }

      // Load from storage
      final allValidations = await _loadAllValidations();
      final spotValidations =
          allValidations.where((v) => v.spotId == spotId).toList();

      // Cache it
      _validationCache[cacheKey] = spotValidations;

      return spotValidations;
    } catch (e) {
      developer.log('Error getting validations for spot: $e', name: _logName);
      return [];
    }
  }

  /// Update spot validation summary cache
  Future<void> _updateSpotValidationSummary(String spotId) async {
    final validations = await _getValidationsForSpot(spotId);
    final summary = SpotValidationSummary.fromValidations(spotId, validations);
    _spotValidationCache[spotId] = summary;
  }

  /// Save list validation result
  Future<void> _saveListValidation(
      String listId, ValidationResult result) async {
    try {
      final listValidations = await _loadListValidations();
      listValidations[listId] = result;

      await _storageService.setObject(
        _listValidationsKey,
        listValidations.map((k, v) => MapEntry(k, _validationResultToJson(v))),
        box: 'spots_user',
      );
    } catch (e) {
      developer.log('Error saving list validation: $e', name: _logName);
    }
  }

  /// Load list validations
  Future<Map<String, ValidationResult>> _loadListValidations() async {
    try {
      final data = _storageService.getObject<Map<String, dynamic>>(
        _listValidationsKey,
        box: 'spots_user',
      );

      if (data == null || data.isEmpty) {
        return {};
      }

      return data.map((k, v) => MapEntry(
            k,
            _validationResultFromJson(v as Map<String, dynamic>),
          ));
    } catch (e) {
      developer.log('Error loading list validations: $e', name: _logName);
      return {};
    }
  }

  // JSON serialization helpers

  Map<String, dynamic> _validationToJson(CommunityValidation validation) {
    return {
      'id': validation.id,
      'spotId': validation.spotId,
      'validatorId': validation.validatorId,
      'status': validation.status.name,
      'level': validation.level.name,
      'feedback': validation.feedback,
      'validatedAt': validation.validatedAt.toIso8601String(),
      'criteriaChecked': validation.criteriaChecked.map((c) => c.name).toList(),
      'confidenceScore': validation.confidenceScore,
      'metadata': validation.metadata,
    };
  }

  CommunityValidation _validationFromJson(Map<String, dynamic> json) {
    return CommunityValidation(
      id: json['id'] as String,
      spotId: json['spotId'] as String,
      validatorId: json['validatorId'] as String,
      status: ValidationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ValidationStatus.pending,
      ),
      level: ValidationLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => ValidationLevel.community,
      ),
      feedback: json['feedback'] as String?,
      validatedAt: DateTime.parse(json['validatedAt'] as String),
      criteriaChecked: (json['criteriaChecked'] as List)
          .map((c) => ValidationCriteria.values.firstWhere(
                (crit) => crit.name == c,
                orElse: () => ValidationCriteria.locationAccuracy,
              ))
          .toList(),
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> _validationResultToJson(ValidationResult result) {
    return {
      'isValid': result.isValid,
      'issues': result.issues,
      'confidenceScore': result.confidenceScore,
      'validatedSpots': result.validatedSpots,
      'totalSpots': result.totalSpots,
    };
  }

  ValidationResult _validationResultFromJson(Map<String, dynamic> json) {
    return ValidationResult(
      isValid: json['isValid'] as bool,
      issues: List<String>.from(json['issues'] as List),
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      validatedSpots: json['validatedSpots'] as int? ?? 0,
      totalSpots: json['totalSpots'] as int? ?? 0,
    );
  }
}

/// Validation result for lists
class ValidationResult {
  final bool isValid;
  final List<String> issues;
  final double confidenceScore;
  final int validatedSpots;
  final int totalSpots;

  ValidationResult({
    required this.isValid,
    required this.issues,
    required this.confidenceScore,
    this.validatedSpots = 0,
    this.totalSpots = 0,
  });
}
