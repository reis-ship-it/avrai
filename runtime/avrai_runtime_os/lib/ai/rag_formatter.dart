import 'dart:developer' as developer;

import 'package:avrai_core/models/expression/expression_models.dart';
import 'package:avrai_runtime_os/ai/retrieval_result.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:get_it/get_it.dart';

/// Format layer for RAG-as-answer: templates first, then grounded expression
/// rendering that cannot originate new facts.
/// Fallback: template-only bullet list. Graceful degradation for empty/partial retrieval.
///
/// Plan: RAG wiring + RAG-as-answer — RAGFormatter.
class RAGFormatter {
  RAGFormatter({
    LanguageKernelOrchestratorService? languageKernelOrchestrator,
  }) : _languageKernelOrchestrator = languageKernelOrchestrator ??
            _get<LanguageKernelOrchestratorService>() ??
            LanguageKernelOrchestratorService();

  static const String _logName = 'RAGFormatter';

  final LanguageKernelOrchestratorService _languageKernelOrchestrator;

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

    if (userId != null && query != null && query.trim().isNotEmpty) {
      try {
        final strict = _formatWithExpressionKernel(
          result: result,
          query: query,
          userId: userId,
          languageStyle: languageStyle,
        );
        if (strict != null && strict.trim().isNotEmpty) {
          return caveat + strict;
        }
      } catch (e) {
        developer.log(
            'RAGFormatter expression kernel format failed, using template: $e',
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

  String? _formatWithExpressionKernel({
    required RetrievalResult result,
    required String query,
    required String userId,
    String? languageStyle,
  }) {
    final allowedClaims = result.items
        .map((entry) => entry.content.trim())
        .where((entry) => entry.isNotEmpty)
        .take(15)
        .toList();
    if (allowedClaims.isEmpty) {
      return null;
    }
    final rendered = _languageKernelOrchestrator.renderGroundedOutput(
      speechAct: ExpressionSpeechAct.explain,
      audience: ExpressionAudience.userSafe,
      surfaceShape: ExpressionSurfaceShape.chatTurn,
      subjectLabel: query,
      allowedClaims: allowedClaims,
      evidenceRefs: result.items
          .take(15)
          .map((entry) => '${entry.source}:${entry.type}:${entry.id}')
          .toList(),
      confidenceBand: _isPartial(result) ? 'low' : 'medium',
      toneProfile: languageStyle != null && languageStyle.trim().isNotEmpty
          ? 'adapted_to_user_style'
          : 'clear_calm',
      uncertaintyNotice: _isPartial(result)
          ? 'This answer is based on a partial slice of what AVRAI has grounded so far.'
          : null,
      cta: 'Ask a narrower follow-up if you want more specific detail.',
      adaptationProfileRef: 'rag_formatter:$userId',
    );
    return rendered.text;
  }
}
