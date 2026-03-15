import 'package:avrai_admin_app/navigation/admin_route_paths.dart';
import 'dart:async';

import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_runtime_os/services/admin/security_immune_system_admin_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class SecurityImmuneSystemCard extends StatefulWidget {
  const SecurityImmuneSystemCard({super.key});

  @override
  State<SecurityImmuneSystemCard> createState() =>
      _SecurityImmuneSystemCardState();
}

class _SecurityImmuneSystemCardState extends State<SecurityImmuneSystemCard> {
  SecurityImmuneSystemAdminService? _service;
  StreamSubscription<SecurityImmuneSystemAdminSnapshot>? _subscription;
  bool _isLoading = true;
  String? _error;
  SecurityImmuneSystemAdminSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    _service = GetIt.instance.isRegistered<SecurityImmuneSystemAdminService>()
        ? GetIt.instance<SecurityImmuneSystemAdminService>()
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
    _subscription = service.watchSnapshot().listen(
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
          _error = 'Failed to load security immune-system diagnostics: $error';
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
      final snapshot = await service.getSnapshot();
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
        _error = 'Failed to load security immune-system diagnostics: $error';
      });
    }
  }

  void _showUnavailableState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _error = 'Security immune-system diagnostics are not registered.';
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
                const Icon(Icons.health_and_safety_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Immune System',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Governed red-team campaigns, immune memory, propagation receipts, and bounded scout oversight.',
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
                  tooltip: 'Refresh security immune-system diagnostics',
                ),
                IconButton(
                  onPressed: () =>
                      context.go(AdminRoutePaths.securityImmuneSystem),
                  icon: const Icon(Icons.open_in_new),
                  tooltip: 'Open security immune-system cockpit',
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
                      'Campaigns', snapshot.campaignCount.toString()),
                  _buildSummaryChip(
                      'Review', snapshot.pendingReviewCount.toString()),
                  _buildSummaryChip(
                      'Findings', snapshot.findingCount.toString()),
                  _buildSummaryChip('Memory', snapshot.memoryCount.toString()),
                  _buildSummaryChip(
                      'Bundles', snapshot.bundleCandidateCount.toString()),
                  _buildSummaryChip('Scouts', snapshot.scoutCount.toString()),
                  _buildSummaryChip(
                    'Autonomy gate',
                    snapshot.blockingAutonomyExpansion ? 'blocked' : 'clear',
                  ),
                  _buildSummaryChip(
                    'Release gate',
                    snapshot.releaseGate.servingAllowed ? 'allow' : 'block',
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
                title: 'Disposition',
                counts: snapshot.dispositionCounts,
              ),
              const SizedBox(height: 16),
              _buildRecentRuns(context, snapshot),
              const SizedBox(height: 16),
              _buildRecentFindings(context, snapshot),
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

  Widget _buildRecentRuns(
    BuildContext context,
    SecurityImmuneSystemAdminSnapshot snapshot,
  ) {
    return _buildSectionCard(
      context,
      title: 'Recent Campaigns',
      child: Column(
        children: [
          for (final run in snapshot.recentRuns.take(4))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${run.laneId} • ${run.name}'),
              subtitle: Text(
                '${run.disposition.name} • ${run.truthScope.governanceStratum.name} • findings ${run.findingCount}',
              ),
              trailing: Text(run.status.name),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentFindings(
    BuildContext context,
    SecurityImmuneSystemAdminSnapshot snapshot,
  ) {
    return _buildSectionCard(
      context,
      title: 'Recent Findings',
      child: Column(
        children: [
          for (final finding in snapshot.recentFindings.take(4))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(finding.title),
              subtitle: Text(
                '${finding.severity.name} • ${finding.disposition.name} • ${finding.summary}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.month}/${local.day} $hour:$minute $suffix';
  }
}
