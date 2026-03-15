import 'package:avrai_core/avra_core.dart';

class BhamOfficialArtsMuseumsExtensionSourcePackService {
  const BhamOfficialArtsMuseumsExtensionSourcePackService();

  ReplaySourcePack buildPack({int replayYear = 2023}) {
    final validFrom = DateTime.utc(replayYear, 1, 1).toIso8601String();
    final validTo = DateTime.utc(replayYear, 12, 31, 23, 59, 59).toIso8601String();
    const lastVerifiedAt = '2026-03-12T23:55:00Z';
    const sourceUrl = 'https://www.birminghamal.gov/play/arts-museums';
    const sourceHost = 'birminghamal.gov';
    const sourcePageTitle = 'Arts & Museums';

    Map<String, dynamic> venueRow({
      required String recordId,
      required String entityId,
      required String name,
      required String locality,
      required List<String> sourceRowBasis,
      required String validationNote,
      double confidence = 0.76,
    }) {
      return <String, dynamic>{
        'record_id': recordId,
        'entity_type': 'venue',
        'entity_id': entityId,
        'title': name,
        'name': name,
        'locality': locality,
        'observed_at': validFrom,
        'published_at': validFrom,
        'valid_from': validFrom,
        'valid_to': validTo,
        'last_verified_at': lastVerifiedAt,
        'category': 'official_cultural_venue_anchor',
        'historical_admissibility': 'year_valid_structural_snapshot',
        'historical_capture_method': 'official_city_arts_museums_page',
        'historical_validation_note': validationNote,
        'historical_source_url': sourceUrl,
        'source_host': sourceHost,
        'source_page_title': sourcePageTitle,
        'source_row_basis': sourceRowBasis,
        'confidence': confidence,
        'uncertainty_minutes': 4320,
      };
    }

    return ReplaySourcePack(
      packId: 'bham-official-arts-museums-extension-$replayYear',
      replayYear: replayYear,
      generatedAtUtc: DateTime.now().toUtc(),
      datasets: <ReplaySourceDataset>[
        ReplaySourceDataset(
          sourceName: 'City of Birmingham Play Pages',
          records: <Map<String, dynamic>>[
            venueRow(
              recordId: 'city-play-alabama-sports-hall-of-fame-2023',
              entityId: 'venue:alabama_sports_hall_of_fame',
              name: 'Alabama Sports Hall of Fame',
              locality: 'bham_uptown',
              sourceRowBasis: const <String>['city-arts-museums-1'],
              validationNote:
                  'Promoted from the official City of Birmingham Arts & Museums page as a stable civic cultural venue valid throughout 2023.',
            ),
            venueRow(
              recordId: 'city-play-arlington-historic-house-2023',
              entityId: 'venue:arlington_historic_house',
              name: 'Arlington Historic House',
              locality: 'bham_citywide',
              sourceRowBasis: const <String>['city-arts-museums-2'],
              validationNote:
                  'Promoted from the official City of Birmingham Arts & Museums page as a stable historical venue anchor valid throughout 2023.',
              confidence: 0.72,
            ),
            venueRow(
              recordId: 'city-play-barber-museum-2023',
              entityId: 'venue:barber_vintage_motorsports_museum',
              name: 'Barber Vintage Motorsports Museum',
              locality: 'bham_metro_regional',
              sourceRowBasis: const <String>['city-arts-museums-3'],
              validationNote:
                  'Promoted from the official City of Birmingham Arts & Museums page as a stable regional destination venue valid throughout 2023.',
            ),
            venueRow(
              recordId: 'city-play-negro-southern-league-museum-2023',
              entityId: 'venue:birmingham_negro_southern_league_museum',
              name: 'Birmingham Negro Southern League Museum',
              locality: 'bham_downtown',
              sourceRowBasis: const <String>['city-arts-museums-4'],
              validationNote:
                  'Promoted from the official City of Birmingham Arts & Museums page as a stable cultural and historical venue valid throughout 2023.',
            ),
            venueRow(
              recordId: 'city-play-birmingham-zoo-2023',
              entityId: 'venue:birmingham_zoo',
              name: 'Birmingham Zoo',
              locality: 'bham_lane_park',
              sourceRowBasis: const <String>['city-arts-museums-5'],
              validationNote:
                  'Promoted from the official City of Birmingham Arts & Museums page as a stable public destination venue valid throughout 2023.',
            ),
            venueRow(
              recordId: 'city-play-mcwane-science-center-2023',
              entityId: 'venue:mcwane_science_center',
              name: 'McWane Science Center',
              locality: 'bham_downtown',
              sourceRowBasis: const <String>['city-arts-museums-6'],
              validationNote:
                  'Promoted from the official City of Birmingham Arts & Museums page as a stable downtown museum/science venue valid throughout 2023.',
            ),
            venueRow(
              recordId: 'city-play-southern-museum-of-flight-2023',
              entityId: 'venue:southern_museum_of_flight',
              name: 'Southern Museum of Flight',
              locality: 'bham_metro_regional',
              sourceRowBasis: const <String>['city-arts-museums-7'],
              validationNote:
                  'Promoted from the official City of Birmingham Arts & Museums page as a stable aviation-history venue valid throughout 2023.',
              confidence: 0.73,
            ),
          ],
          metadata: const <String, dynamic>{
            'status': 'historicalized_extension',
            'historicalPromotionPolicy': 'official_city_structural_venues_only',
            'normalizationTargets': <String>['venue'],
          },
        ),
      ],
      notes: const <String>[
        'This pack extends the official City of Birmingham cultural venue layer with stable arts-and-museums anchors that were valid throughout 2023.',
        'These are structural venue anchors, not dated event-instance rows.',
      ],
      metadata: const <String, dynamic>{
        'sourceBasis': 'official_city_arts_museums_page',
        'extensionKind': 'official_cultural_place_truth',
      },
    );
  }
}
