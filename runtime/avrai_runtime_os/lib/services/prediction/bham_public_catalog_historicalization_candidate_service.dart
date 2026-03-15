import 'package:avrai_core/avra_core.dart';

class BhamPublicCatalogHistoricalizationCandidateService {
  const BhamPublicCatalogHistoricalizationCandidateService();

  List<Map<String, dynamic>> buildCandidates(ReplaySourcePack pack) {
    return pack.datasets
        .where(_isPublicCatalogCandidate)
        .map(_toCandidate)
        .toList(growable: false);
  }

  bool _isPublicCatalogCandidate(ReplaySourceDataset dataset) {
    final coverageStatus = '${dataset.metadata['coverageStatus'] ?? ''}';
    final historicalReady = dataset.metadata['historicalReplayReady'] == true;
    return !historicalReady &&
        (coverageStatus.contains('catalog') || coverageStatus.contains('tourism'));
  }

  Map<String, dynamic> _toCandidate(ReplaySourceDataset dataset) {
    final recordSamples = dataset.records
        .where(_looksSampleable)
        .take(5)
        .map(
          (record) => <String, dynamic>{
            'recordId': record['record_id'],
            'name': record['name'] ?? record['title'],
            'entityType': record['entity_type'],
            'locality': record['locality'],
          },
        )
        .toList(growable: false);
    return <String, dynamic>{
      'sourceName': dataset.sourceName,
      'coverageStatus': dataset.metadata['coverageStatus'],
      'recordCount': dataset.records.length,
      'sourceUri': dataset.metadata['uri'],
      'historicalizationTarget':
          'replace current catalog rows with archived 2023 rows or governed year-valid snapshots',
      'sampleRecords': recordSamples,
    };
  }

  bool _looksSampleable(Map<String, dynamic> record) {
    final rawName = '${record['name'] ?? record['title'] ?? ''}'.trim();
    if (rawName.isEmpty || rawName.length < 4) {
      return false;
    }
    final normalized = rawName.toLowerCase();
    if (normalized.contains('logo-wordmark') || normalized.contains('{fill:')) {
      return false;
    }
    const blocked = <String>{
      'eventbrite',
      'find my tickets',
      'log in',
      'sign up',
      'meetings & conventions',
      'meetings &#038; conventions',
      'sports',
      'travel pros',
      'events',
      'news & stories',
      'news &#038; stories',
      'open data',
    };
    return !blocked.contains(normalized);
  }
}
