import 'package:avrai/core/services/admin/admin_auth_service.dart';

/// Centralized permission checking for admin operations
/// Phase 1.6: Extracted from AdminGodModeService
class AdminPermissionChecker {
  final AdminAuthService _authService;

  AdminPermissionChecker({required AdminAuthService authService})
      : _authService = authService;

  /// Check if admin is authenticated
  bool get isAuthenticated => _authService.isAuthenticated();

  /// Check if admin has god-mode access (viewRealTimeData permission)
  bool get isAuthorized {
    if (!isAuthenticated) return false;
    return _authService.hasPermission(AdminPermission.viewRealTimeData);
  }

  /// Check if admin has a specific permission
  bool hasPermission(AdminPermission permission) {
    if (!isAuthenticated) return false;
    return _authService.hasPermission(permission);
  }

  /// Check if admin can view user data
  bool canViewUserData() => hasPermission(AdminPermission.viewUserData);

  /// Check if admin can view AI data
  bool canViewAIData() => hasPermission(AdminPermission.viewAIData);

  /// Check if admin can view communications
  bool canViewCommunications() =>
      hasPermission(AdminPermission.viewCommunications);

  /// Check if admin can view user progress
  bool canViewUserProgress() =>
      hasPermission(AdminPermission.viewUserProgress);

  /// Check if admin can view user predictions
  bool canViewUserPredictions() =>
      hasPermission(AdminPermission.viewUserPredictions);

  /// Check if admin can view business accounts
  bool canViewBusinessAccounts() =>
      hasPermission(AdminPermission.viewBusinessAccounts);

  /// Check if admin can view real-time data
  bool canViewRealTimeData() =>
      hasPermission(AdminPermission.viewRealTimeData);

  /// Check if admin can modify user data
  bool canModifyUserData() => hasPermission(AdminPermission.modifyUserData);

  /// Check if admin can modify AI data
  bool canModifyAIData() => hasPermission(AdminPermission.modifyAIData);

  /// Check if admin can modify business data
  bool canModifyBusinessData() =>
      hasPermission(AdminPermission.modifyBusinessData);

  /// Check if admin can access audit logs
  bool canAccessAuditLogs() =>
      hasPermission(AdminPermission.accessAuditLogs);
}
