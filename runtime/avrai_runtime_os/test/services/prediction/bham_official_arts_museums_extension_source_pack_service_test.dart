import 'package:avrai_runtime_os/services/prediction/bham_official_arts_museums_extension_source_pack_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds official arts and museums extension source pack', () {
    final pack =
        const BhamOfficialArtsMuseumsExtensionSourcePackService().buildPack();

    expect(pack.replayYear, 2023);
    expect(pack.datasets, hasLength(1));
    expect(pack.datasets.first.sourceName, 'City of Birmingham Play Pages');
    expect(pack.datasets.first.records, hasLength(7));
    expect(
      pack.datasets.first.records.map((row) => row['title']).toSet(),
      containsAll(<String>[
        'Alabama Sports Hall of Fame',
        'Arlington Historic House',
        'Barber Vintage Motorsports Museum',
        'Birmingham Negro Southern League Museum',
        'Birmingham Zoo',
        'McWane Science Center',
        'Southern Museum of Flight',
      ]),
    );
  });
}
