import 'dart:developer' as developer;
import 'dart:convert';
import 'package:avrai_runtime_os/services/admin/research_activity_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:flutter_secure_storage_x/flutter_secure_storage_x.dart';

part 'admin_auth_service_models.dart';

/// Admin Authentication Service
/// Handles god-mode admin login and session management
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable" - Admin access requires strict authentication
class AdminAuthService {
  static const String _logName = 'AdminAuthService';
  static const String _adminSessionKey = 'admin_session';
  static const String _adminSessionMirrorKey = 'admin_session_mirror';
  static const String _adminLoginAttemptsKey = 'admin_login_attempts';
  static const String _adminLockoutKey = 'admin_lockout_until';
  static const String _adminControlPlaneTokenKey =
      'admin_control_plane_session_token';

  final SharedPreferencesCompat _prefs;
  final FlutterSecureStorage? _secureStorage;
  final AdminControlPlaneGateway _gateway;

  // Maximum login attempts before lockout
  // ignore: unused_field
  static const int _maxLoginAttempts = 5;
  // ignore: unused_field - Reserved for future lockout implementation
  static const Duration _lockoutDuration = Duration(minutes: 15);

  AdminAuthService(
    this._prefs, {
    FlutterSecureStorage? secureStorage,
    AdminControlPlaneGateway? gateway,
  })  : _secureStorage = secureStorage,
        _gateway = gateway ??
            AdminControlPlaneGatewayFactory.resolveDefault(prefs: _prefs);

  /// Authenticate admin with god-mode credentials
  /// Returns true if authentication successful
  Future<AdminAuthResult> authenticate({
    required String username,
    required String password,
    String? twoFactorCode,
  }) async {
    try {
      // Check for lockout
      final lockoutUntil = _prefs.getInt(_adminLockoutKey);
      if (lockoutUntil != null &&
          DateTime.now().millisecondsSinceEpoch < lockoutUntil) {
        final remaining = Duration(
            milliseconds: lockoutUntil - DateTime.now().millisecondsSinceEpoch);
        return AdminAuthResult.lockedOut(remaining);
      }

      // Verify credentials via Supabase Edge Function
      final verifyResult =
          await _verifyCredentials(username, password, twoFactorCode);

      if (!verifyResult.success) {
        return AdminAuthResult.failed(error: verifyResult.error);
      }

      // Reset failed attempts on success
      await _prefs.remove(_adminLoginAttemptsKey);
      await _prefs.remove(_adminLockoutKey);

      // Create admin session
      final session = AdminSession(
        username: username,
        loginTime: DateTime.now().toUtc(),
        expiresAt: DateTime.now()
            .toUtc()
            .add(verifyResult.sessionDuration ?? const Duration(hours: 8)),
        accessLevel: AdminAccessLevel.godMode,
        permissions: AdminPermissions.all(),
        sessionTokenId: verifyResult.sessionTokenId,
        issuedBy: verifyResult.issuedBy ?? 'supabase_edge_admin_auth',
        requiresPrivateControlPlane: true,
      );

      await _saveSession(
        session,
        controlPlaneToken: verifyResult.controlPlaneToken,
      );

      developer.log('Admin authenticated: $username', name: _logName);
      return AdminAuthResult.success(session);
    } catch (e) {
      developer.log('Error during admin authentication: $e', name: _logName);
      return AdminAuthResult.error(e.toString());
    }
  }

  /// Verify admin credentials via Supabase Edge Function
  /// Returns a result object with success status and additional info
  Future<_VerifyResult> _verifyCredentials(
      String username, String password, String? twoFactorCode) async {
    try {
      if (!await _gateway.canConnect()) {
        return _VerifyResult(
          success: false,
          error:
              'Private admin control plane unavailable. Backend session issuance is fail-closed.',
        );
      }
      final grant = await _gateway.createSession(
        request: AdminControlPlaneSessionRequest(
          operatorAlias: username,
          oidcAssertion: base64Url.encode(
            utf8.encode(
              jsonEncode(<String, dynamic>{
                'username': username,
                'password': password,
                'exchange': 'compat_credentials_exchange',
              }),
            ),
          ),
          mfaProof: twoFactorCode ?? '',
          deviceAttestation: const AdminControlPlaneDeviceAttestation(
            deviceId: 'desktop-admin-client',
            platform: 'desktop',
            privateMeshProvider: 'headscale_tailscale',
            meshIdentity: 'private-admin-mesh',
            clientCertificateFingerprint: 'managed-device-cert',
            signedDesktopBinary: true,
            managedDevice: true,
            diskEncryptionEnabled: true,
            osPatchBaselineSatisfied: true,
          ),
          allowedGroups: const <String>['admin_operator'],
        ),
      );
      developer.log(
        'Admin credentials verified via private control plane',
        name: _logName,
      );
      return _VerifyResult(
        success: true,
        controlPlaneToken: grant.sessionToken,
        sessionTokenId: grant.sessionTokenId,
        issuedBy: grant.issuedBy,
        sessionDuration: grant.expiresAt.difference(DateTime.now().toUtc()),
      );
    } on AdminControlPlaneAuthException catch (e) {
      developer.log('Admin auth blocked by control plane: $e', name: _logName);
      return _VerifyResult(
        success: false,
        error: e.message,
      );
    } catch (e) {
      developer.log('Error verifying admin credentials: $e', name: _logName);
      return _VerifyResult(
        success: false,
        error: 'Connection error: $e',
      );
    }
  }

  /// Get current admin session
  AdminSession? getCurrentSession() {
    try {
      final sessionJson = _prefs.getString(_adminSessionMirrorKey) ??
          _prefs.getString(_adminSessionKey);
      if (sessionJson == null) return null;

      final sessionMap = jsonDecode(sessionJson) as Map<String, dynamic>;
      return AdminSession.fromJson(sessionMap);
    } catch (e) {
      developer.log('Error loading admin session: $e', name: _logName);
      return null;
    }
  }

  /// Check if admin is currently authenticated
  bool isAuthenticated() {
    final session = getCurrentSession();
    if (session == null) return false;

    // Check if session expired
    if (DateTime.now().isAfter(session.expiresAt)) {
      return false;
    }

    return true;
  }

  /// Check if admin has specific permission
  bool hasPermission(AdminPermission permission) {
    final session = getCurrentSession();
    if (session == null) return false;

    return session.permissions.hasPermission(permission);
  }

  /// Logout admin
  Future<void> logout() async {
    await _gateway.revokeActiveSession();
    await _prefs.remove(_adminSessionKey);
    await _prefs.remove(_adminSessionMirrorKey);
    await _secureStorage?.delete(key: _adminControlPlaneTokenKey);
    developer.log('Admin logged out', name: _logName);
  }

  /// Save admin session
  Future<void> _saveSession(
    AdminSession session, {
    String? controlPlaneToken,
  }) async {
    final sessionJson = jsonEncode(session.toJson());
    if (_secureStorage != null) {
      await _prefs.setString(_adminSessionMirrorKey, sessionJson);
      await _prefs.remove(_adminSessionKey);
      if (controlPlaneToken != null && controlPlaneToken.isNotEmpty) {
        await _secureStorage.write(
          key: _adminControlPlaneTokenKey,
          value: controlPlaneToken,
        );
      }
      return;
    }
    await _prefs.setString(_adminSessionKey, sessionJson);
  }

  /// Extend session
  Future<void> extendSession() async {
    final session = getCurrentSession();
    if (session != null) {
      final extendedSession = session.copyWith(
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
      );
      await _saveSession(extendedSession);
    }
  }
}

/// Admin session data
class AdminSession {
  final String username;
  final DateTime loginTime;
  final DateTime expiresAt;
  final AdminAccessLevel accessLevel;
  final AdminPermissions permissions;
  final String? sessionTokenId;
  final String? issuedBy;
  final bool requiresPrivateControlPlane;

  AdminSession({
    required this.username,
    required this.loginTime,
    required this.expiresAt,
    required this.accessLevel,
    required this.permissions,
    this.sessionTokenId,
    this.issuedBy,
    this.requiresPrivateControlPlane = false,
  });

  AdminSession copyWith({
    String? username,
    DateTime? loginTime,
    DateTime? expiresAt,
    AdminAccessLevel? accessLevel,
    AdminPermissions? permissions,
    String? sessionTokenId,
    String? issuedBy,
    bool? requiresPrivateControlPlane,
  }) {
    return AdminSession(
      username: username ?? this.username,
      loginTime: loginTime ?? this.loginTime,
      expiresAt: expiresAt ?? this.expiresAt,
      accessLevel: accessLevel ?? this.accessLevel,
      permissions: permissions ?? this.permissions,
      sessionTokenId: sessionTokenId ?? this.sessionTokenId,
      issuedBy: issuedBy ?? this.issuedBy,
      requiresPrivateControlPlane:
          requiresPrivateControlPlane ?? this.requiresPrivateControlPlane,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'loginTime': loginTime.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'accessLevel': accessLevel.name,
      'permissions': permissions.toJson(),
      'sessionTokenId': sessionTokenId,
      'issuedBy': issuedBy,
      'requiresPrivateControlPlane': requiresPrivateControlPlane,
    };
  }

  factory AdminSession.fromJson(Map<String, dynamic> json) {
    return AdminSession(
      username: json['username'] as String,
      loginTime: DateTime.parse(json['loginTime'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      accessLevel: AdminAccessLevel.values.firstWhere(
        (e) => e.name == json['accessLevel'],
        orElse: () => AdminAccessLevel.standard,
      ),
      permissions: AdminPermissions.fromJson(
          json['permissions'] as Map<String, dynamic>),
      sessionTokenId: json['sessionTokenId'] as String?,
      issuedBy: json['issuedBy'] as String?,
      requiresPrivateControlPlane:
          json['requiresPrivateControlPlane'] as bool? ?? false,
    );
  }
}

/// Admin access levels
enum AdminAccessLevel {
  standard,
  elevated,
  godMode,
}

/// Admin permissions
class AdminPermissions {
  final bool viewUserData;
  final bool viewAIData;
  final bool viewCommunications;
  final bool viewUserProgress;
  final bool viewUserPredictions;
  final bool viewBusinessAccounts;
  final bool viewRealTimeData;
  final bool modifyUserData;
  final bool modifyAIData;
  final bool modifyBusinessData;
  final bool accessAuditLogs;

  AdminPermissions({
    this.viewUserData = false,
    this.viewAIData = false,
    this.viewCommunications = false,
    this.viewUserProgress = false,
    this.viewUserPredictions = false,
    this.viewBusinessAccounts = false,
    this.viewRealTimeData = false,
    this.modifyUserData = false,
    this.modifyAIData = false,
    this.modifyBusinessData = false,
    this.accessAuditLogs = false,
  });

  factory AdminPermissions.all() {
    return AdminPermissions(
      viewUserData: true,
      viewAIData: true,
      viewCommunications: true,
      viewUserProgress: true,
      viewUserPredictions: true,
      viewBusinessAccounts: true,
      viewRealTimeData: true,
      modifyUserData: true,
      modifyAIData: true,
      modifyBusinessData: true,
      accessAuditLogs: true,
    );
  }

  bool hasPermission(AdminPermission permission) {
    switch (permission) {
      case AdminPermission.viewUserData:
        return viewUserData;
      case AdminPermission.viewAIData:
        return viewAIData;
      case AdminPermission.viewCommunications:
        return viewCommunications;
      case AdminPermission.viewUserProgress:
        return viewUserProgress;
      case AdminPermission.viewUserPredictions:
        return viewUserPredictions;
      case AdminPermission.viewBusinessAccounts:
        return viewBusinessAccounts;
      case AdminPermission.viewRealTimeData:
        return viewRealTimeData;
      case AdminPermission.modifyUserData:
        return modifyUserData;
      case AdminPermission.modifyAIData:
        return modifyAIData;
      case AdminPermission.modifyBusinessData:
        return modifyBusinessData;
      case AdminPermission.accessAuditLogs:
        return accessAuditLogs;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'viewUserData': viewUserData,
      'viewAIData': viewAIData,
      'viewCommunications': viewCommunications,
      'viewUserProgress': viewUserProgress,
      'viewUserPredictions': viewUserPredictions,
      'viewBusinessAccounts': viewBusinessAccounts,
      'viewRealTimeData': viewRealTimeData,
      'modifyUserData': modifyUserData,
      'modifyAIData': modifyAIData,
      'modifyBusinessData': modifyBusinessData,
      'accessAuditLogs': accessAuditLogs,
    };
  }

  factory AdminPermissions.fromJson(Map<String, dynamic> json) {
    return AdminPermissions(
      viewUserData: json['viewUserData'] as bool? ?? false,
      viewAIData: json['viewAIData'] as bool? ?? false,
      viewCommunications: json['viewCommunications'] as bool? ?? false,
      viewUserProgress: json['viewUserProgress'] as bool? ?? false,
      viewUserPredictions: json['viewUserPredictions'] as bool? ?? false,
      viewBusinessAccounts: json['viewBusinessAccounts'] as bool? ?? false,
      viewRealTimeData: json['viewRealTimeData'] as bool? ?? false,
      modifyUserData: json['modifyUserData'] as bool? ?? false,
      modifyAIData: json['modifyAIData'] as bool? ?? false,
      modifyBusinessData: json['modifyBusinessData'] as bool? ?? false,
      accessAuditLogs: json['accessAuditLogs'] as bool? ?? false,
    );
  }
}

/// Admin permission types
enum AdminPermission {
  viewUserData,
  viewAIData,
  viewCommunications,
  viewUserProgress,
  viewUserPredictions,
  viewBusinessAccounts,
  viewRealTimeData,
  modifyUserData,
  modifyAIData,
  modifyBusinessData,
  accessAuditLogs,
}

/// Admin authentication result
class AdminAuthResult {
  final bool success;
  final AdminSession? session;
  final String? error;
  final bool lockedOut;
  final Duration? lockoutRemaining;
  final int? remainingAttempts;

  AdminAuthResult({
    required this.success,
    this.session,
    this.error,
    this.lockedOut = false,
    this.lockoutRemaining,
    this.remainingAttempts,
  });

  factory AdminAuthResult.success(AdminSession session) {
    return AdminAuthResult(success: true, session: session);
  }

  factory AdminAuthResult.failed({String? error, int? remainingAttempts}) {
    return AdminAuthResult(
      success: false,
      error: error ?? 'Invalid credentials',
      remainingAttempts: remainingAttempts,
    );
  }

  factory AdminAuthResult.lockedOut(Duration remaining) {
    return AdminAuthResult(
      success: false,
      lockedOut: true,
      lockoutRemaining: remaining,
      error: 'Account locked. Try again in ${remaining.inMinutes} minutes.',
    );
  }

  factory AdminAuthResult.error(String error) {
    return AdminAuthResult(success: false, error: error);
  }
}
