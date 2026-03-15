import 'dart:async';

import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_runtime_os/services/admin/forecast_kernel_admin_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_strength_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class ForecastKernelStrengthCard extends StatefulWidget {
  const ForecastKernelStrengthCard({super.key});

  @override
  State<ForecastKernelStrengthCard> createState() =>
      _ForecastKernelStrengthCardState();
}

class _ForecastKernelStrengthCardState
    extends State<ForecastKernelStrengthCard> {
  ForecastKernelAdminService? _service;
  StreamSubscription<ForecastKernelAdminSnapshot>? _subscription;
  bool _isLoading = true;
  String? _error;
  ForecastKernelAdminSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    _service = GetIt.instance.isRegistered<ForecastKernelAdminService>()
        ? GetIt.instance<ForecastKernelAdminService>()
        : null;
    _startWatching();
  }

  void _startWatching() {
    final service = _service;
    if (service == null) {
      _showUnavailableState();
      return;
    }
    _subscription?.cancel();
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    _subscription = service.watchForecastSnapshot().listen(
      (snapshot) {
        if (!mounted) {
          return;
        }
        setState(() {
          _snapshot = snapshot;
          _isLoading = false;
          _error = null;
        });
      },
      onError: (Object error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
          _error = 'Failed to load forecast kernel diagnostics: $error';
        });
      },
    );
  }

  Future<void> _loadSnapshot() async {
    final service = _service;
    if (service == null) {
      _showUnavailableState();
      return;
    }
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final snapshot = await service.getForecastSnapshot();
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = 'Failed to load forecast kernel diagnostics: $error';
      });
    }
  }

  void _showUnavailableState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _error = 'Forecast kernel diagnostics are not registered.';
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
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
                const Icon(Icons.query_stats_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Forecast Strength Kernel',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Calibrated forecast strength, actionability, change-risk, and recent governed forecasts.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _loadSnapshot,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh forecast diagnostics',
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
                  _buildSummaryChip('Issued', snapshot.issuedCount.toString()),
                  _buildSummaryChip(
                      'Resolved', snapshot.resolvedCount.toString()),
                  _buildSummaryChip(
                    'Strength',
                    _formatPercent(snapshot.averageForecastStrength),
                  ),
                  _buildSummaryChip(
                    'Actionability',
                    _formatPercent(snapshot.averageActionability),
                  ),
                  _buildSummaryChip(
                    'Cal. gap',
                    _formatPercent(snapshot.averageCalibrationGap),
                  ),
                  _buildSummaryChip(
                    'Change risk',
                    _formatPercent(snapshot.averageChangeRisk),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTrend(context, snapshot),
              const SizedBox(height: 16),
              _buildCountsSection(
                context,
                title: 'Bands',
                counts: snapshot.bandCounts,
              ),
              const SizedBox(height: 16),
              _buildCountsSection(
                context,
                title: 'Disposition',
                counts: snapshot.dispositionCounts,
              ),
              const SizedBox(height: 16),
              _buildRecentForecasts(context, snapshot),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Updated ${_formatTimestamp(snapshot.generatedAt)}',
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

  Widget _buildSummaryChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildTrend(
    BuildContext context,
    ForecastKernelAdminSnapshot snapshot,
  ) {
    if (snapshot.strengthTrend.isEmpty) {
      return _buildSectionCard(
        context,
        title: 'Strength Trend',
        child: const Text('No recent forecast strength data available.'),
      );
    }
    return _buildSectionCard(
      context,
      title: 'Strength Trend',
      child: SizedBox(
        height: 40,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final point in snapshot.strengthTrend)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 12 + (point * 28),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountsSection(
    BuildContext context, {
    required String title,
    required Map<String, int> counts,
  }) {
    if (counts.isEmpty) {
      return _buildSectionCard(
        context,
        title: title,
        child: const Text('No data in the current window.'),
      );
    }
    return _buildSectionCard(
      context,
      title: title,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in counts.entries)
            Chip(label: Text('${entry.key}: ${entry.value}')),
        ],
      ),
    );
  }

  Widget _buildRecentForecasts(
    BuildContext context,
    ForecastKernelAdminSnapshot snapshot,
  ) {
    if (snapshot.recentForecasts.isEmpty) {
      return _buildSectionCard(
        context,
        title: 'Recent Forecasts',
        child:
            const Text('No governed forecasts issued in the current window.'),
      );
    }
    final rows = snapshot.recentForecasts.take(8).toList(growable: false);
    return _buildSectionCard(
      context,
      title: 'Recent Forecasts',
      child: Column(
        children: [
          for (final row in rows)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${row.forecastFamilyId} • ${row.predictedOutcome}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${row.subjectId} • ${row.band.label} • ${row.disposition}',
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildScopeChip(row.governanceStratum.name),
                      _buildScopeChip(row.sphereId),
                      _buildScopeChip(row.agentClass.name),
                      _buildScopeChip(row.tenantScope.name),
                      for (final entry in row.representationMix.entries)
                        _buildScopeChip('${entry.key}:${entry.value}'),
                    ],
                  ),
                ],
              ),
              trailing: Text(_formatPercent(row.forecastStrength)),
              onTap: () => _showDetails(context, row),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildScopeChip(String label) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  void _showDetails(BuildContext context, ForecastKernelAdminForecastRow row) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.forecastFamilyId,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildScopeChip(row.governanceStratum.name),
                  _buildScopeChip(row.truthScope.truthSurfaceKind.name),
                  _buildScopeChip(row.sphereId),
                  _buildScopeChip(row.agentClass.name),
                  _buildScopeChip(row.tenantScope.name),
                  if (row.tenantId != null && row.tenantId!.isNotEmpty)
                    _buildScopeChip(row.tenantId!),
                ],
              ),
              const SizedBox(height: 8),
              Text('Subject: ${row.subjectId}'),
              Text('Scope key: ${row.truthScope.scopeKey}'),
              Text('Outcome: ${row.predictedOutcome}'),
              Text('Strength: ${_formatPercent(row.forecastStrength)}'),
              Text('Actionability: ${_formatPercent(row.actionability)}'),
              Text('Support quality: ${_formatPercent(row.supportQuality)}'),
              Text('Calibration gap: ${_formatPercent(row.calibrationGap)}'),
              Text('Change risk: ${_formatPercent(row.changeRisk)}'),
              Text(
                'Skill LCB: ${row.skillLowerConfidenceBound.toStringAsFixed(3)}',
              ),
              if (row.representationMix.isNotEmpty)
                Text(
                  'Representation mix: ${row.representationMix.entries.map((entry) => '${entry.key}=${entry.value}').join(', ')}',
                ),
              Text('Disposition: ${row.disposition}'),
              Text('Band: ${row.band.label}'),
              if (row.warmingUp)
                const Text('Calibration bucket is warming up.'),
            ],
          ),
        );
      },
    );
  }

  String _formatPercent(double value) {
    return '${(value * 100).toStringAsFixed(0)}%';
  }

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final hour =
        local.hour == 0 ? 12 : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.month}/${local.day} $hour:$minute $period';
  }
}
