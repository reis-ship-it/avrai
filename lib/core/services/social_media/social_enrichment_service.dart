import 'dart:developer' as developer;
import 'package:get_it/get_it.dart';
import 'package:avrai/core/services/network/edge_function_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';

/// Service for enriching social data via edge function
/// Phase 11 Section 4: Edge Mesh Functions
class SocialEnrichmentService {
  static const String _logName = 'SocialEnrichmentService';

  final EdgeFunctionService _edgeFunctionService;
  final AgentIdService _agentIdService;

  SocialEnrichmentService({
    EdgeFunctionService? edgeFunctionService,
    AgentIdService? agentIdService,
  })  : _edgeFunctionService =
            edgeFunctionService ?? GetIt.instance<EdgeFunctionService>(),
        _agentIdService = agentIdService ?? GetIt.instance<AgentIdService>();

  /// Enrich social data via edge function
  ///
  /// [userId] - Authenticated user ID
  ///
  /// Returns enriched social insights
  Future<Map<String, dynamic>> enrichSocialData({
    required String userId,
  }) async {
    try {
      developer.log('Enriching social data via edge function', name: _logName);

      // Convert userId → agentId
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Call edge function
      final response = await _edgeFunctionService.invokeFunction(
        functionName: 'social-enrichment',
        body: {
          'agentId': agentId,
          'userId':
              userId, // Pass userId for querying user_respects/user_follows
        },
      );

      final insights = response['insights'] as Map<String, dynamic>? ?? {};

      developer.log('Social enrichment complete', name: _logName);

      return insights;
    } catch (e, stackTrace) {
      developer.log(
        'Error enriching social data: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Return empty insights on error
      return {};
    }
  }
}
