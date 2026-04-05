import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/auth/signup_page.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../helpers/widget_test_helpers.dart';
import 'package:avrai_core/models/user/user.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/sign_in_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/sign_in_with_apple_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/sign_in_with_google_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/sign_out_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/sign_up_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/update_password_usecase.dart';
import 'package:avrai_runtime_os/domain/repositories/auth_repository.dart';

Finder _signUpButtonFinder() => find.widgetWithText(ElevatedButton, 'Sign Up');

Future<void> _tapSignUp(WidgetTester tester) async {
  final button = _signUpButtonFinder();
  await tester.ensureVisible(button);
  await tester.tap(button);
}

void main() {
  const deviceCapabilitiesChannel = MethodChannel('avra/device_capabilities');

  setUpAll(() async {
    await WidgetTestHelpers.setupWidgetTestEnvironment();
  });

  tearDownAll(() async {
    await WidgetTestHelpers.cleanupWidgetTestEnvironment();
  });

  group('SignupPage Widget Tests', () {
    late _FakeAuthBloc fakeAuthBloc;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(deviceCapabilitiesChannel,
              (MethodCall methodCall) async {
        if (methodCall.method != 'getCapabilities') {
          return null;
        }
        return <String, Object?>{
          'platform': 'ios',
          'deviceModel': 'iPhone 15',
          'osVersion': '18.0',
          'totalRamMb': 8192,
          'freeDiskMb': 32768,
          'totalDiskMb': 131072,
          'cpuCores': 6,
          'isLowPowerMode': false,
        };
      });
      fakeAuthBloc = _FakeAuthBloc();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(deviceCapabilitiesChannel, null);
      fakeAuthBloc.close();
    });

    // Removed: Property assignment tests
    // Signup page tests focus on business logic (UI display, password visibility, validation, form submission), not property assignment

    testWidgets(
        'should display all required UI elements or show password visibility toggles',
        (WidgetTester tester) async {
      // Test business logic: Signup page UI display and password visibility
      fakeAuthBloc.setState(AuthInitial());
      final widget = _createTestableWidgetWithRealBloc(
        child: const SignupPage(),
        authBloc: fakeAuthBloc,
      );
      await _pumpSignupPage(tester, widget);
      expect(find.text('Sign Up'), findsNWidgets(2));
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.text('Join avrai'), findsOneWidget);
      expect(find.text('Create your account to start discovering'),
          findsOneWidget);
      expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);
      expect(find.byKey(const Key('name_field')), findsOneWidget);
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('confirm_password_field')), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      final visibilityIcons = find.byIcon(Icons.visibility);
      expect(visibilityIcons, findsNWidgets(2));
      await tester.tap(visibilityIcons.first);
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets(
        'should validate name field correctly, validate email field correctly, validate password field correctly, or validate password confirmation correctly',
        (WidgetTester tester) async {
      // Test business logic: Signup page field validation
      fakeAuthBloc.setState(AuthInitial());
      final widget = _createTestableWidgetWithRealBloc(
        child: const SignupPage(),
        authBloc: fakeAuthBloc,
      );
      await _pumpSignupPage(tester, widget);
      await tester.enterText(find.byKey(const Key('name_field')), '');
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'password123');
      await _tapSignUp(tester);
      await tester.pump();
      expect(find.text('Please enter your name'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('name_field')), 'Test User');
      await tester.enterText(find.byKey(const Key('email_field')), '');
      await _tapSignUp(tester);
      await tester.pump();
      expect(find.text('Please enter your email'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('email_field')), 'invalid-email');
      await _tapSignUp(tester);
      await tester.pump();
      expect(find.text('Please enter a valid email address'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), '');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), '');
      await _tapSignUp(tester);
      await tester.pump();
      expect(find.text('Please enter your password'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('password_field')), '123');
      await _tapSignUp(tester);
      await tester.pump();
      expect(
          find.text('Password must be at least 6 characters'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'different123');
      await _tapSignUp(tester);
      await tester.pump();
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('should submit valid registration data and show loading state',
        (WidgetTester tester) async {
      // Test business logic: Signup page form submission
      fakeAuthBloc.setState(AuthInitial());
      final widget1 = _createTestableWidgetWithRealBloc(
        child: const SignupPage(),
        authBloc: fakeAuthBloc,
      );
      await _pumpSignupPage(tester, widget1);
      await tester.enterText(find.byKey(const Key('name_field')), 'Test User');
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'password123');
      await _tapSignUp(tester);
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        fakeAuthBloc.addedEvents.whereType<SignUpRequested>().length,
        equals(1),
      );
      // Our fake bloc emits AuthLoading in response to SignUpRequested.
      // Give it a short beat to process and rebuild.
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
      expect(button.onPressed, isNull);
    });

    testWidgets('should show error message on registration failure',
        (WidgetTester tester) async {
      // Test business logic: Error state handling
      const errorMessage = 'Email already exists';
      fakeAuthBloc.setState(AuthInitial());
      final widget = _createTestableWidgetWithRealBloc(
        child: const SignupPage(),
        authBloc: fakeAuthBloc,
      );
      await _pumpSignupPage(tester, widget);
      fakeAuthBloc.setState(AuthError(errorMessage));
      await tester.pump();
      // SnackBar animates in; allow a short frame window.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('should handle confirmation-required signup state',
        (WidgetTester tester) async {
      const confirmationMessage =
          'Check your email to confirm your account before signing in.';
      fakeAuthBloc.setState(AuthInitial());
      final widget = _createTestableWidgetWithRealBloc(
        child: const SignupPage(),
        authBloc: fakeAuthBloc,
      );
      await _pumpSignupPage(tester, widget);
      fakeAuthBloc.setState(SignupConfirmationRequired(
        email: 'test@example.com',
        message: confirmationMessage,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(confirmationMessage), findsOneWidget);
    });

    testWidgets('should handle successful registration',
        (WidgetTester tester) async {
      // Test business logic: Successful registration state
      final testUser = WidgetTestHelpers.createTestUserForAuth();
      fakeAuthBloc.setState(Authenticated(user: testUser));
      final widget = _createTestableWidgetWithRealBloc(
        child: const SignupPage(),
        authBloc: fakeAuthBloc,
      );
      await _pumpSignupPage(tester, widget);
      expect(find.byType(SignupPage), findsOneWidget);
    });

    testWidgets('should dispatch Google OAuth event',
        (WidgetTester tester) async {
      fakeAuthBloc.setState(AuthInitial());
      final widget = _createTestableWidgetWithRealBloc(
        child: const SignupPage(),
        authBloc: fakeAuthBloc,
      );
      await _pumpSignupPage(tester, widget);
      await tester.tap(find.byKey(const Key('google_sign_in_button')));
      await tester.pump();
      expect(
        fakeAuthBloc.addedEvents.whereType<GoogleSignInRequested>().length,
        equals(1),
      );
    });

    testWidgets('should expose sign-in navigation action',
        (WidgetTester tester) async {
      // Test business logic: Navigation
      fakeAuthBloc.setState(AuthInitial());
      final widget = _createTestableWidgetWithRealBloc(
        child: const SignupPage(),
        authBloc: fakeAuthBloc,
      );
      await _pumpSignupPage(tester, widget);
      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(SignupPage), findsOneWidget);
    });

    testWidgets('should maintain form state during interactions',
        (WidgetTester tester) async {
      // Test business logic: Form state persistence
      fakeAuthBloc.setState(AuthInitial());
      final widget = _createTestableWidgetWithRealBloc(
        child: const SignupPage(),
        authBloc: fakeAuthBloc,
      );
      await _pumpSignupPage(tester, widget);
      await tester.enterText(find.byKey(const Key('name_field')), 'Test User');
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'password123');
      await tester.pump();
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsNWidgets(2));
    });

    testWidgets('should meet accessibility requirements',
        (WidgetTester tester) async {
      // Test business logic: Accessibility
      fakeAuthBloc.setState(AuthInitial());
      final widget = _createTestableWidgetWithRealBloc(
        child: const SignupPage(),
        authBloc: fakeAuthBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Sign Up'), findsNWidgets(2));
      expect(find.text('Sign In'), findsOneWidget);
      final nameField = tester.getSize(find.byKey(const Key('name_field')));
      expect(nameField.height, greaterThanOrEqualTo(48.0));
      final signUpButton =
          tester.getSize(find.widgetWithText(ElevatedButton, 'Sign Up').first);
      expect(signUpButton.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('should prevent submission with empty required fields',
        (WidgetTester tester) async {
      // Test business logic: Form validation
      fakeAuthBloc.setState(AuthInitial());
      final widget = _createTestableWidgetWithRealBloc(
        child: const SignupPage(),
        authBloc: fakeAuthBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await _tapSignUp(tester);
      await tester.pump();
      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
      expect(fakeAuthBloc.addedEvents.whereType<SignUpRequested>(), isEmpty);
    });

    testWidgets('should handle rapid form submission attempts',
        (WidgetTester tester) async {
      // Test business logic: Rapid submission handling
      fakeAuthBloc.setState(AuthInitial());
      final widget = _createTestableWidgetWithRealBloc(
        child: const SignupPage(),
        authBloc: fakeAuthBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.enterText(find.byKey(const Key('name_field')), 'Test User');
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'password123');
      await _tapSignUp(tester);
      await _tapSignUp(tester);
      await _tapSignUp(tester);
      await tester.pump();
      expect(
        fakeAuthBloc.addedEvents.whereType<SignUpRequested>().length,
        equals(1),
      );
    });
  });
}

/// Real fake AuthBloc with actual state management
class _FakeAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  @override
  final GetCurrentUserUseCase getCurrentUserUseCase;
  @override
  final SignInUseCase signInUseCase;
  @override
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  @override
  final SignInWithAppleUseCase signInWithAppleUseCase;
  @override
  final SignOutUseCase signOutUseCase;
  @override
  final SignUpUseCase signUpUseCase;
  @override
  final UpdatePasswordUseCase updatePasswordUseCase;
  final List<AuthEvent> addedEvents = [];

  _FakeAuthBloc({
    GetCurrentUserUseCase? getCurrentUserUseCase,
    SignInUseCase? signInUseCase,
    SignInWithGoogleUseCase? signInWithGoogleUseCase,
    SignInWithAppleUseCase? signInWithAppleUseCase,
    SignOutUseCase? signOutUseCase,
    SignUpUseCase? signUpUseCase,
    UpdatePasswordUseCase? updatePasswordUseCase,
  })  : getCurrentUserUseCase =
            getCurrentUserUseCase ?? _FakeGetCurrentUserUseCase(),
        signInUseCase = signInUseCase ?? _FakeSignInUseCase(),
        signInWithGoogleUseCase =
            signInWithGoogleUseCase ?? _FakeSignInWithGoogleUseCase(),
        signInWithAppleUseCase =
            signInWithAppleUseCase ?? _FakeSignInWithAppleUseCase(),
        signOutUseCase = signOutUseCase ?? _FakeSignOutUseCase(),
        signUpUseCase = signUpUseCase ?? _FakeSignUpUseCase(),
        updatePasswordUseCase =
            updatePasswordUseCase ?? _FakeUpdatePasswordUseCase(),
        super(AuthInitial()) {
    on<SignInRequested>(_onSignInRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<AppleSignInRequested>(_onAppleSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<UpdatePasswordRequested>(_onUpdatePasswordRequested);
  }

  void setState(AuthState state) {
    // Emit the state directly for testing
    emit(state);
  }

  @override
  void add(AuthEvent event) {
    addedEvents.add(event);
    super.add(event);
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    // In tests, we can emit states as needed
    emit(AuthLoading());
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    // In tests, we can emit states as needed
    emit(AuthLoading());
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(OAuthInProgress('google'));
  }

  Future<void> _onAppleSignInRequested(
    AppleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(OAuthInProgress('apple'));
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    emit(Unauthenticated());
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    emit(Unauthenticated());
  }

  Future<void> _onUpdatePasswordRequested(
    UpdatePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
  }
}

/// Fake repository for use cases
class _FakeAuthRepository implements AuthRepository {
  @override
  Future<User?> signIn(String email, String password) async => null;

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<User?> signUp(String email, String password, String name) async =>
      null;

  @override
  Future<void> signOut() async {}

  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<User?> updateCurrentUser(User user) async => null;

  @override
  Future<bool> isOfflineMode() async => false;

  @override
  Future<void> updateUser(User user) async {}

  @override
  Future<void> updatePassword(
      String currentPassword, String newPassword) async {}
}

/// Fake use case implementations
class _FakeGetCurrentUserUseCase extends GetCurrentUserUseCase {
  _FakeGetCurrentUserUseCase() : super(_FakeAuthRepository());
}

class _FakeSignInUseCase extends SignInUseCase {
  _FakeSignInUseCase() : super(_FakeAuthRepository());
}

class _FakeSignInWithGoogleUseCase extends SignInWithGoogleUseCase {
  _FakeSignInWithGoogleUseCase() : super(_FakeAuthRepository());
}

class _FakeSignInWithAppleUseCase extends SignInWithAppleUseCase {
  _FakeSignInWithAppleUseCase() : super(_FakeAuthRepository());
}

class _FakeSignOutUseCase extends SignOutUseCase {
  _FakeSignOutUseCase() : super(_FakeAuthRepository());
}

class _FakeSignUpUseCase extends SignUpUseCase {
  _FakeSignUpUseCase() : super(_FakeAuthRepository());
}

class _FakeUpdatePasswordUseCase extends UpdatePasswordUseCase {
  _FakeUpdatePasswordUseCase() : super(_FakeAuthRepository());
}

/// Helper to create testable widget with real BLoC
Widget _createTestableWidgetWithRealBloc({
  required Widget child,
  required Bloc<AuthEvent, AuthState> authBloc,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>.value(value: authBloc as AuthBloc),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}

Future<void> _pumpSignupPage(WidgetTester tester, Widget widget) async {
  await WidgetTestHelpers.pumpAndSettle(tester, widget);
  await tester.pump(const Duration(milliseconds: 300));
  await WidgetTestHelpers.safePumpAndSettle(tester);
}
