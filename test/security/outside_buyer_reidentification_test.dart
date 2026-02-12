/// Red-team style tests: assert that outside-buyer export contract
/// prevents re-identification (deny-list, k-min suppression, no stable identifiers).
///
/// Contract: docs/plans/architecture/OUTSIDE_DATA_BUYER_INSIGHTS_DATA_CONTRACT_V1.md
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/outside_buyer/outside_buyer_insights_v1_validator.dart';

void main() {
  group('Outside buyer re-identification hardening', () {
    test('validator rejects any row containing user_id anywhere (re-id risk)',
        () {
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
        'leak': <String, Object?>{'user_id': 're-id-vector'},
      };
      expect(
        () => OutsideBuyerInsightsV1Validator.validateRow(row),
        throwsA(isA<FormatException>()),
      );
    });

    test('validator rejects row with agent_id in payload (re-id risk)', () {
      final row = <String, Object?>{
        'schema_version': '1.0',
        'dataset': 'spots_insights_v1',
        'time_bucket_start_utc': '2026-01-01T00:00:00Z',
        'time_granularity': 'day',
        'reporting_delay_hours': 72,
        'geo_bucket': <String, Object?>{'type': 'geohash3', 'id': '9q8y'},
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
          'agent_id': 'stable-id-leak',
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
        () => OutsideBuyerInsightsV1Validator.validateRow(row),
        throwsA(isA<FormatException>()),
      );
    });

    test('suppressed rows have null metrics (k-min prevents small-cell re-id)',
        () {
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
          'unique_participants_est': null,
          'doors_opened_est': null,
          'repeat_rate_est': null,
          'trend_score_est': null,
        },
        'privacy': <String, Object?>{
          'k_min_enforced': 100,
          'suppressed': true,
          'suppressed_reason': 'k_min',
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
        () => OutsideBuyerInsightsV1Validator.validateRow(row),
        returnsNormally,
      );
    });
  });
}
