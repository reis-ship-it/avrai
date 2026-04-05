import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/system_temporal_kernel.dart';
import 'package:avrai_runtime_os/services/admin/remote_source_health_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_category.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TemporalInstant buildInstant(DateTime time) {
    return TemporalInstant(
      referenceTime: time.toUtc(),
      civilTime: time,
      timezoneId: 'UTC',
      provenance: const TemporalProvenance(
        authority: TemporalAuthority.device,
        source: 'test',
      ),
      uncertainty: const TemporalUncertainty.zero(),
      monotonicTicks: time.microsecondsSinceEpoch,
    );
  }

  test('kernel freshness marks stale rows as stale', () async {
    final clock = FixedClockSource(buildInstant(DateTime.utc(2026, 3, 6, 12)));
    final kernel = SystemTemporalKernel(clockSource: clock);
    final service = RemoteSourceHealthService(
      supabaseService: SupabaseService(),
      temporalKernel: kernel,
      freshnessPolicy:
          const TemporalFreshnessPolicy(maxAge: Duration(days: 30)),
    );

    final record = await service.fromRowForTest(<String, dynamic>{
      'source_id': 'source-1',
      'provider': 'provider',
      'entity_type': 'event',
      'category_label': 'event',
      'confidence': 0.95,
      'freshness': 0.95,
      'fallback_rate': 0.0,
      'review_needed': false,
      'last_sync_at': DateTime.utc(2026, 1, 1).toIso8601String(),
      'sync_state': 'active',
      'health_category': SignatureHealthCategory.strong.name,
      'summary': 'summary',
    });

    expect(record.healthCategory, SignatureHealthCategory.stale);
    expect(record.freshness, 0.0);
  });
}
