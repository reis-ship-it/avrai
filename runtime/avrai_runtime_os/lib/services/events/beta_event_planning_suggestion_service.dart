import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';
import 'package:avrai_core/services/event_planning_evidence_factory.dart';
import 'package:avrai_core/services/truth_scope_registry.dart';

class BetaEventPlanningSuggestionService {
  const BetaEventPlanningSuggestionService();
  static const TruthScopeRegistry _truthScopeRegistry = TruthScopeRegistry();

  EventCreationSuggestion suggest({
    required EventDocketLite docket,
    required ExpertiseEventType eventType,
    required DateTime currentStartTime,
    required Duration defaultDuration,
    required int currentMaxAttendees,
    double? currentPrice,
    TruthScopeDescriptor? truthScope,
  }) {
    final confidence = _deriveConfidence(docket);
    final isLowConfidence = confidence == EventPlanningConfidence.low;
    final planningTruthScope = _truthScopeRegistry.normalizePlanningScope(
      scope: truthScope,
      familyId: 'event_planning_suggestion',
      metadata: <String, dynamic>{
        'governance_stratum':
            docket.candidateLocalityCode == null ? 'personal' : 'locality',
        'planning_sphere_id': docket.candidateLocalityCode == null
            ? 'event_planning'
            : 'event_planning_locality',
        'planning_family_id': 'event_planning_suggestion',
        'agent_class': TruthAgentClass.organizer.name,
      },
    );
    final suggestedStartTime = _suggestStartTime(
      docket: docket,
      eventType: eventType,
      currentStartTime: currentStartTime,
      isLowConfidence: isLowConfidence,
    );
    final suggestedEndTime = suggestedStartTime.add(defaultDuration);
    final suggestedMaxAttendees = _suggestMaxAttendees(
        docket.sizeIntent, currentMaxAttendees, isLowConfidence);
    final suggestedPrice = _suggestPrice(docket.priceIntent, currentPrice);
    final fillBand = _predictAttendanceFillBand(
      docket,
      suggestedPrice,
      suggestedMaxAttendees,
      confidence,
    );

    final explanation = _buildExplanation(
      docket: docket,
      suggestedStartTime: suggestedStartTime,
      suggestedMaxAttendees: suggestedMaxAttendees,
      suggestedPrice: suggestedPrice,
      fillBand: fillBand,
      confidence: confidence,
    );

    final suggestion = EventCreationSuggestion(
      suggestedStartTime: suggestedStartTime,
      suggestedEndTime: suggestedEndTime,
      suggestedLocalityLabel:
          docket.candidateLocalityLabel?.trim().isEmpty == true
              ? null
              : docket.candidateLocalityLabel,
      suggestedMaxAttendees: suggestedMaxAttendees,
      suggestedPrice: suggestedPrice,
      predictedAttendanceFillBand: fillBand,
      confidence: confidence,
      explanation: explanation,
      truthScope: planningTruthScope,
    );
    return EventCreationSuggestion(
      suggestedStartTime: suggestion.suggestedStartTime,
      suggestedEndTime: suggestion.suggestedEndTime,
      suggestedLocalityLabel: suggestion.suggestedLocalityLabel,
      suggestedMaxAttendees: suggestion.suggestedMaxAttendees,
      suggestedPrice: suggestion.suggestedPrice,
      predictedAttendanceFillBand: suggestion.predictedAttendanceFillBand,
      confidence: suggestion.confidence,
      explanation: suggestion.explanation,
      truthScope: suggestion.truthScope,
      evidenceEnvelope: EventPlanningEvidenceFactory.suggestion(
        docket: docket,
        suggestion: suggestion,
        truthScope: planningTruthScope,
      ),
    );
  }

  EventPlanningConfidence _deriveConfidence(EventDocketLite docket) {
    final signalCount = docket.intentTags.length +
        docket.vibeTags.length +
        docket.audienceTags.length +
        (docket.candidateLocalityLabel?.isNotEmpty == true ? 1 : 0);

    if (signalCount >= 7) {
      return EventPlanningConfidence.high;
    }
    if (signalCount >= 3) {
      return EventPlanningConfidence.medium;
    }
    return EventPlanningConfidence.low;
  }

  DateTime _suggestStartTime({
    required EventDocketLite docket,
    required ExpertiseEventType eventType,
    required DateTime currentStartTime,
    required bool isLowConfidence,
  }) {
    if (isLowConfidence) {
      return currentStartTime;
    }

    var hour = currentStartTime.hour;
    switch (docket.hostGoal) {
      case EventHostGoal.community:
      case EventHostGoal.learning:
        hour = 10;
        break;
      case EventHostGoal.networking:
        hour = 18;
        break;
      case EventHostGoal.celebration:
        hour = eventType == ExpertiseEventType.meetup ? 19 : 17;
        break;
      case EventHostGoal.mixed:
        hour = currentStartTime.hour == 0 ? 14 : currentStartTime.hour;
        break;
    }

    return DateTime(
      currentStartTime.year,
      currentStartTime.month,
      currentStartTime.day,
      hour,
      0,
    );
  }

  int _suggestMaxAttendees(
    EventSizeIntent intent,
    int currentMaxAttendees,
    bool isLowConfidence,
  ) {
    if (isLowConfidence) {
      return currentMaxAttendees;
    }

    return switch (intent) {
      EventSizeIntent.intimate => currentMaxAttendees.clamp(8, 16),
      EventSizeIntent.standard => currentMaxAttendees.clamp(18, 36),
      EventSizeIntent.large => currentMaxAttendees.clamp(40, 80),
    };
  }

  double? _suggestPrice(EventPriceIntent intent, double? currentPrice) {
    return switch (intent) {
      EventPriceIntent.free => null,
      EventPriceIntent.lowCost => currentPrice == null || currentPrice <= 0
          ? 15.0
          : currentPrice.clamp(5.0, 20.0),
      EventPriceIntent.ticketed => currentPrice == null || currentPrice <= 0
          ? 30.0
          : currentPrice < 20
              ? 20.0
              : currentPrice,
    };
  }

  EventAttendanceFillBand _predictAttendanceFillBand(
    EventDocketLite docket,
    double? suggestedPrice,
    int suggestedMaxAttendees,
    EventPlanningConfidence confidence,
  ) {
    if (confidence == EventPlanningConfidence.low) {
      return EventAttendanceFillBand.low;
    }

    var score = 0;
    score += docket.intentTags.isNotEmpty ? 1 : 0;
    score += docket.vibeTags.isNotEmpty ? 1 : 0;
    score += docket.audienceTags.isNotEmpty ? 1 : 0;
    score += docket.candidateLocalityLabel?.isNotEmpty == true ? 1 : 0;
    score += suggestedPrice == null ? 1 : 0;
    score += suggestedMaxAttendees <= 24 ? 1 : 0;

    if (score >= 5) {
      return EventAttendanceFillBand.high;
    }
    if (score >= 3) {
      return EventAttendanceFillBand.medium;
    }
    return EventAttendanceFillBand.low;
  }

  String _buildExplanation({
    required EventDocketLite docket,
    required DateTime suggestedStartTime,
    required int suggestedMaxAttendees,
    required double? suggestedPrice,
    required EventAttendanceFillBand fillBand,
    required EventPlanningConfidence confidence,
  }) {
    final locality = docket.candidateLocalityLabel ?? 'your current locality';
    final priceLabel = suggestedPrice == null
        ? 'free'
        : '\$${suggestedPrice.toStringAsFixed(0)}';
    if (confidence == EventPlanningConfidence.low) {
      return 'Low confidence: AVRAI is keeping this close to your current plan because the air-gapped event truth is still sparse. '
          'It can carry forward the stated ${docket.hostGoal.name} goal and $priceLabel price intent, '
          'but timing, locality, and turnout should be reviewed manually or improved with more purpose, vibe, audience, or locality detail.';
    }

    final confidencePrefix = confidence == EventPlanningConfidence.high
        ? 'High confidence'
        : 'Medium confidence';

    return '$confidencePrefix: $locality is the best current fit, '
        '${_formatHour(suggestedStartTime.hour)} supports the stated ${docket.hostGoal.name} goal, '
        '$suggestedMaxAttendees keeps the event in the ${docket.sizeIntent.name} range, '
        'and $priceLabel supports a ${fillBand.name}-fill forecast.';
  }

  String _formatHour(int hour) {
    final normalizedHour = hour > 12 ? hour - 12 : hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$normalizedHour:00 $period';
  }
}
