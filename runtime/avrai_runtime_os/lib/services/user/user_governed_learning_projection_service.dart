import 'package:avrai_core/models/reality/governed_learning_adoption_receipt.dart';
import 'package:avrai_core/models/reality/governed_learning_chat_observation_receipt.dart';
import 'package:avrai_core/models/reality/governed_learning_envelope.dart';
import 'package:avrai_core/models/reality/governed_learning_usage_receipt.dart';
import 'package:avrai_core/models/reality/user_visible_governed_learning.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_adoption_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_chat_observation_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_control_contract.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_signal_policy_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_usage_service.dart';

class UserGovernedLearningProjectionService {
  const UserGovernedLearningProjectionService({
    required UniversalIntakeRepository intakeRepository,
    UserGovernedLearningSignalPolicyService? signalPolicyService,
    UserGovernedLearningAdoptionService? adoptionService,
    UserGovernedLearningChatObservationService? observationService,
    UserGovernedLearningUsageService? usageService,
  })  : _intakeRepository = intakeRepository,
        _signalPolicyService = signalPolicyService,
        _adoptionService = adoptionService,
        _observationService = observationService,
        _usageService = usageService;

  final UniversalIntakeRepository _intakeRepository;
  final UserGovernedLearningSignalPolicyService? _signalPolicyService;
  final UserGovernedLearningAdoptionService? _adoptionService;
  final UserGovernedLearningChatObservationService? _observationService;
  final UserGovernedLearningUsageService? _usageService;

  Future<List<UserVisibleGovernedLearningRecord>> listVisibleRecords({
    required String ownerUserId,
    int limit = 20,
  }) async {
    final sources = await _intakeRepository.getSourcesForOwner(ownerUserId);
    final adoptionReceiptsByEnvelope = await _loadAdoptionReceiptsByEnvelope(
      ownerUserId: ownerUserId,
    );
    final observationReceiptsByEnvelope =
        await _loadObservationReceiptsByEnvelope(
      ownerUserId: ownerUserId,
    );
    final receiptsByEnvelope = await _loadUsageReceiptsByEnvelope(
      ownerUserId: ownerUserId,
    );
    final records = <UserVisibleGovernedLearningRecord>[];
    final seenEnvelopeIds = <String>{};
    for (final source in sources) {
      final rawEnvelope = source.metadata['governedLearningEnvelope'];
      if (rawEnvelope is! Map) {
        continue;
      }
      final controlMetadata = _controlMetadata(source.metadata);
      if (controlMetadata[governedLearningControlStateKey] ==
          governedLearningControlStateForgotten) {
        continue;
      }
      final envelope = GovernedLearningEnvelope.fromJson(
        Map<String, dynamic>.from(rawEnvelope),
      );
      if (!seenEnvelopeIds.add(envelope.id)) {
        continue;
      }
      final futureSignalUseBlocked =
          controlMetadata[governedLearningControlFutureSignalUseBlockedKey] ==
                  true ||
              await (_signalPolicyService?.isSignalBlocked(
                    ownerUserId: ownerUserId,
                    convictionTier: envelope.convictionTier,
                    sourceProvider: envelope.sourceProvider,
                  ) ??
                  Future<bool>.value(false));
      records.add(
        _projectRecord(
          envelope,
          futureSignalUseBlocked: futureSignalUseBlocked,
          adoptionReceipts: adoptionReceiptsByEnvelope[envelope.id] ??
              const <GovernedLearningAdoptionReceipt>[],
          observationReceipts: observationReceiptsByEnvelope[envelope.id] ??
              const <GovernedLearningChatObservationReceipt>[],
          usageReceipts: receiptsByEnvelope[envelope.id] ??
              const <GovernedLearningUsageReceipt>[],
        ),
      );
    }
    records.sort((a, b) => b.stagedAtUtc.compareTo(a.stagedAtUtc));
    return records.take(limit).toList(growable: false);
  }

  Future<UserGovernedLearningExplanation> buildChatExplanation({
    required String ownerUserId,
    int maxRecords = 3,
    String? query,
  }) async {
    final selectionLimit = query != null && query.trim().isNotEmpty
        ? (maxRecords < 20 ? 20 : maxRecords)
        : maxRecords;
    final records = await listVisibleRecords(
      ownerUserId: ownerUserId,
      limit: selectionLimit,
    );
    if (records.isEmpty) {
      return const UserGovernedLearningExplanation(
        summary:
            'I do not have a recent governed learning record to show you yet.',
        details: <String>[
          'When I learn from your corrections, behavior, or explicit preference signals, I keep that learning bounded and reviewable.',
        ],
        suggestedActions: <UserGovernedLearningAction>[
          UserGovernedLearningAction.showDetails,
          UserGovernedLearningAction.openDataCenter,
        ],
      );
    }

    final selected = _resolveRelevantRecordFromRecords(
          records,
          query: query,
        ) ??
        records.first;
    final isLatestRecord = identical(selected, records.first) ||
        selected.envelopeId == records.first.envelopeId;
    final details = <String>[
      'I treated it as ${_humanizeConvictionTier(selected.convictionTier)}.',
      if (selected.domainHints.isNotEmpty)
        'It touched ${_joinHumanList(selected.domainHints.map(_humanizeToken).toList())}.',
      if (selected.requiresHumanReview)
        'It is still bounded behind human review before any broader promotion.',
      if (selected.referencedEntities.isNotEmpty)
        'The main entities in scope were ${_joinHumanList(selected.referencedEntities.take(3).toList())}.',
    ];

    return UserGovernedLearningExplanation(
      summary: isLatestRecord
          ? 'The latest thing I learned from you was: ${selected.safeSummary}'
          : 'The governed learning record that best matches your question is: ${selected.safeSummary}',
      details: details,
      records: records,
      selectedRecord: selected,
      suggestedActions: selected.availableActions,
    );
  }

  Future<UserVisibleGovernedLearningRecord?> resolveRelevantRecord({
    required String ownerUserId,
    String? query,
    int limit = 20,
  }) async {
    final records = await listVisibleRecords(
      ownerUserId: ownerUserId,
      limit: limit,
    );
    return _resolveRelevantRecordFromRecords(records, query: query);
  }

  UserVisibleGovernedLearningRecord _projectRecord(
    GovernedLearningEnvelope envelope, {
    required bool futureSignalUseBlocked,
    required List<GovernedLearningAdoptionReceipt> adoptionReceipts,
    required List<GovernedLearningChatObservationReceipt> observationReceipts,
    required List<GovernedLearningUsageReceipt> usageReceipts,
  }) {
    final availableActions = <UserGovernedLearningAction>[
      UserGovernedLearningAction.showDetails,
      UserGovernedLearningAction.correctRecord,
      UserGovernedLearningAction.forgetRecord,
      if (!futureSignalUseBlocked) UserGovernedLearningAction.stopUsingSignal,
      UserGovernedLearningAction.openDataCenter,
    ];
    final surfacedSurfaces = _extractSurfacedSurfaces(adoptionReceipts);
    final pendingSurfaces = _extractPendingSurfaces(
      adoptionReceipts,
      surfacedSurfaces: surfacedSurfaces,
    );
    return UserVisibleGovernedLearningRecord(
      envelopeId: envelope.id,
      sourceId: envelope.sourceId,
      title: envelope.title,
      safeSummary: envelope.safeSummary,
      sourceLabel: envelope.sourceLabel,
      sourceProvider: envelope.sourceProvider,
      convictionTier: envelope.convictionTier,
      occurredAtUtc: envelope.occurredAtUtc,
      stagedAtUtc: envelope.stagedAtUtc,
      requiresHumanReview: envelope.requiresHumanReview,
      domainHints: envelope.domainHints,
      referencedEntities: envelope.referencedEntities,
      kernelGraphStatus: envelope.kernelGraphStatus,
      futureSignalUseBlocked: futureSignalUseBlocked,
      usageCount: usageReceipts.length,
      lastUsedAtUtc:
          usageReceipts.isEmpty ? null : usageReceipts.first.usedAtUtc,
      appliedDomains: _extractAppliedDomains(usageReceipts),
      recentUsageReceipts: usageReceipts.take(5).toList(growable: false),
      currentAdoptionStatus: futureSignalUseBlocked
          ? null
          : _deriveCurrentAdoptionStatus(adoptionReceipts),
      pendingSurfaces:
          futureSignalUseBlocked ? const <String>[] : pendingSurfaces,
      surfacedSurfaces:
          futureSignalUseBlocked ? const <String>[] : surfacedSurfaces,
      firstSurfacedAtUtc: futureSignalUseBlocked
          ? null
          : _deriveFirstSurfacedAtUtc(adoptionReceipts),
      recentAdoptionReceipts: adoptionReceipts.take(5).toList(growable: false),
      recentChatObservations:
          observationReceipts.take(5).toList(growable: false),
      availableActions: availableActions,
    );
  }

  Future<Map<String, List<GovernedLearningAdoptionReceipt>>>
      _loadAdoptionReceiptsByEnvelope({
    required String ownerUserId,
  }) async {
    final adoptionService = _adoptionService;
    if (adoptionService == null) {
      return const <String, List<GovernedLearningAdoptionReceipt>>{};
    }
    final receipts = await adoptionService.listReceiptsForUser(
      ownerUserId: ownerUserId,
      limit: 200,
    );
    final grouped = <String, List<GovernedLearningAdoptionReceipt>>{};
    for (final receipt in receipts) {
      grouped
          .putIfAbsent(
            receipt.envelopeId,
            () => <GovernedLearningAdoptionReceipt>[],
          )
          .add(receipt);
    }
    for (final entry in grouped.values) {
      entry.sort(
        (left, right) => right.recordedAtUtc.compareTo(left.recordedAtUtc),
      );
    }
    return grouped;
  }

  Future<Map<String, List<GovernedLearningChatObservationReceipt>>>
      _loadObservationReceiptsByEnvelope({
    required String ownerUserId,
  }) async {
    final observationService = _observationService;
    if (observationService == null) {
      return const <String, List<GovernedLearningChatObservationReceipt>>{};
    }
    final receipts = await observationService.listReceiptsForUser(
      ownerUserId: ownerUserId,
      limit: 200,
    );
    final grouped = <String, List<GovernedLearningChatObservationReceipt>>{};
    for (final receipt in receipts) {
      grouped
          .putIfAbsent(
            receipt.envelopeId,
            () => <GovernedLearningChatObservationReceipt>[],
          )
          .add(receipt);
    }
    for (final entry in grouped.values) {
      entry.sort(
        (left, right) => right.recordedAtUtc.compareTo(left.recordedAtUtc),
      );
    }
    return grouped;
  }

  Future<Map<String, List<GovernedLearningUsageReceipt>>>
      _loadUsageReceiptsByEnvelope({
    required String ownerUserId,
  }) async {
    final usageService = _usageService;
    if (usageService == null) {
      return const <String, List<GovernedLearningUsageReceipt>>{};
    }
    final receipts = await usageService.listReceiptsForUser(
      ownerUserId: ownerUserId,
      limit: 200,
    );
    final grouped = <String, List<GovernedLearningUsageReceipt>>{};
    for (final receipt in receipts) {
      grouped
          .putIfAbsent(
            receipt.envelopeId,
            () => <GovernedLearningUsageReceipt>[],
          )
          .add(receipt);
    }
    for (final entry in grouped.values) {
      entry.sort((left, right) => right.usedAtUtc.compareTo(left.usedAtUtc));
    }
    return grouped;
  }

  List<String> _extractAppliedDomains(
    List<GovernedLearningUsageReceipt> receipts,
  ) {
    final ordered = <String>[];
    final seen = <String>{};
    for (final receipt in receipts) {
      final label = receipt.domainLabel.trim();
      if (label.isEmpty || !seen.add(label)) {
        continue;
      }
      ordered.add(label);
    }
    return ordered;
  }

  GovernedLearningAdoptionStatus? _deriveCurrentAdoptionStatus(
    List<GovernedLearningAdoptionReceipt> receipts,
  ) {
    if (receipts.any(
      (receipt) =>
          receipt.status ==
          GovernedLearningAdoptionStatus.firstSurfacedOnSurface,
    )) {
      return GovernedLearningAdoptionStatus.firstSurfacedOnSurface;
    }
    if (receipts.any(
      (receipt) =>
          receipt.status ==
          GovernedLearningAdoptionStatus.queuedForSurfaceRefresh,
    )) {
      return GovernedLearningAdoptionStatus.queuedForSurfaceRefresh;
    }
    if (receipts.any(
      (receipt) =>
          receipt.status == GovernedLearningAdoptionStatus.acceptedForLearning,
    )) {
      return GovernedLearningAdoptionStatus.acceptedForLearning;
    }
    return null;
  }

  List<String> _extractPendingSurfaces(
    List<GovernedLearningAdoptionReceipt> receipts, {
    required List<String> surfacedSurfaces,
  }) {
    final surfaced = surfacedSurfaces.toSet();
    final ordered = <String>[];
    final seen = <String>{};
    for (final receipt in receipts) {
      if (receipt.status !=
          GovernedLearningAdoptionStatus.queuedForSurfaceRefresh) {
        continue;
      }
      final surface = receipt.surface?.trim() ?? '';
      if (surface.isEmpty || surfaced.contains(surface) || !seen.add(surface)) {
        continue;
      }
      ordered.add(surface);
    }
    return ordered;
  }

  List<String> _extractSurfacedSurfaces(
    List<GovernedLearningAdoptionReceipt> receipts,
  ) {
    final ordered = <String>[];
    final seen = <String>{};
    for (final receipt in receipts) {
      if (receipt.status !=
          GovernedLearningAdoptionStatus.firstSurfacedOnSurface) {
        continue;
      }
      final surface = receipt.surface?.trim() ?? '';
      if (surface.isEmpty || !seen.add(surface)) {
        continue;
      }
      ordered.add(surface);
    }
    return ordered;
  }

  DateTime? _deriveFirstSurfacedAtUtc(
    List<GovernedLearningAdoptionReceipt> receipts,
  ) {
    DateTime? earliest;
    for (final receipt in receipts) {
      if (receipt.status !=
          GovernedLearningAdoptionStatus.firstSurfacedOnSurface) {
        continue;
      }
      if (earliest == null || receipt.recordedAtUtc.isBefore(earliest)) {
        earliest = receipt.recordedAtUtc;
      }
    }
    return earliest;
  }

  Map<String, dynamic> _controlMetadata(Map<String, dynamic> metadata) {
    final raw = metadata[governedLearningControlMetadataKey];
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const <String, dynamic>{};
  }

  UserVisibleGovernedLearningRecord? _resolveRelevantRecordFromRecords(
    List<UserVisibleGovernedLearningRecord> records, {
    String? query,
  }) {
    if (records.isEmpty) {
      return null;
    }
    final normalizedQuery = _normalizeText(query);
    final significantTerms = _extractSignificantTerms(normalizedQuery);
    if (significantTerms.isEmpty) {
      return records.first;
    }
    _RecordSelectionScore? bestMatch;
    for (var index = 0; index < records.length; index++) {
      final record = records[index];
      final score = _scoreRecord(
        record,
        normalizedQuery: normalizedQuery,
        significantTerms: significantTerms,
        recencyIndex: index,
      );
      if (!score.hasExplicitMatch) {
        continue;
      }
      if (bestMatch == null || score.score > bestMatch.score) {
        bestMatch = score;
      }
    }
    return bestMatch?.record ?? records.first;
  }

  _RecordSelectionScore _scoreRecord(
    UserVisibleGovernedLearningRecord record, {
    required String normalizedQuery,
    required List<String> significantTerms,
    required int recencyIndex,
  }) {
    var score = recencyIndex == 0 ? 3 : 0;
    var hasExplicitMatch = false;
    final title = _normalizeText(record.title);
    final summary = _normalizeText(record.safeSummary);
    final sourceLabel = _normalizeText(record.sourceLabel);
    final sourceProvider = _normalizeText(record.sourceProvider);
    final entities = record.referencedEntities.map(_normalizeText).toList();
    final domains = record.domainHints.map(_normalizeText).toList();
    final searchableFields = <String>[
      title,
      summary,
      sourceLabel,
      sourceProvider,
      ...entities,
      ...domains,
    ];

    for (final entity in entities) {
      if (entity.isNotEmpty &&
          (normalizedQuery.contains(entity) ||
              entity.contains(normalizedQuery))) {
        score += 14;
        hasExplicitMatch = true;
      }
    }

    if (significantTerms.length >= 2) {
      final phrase = significantTerms.join(' ');
      if (phrase.trim().isNotEmpty &&
          searchableFields.any((field) => field.contains(phrase))) {
        score += 10;
        hasExplicitMatch = true;
      }
    }

    for (final term in significantTerms) {
      if (term.isEmpty) {
        continue;
      }
      if (entities.any((field) => field.contains(term))) {
        score += 6;
        hasExplicitMatch = true;
      }
      if (title.contains(term)) {
        score += 5;
        hasExplicitMatch = true;
      }
      if (summary.contains(term)) {
        score += 4;
        hasExplicitMatch = true;
      }
      if (domains.any((field) => field.contains(term))) {
        score += 3;
        hasExplicitMatch = true;
      }
      if (sourceLabel.contains(term) || sourceProvider.contains(term)) {
        score += 3;
        hasExplicitMatch = true;
      }
    }

    return _RecordSelectionScore(
      record: record,
      score: score,
      hasExplicitMatch: hasExplicitMatch,
    );
  }

  String _humanizeConvictionTier(String convictionTier) {
    switch (convictionTier) {
      case 'personal_agent_human_observation':
        return 'a personal human observation';
      case 'explicit_correction_signal':
        return 'an explicit correction';
      case 'ai2ai_explicit_correction_signal':
        return 'an AI2AI explicit correction';
      case 'ai2ai_peer_signal':
        return 'an AI2AI peer signal';
      case 'recommendation_feedback_correction_signal':
        return 'a recommendation feedback correction';
      default:
        return _humanizeToken(convictionTier);
    }
  }

  String _humanizeToken(String value) {
    return value.replaceAll('_', ' ').trim();
  }

  String _normalizeText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '';
    }
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _extractSignificantTerms(String normalizedQuery) {
    if (normalizedQuery.isEmpty) {
      return const <String>[];
    }
    const stopWords = <String>{
      'a',
      'about',
      'an',
      'and',
      'did',
      'do',
      'for',
      'forget',
      'from',
      'have',
      'how',
      'i',
      'infer',
      'it',
      'know',
      'latest',
      'learn',
      'learned',
      'learning',
      'me',
      'my',
      'of',
      'record',
      'recent',
      'show',
      'signal',
      'stop',
      'store',
      'stored',
      'that',
      'the',
      'this',
      'to',
      'update',
      'using',
      'what',
      'why',
      'you',
    };
    return normalizedQuery
        .split(' ')
        .where((term) => term.length >= 3 && !stopWords.contains(term))
        .toList(growable: false);
  }

  String _joinHumanList(List<String> values) {
    if (values.isEmpty) {
      return '';
    }
    if (values.length == 1) {
      return values.first;
    }
    if (values.length == 2) {
      return '${values.first} and ${values.last}';
    }
    final head = values.sublist(0, values.length - 1).join(', ');
    return '$head, and ${values.last}';
  }
}

class _RecordSelectionScore {
  const _RecordSelectionScore({
    required this.record,
    required this.score,
    required this.hasExplicitMatch,
  });

  final UserVisibleGovernedLearningRecord record;
  final int score;
  final bool hasExplicitMatch;
}
