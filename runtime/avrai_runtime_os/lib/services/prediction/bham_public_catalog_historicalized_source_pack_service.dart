import 'package:avrai_core/avra_core.dart';

class BhamPublicCatalogHistoricalizedSourcePackService {
  const BhamPublicCatalogHistoricalizedSourcePackService();

  ReplaySourcePack buildPack({int replayYear = 2023}) {
    return ReplaySourcePack(
      packId: 'bham-public-catalog-historicalized-$replayYear',
      replayYear: replayYear,
      generatedAtUtc: DateTime.now().toUtc(),
      datasets: <ReplaySourceDataset>[
        ReplaySourceDataset(
          sourceName: 'Jefferson / Shelby / Regional GIS and Assessors',
          records: _rpcgbRecords(replayYear),
          metadata: const <String, dynamic>{
            'status': 'historicalized_partial',
            'historicalPromotionPolicy': 'safe_structural_rows_only',
            'normalizationTargets': <String>[
              'locality',
              'venue',
              'community',
              'movement_flow',
            ],
          },
        ),
        ReplaySourceDataset(
          sourceName: 'IN Birmingham (CVB Calendar)',
          records: _inBirminghamRecords(replayYear),
          metadata: const <String, dynamic>{
            'status': 'historicalized_partial',
            'historicalPromotionPolicy': 'safe_structural_rows_only',
            'normalizationTargets': <String>['community', 'event', 'locality', 'venue'],
          },
        ),
      ],
      notes: const <String>[
        'This pack promotes only public-catalog rows that are defensible as year-valid 2023 structural truth.',
        'Eventbrite / Meetup remains intentionally excluded until archived 2023-valid rows are captured.',
      ],
      metadata: const <String, dynamic>{
        'excludedPendingHistoricalizationSources': <String>['Eventbrite / Meetup'],
        'historicalizationMode': 'safe_subset_only',
      },
    );
  }

  List<Map<String, dynamic>> _rpcgbRecords(int replayYear) {
    final validFrom = DateTime.utc(replayYear, 1, 1).toIso8601String();
    final validTo = DateTime.utc(replayYear, 12, 31, 23, 59, 59).toIso8601String();
    const lastVerifiedAt = '2026-03-12T23:00:00Z';
    const sourceHost = 'rpcgb.org';
    const sourcePageTitle = 'Data and Maps Downloads';
    const sourceUrl = 'https://www.rpcgb.org/data-and-maps-downloads';
    const historicalCaptureMethod = 'governed_public_catalog_historicalization';
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'record_id': 'rpcgb-hist-greater-birmingham-region-2023',
        'entity_type': 'locality',
        'entity_id': 'locality:greater_birmingham_region',
        'title': 'Greater Birmingham Region',
        'name': 'Greater Birmingham Region',
        'locality': 'greater_birmingham_region',
        'observed_at': validFrom,
        'published_at': validFrom,
        'valid_from': validFrom,
        'valid_to': validTo,
        'last_verified_at': lastVerifiedAt,
        'category': 'regional_spatial_anchor',
        'historical_admissibility': 'year_valid_structural_snapshot',
        'historical_capture_method': historicalCaptureMethod,
        'historical_validation_note':
            'Promoted from RPCGB regional spatial catalog as a stable locality anchor valid throughout 2023; not treated as event or metric truth.',
        'historical_source_url': sourceUrl,
        'source_host': sourceHost,
        'source_page_title': sourcePageTitle,
        'source_row_basis': const <String>['rpcgb-1', 'rpcgb-3', 'rpcgb-5'],
        'confidence': 0.78,
        'uncertainty_minutes': 1440,
      },
      <String, dynamic>{
        'record_id': 'rpcgb-hist-jefferson-county-2023',
        'entity_type': 'locality',
        'entity_id': 'locality:jefferson_county',
        'title': 'Jefferson County',
        'name': 'Jefferson County',
        'locality': 'jefferson_county',
        'observed_at': validFrom,
        'published_at': validFrom,
        'valid_from': validFrom,
        'valid_to': validTo,
        'last_verified_at': lastVerifiedAt,
        'category': 'county_spatial_anchor',
        'historical_admissibility': 'year_valid_structural_snapshot',
        'historical_capture_method': historicalCaptureMethod,
        'historical_validation_note':
            'Promoted as a stable county-level spatial anchor for 2023 from the RPCGB regional GIS catalog; used for locality grounding only.',
        'historical_source_url': sourceUrl,
        'source_host': sourceHost,
        'source_page_title': sourcePageTitle,
        'source_row_basis': const <String>['rpcgb-8'],
        'confidence': 0.76,
        'uncertainty_minutes': 1440,
      },
      <String, dynamic>{
        'record_id': 'rpcgb-hist-shelby-county-2023',
        'entity_type': 'locality',
        'entity_id': 'locality:shelby_county',
        'title': 'Shelby County',
        'name': 'Shelby County',
        'locality': 'shelby_county',
        'observed_at': validFrom,
        'published_at': validFrom,
        'valid_from': validFrom,
        'valid_to': validTo,
        'last_verified_at': lastVerifiedAt,
        'category': 'county_spatial_anchor',
        'historical_admissibility': 'year_valid_structural_snapshot',
        'historical_capture_method': historicalCaptureMethod,
        'historical_validation_note':
            'Promoted as a stable county-level spatial anchor for 2023 from the RPCGB regional GIS catalog; used for locality grounding only.',
        'historical_source_url': sourceUrl,
        'source_host': sourceHost,
        'source_page_title': sourcePageTitle,
        'source_row_basis': const <String>['rpcgb-10', 'rpcgb-11'],
        'confidence': 0.76,
        'uncertainty_minutes': 1440,
      },
      <String, dynamic>{
        'record_id': 'rpcgb-hist-birmingham-open-data-2023',
        'entity_type': 'locality',
        'entity_id': 'locality:bham_regional_open_data',
        'title': 'Birmingham Regional Open Data Portal',
        'name': 'Birmingham Regional Open Data Portal',
        'locality': 'greater_birmingham_region',
        'observed_at': validFrom,
        'published_at': validFrom,
        'valid_from': validFrom,
        'valid_to': validTo,
        'last_verified_at': lastVerifiedAt,
        'category': 'regional_data_anchor',
        'historical_admissibility': 'year_valid_structural_snapshot',
        'historical_capture_method': historicalCaptureMethod,
        'historical_validation_note':
            'Promoted from the RPCGB open-data listing as a stable regional spatial-data anchor valid throughout 2023; used for replay-world place grounding only.',
        'historical_source_url': sourceUrl,
        'source_host': sourceHost,
        'source_page_title': sourcePageTitle,
        'source_row_basis': const <String>['rpcgb-3', 'rpcgb-5'],
        'confidence': 0.74,
        'uncertainty_minutes': 1440,
      },
      <String, dynamic>{
        'record_id': 'rpcgb-hist-regional-transportation-plan-2023',
        'entity_type': 'movement_flow',
        'entity_id': 'movement_flow:regional_transportation_plan',
        'title': 'Regional Transportation Plan',
        'name': 'Regional Transportation Plan',
        'locality': 'greater_birmingham_region',
        'observed_at': validFrom,
        'published_at': validFrom,
        'valid_from': validFrom,
        'valid_to': validTo,
        'last_verified_at': lastVerifiedAt,
        'category': 'regional_transport_anchor',
        'historical_admissibility': 'year_valid_structural_snapshot',
        'historical_capture_method': historicalCaptureMethod,
        'historical_validation_note':
            'Promoted as a stable regional transportation-structure anchor for 2023; used to ground movement-flow expectations, not as direct traffic truth.',
        'historical_source_url': sourceUrl,
        'source_host': sourceHost,
        'source_page_title': sourcePageTitle,
        'source_row_basis': const <String>['rpcgb-1'],
        'confidence': 0.71,
        'uncertainty_minutes': 2880,
      },
      <String, dynamic>{
        'record_id': 'rpcgb-hist-building-communities-program-2023',
        'entity_type': 'community',
        'entity_id': 'community:rpcgb_building_communities_program',
        'title': 'RPCGB Building Communities Program',
        'name': 'RPCGB Building Communities Program',
        'locality': 'greater_birmingham_region',
        'observed_at': validFrom,
        'published_at': validFrom,
        'valid_from': validFrom,
        'valid_to': validTo,
        'last_verified_at': lastVerifiedAt,
        'category': 'regional_community_program_anchor',
        'historical_admissibility': 'year_valid_structural_snapshot',
        'historical_capture_method': historicalCaptureMethod,
        'historical_validation_note':
            'Promoted as a regional community-planning anchor that remained structurally relevant in 2023; used for community/governance context, not as dated event truth.',
        'historical_source_url': sourceUrl,
        'source_host': sourceHost,
        'source_page_title': sourcePageTitle,
        'source_row_basis': const <String>['rpcgb-2'],
        'confidence': 0.7,
        'uncertainty_minutes': 2880,
      },
    ];
  }

  List<Map<String, dynamic>> _inBirminghamRecords(int replayYear) {
    final validFrom = DateTime.utc(replayYear, 1, 1).toIso8601String();
    final validTo = DateTime.utc(replayYear, 12, 31, 23, 59, 59).toIso8601String();
    const lastVerifiedAt = '2026-03-12T23:00:00Z';
    const sourceHost = 'inbirmingham.com';
    const sourcePageTitle = 'Birmingham Guides and Community Pages';
    const historicalCaptureMethod = 'governed_public_catalog_historicalization';

    Map<String, dynamic> communityRow({
      required String recordId,
      required String entityId,
      required String name,
      required String locality,
      required String sourceUrl,
      required List<String> sourceRowBasis,
      required String validationNote,
      double confidence = 0.74,
    }) {
      return <String, dynamic>{
        'record_id': recordId,
        'entity_type': 'community',
        'entity_id': entityId,
        'title': name,
        'name': name,
        'community_name': name,
        'locality': locality,
        'observed_at': validFrom,
        'published_at': validFrom,
        'valid_from': validFrom,
        'valid_to': validTo,
        'last_verified_at': lastVerifiedAt,
        'category': 'destination_community_anchor',
        'historical_admissibility': 'year_valid_structural_snapshot',
        'historical_capture_method': historicalCaptureMethod,
        'historical_validation_note': validationNote,
        'historical_source_url': sourceUrl,
        'source_host': sourceHost,
        'source_page_title': sourcePageTitle,
        'source_row_basis': sourceRowBasis,
        'confidence': confidence,
        'uncertainty_minutes': 2880,
      };
    }

    return <Map<String, dynamic>>[
      <String, dynamic>{
        'record_id': 'inbham-hist-bham-metro-guides-2023',
        'entity_type': 'locality',
        'entity_id': 'locality:bham_metro_regional',
        'title': 'Birmingham Metro Visitor and Culture Guide Network',
        'name': 'Birmingham Metro Visitor and Culture Guide Network',
        'locality': 'bham_metro_regional',
        'observed_at': validFrom,
        'published_at': validFrom,
        'valid_from': validFrom,
        'valid_to': validTo,
        'last_verified_at': lastVerifiedAt,
        'category': 'tourism_locality_anchor',
        'historical_admissibility': 'year_valid_structural_snapshot',
        'historical_capture_method': historicalCaptureMethod,
        'historical_validation_note':
            'Promoted as a stable metro-level tourism and locality guide anchor valid throughout 2023; not treated as a dated event row.',
        'historical_source_url': 'https://inbirmingham.com/birmingham-guides/',
        'source_host': sourceHost,
        'source_page_title': sourcePageTitle,
        'source_row_basis': const <String>['inbham-1'],
        'confidence': 0.72,
        'uncertainty_minutes': 2880,
      },
      communityRow(
        recordId: 'inbham-hist-avondale-crestwood-2023',
        entityId: 'community:bham_avondale_crestwood',
        name: 'Avondale / Crestwood',
        locality: 'bham_avondale',
        sourceUrl: 'https://inbirmingham.com/community/avondale-crestwood/',
        sourceRowBasis: const <String>['inbham-2'],
        validationNote:
            'Promoted as a stable destination-community anchor representing Avondale and Crestwood throughout 2023; not treated as a dated event row.',
      ),
      communityRow(
        recordId: 'inbham-hist-downtown-2023',
        entityId: 'community:bham_downtown',
        name: 'Downtown',
        locality: 'bham_downtown',
        sourceUrl: 'https://inbirmingham.com/community/downtown/',
        sourceRowBasis: const <String>['inbham-4'],
        validationNote:
            'Promoted as a stable destination-community anchor representing downtown Birmingham throughout 2023; not treated as a dated event row.',
      ),
      communityRow(
        recordId: 'inbham-hist-homewood-2023',
        entityId: 'community:bham_homewood',
        name: 'Homewood',
        locality: 'bham_metro_regional',
        sourceUrl: 'https://inbirmingham.com/community/homewood/',
        sourceRowBasis: const <String>['inbham-7'],
        validationNote:
            'Promoted as a stable metro destination-community anchor representing Homewood throughout 2023; not treated as a dated event row.',
      ),
      communityRow(
        recordId: 'inbham-hist-hoover-2023',
        entityId: 'community:bham_hoover',
        name: 'Hoover',
        locality: 'bham_metro_regional',
        sourceUrl: 'https://inbirmingham.com/community/hoover/',
        sourceRowBasis: const <String>['inbham-8'],
        validationNote:
            'Promoted as a stable metro destination-community anchor representing Hoover throughout 2023; not treated as a dated event row.',
      ),
      communityRow(
        recordId: 'inbham-hist-irondale-2023',
        entityId: 'community:bham_irondale',
        name: 'Irondale',
        locality: 'bham_metro_regional',
        sourceUrl: 'https://inbirmingham.com/community/irondale/',
        sourceRowBasis: const <String>['inbham-9'],
        validationNote:
            'Promoted as a stable metro destination-community anchor representing Irondale throughout 2023; not treated as a dated event row.',
      ),
      communityRow(
        recordId: 'inbham-hist-bessemer-2023',
        entityId: 'community:bham_bessemer',
        name: 'Bessemer',
        locality: 'bham_metro_regional',
        sourceUrl: 'https://inbirmingham.com/community/bessemer/',
        sourceRowBasis: const <String>['inbham-3'],
        validationNote:
            'Promoted as a stable metro destination-community anchor representing Bessemer throughout 2023; not treated as a dated event row.',
      ),
      communityRow(
        recordId: 'inbham-hist-fultondale-2023',
        entityId: 'community:bham_fultondale',
        name: 'Fultondale',
        locality: 'bham_metro_regional',
        sourceUrl: 'https://inbirmingham.com/community/fultondale/',
        sourceRowBasis: const <String>['inbham-5'],
        validationNote:
            'Promoted as a stable metro destination-community anchor representing Fultondale throughout 2023; not treated as a dated event row.',
        confidence: 0.71,
      ),
      communityRow(
        recordId: 'inbham-hist-gardendale-2023',
        entityId: 'community:bham_gardendale',
        name: 'Gardendale',
        locality: 'bham_metro_regional',
        sourceUrl: 'https://inbirmingham.com/community/gardendale/',
        sourceRowBasis: const <String>['inbham-6'],
        validationNote:
            'Promoted as a stable metro destination-community anchor representing Gardendale throughout 2023; not treated as a dated event row.',
        confidence: 0.71,
      ),
      communityRow(
        recordId: 'inbham-hist-leeds-2023',
        entityId: 'community:bham_leeds',
        name: 'Leeds',
        locality: 'bham_metro_regional',
        sourceUrl: 'https://inbirmingham.com/community/leeds/',
        sourceRowBasis: const <String>['inbham-10'],
        validationNote:
            'Promoted as a stable metro destination-community anchor representing Leeds throughout 2023; not treated as a dated event row.',
        confidence: 0.71,
      ),
      communityRow(
        recordId: 'inbham-hist-mountain-brook-2023',
        entityId: 'community:bham_mountain_brook',
        name: 'Mountain Brook',
        locality: 'bham_metro_regional',
        sourceUrl: 'https://inbirmingham.com/community/mountain-brook/',
        sourceRowBasis: const <String>['inbham-11'],
        validationNote:
            'Promoted as a stable metro destination-community anchor representing Mountain Brook throughout 2023; not treated as a dated event row.',
        confidence: 0.72,
      ),
      communityRow(
        recordId: 'inbham-hist-trussville-2023',
        entityId: 'community:bham_trussville',
        name: 'Trussville',
        locality: 'bham_metro_regional',
        sourceUrl: 'https://inbirmingham.com/community/trussville/',
        sourceRowBasis: const <String>['inbham-12'],
        validationNote:
            'Promoted as a stable metro destination-community anchor representing Trussville throughout 2023; not treated as a dated event row.',
        confidence: 0.71,
      ),
      communityRow(
        recordId: 'inbham-hist-vestavia-2023',
        entityId: 'community:bham_vestavia',
        name: 'Vestavia',
        locality: 'bham_metro_regional',
        sourceUrl: 'https://inbirmingham.com/community/vestavia/',
        sourceRowBasis: const <String>['inbham-13'],
        validationNote:
            'Promoted as a stable metro destination-community anchor representing Vestavia throughout 2023; not treated as a dated event row.',
        confidence: 0.71,
      ),
    ];
  }
}
