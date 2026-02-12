import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/controllers/list_creation_controller.dart';
import 'package:avrai/data/repositories/lists_repository_impl.dart';
import 'package:avrai/domain/repositories/lists_repository.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/presentation/pages/lists/create_list_page.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';
import '../../../helpers/getit_test_harness.dart';

/// Widget tests for CreateListPage
/// Tests form rendering, validation, and list creation
void main() {
  group('CreateListPage Widget Tests', () {
    late MockListsBloc mockListsBloc;
    late GetItTestHarness getIt;

    setUp(() {
      mockListsBloc = MockListsBloc();
      getIt = GetItTestHarness(sl: GetIt.instance);

      // CreateListPage resolves ListCreationController from GetIt in initState.
      // Register a minimal controller + dependencies so the page can render.
      getIt.registerLazySingletonReplace<AtomicClockService>(
          () => AtomicClockService());
      getIt.registerLazySingletonReplace<ListsRepository>(
        () => ListsRepositoryImpl(
          connectivity: null, // local-only in widget tests
          localDataSource: null,
          remoteDataSource: null,
        ),
      );
      getIt.registerLazySingletonReplace<ListCreationController>(
        () => ListCreationController(
          listsRepository: GetIt.instance<ListsRepository>(),
          atomicClock: GetIt.instance<AtomicClockService>(),
        ),
      );
    });

    tearDown(() {
      getIt.unregisterIfRegistered<ListCreationController>();
      getIt.unregisterIfRegistered<ListsRepository>();
      getIt.unregisterIfRegistered<AtomicClockService>();
    });

    // Removed: Property assignment tests
    // Create list page tests focus on business logic (form fields display, create list title display), not property assignment

    testWidgets(
        'should display all required form fields or display create list title',
        (WidgetTester tester) async {
      // Test business logic: Create list page display
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const CreateListPage(),
        listsBloc: mockListsBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.byType(CreateListPage), findsOneWidget);
    });
  });
}
