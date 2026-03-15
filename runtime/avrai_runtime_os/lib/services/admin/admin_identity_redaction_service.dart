import 'package:avrai_runtime_os/services/admin/admin_privacy_filter.dart';
import 'package:avrai_runtime_os/services/admin/bham_admin_models.dart';
import 'package:avrai_runtime_os/services/messaging/bham_messaging_models.dart';

class AdminIdentityRedactionService {
  const AdminIdentityRedactionService({
    this.policy = const AdminIdentityRedactionPolicy(),
  });

  final AdminIdentityRedactionPolicy policy;

  AdminRedactedView redactActor(
    String rawId, {
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final normalized = rawId.trim();
    final token = _tokenFor(normalized);
    return AdminRedactedView(
      subjectId: normalized,
      displayLabel: '${policy.labelPrefix}-$token',
      initials: token.substring(0, 2),
      metadata: metadata,
    );
  }

  String redactText(String value) {
    var next = value;
    next = next.replaceAll(
      RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}', caseSensitive: false),
      '[redacted-email]',
    );
    next = next.replaceAll(
      RegExp(r'(\+?\d[\d\-\(\) ]{6,}\d)'),
      '[redacted-phone]',
    );
    next = next.replaceAll(RegExp(r'@[A-Za-z0-9_]+'), '@[redacted]');
    return next;
  }

  Map<String, dynamic> redactMap(Map<String, dynamic> data) {
    return AdminPrivacyFilter.filterPersonalData(data);
  }

  ChatParticipantPresentation redactParticipant(String participantId) {
    final redacted = redactActor(participantId);
    return ChatParticipantPresentation(
      participantId: participantId,
      displayName: redacted.displayLabel,
      initials: redacted.initials,
      pseudonymous: true,
    );
  }

  String _tokenFor(String value) {
    final source = value.isEmpty ? 'anon' : value;
    final hash = source.codeUnits.fold<int>(17, (acc, unit) {
      return (acc * 37 + unit) & 0x7fffffff;
    });
    return hash.toRadixString(16).padLeft(6, '0').substring(0, 6).toUpperCase();
  }
}
