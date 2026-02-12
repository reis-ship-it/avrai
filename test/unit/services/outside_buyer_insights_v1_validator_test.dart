import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/outside_buyer/outside_buyer_insights_v1_validator.dart';

void main() {
  group('OutsideBuyerInsightsV1Validator', () {
    Map<String, Object?> baseRow({
      bool suppressed = false,
    }) {
      return <String, Object?>{
        'schema_version': '1.0',
        'dataset': 'spots_insights_v1',
        'time_bucket_start_utc': '2026-01-01T00:00:00Z',
        'time_granularity': 'day',
        'reporting_delay_hours': 72,
        'geo_bucket': <String, Object?>{
          'type': 'geohash4',
          'id': '9q8y',
        },
        'segment': <String, Object?>{
          'door_type': 'spot',
          'category': 'coffee',
          'context': 'morning',
        },
        'metrics': suppressed
            ? <String, Object?>{
                'unique_participants_est': null,
                'doors_opened_est': null,
                'repeat_rate_est': null,
                'trend_score_est': null,
              }
            : <String, Object?>{
                'unique_participants_est': 12850,
                'doors_opened_est': 45120,
                'repeat_rate_est': 0.31,
                'trend_score_est': 0.74,
              },
        'privacy': <String, Object?>{
          'k_min_enforced': 100,
          'suppressed': suppressed,
          'suppressed_reason': suppressed ? 'k_min' : null,
          'dp': <String, Object?>{
            'enabled': true,
            'mechanism': 'laplace',
            'epsilon': 0.5,
            'delta': 1e-6,
            'budget_window_days': 30,
          },
        },
      };
    }

    test('accepts a valid non-suppressed row', () {
      final row = baseRow(suppressed: false);
      expect(
        () => OutsideBuyerInsightsV1Validator.validateRow(row),
        returnsNormally,
      );
    });

    test('accepts a valid suppressed row with null metrics', () {
      final row = baseRow(suppressed: true);
      expect(
        () => OutsideBuyerInsightsV1Validator.validateRow(row),
        returnsNormally,
      );
    });

    test('rejects any appearance of forbidden keys (deny-list scan)', () {
      final row = baseRow(suppressed: false);

      // Simulate an accidental leak of stable identifiers nested deep in the output.
      (row['metrics'] as Map<String, Object?>)['debug'] = <String, Object?>{
        'user_id': 'abc',
      };

      expect(
        () => OutsideBuyerInsightsV1Validator.validateRow(row),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects reporting delays below the contract minimum', () {
      final row = baseRow(suppressed: false);
      row['reporting_delay_hours'] = 24;

      expect(
        () => OutsideBuyerInsightsV1Validator.validateRow(row),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid enums (door_type/category/context)', () {
      final row = baseRow(suppressed: false);
      (row['segment'] as Map<String, Object?>)['door_type'] = 'person';
      (row['segment'] as Map<String, Object?>)['category'] = 'restaurant';
      (row['segment'] as Map<String, Object?>)['context'] = 'night';

      expect(
        () => OutsideBuyerInsightsV1Validator.validateRow(row),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects non-suppressed rows with missing metrics', () {
      final row = baseRow(suppressed: false);
      (row['metrics'] as Map<String, Object?>)['unique_participants_est'] = null;

      expect(
        () => OutsideBuyerInsightsV1Validator.validateRow(row),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

