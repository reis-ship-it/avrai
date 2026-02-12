import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/auth/login_page.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../helpers/widget_test_helpers.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/models/user/user.dart';
import 'package:avrai/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:avrai/domain/usecases/auth/sign_in_usecase.dart';
import 'package:avrai/domain/usecases/auth/sign_out_usecase.dart';
import 'package:avrai/domain/usecases/auth/sign_up_usecase.dart';
import 'package:avrai/domain/usecases/auth/update_password_usecase.dart';
import 'package:avrai/domain/repositories/auth_repository.dart';

void main() {
  group('LoginPage Widget Tests', () {
    late _FakeAuthBloc fakeAuthBloc;

    setUp(() {
      fakeAuthBloc = _FakeAuthBloc();
    });

    tearDown(() {
      fakeAuthBloc.close();
    });

    // Removed: Property assignment tests
    // Login page tests focus on business logic (UI display, password visibility, validation, form submission), not property assignment

    testWidgets(
        'should display all required UI elements or show password visibility toggle',
        (WidgetTester tester) async {
      // Test business logic: Login page UI display and password visibility
      fakeAuthBloc.setState(AuthInitial());
      final widget = _createTestableWidgetWithRealBloc(
        child: const LoginPage(),
        authBloc: fakeAuthBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.text('SPOTS'), findsOneWidget);
      expect(find.text('Discover meaningful places'), findsOneWidget);
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('🧪 Demo Login'), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets(
        'should validate email field correctly or validate password field correctly',
        (WidgetTester tester) async {
      // Test business logic: Login page field validation
      fakeAuthBloc.setState(AuthInitial());
      final widget = _createTestableWidgetWithRealBloc(
        child: const LoginPage(),
        authBloc: fakeAuthBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.enterText(find.byKey(const Key('email_field')), '');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(find.text('Please enter your email or username'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('email_field')), 'ab');
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(
        find.text('Username must be 3+ chars (letters/numbers/._-)'),
        findsOneWidget,
      );
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), '');
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(find.text('Please enter your password'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('password_field')), '123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(
          find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets(
        'should submit valid credentials and show loading state',
        (WidgetTester tester) async {
      // Test business logic: Form submission
      fakeAuthBloc.setState(AuthInitial());
      final widget1 = _createTestableWidgetWithRealBloc(
        child: const LoginPage(),
        authBloc: fakeAuthBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        fakeAuthBloc.addedEvents.whereType<SignInRequested>().length,
        equals(1),
      );
      // Loading UI should render once submit begins (either via bloc state or local submit gating).
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
      expect(button.onPressed, isNull);
    });

    testWidgets(
        'should show error message on authentication failure',
        (WidgetTester tester) async {
      // Test business logic: Error state handling
      const errorMessage = 'Invalid credentials';
      fakeAuthBloc.setState(AuthInitial());
      final widget = _createTestableWidgetWithRealBloc(
        child: const LoginPage(),
        authBloc: fakeAuthBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      // SnackBar is shown via BlocListener on state changes, not initial state.
      fakeAuthBloc.setState(AuthError(errorMessage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets(
        'should handle successful authentication',
        (WidgetTester tester) async {
      // Test business logic: Successful authentication state
      final testUser = WidgetTestHelpers.createTestUserForAuth();
      fakeAuthBloc.setState(Authenticated(user: testUser));
      final navigatorObserver = NavigatorObserver();
      final widget = _createTestableWidgetWithRealBloc(
        child: const LoginPage(),
        authBloc: fakeAuthBloc,
        navigatorObserver: navigatorObserver,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets(
        'should have demo login button fill credentials',
        (WidgetTester tester) async {
      // Test business logic: Demo login functionality
      fakeAuthBloc.setState(AuthInitial());
      final widget = _createTestableWidgetWithRealBloc(
        child: const LoginPage(),
        authBloc: fakeAuthBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.tap(find.text('🧪 Demo Login'));
      await tester.pump();
      expect(find.text('demo@spots.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets(
        'should maintain state during screen rotations',
        (WidgetTester tester) async {
      // Test business logic: State persistence during orientation changes
      fakeAuthBloc.setState(AuthInitial());
      final widget = _createTestableWidgetWithRealBloc(
        child: const LoginPage(),
        authBloc: fakeAuthBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');
      tester.view.physicalSize = const Size(800, 600);
      await tester.pump();
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
      tester.view.resetPhysicalSize();
    });

    testWidgets(
        'should meet accessibility requirements',
        (WidgetTester tester) async {
      // Test business logic: Accessibility
      fakeAuthBloc.setState(AuthInitial());
      final widget = _createTestableWidgetWithRealBloc(
        child: const LoginPage(),
        authBloc: fakeAuthBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.text('Email or username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      final emailField = tester.getSize(find.byKey(const Key('email_field')));
      expect(emailField.height, greaterThanOrEqualTo(48.0));
      final signInButton =
          tester.getSize(find.widgetWithText(ElevatedButton, 'Sign In').first);
      expect(signInButton.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets(
        'should handle rapid tap events gracefully',
        (WidgetTester tester) async {
      // Test business logic: Rapid submission handling
      fakeAuthBloc.setState(AuthInitial());
      final widget = _createTestableWidgetWithRealBloc(
        child: const LoginPage(),
        authBloc: fakeAuthBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(
        fakeAuthBloc.addedEvents.whereType<SignInRequested>().length,
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
  final SignOutUseCase signOutUseCase;
  @override
  final SignUpUseCase signUpUseCase;
  @override
  final UpdatePasswordUseCase updatePasswordUseCase;
  final List<AuthEvent> addedEvents = [];

  _FakeAuthBloc({
    GetCurrentUserUseCase? getCurrentUserUseCase,
    SignInUseCase? signInUseCase,
    SignOutUseCase? signOutUseCase,
    SignUpUseCase? signUpUseCase,
    UpdatePasswordUseCase? updatePasswordUseCase,
  })  : getCurrentUserUseCase = getCurrentUserUseCase ?? _FakeGetCurrentUserUseCase(),
        signInUseCase = signInUseCase ?? _FakeSignInUseCase(),
        signOutUseCase = signOutUseCase ?? _FakeSignOutUseCase(),
        signUpUseCase = signUpUseCase ?? _FakeSignUpUseCase(),
        updatePasswordUseCase = updatePasswordUseCase ?? _FakeUpdatePasswordUseCase(),
        super(AuthInitial()) {
    on<SignInRequested>(_onSignInRequested);
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
  Future<User?> signUp(String email, String password, String name) async => null;

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
  Future<void> updatePassword(String currentPassword, String newPassword) async {}
}

/// Fake use case implementations
class _FakeGetCurrentUserUseCase extends GetCurrentUserUseCase {
  _FakeGetCurrentUserUseCase() : super(_FakeAuthRepository());
}

class _FakeSignInUseCase extends SignInUseCase {
  _FakeSignInUseCase() : super(_FakeAuthRepository());
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
  NavigatorObserver? navigatorObserver,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>.value(value: authBloc as AuthBloc),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
    ),
  );
}
