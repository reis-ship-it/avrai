import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for persisting and retrieving user permissions per user
/// Ensures permissions are remembered across app sessions
///
/// Phase 26: Migrated from Sembast to GetStorage
class PermissionsPersistenceService {
  static const AppLogger _logger = AppLogger(
    defaultTag: 'PermissionsPersistence',
    minimumLevel: LogLevel.debug,
  );

  static const String _keyPrefix = 'user_permissions_';

  final GetStorage _box = GetStorage('user_permissions');

  /// Initialize storage (call during app startup)
  static Future<void> initStorage() async {
    await GetStorage.init('user_permissions');
  }

  /// Store permissions for a specific user
  Future<void> saveUserPermissions(
    String userId,
    Map<Permission, PermissionStatus> permissions,
  ) async {
    try {
      _logger.info('💾 Saving permissions for user: $userId',
          tag: 'PermissionsPersistence');

      // Convert permissions to JSON-serializable format
      final permissionsMap = <String, String>{};
      permissions.forEach((permission, status) {
        permissionsMap[permission.toString()] = status.toString();
      });

      final record = {
        'userId': userId,
        'permissions': permissionsMap,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _box.write('$_keyPrefix$userId', record);
      _logger.info('✅ Permissions saved for user: $userId',
          tag: 'PermissionsPersistence');
    } catch (e, stackTrace) {
      _logger.error('❌ Error saving permissions',
          error: e, tag: 'PermissionsPersistence');
      _logger.debug('Stack trace: $stackTrace', tag: 'PermissionsPersistence');
    }
  }

  /// Get saved permissions for a specific user
  Future<Map<Permission, PermissionStatus>?> getUserPermissions(
      String userId) async {
    try {
      _logger.debug('🔍 Loading permissions for user: $userId',
          tag: 'PermissionsPersistence');

      final record = _box.read<Map<String, dynamic>>('$_keyPrefix$userId');

      if (record == null) {
        _logger.debug('📭 No saved permissions found for user: $userId',
            tag: 'PermissionsPersistence');
        return null;
      }

      final permissionsMap = record['permissions'] as Map<String, dynamic>?;
      if (permissionsMap == null) {
        return null;
      }

      // Convert back to Permission -> PermissionStatus map
      final result = <Permission, PermissionStatus>{};
      for (final entry in permissionsMap.entries) {
        // Parse permission string (e.g., "Permission.locationWhenInUse")
        final permission = _parsePermission(entry.key);
        if (permission != null) {
          final status = _parsePermissionStatus(entry.value as String);
          if (status != null) {
            result[permission] = status;
          }
        }
      }

      _logger.info('✅ Loaded ${result.length} permissions for user: $userId',
          tag: 'PermissionsPersistence');
      return result;
    } catch (e, stackTrace) {
      _logger.error('❌ Error loading permissions',
          error: e, tag: 'PermissionsPersistence');
      _logger.debug('Stack trace: $stackTrace', tag: 'PermissionsPersistence');
      return null;
    }
  }

  /// Check if user has critical permissions saved
  Future<bool> hasCriticalPermissions(String userId) async {
    try {
      final savedPermissions = await getUserPermissions(userId);
      if (savedPermissions == null || savedPermissions.isEmpty) {
        return false;
      }

      // Check if all critical permissions are granted
      final criticalPermissions = [
        Permission.locationWhenInUse,
        Permission.locationAlways,
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ];

      for (final permission in criticalPermissions) {
        final status = savedPermissions[permission];
        if (status == null ||
            (!status.isGranted && !status.isLimited && !status.isProvisional)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      _logger.error('❌ Error checking critical permissions',
          error: e, tag: 'PermissionsPersistence');
      return false;
    }
  }

  /// Clear permissions for a user (e.g., on logout)
  Future<void> clearUserPermissions(String userId) async {
    try {
      _logger.info('🗑️ Clearing permissions for user: $userId',
          tag: 'PermissionsPersistence');

      await _box.remove('$_keyPrefix$userId');
      _logger.info('✅ Permissions cleared for user: $userId',
          tag: 'PermissionsPersistence');
    } catch (e, stackTrace) {
      _logger.error('❌ Error clearing permissions',
          error: e, tag: 'PermissionsPersistence');
      _logger.debug('Stack trace: $stackTrace', tag: 'PermissionsPersistence');
    }
  }

  /// Helper to parse Permission from string
  Permission? _parsePermission(String permissionString) {
    // Map permission strings to Permission enum values
    final permissionMap = {
      'Permission.locationWhenInUse': Permission.locationWhenInUse,
      'Permission.locationAlways': Permission.locationAlways,
      'Permission.bluetooth': Permission.bluetooth,
      'Permission.bluetoothScan': Permission.bluetoothScan,
      'Permission.bluetoothConnect': Permission.bluetoothConnect,
      'Permission.bluetoothAdvertise': Permission.bluetoothAdvertise,
      'Permission.nearbyWifiDevices': Permission.nearbyWifiDevices,
    };

    return permissionMap[permissionString];
  }

  /// Helper to parse PermissionStatus from string
  PermissionStatus? _parsePermissionStatus(String statusString) {
    // Map status strings to PermissionStatus enum values
    final statusMap = {
      'PermissionStatus.granted': PermissionStatus.granted,
      'PermissionStatus.denied': PermissionStatus.denied,
      'PermissionStatus.restricted': PermissionStatus.restricted,
      'PermissionStatus.limited': PermissionStatus.limited,
      'PermissionStatus.permanentlyDenied': PermissionStatus.permanentlyDenied,
      'PermissionStatus.provisional': PermissionStatus.provisional,
    };

    return statusMap[statusString];
  }
}
