import 'package:mockito/mockito.dart';
import 'package:avrai_admin_app/auth/auth_bloc.dart';
import 'package:avrai_core/models/user/user.dart';

/// Mock AuthBloc for widget testing
class MockAuthBloc extends Mock implements AuthBloc {
  AuthState? _state;
  Stream<AuthState>? _stream;
  bool _isClosed = false;
  final List<AuthEvent> addedEvents = [];

  @override
  AuthState get state => _state ?? AuthInitial();

  @override
  Stream<AuthState> get stream =>
      _stream ?? Stream.value(state).asBroadcastStream();

  @override
  Future<void> close() async {
    _isClosed = true;
  }

  @override
  bool get isClosed => _isClosed;

  @override
  void add(AuthEvent event) {
    addedEvents.add(event);
  }

  void setState(AuthState state) {
    _state = state;
    _stream = Stream.value(state).asBroadcastStream();
  }

  void setStream(Stream<AuthState> stream) {
    _stream = stream.asBroadcastStream();
  }
}

/// Helper class to create mock blocs with predefined states
class MockBlocFactory {
  /// Creates an authenticated mock auth bloc
  static MockAuthBloc createAuthenticatedAuthBloc(
      {UserRole role = UserRole.user, bool isAgeVerified = true}) {
    final mockBloc = MockAuthBloc();
    final user = MockBlocFactory._createTestUser(
        role: role, isAgeVerified: isAgeVerified);
    final authenticatedState = Authenticated(user: user);
    mockBloc.setState(authenticatedState);
    return mockBloc;
  }

  /// Creates an unauthenticated mock auth bloc
  static MockAuthBloc createUnauthenticatedAuthBloc() {
    final mockBloc = MockAuthBloc();
    final unauthenticatedState = Unauthenticated();
    mockBloc.setState(unauthenticatedState);
    return mockBloc;
  }

  /// Creates a loading mock auth bloc
  static MockAuthBloc createLoadingAuthBloc() {
    final mockBloc = MockAuthBloc();
    final loadingState = AuthLoading();
    mockBloc.setState(loadingState);
    return mockBloc;
  }

  /// Creates an error mock auth bloc
  static MockAuthBloc createErrorAuthBloc(String message) {
    final mockBloc = MockAuthBloc();
    final errorState = AuthError(message);
    mockBloc.setState(errorState);
    return mockBloc;
  }

  /// Creates a test user for mocking purposes
  static User _createTestUser(
      {UserRole role = UserRole.user, bool isAgeVerified = true}) {
    final now = DateTime.now();
    return User(
      id: 'test-user-id',
      email: 'test@example.com',
      name: 'Test User',
      displayName: 'Test User Display',
      role: role,
      createdAt: now,
      updatedAt: now,
    );
  }
}
