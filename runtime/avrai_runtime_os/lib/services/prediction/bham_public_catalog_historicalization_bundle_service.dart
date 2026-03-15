import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_public_catalog_historicalization_candidate_service.dart';

class BhamPublicCatalogHistoricalizationBundleService {
  const BhamPublicCatalogHistoricalizationBundleService({
    this.candidateService =
        const BhamPublicCatalogHistoricalizationCandidateService(),
  });

  final BhamPublicCatalogHistoricalizationCandidateService candidateService;

  ReplayHistoricalizationBundle buildBundle(ReplaySourcePack pack) {
    final candidates = candidateService.buildCandidates(pack);
    final entries = candidates
        .map(
          (candidate) => ReplayHistoricalizationEntry(
            sourceName: candidate['sourceName'] as String? ?? '',
            sourceUri: candidate['sourceUri'] as String? ?? '',
            coverageStatus: candidate['coverageStatus'] as String? ?? '',
            recordCount: (candidate['recordCount'] as num?)?.toInt() ?? 0,
            requiredHistoricalFields: _requiredFieldsFor(
              candidate['sourceName'] as String? ?? '',
            ),
            sourceSpecificActions: _actionsFor(
              candidate['sourceName'] as String? ?? '',
            ),
            samples: ((candidate['sampleRecords'] as List?) ?? const <dynamic>[])
                .whereType<Map>()
                .map(
                  (entry) => ReplayHistoricalizationSample.fromJson(
                    entry.map((key, value) => MapEntry('$key', value)),
                  ),
                )
                .toList(growable: false),
            notes: _notesFor(candidate['sourceName'] as String? ?? ''),
          ),
        )
        .toList(growable: false);

    return ReplayHistoricalizationBundle(
      bundleId: 'bham-public-catalog-historicalization-${pack.replayYear}',
      replayYear: pack.replayYear,
      generatedAtUtc: DateTime.now().toUtc(),
      entries: entries,
      notes: const <String>[
        'Operational public catalogs should not be promoted to replay truth until replaced by governed year-valid 2023 historical rows.',
        'This bundle is the handoff from public-catalog seeding to archival or year-valid historicalization.',
      ],
    );
  }

  List<String> _requiredFieldsFor(String sourceName) {
    return const <String>[
      'historical_source_url',
      'historical_capture_method',
      'record_id',
      'entity_id',
      'entity_type',
      'name',
      'observed_at',
      'published_at',
      'valid_from',
      'valid_to',
      'historical_validation_note',
    ];
  }

  List<String> _actionsFor(String sourceName) {
    switch (sourceName) {
      case 'Jefferson / Shelby / Regional GIS and Assessors':
        return const <String>[
          'Replace current catalog rows with year-valid 2023 geometry, parcel, building, or zoning exports.',
          'Prefer official 2023 downloads, snapshots, or archived RPCGB/ArcGIS items over current landing-page links.',
          'Convert structural catalog items into locality, parcel, building, housing, or economic replay rows only when year validity is explicit.',
        ];
      case 'IN Birmingham (CVB Calendar)':
        return const <String>[
          'Replace current guides and tourism landing pages with archived 2023 event or neighborhood/community rows.',
          'Prefer official 2023 CVB event pages or archived captures with explicit date validity.',
          'Dedupe venue and event truth against official city pages, BJCC, and major venue calendars before promotion.',
        ];
      case 'Eventbrite / Meetup':
        return const <String>[
          'Replace current discovery pages with archived or year-valid 2023 event/group rows.',
          'Dedupe against official venue calendars and city event truth before promotion.',
          'Keep only event, community, or club rows with explicit Birmingham locality and date validity.',
        ];
      default:
        return const <String>[
          'Replace current catalog rows with archived or year-valid 2023 rows before promotion into replay truth.',
        ];
    }
  }

  List<String> _notesFor(String sourceName) {
    switch (sourceName) {
      case 'Jefferson / Shelby / Regional GIS and Assessors':
        return const <String>[
          'Current lane is operational, but still structural spatial catalog truth rather than governed 2023 parcel/building truth.',
        ];
      case 'IN Birmingham (CVB Calendar)':
        return const <String>[
          'Current lane is operational, but still tourism/community catalog truth rather than governed 2023 historical event truth.',
        ];
      case 'Eventbrite / Meetup':
        return const <String>[
          'Current lane is operational, but still public community-event catalog truth rather than governed 2023 historical event truth.',
        ];
      default:
        return const <String>[];
    }
  }
}
