import 'dart:developer' as developer;

import 'package:avrai_runtime_os/kernel/language/kernel_derived_language_dimension_mapper.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:avrai_runtime_os/services/language/language_runtime_service.dart';

/// Kernel-governed parser for aspirational DNA shifts.
///
/// The legacy [LanguageRuntimeService] constructor parameter is retained for
/// compatibility while the parser itself now reads only sanitized language
/// kernel artifacts.
class AspirationalIntentParser {
  AspirationalIntentParser({
    LanguageKernelOrchestratorService? languageKernelOrchestrator,
    LanguageRuntimeService? languageRuntimeService,
    KernelDerivedLanguageDimensionMapper? dimensionMapper,
  })  : _languageKernelOrchestrator =
            languageKernelOrchestrator ?? LanguageKernelOrchestratorService(),
        _dimensionMapper =
            dimensionMapper ?? KernelDerivedLanguageDimensionMapper();

  final LanguageKernelOrchestratorService _languageKernelOrchestrator;
  final KernelDerivedLanguageDimensionMapper _dimensionMapper;

  Future<Map<String, double>> parseIntent(
    String message, {
    String actorAgentId = 'agt_user_local',
    Set<String> consentScopes = const <String>{'user_runtime_learning'},
  }) async {
    try {
      final turn = await _languageKernelOrchestrator.processHumanText(
        actorAgentId: actorAgentId,
        rawText: message,
        consentScopes: consentScopes,
        chatType: 'agent',
        surface: 'aspirational_dna',
        channel: 'personality_chat',
      );

      final vectorShift = _dimensionMapper.parseAspirationalShift(turn);
      developer.log(
        'Parsed intent into vector shift through the language kernel: '
        '$vectorShift',
        name: 'AspirationalIntentParser',
      );
      return vectorShift;
    } catch (e, st) {
      developer.log(
        'Failed to parse aspirational intent, falling back to empty shift: $e',
        error: e,
        stackTrace: st,
        name: 'AspirationalIntentParser',
      );
      return const <String, double>{};
    }
  }
}
