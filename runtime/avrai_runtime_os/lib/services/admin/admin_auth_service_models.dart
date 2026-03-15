part of 'admin_auth_service.dart';

/// Internal result class for credential verification.
class _VerifyResult {
  final bool success;
  final String? error;
  final String? controlPlaneToken;
  final String? sessionTokenId;
  final String? issuedBy;
  final Duration? sessionDuration;

  _VerifyResult({
    required this.success,
    this.error,
    this.controlPlaneToken,
    this.sessionTokenId,
    this.issuedBy,
    this.sessionDuration,
  });
}
