import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_runtime_os/services/admin/admin_runtime_governance_service.dart';
import 'package:avrai_runtime_os/services/background/background_execution_models.dart';
import 'package:avrai_runtime_os/services/passive_collection/passive_dwell_reality_learning_service.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_runner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MeshTrustDiagnosticsPanel extends StatelessWidget {
  const MeshTrustDiagnosticsPanel({
    super.key,
    required this.meshSnapshot,
    required this.rendezvousSnapshot,
    required this.ambientSocialSnapshot,
    this.onRunFieldAcceptanceValidation,
    this.onRunControlledValidation,
    this.onRunControlledMultiHopValidation,
    this.onRunAi2AiPeerTruthValidation,
    this.onRunAmbientSocialValidation,
    this.onExportRecentProofBundles,
  });

  final MeshTrustDiagnosticsSnapshot meshSnapshot;
  final Ai2AiRendezvousDiagnosticsSnapshot rendezvousSnapshot;
  final AmbientSocialLearningDiagnosticsSnapshot ambientSocialSnapshot;
  final Future<List<DomainExecutionFieldScenarioProof>> Function()?
      onRunFieldAcceptanceValidation;
  final Future<List<DomainExecutionFieldScenarioProof>> Function()?
      onRunControlledValidation;
  final Future<List<DomainExecutionFieldScenarioProof>> Function()?
      onRunControlledMultiHopValidation;
  final Future<List<DomainExecutionFieldScenarioProof>> Function()?
      onRunAi2AiPeerTruthValidation;
  final Future<List<DomainExecutionFieldScenarioProof>> Function()?
      onRunAmbientSocialValidation;
  final Future<String> Function()? onExportRecentProofBundles;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trust And Segment Diagnostics',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Trusted announce, replay, rendezvous, and segment lifecycle visibility for controlled private-mesh validation.',
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _TrustMetricChip(
                      label: 'Trusted announces',
                      value: meshSnapshot.trustedActiveAnnounceCount.toString(),
                      color: AppColors.success,
                    ),
                    _TrustMetricChip(
                      label: 'Rejected announces',
                      value: meshSnapshot.rejectedAnnounceCount.toString(),
                      color: meshSnapshot.rejectedAnnounceCount > 0
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                    _TrustMetricChip(
                      label: 'Trusted replay triggers',
                      value: meshSnapshot.trustedReplayTriggerCount.toString(),
                      color: AppColors.selection,
                    ),
                    _TrustMetricChip(
                      label: 'Peer received',
                      value: rendezvousSnapshot.peerReceivedCount.toString(),
                      color: AppColors.selection,
                    ),
                    _TrustMetricChip(
                      label: 'Peer validated',
                      value: rendezvousSnapshot.peerValidatedCount.toString(),
                      color: AppColors.selection,
                    ),
                    _TrustMetricChip(
                      label: 'Peer consumed',
                      value: rendezvousSnapshot.peerConsumedCount.toString(),
                      color: AppColors.selection,
                    ),
                    _TrustMetricChip(
                      label: 'Peer applied',
                      value: rendezvousSnapshot.peerAppliedCount.toString(),
                      color: AppColors.success,
                    ),
                    _TrustMetricChip(
                      label: 'Active credentials',
                      value: meshSnapshot.activeCredentialCount.toString(),
                      color: AppColors.selection,
                    ),
                    _TrustMetricChip(
                      label: 'Expiring soon',
                      value:
                          meshSnapshot.expiringSoonCredentialCount.toString(),
                      color: meshSnapshot.expiringSoonCredentialCount > 0
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                    _TrustMetricChip(
                      label: 'Revoked credentials',
                      value: meshSnapshot.revokedCredentialCount.toString(),
                      color: meshSnapshot.revokedCredentialCount > 0
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                    _TrustMetricChip(
                      label: 'Active rendezvous',
                      value:
                          rendezvousSnapshot.activeRendezvousCount.toString(),
                      color: AppColors.selection,
                    ),
                    _TrustMetricChip(
                      label: 'Trusted-route blocks',
                      value: rendezvousSnapshot
                          .trustedRouteUnavailableBlockCount
                          .toString(),
                      color:
                          rendezvousSnapshot.trustedRouteUnavailableBlockCount >
                                  0
                              ? AppColors.warning
                              : AppColors.textSecondary,
                    ),
                    _TrustMetricChip(
                      label: 'Ambient observations',
                      value: ambientSocialSnapshot.normalizedObservationCount
                          .toString(),
                      color: AppColors.selection,
                    ),
                    _TrustMetricChip(
                      label: 'Candidate co-presence',
                      value: ambientSocialSnapshot
                          .candidateCoPresenceObservationCount
                          .toString(),
                      color: AppColors.selection,
                    ),
                    _TrustMetricChip(
                      label: 'Confirmed interactions',
                      value: ambientSocialSnapshot
                          .confirmedInteractionPromotionCount
                          .toString(),
                      color: AppColors.success,
                    ),
                    _TrustMetricChip(
                      label: 'Crowd upgrades',
                      value:
                          ambientSocialSnapshot.crowdUpgradeCount.toString(),
                      color: ambientSocialSnapshot.crowdUpgradeCount > 0
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                    _TrustMetricChip(
                      label: 'Duplicate merges',
                      value:
                          ambientSocialSnapshot.duplicateMergeCount.toString(),
                      color: ambientSocialSnapshot.duplicateMergeCount > 0
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                    _TrustMetricChip(
                      label: 'Rejected promotions',
                      value: ambientSocialSnapshot
                          .rejectedInteractionPromotionCount
                          .toString(),
                      color: ambientSocialSnapshot
                                  .rejectedInteractionPromotionCount >
                              0
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                    _TrustMetricChip(
                      label: 'What ingestions',
                      value:
                          ambientSocialSnapshot.whatIngestionCount.toString(),
                      color: AppColors.selection,
                    ),
                    _TrustMetricChip(
                      label: 'Place-vibe updates',
                      value: ambientSocialSnapshot.localityVibeUpdateCount
                          .toString(),
                      color: AppColors.selection,
                    ),
                    _TrustMetricChip(
                      label: 'DNA feedback',
                      value:
                          ambientSocialSnapshot.personalDnaAppliedCount.toString(),
                      color: ambientSocialSnapshot.personalDnaAppliedCount > 0
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Ambient social learning',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (ambientSocialSnapshot.latestLocalityStableKey != null)
                      ambientSocialSnapshot.latestLocalityStableKey!,
                    if (ambientSocialSnapshot.latestPlaceVibeLabel != null)
                      ambientSocialSnapshot.latestPlaceVibeLabel!,
                    if (ambientSocialSnapshot.latestSocialContext != null)
                      ambientSocialSnapshot.latestSocialContext!,
                    'nearby ${ambientSocialSnapshot.latestNearbyPeerCount}',
                    'confirmed ${ambientSocialSnapshot.latestConfirmedInteractivePeerCount}',
                  ].join(' | '),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: onRunFieldAcceptanceValidation == null
                          ? null
                          : () => _runFieldAcceptanceValidation(context),
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('Run Field Acceptance'),
                    ),
                    FilledButton.icon(
                      onPressed: onRunControlledValidation == null
                          ? null
                          : () => _runControlledValidation(context),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Run Private-Mesh Validation'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: onRunControlledMultiHopValidation == null
                          ? null
                          : () => _runControlledMultiHopValidation(context),
                      icon: const Icon(Icons.alt_route),
                      label: const Text('Run Multi-Hop Validation'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: onRunAi2AiPeerTruthValidation == null
                          ? null
                          : () => _runAi2AiPeerTruthValidation(context),
                      icon: const Icon(Icons.hub_outlined),
                      label: const Text('Run AI2AI Peer Truth'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: onRunAmbientSocialValidation == null
                          ? null
                          : () => _runAmbientSocialValidation(context),
                      icon: const Icon(Icons.groups_outlined),
                      label: const Text('Run Ambient Social'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onExportRecentProofBundles == null
                          ? null
                          : () => _exportRecentProofBundles(context),
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Export Proof Bundles'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Rejection reasons',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (meshSnapshot.rejectionReasonCounts.isEmpty)
                  const Text(
                    'No rejected announces recorded.',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: meshSnapshot.rejectionReasonCounts.entries
                        .map(
                          (entry) => Chip(
                            label: Text('${entry.key}: ${entry.value}'),
                            backgroundColor:
                                AppColors.warning.withValues(alpha: 0.12),
                          ),
                        )
                        .toList(growable: false),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Announce source breakdown',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (meshSnapshot.activeAnnounceSourceCounts.isEmpty &&
                    meshSnapshot.rejectedAnnounceSourceCounts.isEmpty)
                  const Text(
                    'No announce source breakdown recorded yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...meshSnapshot.activeAnnounceSourceCounts.entries.map(
                        (entry) => Chip(
                          label: Text('active ${entry.key}: ${entry.value}'),
                          backgroundColor:
                              AppColors.success.withValues(alpha: 0.1),
                        ),
                      ),
                      ...meshSnapshot.rejectedAnnounceSourceCounts.entries.map(
                        (entry) => Chip(
                          label: Text('rejected ${entry.key}: ${entry.value}'),
                          backgroundColor:
                              AppColors.warning.withValues(alpha: 0.12),
                        ),
                      ),
                      ...meshSnapshot.trustedReplayTriggerSourceCounts.entries
                          .map(
                        (entry) => Chip(
                          label: Text(
                              'trusted replay ${entry.key}: ${entry.value}'),
                          backgroundColor:
                              AppColors.selection.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Text(
                  'Recent proof bundles',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (meshSnapshot.recentProofs.isEmpty &&
                    rendezvousSnapshot.recentProofs.isEmpty)
                  const Text(
                    'No controlled trust proofs recorded yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                else
                  Column(
                    children: _recentProofs().map((proof) {
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          proof.passed ? Icons.verified : Icons.error_outline,
                          color: proof.passed
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        title: Text(proof.scenario.name),
                        subtitle: Text(proof.summary),
                      );
                    }).toList(growable: false),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Recent headless wake runs',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (_recentHeadlessRuns().isEmpty)
                  const Text(
                    'No headless wake executions recorded yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                else
                  Column(
                    children: _recentHeadlessRuns().map((run) {
                      final summaryParts = <String>[
                        run.platformSource,
                        'mesh ${run.meshDueReplayCount + run.meshRecoveredReplayCount}',
                        'ai2ai ${run.ai2aiReleasedCount}',
                        'passive ${run.passiveIngestedDwellEventCount}',
                        'ambient c${run.ambientCandidateObservationDeltaCount}',
                        'ambient p${run.ambientConfirmedPromotionDeltaCount}',
                      ];
                      if (run.failureSummary != null &&
                          run.failureSummary!.isNotEmpty) {
                        summaryParts.add('failed');
                      }
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(run.reason.wireName),
                        subtitle: Text(summaryParts.join(' | ')),
                        trailing: Text('${run.duration.inMilliseconds}ms'),
                      );
                    }).toList(growable: false),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Ambient promotion lineage',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (ambientSocialSnapshot.lastPromotionTrace == null)
                  const Text(
                    'No confirmed ambient-social promotion trace recorded yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          ambientSocialSnapshot
                              .lastPromotionTrace!.localityStableKey,
                          ambientSocialSnapshot.lastPromotionTrace!.placeVibeLabel,
                          ambientSocialSnapshot.lastPromotionTrace!.socialContext,
                        ].join(' | '),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...ambientSocialSnapshot
                              .lastPromotionTrace!.sourceKinds
                              .map(
                                (entry) => Chip(
                                  label: Text('source $entry'),
                                  backgroundColor:
                                      AppColors.selection.withValues(alpha: 0.12),
                                ),
                              ),
                          ...ambientSocialSnapshot
                              .lastPromotionTrace!.confirmedInteractivePeerIds
                              .map(
                                (entry) => Chip(
                                  label: Text('confirmed $entry'),
                                  backgroundColor:
                                      AppColors.success.withValues(alpha: 0.1),
                                ),
                              ),
                          ...ambientSocialSnapshot
                              .lastPromotionTrace!.lineageRefs
                              .map(
                                (entry) => Chip(
                                  label: Text(entry),
                                  backgroundColor:
                                      AppColors.warning.withValues(alpha: 0.12),
                                ),
                              ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<DomainExecutionFieldScenarioProof> _recentProofs() {
    final proofs = <String, DomainExecutionFieldScenarioProof>{};
    for (final proof in meshSnapshot.recentProofs) {
      proofs['mesh:${proof.scenario.name}'] = proof;
    }
    for (final proof in rendezvousSnapshot.recentProofs) {
      proofs['ai2ai:${proof.scenario.name}'] = proof;
    }
    final merged = proofs.values.toList(growable: false);
    merged.sort((left, right) {
      final leftAt = left.meshRuntimeStateFrame.capturedAtUtc;
      final rightAt = right.meshRuntimeStateFrame.capturedAtUtc;
      return rightAt.compareTo(leftAt);
    });
    return merged.take(4).toList(growable: false);
  }

  List<BackgroundWakeExecutionRunRecord> _recentHeadlessRuns() {
    final runs = <String, BackgroundWakeExecutionRunRecord>{};
    for (final run in meshSnapshot.recentHeadlessRuns) {
      final key =
          'mesh:${run.platformSource}:${run.startedAtUtc.toIso8601String()}:${run.reason.wireName}';
      runs[key] = run;
    }
    for (final run in rendezvousSnapshot.recentHeadlessRuns) {
      final key =
          'ai2ai:${run.platformSource}:${run.startedAtUtc.toIso8601String()}:${run.reason.wireName}';
      runs[key] = run;
    }
    final merged = runs.values.toList(growable: false);
    merged
        .sort((left, right) => right.startedAtUtc.compareTo(left.startedAtUtc));
    return merged.take(6).toList(growable: false);
  }

  Future<void> _runControlledValidation(BuildContext context) async {
    final callback = onRunControlledValidation;
    if (callback == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      final proofs = await callback();
      final passedCount = proofs.where((entry) => entry.passed).length;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Controlled validation completed: $passedCount/${proofs.length} passed.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Controlled validation failed: $error')),
      );
    }
  }

  Future<void> _runFieldAcceptanceValidation(BuildContext context) async {
    final callback = onRunFieldAcceptanceValidation;
    if (callback == null) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    final proofs = await callback();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          'Field acceptance completed: ${proofs.where((entry) => entry.passed).length}/${proofs.length} passed.',
        ),
      ),
    );
  }

  Future<void> _runControlledMultiHopValidation(BuildContext context) async {
    final callback = onRunControlledMultiHopValidation;
    if (callback == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      final proofs = await callback();
      final passedCount = proofs.where((entry) => entry.passed).length;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Multi-hop validation completed: $passedCount/${proofs.length} passed.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Multi-hop validation failed: $error'),
        ),
      );
    }
  }

  Future<void> _runAi2AiPeerTruthValidation(BuildContext context) async {
    final callback = onRunAi2AiPeerTruthValidation;
    if (callback == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      final proofs = await callback();
      final passedCount = proofs.where((entry) => entry.passed).length;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'AI2AI peer-truth validation completed: $passedCount/${proofs.length} passed.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('AI2AI peer-truth validation failed: $error'),
        ),
      );
    }
  }

  Future<void> _runAmbientSocialValidation(BuildContext context) async {
    final callback = onRunAmbientSocialValidation;
    if (callback == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      final proofs = await callback();
      final passedCount = proofs.where((entry) => entry.passed).length;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Ambient-social validation completed: $passedCount/${proofs.length} passed.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Ambient-social validation failed: $error'),
        ),
      );
    }
  }

  Future<void> _exportRecentProofBundles(BuildContext context) async {
    final callback = onExportRecentProofBundles;
    if (callback == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      final payload = await callback();
      await Clipboard.setData(ClipboardData(text: payload));
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Recent proof bundles copied to clipboard.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Proof export failed: $error')),
      );
    }
  }
}

class _TrustMetricChip extends StatelessWidget {
  const _TrustMetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
