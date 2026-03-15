import 'package:avrai_runtime_os/services/prediction/bham_replay_source_registry_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses BHAM replay source registry JSON', () {
    const service = BhamReplaySourceRegistryService();

    final registry = service.parseRegistryJson('''
{
  "registryId": "bham-registry",
  "registryVersion": "wave8-phase1",
  "generatedAtUtc": "2026-03-10T12:00:00Z",
  "status": "active",
  "selectionCandidateYears": [2024, 2025],
  "notes": ["registry test"],
  "sources": [
    {
      "sourceName": "City Events",
      "sourceType": "official_calendar",
      "accessMethod": "api",
      "trustTier": "tier1",
      "status": "approved",
      "entityCoverage": ["events", "venues", "communities"],
      "temporalStartYear": 2024,
      "temporalEndYear": 2025,
      "replayRole": "event_truth",
      "legalStatus": "allowed",
      "updateCadence": "daily",
      "richestYear": 2025,
      "structuredExportAvailable": true,
      "seedingEligible": true
    }
  ]
}
''');

    expect(registry.registryId, 'bham-registry');
    expect(registry.selectionCandidateYears, const <int>[2024, 2025]);
    expect(registry.sources.single.sourceName, 'City Events');
    expect(registry.sources.single.seedingEligible, isTrue);
  });
}
