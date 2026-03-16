import 'dart:async';

import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_runtime_os/services/admin/replay_simulation_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/planning_truth_surface_admin_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class PlanningTruthSurfaceCard extends StatefulWidget {
  const PlanningTruthSurfaceCard({super.key});

  @override
  State<PlanningTruthSurfaceCard> createState() =>
      _PlanningTruthSurfaceCardState();
}

class _PlanningTruthSurfaceCardState extends State<PlanningTruthSurfaceCard> {
  PlanningTruthSurfaceAdminService? _service;
  ReplaySimulationAdminService? _replayService;
  StreamSubscription<PlanningTruthSurfaceAdminSnapshot>? _subscription;
  bool _isLoading = true;
  String? _error;
  PlanningTruthSurfaceAdminSnapshot? _snapshot;
  ReplaySimulationAdminSnapshot? _replaySnapshot;

  @override
  void initState() {
    super.initState();
    _service = GetIt.instance.isRegistered<PlanningTruthSurfaceAdminService>()
        ? GetIt.instance<PlanningTruthSurfaceAdminService>()
        : null;
    _replayService = GetIt.instance.isRegistered<ReplaySimulationAdminService>()
        ? GetIt.instance<ReplaySimulationAdminService>()
        : null;
    _startWatching();
    _loadReplaySnapshot();
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
    _subscription = service.watchPlanningSnapshot().listen(
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
          _error = 'Failed to load planning truth surface diagnostics: $error';
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
      final snapshot = await service.getPlanningSnapshot();
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
        _error = 'Failed to load planning truth surface diagnostics: $error';
      });
    }
  }

  Future<void> _loadReplaySnapshot() async {
    final service = _replayService;
    if (service == null) {
      return;
    }
    try {
      final snapshot = await service.getSnapshot();
      if (!mounted) {
        return;
      }
      setState(() {
        _replaySnapshot = snapshot;
      });
    } catch (_) {}
  }

  void _showUnavailableState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _error = 'Planning truth surface diagnostics are not registered.';
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
    final replaySnapshot = _replaySnapshot;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Planning Truth Surface',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Air-gapped planning evidence, scoped learning signals, and recent host debrief outcomes.',
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
                  tooltip: 'Refresh planning truth diagnostics',
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
                  _buildSummaryChip('Signals', snapshot.signalCount.toString()),
                  _buildSummaryChip(
                    'Created',
                    snapshot.createdSignalCount.toString(),
                  ),
                  _buildSummaryChip(
                    'Completed',
                    snapshot.completedSignalCount.toString(),
                  ),
                  _buildSummaryChip(
                    'Locality',
                    snapshot.localityScopedCount.toString(),
                  ),
                  _buildSummaryChip(
                    'Avg attendance',
                    _formatPercent(snapshot.averageAttendanceRate),
                  ),
                  _buildSummaryChip(
                    'Avg rating',
                    snapshot.averageAverageRating.toStringAsFixed(1),
                  ),
                  if (replaySnapshot != null)
                    _buildSummaryChip(
                      'Receipts',
                      replaySnapshot.receipts.length.toString(),
                    ),
                  if (replaySnapshot != null)
                    _buildSummaryChip(
                      'Overlays',
                      replaySnapshot.localityOverlays.length.toString(),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCountsSection(
                context,
                title: 'Strata',
                counts: snapshot.stratumCounts,
              ),
              const SizedBox(height: 16),
              _buildCountsSection(
                context,
                title: 'Evidence Classes',
                counts: snapshot.evidenceClassCounts,
              ),
              const SizedBox(height: 16),
              _buildCountsSection(
                context,
                title: 'Privacy Ladder',
                counts: snapshot.privacyCounts,
              ),
              const SizedBox(height: 16),
              _buildRecentSignals(context, snapshot),
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

  Widget _buildRecentSignals(
    BuildContext context,
    PlanningTruthSurfaceAdminSnapshot snapshot,
  ) {
    if (snapshot.recentSignals.isEmpty) {
      return _buildSectionCard(
        context,
        title: 'Recent Planning Signals',
        child: const Text('No planning truth-surface signals in the window.'),
      );
    }
    final rows = snapshot.recentSignals.take(8).toList(growable: false);
    return _buildSectionCard(
      context,
      title: 'Recent Planning Signals',
      child: Column(
        children: [
          for (final row in rows)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${row.kind.name} • ${row.eventId}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${row.evidenceEnvelope.evidenceClass} • ${row.evidenceEnvelope.privacyLadderTag}',
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildScopeChip(row.truthScope.governanceStratum.name),
                      _buildScopeChip(row.truthScope.sphereId),
                      _buildScopeChip(row.truthScope.familyId),
                      _buildScopeChip(row.hostGoal),
                      if (row.candidateLocalityCode != null &&
                          row.candidateLocalityCode!.isNotEmpty)
                        _buildScopeChip(row.candidateLocalityCode!),
                    ],
                  ),
                ],
              ),
              trailing: Text('${row.tupleRefCount} refs'),
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

  void _showDetails(BuildContext context, PlanningTruthSurfaceAdminRow row) {
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
                row.eventId,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildScopeChip(row.truthScope.governanceStratum.name),
                  _buildScopeChip(row.truthScope.truthSurfaceKind.name),
                  _buildScopeChip(row.truthScope.sphereId),
                  _buildScopeChip(row.truthScope.familyId),
                  _buildScopeChip(row.truthScope.agentClass.name),
                ],
              ),
              const SizedBox(height: 8),
              Text('Signal: ${row.signalId}'),
              Text('Kind: ${row.kind.name}'),
              Text('Scope key: ${row.truthScope.scopeKey}'),
              Text('Trace: ${row.evidenceEnvelope.traceId}'),
              Text('Evidence class: ${row.evidenceEnvelope.evidenceClass}'),
              Text('Privacy: ${row.evidenceEnvelope.privacyLadderTag}'),
              Text('Source kind: ${row.sourceKind}'),
              Text('Confidence: ${row.confidence}'),
              Text('Tuple refs: ${row.tupleRefCount}'),
              Text('Host goal: ${row.hostGoal}'),
              if (row.candidateLocalityCode != null)
                Text('Locality: ${row.candidateLocalityCode}'),
              Text('Accepted suggestion: ${row.acceptedSuggestion}'),
              if (row.predictedFillBand != null)
                Text('Predicted fill: ${row.predictedFillBand}'),
              if (row.attendanceRate != null)
                Text('Attendance: ${_formatPercent(row.attendanceRate!)}'),
              if (row.averageRating != null)
                Text(
                    'Average rating: ${row.averageRating!.toStringAsFixed(1)}'),
              if (row.wouldAttendAgainRate != null)
                Text(
                  'Would attend again: ${_formatPercent(row.wouldAttendAgainRate!)}',
                ),
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
