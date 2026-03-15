import 'dart:convert';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_manual_import_template_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_pull_plan_service.dart';

class BhamReplayManualImportBundleService {
  const BhamReplayManualImportBundleService({
    this.templateService = const BhamReplayManualImportTemplateService(),
  });

  final BhamReplayManualImportTemplateService templateService;

  static const List<String> defaultPrioritySources = <String>[
    'ALDOT Traffic Data',
    'ALDOT Long-Term Construction Projects',
    'City of Birmingham OpenGov',
    'UAB Academic, Clinical, and Event Calendars',
  ];

  ReplayManualImportBundle buildPriorityBundle({
    required ReplayIngestionManifest manifest,
    required BhamReplayPullPlanBatch pullPlan,
    List<String> prioritySources = defaultPrioritySources,
  }) {
    final templates = templateService.buildTemplates(
      manifest: manifest,
      pullPlan: pullPlan,
    );
    final allowed = prioritySources.toSet();
    final entries = templates.templates
        .where((template) => allowed.contains(template.sourceName))
        .map(
          (template) => ReplayManualImportEntry(
            sourceName: template.sourceName,
            rawOutputKey: template.rawOutputKey,
            requiredFields: template.requiredFields,
            dedupeKeys: template.dedupeKeys,
            normalizationTargets: template.normalizationTargets,
            requiresReview: template.requiresReview,
            templateRecord: template.exampleRecord,
            records: const <Map<String, dynamic>>[],
            notes: template.notes,
          ),
        )
        .toList();

    return ReplayManualImportBundle(
      bundleId:
          'bham-priority-manual-import-${manifest.replayYear}-${entries.length}',
      replayYear: manifest.replayYear,
      generatedAtUtc: DateTime.now().toUtc(),
      entries: entries,
      notes: <String>[
        'Priority manual-import scaffold for BHAM replay year ${manifest.replayYear}.',
        'Populate entry records with governed raw source rows before converting to a replay source pack.',
      ],
      metadata: <String, dynamic>{
        'prioritySources': prioritySources,
      },
    );
  }

  ReplaySourcePack toReplaySourcePack(ReplayManualImportBundle bundle) {
    final validation = validateBundle(bundle);
    if (!validation.isValid) {
      final issueSummary = validation.issues
          .map(
            (issue) =>
                '${issue.sourceName}[${issue.recordIndex}]: ${issue.missingFields.join(', ')}',
          )
          .join('; ');
      throw FormatException(
        'Replay manual-import bundle is invalid: $issueSummary',
      );
    }

    final datasets = bundle.entries
        .where((entry) => entry.records.isNotEmpty)
        .map(
          (entry) => ReplaySourceDataset(
            sourceName: entry.sourceName,
            records: entry.records,
            metadata: <String, dynamic>{
              'rawOutputKey': entry.rawOutputKey,
              'requiresReview': entry.requiresReview,
              'status': entry.status.name,
              'normalizationTargets': entry.normalizationTargets,
              'dedupeKeys': entry.dedupeKeys,
            },
          ),
        )
        .toList();

    return ReplaySourcePack(
      packId: 'manual-import-${bundle.bundleId}',
      replayYear: bundle.replayYear,
      generatedAtUtc: DateTime.now().toUtc(),
      datasets: datasets,
      notes: <String>[
        ...bundle.notes,
        'Generated from manual-import bundle ${bundle.bundleId}.',
      ],
      metadata: <String, dynamic>{
        'sourceBundleId': bundle.bundleId,
      },
    );
  }

  ReplayManualImportValidationResult validateBundle(
    ReplayManualImportBundle bundle,
  ) {
    final issues = <ReplayManualImportValidationIssue>[];

    for (final entry in bundle.entries) {
      for (var index = 0; index < entry.records.length; index++) {
        final record = entry.records[index];
        final missingFields = entry.requiredFields
            .where(
              (field) =>
                  !record.containsKey(field) ||
                  record[field] == null ||
                  (record[field] is String &&
                      (record[field] as String).trim().isEmpty),
            )
            .toList();
        if (missingFields.isEmpty) {
          continue;
        }
        issues.add(
          ReplayManualImportValidationIssue(
            sourceName: entry.sourceName,
            recordIndex: index,
            missingFields: missingFields,
          ),
        );
      }
    }

    return ReplayManualImportValidationResult(issues: issues);
  }

  ReplayManualImportBundle parseBundleJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      throw const FormatException(
        'Replay manual-import bundle must be a JSON object.',
      );
    }
    return ReplayManualImportBundle.fromJson(
      decoded.map((key, value) => MapEntry('$key', value)),
    );
  }
}

class ReplayManualImportValidationIssue {
  const ReplayManualImportValidationIssue({
    required this.sourceName,
    required this.recordIndex,
    required this.missingFields,
  });

  final String sourceName;
  final int recordIndex;
  final List<String> missingFields;
}

class ReplayManualImportValidationResult {
  const ReplayManualImportValidationResult({
    required this.issues,
  });

  final List<ReplayManualImportValidationIssue> issues;

  bool get isValid => issues.isEmpty;
}
