import 'package:avrai_core/models/reality/artifact_lifecycle.dart';
import 'package:test/test.dart';

void main() {
  test('ArtifactLifecycleMetadata round-trips through json', () {
    const metadata = ArtifactLifecycleMetadata(
      artifactClass: ArtifactLifecycleClass.canonical,
      artifactState: ArtifactLifecycleState.accepted,
      retentionPolicy: ArtifactRetentionPolicy(
        mode: ArtifactRetentionMode.archive,
        ttlDays: 30,
        deleteWhenSuperseded: true,
      ),
      artifactFamily: 'replay_training_export_manifest',
      sourceScope: 'simulation',
      provenanceRefs: <String>['source:35', 'source:36'],
      evaluationRefs: <String>['eval:69'],
      promotionRefs: <String>['promotion:training_kernel'],
      containsRawPersonalPayload: false,
      containsMessageContent: false,
    );

    final decoded = ArtifactLifecycleMetadata.fromJson(metadata.toJson());

    expect(decoded.artifactClass, ArtifactLifecycleClass.canonical);
    expect(decoded.artifactState, ArtifactLifecycleState.accepted);
    expect(decoded.retentionPolicy.mode, ArtifactRetentionMode.archive);
    expect(decoded.retentionPolicy.ttlDays, 30);
    expect(decoded.retentionPolicy.deleteWhenSuperseded, isTrue);
    expect(decoded.artifactFamily, 'replay_training_export_manifest');
    expect(decoded.sourceScope, 'simulation');
    expect(decoded.provenanceRefs, <String>['source:35', 'source:36']);
    expect(decoded.evaluationRefs, <String>['eval:69']);
    expect(decoded.promotionRefs, <String>['promotion:training_kernel']);
    expect(decoded.containsRawPersonalPayload, isFalse);
    expect(decoded.containsMessageContent, isFalse);
  });

  test('ArtifactLifecycleMetadata falls back safely for unknown wire values',
      () {
    final decoded = ArtifactLifecycleMetadata.fromJson(<String, dynamic>{
      'artifactClass': 'unknown_class',
      'artifactState': 'unknown_state',
      'retentionPolicy': <String, dynamic>{
        'mode': 'unknown_mode',
      },
    });

    expect(decoded.artifactClass, ArtifactLifecycleClass.temporary);
    expect(decoded.artifactState, ArtifactLifecycleState.candidate);
    expect(decoded.retentionPolicy.mode, ArtifactRetentionMode.keepForever);
    expect(decoded.retentionPolicy.ttlDays, isNull);
    expect(decoded.retentionPolicy.deleteWhenSuperseded, isFalse);
  });
}
