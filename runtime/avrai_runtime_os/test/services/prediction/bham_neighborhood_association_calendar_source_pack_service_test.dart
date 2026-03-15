import 'package:avrai_runtime_os/services/prediction/bham_neighborhood_association_calendar_source_pack_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a reconstructed neighborhood association calendar source pack', () {
    final pack =
        const BhamNeighborhoodAssociationCalendarSourcePackService().buildPack();

    expect(pack.replayYear, 2023);
    expect(pack.datasets.length, 1);
    expect(pack.datasets.single.sourceName, 'Neighborhood Association Calendars');
    expect(pack.datasets.single.records.length, 3);
    expect(
      pack.datasets.single.records.every(
        (record) =>
            record['historical_admissibility'] ==
            'retrospective_archive_calendar_reconstruction',
      ),
      isTrue,
    );
  });
}
