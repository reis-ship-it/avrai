import 'dart:async';
import 'dart:convert';

import 'package:avrai_admin_app/ui/widgets/why_snapshot_admin_card.dart';
import 'package:avrai_core/models/events/event_recommendation.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/why/why_models.dart';
import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_why_explanation_service.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_telemetry_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

class RecommendationWhyPreview {
  const RecommendationWhyPreview({
    this.record,
    required this.snapshot,
    required this.event,
    required this.referenceUser,
    required this.generatedAt,
  });

  final RecommendationTelemetryRecord? record;
  final WhySnapshot snapshot;
  final ExpertiseEvent event;
  final UnifiedUser referenceUser;
  final DateTime generatedAt;
}

class RecommendationWhyPreviewCard extends StatefulWidget {
  const RecommendationWhyPreviewCard({
    super.key,
    this.previewLoader,
  });

  final Future<RecommendationWhyPreview?> Function()? previewLoader;

  @override
  State<RecommendationWhyPreviewCard> createState() =>
      _RecommendationWhyPreviewCardState();
}

class _RecommendationWhyPreviewCardState
    extends State<RecommendationWhyPreviewCard> {
  bool _isLoading = true;
  String? _error;
  RecommendationWhyPreview? _preview;
  List<RecommendationTelemetryRecord> _recentRecords =
      const <RecommendationTelemetryRecord>[];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    unawaited(_loadPreview());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final recentRecords = widget.previewLoader == null
          ? _loadRecentTelemetry()
          : const <RecommendationTelemetryRecord>[];
      final loader = widget.previewLoader ?? _defaultPreviewLoader;
      final preview = await loader();
      if (!mounted) {
        return;
      }
      setState(() {
        _preview = preview;
        _recentRecords = recentRecords;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to build recommendation why preview: $error';
        _isLoading = false;
      });
    }
  }

  List<RecommendationTelemetryRecord> _loadRecentTelemetry() {
    final getIt = GetIt.instance;
    final telemetry = getIt.isRegistered<RecommendationTelemetryService>()
        ? getIt<RecommendationTelemetryService>()
        : null;
    return telemetry?.listAll(limit: 5) ??
        const <RecommendationTelemetryRecord>[];
  }

  Future<RecommendationWhyPreview?> _defaultPreviewLoader() async {
    final getIt = GetIt.instance;
    final telemetry = getIt.isRegistered<RecommendationTelemetryService>()
        ? getIt<RecommendationTelemetryService>()
        : null;
    final headlessOsHost = getIt.isRegistered<HeadlessAvraiOsHost>()
        ? getIt<HeadlessAvraiOsHost>()
        : null;
    final latest = telemetry?.latest();
    if (latest != null) {
      return RecommendationWhyPreview(
        record: latest,
        snapshot: latest.explanation,
        event: _recordEvent(latest),
        referenceUser: _recordUser(latest),
        generatedAt: latest.timestamp,
      );
    }
    final referenceUser = _referenceUser();
    final event = _referenceEvent(referenceUser);
    final recommendation = _buildReferenceRecommendation(event, referenceUser);
    final whyService =
        RecommendationWhyExplanationService(headlessOsHost: headlessOsHost);
    final snapshot = await whyService.explainRecommendationWithKernelContext(
      user: referenceUser,
      recommendation: recommendation,
      perspective: 'admin',
    );
    return RecommendationWhyPreview(
      snapshot: snapshot,
      event: event,
      referenceUser: referenceUser,
      generatedAt: recommendation.generatedAt,
    );
  }

  UnifiedUser _referenceUser() {
    final now = DateTime.now().toUtc();
    return UnifiedUser(
      id: 'admin_reference_user',
      email: 'admin-reference@avrai.local',
      displayName: 'Admin Reference User',
      location: 'Austin, TX',
      createdAt: now,
      updatedAt: now,
      expertiseMap: const <String, String>{'food': 'local'},
    );
  }

  ExpertiseEvent _referenceEvent(UnifiedUser host) {
    final now = DateTime.now().toUtc();
    return ExpertiseEvent(
      id: 'admin_reference_event',
      title: 'Coffee Walk',
      description: 'Reference event for recommendation why inspection.',
      category: 'food',
      eventType: ExpertiseEventType.walk,
      host: host,
      startTime: now.add(const Duration(days: 1)),
      endTime: now.add(const Duration(days: 1, hours: 2)),
      location: 'Austin, TX',
      createdAt: now,
      updatedAt: now,
    );
  }

  UnifiedUser _recordUser(RecommendationTelemetryRecord record) {
    return UnifiedUser(
      id: record.userId,
      email: '${record.userId}@avrai.local',
      displayName: record.userId,
      location: record.location,
      createdAt: record.timestamp,
      updatedAt: record.timestamp,
    );
  }

  ExpertiseEvent _recordEvent(RecommendationTelemetryRecord record) {
    return ExpertiseEvent(
      id: record.eventId,
      title: record.eventTitle,
      description: record.reason,
      category: record.category,
      eventType: ExpertiseEventType.walk,
      host: _recordUser(record),
      startTime: record.timestamp,
      endTime: record.timestamp.add(const Duration(hours: 2)),
      location: record.location,
      createdAt: record.timestamp,
      updatedAt: record.timestamp,
    );
  }

  EventRecommendation _buildReferenceRecommendation(
    ExpertiseEvent event,
    UnifiedUser referenceUser,
  ) {
    final categoryMatch =
        referenceUser.hasExpertiseIn(event.category) ? 0.9 : 0.48;
    final localityMatch = (event.location ?? '').isNotEmpty ? 0.74 : 0.41;
    const scopeMatch = 0.64;
    final localExpertMatch = event.host.id == referenceUser.id ? 0.82 : 0.58;
    final eventTypeMatch =
        event.eventType == ExpertiseEventType.tour ? 0.7 : 0.62;
    final preferenceMatch = PreferenceMatchDetails(
      categoryMatch: categoryMatch,
      localityMatch: localityMatch,
      scopeMatch: scopeMatch,
      eventTypeMatch: eventTypeMatch,
      localExpertMatch: localExpertMatch,
    );
    final reason = localityMatch >= categoryMatch
        ? RecommendationReason.localityPreference
        : RecommendationReason.categoryPreference;
    return EventRecommendation(
      event: event,
      relevanceScore: preferenceMatch.overallMatch.clamp(0.0, 1.0),
      reason: reason,
      preferenceMatch: preferenceMatch,
      isExploration: false,
      generatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.recommend_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommendation Why Preview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Admin inspection for canonical recommendation why output. Uses the latest recorded recommendation audit when available and falls back to a deterministic reference scenario otherwise.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _loadPreview,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh recommendation why preview',
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
              _buildInfoBox(context, _error!, AppColors.error)
            else if (_preview == null)
              _buildInfoBox(
                  context,
                  'Recommendation why preview is currently unavailable.',
                  AppColors.warning)
            else ...[
              if (_recentRecords.isNotEmpty) ...[
                _buildRecentTimeline(context, _filteredRecords()),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_preview!.record != null)
                    _chip('record ${_preview!.record!.recordId}'),
                  if (_preview!.record?.modelTruthReady == true)
                    _chip('model truth ready'),
                  if (_preview!.record?.localityContainedInWhere == true)
                    _chip('locality in where'),
                  _chip('event ${_preview!.event.title}'),
                  _chip('category ${_preview!.event.category}'),
                  _chip('reference user ${_preview!.referenceUser.id}'),
                  _chip(
                    'generated ${_formatTimestamp(_preview!.generatedAt)}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_preview!.record != null) ...[
                _buildAuditDrilldown(context, _preview!.record!),
                const SizedBox(height: 12),
              ],
              WhySnapshotAdminCard(
                snapshot: _preview!.snapshot,
                title: 'Canonical Recommendation Why Snapshot',
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<RecommendationTelemetryRecord> _filteredRecords() {
    return _recentRecords.where((record) {
      final categoryMatch =
          _categoryFilter == null || record.category == _categoryFilter;
      final haystack = <String>[
        record.eventTitle,
        record.category,
        record.reason,
        record.userId,
        record.location ?? '',
      ].join(' ').toLowerCase();
      final queryMatch =
          _searchQuery.isEmpty || haystack.contains(_searchQuery);
      return categoryMatch && queryMatch;
    }).toList(growable: false);
  }

  Widget _buildRecentTimeline(
    BuildContext context,
    List<RecommendationTelemetryRecord> filteredRecords,
  ) {
    final categories =
        _recentRecords.map((entry) => entry.category).toSet().toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent Recommendation Audits',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: filteredRecords.isEmpty
                  ? null
                  : () => _exportFilteredToClipboard(filteredRecords),
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Export Filtered'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            isDense: true,
            hintText: 'Search event, user, reason, location...',
            prefixIcon: Icon(Icons.search, size: 18),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        if (categories.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Category: All'),
                selected: _categoryFilter == null,
                onSelected: (_) => setState(() {
                  _categoryFilter = null;
                }),
              ),
              ...categories.map(
                (category) => ChoiceChip(
                  label: Text(category),
                  selected: _categoryFilter == category,
                  onSelected: (_) => setState(() {
                    _categoryFilter = category;
                  }),
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        if (filteredRecords.isEmpty)
          const Text(
            'No recommendation audits match the current filters.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          ...filteredRecords.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _preview = RecommendationWhyPreview(
                      record: record,
                      snapshot: record.explanation,
                      event: _recordEvent(record),
                      referenceUser: _recordUser(record),
                      generatedAt: record.timestamp,
                    );
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _preview?.event.id == record.eventId
                        ? AppColors.selection.withValues(alpha: 0.08)
                        : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _preview?.event.id == record.eventId
                          ? AppColors.selection.withValues(alpha: 0.25)
                          : AppColors.borderSubtle,
                    ),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        record.eventTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Tooltip(
                        message: 'Copy Record ID',
                        child: InkWell(
                          onTap: () => _copyToClipboard(
                            'Record ID',
                            record.recordId,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(Icons.copy, size: 14),
                          ),
                        ),
                      ),
                      Text(
                        record.reason,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        _formatTimestamp(record.timestamp),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      if (record.modelTruthReady == true)
                        const Text(
                          'model-truth',
                          style: TextStyle(color: AppColors.success),
                        ),
                      if (record.localityContainedInWhere == true)
                        const Text(
                          'where/locality',
                          style: TextStyle(color: AppColors.selection),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _exportFilteredToClipboard(
    List<RecommendationTelemetryRecord> filteredRecords,
  ) async {
    final payload = const JsonEncoder.withIndent('  ').convert(
      filteredRecords.map((entry) => entry.toJson()).toList(),
    );
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exported ${filteredRecords.length} filtered recommendation audits',
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied')),
    );
  }

  Widget _buildAuditDrilldown(
    BuildContext context,
    RecommendationTelemetryRecord record,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Audit Drill-down',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showRecordDetails(record),
                icon: const Icon(Icons.open_in_full, size: 16),
                label: const Text('Open Details'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Record ID: ${record.recordId}'),
          Text('Reason: ${record.reason}'),
          if (record.kernelEventId != null)
            Text('Kernel Event: ${record.kernelEventId}'),
          if (record.governanceSummary != null)
            Text('Governance: ${record.governanceSummary}'),
          if (record.traceRef != null) Text('Trace: ${record.traceRef}'),
        ],
      ),
    );
  }

  void _showRecordDetails(RecommendationTelemetryRecord record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recommendation Audit Details',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy Record ID',
                      onPressed: () =>
                          _copyToClipboard('Record ID', record.recordId),
                      icon: const Icon(Icons.copy, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _detailLine('Record ID', record.recordId),
                _detailLine('Event', record.eventTitle),
                _detailLine('User', record.userId),
                _detailLine('Category', record.category),
                _detailLine(
                  'Relevance',
                  record.relevanceScore.toStringAsFixed(2),
                ),
                _detailLine('Reason', record.reason),
                if (record.location != null)
                  _detailLine('Location', record.location!),
                if (record.kernelEventId != null)
                  _detailLine('Kernel Event ID', record.kernelEventId!),
                if (record.modelTruthReady != null)
                  _detailLine(
                    'Model Truth Ready',
                    record.modelTruthReady! ? 'true' : 'false',
                  ),
                if (record.localityContainedInWhere != null)
                  _detailLine(
                    'Locality In Where',
                    record.localityContainedInWhere! ? 'true' : 'false',
                  ),
                if (record.governanceSummary != null)
                  _detailLine('Governance Summary', record.governanceSummary!),
                if (record.governanceDomains.isNotEmpty)
                  _detailLine(
                    'Governance Domains',
                    record.governanceDomains.join(', '),
                  ),
                if (record.traceRef != null)
                  _detailLine('Trace Ref', record.traceRef!),
                _detailLine('Timestamp', _formatTimestamp(record.timestamp)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppColors.textPrimary),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context, String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
      ),
    );
  }

  Widget _chip(String label) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }

  String _formatTimestamp(DateTime ts) {
    final utc = ts.toUtc();
    final hh = utc.hour.toString().padLeft(2, '0');
    final mm = utc.minute.toString().padLeft(2, '0');
    return '${utc.year}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')} $hh:$mm UTC';
  }
}
