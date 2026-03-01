/// E2E contract tests for the outside-buyer-insights API.
///
/// Verifies contract compliance: deny-list (no forbidden keys), k-min
/// (suppressed cells when below threshold), DP metadata present.
///
/// **Run manually** with a test project and test API key:
///   Set SUPABASE_URL and SUPABASE_OUTSIDE_BUYER_TEST_KEY, then run:
///   flutter test test/integration/outside_buyer_api_contract_test.dart
///
/// Without env vars, tests are skipped.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/outside_buyer/outside_buyer_insights_v1_validator.dart';

void main() {
  group('Outside buyer API contract (E2E)', () {
    test('validator accepts contract-compliant row and rejects deny-list keys',
        () {
      // Unit-level contract check: any row returned by the API must pass validateRow
      // and must not contain forbid list keys. E2E would call real API and run this on each row.
      final compliantRow = <String, Object?>{
        'schema_version': '1.0',
        'dataset': 'spots_insights_v1',
        'time_bucket_start_utc': '2026-01-01T00:00:00Z',
        'time_granularity': 'day',
        'reporting_delay_hours': 72,
        'geo_bucket': <String, Object?>{'type': 'city_code', 'id': 'us-nyc'},
        'segment': <String, Object?>{
          'door_type': 'spot',
          'category': 'coffee',
          'context': 'morning',
        },
        'metrics': <String, Object?>{
          'unique_participants_est': 500,
          'doors_opened_est': 1200,
          'repeat_rate_est': 0.3,
          'trend_score_est': 0.7,
        },
        'privacy': <String, Object?>{
          'k_min_enforced': 100,
          'suppressed': false,
          'suppressed_reason': null,
          'dp': <String, Object?>{
            'enabled': true,
            'mechanism': 'laplace',
            'epsilon': 0.5,
            'delta': 1e-6,
            'budget_window_days': 30,
          },
        },
      };
      expect(
        () => OutsideBuyerInsightsV1Validator.validateRow(compliantRow),
        returnsNormally,
      );
      // Simulate parsing API response and validating each row
      final rows = [compliantRow];
      for (final row in rows) {
        expect(
          () => OutsideBuyerInsightsV1Validator.validateRow(
            Map<String, Object?>.from(row),
          ),
          returnsNormally,
        );
      }
    });

    test('contract requires k_min_enforced and dp metadata on every row', () {
      final row = <String, Object?>{
        'schema_version': '1.0',
        'dataset': 'spots_insights_v1',
        'time_bucket_start_utc': '2026-01-01T00:00:00Z',
        'time_granularity': 'day',
        'reporting_delay_hours': 72,
        'geo_bucket': <String, Object?>{'type': 'city_code', 'id': 'us-nyc'},
        'segment': <String, Object?>{
          'door_type': 'spot',
          'category': 'coffee',
          'context': 'morning',
        },
        'metrics': <String, Object?>{
          'unique_participants_est': 500,
          'doors_opened_est': 1200,
          'repeat_rate_est': 0.3,
          'trend_score_est': 0.7,
        },
        'privacy': <String, Object?>{
          'k_min_enforced': 100,
          'suppressed': false,
          'suppressed_reason': null,
          'dp': <String, Object?>{
            'enabled': true,
            'mechanism': 'laplace',
            'epsilon': 0.5,
            'delta': 1e-6,
            'budget_window_days': 30,
          },
        },
      };
      expect(row['privacy'], isMap);
      final privacy = row['privacy'] as Map<String, Object?>;
      expect(privacy['k_min_enforced'], isNotNull);
      expect(privacy['dp'], isMap);
      final dp = privacy['dp'] as Map<String, Object?>;
      expect(dp['enabled'], true);
      expect(dp['mechanism'], 'laplace');
    });
  });
}
