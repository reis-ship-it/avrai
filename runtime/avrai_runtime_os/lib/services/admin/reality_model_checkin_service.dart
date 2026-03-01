import 'dart:convert';
import 'dart:developer' as developer;

import 'package:avrai_runtime_os/services/ai_infrastructure/llm_service.dart';
import 'package:get_it/get_it.dart';

/// Runtime-backed check-in service for admin reality-system oversight pages.
///
/// Uses the app's LLM runtime boundary when available and falls back to
/// deterministic responses if runtime chat is unavailable.
class RealityModelCheckInService {
  static const String _logName = 'RealityModelCheckInService';

  Future<String> checkIn({
    required String layer,
    required String prompt,
    required Map<String, dynamic> context,
    required List<String> approvedGroupings,
  }) async {
    final llm = _resolveLlmService();
    if (llm == null) {
      return _fallbackResponse(
        layer: layer,
        prompt: prompt,
        context: context,
        approvedGroupings: approvedGroupings,
      );
    }

    final messages = <ChatMessage>[
      ChatMessage(
        role: ChatRole.system,
        content:
            'You are the AVRAI internal oversight model interface for admins. '
            'Respond only with operational insights. Never reveal personal data. '
            'Only agent identity and aggregate metrics are allowed.',
      ),
      ChatMessage(
        role: ChatRole.user,
        content: jsonEncode(<String, dynamic>{
          'requestType': 'admin_reality_system_check_in',
          'layer': layer,
          'prompt': prompt,
          'approvedGroupings': approvedGroupings,
          'context': context,
          'outputRules': <String>[
            'Under 140 words',
            'Actionable operational summary',
            'Mention current planning/prep direction',
            'No PII, no personal identity details',
          ],
        }),
      ),
    ];

    try {
      final response = await llm.chat(
        messages: messages,
        context: LLMContext(
          preferences: <String, dynamic>{
            'surface': 'admin_reality_system',
            'layer': layer,
            'privacy_mode': 'agent_identity_only',
          },
        ),
        temperature: 0.25,
        maxTokens: 280,
      );

      final trimmed = response.trim();
      if (trimmed.isEmpty) {
        return _fallbackResponse(
          layer: layer,
          prompt: prompt,
          context: context,
          approvedGroupings: approvedGroupings,
        );
      }
      return trimmed;
    } catch (e, st) {
      developer.log(
        'Runtime check-in failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return _fallbackResponse(
        layer: layer,
        prompt: prompt,
        context: context,
        approvedGroupings: approvedGroupings,
      );
    }
  }

  Future<List<String>> proposeGroupings({
    required String layer,
    required List<String> observedTypes,
    required List<String> approvedGroupings,
  }) async {
    if (observedTypes.isEmpty) {
      return const <String>[];
    }

    final llm = _resolveLlmService();
    if (llm == null) {
      return _fallbackGroupingProposals(
        layer: layer,
        observedTypes: observedTypes,
        approvedGroupings: approvedGroupings,
      );
    }

    final messages = <ChatMessage>[
      ChatMessage(
        role: ChatRole.system,
        content: 'Propose concise taxonomy groups for admin oversight. '
            'Return strict JSON array of strings only. '
            'No prose and no personal data.',
      ),
      ChatMessage(
        role: ChatRole.user,
        content: jsonEncode(<String, dynamic>{
          'layer': layer,
          'observedTypes': observedTypes,
          'approvedGroupings': approvedGroupings,
          'targetCount': 6,
          'format': 'json_array_strings',
        }),
      ),
    ];

    try {
      final response = await llm.chat(
        messages: messages,
        context: LLMContext(
          preferences: <String, dynamic>{
            'surface': 'admin_reality_grouping_proposal',
            'layer': layer,
            'privacy_mode': 'agent_identity_only',
          },
        ),
        temperature: 0.35,
        maxTokens: 220,
      );

      final parsed = _parseJsonStringList(response);
      if (parsed.isEmpty) {
        return _fallbackGroupingProposals(
          layer: layer,
          observedTypes: observedTypes,
          approvedGroupings: approvedGroupings,
        );
      }

      return parsed
          .where((group) => !approvedGroupings.contains(group))
          .take(8)
          .toList();
    } catch (e, st) {
      developer.log(
        'Grouping proposal failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return _fallbackGroupingProposals(
        layer: layer,
        observedTypes: observedTypes,
        approvedGroupings: approvedGroupings,
      );
    }
  }

  LLMService? _resolveLlmService() {
    try {
      if (GetIt.instance.isRegistered<LLMService>()) {
        return GetIt.instance<LLMService>();
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String _fallbackResponse({
    required String layer,
    required String prompt,
    required Map<String, dynamic> context,
    required List<String> approvedGroupings,
  }) {
    final groupingHint = approvedGroupings.isEmpty
        ? 'No approved grouping taxonomy yet.'
        : 'Approved grouping taxonomy count: ${approvedGroupings.length}.';

    if (layer == 'reality') {
      return 'Reality runtime is in guarded fallback mode. $groupingHint Focus remains on coherence, policy alignment, and updating grouping logic after human approvals. Prompt received: "$prompt".';
    }

    if (layer == 'universe') {
      return 'Universe runtime is in guarded fallback mode. $groupingHint Current prep emphasizes cluster health across clubs/communities/events with agent-level identity visibility only.';
    }

    return 'World runtime is in guarded fallback mode. $groupingHint Current prep emphasizes continuity across users, businesses, and service surfaces with privacy-safe agent identity only.';
  }

  List<String> _fallbackGroupingProposals({
    required String layer,
    required List<String> observedTypes,
    required List<String> approvedGroupings,
  }) {
    final uniqueObserved = observedTypes.toSet().toList()..sort();
    final proposals = <String>[];

    for (final type in uniqueObserved.take(6)) {
      final prefix = layer == 'universe' ? 'Universe' : 'World';
      proposals.add('$prefix logical cluster: $type');
    }

    return proposals
        .where((proposal) => !approvedGroupings.contains(proposal))
        .toList();
  }

  List<String> _parseJsonStringList(String response) {
    final trimmed = response.trim();
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        return decoded
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    } catch (_) {
      final match = RegExp(r'\[[\s\S]*\]').firstMatch(trimmed);
      if (match == null) return const <String>[];
      try {
        final decoded = jsonDecode(match.group(0)!);
        if (decoded is List) {
          return decoded
              .whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList();
        }
      } catch (_) {
        return const <String>[];
      }
    }
    return const <String>[];
  }
}
