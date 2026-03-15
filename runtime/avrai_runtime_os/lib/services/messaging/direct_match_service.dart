import 'package:avrai_runtime_os/services/messaging/bham_messaging_models.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

class DirectMatchService {
  static const double minimumCompatibility = 0.995;
  static const String _storeName = 'bham_direct_match';

  Future<DirectMatchInvitation?> createInvitation({
    required String userAId,
    required String userBId,
    required double compatibilityScore,
  }) async {
    if (compatibilityScore < minimumCompatibility) {
      return null;
    }
    final invitation = DirectMatchInvitation(
      invitationId: const Uuid().v4(),
      userAId: userAId,
      userBId: userBId,
      compatibilityScore: compatibilityScore,
      createdAtUtc: DateTime.now().toUtc(),
    );
    final box = GetStorage(_storeName);
    final raw = box.read<List<dynamic>>('invitations') ?? <dynamic>[];
    raw.add(_invitationToJson(invitation));
    await box.write('invitations', raw);
    return invitation;
  }

  Future<DirectMatchResult> respond({
    required String invitationId,
    required String userId,
    required bool accepted,
  }) async {
    final invitation = await getInvitation(invitationId);
    if (invitation == null) {
      throw StateError('Invitation not found: $invitationId');
    }
    final box = GetStorage(_storeName);
    final rawDecisions = box.read<List<dynamic>>('decisions') ?? <dynamic>[];
    rawDecisions.removeWhere(
      (entry) =>
          (entry as Map)['invitation_id'] == invitationId &&
          (entry)['user_id'] == userId,
    );
    final decision = DirectMatchDecision(
      invitationId: invitationId,
      userId: userId,
      accepted: accepted,
      decidedAtUtc: DateTime.now().toUtc(),
    );
    rawDecisions.add(_decisionToJson(decision));
    await box.write('decisions', rawDecisions);

    final decisions = await getDecisions(invitationId);
    final hasDecline = decisions.any((entry) => !entry.accepted);
    final chatOpened =
        decisions.length == 2 && decisions.every((entry) => entry.accepted);
    final result = DirectMatchResult(
      invitation: invitation,
      decisions: decisions,
      chatOpened: chatOpened,
      chatThreadId: chatOpened ? _matchedThreadId(invitation) : null,
      declineMessage: hasDecline
          ? 'This match was declined. AVRAI will keep looking for a better fit.'
          : null,
    );
    if (chatOpened) {
      final rawOpened =
          box.read<List<dynamic>>('opened_threads') ?? <dynamic>[];
      if (!rawOpened.contains(_matchedThreadId(invitation))) {
        rawOpened.add(_matchedThreadId(invitation));
        await box.write('opened_threads', rawOpened);
      }
    }
    return result;
  }

  Future<DirectMatchInvitation?> getInvitation(String invitationId) async {
    final box = GetStorage(_storeName);
    final raw = box.read<List<dynamic>>('invitations') ?? <dynamic>[];
    for (final entry in raw) {
      final invitation =
          _invitationFromJson(Map<String, dynamic>.from(entry as Map));
      if (invitation.invitationId == invitationId) {
        return invitation;
      }
    }
    return null;
  }

  Future<List<DirectMatchDecision>> getDecisions(String invitationId) async {
    final box = GetStorage(_storeName);
    final raw = box.read<List<dynamic>>('decisions') ?? <dynamic>[];
    return raw
        .map((entry) =>
            _decisionFromJson(Map<String, dynamic>.from(entry as Map)))
        .where((decision) => decision.invitationId == invitationId)
        .toList();
  }

  Future<List<DirectMatchResult>> listActiveMatches(String userId) async {
    final box = GetStorage(_storeName);
    final invitationsRaw =
        box.read<List<dynamic>>('invitations') ?? <dynamic>[];
    final openedThreads =
        box.read<List<dynamic>>('opened_threads') ?? <dynamic>[];
    final results = <DirectMatchResult>[];
    for (final entry in invitationsRaw) {
      final invitation =
          _invitationFromJson(Map<String, dynamic>.from(entry as Map));
      if (invitation.userAId != userId && invitation.userBId != userId) {
        continue;
      }
      final decisions = await getDecisions(invitation.invitationId);
      final threadId = _matchedThreadId(invitation);
      final chatOpened = openedThreads.contains(threadId);
      final hasDecline = decisions.any((decision) => !decision.accepted);
      results.add(
        DirectMatchResult(
          invitation: invitation,
          decisions: decisions,
          chatOpened: chatOpened,
          chatThreadId: chatOpened ? threadId : null,
          declineMessage: hasDecline
              ? 'This match was declined. AVRAI will keep looking for a better fit.'
              : null,
        ),
      );
    }
    return results;
  }

  Future<List<DirectMatchResult>> listAllResults() async {
    final box = GetStorage(_storeName);
    final invitationsRaw =
        box.read<List<dynamic>>('invitations') ?? <dynamic>[];
    final openedThreads =
        box.read<List<dynamic>>('opened_threads') ?? <dynamic>[];
    final results = <DirectMatchResult>[];
    for (final entry in invitationsRaw) {
      final invitation =
          _invitationFromJson(Map<String, dynamic>.from(entry as Map));
      final decisions = await getDecisions(invitation.invitationId);
      final threadId = _matchedThreadId(invitation);
      final chatOpened = openedThreads.contains(threadId);
      final hasDecline = decisions.any((decision) => !decision.accepted);
      results.add(
        DirectMatchResult(
          invitation: invitation,
          decisions: decisions,
          chatOpened: chatOpened,
          chatThreadId: chatOpened ? threadId : null,
          declineMessage: hasDecline
              ? 'This match was declined. AVRAI will keep looking for a better fit.'
              : null,
        ),
      );
    }
    return results;
  }

  String _matchedThreadId(DirectMatchInvitation invitation) {
    final ids = <String>[invitation.userAId, invitation.userBId]..sort();
    return 'matched_direct:${ids.join(':')}';
  }

  Map<String, dynamic> _invitationToJson(DirectMatchInvitation invitation) =>
      <String, dynamic>{
        'invitation_id': invitation.invitationId,
        'user_a_id': invitation.userAId,
        'user_b_id': invitation.userBId,
        'compatibility_score': invitation.compatibilityScore,
        'created_at_utc': invitation.createdAtUtc.toUtc().toIso8601String(),
        'status': invitation.status,
      };

  DirectMatchInvitation _invitationFromJson(Map<String, dynamic> json) =>
      DirectMatchInvitation(
        invitationId: json['invitation_id'] as String? ?? 'unknown_invitation',
        userAId: json['user_a_id'] as String? ?? 'unknown_user_a',
        userBId: json['user_b_id'] as String? ?? 'unknown_user_b',
        compatibilityScore:
            (json['compatibility_score'] as num?)?.toDouble() ?? 0.0,
        createdAtUtc: DateTime.tryParse(json['created_at_utc'] as String? ?? '')
                ?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        status: json['status'] as String? ?? 'pending',
      );

  Map<String, dynamic> _decisionToJson(DirectMatchDecision decision) =>
      <String, dynamic>{
        'invitation_id': decision.invitationId,
        'user_id': decision.userId,
        'accepted': decision.accepted,
        'decided_at_utc': decision.decidedAtUtc.toUtc().toIso8601String(),
      };

  DirectMatchDecision _decisionFromJson(Map<String, dynamic> json) =>
      DirectMatchDecision(
        invitationId: json['invitation_id'] as String? ?? 'unknown_invitation',
        userId: json['user_id'] as String? ?? 'unknown_user',
        accepted: json['accepted'] as bool? ?? false,
        decidedAtUtc: DateTime.tryParse(json['decided_at_utc'] as String? ?? '')
                ?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
}
