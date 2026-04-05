import 'package:avrai_runtime_os/services/intake/intake_models.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';

import 'kernel_graph_primitive_registry.dart';

class IntakeKernelGraphPrimitives {
  static const String upsertSourceDescriptor =
      'intake.upsert_source_descriptor';
  static const String upsertSyncJob = 'intake.upsert_sync_job';
  static const String upsertReviewItem = 'intake.upsert_review_item';

  static KernelGraphPrimitiveRegistry buildRegistry({
    required UniversalIntakeRepository intakeRepository,
  }) {
    final registry = KernelGraphPrimitiveRegistry();

    registry.register(
      KernelGraphPrimitiveHandler(
        id: upsertSourceDescriptor,
        label: 'Persist intake source descriptor',
        description:
            'Writes the normalized source descriptor for a governed intake item.',
        execute: (context, step) async {
          final descriptor = ExternalSourceDescriptor.fromJson(
            _map(step.config['descriptor']),
          );
          await intakeRepository.upsertSource(descriptor);
          context.recordArtifact(step.nodeId, descriptor.id);
          context.write('${step.nodeId}.sourceId', descriptor.id);
          return KernelGraphNodeExecutionResult(
            summary: 'Persisted intake source `${descriptor.id}`.',
            outputRefs: <String>[descriptor.id],
            metadata: <String, dynamic>{'sourceId': descriptor.id},
          );
        },
      ),
    );

    registry.register(
      KernelGraphPrimitiveHandler(
        id: upsertSyncJob,
        label: 'Persist intake sync job',
        description:
            'Writes the review-lane job record for a governed intake item.',
        execute: (context, step) async {
          final job = ExternalSyncJob.fromJson(_map(step.config['job']));
          await intakeRepository.upsertJob(job);
          context.recordArtifact(step.nodeId, job.id);
          context.write('${step.nodeId}.jobId', job.id);
          return KernelGraphNodeExecutionResult(
            summary: 'Persisted intake job `${job.id}`.',
            outputRefs: <String>[job.id],
            metadata: <String, dynamic>{'jobId': job.id},
          );
        },
      ),
    );

    registry.register(
      KernelGraphPrimitiveHandler(
        id: upsertReviewItem,
        label: 'Persist intake review item',
        description:
            'Queues the governed intake item for bounded upward review.',
        execute: (context, step) async {
          final reviewItem = OrganizerReviewItem.fromJson(
            _map(step.config['reviewItem']),
          );
          await intakeRepository.upsertReviewItem(reviewItem);
          context.recordArtifact(step.nodeId, reviewItem.id);
          context.write('${step.nodeId}.reviewItemId', reviewItem.id);
          return KernelGraphNodeExecutionResult(
            summary: 'Queued review item `${reviewItem.id}`.',
            outputRefs: <String>[reviewItem.id],
            metadata: <String, dynamic>{'reviewItemId': reviewItem.id},
          );
        },
      ),
    );

    return registry;
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}
