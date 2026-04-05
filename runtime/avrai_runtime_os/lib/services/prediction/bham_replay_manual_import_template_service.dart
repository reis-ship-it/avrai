import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_pull_plan_service.dart';

class ReplayManualImportTemplate {
  const ReplayManualImportTemplate({
    required this.sourceName,
    required this.rawOutputKey,
    required this.requiredFields,
    required this.dedupeKeys,
    required this.normalizationTargets,
    this.requiresReview = false,
    this.exampleRecord = const <String, dynamic>{},
    this.notes = const <String>[],
  });

  final String sourceName;
  final String rawOutputKey;
  final List<String> requiredFields;
  final List<String> dedupeKeys;
  final List<String> normalizationTargets;
  final bool requiresReview;
  final Map<String, dynamic> exampleRecord;
  final List<String> notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sourceName': sourceName,
      'rawOutputKey': rawOutputKey,
      'requiredFields': requiredFields,
      'dedupeKeys': dedupeKeys,
      'normalizationTargets': normalizationTargets,
      'requiresReview': requiresReview,
      'exampleRecord': exampleRecord,
      'notes': notes,
    };
  }
}

class ReplayManualImportTemplateBatch {
  const ReplayManualImportTemplateBatch({
    required this.replayYear,
    required this.templates,
  });

  final int replayYear;
  final List<ReplayManualImportTemplate> templates;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'replayYear': replayYear,
      'templates': templates.map((template) => template.toJson()).toList(),
    };
  }
}

class BhamReplayManualImportTemplateService {
  const BhamReplayManualImportTemplateService();

  ReplayManualImportTemplateBatch buildTemplates({
    required ReplayIngestionManifest manifest,
    required BhamReplayPullPlanBatch pullPlan,
  }) {
    final templates = <ReplayManualImportTemplate>[];
    final planByName = <String, ReplaySourcePullPlan>{
      for (final plan in pullPlan.plans) plan.sourceName: plan,
    };

    for (final sourcePlan in manifest.sourcePlans) {
      final pullPlanEntry = planByName[sourcePlan.source.sourceName];
      if (pullPlanEntry == null) {
        continue;
      }
      if (pullPlanEntry.acquisitionMode != ReplaySourceAcquisitionMode.manualImport &&
          pullPlanEntry.acquisitionMode != ReplaySourceAcquisitionMode.partnerReview) {
        continue;
      }

      final plannedFields =
          (sourcePlan.source.metadata['plannedIngestFields'] as List?)
                  ?.map((entry) => entry.toString())
                  .toList() ??
              const <String>[];
      final requiredFields = <String>{
        'record_id',
        'entity_type',
        'entity_id',
        'observed_at',
        'published_at',
        ...plannedFields,
      }.toList();

      final exampleRecord = <String, dynamic>{
        for (final field in requiredFields) field: '<required>',
      };
      if (sourcePlan.normalizationTargetTypes.isNotEmpty) {
        exampleRecord['entity_type'] = sourcePlan.normalizationTargetTypes.first;
      }
      exampleRecord['locality'] = '<bham_locality>';

      templates.add(
        ReplayManualImportTemplate(
          sourceName: sourcePlan.source.sourceName,
          rawOutputKey: pullPlanEntry.rawOutputKey,
          requiredFields: requiredFields,
          dedupeKeys: sourcePlan.dedupeKeys,
          normalizationTargets: sourcePlan.normalizationTargetTypes,
          requiresReview: pullPlanEntry.requiresReview,
          exampleRecord: exampleRecord,
          notes: <String>[
            ...pullPlanEntry.notes,
            ...sourcePlan.notes,
          ],
        ),
      );
    }

    return ReplayManualImportTemplateBatch(
      replayYear: manifest.replayYear,
      templates: templates,
    );
  }
}
