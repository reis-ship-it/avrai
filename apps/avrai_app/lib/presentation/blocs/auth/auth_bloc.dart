// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai_core/models/user/user.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/sign_in_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/sign_in_with_apple_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/sign_in_with_google_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/sign_out_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/sign_up_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/update_password_usecase.dart';
import 'package:flutter_secure_storage_x/flutter_secure_storage_x.dart';
import 'package:avrai_runtime_os/services/matching/personality_sync_service.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai2ai/connection_orchestrator.dart';
import 'package:avrai_runtime_os/services/admin/admin_internal_use_agreement_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/oauth/oauth_deep_link_handler.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show StorageService, SharedPreferencesCompat;
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai_network/interfaces/auth_backend.dart';

// Events
abstract class AuthEvent {}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;
  final bool requireAdminInternalUseAgreement;
  final bool adminInternalUseAgreementAccepted;
  final String adminInternalUseAgreementText;

  SignInRequested(
    this.email,
    this.password, {
    this.requireAdminInternalUseAgreement = false,
    this.adminInternalUseAgreementAccepted = false,
    this.adminInternalUseAgreementText = '',
  });
}

class GoogleSignInRequested extends AuthEvent {}

class AppleSignInRequested extends AuthEvent {}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;

  SignUpRequested(this.email, this.password, this.name);
}

class SignOutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class UpdatePasswordRequested extends AuthEvent {
  final String currentPassword;
  final String newPassword;

  UpdatePasswordRequested(this.currentPassword, this.newPassword);
}

class PasswordResetRequested extends AuthEvent {
  final String email;

  PasswordResetRequested(this.email);
}

class OAuthCallbackReceived extends AuthEvent {
  final String platform;
  final Map<String, String> params;

  OAuthCallbackReceived({
    required this.platform,
    required this.params,
  });
}

class OAuthCancelled extends AuthEvent {
  final String platform;
  final String message;

  OAuthCancelled({
    required this.platform,
    required this.message,
  });
}

// States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class OAuthInProgress extends AuthState {
  final String provider;

  OAuthInProgress(this.provider);
}

class Authenticated extends AuthState {
  final User user;
  final bool isOffline;

  Authenticated({required this.user, this.isOffline = false});
}

class Unauthenticated extends AuthState {}

class PasswordResetSent extends AuthState {
  final String email;

  PasswordResetSent(this.email);
}

class SignupConfirmationRequired extends AuthState {
  final String email;
  final String message;

  SignupConfirmationRequired({
    required this.email,
    required this.message,
  });
}

class OAuthCancelledState extends AuthState {
  final String platform;
  final String message;

  OAuthCancelledState({
    required this.platform,
    required this.message,
  });
}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AppLogger _logger =
      const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final SignInUseCase signInUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignInWithAppleUseCase signInWithAppleUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final UpdatePasswordUseCase updatePasswordUseCase;
  final OAuthDeepLinkHandler? _oauthDeepLinkHandler;
  Timer? _oauthTimeout;
  String? _oauthInFlightProvider;
  bool _isCompletingOAuth = false;

  AuthBloc({
    required this.signInUseCase,
    required this.signInWithGoogleUseCase,
    required this.signInWithAppleUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
    required this.updatePasswordUseCase,
  })  : _oauthDeepLinkHandler = di.sl.isRegistered<OAuthDeepLinkHandler>()
            ? di.sl<OAuthDeepLinkHandler>()
            : null,
        super(AuthInitial()) {
    on<SignInRequested>(_onSignInRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<AppleSignInRequested>(_onAppleSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<UpdatePasswordRequested>(_onUpdatePasswordRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<OAuthCallbackReceived>(_onOAuthCallbackReceived);
    on<OAuthCancelled>(_onOAuthCancelled);

    _initializeOAuthBridge();
  }

  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final authBackend = di.sl<AuthBackend>();
      await authBackend.sendPasswordReset(event.email);
      emit(PasswordResetSent(event.email));
    } catch (e) {
      _logger.error('Password reset failed', error: e, tag: 'AuthBloc');
      emit(AuthError('Failed to send reset email. Please try again.'));
    }
  }

  void _initializeOAuthBridge() {
    final handler = _oauthDeepLinkHandler;
    if (handler == null) {
      return;
    }

    handler.onOAuthCallback = (platform, params) {
      add(OAuthCallbackReceived(platform: platform, params: params));
    };
    handler.startListening();
    unawaited(handler.getInitialLink());
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _startOAuthFlow(
      provider: 'google',
      emit: emit,
      launch: signInWithGoogleUseCase.call,
    );
  }

  Future<void> _onAppleSignInRequested(
    AppleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _startOAuthFlow(
      provider: 'apple',
      emit: emit,
      launch: signInWithAppleUseCase.call,
    );
  }

  Future<void> _startOAuthFlow({
    required String provider,
    required Emitter<AuthState> emit,
    required Future<void> Function() launch,
  }) async {
    emit(OAuthInProgress(provider));
    _oauthInFlightProvider = provider;
    _isCompletingOAuth = false;
    _oauthTimeout?.cancel();
    _oauthTimeout = Timer(const Duration(minutes: 2), () {
      add(OAuthCancelled(
        platform: provider,
        message: 'Sign-in was cancelled or timed out. Please try again.',
      ));
    });

    try {
      await launch();
    } catch (e) {
      _clearOAuthFlow();
      emit(AuthError(_formatOAuthError(e, fallbackProvider: provider)));
    }
  }

  Future<void> _onOAuthCallbackReceived(
    OAuthCallbackReceived event,
    Emitter<AuthState> emit,
  ) async {
    final provider = event.platform == 'unknown' || event.platform.isEmpty
        ? (_oauthInFlightProvider ?? 'oauth')
        : event.platform;

    final callbackError = _readOAuthCallbackError(event.params);
    if (callbackError != null) {
      final isCancelled = callbackError.toLowerCase().contains('cancel') ||
          callbackError.toLowerCase().contains('denied');
      add(OAuthCancelled(
        platform: provider,
        message: isCancelled ? 'Sign-in was cancelled.' : callbackError,
      ));
      return;
    }

    if (_isCompletingOAuth) {
      return;
    }

    _oauthInFlightProvider ??= provider;
    _isCompletingOAuth = true;
    emit(OAuthInProgress(provider));

    for (var attempt = 0; attempt < 6; attempt++) {
      final user = await getCurrentUserUseCase();
      if (user != null) {
        final isOffline = user.isOnline == false;
        _clearOAuthFlow();
        emit(Authenticated(user: user, isOffline: isOffline));
        unawaited(_postLoginInit(
          user: user,
          password: null,
          allowCloudLoad: false,
        ));
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    _clearOAuthFlow();
    emit(AuthError(
      'We returned from $provider sign-in, but the session did not finish loading. Please try again.',
    ));
  }

  Future<void> _onOAuthCancelled(
    OAuthCancelled event,
    Emitter<AuthState> emit,
  ) async {
    _clearOAuthFlow();
    emit(OAuthCancelledState(
      platform: event.platform,
      message: event.message,
    ));
  }

  /// Normalize login input for the beta email/password flow.
  ///
  /// Beta auth is intentionally email-first to match the real backend contract.
  String _normalizeEmail(String value) {
    return value.trim();
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final normalizedEmail = _normalizeEmail(event.email);
      _logger.info('🔐 AuthBloc: Attempting sign in for ${event.email}',
          tag: 'AuthBloc');
      final user = await signInUseCase(normalizedEmail, event.password);
      _logger.debug(
          '🔐 AuthBloc: Sign in result - user: ${user?.email ?? 'null'}',
          tag: 'AuthBloc');
      if (user != null) {
        if (event.requireAdminInternalUseAgreement) {
          if (!event.adminInternalUseAgreementAccepted) {
            await signOutUseCase();
            emit(AuthError(
                'Internal-use agreement is required for admin sign-in.'));
            return;
          }

          final agreementOk = await _recordAdminInternalUseAgreement(
            userId: user.id,
            agreementText: event.adminInternalUseAgreementText,
          );
          if (!agreementOk) {
            await signOutUseCase();
            emit(AuthError(
                'Admin internal-use agreement verification failed. Please try again.'));
            return;
          }
        }

        final isOffline = user.isOnline == false;
        _logger.info('🔐 AuthBloc: User authenticated successfully',
            tag: 'AuthBloc');
        _clearOAuthFlow();

        // Emit authenticated ASAP so routing/UI can proceed immediately.
        // All heavy post-login initialization runs in the background.
        emit(Authenticated(user: user, isOffline: isOffline));

        unawaited(_postLoginInit(
          user: user,
          password: event.password,
          allowCloudLoad: true,
        ));

        return;
      } else {
        _logger.warn('🔐 AuthBloc: User authentication failed - null user',
            tag: 'AuthBloc');
        emit(AuthError('Invalid credentials'));
      }
    } catch (e) {
      _logger.error('🔐 AuthBloc: Sign in error', error: e, tag: 'AuthBloc');
      final msg = e.toString();
      if (msg.contains('email_not_confirmed') ||
          msg.toLowerCase().contains('email not confirmed')) {
        emit(AuthError(
            'Email not confirmed. Ask support to confirm your account (dev: confirm the user in Supabase) and try again.'));
      } else {
        emit(AuthError(msg));
      }
    }
  }

  Future<bool> _recordAdminInternalUseAgreement({
    required String userId,
    required String agreementText,
  }) async {
    try {
      final prefs = await SharedPreferencesCompat.getInstance();
      final nonce =
          'admin_login_${DateTime.now().toUtc().microsecondsSinceEpoch}';
      final service = AdminInternalUseAgreementService(
        prefs: prefs,
        supabaseService: SupabaseService(),
      );
      return service.recordAndVerifyCurrentLogin(
        userId: userId,
        sessionNonce: nonce,
        agreementText: agreementText,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await signUpUseCase(event.email, event.password, event.name);
      if (user != null) {
        final isOffline = user.isOnline == false;
        _clearOAuthFlow();
        emit(Authenticated(user: user, isOffline: isOffline));
      } else {
        emit(AuthError(
            'Failed to create account. Please check your connection and try again.'));
      }
    } catch (e) {
      _logger.error('🔐 AuthBloc: Sign up error', error: e, tag: 'AuthBloc');
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (errorMessage.toLowerCase().contains('signup_confirmation_required')) {
        emit(SignupConfirmationRequired(
          email: event.email,
          message:
              'Check your email to confirm your account before signing in.',
        ));
        return;
      }
      emit(AuthError(
          errorMessage.isEmpty ? 'Failed to create account' : errorMessage));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Clear stored password from secure storage before sign out
      try {
        final authState = state;
        if (authState is Authenticated) {
          const secureStorage = FlutterSecureStorage();
          await secureStorage.delete(
              key: 'user_password_session_${authState.user.id}');
          _logger.debug('🔐 AuthBloc: Password cleared from secure storage',
              tag: 'AuthBloc');
        }
      } catch (e) {
        // MissingPluginException is expected in unit tests (platform channels not available)
        // Only log at debug level to avoid cluttering test output
        if (e.toString().contains('MissingPluginException')) {
          _logger.debug(
              '🔐 AuthBloc: Secure storage not available (expected in tests): $e',
              tag: 'AuthBloc');
        } else {
          _logger.warn('🔐 AuthBloc: Failed to clear password: $e',
              tag: 'AuthBloc');
        }
        // Don't block sign out if password clearing fails
      }

      await signOutUseCase();
      _clearOAuthFlow();
      try {
        final prefs = await SharedPreferencesCompat.getInstance();
        await AdminInternalUseAgreementService(
          prefs: prefs,
          supabaseService: SupabaseService(),
        ).clearSessionAgreementState();
      } catch (_) {
        // Best effort.
      }

      // Ensure AI2AI background work is stopped on sign out.
      try {
        final orchestrator = di.sl<VibeConnectionOrchestrator>();
        await orchestrator.shutdown();
      } catch (e) {
        _logger.debug('AuthBloc: Orchestrator shutdown skipped: $e',
            tag: 'AuthBloc');
      }

      emit(Unauthenticated());
    } catch (e) {
      _logger.error('🔐 AuthBloc: Sign out error', error: e, tag: 'AuthBloc');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await getCurrentUserUseCase();
      if (user != null) {
        final isOffline = user.isOnline == false;
        _clearOAuthFlow();
        emit(Authenticated(user: user, isOffline: isOffline));

        // Background init (no password available during auth-check).
        unawaited(_postLoginInit(
          user: user,
          password: null,
          allowCloudLoad: false,
        ));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _postLoginInit({
    required User user,
    required String? password,
    required bool allowCloudLoad,
  }) async {
    // Store password temporarily in secure storage for cloud sync operations.
    if (password != null && password.isNotEmpty) {
      try {
        const secureStorage = FlutterSecureStorage();
        await secureStorage.write(
          key: 'user_password_session_${user.id}',
          value: password,
        );
        _logger.debug('🔐 AuthBloc: Password stored in secure storage for sync',
            tag: 'AuthBloc');
      } catch (e) {
        // MissingPluginException is expected in unit tests (platform channels not available)
        if (e.toString().contains('MissingPluginException')) {
          _logger.debug(
              '🔐 AuthBloc: Secure storage not available (expected in tests): $e',
              tag: 'AuthBloc');
        } else {
          _logger.warn('🔐 AuthBloc: Failed to store password for sync: $e',
              tag: 'AuthBloc');
        }
      }
    }

    // Initialize personality (cloud load if enabled and we have a password).
    PersonalityProfile? profile;
    try {
      final personalityLearning = di.sl<PersonalityLearning>();
      if (allowCloudLoad && password != null && password.isNotEmpty) {
        final syncService = di.sl<PersonalitySyncService>();
        final syncEnabled = await syncService.isCloudSyncEnabled(user.id);
        if (syncEnabled) {
          _logger.info(
              '☁️ AuthBloc: Cloud sync enabled, initializing personality with cloud load...',
              tag: 'AuthBloc');
          profile = await personalityLearning.initializePersonality(
            user.id,
            password: password,
          );
          _logger.info(
              '✅ AuthBloc: Personality initialized (may have loaded from cloud)',
              tag: 'AuthBloc');
        } else {
          profile = await personalityLearning.initializePersonality(user.id);
        }
      } else {
        profile = await personalityLearning.initializePersonality(user.id);
      }
    } catch (e) {
      _logger.warn('⚠️ AuthBloc: Personality init failed/skipped: $e',
          tag: 'AuthBloc');
    }

    // Start/stop AI2AI orchestration based on the discovery switch.
    try {
      final discoveryEnabled =
          StorageService.instance.getBool('discovery_enabled') ?? false;
      final orchestrator = di.sl<VibeConnectionOrchestrator>();
      if (!discoveryEnabled) {
        await orchestrator.shutdown();
      } else {
        final personalityLearning = di.sl<PersonalityLearning>();
        profile ??= await personalityLearning.getCurrentPersonality(user.id) ??
            await personalityLearning.initializePersonality(user.id);
        await orchestrator.initializeOrchestration(user.id, profile);
      }
    } catch (e) {
      _logger.debug('AuthBloc: AI2AI post-login init skipped: $e',
          tag: 'AuthBloc');
    }
  }

  String? _readOAuthCallbackError(Map<String, String> params) {
    final error = params['error'];
    final description = params['error_description'] ?? params['error_code'];
    if (error == null || error.isEmpty) {
      return null;
    }

    if (description != null && description.isNotEmpty) {
      return '$error: $description';
    }

    return error;
  }

  String _formatOAuthError(Object error, {required String fallbackProvider}) {
    final raw = error.toString().replaceFirst('Exception: ', '');
    final normalized = raw.toLowerCase();
    if (normalized.contains('cancel') || normalized.contains('denied')) {
      return 'Sign-in with $fallbackProvider was cancelled.';
    }
    if (normalized.contains('identity') ||
        normalized.contains('already exists') ||
        normalized.contains('already registered') ||
        normalized.contains('duplicate')) {
      return 'This email already belongs to another sign-in method. Use your existing login method for now.';
    }
    if (normalized.contains('network') || normalized.contains('connection')) {
      return 'Network error while starting $fallbackProvider sign-in. Please try again.';
    }

    return raw.isEmpty ? 'Unable to start $fallbackProvider sign-in.' : raw;
  }

  void _clearOAuthFlow() {
    _oauthTimeout?.cancel();
    _oauthTimeout = null;
    _oauthInFlightProvider = null;
    _isCompletingOAuth = false;
  }

  Future<void> _onUpdatePasswordRequested(
    UpdatePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Capture authenticated state BEFORE emitting AuthLoading
    // (state will be AuthLoading after emit, so we need to capture it first)
    final authState = state is Authenticated ? state as Authenticated : null;

    // Emit loading state FIRST (before any async operations)
    // This ensures blocTest captures the state immediately
    emit(AuthLoading());

    if (authState == null) {
      emit(AuthError('Must be authenticated to change password'));
      return;
    }

    try {
      final userId = authState.user.id;
      _logger.info('🔐 AuthBloc: Updating password for user: $userId',
          tag: 'AuthBloc');

      // Re-encrypt personality profile with new password BEFORE updating password
      // This ensures we can decrypt with old password, then re-encrypt with new
      try {
        final syncService = di.sl<PersonalitySyncService>();
        final syncEnabled = await syncService.isCloudSyncEnabled(userId);

        if (syncEnabled) {
          _logger.info(
            '☁️ AuthBloc: Cloud sync enabled, re-encrypting profile with new password...',
            tag: 'AuthBloc',
          );
          await syncService.reEncryptWithNewPassword(
            userId,
            event.currentPassword,
            event.newPassword,
          );
          _logger.info('✅ AuthBloc: Profile re-encrypted successfully',
              tag: 'AuthBloc');
        }
      } catch (e) {
        // Catch both Exception and Error (like StateError from GetIt)
        _logger.error(
          '❌ AuthBloc: Failed to re-encrypt profile: $e',
          error: e,
          tag: 'AuthBloc',
        );
        // Don't block password update if re-encryption fails
        // User will lose cloud access but can still change password
        _logger.warn(
          '⚠️ AuthBloc: Password will be updated but cloud profile may be inaccessible',
          tag: 'AuthBloc',
        );
      }

      // Update password in auth system
      await updatePasswordUseCase(event.currentPassword, event.newPassword);

      // Update stored password in secure storage
      try {
        const secureStorage = FlutterSecureStorage();
        await secureStorage.write(
          key: 'user_password_session_$userId',
          value: event.newPassword,
        );
        _logger.debug('🔐 AuthBloc: Updated password in secure storage',
            tag: 'AuthBloc');
      } catch (e) {
        // MissingPluginException is expected in unit tests (platform channels not available)
        // Only log at debug level to avoid cluttering test output
        if (e.toString().contains('MissingPluginException')) {
          _logger.debug(
              '🔐 AuthBloc: Secure storage not available (expected in tests): $e',
              tag: 'AuthBloc');
        } else {
          _logger.warn(
              '🔐 AuthBloc: Failed to update password in secure storage: $e',
              tag: 'AuthBloc');
        }
        // Don't block - password is updated in auth system
      }

      _logger.info('✅ AuthBloc: Password updated successfully',
          tag: 'AuthBloc');

      // Re-emit authenticated state (user is still authenticated)
      emit(Authenticated(user: authState.user, isOffline: authState.isOffline));
    } catch (e) {
      // Catch both Exception and Error types
      _logger.error('🔐 AuthBloc: Password update error',
          error: e, tag: 'AuthBloc');
      final errorMessage = e is Error
          ? 'Failed to update password: ${e.toString()}'
          : 'Failed to update password: ${e.toString()}';
      emit(AuthError(errorMessage));
    }
  }

  @override
  Future<void> close() {
    _clearOAuthFlow();
    if (_oauthDeepLinkHandler?.onOAuthCallback != null) {
      _oauthDeepLinkHandler?.onOAuthCallback = null;
    }
    return super.close();
  }
}
