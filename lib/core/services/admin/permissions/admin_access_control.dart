import 'package:avrai/core/services/admin/permissions/admin_permission_checker.dart';
import 'package:avrai/core/services/admin/admin_auth_service.dart';

/// Admin access control wrapper
/// Provides authorization helpers and exception handling
/// Phase 1.6: Extracted from AdminGodModeService
class AdminAccessControl {
  final AdminPermissionChecker _permissionChecker;

  AdminAccessControl({required AdminPermissionChecker permissionChecker})
      : _permissionChecker = permissionChecker;

  /// Check if god-mode access is authorized
  /// Throws UnauthorizedException if not authorized
  void requireAuthorization() {
    if (!_permissionChecker.isAuthorized) {
      throw UnauthorizedException('God-mode access required');
    }
  }

  /// Check if admin has a specific permission
  /// Throws UnauthorizedException if permission denied
  void requirePermission(AdminPermission permission) {
    if (!_permissionChecker.hasPermission(permission)) {
      throw UnauthorizedException('Permission required: $permission');
    }
  }

  /// Check if admin can view user data
  /// Throws UnauthorizedException if denied
  void requireViewUserData() {
    if (!_permissionChecker.canViewUserData()) {
      throw UnauthorizedException('View user data permission required');
    }
  }

  /// Check if admin can view AI data
  /// Throws UnauthorizedException if denied
  void requireViewAIData() {
    if (!_permissionChecker.canViewAIData()) {
      throw UnauthorizedException('View AI data permission required');
    }
  }

  /// Check if admin can view communications
  /// Throws UnauthorizedException if denied
  void requireViewCommunications() {
    if (!_permissionChecker.canViewCommunications()) {
      throw UnauthorizedException('View communications permission required');
    }
  }

  /// Check if admin can view real-time data
  /// Throws UnauthorizedException if denied
  void requireViewRealTimeData() {
    if (!_permissionChecker.canViewRealTimeData()) {
      throw UnauthorizedException('View real-time data permission required');
    }
  }

  /// Get the permission checker (for direct access if needed)
  AdminPermissionChecker get permissionChecker => _permissionChecker;
}

/// Exception thrown when admin operation is unauthorized
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}
