import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_core/services/event_planning_evidence_factory.dart';
import 'package:avrai_runtime_os/services/events/event_learning_signal_service.dart';
import 'package:avrai_runtime_os/services/events/event_planning_telemetry_service.dart';
import 'package:avrai_runtime_os/services/events/event_success_analysis_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';

class EventHostDebriefService {
  final ExpertiseEventService _eventService;
  final EventSuccessAnalysisService _successAnalysisService;
  final EventLearningSignalService _learningSignalService;
  final EventPlanningTelemetryService? _telemetryService;

  final Map<String, HostEventDebrief> _debriefs = <String, HostEventDebrief>{};

  EventHostDebriefService({
    required ExpertiseEventService eventService,
    required EventSuccessAnalysisService successAnalysisService,
    required EventLearningSignalService learningSignalService,
    EventPlanningTelemetryService? telemetryService,
  })  : _eventService = eventService,
        _successAnalysisService = successAnalysisService,
        _learningSignalService = learningSignalService,
        _telemetryService = telemetryService;

  Future<HostEventDebrief?> getDebrief(String eventId) async {
    return _debriefs[eventId];
  }

  Future<HostEventDebrief> createDebrief({
    required String eventId,
    String? outcomeNotesRaw,
  }) async {
    final event = await _eventService.getEventById(eventId);
    if (event == null) {
      throw Exception('Event not found: $eventId');
    }

    if (event.planningSnapshot == null) {
      throw StateError(
          'Event debrief requires an air-gapped planning snapshot.');
    }

    final metrics = await _successAnalysisService.analyzeEventSuccess(eventId);
    final predictedFill =
        event.planningSnapshot?.acceptedSuggestion?.predictedAttendanceFillBand;
    final wouldAttendAgainRate = metrics.actualAttendance > 0
        ? metrics.attendeesWhoWouldReturn / metrics.actualAttendance
        : 0.0;

    final insightLines = <String>[
      if (predictedFill != null)
        'Predicted ${predictedFill.name} fill; actual attendance landed at ${_fillBand(metrics.attendanceRate).name}.',
      if (metrics.successFactors.isNotEmpty) metrics.successFactors.first,
      if (metrics.improvementAreas.isNotEmpty) metrics.improvementAreas.first,
    ].where((line) => line.trim().isNotEmpty).take(3).toList(growable: false);

    final createdAt = DateTime.now();
    final baseDebrief = HostEventDebrief(
      eventId: eventId,
      predictedAttendanceFillBand: predictedFill,
      actualAttendance: metrics.actualAttendance,
      attendanceRate: metrics.attendanceRate,
      averageRating: metrics.averageRating,
      wouldAttendAgainRate: wouldAttendAgainRate,
      insightLines: insightLines,
      createdAt: createdAt,
      truthScope: event.planningSnapshot!.truthScope,
    );

    final debrief = HostEventDebrief(
      eventId: baseDebrief.eventId,
      predictedAttendanceFillBand: baseDebrief.predictedAttendanceFillBand,
      actualAttendance: baseDebrief.actualAttendance,
      attendanceRate: baseDebrief.attendanceRate,
      averageRating: baseDebrief.averageRating,
      wouldAttendAgainRate: baseDebrief.wouldAttendAgainRate,
      insightLines: baseDebrief.insightLines,
      createdAt: baseDebrief.createdAt,
      truthScope: baseDebrief.truthScope,
      evidenceEnvelope: EventPlanningEvidenceFactory.debrief(
        snapshot: event.planningSnapshot!,
        debrief: baseDebrief,
      ),
    );

    _debriefs[eventId] = debrief;
    await _learningSignalService.recordEventOutcome(
      event: event,
      debrief: debrief,
      outcomeNotesRaw: outcomeNotesRaw,
    );
    final EventPlanningTelemetryService? telemetryService = _telemetryService;
    if (telemetryService != null) {
      await telemetryService.recordDebriefCompleted(
        event: event,
        debrief: debrief,
      );
    }

    return debrief;
  }

  EventAttendanceFillBand _fillBand(double attendanceRate) {
    if (attendanceRate >= 0.75) {
      return EventAttendanceFillBand.high;
    }
    if (attendanceRate >= 0.4) {
      return EventAttendanceFillBand.medium;
    }
    return EventAttendanceFillBand.low;
  }
}
