import 'dart:developer' as developer;
import 'dart:convert';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

part 'business_auth_service_models.dart';

/// Business Authentication Service
/// Handles business login and session management
/// Similar to AdminAuthService but for business accounts
class BusinessAuthService {
  static const String _logName = 'BusinessAuthService';
  static const String _businessSessionKey = 'business_session';
  static const String _businessLoginAttemptsKey = 'business_login_attempts';
  static const String _businessLockoutKey = 'business_lockout_until';

  final SharedPreferencesCompat _prefs;

  BusinessAuthService(this._prefs);

  /// Authenticate business with credentials
  /// Returns BusinessAuthResult with success status
  Future<BusinessAuthResult> authenticate({
    required String username,
    required String password,
    String? twoFactorCode,
  }) async {
    try {
      // Check for lockout
      final lockoutUntil = _prefs.getInt(_businessLockoutKey);
      if (lockoutUntil != null &&
          DateTime.now().millisecondsSinceEpoch < lockoutUntil) {
        final remaining = Duration(
            milliseconds: lockoutUntil - DateTime.now().millisecondsSinceEpoch);
        return BusinessAuthResult.lockedOut(remaining);
      }

      // Verify credentials via Supabase Edge Function
      final verifyResult =
          await _verifyCredentials(username, password, twoFactorCode);

      if (!verifyResult.success) {
        // Handle lockout from server
        if (verifyResult.lockedOut && verifyResult.lockoutRemaining != null) {
          final lockoutUntil = DateTime.now()
              .add(verifyResult.lockoutRemaining!)
              .millisecondsSinceEpoch;
          await _prefs.setInt(_businessLockoutKey, lockoutUntil);
          return BusinessAuthResult.lockedOut(verifyResult.lockoutRemaining!);
        }

        // Handle failed attempts
        if (verifyResult.remainingAttempts != null) {
          return BusinessAuthResult.failed(
            error: verifyResult.error,
            remainingAttempts: verifyResult.remainingAttempts,
          );
        }

        return BusinessAuthResult.failed(error: verifyResult.error);
      }

      // Reset failed attempts on success
      await _prefs.remove(_businessLoginAttemptsKey);
      await _prefs.remove(_businessLockoutKey);

      // Create business session
      final session = BusinessSession(
        businessId: verifyResult.businessId!,
        username: username,
        loginTime: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
        accessLevel: BusinessAccessLevel.business,
      );

      await _saveSession(session);

      developer.log(
          'Business authenticated: $username (business: ${verifyResult.businessId})',
          name: _logName);
      return BusinessAuthResult.success(session);
    } catch (e) {
      developer.log('Error during business authentication: $e', name: _logName);
      return BusinessAuthResult.error(e.toString());
    }
  }

  /// Verify business credentials via Supabase Edge Function
  /// Returns a result object with success status and additional info
  Future<_VerifyResult> _verifyCredentials(
      String username, String password, String? twoFactorCode) async {
    try {
      final supabaseService = SupabaseService();

      // Check if Supabase is available before trying to use it
      if (!supabaseService.isAvailable) {
        developer.log(
          'Supabase not initialized - cannot verify business credentials',
          name: _logName,
        );
        return _VerifyResult(
          success: false,
          error:
              'Backend service unavailable. Please configure Supabase credentials.',
        );
      }

      // Get client (we know it's available from the check above)
      final client = supabaseService.client;

      // Call the business-auth edge function
      final response = await client.functions.invoke(
        'business-auth',
        body: {
          'username': username,
          'password': password,
          if (twoFactorCode != null) 'twoFactorCode': twoFactorCode,
        },
      );

      // Parse response data - handle both Map and String responses
      Map<String, dynamic>? data;
      if (response.data is Map) {
        data = response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        try {
          data = jsonDecode(response.data as String) as Map<String, dynamic>;
        } catch (e) {
          developer.log('Failed to parse edge function response: $e',
              name: _logName);
          return _VerifyResult(
            success: false,
            error: 'Invalid response from server',
          );
        }
      }

      if (response.status == 200 && data?['success'] == true) {
        developer.log('Business credentials verified successfully',
            name: _logName);
        return _VerifyResult(
          success: true,
          businessId: data?['businessId'] as String?,
        );
      }

      // Handle error responses
      final error = data?['error'] as String? ?? 'Authentication failed';
      final lockedOut = data?['lockedOut'] as bool? ?? false;
      final lockoutRemaining = data?['lockoutRemaining'] as int?;
      final remainingAttempts = data?['remainingAttempts'] as int?;

      developer.log('Business auth failed: $error (status: ${response.status})',
          name: _logName);

      return _VerifyResult(
        success: false,
        error: error,
        lockedOut: lockedOut,
        lockoutRemaining: lockoutRemaining != null
            ? Duration(minutes: lockoutRemaining)
            : null,
        remainingAttempts: remainingAttempts,
      );
    } catch (e) {
      developer.log('Error verifying business credentials: $e', name: _logName);
      return _VerifyResult(
        success: false,
        error: 'Connection error: $e',
      );
    }
  }

  /// Get current business session
  BusinessSession? getCurrentSession() {
    try {
      final sessionJson = _prefs.getString(_businessSessionKey);
      if (sessionJson == null) return null;

      final sessionMap = jsonDecode(sessionJson) as Map<String, dynamic>;
      return BusinessSession.fromJson(sessionMap);
    } catch (e) {
      developer.log('Error loading business session: $e', name: _logName);
      return null;
    }
  }

  /// Check if business is currently authenticated
  bool isAuthenticated() {
    final session = getCurrentSession();
    if (session == null) return false;

    // Check if session expired
    if (DateTime.now().isAfter(session.expiresAt)) {
      logout();
      return false;
    }

    return true;
  }

  /// Get current business ID from session
  String? getCurrentBusinessId() {
    final session = getCurrentSession();
    return session?.businessId;
  }

  /// Logout business
  Future<void> logout() async {
    await _prefs.remove(_businessSessionKey);
    developer.log('Business logged out', name: _logName);
  }

  /// Save business session
  Future<void> _saveSession(BusinessSession session) async {
    final sessionJson = jsonEncode(session.toJson());
    await _prefs.setString(_businessSessionKey, sessionJson);
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

/// Business session data
class BusinessSession {
  final String businessId;
  final String username;
  final DateTime loginTime;
  final DateTime expiresAt;
  final BusinessAccessLevel accessLevel;

  BusinessSession({
    required this.businessId,
    required this.username,
    required this.loginTime,
    required this.expiresAt,
    required this.accessLevel,
  });

  BusinessSession copyWith({
    String? businessId,
    String? username,
    DateTime? loginTime,
    DateTime? expiresAt,
    BusinessAccessLevel? accessLevel,
  }) {
    return BusinessSession(
      businessId: businessId ?? this.businessId,
      username: username ?? this.username,
      loginTime: loginTime ?? this.loginTime,
      expiresAt: expiresAt ?? this.expiresAt,
      accessLevel: accessLevel ?? this.accessLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'username': username,
      'loginTime': loginTime.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'accessLevel': accessLevel.name,
    };
  }

  factory BusinessSession.fromJson(Map<String, dynamic> json) {
    return BusinessSession(
      businessId: json['businessId'] as String,
      username: json['username'] as String,
      loginTime: DateTime.parse(json['loginTime'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      accessLevel: BusinessAccessLevel.values.firstWhere(
        (e) => e.name == json['accessLevel'],
        orElse: () => BusinessAccessLevel.business,
      ),
    );
  }
}

/// Business access levels
enum BusinessAccessLevel {
  business,
  verifiedBusiness,
  premiumBusiness,
}

/// Business authentication result
class BusinessAuthResult {
  final bool success;
  final BusinessSession? session;
  final String? error;
  final bool lockedOut;
  final Duration? lockoutRemaining;
  final int? remainingAttempts;

  BusinessAuthResult({
    required this.success,
    this.session,
    this.error,
    this.lockedOut = false,
    this.lockoutRemaining,
    this.remainingAttempts,
  });

  factory BusinessAuthResult.success(BusinessSession session) {
    return BusinessAuthResult(success: true, session: session);
  }

  factory BusinessAuthResult.failed({String? error, int? remainingAttempts}) {
    return BusinessAuthResult(
      success: false,
      error: error ?? 'Invalid credentials',
      remainingAttempts: remainingAttempts,
    );
  }

  factory BusinessAuthResult.lockedOut(Duration remaining) {
    return BusinessAuthResult(
      success: false,
      lockedOut: true,
      lockoutRemaining: remaining,
      error: 'Account locked. Try again in ${remaining.inMinutes} minutes.',
    );
  }

  factory BusinessAuthResult.error(String error) {
    return BusinessAuthResult(success: false, error: error);
  }
}
