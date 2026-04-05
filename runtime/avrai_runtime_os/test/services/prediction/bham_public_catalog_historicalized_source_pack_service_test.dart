import 'package:avrai_runtime_os/services/prediction/bham_public_catalog_historicalized_source_pack_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a safe-subset historicalized public catalog source pack', () {
    final pack =
        const BhamPublicCatalogHistoricalizedSourcePackService().buildPack();

    expect(pack.replayYear, 2023);
    expect(pack.datasets.length, 2);
    expect(
      pack.metadata['excludedPendingHistoricalizationSources'],
      contains('Eventbrite / Meetup'),
    );

    final rpcgb = pack.datasets.firstWhere(
      (dataset) =>
          dataset.sourceName ==
          'Jefferson / Shelby / Regional GIS and Assessors',
    );
    expect(rpcgb.records.length, 6);
    expect(
      rpcgb.records.every(
        (record) =>
            record['historical_admissibility'] ==
            'year_valid_structural_snapshot',
      ),
      isTrue,
    );

    final inBirmingham = pack.datasets.firstWhere(
      (dataset) => dataset.sourceName == 'IN Birmingham (CVB Calendar)',
    );
    expect(inBirmingham.records.length, 13);
    expect(
      inBirmingham.records
          .where((record) => record['entity_type'] == 'community')
          .length,
      12,
    );
  });
}
