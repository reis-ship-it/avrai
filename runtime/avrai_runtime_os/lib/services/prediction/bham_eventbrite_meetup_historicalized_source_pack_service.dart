import 'package:avrai_core/avra_core.dart';

class BhamEventbriteMeetupHistoricalizedSourcePackService {
  const BhamEventbriteMeetupHistoricalizedSourcePackService();

  ReplaySourcePack buildPack({
    required ReplaySourcePack automatedPack,
    int replayYear = 2023,
  }) {
    final dataset = automatedPack.datasets.where(
      (entry) => entry.sourceName == 'Eventbrite / Meetup',
    );
    if (dataset.isEmpty) {
      return ReplaySourcePack(
        packId: 'bham-eventbrite-meetup-historicalized-$replayYear',
        replayYear: replayYear,
        generatedAtUtc: DateTime.now().toUtc(),
        datasets: const <ReplaySourceDataset>[],
        notes: const <String>[
          'No Eventbrite / Meetup automated dataset was available for governed historicalization.',
        ],
      );
    }

    final records = _historicalizeRows(
      dataset.first.records,
      replayYear: replayYear,
    );
    return ReplaySourcePack(
      packId: 'bham-eventbrite-meetup-historicalized-$replayYear',
      replayYear: replayYear,
      generatedAtUtc: DateTime.now().toUtc(),
      datasets: <ReplaySourceDataset>[
        ReplaySourceDataset(
          sourceName: 'Eventbrite / Meetup',
          records: records,
          metadata: const <String, dynamic>{
            'status': 'historicalized_partial',
            'historicalPromotionPolicy': 'persistent_group_pages_only',
            'normalizationTargets': <String>['community', 'club'],
          },
        ),
      ],
      notes: const <String>[
        'This pack promotes only persistent Birmingham Meetup group pages, not dated event rows.',
        'Rows are recurring social-group anchors for 2023 replay truth and remain unsuitable as exact 2023 event-instance truth.',
      ],
      metadata: const <String, dynamic>{
        'sourceBasis': 'eventbrite_meetup_automated_pack',
        'excludedRowClasses': <String>['future_dated_events', 'generic_navigation'],
      },
    );
  }

  List<Map<String, dynamic>> _historicalizeRows(
    List<Map<String, dynamic>> rawRows, {
    required int replayYear,
  }) {
    final validFrom = DateTime.utc(replayYear, 1, 1).toIso8601String();
    final validTo = DateTime.utc(replayYear, 12, 31, 23, 59, 59).toIso8601String();
    const lastVerifiedAt = '2026-03-12T23:45:00Z';
    final records = <Map<String, dynamic>>[];

    bool isPersistentGroup(Map<String, dynamic> row) {
      final url = row['source_url']?.toString() ?? '';
      final name = row['name']?.toString().toLowerCase() ?? '';
      return (url.contains('/?eventOrigin=city_popular_groups') ||
              url.startsWith('/')) &&
          (name.contains('birmingham') ||
              name.contains('bham') ||
              name.contains('alabama'));
    }

    String normalizeUrl(String raw) {
      if (raw.startsWith('http')) {
        return raw;
      }
      if (raw.startsWith('/')) {
        return 'https://www.meetup.com$raw';
      }
      return raw;
    }

    String entityTypeFor(Map<String, dynamic> row) {
      final name = row['name']?.toString().toLowerCase() ?? '';
      if (name.contains('club') || name.contains('book club')) {
        return 'club';
      }
      return 'community';
    }

    String localityFor(Map<String, dynamic> row) {
      final name = row['name']?.toString().toLowerCase() ?? '';
      if (name.contains('avondale')) {
        return 'bham_avondale';
      }
      if (name.contains('southside')) {
        return 'bham_southside';
      }
      if (name.contains('downtown')) {
        return 'bham_downtown';
      }
      return 'bham_metro_regional';
    }

    String validationNoteFor(Map<String, dynamic> row) {
      final name = row['name']?.toString() ?? 'Unknown Group';
      return '$name was promoted as a persistent Birmingham social-group anchor from a Meetup group listing; it is treated as recurring community or club structure, not a dated 2023 event row.';
    }

    final seenEntityIds = <String>{};
    for (final row in rawRows) {
      if (!isPersistentGroup(row)) {
        continue;
      }
      final rawName = row['name']?.toString().trim();
      final rawUrl = row['source_url']?.toString().trim();
      if (rawName == null ||
          rawName.isEmpty ||
          rawUrl == null ||
          rawUrl.isEmpty ||
          rawName.toLowerCase() == 'see all') {
        continue;
      }
      final entityType = entityTypeFor(row);
      final normalizedId =
          '${entityType == 'club' ? 'club' : 'community'}:${_slugFor(rawName)}';
      if (!seenEntityIds.add(normalizedId)) {
        continue;
      }
      records.add(<String, dynamic>{
        'record_id': 'evtmeet-hist-${records.length + 1}',
        'entity_type': entityType,
        'entity_id': normalizedId,
        'title': rawName,
        'name': rawName,
        if (entityType == 'community') 'community_name': rawName,
        'locality': localityFor(row),
        'observed_at': validFrom,
        'published_at': validFrom,
        'valid_from': validFrom,
        'valid_to': validTo,
        'last_verified_at': lastVerifiedAt,
        'category': entityType == 'club'
            ? 'recurring_social_club_anchor'
            : 'recurring_social_group_anchor',
        'historical_admissibility': 'governed_group_anchor_reconstruction',
        'historical_capture_method': 'persistent_meetup_group_listing',
        'historical_validation_note': validationNoteFor(row),
        'historical_source_url': normalizeUrl(rawUrl),
        'source_host': 'meetup.com',
        'source_page_title': rawName,
        'source_row_basis': <String>[row['record_id']?.toString() ?? rawName],
        'confidence': entityType == 'club' ? 0.68 : 0.64,
        'uncertainty_minutes': 10080,
      });
    }
    return records;
  }

  String _slugFor(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
