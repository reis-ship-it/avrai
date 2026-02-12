// ignore: dangling_library_doc_comments
/// Fabric Stability Prediction Service
/// 
/// Service for predicting fabric stability with new users.
/// Part of Predictive Proactive Outreach System - Phase 1.3
/// 
/// Uses knot fabric analysis and worldsheet predictions to determine
/// how adding a user would affect group/community stability.

import 'dart:developer' as developer;
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_core/models/personality_knot.dart';

/// Fabric stability prediction result
class FabricStabilityPrediction {
  /// Current fabric stability
  final double currentStability;
  
  /// Predicted fabric stability with new user
  final double predictedStability;
  
  /// Stability change (predicted - current)
  final double stabilityChange;
  
  /// Stability improvement (0.0-1.0, clamped positive values)
  final double stabilityImprovement;
  
  /// Whether adding user would improve stability
  final bool wouldImprove;
  
  /// Confidence in prediction
  final double confidence;
  
  FabricStabilityPrediction({
    required this.currentStability,
    required this.predictedStability,
    required this.stabilityChange,
    required this.stabilityImprovement,
    required this.wouldImprove,
    this.confidence = 0.5,
  });
  
  /// Empty prediction
  factory FabricStabilityPrediction.empty() {
    return FabricStabilityPrediction(
      currentStability: 0.0,
      predictedStability: 0.0,
      stabilityChange: 0.0,
      stabilityImprovement: 0.0,
      wouldImprove: false,
      confidence: 0.0,
    );
  }
}

/// Future fabric stability prediction
class FutureFabricStability {
  /// Current stability
  final double currentStability;
  
  /// Predicted stability at target time
  final double predictedStability;
  
  /// Stability change
  final double stabilityChange;
  
  /// Target time for prediction
  final DateTime targetTime;
  
  FutureFabricStability({
    required this.currentStability,
    required this.predictedStability,
    required this.stabilityChange,
    required this.targetTime,
  });
  
  /// Empty prediction
  factory FutureFabricStability.empty() {
    return FutureFabricStability(
      currentStability: 0.0,
      predictedStability: 0.0,
      stabilityChange: 0.0,
      targetTime: DateTime.now(),
    );
  }
}

/// Service for predicting fabric stability with new users
class FabricStabilityPredictionService {
  static const String _logName = 'FabricStabilityPredictionService';
  
  final KnotFabricService _fabricService;
  final KnotWorldsheetService _worldsheetService;
  final KnotStorageService _knotStorage;
  final KnotEvolutionStringService _stringService;
  
  FabricStabilityPredictionService({
    required KnotFabricService fabricService,
    required KnotWorldsheetService worldsheetService,
    required KnotStorageService knotStorage,
    required KnotEvolutionStringService stringService,
  })  : _fabricService = fabricService,
        _worldsheetService = worldsheetService,
        _knotStorage = knotStorage,
        _stringService = stringService;
  
  /// Predict how adding a user would affect fabric stability
  /// 
  /// **Flow:**
  /// 1. Get current fabric
  /// 2. Get candidate user's knot (current or predicted future)
  /// 3. Simulate adding user to fabric
  /// 4. Calculate new stability
  /// 5. Compare with current stability
  /// 
  /// **Parameters:**
  /// - `groupId`: Group/community ID
  /// - `candidateUserId`: Candidate user's agent ID
  /// - `currentFabric`: Current fabric
  /// - `targetTime`: Optional target time for prediction
  Future<FabricStabilityPrediction> predictStabilityWithUser({
    required String groupId,
    required String candidateUserId,
    required KnotFabric currentFabric,
    DateTime? targetTime,
  }) async {
    try {
      developer.log(
        'Predicting fabric stability with user: ${candidateUserId.substring(0, 10)}... '
        'for group: $groupId',
        name: _logName,
      );
      
      // 1. Get candidate user's knot
      final candidateKnot = await _knotStorage.loadKnot(candidateUserId);
      if (candidateKnot == null) {
        developer.log(
          '⚠️ Could not load knot for candidate user',
          name: _logName,
        );
        return FabricStabilityPrediction.empty();
      }
      
      // 2. Get predicted future knot if targetTime provided
      PersonalityKnot? futureKnot;
      if (targetTime != null) {
        futureKnot = await _stringService.predictFutureKnot(
          candidateUserId,
          targetTime,
        );
      }
      final knotToUse = futureKnot ?? candidateKnot;
      
      // 3. Get current fabric stability
      final currentStability = await _fabricService.measureFabricStability(
        currentFabric,
      );
      
      // 4. Simulate adding user to fabric
      // Get all current user knots from fabric
      final currentUserKnots = List<PersonalityKnot>.from(currentFabric.userKnots);
      
      // Add candidate knot
      final simulatedKnots = [...currentUserKnots, knotToUse];
      
      // Generate simulated fabric
      final simulatedFabric = await _fabricService.generateMultiStrandBraidFabric(
        userKnots: simulatedKnots,
      );
      
      // 5. Calculate new stability
      final newStability = await _fabricService.measureFabricStability(
        simulatedFabric,
      );
      
      // 6. Calculate stability change
      final stabilityChange = newStability - currentStability;
      final stabilityImprovement = stabilityChange.clamp(0.0, 1.0);
      
      developer.log(
        '✅ Fabric stability prediction: current=${currentStability.toStringAsFixed(2)}, '
        'predicted=${newStability.toStringAsFixed(2)}, change=${stabilityChange.toStringAsFixed(2)}',
        name: _logName,
      );
      
      return FabricStabilityPrediction(
        currentStability: currentStability,
        predictedStability: newStability,
        stabilityChange: stabilityChange,
        stabilityImprovement: stabilityImprovement,
        wouldImprove: stabilityChange > 0,
        confidence: _calculateConfidence(currentFabric, knotToUse),
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to predict fabric stability: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return FabricStabilityPrediction.empty();
    }
  }
  
  /// Predict future fabric stability using worldsheet
  /// 
  /// **Flow:**
  /// 1. Get worldsheet for group
  /// 2. Get fabric at target time
  /// 3. Calculate stability at target time
  /// 4. Compare with current stability
  /// 
  /// **Parameters:**
  /// - `groupId`: Group/community ID
  /// - `targetTime`: Target time for prediction
  Future<FutureFabricStability> predictFutureFabricStability({
    required String groupId,
    required DateTime targetTime,
  }) async {
    try {
      developer.log(
        'Predicting future fabric stability for group: $groupId at ${targetTime.toIso8601String()}',
        name: _logName,
      );
      
      // 1. Get worldsheet for group
      final worldsheet = await _worldsheetService.createWorldsheet(
        groupId: groupId,
        userIds: [], // Will be loaded from fabric
      );
      
      if (worldsheet == null) {
        developer.log(
          '⚠️ Could not create worldsheet for group',
          name: _logName,
        );
        return FutureFabricStability.empty();
      }
      
      // 2. Get fabric at target time
      final futureFabric = worldsheet.getFabricAtTime(targetTime);
      
      if (futureFabric == null) {
        developer.log(
          '⚠️ Could not get fabric at target time',
          name: _logName,
        );
        return FutureFabricStability.empty();
      }
      
      // 3. Calculate stability at target time
      final futureStability = await _fabricService.measureFabricStability(
        futureFabric,
      );
      
      // 4. Get current fabric and stability
      // Load current fabric from storage (would need fabric storage service)
      // For now, use worldsheet's initial fabric
      final currentFabric = worldsheet.initialFabric;
      final currentStability = await _fabricService.measureFabricStability(
        currentFabric,
      );
      
      final stabilityChange = futureStability - currentStability;
      
      developer.log(
        '✅ Future fabric stability predicted: current=${currentStability.toStringAsFixed(2)}, '
        'future=${futureStability.toStringAsFixed(2)}, change=${stabilityChange.toStringAsFixed(2)}',
        name: _logName,
      );
      
      return FutureFabricStability(
        currentStability: currentStability,
        predictedStability: futureStability,
        stabilityChange: stabilityChange,
        targetTime: targetTime,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to predict future fabric stability: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return FutureFabricStability.empty();
    }
  }
  
  /// Calculate confidence in prediction
  double _calculateConfidence(
    KnotFabric currentFabric,
    PersonalityKnot candidateKnot,
  ) {
    // Confidence based on:
    // 1. Fabric size (larger = more stable predictions)
    // 2. Knot data quality (more crossings = more confident)
    
    var confidence = 0.5; // Base confidence
    
      // Fabric size boost (0-0.3)
      final fabricSize = currentFabric.userKnots.length;
    confidence += (fabricSize / 20.0).clamp(0.0, 0.3);
    
    // Knot complexity boost (0-0.2)
    final knotComplexity = candidateKnot.invariants.crossingNumber;
    confidence += (knotComplexity / 50.0).clamp(0.0, 0.2);
    
    return confidence.clamp(0.0, 1.0);
  }
}
