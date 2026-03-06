import 'dart:async';
import 'dart:math' as math;

import 'package:avrai/theme/colors.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_syscall_contract.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_training_contract.dart';
import 'package:avrai_runtime_os/services/admin/admin_runtime_governance_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class LocalityKernelDiagnosticsCard extends StatefulWidget {
  const LocalityKernelDiagnosticsCard({
    super.key,
    required this.activeAgents,
  });

  final List<ActiveAIAgentData> activeAgents;

  @override
  State<LocalityKernelDiagnosticsCard> createState() =>
      _LocalityKernelDiagnosticsCardState();
}

class _LocalityKernelDiagnosticsCardState
    extends State<LocalityKernelDiagnosticsCard> {
  static const double _fallbackBirminghamLat = 33.5186;
  static const double _fallbackBirminghamLon = -86.8104;
  static const int _maxAgentsToInspect = 24;

  LocalityKernelContract? _kernel;
  bool _isLoading = true;
  String? _error;
  _LocalityDiagnosticsSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    _kernel = GetIt.instance.isRegistered<LocalityKernelContract>()
        ? GetIt.instance<LocalityKernelContract>()
        : null;
    unawaited(_loadDiagnostics());
  }

  @override
  void didUpdateWidget(LocalityKernelDiagnosticsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.activeAgents, widget.activeAgents)) {
      unawaited(_loadDiagnostics());
    }
  }

  Future<void> _loadDiagnostics() async {
    final kernel = _kernel;
    if (kernel == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Locality kernel contract is not registered.';
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final probes = _buildProbes(widget.activeAgents);
      final resolutions = await Future.wait(
        probes.map(
          (probe) => kernel.resolvePoint(
            LocalityPointQuery(
              latitude: probe.latitude,
              longitude: probe.longitude,
              occurredAtUtc: DateTime.now().toUtc(),
              audience: LocalityProjectionAudience.admin,
              includeGeometry: true,
              includeAttribution: true,
              includePrediction: true,
            ),
          ),
        ),
      );

      final dominantLabels = <String, int>{};
      int nearBoundaryCount = 0;
      int highConfidenceCount = 0;
      int advisoryActiveCount = 0;
      int predictiveChangeCount = 0;

      for (final resolution in resolutions) {
        dominantLabels.update(
          resolution.projection.primaryLabel,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        if (resolution.projection.nearBoundary) {
          nearBoundaryCount += 1;
        }
        if (resolution.projection.confidenceBucket == 'high') {
          highConfidenceCount += 1;
        }

        final metadata = resolution.projection.metadata;
        if (metadata['advisoryStatus'] == 'active') {
          advisoryActiveCount += 1;
        }
        if (metadata['predictiveTrend'] == 'changing') {
          predictiveChangeCount += 1;
        }
      }

      final topLocalities = dominantLabels.entries.toList()
        ..sort((left, right) => right.value.compareTo(left.value));
      final sampleResolution =
          resolutions.reduce(_preferHigherSignalResolution);
      final cityProfile = _normalizeCityProfile(
        sampleResolution.cityCode ??
            sampleResolution.displayName ??
            sampleResolution.projection.primaryLabel,
      );
      final zeroLocalityReport = await kernel.evaluateZeroLocalityReadiness(
        cityProfile: cityProfile,
        modelFamily: 'reality_kernel',
        localityCount: math.max(
          12,
          math.max(resolutions.length, topLocalities.length * 3),
        ),
      );

      if (!mounted) return;
      setState(() {
        _snapshot = _LocalityDiagnosticsSnapshot(
          resolutions: resolutions,
          topLocalities: topLocalities,
          nearBoundaryCount: nearBoundaryCount,
          highConfidenceCount: highConfidenceCount,
          advisoryActiveCount: advisoryActiveCount,
          predictiveChangeCount: predictiveChangeCount,
          sampleResolution: sampleResolution,
          zeroLocalityReport: zeroLocalityReport,
          cityProfile: cityProfile,
          lastUpdatedUtc: DateTime.now().toUtc(),
        );
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load locality kernel diagnostics: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_searching_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Locality Kernel Diagnostics',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hard-token runtime locality state, predictive trend, and zero-locality reliability from the live kernel.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _loadDiagnostics,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh locality diagnostics',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _buildErrorState(context, _error!)
            else if (snapshot != null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSummaryChip(
                    'Points',
                    snapshot.resolutions.length.toString(),
                  ),
                  _buildSummaryChip(
                    'Dominant',
                    snapshot.topLocalities.isEmpty
                        ? snapshot.sampleResolution.projection.primaryLabel
                        : snapshot.topLocalities.first.key,
                  ),
                  _buildSummaryChip(
                    'Boundary watch',
                    snapshot.nearBoundaryCount.toString(),
                  ),
                  _buildSummaryChip(
                    'High confidence',
                    snapshot.highConfidenceCount.toString(),
                  ),
                  _buildSummaryChip(
                    'Advisory active',
                    snapshot.advisoryActiveCount.toString(),
                  ),
                  _buildSummaryChip(
                    'Changing',
                    snapshot.predictiveChangeCount.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSampleResolution(context, snapshot),
              const SizedBox(height: 16),
              _buildDominantLocalities(context, snapshot),
              const SizedBox(height: 16),
              _buildZeroLocalityReadiness(context, snapshot),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Updated ${_formatTimestamp(snapshot.lastUpdatedUtc)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        error,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.error,
            ),
      ),
    );
  }

  Widget _buildSampleResolution(
    BuildContext context,
    _LocalityDiagnosticsSnapshot snapshot,
  ) {
    final resolution = snapshot.sampleResolution;
    final metadata = resolution.projection.metadata;
    final reliabilityTier =
        (metadata['reliabilityTier'] as String?) ?? 'zeroLocality';
    final advisoryStatus =
        (metadata['advisoryStatus'] as String?) ?? 'inactive';
    final predictiveTrend =
        (metadata['predictiveTrend'] as String?) ?? 'stable';
    final sourceMix = _sourceMixSummary(
      metadata['sourceMix'] as Map<String, dynamic>?,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Representative locality state',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            resolution.projection.primaryLabel,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSummaryChip('Token', resolution.state.activeToken.id),
              _buildSummaryChip(
                'Confidence',
                resolution.projection.confidenceBucket,
              ),
              _buildSummaryChip('Tier', reliabilityTier),
              _buildSummaryChip('Advisory', advisoryStatus),
              _buildSummaryChip('Trend', predictiveTrend),
              _buildSummaryChip(
                'Boundary',
                resolution.projection.nearBoundary ? 'edge' : 'stable',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'City code: ${resolution.cityCode ?? 'unresolved'}  |  Locality code: ${resolution.localityCode ?? 'unresolved'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Evidence mix: $sourceMix',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildDominantLocalities(
    BuildContext context,
    _LocalityDiagnosticsSnapshot snapshot,
  ) {
    final localities = snapshot.topLocalities.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dominant localities across inspected points',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        if (localities.isEmpty)
          Text(
            'No locality labels resolved.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          )
        else
          ...localities.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    '${entry.value} points',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildZeroLocalityReadiness(
    BuildContext context,
    _LocalityDiagnosticsSnapshot snapshot,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zero-locality readiness',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Simulation profile: ${snapshot.cityProfile}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        ...snapshot.zeroLocalityReport.metrics.map(
          (metric) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        metric.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${(metric.value * 100).toStringAsFixed(0)} / ${(metric.target * 100).toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: metric.passes
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: metric.value.clamp(0.0, 1.0),
                  color: metric.passes ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Chip _buildSummaryChip(String label, String value) {
    return Chip(label: Text('$label: $value'));
  }

  List<_LocalityProbe> _buildProbes(List<ActiveAIAgentData> agents) {
    if (agents.isEmpty) {
      return const <_LocalityProbe>[
        _LocalityProbe(
          latitude: _fallbackBirminghamLat,
          longitude: _fallbackBirminghamLon,
        ),
      ];
    }

    final sortedAgents = agents.toList()
      ..sort((left, right) => right.confidence.compareTo(left.confidence));

    return sortedAgents
        .take(_maxAgentsToInspect)
        .map(
          (agent) => _LocalityProbe(
            latitude: agent.latitude,
            longitude: agent.longitude,
          ),
        )
        .toList(growable: false);
  }

  LocalityPointResolution _preferHigherSignalResolution(
    LocalityPointResolution left,
    LocalityPointResolution right,
  ) {
    final confidenceDelta = right.state.confidence - left.state.confidence;
    if (confidenceDelta.abs() > 0.0001) {
      return confidenceDelta > 0 ? right : left;
    }
    final evidenceDelta = right.state.evidenceCount - left.state.evidenceCount;
    return evidenceDelta > 0 ? right : left;
  }

  String _normalizeCityProfile(String rawValue) {
    final normalized = rawValue
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'birmingham_alabama' : normalized;
  }

  String _sourceMixSummary(Map<String, dynamic>? sourceMix) {
    if (sourceMix == null || sourceMix.isEmpty) {
      return 'synthetic bootstrap only';
    }

    final sortedEntries = sourceMix.entries
        .map(
          (entry) => MapEntry(
            entry.key,
            (entry.value as num?)?.toDouble() ?? 0.0,
          ),
        )
        .where((entry) => entry.value > 0.0)
        .toList()
      ..sort((left, right) => right.value.compareTo(left.value));

    if (sortedEntries.isEmpty) {
      return 'synthetic bootstrap only';
    }

    return sortedEntries
        .take(2)
        .map(
          (entry) => '${entry.key}:${(entry.value * 100).toStringAsFixed(0)}%',
        )
        .join('  ');
  }

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final hour = local.hour == 0
        ? 12
        : local.hour > 12
            ? local.hour - 12
            : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _LocalityDiagnosticsSnapshot {
  final List<LocalityPointResolution> resolutions;
  final List<MapEntry<String, int>> topLocalities;
  final int nearBoundaryCount;
  final int highConfidenceCount;
  final int advisoryActiveCount;
  final int predictiveChangeCount;
  final LocalityPointResolution sampleResolution;
  final LocalityZeroReliabilityReport zeroLocalityReport;
  final String cityProfile;
  final DateTime lastUpdatedUtc;

  const _LocalityDiagnosticsSnapshot({
    required this.resolutions,
    required this.topLocalities,
    required this.nearBoundaryCount,
    required this.highConfidenceCount,
    required this.advisoryActiveCount,
    required this.predictiveChangeCount,
    required this.sampleResolution,
    required this.zeroLocalityReport,
    required this.cityProfile,
    required this.lastUpdatedUtc,
  });
}

class _LocalityProbe {
  final double latitude;
  final double longitude;

  const _LocalityProbe({
    required this.latitude,
    required this.longitude,
  });
}
