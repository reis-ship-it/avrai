import 'package:avrai_core/models/user/language_profile_diagnostics.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/language_pattern_learning_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:get_it/get_it.dart';

class LanguageProfileDiagnosticsService {
  LanguageProfileDiagnosticsService({
    LanguagePatternLearningService? languageLearningService,
    AgentIdService? agentIdService,
  })  : _languageLearningService = languageLearningService ??
            (GetIt.instance.isRegistered<LanguagePatternLearningService>()
                ? GetIt.instance<LanguagePatternLearningService>()
                : LanguagePatternLearningService()),
        _agentIdService = agentIdService ??
            (GetIt.instance.isRegistered<AgentIdService>()
                ? GetIt.instance<AgentIdService>()
                : GetIt.instance<AgentIdService>());

  final LanguagePatternLearningService _languageLearningService;
  final AgentIdService _agentIdService;

  Future<LanguageProfileDiagnosticsSnapshot?> getDiagnosticsForUser(
    String userId, {
    int recentEventLimit = 6,
  }) async {
    final agentId = await _agentIdService.getUserAgentId(userId);
    return getDiagnosticsForProfileRef(
      agentId,
      recentEventLimit: recentEventLimit,
    );
  }

  Future<LanguageProfileDiagnosticsSnapshot?> getDiagnosticsForProfileRef(
    String profileRef, {
    int recentEventLimit = 6,
  }) async {
    final normalizedRef = profileRef.trim();
    if (normalizedRef.isEmpty) {
      return null;
    }

    final profile =
        await _languageLearningService.getLanguageProfileByRef(normalizedRef);
    if (profile == null) {
      return null;
    }

    final recentEvents = await _languageLearningService
        .getRecentLearningEventsByRef(normalizedRef, limit: recentEventLimit);

    return LanguageProfileDiagnosticsSnapshot(
      profileRef: normalizedRef,
      displayRef: profile.userId,
      profile: profile,
      recentEvents: recentEvents,
    );
  }
}
