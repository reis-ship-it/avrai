import 'package:avrai_runtime_os/services/security/security_campaign_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('critical release-blocking lanes are fully mapped and owned', () {
    final definitions =
        const SecurityCampaignRegistry().releaseBlockingDefinitions();
    final laneIds = definitions.map((entry) => entry.laneId).toSet();

    expect(
      laneIds,
      containsAll(<String>[
        'RT-001',
        'RT-002',
        'RT-003',
        'RT-004',
        'RT-006',
        'RT-008',
        'RT-009',
        'RT-012',
      ]),
    );
    for (final definition in definitions) {
      expect(definition.ownerAlias, isNotEmpty, reason: definition.laneId);
      expect(definition.ownershipArea, isNotEmpty, reason: definition.laneId);
      expect(definition.mappedScenarioIds, isNotEmpty,
          reason: definition.laneId);
      expect(definition.requiredProofKinds, isNotEmpty,
          reason: definition.laneId);
    }
  });
}
