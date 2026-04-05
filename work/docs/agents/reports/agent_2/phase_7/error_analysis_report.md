# Error Analysis Report
**Date:** 2025-12-04
**Total Errors:** 1358
**Total Warnings:** 0
0

## Error Categories

### Undefined/Missing Errors
  error • Undefined class 'UnifiedUser' • lib/core/models/partnership_event.dart:133:5 • undefined_class
  error • Undefined class 'UnifiedUser' • lib/core/models/partnership_event.dart:153:5 • undefined_class
  error • Undefined name 'GetIt' • lib/core/network/device_discovery_web.dart:410:19 • undefined_identifier
  error • The method 'calculateEarningsForYear' isn't defined for the type 'TaxComplianceService' • lib/core/services/identity_verification_service.dart:89:60 • undefined_method
  error • The getter 'review' isn't defined for the type 'Icons' • lib/presentation/pages/admin/fraud_review_page.dart:418:25 • undefined_getter
  error • The getter 'review' isn't defined for the type 'Icons' • lib/presentation/pages/admin/review_fraud_review_page.dart:418:25 • undefined_getter
  error • The named parameter 'onTap' isn't defined • lib/presentation/pages/admin/user_data_viewer_page.dart:162:23 • undefined_named_parameter
  error • The getter 'user' isn't defined for the type 'AuthState' • lib/presentation/pages/brand/brand_discovery_page.dart:60:51 • undefined_getter
  error • The getter 'user' isn't defined for the type 'AuthState' • lib/presentation/pages/brand/sponsorship_checkout_page.dart:609:53 • undefined_getter
  error • The getter 'user' isn't defined for the type 'AuthState' • lib/presentation/pages/brand/sponsorship_management_page.dart:57:51 • undefined_getter
  error • The method 'getHostEarnings' isn't defined for the type 'PayoutService' • lib/presentation/pages/business/earnings_dashboard_page.dart:58:48 • undefined_method
  error • The method 'getPayoutHistory' isn't defined for the type 'PayoutService' • lib/presentation/pages/business/earnings_dashboard_page.dart:61:50 • undefined_method
  error • The getter 'activity' isn't defined for the type 'Icons' • lib/presentation/pages/communities/community_page.dart:592:25 • undefined_getter
  error • The getter 'neonPink' isn't defined for the type 'AppColors' • lib/presentation/pages/network/ai2ai_connections_page.dart:198:31 • undefined_getter
  error • The getter 'neonPink' isn't defined for the type 'AppColors' • lib/presentation/pages/network/ai2ai_connections_page.dart:317:29 • undefined_getter
  error • Undefined name 'mounted' • lib/presentation/pages/onboarding/legal_acceptance_dialog.dart:46:45 • undefined_identifier
  error • Undefined name 'mounted' • lib/presentation/pages/onboarding/legal_acceptance_dialog.dart:71:45 • undefined_identifier
  error • Expected an identifier • lib/presentation/pages/tax/tax_documents_page.dart:357:46 • missing_identifier
  error • Undefined name 'coverageThreshold' • lib/presentation/widgets/clubs/expertise_coverage_widget.dart:592:30 • undefined_identifier
  error • Undefined name 'coverageThreshold' • lib/presentation/widgets/clubs/expertise_coverage_widget.dart:595:20 • undefined_identifier

### Type Errors
  error • The name 'Spot' isn't a type, so it can't be used as a type argument • lib/core/models/partnership_event.dart:159:10 • non_type_as_type_argument
  error • The name 'SharedPreferences' isn't a type, so it can't be used as a type argument • lib/core/network/device_discovery_web.dart:410:34 • non_type_as_type_argument
  error • The method 'calculateEarningsForYear' isn't defined for the type 'TaxComplianceService' • lib/core/services/identity_verification_service.dart:89:60 • undefined_method
  error • Too many positional arguments: 1 expected, but 5 found • lib/presentation/pages/admin/business_accounts_viewer_page.dart:22:11 • extra_positional_arguments_could_be_named
  error • Too many positional arguments: 1 expected, but 5 found • lib/presentation/pages/admin/communications_viewer_page.dart:35:17 • extra_positional_arguments_could_be_named
  error • The getter 'review' isn't defined for the type 'Icons' • lib/presentation/pages/admin/fraud_review_page.dart:418:25 • undefined_getter
  error • The getter 'review' isn't defined for the type 'Icons' • lib/presentation/pages/admin/review_fraud_review_page.dart:418:25 • undefined_getter
  error • Too many positional arguments: 1 expected, but 5 found • lib/presentation/pages/admin/user_data_viewer_page.dart:103:23 • extra_positional_arguments_could_be_named
  error • The named parameter 'onTap' isn't defined • lib/presentation/pages/admin/user_data_viewer_page.dart:162:23 • undefined_named_parameter
  error • Too many positional arguments: 1 expected, but 5 found • lib/presentation/pages/admin/user_predictions_viewer_page.dart:22:11 • extra_positional_arguments_could_be_named
  error • Too many positional arguments: 1 expected, but 5 found • lib/presentation/pages/admin/user_progress_viewer_page.dart:22:11 • extra_positional_arguments_could_be_named
  error • The getter 'user' isn't defined for the type 'AuthState' • lib/presentation/pages/brand/brand_discovery_page.dart:60:51 • undefined_getter
  error • The getter 'user' isn't defined for the type 'AuthState' • lib/presentation/pages/brand/sponsorship_checkout_page.dart:609:53 • undefined_getter
  error • The getter 'user' isn't defined for the type 'AuthState' • lib/presentation/pages/brand/sponsorship_management_page.dart:57:51 • undefined_getter
  error • The method 'getHostEarnings' isn't defined for the type 'PayoutService' • lib/presentation/pages/business/earnings_dashboard_page.dart:58:48 • undefined_method
  error • The method 'getPayoutHistory' isn't defined for the type 'PayoutService' • lib/presentation/pages/business/earnings_dashboard_page.dart:61:50 • undefined_method
  error • The getter 'activity' isn't defined for the type 'Icons' • lib/presentation/pages/communities/community_page.dart:592:25 • undefined_getter
  error • The getter 'neonPink' isn't defined for the type 'AppColors' • lib/presentation/pages/network/ai2ai_connections_page.dart:198:31 • undefined_getter
  error • The getter 'neonPink' isn't defined for the type 'AppColors' • lib/presentation/pages/network/ai2ai_connections_page.dart:317:29 • undefined_getter
  error • The argument type 'StreamingChatBubble' can't be assigned to the parameter type 'ChatBubble'.  • lib/presentation/widgets/common/enhanced_ai_chat_interface.dart:171:23 • argument_type_not_assignable

### Test File Errors
  error • Undefined name 'BackendCapabilities' • packages/spots_network/test/supabase_backend_test.dart:101:28 • undefined_identifier
  error • The method 'createLocalExpertScope' isn't defined for the type 'IntegrationTestHelpers' • test/fixtures/integration_test_fixtures.dart:579:42 • undefined_method
  error • The method 'createCityExpertScope' isn't defined for the type 'IntegrationTestHelpers' • test/fixtures/integration_test_fixtures.dart:598:42 • undefined_method
  error • The method 'createRegionalExpertScope' isn't defined for the type 'IntegrationTestHelpers' • test/fixtures/integration_test_fixtures.dart:617:42 • undefined_method
  error • The method 'createTestLocality' isn't defined for the type 'IntegrationTestHelpers' • test/fixtures/integration_test_fixtures.dart:633:45 • undefined_method
  error • The method 'createTestLargeCity' isn't defined for the type 'IntegrationTestHelpers' • test/fixtures/integration_test_fixtures.dart:655:41 • undefined_method
  error • The method 'createCoffeeFocusedLocalityValue' isn't defined for the type 'IntegrationTestHelpers' • test/fixtures/integration_test_fixtures.dart:685:42 • undefined_method
  error • The method 'createTestQualification' isn't defined for the type 'IntegrationTestHelpers' • test/fixtures/integration_test_fixtures.dart:699:50 • undefined_method
  error • The method 'createTestProgress' isn't defined for the type 'IntegrationTestHelpers' • test/fixtures/integration_test_fixtures.dart:703:40 • undefined_method
  error • The method 'createTestFactors' isn't defined for the type 'IntegrationTestHelpers' • test/fixtures/integration_test_fixtures.dart:711:39 • undefined_method
  error • The method 'createTestQualification' isn't defined for the type 'IntegrationTestHelpers' • test/fixtures/integration_test_fixtures.dart:729:50 • undefined_method
  error • The method 'createTestProgress' isn't defined for the type 'IntegrationTestHelpers' • test/fixtures/integration_test_fixtures.dart:733:40 • undefined_method
  error • The method 'createTestFactors' isn't defined for the type 'IntegrationTestHelpers' • test/fixtures/integration_test_fixtures.dart:741:39 • undefined_method
  error • Target of URI doesn't exist: '../../mocks/mock_storage_service.dart' • test/integration/action_execution_integration_test.dart:26:8 • uri_does_not_exist
  error • Target of URI doesn't exist: '../../helpers/test_helpers.dart' • test/integration/action_execution_integration_test.dart:27:8 • uri_does_not_exist
  error • Undefined name 'TestHelpers' • test/integration/action_execution_integration_test.dart:39:7 • undefined_identifier
  error • Undefined name 'MockGetStorage' • test/integration/action_execution_integration_test.dart:40:21 • undefined_identifier
  error • Undefined name 'MockGetStorage' • test/integration/action_execution_integration_test.dart:41:7 • undefined_identifier
  error • Undefined name 'MockGetStorage' • test/integration/action_execution_integration_test.dart:49:7 • undefined_identifier
  error • Undefined name 'TestHelpers' • test/integration/action_execution_integration_test.dart:50:7 • undefined_identifier
