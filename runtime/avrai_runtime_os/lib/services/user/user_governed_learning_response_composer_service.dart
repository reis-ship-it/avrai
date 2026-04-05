import 'package:avrai_core/models/reality/governed_learning_adoption_receipt.dart';
import 'package:avrai_core/models/reality/governed_learning_chat_observation_receipt.dart';
import 'package:avrai_core/models/reality/governed_learning_usage_receipt.dart';
import 'package:avrai_core/models/reality/user_visible_governed_learning.dart';

enum UserGovernedLearningResponseFocus {
  overview,
  why,
  confidence,
  impact,
  lineage,
}

class UserGovernedLearningComposedResponse {
  const UserGovernedLearningComposedResponse({
    required this.headline,
    required this.bodySegments,
    required this.focus,
    required this.selectedRecord,
  });

  final String headline;
  final List<String> bodySegments;
  final UserGovernedLearningResponseFocus focus;
  final UserVisibleGovernedLearningRecord selectedRecord;

  String render({int maxBodySegments = 4}) {
    final segments = <String>[
      headline,
      ...bodySegments.where((entry) => entry.trim().isNotEmpty).take(
            maxBodySegments,
          ),
    ];
    return segments.join(' ');
  }
}

class UserGovernedLearningResponseComposerService {
  const UserGovernedLearningResponseComposerService();

  static const List<String> _knownSurfacedRecommendationLanes = <String>[
    'events_personalized',
    'explore_events',
    'explore_spots',
  ];

  UserGovernedLearningComposedResponse compose({
    required UserVisibleGovernedLearningRecord selectedRecord,
    required List<UserVisibleGovernedLearningRecord> visibleRecords,
    String? userQuestion,
  }) {
    final focus = _resolveFocus(userQuestion);
    final isLatestRecord = visibleRecords.isNotEmpty &&
        visibleRecords.first.envelopeId == selectedRecord.envelopeId;
    final sourceStatement = _buildSourceStatement(
      selectedRecord,
      isLatestRecord: isLatestRecord,
    );
    final confidenceStatement = _buildConfidenceStatement(selectedRecord);
    final impactStatement = _buildImpactStatement(
      selectedRecord,
      userQuestion: userQuestion,
    );
    final lineageStatement = _buildLineageStatement(
      selectedRecord,
      userQuestion: userQuestion,
    );
    final uncertaintyStatement = _buildUncertaintyStatement(selectedRecord);
    final actionStatement = _buildActionStatement(selectedRecord);

    final bodySegments = switch (focus) {
      UserGovernedLearningResponseFocus.lineage => <String>[
          sourceStatement,
          if (lineageStatement != null) lineageStatement,
          impactStatement,
          actionStatement,
        ],
      UserGovernedLearningResponseFocus.why => <String>[
          sourceStatement,
          if (lineageStatement != null) lineageStatement,
          confidenceStatement,
          uncertaintyStatement,
          actionStatement,
        ],
      UserGovernedLearningResponseFocus.confidence => <String>[
          confidenceStatement,
          sourceStatement,
          uncertaintyStatement,
          actionStatement,
        ],
      UserGovernedLearningResponseFocus.impact => <String>[
          impactStatement,
          if (lineageStatement != null) lineageStatement,
          confidenceStatement,
          uncertaintyStatement,
          actionStatement,
        ],
      UserGovernedLearningResponseFocus.overview => <String>[
          sourceStatement,
          confidenceStatement,
          impactStatement,
          if (lineageStatement != null) lineageStatement,
          uncertaintyStatement,
          actionStatement,
        ],
    };

    return UserGovernedLearningComposedResponse(
      headline: _buildHeadline(
        selectedRecord,
        isLatestRecord: isLatestRecord,
      ),
      bodySegments: bodySegments,
      focus: focus,
      selectedRecord: selectedRecord,
    );
  }

  UserGovernedLearningResponseFocus _resolveFocus(String? userQuestion) {
    final normalized = userQuestion?.toLowerCase() ?? '';
    if (normalized.contains('why')) {
      return UserGovernedLearningResponseFocus.why;
    }
    if (_wantsLineageExplanation(normalized)) {
      return UserGovernedLearningResponseFocus.lineage;
    }
    if (normalized.contains('confidence') ||
        normalized.contains('certain') ||
        normalized.contains('sure') ||
        normalized.contains('how strong')) {
      return UserGovernedLearningResponseFocus.confidence;
    }
    if (normalized.contains('use') ||
        normalized.contains('used') ||
        normalized.contains('change') ||
        normalized.contains('changed') ||
        normalized.contains('update') ||
        normalized.contains('affect') ||
        normalized.contains('impact') ||
        normalized.contains('shape')) {
      return UserGovernedLearningResponseFocus.impact;
    }
    return UserGovernedLearningResponseFocus.overview;
  }

  String _buildHeadline(
    UserVisibleGovernedLearningRecord record, {
    required bool isLatestRecord,
  }) {
    final humanizedSummary = _humanizeSummary(record.safeSummary);
    final latestUsage = _latestUsage(record);
    if (latestUsage != null) {
      return 'I saw that ${_ensureSentenceBody(humanizedSummary)}, so that helped me recommend "${latestUsage.targetEntityTitle}".';
    }
    return isLatestRecord
        ? 'I learned that ${_ensureSentenceBody(humanizedSummary)}.'
        : 'I am referring to the record about ${_ensureSentenceBody(humanizedSummary)}.';
  }

  String _buildSourceStatement(
    UserVisibleGovernedLearningRecord record, {
    required bool isLatestRecord,
  }) {
    final sourceDescription = _describeSource(record);
    final date = _formatDate(record.occurredAtUtc);
    final latestUsage = _latestUsage(record);
    if (latestUsage != null) {
      final usedAt = _formatDate(latestUsage.usedAtUtc);
      return isLatestRecord
          ? 'That came from $sourceDescription on $date, and the latest visible use was when I recommended "${latestUsage.targetEntityTitle}" on $usedAt.'
          : 'That is not the newest visible record in your ledger, but it best matched your question. It came from $sourceDescription on $date, and I most recently used it when I recommended "${latestUsage.targetEntityTitle}" on $usedAt.';
    }
    if (isLatestRecord) {
      return 'That came from $sourceDescription on $date.';
    }
    return 'That is not the newest visible record in your ledger, but it best matched your question. It came from $sourceDescription on $date.';
  }

  String _buildConfidenceStatement(UserVisibleGovernedLearningRecord record) {
    final confidence = switch (record.convictionTier) {
      'explicit_correction_signal' => 'a strong explicit correction',
      'ai2ai_explicit_correction_signal' =>
        'a strong bounded AI2AI explicit correction',
      'recommendation_feedback_correction_signal' =>
        'a strong recommendation-feedback correction',
      'personal_agent_human_observation' =>
        'a medium-confidence personal observation',
      'ai2ai_peer_signal' => 'a bounded AI2AI peer signal',
      _ => 'a bounded ${_humanizeToken(record.convictionTier)} signal',
    };
    final reviewTail = record.requiresHumanReview
        ? ' It is still behind human review before any broader promotion.'
        : '';
    final validationTail = _buildValidationTail(record);
    final governanceTail = _buildGovernanceTail(record);
    return 'I am treating it as $confidence.$reviewTail$validationTail$governanceTail';
  }

  String _buildImpactStatement(
    UserVisibleGovernedLearningRecord record, {
    String? userQuestion,
  }) {
    final latestUsage = _latestUsage(record);
    final hasSurfacedRecommendations = record.surfacedSurfaces.isNotEmpty;
    final hasQueuedEvents = _hasPendingSurface(record, 'events_personalized');
    final surfacedScope = record.surfacedSurfaces.isEmpty
        ? null
        : _joinHumanList(
            record.surfacedSurfaces
                .take(3)
                .map(_humanizeLearningSurface)
                .toList(growable: false),
          );
    final appliedDomains = _effectiveAppliedDomains(record);
    final askedDomains = _extractAskedAboutDomains(
      userQuestion,
      record,
    );
    final matchedAskedDomains = askedDomains
        .where(
          (askedDomain) => appliedDomains.any(
            (appliedDomain) => _domainMatches(askedDomain, appliedDomain),
          ),
        )
        .toList(growable: false);
    final unmatchedAskedDomains = askedDomains
        .where(
          (askedDomain) => !matchedAskedDomains.contains(askedDomain),
        )
        .toList(growable: false);
    final surfaceProgressTail = _buildSurfaceProgressTail(record);
    if (latestUsage != null &&
        hasSurfacedRecommendations &&
        appliedDomains.isNotEmpty) {
      if (matchedAskedDomains.isNotEmpty && unmatchedAskedDomains.isNotEmpty) {
        return 'So far this has affected ${_joinHumanList(matchedAskedDomains)} recommendations, but not ${_joinHumanList(unmatchedAskedDomains)} recommendations. The latest visible use was "${latestUsage.targetEntityTitle}" in ${surfacedScope ?? 'a surfaced recommendation lane'}.${surfaceProgressTail == null ? '' : ' $surfaceProgressTail'}';
      }
      if (matchedAskedDomains.isNotEmpty) {
        return 'So far this has affected ${_joinHumanList(matchedAskedDomains)} recommendations. The latest visible use was "${latestUsage.targetEntityTitle}" in ${surfacedScope ?? 'a surfaced recommendation lane'}.${surfaceProgressTail == null ? '' : ' $surfaceProgressTail'}';
      }
      if (unmatchedAskedDomains.isNotEmpty) {
        final scope = _joinHumanList(
          appliedDomains.take(3).toList(growable: false),
        );
        return 'So far this has affected $scope recommendations, but not ${_joinHumanList(unmatchedAskedDomains)} recommendations. The latest visible use was "${latestUsage.targetEntityTitle}" in ${surfacedScope ?? 'a surfaced recommendation lane'}.${surfaceProgressTail == null ? '' : ' $surfaceProgressTail'}';
      }
      final scope =
          _joinHumanList(appliedDomains.take(3).toList(growable: false));
      return 'So far this has affected $scope recommendations. The latest visible use was "${latestUsage.targetEntityTitle}" in ${surfacedScope ?? 'a surfaced recommendation lane'}.${surfaceProgressTail == null ? '' : ' $surfaceProgressTail'}';
    }
    if (latestUsage != null) {
      return 'So far this has already influenced at least one surfaced recommendation, including "${latestUsage.targetEntityTitle}".${surfaceProgressTail == null ? '' : ' $surfaceProgressTail'}';
    }
    if (hasQueuedEvents) {
      final unaffectedDomains = unmatchedAskedDomains
          .where((domain) => !_domainMatches(domain, 'event'))
          .toList(growable: false);
      if (unaffectedDomains.isNotEmpty) {
        return 'I have taken your correction into account. You should notice this in personalized event recommendations soon, but not in ${_joinHumanList(unaffectedDomains)} recommendations.${surfaceProgressTail == null ? '' : ' $surfaceProgressTail'}';
      }
      return 'I have taken your correction into account. You should notice this in personalized event recommendations soon.${surfaceProgressTail == null ? '' : ' $surfaceProgressTail'}';
    }
    if (record.currentAdoptionStatus ==
            GovernedLearningAdoptionStatus.acceptedForLearning &&
        _isCorrectionRecord(record)) {
      if (askedDomains.isNotEmpty) {
        return 'I have taken your correction into account, but I do not have a surfaced recommendation lane queued for it yet, so it has not changed ${_joinHumanList(askedDomains)} recommendations yet.${surfaceProgressTail == null ? '' : ' $surfaceProgressTail'}';
      }
      return 'I have taken your correction into account, but I do not have a surfaced recommendation lane queued for it yet.${surfaceProgressTail == null ? '' : ' $surfaceProgressTail'}';
    }
    if (record.domainHints.isEmpty) {
      if (askedDomains.isNotEmpty) {
        final askedScope = _joinHumanList(askedDomains);
        if (_isCorrectionRecord(record)) {
          return 'This specific record has not been used in a surfaced recommendation yet, so it has not changed $askedScope recommendations yet. Once it clears into runtime use, it can shape later recommendations in the same area without changing unrelated categories.';
        }
        return 'This specific record has not been used in a surfaced recommendation yet, so it has not changed $askedScope recommendations yet. It can shape later recommendations and explanations in the same domain, not unrelated categories.';
      }
      if (_isCorrectionRecord(record)) {
        return 'This specific record has not been used in a surfaced recommendation yet. Once it clears into runtime use, it can shape later recommendations in the same area without changing unrelated categories.';
      }
      return 'This specific record has not been used in a surfaced recommendation yet. It can shape later recommendations and explanations in the same domain, not unrelated categories.';
    }
    final scope = _joinHumanList(
      record.domainHints
          .take(3)
          .map(_humanizeToken)
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false),
    );
    if (askedDomains.isNotEmpty) {
      final askedScope = _joinHumanList(askedDomains);
      if (_isCorrectionRecord(record)) {
        return 'This specific record has not been used in a surfaced recommendation yet, so it has not changed $askedScope recommendations yet. Once it starts applying, you should notice the change mainly in $scope, not unrelated categories.';
      }
      return 'This specific record has not been used in a surfaced recommendation yet, so it has not changed $askedScope recommendations yet. When it does apply, it should shape recommendations and explanations about $scope, not unrelated categories.';
    }
    if (_isCorrectionRecord(record)) {
      return 'This specific record has not been used in a surfaced recommendation yet. Once it starts applying, you should notice the change mainly in $scope, not unrelated categories.';
    }
    return 'This specific record has not been used in a surfaced recommendation yet. When it does apply, it should shape recommendations and explanations about $scope, not unrelated categories.';
  }

  String _buildUncertaintyStatement(UserVisibleGovernedLearningRecord record) {
    if (record.futureSignalUseBlocked) {
      return 'Future signals of this type are blocked, so I will keep this record visible for inspection but stop learning from similar new signals.';
    }
    if (record.requiresHumanReview) {
      if (record.usageCount > 0) {
        return 'It is still bounded before any broader promotion, even though it has already influenced your local recommendations.';
      }
      if (_isCorrectionRecord(record)) {
        return 'I have that correction staged, but it is still bounded behind review, so you may not see the change immediately. If you do not notice it later, let me know.';
      }
      return 'It has not been broadly promoted yet, so this remains a bounded learning record rather than a permanent truth.';
    }
    if (record.pendingSurfaces.isNotEmpty) {
      final pending = _joinHumanList(
        record.pendingSurfaces
            .map(_humanizeLearningSurface)
            .toList(growable: false),
      );
      final inactive = _inactiveKnownSurfaceLabels(record);
      if (inactive.isNotEmpty) {
        return 'It is queued for $pending, but it is not active in ${_joinHumanList(inactive)} yet. If you do not notice the change later, let me know.';
      }
      return 'It is queued for $pending, but it has not surfaced there yet. If you do not notice the change later, let me know.';
    }
    if (record.currentAdoptionStatus ==
            GovernedLearningAdoptionStatus.acceptedForLearning &&
        _isCorrectionRecord(record)) {
      return 'I have that correction accepted into governed learning, but I do not have a surfaced recommendation lane queued for it yet.';
    }
    return 'If this was situational rather than durable, you can correct it, forget it, or tell me to stop using this signal.';
  }

  String? _buildLineageStatement(
    UserVisibleGovernedLearningRecord record, {
    String? userQuestion,
  }) {
    if (!_wantsLineageExplanation(userQuestion?.toLowerCase() ?? '')) {
      return null;
    }
    final latestUsage = _latestUsage(record);
    final recordLabel =
        record.title.isNotEmpty ? record.title : record.safeSummary;
    if (latestUsage != null) {
      final targetType =
          _humanizeTargetEntityType(latestUsage.targetEntityType);
      return 'If you want to inspect the exact trail, open your Data Center ledger and jump to the record about "$recordLabel". The latest visible $targetType recommendation it shaped was "${latestUsage.targetEntityTitle}".';
    }
    return 'If you want to inspect the exact trail, open your Data Center ledger and jump to the record about "$recordLabel". This one has not shown up in a surfaced recommendation yet.';
  }

  String _buildActionStatement(UserVisibleGovernedLearningRecord record) {
    final recentOutcome = _latestResolvedObservationOutcome(record);
    final supportsCorrection = record.availableActions
        .contains(UserGovernedLearningAction.correctRecord);
    final supportsForget = record.availableActions
        .contains(UserGovernedLearningAction.forgetRecord);
    final supportsStopUsing = record.availableActions
        .contains(UserGovernedLearningAction.stopUsingSignal);
    final fragments = <String>[];
    if (supportsCorrection) {
      fragments.add('correct it');
    }
    if (supportsForget) {
      fragments.add('forget it');
    }
    if (supportsStopUsing) {
      fragments.add('stop using that signal');
    }
    if (fragments.isEmpty) {
      return 'If you want, I can show more detail or open your Data Center ledger.';
    }
    if (recentOutcome ==
        GovernedLearningChatObservationOutcome.requestedFollowUp) {
      return 'The last time we talked about this, you wanted more trace detail. I can keep walking the record and recommendation trail step by step, ${_joinHumanList(fragments)}, or open your Data Center ledger.';
    }
    if (recentOutcome ==
        GovernedLearningChatObservationOutcome.correctedRecord) {
      final nonCorrectionFragments = fragments
          .where((entry) => entry != 'correct it')
          .toList(growable: false);
      if (nonCorrectionFragments.isEmpty) {
        return 'The last time we talked about this, you corrected it. If it is still off, I can help you correct it again or open your Data Center ledger.';
      }
      return 'The last time we talked about this, you corrected it. If it is still off, I can help you correct it again, ${_joinHumanList(nonCorrectionFragments)}, or open your Data Center ledger.';
    }
    return 'If you want, I can show more detail here, ${_joinHumanList(fragments)}, or open your Data Center ledger.';
  }

  bool _wantsLineageExplanation(String normalizedQuestion) {
    if (normalizedQuestion.isEmpty) {
      return false;
    }
    return normalizedQuestion.contains('came from') ||
        normalizedQuestion.contains('come from') ||
        normalizedQuestion.contains('show me what this') ||
        normalizedQuestion.contains('show me where this') ||
        normalizedQuestion.contains('show me the record') ||
        normalizedQuestion.contains('show me the recommendation') ||
        normalizedQuestion.contains('what recommendation') ||
        normalizedQuestion.contains('which recommendation') ||
        normalizedQuestion.contains('open the record') ||
        normalizedQuestion.contains('trace this');
  }

  String _describeSource(UserVisibleGovernedLearningRecord record) {
    final label = _humanizeToken(record.sourceLabel);
    final provider = _humanizeToken(record.sourceProvider);
    if (label.isEmpty && provider.isEmpty) {
      return 'a governed learning record';
    }
    if (provider.isEmpty || provider == label) {
      return label;
    }
    if (label.isEmpty) {
      return provider;
    }
    return '$label via $provider';
  }

  GovernedLearningUsageReceipt? _latestUsage(
    UserVisibleGovernedLearningRecord record,
  ) {
    if (record.recentUsageReceipts.isEmpty) {
      return null;
    }
    return record.recentUsageReceipts.first;
  }

  bool _isCorrectionRecord(UserVisibleGovernedLearningRecord record) {
    return record.convictionTier.contains('correction') ||
        record.sourceProvider.contains('correction');
  }

  GovernedLearningChatObservationOutcome? _latestResolvedObservationOutcome(
    UserVisibleGovernedLearningRecord record,
  ) {
    for (final observation in record.recentChatObservations) {
      if (observation.outcome !=
          GovernedLearningChatObservationOutcome.pending) {
        return observation.outcome;
      }
    }
    return null;
  }

  String _buildValidationTail(UserVisibleGovernedLearningRecord record) {
    for (final observation in record.recentChatObservations) {
      if (observation.validationStatus !=
          GovernedLearningChatObservationValidationStatus
              .validatedBySurfacedAdoption) {
        continue;
      }
      final surfaceLabel = observation.validatedSurface == null
          ? 'a surfaced recommendation lane'
          : _humanizeLearningSurface(observation.validatedSurface!);
      final targetLabel = observation.validatedTargetEntityTitle?.trim();
      if (targetLabel != null && targetLabel.isNotEmpty) {
        return ' A recent explanation about this record was later borne out when it surfaced in $surfaceLabel through "$targetLabel".';
      }
      return ' A recent explanation about this record was later borne out when it surfaced in $surfaceLabel.';
    }
    return '';
  }

  String _buildGovernanceTail(UserVisibleGovernedLearningRecord record) {
    final observation = _latestGovernedObservation(record);
    if (observation == null) {
      return '';
    }
    final stage = _humanizeGovernanceStage(observation.governanceStage);
    switch (observation.governanceStatus) {
      case GovernedLearningChatObservationGovernanceStatus.pending:
        return '';
      case GovernedLearningChatObservationGovernanceStatus
            .reinforcedByGovernance:
        return ' A later governance review reinforced this explanation${stage == null ? '' : ' during $stage'}.';
      case GovernedLearningChatObservationGovernanceStatus
            .constrainedByGovernance:
        return ' A later governance review constrained this explanation${stage == null ? '' : ' during $stage'} and held it for more evidence.';
      case GovernedLearningChatObservationGovernanceStatus
            .overruledByGovernance:
        return ' A later governance review overruled broader integration for this explanation${stage == null ? '' : ' during $stage'}.';
    }
  }

  GovernedLearningChatObservationReceipt? _latestGovernedObservation(
    UserVisibleGovernedLearningRecord record,
  ) {
    for (final observation in record.recentChatObservations) {
      if (observation.governanceStatus !=
          GovernedLearningChatObservationGovernanceStatus.pending) {
        return observation;
      }
    }
    return null;
  }

  String? _humanizeGovernanceStage(String? stage) {
    switch ((stage ?? '').trim()) {
      case 'upward_learning_review':
        return 'upward learning review';
      case 'reality_model_truth_review':
        return 'reality-model truth review';
      case 'reality_model_update_review':
        return 'bounded reality-model update review';
      default:
        final normalized = (stage ?? '').trim();
        if (normalized.isEmpty) {
          return null;
        }
        return _humanizeToken(normalized);
    }
  }

  bool _hasPendingSurface(
    UserVisibleGovernedLearningRecord record,
    String surface,
  ) {
    return record.pendingSurfaces.any(
      (candidate) =>
          _normalizeDomainKey(candidate) == _normalizeDomainKey(surface),
    );
  }

  String? _buildSurfaceProgressTail(UserVisibleGovernedLearningRecord record) {
    final active = record.surfacedSurfaces
        .map(_humanizeLearningSurface)
        .toList(growable: false);
    final pending = record.pendingSurfaces
        .map(_humanizeLearningSurface)
        .toList(growable: false);
    final inactive = _inactiveKnownSurfaceLabels(record);

    final fragments = <String>[];
    if (active.isNotEmpty) {
      fragments.add('It is already active in ${_joinHumanList(active)}');
    }
    if (pending.isNotEmpty) {
      fragments.add('it is queued for ${_joinHumanList(pending)}');
    }
    if (inactive.isNotEmpty) {
      fragments.add('it is not active in ${_joinHumanList(inactive)} yet');
    }

    if (fragments.isEmpty) {
      return null;
    }
    if (fragments.length == 1) {
      return '${fragments.single}.';
    }
    return '${fragments.first}, ${fragments.skip(1).join(', ')}.';
  }

  List<String> _inactiveKnownSurfaceLabels(
    UserVisibleGovernedLearningRecord record,
  ) {
    final activeOrPending = <String>{
      ...record.surfacedSurfaces.map(_normalizeDomainKey),
      ...record.pendingSurfaces.map(_normalizeDomainKey),
    };
    return _knownSurfacedRecommendationLanes
        .where(
          (surface) => !activeOrPending.contains(_normalizeDomainKey(surface)),
        )
        .map(_humanizeLearningSurface)
        .toList(growable: false);
  }

  String _humanizeLearningSurface(String surface) {
    switch (_normalizeDomainKey(surface)) {
      case 'events personalized':
        return 'personalized event recommendations';
      case 'explore events':
        return 'explore event recommendations';
      case 'explore spots':
        return 'explore spot recommendations';
      default:
        return _humanizeToken(surface);
    }
  }

  String _humanizeTargetEntityType(String value) {
    switch (value.trim().toLowerCase()) {
      case 'event':
        return 'event';
      case 'spot':
        return 'spot';
      case 'list':
        return 'list';
      case 'club':
        return 'club';
      case 'community':
        return 'community';
      default:
        return 'recommendation';
    }
  }

  List<String> _effectiveAppliedDomains(
    UserVisibleGovernedLearningRecord record,
  ) {
    final ordered = <String>[
      ...record.appliedDomains,
      ...record.recentUsageReceipts.expand(
        (receipt) => <String>[receipt.domainLabel, receipt.domainId],
      ),
    ];
    return _dedupeHumanizedValues(ordered);
  }

  List<String> _extractAskedAboutDomains(
    String? userQuestion,
    UserVisibleGovernedLearningRecord record,
  ) {
    final normalizedQuestion = userQuestion?.toLowerCase().trim() ?? '';
    if (normalizedQuestion.isEmpty) {
      return const <String>[];
    }

    final detected = <String>[];
    final candidateDomains = <String>[
      ...record.appliedDomains,
      ...record.domainHints,
      ...record.recentUsageReceipts.expand(
        (receipt) => <String>[receipt.domainLabel, receipt.domainId],
      ),
    ];
    for (final candidate in _dedupeHumanizedValues(candidateDomains)) {
      if (_questionMentionsDomain(normalizedQuestion, candidate)) {
        detected.add(candidate);
      }
    }

    const commonDomainAliases = <String, List<String>>{
      'nightlife': <String>[
        'nightlife',
        'late night',
        'late-night',
        'bar',
        'bars',
        'club',
        'clubs'
      ],
      'coffee': <String>['coffee', 'cafe', 'cafes', 'espresso'],
      'restaurant': <String>[
        'restaurant',
        'restaurants',
        'dinner',
        'lunch',
        'food'
      ],
      'brunch': <String>['brunch'],
      'breakfast': <String>['breakfast'],
      'music': <String>['music', 'concert', 'live music'],
      'outdoor': <String>['outdoor', 'outdoors', 'park', 'parks', 'hiking'],
    };
    commonDomainAliases.forEach((canonical, aliases) {
      if (detected.any((existing) => _domainMatches(existing, canonical))) {
        return;
      }
      if (aliases.any(normalizedQuestion.contains)) {
        detected.add(canonical);
      }
    });

    return _dedupeHumanizedValues(detected);
  }

  bool _questionMentionsDomain(String normalizedQuestion, String domain) {
    final normalizedDomain = _normalizeDomainKey(domain);
    if (normalizedDomain.isEmpty) {
      return false;
    }
    if (normalizedQuestion.contains(normalizedDomain)) {
      return true;
    }
    final tokens = normalizedDomain
        .split(' ')
        .where((token) => token.length >= 4)
        .toList(growable: false);
    return tokens.any(normalizedQuestion.contains);
  }

  bool _domainMatches(String left, String right) {
    final normalizedLeft = _normalizeDomainKey(left);
    final normalizedRight = _normalizeDomainKey(right);
    if (normalizedLeft.isEmpty || normalizedRight.isEmpty) {
      return false;
    }
    if (normalizedLeft == normalizedRight ||
        normalizedLeft.contains(normalizedRight) ||
        normalizedRight.contains(normalizedLeft)) {
      return true;
    }
    final leftTokens =
        normalizedLeft.split(' ').where((token) => token.length >= 4).toSet();
    final rightTokens =
        normalizedRight.split(' ').where((token) => token.length >= 4).toSet();
    return leftTokens.intersection(rightTokens).isNotEmpty;
  }

  List<String> _dedupeHumanizedValues(Iterable<String> rawValues) {
    final ordered = <String>[];
    final seen = <String>{};
    for (final rawValue in rawValues) {
      final humanized = _humanizeToken(rawValue);
      final key = _normalizeDomainKey(humanized);
      if (key.isEmpty || !seen.add(key)) {
        continue;
      }
      ordered.add(humanized);
    }
    return ordered;
  }

  String _normalizeDomainKey(String raw) {
    return _humanizeToken(raw)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _humanizeSummary(String summary) {
    final trimmed = summary.trim();
    const replacements = <MapEntry<String, String>>[
      MapEntry('The user wants ', 'you want '),
      MapEntry('The user prefers ', 'you prefer '),
      MapEntry('The user likes ', 'you like '),
      MapEntry('The user does not like ', 'you do not like '),
      MapEntry('The user reacted ', 'you reacted '),
      MapEntry('The user said ', 'you said '),
      MapEntry('The user asked ', 'you asked '),
      MapEntry('The user corrected ', 'you corrected '),
    ];
    for (final replacement in replacements) {
      if (trimmed.startsWith(replacement.key)) {
        return replacement.value + trimmed.substring(replacement.key.length);
      }
    }
    return trimmed;
  }

  String _ensureSentenceBody(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('.')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  String _humanizeToken(String raw) {
    return raw
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'\b\w'),
          (match) => match.group(0)?.toLowerCase() ?? '',
        )
        .trim();
  }

  String _joinHumanList(List<String> values) {
    final cleaned = values.where((entry) => entry.trim().isNotEmpty).toList();
    if (cleaned.isEmpty) {
      return '';
    }
    if (cleaned.length == 1) {
      return cleaned.first;
    }
    if (cleaned.length == 2) {
      return '${cleaned.first} and ${cleaned.last}';
    }
    return '${cleaned.sublist(0, cleaned.length - 1).join(', ')}, and ${cleaned.last}';
  }

  String _formatDate(DateTime value) {
    const monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final utc = value.toUtc();
    final month = monthNames[utc.month - 1];
    return '$month ${utc.day}, ${utc.year}';
  }
}
