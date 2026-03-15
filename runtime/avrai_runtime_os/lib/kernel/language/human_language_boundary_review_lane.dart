import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

class HumanLanguageBoundaryViolationException implements Exception {
  const HumanLanguageBoundaryViolationException({
    required this.operation,
    required this.decision,
  });

  final String operation;
  final BoundaryDecision decision;

  @override
  String toString() {
    final reasons = decision.reasonCodes.join(', ');
    return 'HumanLanguageBoundaryViolationException('
        'operation: $operation, '
        'disposition: ${decision.disposition.toWireValue()}, '
        'reasons: $reasons)';
  }
}

class HumanLanguageBoundaryReview {
  static const String learningMetadataKey = 'human_language_learning_boundary';

  const HumanLanguageBoundaryReview({
    required this.rawText,
    required this.turn,
    required this.egressRequested,
    required this.egressPurpose,
    required this.chatType,
    required this.surface,
    required this.channel,
  });

  static const String metadataKey = 'human_language_boundary';

  final String rawText;
  final HumanLanguageKernelTurn turn;
  final bool egressRequested;
  final BoundaryEgressPurpose egressPurpose;
  final String chatType;
  final String surface;
  final String channel;

  bool get transcriptStorageAllowed =>
      turn.boundary.accepted && turn.boundary.transcriptStorageAllowed;

  bool get egressAllowed =>
      !egressRequested ||
      (turn.boundary.accepted && turn.boundary.egressAllowed);

  String get transcriptText => rawText;

  String get transportText => rawText;

  Map<String, dynamic> toMetadata({
    String metadataKey = HumanLanguageBoundaryReview.metadataKey,
  }) =>
      <String, dynamic>{
        metadataKey: <String, dynamic>{
          'intent': turn.interpretation.intent.toWireValue(),
          'summary': turn.interpretation.requestArtifact.summary,
          'privacy_sensitivity':
              turn.interpretation.privacySensitivity.toWireValue(),
          'needs_clarification': turn.interpretation.needsClarification,
          'confidence': turn.interpretation.confidence,
          'accepted': turn.boundary.accepted,
          'disposition': turn.boundary.disposition.toWireValue(),
          'transcript_storage_allowed': turn.boundary.transcriptStorageAllowed,
          'storage_allowed': turn.boundary.storageAllowed,
          'learning_allowed': turn.boundary.learningAllowed,
          'egress_allowed': turn.boundary.egressAllowed,
          'air_gap_required': turn.boundary.airGapRequired,
          'egress_purpose': turn.boundary.egressPurpose.toWireValue(),
          'egress_requested': egressRequested,
          'reason_codes': turn.boundary.reasonCodes,
          'chat_type': chatType,
          'surface': surface,
          'channel': channel,
          'sanitized_summary': turn.boundary.sanitizedArtifact.summary,
          'sanitized_artifact': turn.boundary.sanitizedArtifact.toJson(),
          'pseudonymous_actor_ref':
              turn.boundary.sanitizedArtifact.pseudonymousActorRef,
        },
      };
}

class HumanLanguageBoundaryReviewLane {
  HumanLanguageBoundaryReviewLane({
    LanguageKernelOrchestratorService? languageKernelOrchestrator,
    SharedPreferencesCompat? prefs,
  })  : _languageKernelOrchestrator =
            languageKernelOrchestrator ?? LanguageKernelOrchestratorService(),
        _prefs = prefs;

  final LanguageKernelOrchestratorService _languageKernelOrchestrator;
  final SharedPreferencesCompat? _prefs;

  Future<HumanLanguageBoundaryReview> reviewOutboundText({
    required String actorAgentId,
    required String rawText,
    required BoundaryEgressPurpose egressPurpose,
    required bool egressRequested,
    String? userId,
    String chatType = 'agent',
    String surface = 'chat',
    String channel = 'in_app',
    BoundaryPrivacyMode privacyMode = BoundaryPrivacyMode.localSovereign,
    Set<String>? consentScopes,
  }) async {
    return _reviewText(
      actorAgentId: actorAgentId,
      rawText: rawText,
      egressPurpose: egressPurpose,
      egressRequested: egressRequested,
      userId: userId,
      chatType: chatType,
      surface: surface,
      channel: channel,
      privacyMode: privacyMode,
      consentScopes: consentScopes,
    );
  }

  Future<HumanLanguageBoundaryReview> reviewLocalLearningText({
    required String actorAgentId,
    required String rawText,
    String? userId,
    String chatType = 'agent',
    String surface = 'chat',
    String channel = 'in_app',
    BoundaryPrivacyMode privacyMode = BoundaryPrivacyMode.userRuntime,
    Set<String>? consentScopes,
  }) {
    return _reviewText(
      actorAgentId: actorAgentId,
      rawText: rawText,
      egressPurpose: BoundaryEgressPurpose.none,
      egressRequested: false,
      userId: userId,
      chatType: chatType,
      surface: surface,
      channel: channel,
      privacyMode: privacyMode,
      consentScopes: consentScopes,
    );
  }

  Future<HumanLanguageBoundaryReview> _reviewText({
    required String actorAgentId,
    required String rawText,
    required BoundaryEgressPurpose egressPurpose,
    required bool egressRequested,
    String? userId,
    required String chatType,
    required String surface,
    required String channel,
    required BoundaryPrivacyMode privacyMode,
    Set<String>? consentScopes,
  }) async {
    final turn = await _languageKernelOrchestrator.processHumanText(
      actorAgentId: actorAgentId,
      rawText: rawText,
      consentScopes: consentScopes ?? await _resolveConsentScopes(),
      privacyMode: privacyMode,
      shareRequested: egressRequested,
      egressPurpose: egressPurpose,
      userId: userId,
      chatType: chatType,
      surface: surface,
      channel: channel,
    );
    return HumanLanguageBoundaryReview(
      rawText: rawText,
      turn: turn,
      egressRequested: egressRequested,
      egressPurpose: egressPurpose,
      chatType: chatType,
      surface: surface,
      channel: channel,
    );
  }

  Future<Set<String>> _resolveConsentScopes() async {
    try {
      final prefs = _prefs ?? await SharedPreferencesCompat.getInstance();
      final scopes = <String>{};
      if (prefs.getBool('user_runtime_learning_enabled') ?? true) {
        scopes.add('user_runtime_learning');
      }
      if (prefs.getBool('ai2ai_learning_enabled') ?? true) {
        scopes.add('ai2ai_learning');
      }
      if (prefs.getBool('discovery_enabled') ?? true) {
        scopes.add('discovery');
      }
      return scopes;
    } catch (_) {
      return const <String>{'user_runtime_learning', 'ai2ai_learning'};
    }
  }
}
