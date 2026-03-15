import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_runtime_os/services/events/event_planning_telemetry_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class EventPlanningTelemetryDebugCard extends StatefulWidget {
  const EventPlanningTelemetryDebugCard({
    super.key,
    this.telemetryService,
    this.summaryOverride,
    this.recordsOverride,
  });

  final EventPlanningTelemetryService? telemetryService;
  final EventPlanningTelemetrySummary? summaryOverride;
  final List<EventPlanningTelemetryRecord>? recordsOverride;

  @override
  State<EventPlanningTelemetryDebugCard> createState() =>
      _EventPlanningTelemetryDebugCardState();
}

class _EventPlanningTelemetryDebugCardState
    extends State<EventPlanningTelemetryDebugCard> {
  EventPlanningTelemetryService? _telemetryService;
  EventPlanningTelemetrySummary? _summary;
  List<EventPlanningTelemetryRecord> _records =
      const <EventPlanningTelemetryRecord>[];
  bool _usingOverride = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (widget.summaryOverride != null || widget.recordsOverride != null) {
      setState(() {
        _usingOverride = true;
        _telemetryService = widget.telemetryService;
        _summary = widget.summaryOverride;
        _records =
            widget.recordsOverride ?? const <EventPlanningTelemetryRecord>[];
      });
      return;
    }
    final EventPlanningTelemetryService? telemetry = widget.telemetryService ??
        (GetIt.instance.isRegistered<EventPlanningTelemetryService>()
            ? GetIt.instance<EventPlanningTelemetryService>()
            : null);
    _telemetryService = telemetry;
    if (telemetry == null) {
      setState(() {
        _usingOverride = false;
        _summary = null;
        _records = const <EventPlanningTelemetryRecord>[];
      });
      return;
    }
    setState(() {
      _usingOverride = false;
      _summary = telemetry.summarize();
      _records = telemetry.listAll(limit: 5);
    });
  }

  @override
  Widget build(BuildContext context) {
    final EventPlanningTelemetrySummary? summary = _summary;
    return AppSurface(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Event Planning Telemetry',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Refresh telemetry',
              ),
            ],
          ),
          if (!_usingOverride && _telemetryService == null)
            const Text(
              'Telemetry service is not registered in this build.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else if (summary == null)
            const Text(
              'Loading event-planning telemetry…',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else ...<Widget>[
            Text(
              'Crossings ${summary.airGapCrossings} • Low-confidence ${summary.lowConfidenceSuggestions} (${_formatPercent(summary.lowConfidenceRate)}) • Accepted ${summary.suggestionAcceptances} (${_formatPercent(summary.suggestionAcceptanceRate)})',
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Created ${summary.eventsCreated} • Debriefs ${summary.debriefCompletions} (${_formatPercent(summary.debriefCompletionRate)})',
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            if (_records.isEmpty)
              const Text(
                'No event-planning telemetry recorded yet.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              ..._records.map(_buildRecordRow),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordRow(EventPlanningTelemetryRecord record) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _labelFor(record.kind),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  record.sourceKind.name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Crossing ${_shortCrossingId(record.crossingId)} • ${record.confidence.name} • ${record.truthScopeKey}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Event ${record.eventId ?? 'pending'} • Locality ${record.localityCode ?? 'n/a'} • City ${record.cityCode ?? 'n/a'}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _labelFor(EventPlanningTelemetryKind kind) {
    return switch (kind) {
      EventPlanningTelemetryKind.airGapCrossed => 'Air gap crossed',
      EventPlanningTelemetryKind.lowConfidenceSuggestionShown =>
        'Low-confidence suggestion',
      EventPlanningTelemetryKind.suggestionAccepted => 'Suggestion accepted',
      EventPlanningTelemetryKind.eventCreated => 'Event created',
      EventPlanningTelemetryKind.debriefCompleted => 'Debrief completed',
    };
  }

  String _shortCrossingId(String crossingId) {
    if (crossingId.length <= 18) {
      return crossingId;
    }
    return '${crossingId.substring(0, 10)}…${crossingId.substring(crossingId.length - 6)}';
  }

  String _formatPercent(double value) {
    return '${(value * 100).toStringAsFixed(0)}%';
  }
}
