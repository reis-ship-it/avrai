import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/presentation/widgets/map/geo_synco_summary_card.dart';
import 'package:avrai_runtime_os/services/geographic/geo_locality_pack_service.dart';

void main() {
  testWidgets('GeoSyncoSummaryCard shows one_liner from installed pack',
      (tester) async {
    const cityCode = 'us-nyc';
    const geoId = 'us-nyc-brooklyn';

    final root = Directory('${Directory.systemTemp.path}/geo_packs_v1');
    final cityDir = Directory('${root.path}/$cityCode');

    await tester.runAsync(() async {
      // Clean any previous run.
      if (await cityDir.exists()) {
        await cityDir.delete(recursive: true);
      }
      await cityDir.create(recursive: true);
      await File('${cityDir.path}/current.txt').writeAsString('v1');

      final vDir = Directory('${cityDir.path}/v1');
      await vDir.create(recursive: true);

      await File('${vDir.path}/localities.geojson').writeAsString(jsonEncode({
        'type': 'FeatureCollection',
        'features': const [],
      }));

      await File('${vDir.path}/index.json').writeAsString(jsonEncode({}));

      await File('${vDir.path}/summaries.json').writeAsString(jsonEncode({
        geoId: {
          'general_synco': {'one_liner': 'Brooklyn: test summary'},
        },
      }));
    });

    addTearDown(() async {
      try {
        await cityDir.delete(recursive: true);
      } catch (_) {}
    });

    // Sanity check: pack service can read the summary from disk in widget tests.
    await tester.runAsync(() async {
      final svc = GeoLocalityPackService();
      final s =
          await svc.getGeneralSyncoSummary(cityCode: cityCode, geoId: geoId);
      expect(s, isNotNull);
      expect(s!['one_liner'], 'Brooklyn: test summary');
    });

    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GeoSyncoSummaryCard(
              cityCode: cityCode,
              geoId: geoId,
            ),
          ),
        ),
      );
    });
    await tester.pump();

    // Initial loading state.
    expect(find.textContaining('Loading cached city pack'), findsOneWidget);

    // Let async load resolve (file I/O + setState).
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      });
      await tester.pump();
      if (find.textContaining('Brooklyn: test summary').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.textContaining('Brooklyn: test summary'), findsOneWidget);
  });
}
