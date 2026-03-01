import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/onboarding/ai_loading_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/blocs/lists/lists_bloc.dart';
import '../../helpers/widget_test_helpers.dart';
import 'package:avrai_core/models/misc/list.dart';
import 'package:avrai_core/models/user/user.dart';
import 'package:avrai_runtime_os/domain/usecases/lists/create_list_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/lists/delete_list_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/lists/get_lists_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/lists/update_list_usecase.dart';
import 'package:avrai_runtime_os/data/repositories/lists_repository_impl.dart';
import 'package:avrai_runtime_os/data/datasources/local/lists_local_datasource.dart';
import 'package:avrai_runtime_os/data/datasources/remote/lists_remote_datasource.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai/theme/app_theme.dart';
import '../../mocks/mock_blocs.dart';

/// Widget tests for AILoadingPage
/// Tests AI loading page that generates personalized lists
/// Uses real implementations with in-memory storage
void main() {
  group('AILoadingPage Widget Tests', () {
    late _FakeListsLocalDataSource fakeLocalDataSource;
    late _FakeListsRemoteDataSource fakeRemoteDataSource;
    late _FakeConnectivity fakeConnectivity;
    late ListsRepositoryImpl listsRepository;
    late GetListsUseCase getListsUseCase;
    late CreateListUseCase createListUseCase;
    late UpdateListUseCase updateListUseCase;
    late DeleteListUseCase deleteListUseCase;
    late MockAuthBloc mockAuthBloc;
    late ListsBloc listsBloc;

    setUp(() {
      fakeLocalDataSource = _FakeListsLocalDataSource();
      fakeRemoteDataSource = _FakeListsRemoteDataSource();
      fakeConnectivity = _FakeConnectivity();
      fakeConnectivity.setConnectivity(ConnectivityResult.wifi);

      listsRepository = ListsRepositoryImpl(
        localDataSource: fakeLocalDataSource,
        remoteDataSource: fakeRemoteDataSource,
        connectivity: fakeConnectivity,
      );

      getListsUseCase = GetListsUseCase(listsRepository);
      createListUseCase = CreateListUseCase(listsRepository);
      updateListUseCase = UpdateListUseCase(listsRepository);
      deleteListUseCase = DeleteListUseCase(listsRepository);

      mockAuthBloc = MockAuthBloc();
      final now = DateTime.now();
      mockAuthBloc.setState(
        Authenticated(
          user: User(
            id: 'user-123',
            email: 'test@example.com',
            name: 'Test User',
            role: UserRole.user,
            createdAt: now,
            updatedAt: now,
          ),
        ),
      );

      listsBloc = ListsBloc(
        getListsUseCase: getListsUseCase,
        createListUseCase: createListUseCase,
        updateListUseCase: updateListUseCase,
        deleteListUseCase: deleteListUseCase,
      );
    });

    tearDown(() {
      mockAuthBloc.close();
      listsBloc.close();
      fakeLocalDataSource.clear();
      fakeRemoteDataSource.clear();
    });

    testWidgets('should display loading page with user information',
        (WidgetTester tester) async {
      // Arrange
      final widget = _createTestableWidgetWithRealBlocs(
        child: AILoadingPage(
          userName: 'Test User',
          homebase: 'New York',
          favoritePlaces: const ['Central Park', 'Brooklyn Bridge'],
          preferences: const {
            'Food & Drink': ['Coffee & Tea'],
          },
          onLoadingComplete: () {},
        ),
        authBloc: mockAuthBloc,
        listsBloc: listsBloc,
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump(); // Initial frame

      // Assert: Widget should be displayed
      expect(find.byType(AILoadingPage), findsOneWidget);
    });

    testWidgets('should display loading indicator',
        (WidgetTester tester) async {
      // Arrange
      final widget = _createTestableWidgetWithRealBlocs(
        child: AILoadingPage(
          userName: 'Test User',
          onLoadingComplete: () {},
        ),
        authBloc: mockAuthBloc,
        listsBloc: listsBloc,
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump(); // Initial frame

      // Assert: Loading indicator should be visible (SPOTS uses a branded icon animation).
      expect(find.byIcon(Icons.psychology), findsWidgets);
    });

    testWidgets('should handle minimal user data', (WidgetTester tester) async {
      // Arrange
      final widget = _createTestableWidgetWithRealBlocs(
        child: AILoadingPage(
          userName: 'Test User',
          onLoadingComplete: () {},
        ),
        authBloc: mockAuthBloc,
        listsBloc: listsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Widget should render without errors
      expect(find.byType(AILoadingPage), findsOneWidget);
    });

    testWidgets('should handle extended user data',
        (WidgetTester tester) async {
      // Arrange
      final widget = _createTestableWidgetWithRealBlocs(
        child: AILoadingPage(
          userName: 'John Doe',
          age: 25,
          birthday: DateTime(2000, 1, 1),
          homebase: 'Brooklyn',
          favoritePlaces: const ['Park', 'Bridge'],
          preferences: const {
            'Activities': ['Music', 'Art'],
          },
          onLoadingComplete: () {},
        ),
        authBloc: mockAuthBloc,
        listsBloc: listsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Widget should render without errors
      expect(find.byType(AILoadingPage), findsOneWidget);
    });

    testWidgets('should render successfully with callback',
        (WidgetTester tester) async {
      // Arrange
      final widget = _createTestableWidgetWithRealBlocs(
        child: AILoadingPage(
          userName: 'Test User',
          onLoadingComplete: () {},
        ),
        authBloc: mockAuthBloc,
        listsBloc: listsBloc,
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump(); // Initial frame

      // Assert: Widget should render successfully
      expect(find.byType(AILoadingPage), findsOneWidget);
    });
  });
}

/// Real fake implementation with in-memory storage for local data source
class _FakeListsLocalDataSource implements ListsLocalDataSource {
  final Map<String, SpotList> _storage = {};

  void clear() {
    _storage.clear();
  }

  @override
  Future<List<SpotList>> getLists() async {
    return _storage.values.toList();
  }

  @override
  Future<SpotList?> saveList(SpotList list) async {
    _storage[list.id] = list;
    return list;
  }

  @override
  Future<void> deleteList(String id) async {
    _storage.remove(id);
  }
}

/// Real fake implementation with in-memory storage for remote data source
class _FakeListsRemoteDataSource implements ListsRemoteDataSource {
  final Map<String, SpotList> _storage = {};

  void clear() {
    _storage.clear();
  }

  @override
  Future<List<SpotList>> getLists() async {
    return _storage.values.toList();
  }

  @override
  Future<List<SpotList>> getPublicLists({int? limit}) async {
    final publicLists = _storage.values.where((list) => list.isPublic).toList();
    if (limit != null) {
      return publicLists.take(limit).toList();
    }
    return publicLists;
  }

  @override
  Future<SpotList> createList(SpotList list) async {
    _storage[list.id] = list;
    return list;
  }

  @override
  Future<SpotList> updateList(SpotList list) async {
    _storage[list.id] = list;
    return list;
  }

  @override
  Future<void> deleteList(String listId) async {
    _storage.remove(listId);
  }
}

/// Real fake implementation with state management for connectivity testing
class _FakeConnectivity implements Connectivity {
  ConnectivityResult _currentResult = ConnectivityResult.wifi;

  void setConnectivity(ConnectivityResult result) {
    _currentResult = result;
  }

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return [_currentResult];
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return Stream.value([_currentResult]);
  }
}

/// Helper to create testable widget with real BLoCs
Widget _createTestableWidgetWithRealBlocs({
  required Widget child,
  required AuthBloc authBloc,
  required ListsBloc listsBloc,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>.value(value: authBloc),
      BlocProvider<ListsBloc>.value(value: listsBloc),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}
