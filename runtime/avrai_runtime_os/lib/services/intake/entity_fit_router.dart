import 'package:avrai_runtime_os/services/intake/intake_models.dart';

/// Heuristic best-fit router for universal external intake.
class EntityFitRouter {
  const EntityFitRouter();

  IntakeRouteDecision route(IntakeCandidate candidate) {
    final spotScore = _spotScore(candidate);
    final eventScore = _eventScore(candidate);
    final communityScore = _communityScore(candidate);
    final scores = <IntakeEntityType, double>{
      IntakeEntityType.spot: spotScore,
      IntakeEntityType.event: eventScore,
      IntakeEntityType.community: communityScore,
    };

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final primary = sorted.first.key;
    final primaryScore = sorted.first.value;
    final secondary = sorted.length > 1 ? sorted[1] : null;
    final linkedTypes = <IntakeEntityType>[];
    final reasons = <String>[];

    if (primary == IntakeEntityType.event && communityScore >= 0.6) {
      linkedTypes.addAll(
        const [IntakeEntityType.event, IntakeEntityType.community],
      );
      reasons.add('Source looks like an event run by an ongoing group.');
    } else if (primary == IntakeEntityType.community && eventScore >= 0.6) {
      linkedTypes.addAll(
        const [IntakeEntityType.community, IntakeEntityType.event],
      );
      reasons
          .add('Source includes a recurring community plus dated happenings.');
    }

    final missingFields = <String>[
      if (!candidate.hasWho) 'who',
      if (!candidate.hasWhat) 'what',
      if (!candidate.hasWhen && primary != IntakeEntityType.community) 'when',
      if (!candidate.hasWhere) 'where',
    ];

    final reviewDecision = missingFields.isEmpty
        ? IntakeReviewDecision.publish
        : IntakeReviewDecision.review;

    if (primary == IntakeEntityType.spot &&
        candidate.rawPayload['hours'] != null) {
      reasons.add('Hours/location signals make this behave like a place.');
    }
    if (primary == IntakeEntityType.event && candidate.startTime != null) {
      reasons.add('Time-bound schedule makes this an event.');
    }
    if (primary == IntakeEntityType.community &&
        _containsAny(candidate, const [
          'community',
          'club',
          'group',
          'volunteer',
          'chapter',
          'newsletter',
        ])) {
      reasons.add('Recurring group language makes this a community.');
    }
    if (missingFields.isNotEmpty) {
      reasons.add('Needs review for missing ${missingFields.join(", ")}.');
    } else {
      reasons.add('Has enough structure to appear in Explore immediately.');
    }
    if (secondary != null && secondary.value > 0.45) {
      reasons.add('Secondary fit: ${secondary.key.name}.');
    }

    return IntakeRouteDecision(
      primaryType:
          linkedTypes.isNotEmpty ? IntakeEntityType.linkedBundle : primary,
      linkedTypes: linkedTypes,
      reviewDecision: reviewDecision,
      confidence: primaryScore.clamp(0.0, 1.0),
      reasons: reasons,
    );
  }

  double _spotScore(IntakeCandidate candidate) {
    var score = 0.0;
    if (candidate.rawPayload['hours'] != null) score += 0.4;
    if ((candidate.websiteUrl ?? '').isNotEmpty) score += 0.1;
    if (candidate.hasWhere) score += 0.2;
    if (_containsAny(candidate, const [
      'restaurant',
      'cafe',
      'coffee',
      'bar',
      'shop',
      'store',
      'venue',
      'spot',
    ])) {
      score += 0.3;
    }
    return score;
  }

  double _eventScore(IntakeCandidate candidate) {
    var score = 0.0;
    if (candidate.startTime != null) score += 0.45;
    if (candidate.endTime != null) score += 0.1;
    if (_containsAny(candidate, const [
      'tonight',
      'today',
      'tomorrow',
      'rsvp',
      'doors at',
      'tickets',
      'lineup',
      'meetup',
      'festival',
      'workshop',
      'event',
    ])) {
      score += 0.35;
    }
    if (candidate.hasWhere) score += 0.1;
    return score;
  }

  double _communityScore(IntakeCandidate candidate) {
    var score = 0.0;
    if ((candidate.organizerName ?? '').isNotEmpty) score += 0.15;
    if (_containsAny(candidate, const [
      'community',
      'club',
      'organization',
      'org',
      'volunteer',
      'group',
      'chapter',
      'collective',
      'newsletter',
      'membership',
    ])) {
      score += 0.45;
    }
    if (candidate.startTime != null) score += 0.1;
    if (candidate.tags.length >= 2) score += 0.1;
    if (candidate.hasWhere) score += 0.1;
    return score;
  }

  bool _containsAny(IntakeCandidate candidate, List<String> needles) {
    final haystack = [
      candidate.title,
      candidate.description,
      candidate.category,
      candidate.organizerName ?? '',
      candidate.locationLabel ?? '',
      ...candidate.tags,
    ].join(' ').toLowerCase();
    return needles.any(haystack.contains);
  }
}
