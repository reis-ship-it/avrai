import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/config/replay_storage_config.dart';
import 'package:avrai_runtime_os/config/supabase_config.dart';

class BhamReplayStorageBoundaryService {
  const BhamReplayStorageBoundaryService();

  static const List<String> _knownAppBuckets = <String>[
    SupabaseConfig.userAvatarsBucket,
    SupabaseConfig.spotImagesBucket,
    SupabaseConfig.listImagesBucket,
    'paperwork-documents',
    'tax-documents',
    'geo-packs',
    'local-llm-models',
  ];

  ReplayStorageBoundaryReport buildReport({
    required String environmentId,
    required int replayYear,
    Map<String, dynamic> artifactMetadata = const <String, dynamic>{},
    String replaySchema = ReplayStorageConfig.schema,
    List<String> replayBuckets = ReplayStorageConfig.buckets,
    List<String> replayMetadataTables = ReplayStorageConfig.metadataTables,
    List<String> appBuckets = _knownAppBuckets,
    List<String> appSchemas = const <String>['public'],
    String replayUrl = ReplayStorageConfig.url,
    String appUrl = SupabaseConfig.url,
  }) {
    final replayBucketSet =
        replayBuckets.where((entry) => entry.isNotEmpty).toSet();
    final appBucketSet = appBuckets.where((entry) => entry.isNotEmpty).toSet();
    final overlappingBuckets =
        replayBucketSet.intersection(appBucketSet).toList()..sort();

    final violations = <String>[];
    if (replaySchema.isEmpty) {
      violations.add('Replay schema must be explicitly set.');
    }
    if (replaySchema == 'public') {
      violations.add('Replay schema may not use the live app public schema.');
    }
    if (overlappingBuckets.isNotEmpty) {
      violations.add(
        'Replay buckets overlap live app buckets: ${overlappingBuckets.join(', ')}.',
      );
    }
    final nonPrefixedBuckets = replayBucketSet
        .where((entry) => !entry.startsWith('replay-'))
        .toList()
      ..sort();
    if (nonPrefixedBuckets.isNotEmpty) {
      violations.add(
        'Replay buckets must use the replay- prefix: ${nonPrefixedBuckets.join(', ')}.',
      );
    }
    final nonPrefixedTables = replayMetadataTables
        .where((entry) => !entry.startsWith('replay_'))
        .toList()
      ..sort();
    if (nonPrefixedTables.isNotEmpty) {
      violations.add(
        'Replay metadata tables must use the replay_ prefix: ${nonPrefixedTables.join(', ')}.',
      );
    }
    if (appSchemas.contains(replaySchema)) {
      violations.add(
        'Replay schema overlaps an app schema: $replaySchema.',
      );
    }

    final projectIsolationMode =
        replayUrl.isNotEmpty && appUrl.isNotEmpty && replayUrl != appUrl
            ? 'dedicated_project'
            : 'shared_project_isolated_namespace';
    final citySlug = _citySlugFromEnvironmentId(environmentId);
    final cityDisplayName = _cityDisplayNameFromSlug(citySlug);

    return ReplayStorageBoundaryReport(
      environmentId: environmentId,
      replayYear: replayYear,
      passed: violations.isEmpty,
      projectIsolationMode: projectIsolationMode,
      replaySchema: replaySchema,
      replayBuckets: replayBucketSet.toList()..sort(),
      replayMetadataTables: replayMetadataTables.toList()..sort(),
      appBuckets: appBucketSet.toList()..sort(),
      appSchemas: appSchemas.toList()..sort(),
      violations: violations,
      policySnapshot: <String, String>{
        'liveAppBucketReuse': 'blocked',
        'liveAppSchemaReuse': 'blocked',
        'appDirectReplayAccess': 'blocked',
        'replayWriteAuthority': 'admin_tooling_or_service_role_only',
      },
      notes: <String>[
        if (projectIsolationMode == 'dedicated_project')
          'Replay storage is configured to use a dedicated Supabase project.'
        else
          'Replay storage may share the Supabase project, but must remain isolated by schema and replay-prefixed buckets.',
        'Replay artifacts must never be written through the live app SupabaseService surface.',
      ],
      metadata: <String, dynamic>{
        'legacyEnvironmentId': environmentId,
        'simulationEnvironmentId':
            '$citySlug-simulation-environment-$replayYear',
        'simulationEnvironmentNamespace':
            'simulation-world/$citySlug/$replayYear',
        'simulationLabel':
            '$cityDisplayName Simulation Environment $replayYear',
        'citySlug': citySlug,
        'cityDisplayName': cityDisplayName,
        if (artifactMetadata['cityCode'] != null)
          'cityCode': artifactMetadata['cityCode'],
        if (artifactMetadata['cityPackManifestRef'] != null)
          'cityPackManifestRef': artifactMetadata['cityPackManifestRef'],
        if (artifactMetadata['cityPackId'] != null)
          'cityPackId': artifactMetadata['cityPackId'],
        if (artifactMetadata['cityPackStructuralRef'] != null)
          'cityPackStructuralRef': artifactMetadata['cityPackStructuralRef'],
        if (artifactMetadata['campaignDefaultsRef'] != null)
          'campaignDefaultsRef': artifactMetadata['campaignDefaultsRef'],
        if (artifactMetadata['localityExpectationProfileRef'] != null)
          'localityExpectationProfileRef':
              artifactMetadata['localityExpectationProfileRef'],
        if (artifactMetadata['worldHealthProfileRef'] != null)
          'worldHealthProfileRef': artifactMetadata['worldHealthProfileRef'],
        'replayBucketCount': replayBucketSet.length,
        'replayMetadataTableCount': replayMetadataTables.length,
        'overlappingBucketCount': overlappingBuckets.length,
      },
    );
  }

  String _citySlugFromEnvironmentId(String environmentId) {
    final trimmed = environmentId.trim();
    final replaySuffix = RegExp(r'-replay-world-\d+$');
    if (replaySuffix.hasMatch(trimmed)) {
      return trimmed.replaceFirst(replaySuffix, '');
    }
    final simulationSuffix = RegExp(r'-simulation-environment-\d+$');
    if (simulationSuffix.hasMatch(trimmed)) {
      return trimmed.replaceFirst(simulationSuffix, '');
    }
    return trimmed
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-')
        .toLowerCase()
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  String _cityDisplayNameFromSlug(String citySlug) {
    final parts = citySlug
        .split(RegExp(r'[-_]+'))
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'Simulation';
    }
    return parts
        .map(
          (part) => part.length == 1
              ? part.toUpperCase()
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}
