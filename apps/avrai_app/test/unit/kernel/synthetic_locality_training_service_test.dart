import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/kernel/locality/synthetic_locality_training_service.dart';

void main() {
  group('SyntheticLocalityTrainingService', () {
    const service = SyntheticLocalityTrainingService();

    test('builds a passing zero-locality reliability report', () async {
      final artifact = await service.loadBaselineArtifact(
        cityProfile: 'bham_demo',
        modelFamily: 'reality_model',
      );
      final batch = await service.buildBootstrapBatch(
        cityProfile: 'bham_demo',
        localityCount: 9,
      );
      final report = await service.evaluateZeroLocality(
        artifact: artifact,
        batch: batch,
      );

      expect(artifact.artifactId, contains('bham_demo'));
      expect(batch.scenarios, isNotEmpty);
      expect(report.metrics, isNotEmpty);
      expect(report.passes, isTrue);
    });
  });
}
