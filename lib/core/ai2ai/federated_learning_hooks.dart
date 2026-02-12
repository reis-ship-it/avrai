// Federated Learning Hooks for Phase 11: User-AI Interaction Update
// Section 7: Federated Learning Hooks
// Hooks into AI2AI connections to collect embedding deltas for federated learning

import 'dart:developer' as developer;
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/ai2ai/embedding_delta_collector.dart';
import 'package:avrai/core/ml/onnx_dimension_scorer.dart';
import 'package:get_it/get_it.dart';

/// Federated Learning Hooks
/// 
/// Hooks into AI2AI connections to collect anonymized embedding deltas
/// and apply them to on-device models for federated learning.
/// 
/// Phase 11 Section 7: Federated Learning Hooks
class FederatedLearningHooks {
  static const String _logName = 'FederatedLearningHooks';
  
  final EmbeddingDeltaCollector _deltaCollector;
  
  FederatedLearningHooks({
    EmbeddingDeltaCollector? deltaCollector,
  })  : _deltaCollector = deltaCollector ?? EmbeddingDeltaCollector();
  
  /// Hook into AI2AI connection establishment
  /// 
  /// Called when an AI2AI connection is established.
  /// Collects embedding deltas and applies them to on-device models.
  /// 
  /// [userId] - Local user ID
  /// [localPersonality] - Local user's personality profile
  /// [remotePersonality] - Remote AI's personality profile
  /// [connectionId] - Connection identifier
  Future<void> onConnectionEstablished({
    required String userId,
    required PersonalityProfile localPersonality,
    required PersonalityProfile remotePersonality,
    required String connectionId,
  }) async {
    try {
      developer.log(
        'Federated learning hook: Connection established: $connectionId',
        name: _logName,
      );
      
      // Calculate delta directly from personalities
      final delta = await _deltaCollector.calculateDelta(
        localPersonality: localPersonality,
        remotePersonality: remotePersonality,
      );
      
      if (delta == null) {
        developer.log(
          'No significant delta found for connection: $connectionId',
          name: _logName,
        );
        return;
      }
      
      final deltas = [delta];
      
      if (deltas.isEmpty) {
        developer.log(
          'No significant deltas found for connection: $connectionId',
          name: _logName,
        );
        return;
      }
      
      // Apply deltas to on-device model
      await _applyDeltasToModel(deltas);
      
      developer.log(
        'Applied ${deltas.length} deltas from connection: $connectionId',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error in federated learning hook: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  /// Hook into periodic delta collection
  /// 
  /// Called periodically to collect deltas from all active connections.
  /// This enables continuous learning from the AI2AI network.
  /// 
  /// [userId] - Local user ID
  /// [localPersonality] - Local user's personality profile
  /// [remotePersonalities] - List of remote personality profiles from active connections
  Future<void> collectPeriodicDeltas({
    required String userId,
    required PersonalityProfile localPersonality,
    required List<PersonalityProfile> remotePersonalities,
  }) async {
    try {
      developer.log(
        'Collecting periodic deltas from ${remotePersonalities.length} active connections',
        name: _logName,
      );
      
      if (remotePersonalities.isEmpty) {
        developer.log('No remote personalities found for delta collection', name: _logName);
        return;
      }
      
      // Collect embedding deltas
      final deltas = await _deltaCollector.collectDeltas(
        localPersonality: localPersonality,
        remotePersonalities: remotePersonalities,
      );
      
      if (deltas.isEmpty) {
        developer.log('No significant deltas found', name: _logName);
        return;
      }
      
      // Apply deltas to on-device model
      await _applyDeltasToModel(deltas);
      
      developer.log(
        'Applied ${deltas.length} deltas from ${remotePersonalities.length} connections',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error collecting periodic deltas: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  /// Apply embedding deltas to on-device model
  /// 
  /// Updates the ONNX model with federated deltas for continuous learning.
  Future<void> _applyDeltasToModel(List<EmbeddingDelta> deltas) async {
    try {
      // Get ONNX scorer from DI
      if (GetIt.instance.isRegistered<OnnxDimensionScorer>()) {
        final onnxScorer = GetIt.instance<OnnxDimensionScorer>();
        await onnxScorer.updateWithDeltas(deltas);
        developer.log(
          'Applied ${deltas.length} deltas to ONNX model',
          name: _logName,
        );
      } else {
        developer.log(
          'ONNX scorer not available, skipping delta application',
          name: _logName,
        );
      }
    } catch (e) {
      developer.log(
        'Error applying deltas to model: $e',
        name: _logName,
      );
      // Don't throw - delta application failure shouldn't break the app
    }
  }
  
  /// Get deltas for edge sync
  /// 
  /// Returns recent deltas that can be synced to the cloud.
  /// Used by the federated-sync edge function.
  Future<List<EmbeddingDelta>> getDeltasForSync({
    required String userId,
    required PersonalityProfile localPersonality,
    required List<PersonalityProfile> remotePersonalities,
  }) async {
    try {
      if (remotePersonalities.isEmpty) {
        return [];
      }
      
      // Collect embedding deltas
      final deltas = await _deltaCollector.collectDeltas(
        localPersonality: localPersonality,
        remotePersonalities: remotePersonalities,
      );
      
      return deltas;
    } catch (e) {
      developer.log(
        'Error getting deltas for sync: $e',
        name: _logName,
      );
      return [];
    }
  }
}
