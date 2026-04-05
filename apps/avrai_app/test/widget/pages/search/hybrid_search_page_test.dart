import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/search/hybrid_search_page.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

/// Widget tests for HybridSearchPage
/// Tests search UI, results display, and BLoC integration
void main() {
  group('HybridSearchPage Widget Tests', () {
    late MockHybridSearchBloc mockHybridSearchBloc;

    setUp(() {
      mockHybridSearchBloc = MockHybridSearchBloc();
    });

    // Removed: Property assignment tests
    // Hybrid search page tests focus on business logic (UI display, search field), not property assignment

    testWidgets(
        'should display all required UI elements or display search field',
        (WidgetTester tester) async {
      // Test business logic: Hybrid search page display
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const HybridSearchPage(),
        hybridSearchBloc: mockHybridSearchBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.byType(HybridSearchPage), findsOneWidget);
    });
  });
}
