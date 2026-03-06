/// SPOTS OnboardingAggregationService Acceptance Tests
/// Date: January 2, 2026
/// Purpose: Verify device-first onboarding dimension mapping contract:
/// - mappingSource = 'device'
/// - dimensions are computed locally and forwarded to edge function
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/user/onboarding_data.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/network/edge_function_service.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_aggregation_service.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_dimension_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class _CapturingEdgeFunctionService extends EdgeFunctionService {
  _CapturingEdgeFunctionService()
      : super(client: SupabaseClient('http://localhost', 'anon'));

  String? lastFunctionName;
  Map<String, dynamic>? lastBody;

  @override
  Future<Map<String, dynamic>> invokeFunction({
    required String functionName,
    required Map<String, dynamic> body,
  }) async {
    lastFunctionName = functionName;
    lastBody = body;
    final rawDims = body['dimensions'];
    final dims = rawDims is Map
        ? rawDims.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))
        : <String, double>{};
    return <String, dynamic>{
      'success': true,
      // Mirror what the edge function returns: numbers that must parse to double.
      'dimensions': dims,
    };
  }
}

final class _FakeAgentIdService extends AgentIdService {
  _FakeAgentIdService();

  @override
  Future<String> getUserAgentId(String userId) async {
    return 'agent_$userId';
  }
}

void main() {
  test('sends device-mapped dimensions + mappingSource=device to edge function',
      () async {
    final edge = _CapturingEdgeFunctionService();
    final agentIds = _FakeAgentIdService();
    final mapper = OnboardingDimensionMapper();

    final svc = OnboardingAggregationService(
      edgeFunctionService: edge,
      agentIdService: agentIds,
      dimensionMapper: mapper,
    );

    final onboarding = OnboardingData(
      agentId: 'agent_local_placeholder',
      age: 22,
      homebase: 'New York, NY',
      favoritePlaces: const ['Central Park', 'Brooklyn Bridge', 'SoHo'],
      preferences: const {
        'Activities': ['Live Music'],
        'Social': ['Trivia Nights'],
      },
      completedAt: DateTime(2026, 1, 1),
    );

    final result = await svc.aggregateOnboardingData(
      userId: 'user_1',
      onboardingData: onboarding,
    );

    expect(edge.lastFunctionName, equals('onboarding-aggregation'));
    final body = edge.lastBody!;
    expect(body['agentId'], equals('agent_user_1'));
    expect(body['mappingSource'], equals('device_inferred'));

    final sentDims = Map<String, double>.from(body['dimensions'] as Map);
    expect(sentDims, isNotEmpty);
    expect(result, equals(sentDims));
  });
}
