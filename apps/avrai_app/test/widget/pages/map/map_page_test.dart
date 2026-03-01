import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/presentation/pages/map/map_page.dart';
import 'package:avrai/presentation/blocs/lists/lists_bloc.dart';
import 'package:avrai/presentation/blocs/spots/spots_bloc.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai_core/models/misc/list.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_runtime_os/domain/usecases/lists/get_lists_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/lists/create_list_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/spots/get_spots_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/spots/get_spots_from_respected_lists_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/spots/create_spot_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/spots/update_spot_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/spots/delete_spot_usecase.dart';
import 'package:avrai_runtime_os/domain/repositories/spots_repository.dart';
import 'package:avrai_runtime_os/domain/repositories/lists_repository.dart';
import 'package:avrai_runtime_os/domain/usecases/lists/update_list_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/lists/delete_list_usecase.dart';
import 'package:avrai_runtime_os/data/repositories/lists_repository_impl.dart';
import 'package:avrai_runtime_os/data/datasources/local/lists_local_datasource.dart';
import 'package:avrai_runtime_os/data/datasources/remote/lists_remote_datasource.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for MapPage
/// Tests map page display, orientation handling, and state management
/// Uses real implementations with in-memory storage
///
/// Note: Currently skipped due to map widget complexity (pending timers/network)
/// TODO(Phase 7): Add test-safe map abstraction or mock tile provider
void main() {
  group('MapPage Widget Tests', () {
    late _FakeListsLocalDataSource fakeListsLocalDataSource;
    late _FakeListsRemoteDataSource fakeListsRemoteDataSource;
    late _FakeConnectivity fakeConnectivity;
    late ListsRepositoryImpl listsRepository;
    late GetListsUseCase getListsUseCase;
    late CreateListUseCase createListUseCase;
    late _FakeSpotsRepository fakeSpotsRepository;
    late GetSpotsUseCase getSpotsUseCase;
    late GetSpotsFromRespectedListsUseCase getSpotsFromRespectedListsUseCase;
    late CreateSpotUseCase createSpotUseCase;
    late UpdateSpotUseCase updateSpotUseCase;
    late DeleteSpotUseCase deleteSpotUseCase;
    late _FakeListsBloc fakeListsBloc;
    late _FakeSpotsBloc fakeSpotsBloc;

    setUp(() {
      fakeListsLocalDataSource = _FakeListsLocalDataSource();
      fakeListsRemoteDataSource = _FakeListsRemoteDataSource();
      fakeConnectivity = _FakeConnectivity();
      fakeConnectivity.setConnectivity(ConnectivityResult.wifi);

      listsRepository = ListsRepositoryImpl(
        localDataSource: fakeListsLocalDataSource,
        remoteDataSource: fakeListsRemoteDataSource,
        connectivity: fakeConnectivity,
      );

      getListsUseCase = GetListsUseCase(listsRepository);
      createListUseCase = CreateListUseCase(listsRepository);

      fakeSpotsRepository = _FakeSpotsRepository();
      getSpotsUseCase = GetSpotsUseCase(fakeSpotsRepository);
      getSpotsFromRespectedListsUseCase =
          GetSpotsFromRespectedListsUseCase(fakeSpotsRepository);
      createSpotUseCase = CreateSpotUseCase(fakeSpotsRepository);
      updateSpotUseCase = UpdateSpotUseCase(fakeSpotsRepository);
      deleteSpotUseCase = DeleteSpotUseCase(fakeSpotsRepository);

      fakeListsBloc = _FakeListsBloc(
        getListsUseCase: getListsUseCase,
        createListUseCase: createListUseCase,
      );
      fakeSpotsBloc = _FakeSpotsBloc(
        getSpotsUseCase: getSpotsUseCase,
        getSpotsFromRespectedListsUseCase: getSpotsFromRespectedListsUseCase,
        createSpotUseCase: createSpotUseCase,
        updateSpotUseCase: updateSpotUseCase,
        deleteSpotUseCase: deleteSpotUseCase,
      );
    });

    tearDown(() {
      fakeListsBloc.close();
      fakeSpotsBloc.close();
      fakeListsLocalDataSource.clear();
      fakeListsRemoteDataSource.clear();
      fakeSpotsRepository.clear();
    });

    testWidgets(
      'should display map view with app bar',
      (WidgetTester tester) async {
        // Arrange
        final widget = _createTestableWidgetWithRealBlocs(
          child: const MapPage(),
          listsBloc: fakeListsBloc,
          spotsBloc: fakeSpotsBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert: Map page should be displayed with app bar
        expect(find.text('Map'), findsOneWidget);
        expect(find.byType(MapPage), findsOneWidget);
      },
      skip: true, // TODO(Phase 7): Map widgets introduce pending timers/network
    );

    testWidgets(
      'should handle different screen orientations',
      (WidgetTester tester) async {
        // Arrange
        final widget = _createTestableWidgetWithRealBlocs(
          child: const MapPage(),
          listsBloc: fakeListsBloc,
          spotsBloc: fakeSpotsBloc,
        );

        // Act & Assert: Test portrait orientation
        tester.view.physicalSize = const Size(400, 800);
        addTearDown(() => tester.view.resetPhysicalSize());
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        expect(find.text('Map'), findsOneWidget);

        // Act & Assert: Test landscape orientation
        tester.view.physicalSize = const Size(800, 400);
        await tester.pump();
        expect(find.text('Map'), findsOneWidget);
      },
      skip: true, // TODO(Phase 7): Map widgets introduce pending timers/network
    );

    testWidgets(
      'should maintain state during rebuilds',
      (WidgetTester tester) async {
        // Arrange
        final widget = _createTestableWidgetWithRealBlocs(
          child: const MapPage(),
          listsBloc: fakeListsBloc,
          spotsBloc: fakeSpotsBloc,
        );

        // Act: Multiple rebuilds
        await tester.pumpWidget(widget);
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();

        // Assert: Widget should maintain state
        expect(find.byType(MapPage), findsOneWidget);
        expect(find.text('Map'), findsOneWidget);
      },
      skip: true, // TODO(Phase 7): Map widgets introduce pending timers/network
    );

    group('Map View Integration', () {
      testWidgets(
        'should integrate with lists bloc and spots bloc',
        (WidgetTester tester) async {
          // Arrange: Set up lists in bloc
          final testLists = TestDataFactory.createTestLists(3);
          for (final list in testLists) {
            await listsRepository.createList(list);
          }
          fakeListsBloc.add(LoadLists());
          await tester.pump();

          final widget = _createTestableWidgetWithRealBlocs(
            child: const MapPage(),
            listsBloc: fakeListsBloc,
            spotsBloc: fakeSpotsBloc,
          );

          // Act
          await tester.pumpWidget(widget);
          await tester.pumpAndSettle();

          // Assert: Map page should render with lists bloc
          expect(find.byType(MapPage), findsOneWidget);
        },
        skip:
            true, // TODO(Phase 7): Map widgets introduce pending timers/network
      );

      testWidgets(
        'should handle loading states correctly',
        (WidgetTester tester) async {
          // Arrange: Trigger loading state
          fakeListsBloc.add(LoadLists());
          fakeSpotsBloc.add(LoadSpots());
          await tester.pump();

          final widget = _createTestableWidgetWithRealBlocs(
            child: const MapPage(),
            listsBloc: fakeListsBloc,
            spotsBloc: fakeSpotsBloc,
          );

          // Act
          await tester.pumpWidget(widget);
          await tester.pumpAndSettle();

          // Assert: Map page should render during loading
          expect(find.byType(MapPage), findsOneWidget);
        },
        skip:
            true, // TODO(Phase 7): Map widgets introduce pending timers/network
      );

      testWidgets(
        'should handle error states correctly',
        (WidgetTester tester) async {
          // Arrange: Set up error states
          fakeSpotsRepository.setShouldThrow(true);
          fakeListsBloc.add(LoadLists());
          fakeSpotsBloc.add(LoadSpots());
          await tester.pump();

          final widget = _createTestableWidgetWithRealBlocs(
            child: const MapPage(),
            listsBloc: fakeListsBloc,
            spotsBloc: fakeSpotsBloc,
          );

          // Act
          await tester.pumpWidget(widget);
          await tester.pumpAndSettle();

          // Assert: Map page should render even with errors
          expect(find.byType(MapPage), findsOneWidget);
        },
        skip:
            true, // TODO(Phase 7): Map widgets introduce pending timers/network
      );
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

/// Real fake ListsBloc with actual state management and use cases
class _FakeListsBloc extends Bloc<ListsEvent, ListsState> implements ListsBloc {
  @override
  final GetListsUseCase getListsUseCase;
  @override
  final CreateListUseCase createListUseCase;
  @override
  final UpdateListUseCase updateListUseCase;
  @override
  final DeleteListUseCase deleteListUseCase;

  _FakeListsBloc({
    required this.getListsUseCase,
    required this.createListUseCase,
    UpdateListUseCase? updateListUseCase,
    DeleteListUseCase? deleteListUseCase,
  })  : updateListUseCase =
            updateListUseCase ?? _FakeUpdateListUseCase(listsRepository: null),
        deleteListUseCase =
            deleteListUseCase ?? _FakeDeleteListUseCase(listsRepository: null),
        super(ListsInitial()) {
    on<LoadLists>(_onLoadLists);
    on<CreateList>(_onCreateList);
    // Stub other events to prevent errors
    on<UpdateList>(_onUpdateList);
    on<DeleteList>(_onDeleteList);
    on<SearchLists>(_onSearchLists);
  }

  Future<void> _onLoadLists(
    LoadLists event,
    Emitter<ListsState> emit,
  ) async {
    emit(ListsLoading());
    try {
      final lists = await getListsUseCase();
      emit(ListsLoaded(lists, lists));
    } catch (e) {
      emit(ListsError(e.toString()));
    }
  }

  Future<void> _onCreateList(
    CreateList event,
    Emitter<ListsState> emit,
  ) async {
    try {
      await createListUseCase(event.list);
      add(LoadLists());
    } catch (e) {
      emit(ListsError(e.toString()));
    }
  }

  Future<void> _onUpdateList(
    UpdateList event,
    Emitter<ListsState> emit,
  ) async {
    try {
      await updateListUseCase(event.list);
      add(LoadLists());
    } catch (e) {
      emit(ListsError(e.toString()));
    }
  }

  Future<void> _onDeleteList(
    DeleteList event,
    Emitter<ListsState> emit,
  ) async {
    try {
      await deleteListUseCase(event.id);
      add(LoadLists());
    } catch (e) {
      emit(ListsError(e.toString()));
    }
  }

  Future<void> _onSearchLists(
    SearchLists event,
    Emitter<ListsState> emit,
  ) async {
    add(LoadLists());
  }
}

/// Real fake SpotsBloc with actual state management and use cases
class _FakeSpotsBloc extends Bloc<SpotsEvent, SpotsState> implements SpotsBloc {
  @override
  final GetSpotsUseCase getSpotsUseCase;
  @override
  final GetSpotsFromRespectedListsUseCase getSpotsFromRespectedListsUseCase;
  @override
  final CreateSpotUseCase createSpotUseCase;
  @override
  final UpdateSpotUseCase updateSpotUseCase;
  @override
  final DeleteSpotUseCase deleteSpotUseCase;

  _FakeSpotsBloc({
    required this.getSpotsUseCase,
    required this.getSpotsFromRespectedListsUseCase,
    required this.createSpotUseCase,
    required this.updateSpotUseCase,
    required this.deleteSpotUseCase,
  }) : super(SpotsInitial()) {
    on<LoadSpots>(_onLoadSpots);
    on<LoadSpotsWithRespected>(_onLoadSpotsWithRespected);
    on<SearchSpots>(_onSearchSpots);
    on<CreateSpot>(_onCreateSpot);
    on<UpdateSpot>(_onUpdateSpot);
    on<DeleteSpot>(_onDeleteSpot);
  }

  Future<void> _onLoadSpots(
    LoadSpots event,
    Emitter<SpotsState> emit,
  ) async {
    emit(SpotsLoading());
    try {
      final spots = await getSpotsUseCase();
      emit(SpotsLoaded(spots));
    } catch (e) {
      emit(SpotsError(e.toString()));
    }
  }

  Future<void> _onLoadSpotsWithRespected(
    LoadSpotsWithRespected event,
    Emitter<SpotsState> emit,
  ) async {
    emit(SpotsLoading());
    try {
      final spots = await getSpotsUseCase();
      final respectedSpots = await getSpotsFromRespectedListsUseCase();
      emit(SpotsLoaded(spots, respectedSpots: respectedSpots));
    } catch (e) {
      emit(SpotsError(e.toString()));
    }
  }

  void _onSearchSpots(
    SearchSpots event,
    Emitter<SpotsState> emit,
  ) {
    if (state is SpotsLoaded) {
      final currentState = state as SpotsLoaded;
      final query = event.query.toLowerCase();

      if (query.isEmpty) {
        emit(SpotsLoaded(currentState.spots));
      } else {
        final filtered = currentState.spots
            .where((spot) =>
                spot.name.toLowerCase().contains(query) ||
                spot.description.toLowerCase().contains(query))
            .toList();
        emit(SpotsLoaded(currentState.spots,
            filteredSpots: filtered, searchQuery: query));
      }
    }
  }

  Future<void> _onCreateSpot(
    CreateSpot event,
    Emitter<SpotsState> emit,
  ) async {
    try {
      await createSpotUseCase(event.spot);
      add(LoadSpots());
    } catch (e) {
      emit(SpotsError(e.toString()));
    }
  }

  Future<void> _onUpdateSpot(
    UpdateSpot event,
    Emitter<SpotsState> emit,
  ) async {
    try {
      await updateSpotUseCase(event.spot);
      add(LoadSpots());
    } catch (e) {
      emit(SpotsError(e.toString()));
    }
  }

  Future<void> _onDeleteSpot(
    DeleteSpot event,
    Emitter<SpotsState> emit,
  ) async {
    try {
      await deleteSpotUseCase(event.spotId);
      add(LoadSpots());
    } catch (e) {
      emit(SpotsError(e.toString()));
    }
  }
}

/// Stub use cases for ListsBloc
class _FakeUpdateListUseCase extends UpdateListUseCase {
  _FakeUpdateListUseCase({required ListsRepository? listsRepository})
      : super(listsRepository ?? _FakeListsRepositoryForUseCases());

  @override
  Future<SpotList> call(SpotList list) async => list;
}

class _FakeDeleteListUseCase extends DeleteListUseCase {
  _FakeDeleteListUseCase({required ListsRepository? listsRepository})
      : super(listsRepository ?? _FakeListsRepositoryForUseCases());

  @override
  Future<void> call(String id) async {}
}

/// Stub lists repository for use cases
class _FakeListsRepositoryForUseCases extends ListsRepositoryImpl {
  _FakeListsRepositoryForUseCases()
      : super(
          localDataSource: _FakeListsLocalDataSource(),
          remoteDataSource: _FakeListsRemoteDataSource(),
          connectivity: _FakeConnectivity(),
        );
}

/// Real fake spots repository with in-memory storage
class _FakeSpotsRepository implements SpotsRepository {
  final Map<String, Spot> _storage = {};
  bool _shouldThrow = false;

  void clear() {
    _storage.clear();
    _shouldThrow = false;
  }

  void setShouldThrow(bool shouldThrow) {
    _shouldThrow = shouldThrow;
  }

  @override
  Future<List<Spot>> getSpots() async {
    if (_shouldThrow) {
      throw Exception('Failed to load spots');
    }
    return _storage.values.toList();
  }

  @override
  Future<List<Spot>> getSpotsFromRespectedLists() async {
    if (_shouldThrow) {
      throw Exception('Failed to load respected spots');
    }
    // Return a subset of spots as "respected" (simplified for testing)
    return _storage.values.take(2).toList();
  }

  @override
  Future<Spot> createSpot(Spot spot) async {
    if (_shouldThrow) {
      throw Exception('Failed to create spot');
    }
    _storage[spot.id] = spot;
    return spot;
  }

  @override
  Future<Spot> updateSpot(Spot spot) async {
    if (_shouldThrow) {
      throw Exception('Failed to update spot');
    }
    _storage[spot.id] = spot;
    return spot;
  }

  @override
  Future<void> deleteSpot(String spotId) async {
    if (_shouldThrow) {
      throw Exception('Failed to delete spot');
    }
    _storage.remove(spotId);
  }
}

/// Helper to create testable widget with real BLoCs
Widget _createTestableWidgetWithRealBlocs({
  required Widget child,
  required ListsBloc listsBloc,
  required SpotsBloc spotsBloc,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<ListsBloc>.value(value: listsBloc),
      BlocProvider<SpotsBloc>.value(value: spotsBloc),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}
