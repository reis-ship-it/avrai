import 'package:avrai_core/avra_core.dart';

class BhamNeighborhoodAssociationCalendarSourcePackService {
  const BhamNeighborhoodAssociationCalendarSourcePackService();

  ReplaySourcePack buildPack({int replayYear = 2023}) {
    final validFrom = DateTime.utc(replayYear, 1, 1).toIso8601String();
    final validTo = DateTime.utc(replayYear, 12, 31, 23, 59, 59).toIso8601String();
    const lastVerifiedAt = '2026-03-12T23:30:00Z';

    Map<String, dynamic> communityRow({
      required String recordId,
      required String entityId,
      required String name,
      required String locality,
      required String meetingDates,
      required String sourceExcerpt,
      required List<String> neighborhoodLinks,
      required String validationNote,
      double confidence = 0.79,
    }) {
      return <String, dynamic>{
        'record_id': recordId,
        'entity_type': 'community',
        'entity_id': entityId,
        'title': name,
        'name': name,
        'community_name': name,
        'locality': locality,
        'meeting_dates': meetingDates,
        'observed_at': validFrom,
        'published_at': validFrom,
        'valid_from': validFrom,
        'valid_to': validTo,
        'last_verified_at': lastVerifiedAt,
        'category': 'neighborhood_association',
        'historical_admissibility': 'retrospective_archive_calendar_reconstruction',
        'historical_capture_method': 'archival_reconstruction_from_bhamwiki',
        'historical_validation_note': validationNote,
        'retrospective_evidence': true,
        'source_host': 'bhamwiki.com',
        'source_page_title': name.replaceAll(' Neighborhood Association', ''),
        'historical_source_url': 'https://www.bhamwiki.com/',
        'source_excerpt': sourceExcerpt,
        'neighborhood_links': neighborhoodLinks,
        'confidence': confidence,
        'uncertainty_minutes': 10080,
      };
    }

    return ReplaySourcePack(
      packId: 'bham-neighborhood-association-calendars-$replayYear',
      replayYear: replayYear,
      generatedAtUtc: DateTime.now().toUtc(),
      datasets: <ReplaySourceDataset>[
        ReplaySourceDataset(
          sourceName: 'Neighborhood Association Calendars',
          records: <Map<String, dynamic>>[
            communityRow(
              recordId: 'nhcal-east-avondale-neighborhood-association-2023',
              entityId: 'community:east_avondale_neighborhood_association',
              name: 'East Avondale Neighborhood Association',
              locality: 'bham_east_avondale',
              meetingDates: 'Second Tuesday at 7:00 PM at New Bethel Baptist Church',
              sourceExcerpt:
                  'Neighborhood association meets on the second Tuesday at New Bethel Baptist Church.',
              neighborhoodLinks: const <String>[
                'East Avondale',
                'New Bethel Baptist Church',
              ],
              validationNote:
                  'Calendar lane reconstructed from archived neighborhood evidence documenting an active 2023 association meeting cadence.',
            ),
            communityRow(
              recordId: 'nhcal-glen-iris-neighborhood-association-2023',
              entityId: 'community:glen_iris_neighborhood_association',
              name: 'Glen Iris Neighborhood Association',
              locality: 'bham_glen_iris',
              meetingDates: 'First Monday at 6:30 PM at St. Elias Maronite Catholic Church',
              sourceExcerpt:
                  'Neighborhood association meets on the first Monday at 6:30 PM at St. Elias; Rob Burton listed as president in the 2023-present period.',
              neighborhoodLinks: const <String>[
                'Glen Iris',
                'St. Elias Maronite Catholic Church',
              ],
              validationNote:
                  'Calendar lane reconstructed from archived neighborhood evidence documenting an active 2023 association meeting cadence and leadership continuity.',
              confidence: 0.82,
            ),
            communityRow(
              recordId: 'nhcal-wylam-neighborhood-association-2023',
              entityId: 'community:wylam_neighborhood_association',
              name: 'Wylam Neighborhood Association',
              locality: 'bham_wylam',
              meetingDates: 'First Tuesday at 6:00 PM at Wylam Public Library',
              sourceExcerpt:
                  'Neighborhood association meets on the first Tuesday at 6:00 PM at Wylam Public Library.',
              neighborhoodLinks: const <String>[
                'Wylam',
                'Wylam Public Library',
              ],
              validationNote:
                  'Calendar lane reconstructed from archived neighborhood evidence documenting an active 2023 association meeting cadence.',
              confidence: 0.8,
            ),
          ],
          metadata: const <String, dynamic>{
            'status': 'historicalized_partial',
            'historicalPromotionPolicy': 'archival_reconstruction',
            'normalizationTargets': <String>['events', 'communities', 'clubs', 'neighborhoods', 'localities'],
            'sourceBasis': <String>['Bhamwiki archive reconstruction'],
          },
        ),
      ],
      notes: const <String>[
        'This pack makes the Neighborhood Association Calendars lane operational through governed archival reconstruction.',
        'Rows are community cadence truth, not exact dated 2023 event-instance truth.',
      ],
      metadata: const <String, dynamic>{
        'reconstructionBasis': 'Bhamwiki archived neighborhood association evidence',
      },
    );
  }
}
