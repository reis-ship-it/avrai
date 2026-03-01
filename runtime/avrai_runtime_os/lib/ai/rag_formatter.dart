import 'dart:developer' as developer;

import 'package:avrai_runtime_os/ai/retrieval_result.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/llm_service.dart'
    as llm;

/// Format layer for RAG-as-answer: templates first, optional LLM with strict "no new facts" instructions.
/// Fallback: template-only bullet list. Graceful degradation for empty/partial retrieval.
///
/// Plan: RAG wiring + RAG-as-answer — RAGFormatter.
class RAGFormatter {
  RAGFormatter({llm.LLMService? llmService})
      : _llmService = llmService ?? _get<llm.LLMService>();

  static const String _logName = 'RAGFormatter';

  final llm.LLMService? _llmService;

  static T? _get<T extends Object>() {
    if (!GetIt.instance.isRegistered<T>()) return null;
    return GetIt.instance<T>();
  }

  /// Formats [result] into an answer string. [query] and [languageStyle] optional.
  /// Empty retrieval -> fixed "not enough" message. Partial -> caveat + template. Formatter failure -> template-only.
  Future<String> format({
    required RetrievalResult result,
    String? query,
    String? languageStyle,
    String? userId,
  }) async {
    if (result.isEmpty) {
      return "I don't have enough about you yet to answer that. Share more about your preferences, places you like, or people you connect with, and I'll use it next time.";
    }

    final caveat = _isPartial(result) ? "Based on what I know so far: " : "";

    final bullet = _templateOnly(result);
    final formatted = caveat + bullet;

    if (_llmService != null &&
        userId != null &&
        query != null &&
        query.trim().isNotEmpty) {
      try {
        final strict = await _formatWithLlm(
          result: result,
          query: query,
          userId: userId,
          languageStyle: languageStyle,
        );
        if (strict != null && strict.trim().isNotEmpty) {
          return caveat + strict;
        }
      } catch (e) {
        developer.log('RAGFormatter LLM format failed, using template: $e',
            name: _logName);
      }
    }
    return formatted;
  }

  bool _isPartial(RetrievalResult r) {
    final total = (r.coverage['traits'] ?? 0) +
        (r.coverage['places'] ?? 0) +
        (r.coverage['social'] ?? 0) +
        (r.coverage['cues'] ?? 0) +
        (r.coverage['insight'] ?? 0);
    return total > 0 && total < 5;
  }

  String _templateOnly(RetrievalResult r) {
    final buf = StringBuffer();
    final byType = <String, List<RetrievedItem>>{};
    for (final it in r.items) {
      byType.putIfAbsent(it.type, () => []).add(it);
    }
    if ((byType['traits'] ?? []).isNotEmpty) {
      buf.writeln(
          'Traits: ${(byType['traits']!.map((e) => e.content).take(5).join(', '))}.');
    }
    if ((byType['places'] ?? []).isNotEmpty) {
      buf.writeln(
          'Places: ${(byType['places']!.map((e) => e.content).take(5).join(', '))}.');
    }
    if ((byType['social'] ?? []).isNotEmpty) {
      buf.writeln(
          'Social: ${(byType['social']!.map((e) => e.content).take(3).join(', '))}.');
    }
    if ((byType['cues'] ?? []).isNotEmpty) {
      buf.writeln(
          'Network cues: ${(byType['cues']!.map((e) => e.content).take(3).join('; '))}.');
    }
    if ((byType['insight'] ?? []).isNotEmpty) {
      buf.writeln(
          'Insights: ${(byType['insight']!.map((e) => e.content).take(3).join('; '))}.');
    }
    final s = buf.toString().trim();
    final fallback = r.items.map((e) => e.content).take(10).join(', ');
    return s.isEmpty ? "Here's what I have: $fallback" : s;
  }

  Future<String?> _formatWithLlm({
    required RetrievalResult result,
    required String query,
    required String userId,
    String? languageStyle,
  }) async {
    final list = result.items.map((e) => e.content).take(15).toList();
    final block = list.join('\n');
    var system =
        "You only use the following retrieved items to answer. Do not add any information not in the list. Only rephrase or structure. Items:\n$block";
    if (languageStyle != null && languageStyle.trim().isNotEmpty) {
      system =
          "$system\n\nUser's preferred communication style (match if possible):\n$languageStyle";
    }
    final ctx = llm.LLMContext(userId: userId);
    final messages = [
      llm.ChatMessage(role: llm.ChatRole.system, content: system),
      llm.ChatMessage(role: llm.ChatRole.user, content: query),
    ];
    return _llmService!.chat(
      messages: messages,
      context: ctx,
      temperature: 0.3,
      maxTokens: 300,
    );
  }
}
