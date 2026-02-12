// Quantum Matching Integration Service
//
// Integrates Phase 19 quantum entanglement matching with existing matching systems
// Part of Phase 19 Section 19.15: Integration with Existing Matching Systems
// Patent #29: Multi-Entity Quantum Entanglement Matching System

import 'dart:developer' as developer;

import 'package:avrai/core/controllers/quantum_matching_controller.dart';
import 'package:avrai/core/models/quantum/matching_input.dart';
import 'package:avrai/core/models/quantum/matching_result.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/business/business_account.dart';
import 'package:avrai/core/models/business/brand_account.dart';
import 'package:avrai/core/models/spots/spot.dart';
import 'package:avrai/core/services/infrastructure/feature_flag_service.dart';
import 'package:avrai/core/services/quantum/quantum_matching_ai_learning_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai/core/services/security/hybrid_encryption_service.dart';
import 'package:avrai/core/ai2ai/anonymous_communication.dart';
import 'dart:async';

/// Service for integrating quantum entanglement matching with existing systems
///
/// **Purpose:**
/// - Provides unified interface for quantum matching
/// - Handles entity conversion (User, Event, Business, Brand → MatchingInput)
/// - Manages feature flag checks
/// - Provides fallback to classical methods
///
/// **Usage:**
/// ```dart
/// final integrationService = sl<QuantumMatchingIntegrationService>();
///
/// // Calculate compatibility using quantum matching (if enabled)
/// final compatibility = await integrationService.calculateCompatibility(
///   user: user,
///   event: event,
///   business: business,
/// );
/// ```
class QuantumMatchingIntegrationService {
  static const String _logName = 'QuantumMatchingIntegrationService';

  // Feature flag names
  static const String _quantumMatchingEnabled = 'phase19_quantum_matching_enabled';
  static const String _knotIntegrationEnabled = 'phase19_knot_integration_enabled';

  final QuantumMatchingController _quantumController;
  final FeatureFlagService _featureFlags;
  // Phase 19.16: AI2AI Integration
  final QuantumMatchingAILearningService? _aiLearningService;
  // Phase 19 Integration Enhancement: String/Fabric/Worldsheet + Signal Protocol
  // Reserved for future use: enhanced integration capabilities or result transmission
  // Note: QuantumMatchingController already has these integrations, but keeping here for consistency
  // ignore: unused_field
  final KnotEvolutionStringService? _stringService;
  // ignore: unused_field
  final KnotFabricService? _fabricService;
  // ignore: unused_field
  final KnotWorldsheetService? _worldsheetService;
  // ignore: unused_field
  final HybridEncryptionService? _encryptionService;
  // ignore: unused_field
  final AnonymousCommunicationProtocol? _ai2aiProtocol;

  QuantumMatchingIntegrationService({
    required QuantumMatchingController quantumController,
    required FeatureFlagService featureFlags,
    QuantumMatchingAILearningService? aiLearningService,
    KnotEvolutionStringService? stringService,
    KnotFabricService? fabricService,
    KnotWorldsheetService? worldsheetService,
    HybridEncryptionService? encryptionService,
    AnonymousCommunicationProtocol? ai2aiProtocol,
  })  : _quantumController = quantumController,
        _featureFlags = featureFlags,
        _aiLearningService = aiLearningService,
        _stringService = stringService,
        _fabricService = fabricService,
        _worldsheetService = worldsheetService,
        _encryptionService = encryptionService,
        _ai2aiProtocol = ai2aiProtocol;

  /// Calculate compatibility using quantum matching (if enabled) or fallback
  ///
  /// **Flow:**
  /// 1. Check feature flag for quantum matching
  /// 2. If enabled: Use QuantumMatchingController
  /// 3. If disabled: Return null (caller should use classical method)
  ///
  /// **Parameters:**
  /// - `user`: User to match
  /// - `event`: Event entity (optional)
  /// - `business`: Business entity (optional)
  /// - `brand`: Brand entity (optional)
  /// - `spot`: Spot entity (optional)
  /// - `additionalEntities`: Additional entities (optional)
  ///
  /// **Returns:**
  /// `MatchingResult` if quantum matching is enabled and successful, `null` otherwise
  Future<MatchingResult?> calculateCompatibility({
    required UnifiedUser user,
    ExpertiseEvent? event,
    BusinessAccount? business,
    BrandAccount? brand,
    Spot? spot,
    List<dynamic>? additionalEntities,
  }) async {
    try {
      // Check if quantum matching is enabled
      final isEnabled = await _featureFlags.isEnabled(
        _quantumMatchingEnabled,
        userId: user.id,
        defaultValue: false,
      );

      if (!isEnabled) {
        developer.log(
          'Quantum matching disabled for user ${user.id}, use classical method',
          name: _logName,
        );
        return null; // Signal to use classical method
      }

      // Build matching input
      final matchingInput = MatchingInput(
        user: user,
        event: event,
        business: business,
        spot: spot,
        additionalEntities: additionalEntities != null
            ? [
                ...additionalEntities,
                if (brand != null) brand,
              ]
            : brand != null
                ? [brand]
                : null,
      );

      // Validate input
      if (!matchingInput.isValid) {
        developer.log(
          'Invalid matching input: no entities provided',
          name: _logName,
        );
        return null;
      }

      // Execute quantum matching
      final result = await _quantumController.execute(matchingInput);

      if (!result.success || result.matchingResult == null) {
        developer.log(
          'Quantum matching failed: ${result.error}, falling back to classical method',
          name: _logName,
        );
        return null; // Fallback to classical method
      }

      developer.log(
        'Quantum matching successful: compatibility=${result.matchingResult!.compatibility.toStringAsFixed(3)}',
        name: _logName,
      );

      // Phase 19.16: Learn from successful match (fire-and-forget)
      if (_aiLearningService != null && result.matchingResult!.compatibility >= 0.5) {
        // Only learn from matches with reasonable compatibility (>= 0.5)
        unawaited(_aiLearningService.learnFromSuccessfulMatch(
          userId: user.id,
          matchingResult: result.matchingResult!,
          event: event,
          isOffline: false, // Integration service assumes online matching
        ));
      }

      return result.matchingResult;
    } catch (e, stackTrace) {
      developer.log(
        'Error in quantum matching integration: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null; // Fallback to classical method on error
    }
  }

  /// Check if quantum matching is enabled for a user
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  ///
  /// **Returns:**
  /// `true` if quantum matching is enabled, `false` otherwise
  Future<bool> isQuantumMatchingEnabled({required String userId}) async {
    return await _featureFlags.isEnabled(
      _quantumMatchingEnabled,
      userId: userId,
      defaultValue: false,
    );
  }

  /// Check if knot integration is enabled
  ///
  /// **Parameters:**
  /// - `userId`: User ID (optional, for user-based targeting)
  ///
  /// **Returns:**
  /// `true` if knot integration is enabled, `false` otherwise
  Future<bool> isKnotIntegrationEnabled({String? userId}) async {
    return await _featureFlags.isEnabled(
      _knotIntegrationEnabled,
      userId: userId,
      defaultValue: true, // Default to enabled (knot services are stable)
    );
  }

  /// Calculate compatibility for user-event matching
  ///
  /// **Convenience method** for user-event compatibility
  Future<MatchingResult?> calculateUserEventCompatibility({
    required UnifiedUser user,
    required ExpertiseEvent event,
  }) async {
    return await calculateCompatibility(
      user: user,
      event: event,
    );
  }

  /// Calculate compatibility for user-business matching
  ///
  /// **Convenience method** for user-business compatibility
  Future<MatchingResult?> calculateUserBusinessCompatibility({
    required UnifiedUser user,
    required BusinessAccount business,
  }) async {
    return await calculateCompatibility(
      user: user,
      business: business,
    );
  }

  /// Calculate compatibility for user-brand matching
  ///
  /// **Convenience method** for user-brand compatibility
  Future<MatchingResult?> calculateUserBrandCompatibility({
    required UnifiedUser user,
    required BrandAccount brand,
  }) async {
    return await calculateCompatibility(
      user: user,
      brand: brand,
    );
  }

  /// Calculate compatibility for multi-entity matching
  ///
  /// **Convenience method** for matching with multiple entities
  Future<MatchingResult?> calculateMultiEntityCompatibility({
    required UnifiedUser user,
    ExpertiseEvent? event,
    BusinessAccount? business,
    BrandAccount? brand,
    Spot? spot,
    List<dynamic>? additionalEntities,
  }) async {
    return await calculateCompatibility(
      user: user,
      event: event,
      business: business,
      brand: brand,
      spot: spot,
      additionalEntities: additionalEntities,
    );
  }
}
