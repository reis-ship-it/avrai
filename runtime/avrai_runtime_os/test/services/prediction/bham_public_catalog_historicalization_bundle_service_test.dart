import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_public_catalog_historicalization_bundle_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds historicalization bundle for non-historical public catalogs', () {
    final pack = ReplaySourcePack(
      packId: 'pack-1',
      replayYear: 2023,
      generatedAtUtc: DateTime.utc(2026, 3, 12),
      datasets: <ReplaySourceDataset>[
        ReplaySourceDataset(
          sourceName: 'IN Birmingham (CVB Calendar)',
          records: <Map<String, dynamic>>[
            <String, dynamic>{
              'record_id': 'a',
              'name': 'Avondale / Crestwood Visit Avondale / Crestwood',
              'entity_type': 'community',
              'locality': 'bham_avondale',
            },
          ],
          metadata: <String, dynamic>{
            'coverageStatus': 'current_tourism_catalog',
            'historicalReplayReady': false,
            'uri': 'https://inbirmingham.com/festivals-and-events/',
          },
        ),
      ],
    );

    final bundle =
        const BhamPublicCatalogHistoricalizationBundleService().buildBundle(pack);

    expect(bundle.entries, hasLength(1));
    expect(bundle.entries.first.sourceName, 'IN Birmingham (CVB Calendar)');
    expect(
      bundle.entries.first.requiredHistoricalFields,
      contains('historical_source_url'),
    );
    expect(bundle.entries.first.samples, hasLength(1));
  });
}
