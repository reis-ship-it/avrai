import 'dart:async';

import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_admin_diagnostics_bridge.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
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

  LocalityNativeAdminDiagnosticsBridge? _diagnostics;
  bool _isLoading = true;
  String? _error;
  _LocalityDiagnosticsSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    _diagnostics =
        GetIt.instance.isRegistered<LocalityNativeAdminDiagnosticsBridge>()
            ? GetIt.instance<LocalityNativeAdminDiagnosticsBridge>()
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
    final diagnostics = _diagnostics;
    if (diagnostics == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Locality native diagnostics bridge is not registered.';
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
      final occurredAtUtc = DateTime.now().toUtc();
      final report = await diagnostics.diagnose(
        probes: _buildProbes(widget.activeAgents)
            .map(
              (probe) => LocalityAdminDiagnosticsProbe(
                latitude: probe.latitude,
                longitude: probe.longitude,
                occurredAtUtc: occurredAtUtc,
              ),
            )
            .toList(),
        cityProfile: null,
        modelFamily: 'reality_kernel',
      );
      if (report.sampleResolution == null) {
        throw StateError('Locality diagnostics returned no sample resolution.');
      }

      if (!mounted) return;
      setState(() {
        _snapshot = _LocalityDiagnosticsSnapshot(
          report: report,
          lastUpdatedUtc: occurredAtUtc,
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
                    snapshot.resolutionCount.toString(),
                  ),
                  _buildSummaryChip('Execution', snapshot.executionPath),
                  _buildSummaryChip(
                    'Native',
                    snapshot.nativeAvailable ? 'available' : 'unavailable',
                  ),
                  _buildSummaryChip(
                    'Policy',
                    snapshot.nativeRequired ? 'required' : 'allow-fallback',
                  ),
                  _buildSummaryChip(
                    'Dominant',
                    snapshot.topLocalities.isEmpty
                        ? snapshot.sampleResolution.projection.primaryLabel
                        : snapshot.topLocalities.first.label,
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
                  _buildSummaryChip(
                    'Fallbacks',
                    snapshot.totalFallbackCount.toString(),
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
    final sourceMix = (metadata['sourceMixSummary'] as String?) ??
        _sourceMixSummary(metadata['sourceMix'] as Map<String, dynamic>?);
    final stabilityClass = (metadata['stabilityClass'] as String?) ?? 'watch';
    final nextStateRisk = (metadata['nextStateRisk'] as String?) ?? 'medium';

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
              _buildSummaryChip('Stability', stabilityClass),
              _buildSummaryChip('Risk', nextStateRisk),
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
          const SizedBox(height: 6),
          Text(
            'Kernel path: ${snapshot.executionPath}  |  native calls: ${snapshot.nativeHandledCount}  |  fallbacks: ${snapshot.totalFallbackCount}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
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
                      entry.label,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    '${entry.count} points',
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
  final LocalityAdminDiagnosticsReport report;
  final DateTime lastUpdatedUtc;

  const _LocalityDiagnosticsSnapshot({
    required this.report,
    required this.lastUpdatedUtc,
  });

  int get resolutionCount => report.resolutionCount;

  List<LocalityAdminTopLocality> get topLocalities => report.topLocalities;

  int get nearBoundaryCount => report.nearBoundaryCount;

  int get highConfidenceCount => report.highConfidenceCount;

  int get advisoryActiveCount => report.advisoryActiveCount;

  int get predictiveChangeCount => report.predictiveChangeCount;

  String get executionPath => report.executionPath;

  bool get nativeAvailable => report.nativeAvailable;

  bool get nativeRequired => report.nativeRequired;

  int get nativeHandledCount => report.nativeHandledCount;

  int get fallbackUnavailableCount => report.fallbackUnavailableCount;

  int get fallbackDeferredCount => report.fallbackDeferredCount;

  int get totalFallbackCount => report.totalFallbackCount;

  LocalityPointResolution get sampleResolution => report.sampleResolution!;

  LocalityZeroReliabilityReport get zeroLocalityReport =>
      report.zeroLocalityReport;

  String get cityProfile => report.cityProfile;
}

class _LocalityProbe {
  final double latitude;
  final double longitude;

  const _LocalityProbe({
    required this.latitude,
    required this.longitude,
  });
}
