import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';
import 'package:avrai/core/models/user/onboarding_data.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/network/edge_function_service.dart';
import 'package:avrai/core/services/onboarding/onboarding_dimension_mapper.dart';

/// Service for syncing aggregated onboarding data to an edge function.
///
/// **Source of truth:** on-device mapping.
/// This service sends the *device-computed* onboarding-dimension mapping to the
/// edge function for storage/analytics, so cloud state mirrors local state.
/// Phase 11 Section 4: Edge Mesh Functions
class OnboardingAggregationService {
  static const String _logName = 'OnboardingAggregationService';

  final EdgeFunctionService _edgeFunctionService;
  final AgentIdService _agentIdService;
  final OnboardingDimensionMapper _dimensionMapper;

  OnboardingAggregationService({
    EdgeFunctionService? edgeFunctionService,
    AgentIdService? agentIdService,
    OnboardingDimensionMapper? dimensionMapper,
  })  : _edgeFunctionService =
            edgeFunctionService ?? GetIt.instance<EdgeFunctionService>(),
        _agentIdService = agentIdService ?? GetIt.instance<AgentIdService>(),
        _dimensionMapper = dimensionMapper ?? OnboardingDimensionMapper();

  /// Sync onboarding aggregation via edge function.
  ///
  /// [userId] - Authenticated user ID
  /// [onboardingData] - OnboardingData to aggregate
  ///
  /// Returns the stored personality dimensions (device-mapped, or server fallback
  /// for older clients).
  Future<Map<String, double>> aggregateOnboardingData({
    required String userId,
    required OnboardingData onboardingData,
  }) async {
    try {
      developer.log('Aggregating onboarding data via edge function',
          name: _logName);

      // Convert userId → agentId
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Device-side dimensions - use directly computed values if available (new flow)
      // Otherwise fall back to legacy inference
      Map<String, double> localDimensions;
      String mappingSource;

      if (onboardingData.hasDimensionValues) {
        // NEW FLOW: Use directly computed dimensions from onboarding questions
        localDimensions =
            Map<String, double>.from(onboardingData.dimensionValues!);
        mappingSource = 'device_direct';
        developer.log(
          'Using directly computed dimensions (${localDimensions.length} dimensions)',
          name: _logName,
        );
      } else {
        // LEGACY FLOW: Infer dimensions from preferences
        localDimensions = _dimensionMapper.mapOnboardingToDimensions(
          onboardingData.toAgentInitializationMap(),
        );
        mappingSource = 'device_inferred';
        developer.log(
          'Using inferred dimensions from preferences',
          name: _logName,
        );
      }

      // Call edge function
      final response = await _edgeFunctionService.invokeFunction(
        functionName: 'onboarding-aggregation',
        body: {
          'agentId': agentId,
          'onboardingData': onboardingData.toJson(),
          'dimensions': localDimensions,
          'dimensionConfidence': onboardingData.dimensionConfidence,
          'mappingSource': mappingSource,
        },
      );

      if (response['success'] != true) {
        throw Exception('Onboarding aggregation failed');
      }

      // Extract dimensions (convert JSON numbers to doubles)
      final dimensionsJson =
          response['dimensions'] as Map<String, dynamic>? ?? {};
      final dimensions = <String, double>{};

      dimensionsJson.forEach((key, value) {
        if (value is num) {
          dimensions[key] = value.toDouble();
        }
      });

      developer.log(
        'Onboarding aggregation complete: ${dimensions.length} dimensions',
        name: _logName,
      );

      return dimensions;
    } catch (e, stackTrace) {
      developer.log(
        'Error aggregating onboarding data: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Return empty dimensions on error (don't fail onboarding)
      return {};
    }
  }
}
