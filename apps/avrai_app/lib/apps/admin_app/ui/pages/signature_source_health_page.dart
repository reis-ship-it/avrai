import 'dart:async';

import 'package:avrai/apps/admin_app/navigation/admin_route_paths.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_category.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class SignatureSourceHealthPage extends StatefulWidget {
  const SignatureSourceHealthPage({super.key});

  @override
  State<SignatureSourceHealthPage> createState() =>
      _SignatureSourceHealthPageState();
}

class _SignatureSourceHealthPageState extends State<SignatureSourceHealthPage> {
  SignatureHealthAdminService? _service;
  StreamSubscription<SignatureHealthSnapshot>? _subscription;
  SignatureHealthSnapshot? _snapshot;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _service = GetIt.instance<SignatureHealthAdminService>();
      _subscription = _service!.watchSnapshot().listen(
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
            _error = 'Failed to load signature health: $error';
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Signature health services are unavailable: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    final service = _service;
    if (service == null) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final snapshot = await service.getSnapshot();
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Refresh failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Signature + Source Health',
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _refresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _snapshot == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final snapshot = _snapshot;
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live signature + intake health',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This surface groups imported sources by health category so operators can spot weak confidence, stale pheromones, fallback-heavy ranking, and review queues before launch quality drifts.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _kpiChip('Strong', snapshot.overview.strongCount),
                      _kpiChip('Weak', snapshot.overview.weakDataCount),
                      _kpiChip('Stale', snapshot.overview.staleCount),
                      _kpiChip('Fallback', snapshot.overview.fallbackCount),
                      _kpiChip('Review', snapshot.overview.reviewNeededCount),
                      _kpiChip('Bundle', snapshot.overview.bundleCount),
                      _kpiChip('Review queue', snapshot.reviewQueueCount),
                      _kpiChip(
                        'Soft ignore',
                        snapshot.overview.softIgnoreCount,
                      ),
                      _kpiChip(
                        'Hard reject',
                        snapshot.overview.hardNotInterestedCount,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildFeedbackIntentSection(context, snapshot),
          const SizedBox(height: 12),
          _buildFeedbackTrendSection(context, snapshot),
          const SizedBox(height: 12),
          _buildRouteCard(
            context,
            title: 'Back to Command Center',
            subtitle: 'Return to the operator overview shell.',
            route: AdminRoutePaths.commandCenter,
          ),
          const SizedBox(height: 12),
          ...SignatureHealthCategory.values.map(
            (category) => _buildCategorySection(context, snapshot, category),
          ),
          const SizedBox(height: 12),
          _buildGroupedSection(
            context,
            title: 'Grouped by Entity Type',
            grouped: snapshot.byEntityType,
          ),
          const SizedBox(height: 12),
          _buildGroupedSection(
            context,
            title: 'Grouped by Provider',
            grouped: snapshot.byProvider,
          ),
          const SizedBox(height: 12),
          _buildGroupedSection(
            context,
            title: 'Grouped by Metro',
            grouped: snapshot.byMetro,
          ),
          const SizedBox(height: 12),
          _buildRecordsTable(snapshot.sourceRecords),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    SignatureHealthSnapshot snapshot,
    SignatureHealthCategory category,
  ) {
    final records =
        snapshot.byCategory[category] ?? const <SignatureHealthRecord>[];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              records.isEmpty
                  ? 'No sources currently grouped here.'
                  : '${records.length} sources currently grouped here.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ...records.take(6).map(
                  (record) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(record.sourceLabel ?? record.sourceId),
                    subtitle: Text(record.summary),
                    trailing: Text(
                      '${(record.confidence * 100).round()}% / ${(record.freshness * 100).round()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedSection(
    BuildContext context, {
    required String title,
    required Map<String, List<SignatureHealthRecord>> grouped,
  }) {
    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entries
                  .map(
                    (entry) => Chip(
                      label: Text('${entry.key}: ${entry.value.length}'),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackIntentSection(
    BuildContext context,
    SignatureHealthSnapshot snapshot,
  ) {
    final grouped = snapshot.feedbackByIntent;
    final softIgnore =
        grouped['soft_ignore'] ?? const <SignatureHealthRecord>[];
    final hardReject =
        grouped['hard_not_interested'] ?? const <SignatureHealthRecord>[];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live feedback intent',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tracks whether users are softly passing for now or explicitly rejecting recommendations.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _kpiChip('Soft ignore', softIgnore.length),
                _kpiChip('Hard reject', hardReject.length),
              ],
            ),
            if (snapshot.feedbackRecords.isEmpty) ...[
              const SizedBox(height: 12),
              const Text('No live feedback telemetry captured yet.'),
            ] else ...[
              const SizedBox(height: 12),
              ...snapshot.feedbackRecords.take(8).map(
                    (record) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(record.sourceLabel ?? record.categoryLabel),
                      subtitle: Text(record.summary),
                      trailing: Text(record.categoryLabel),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackTrendSection(
    BuildContext context,
    SignatureHealthSnapshot snapshot,
  ) {
    final trendRows = snapshot.buildFeedbackTrendRows();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feedback trend by entity type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Shows where soft passes or hard rejections are clustering across the last 24 hours, 7 days, and 30 days.',
            ),
            if (trendRows.isEmpty) ...[
              const SizedBox(height: 12),
              const Text('No feedback trend data available yet.'),
            ] else ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Entity type')),
                    DataColumn(label: Text('24h')),
                    DataColumn(label: Text('7d')),
                    DataColumn(label: Text('30d')),
                  ],
                  rows: trendRows.take(8).map((row) {
                    return DataRow(
                      cells: [
                        DataCell(Text(row.entityType)),
                        for (final window
                            in SignatureHealthSnapshot.feedbackTrendWindows)
                          DataCell(
                            _trendCell(row.countsByWindow[window.label]!),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _trendCell(FeedbackTrendCount count) {
    return Text('${count.softIgnoreCount}/${count.hardNotInterestedCount}');
  }

  Widget _buildRecordsTable(List<SignatureHealthRecord> records) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entity Health Table',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Source')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Entity')),
                  DataColumn(label: Text('Provider')),
                  DataColumn(label: Text('Metro')),
                  DataColumn(label: Text('Confidence')),
                  DataColumn(label: Text('Freshness')),
                ],
                rows: records
                    .take(20)
                    .map(
                      (record) => DataRow(
                        cells: [
                          DataCell(Text(record.sourceLabel ?? record.sourceId)),
                          DataCell(Text(record.healthCategory.label)),
                          DataCell(Text(record.entityType)),
                          DataCell(Text(record.provider)),
                          DataCell(Text(record.metroLabel)),
                          DataCell(
                            Text('${(record.confidence * 100).round()}%'),
                          ),
                          DataCell(
                            Text('${(record.freshness * 100).round()}%'),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String route,
  }) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.dashboard_customize_outlined),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go(route),
      ),
    );
  }

  Widget _kpiChip(String label, int value) {
    return Chip(label: Text('$label: $value'));
  }
}
