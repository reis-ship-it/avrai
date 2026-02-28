part of 'admin_auth_service.dart';

/// Internal result class for credential verification.
class _VerifyResult {
  final bool success;
  final String? error;
  final bool lockedOut;
  final Duration? lockoutRemaining;
  final int? remainingAttempts;

  _VerifyResult({
    required this.success,
    this.error,
    this.lockedOut = false,
    this.lockoutRemaining,
    this.remainingAttempts,
  });
}
