import 'dart:convert';

import 'package:avrai_core/models/reality/governed_learning_chat_observation_receipt.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

class UserGovernedLearningChatObservationService {
  const UserGovernedLearningChatObservationService({
    required StorageService storageService,
    Duration retentionWindow = const Duration(days: 30),
    int maxReceiptsPerUser = 500,
  })  : _storageService = storageService,
        _retentionWindow = retentionWindow,
        _maxReceiptsPerUser = maxReceiptsPerUser;

  static const String _box = 'spots_user';
  static const String _receiptKeyPrefix =
      'user_governed_learning_chat_observations_v1';

  final StorageService _storageService;
  final Duration _retentionWindow;
  final int _maxReceiptsPerUser;

  Future<void> recordReceipts(
    List<GovernedLearningChatObservationReceipt> receipts,
  ) async {
    if (receipts.isEmpty) {
      return;
    }
    final grouped = <String, List<GovernedLearningChatObservationReceipt>>{};
    for (final receipt in receipts) {
      grouped
          .putIfAbsent(
            receipt.ownerUserId,
            () => <GovernedLearningChatObservationReceipt>[],
          )
          .add(receipt);
    }
    for (final entry in grouped.entries) {
      final existing = await listReceiptsForUser(
        ownerUserId: entry.key,
        limit: _maxReceiptsPerUser,
      );
      final byId = <String, GovernedLearningChatObservationReceipt>{
        for (final receipt in existing) receipt.id: receipt,
      };
      for (final receipt in entry.value) {
        byId[receipt.id] = receipt;
      }
      await _persistReceipts(
        ownerUserId: entry.key,
        receipts: byId.values.toList(growable: false),
      );
    }
  }

  Future<List<GovernedLearningChatObservationReceipt>> listReceiptsForUser({
    required String ownerUserId,
    int limit = 100,
  }) async {
    final raw = _storageService.getStringList(
          _storageKey(ownerUserId),
          box: _box,
        ) ??
        const <String>[];
    final receipts = <GovernedLearningChatObservationReceipt>[];
    for (final item in raw) {
      try {
        receipts.add(
          GovernedLearningChatObservationReceipt.fromJson(
            Map<String, dynamic>.from(jsonDecode(item) as Map),
          ),
        );
      } catch (_) {
        // Ignore malformed receipt payloads.
      }
    }
    receipts.sort(
      (left, right) => right.recordedAtUtc.compareTo(left.recordedAtUtc),
    );
    if (receipts.length <= limit) {
      return receipts;
    }
    return receipts.sublist(0, limit);
  }

  Future<List<GovernedLearningChatObservationReceipt>> listReceiptsForEnvelope({
    required String ownerUserId,
    required String envelopeId,
    int limit = 20,
  }) async {
    final receipts = await listReceiptsForUser(
      ownerUserId: ownerUserId,
      limit: _maxReceiptsPerUser,
    );
    final matches = receipts
        .where((receipt) => receipt.envelopeId == envelopeId)
        .toList(growable: false);
    if (matches.length <= limit) {
      return matches;
    }
    return matches.sublist(0, limit);
  }

  Future<GovernedLearningChatObservationReceipt?> markLatestPendingOutcome({
    required String ownerUserId,
    required GovernedLearningChatObservationOutcome outcome,
    String? envelopeId,
    Duration maxPendingAge = const Duration(days: 7),
  }) async {
    final existing = await listReceiptsForUser(
      ownerUserId: ownerUserId,
      limit: _maxReceiptsPerUser,
    );
    final now = DateTime.now().toUtc();
    GovernedLearningChatObservationReceipt? updatedReceipt;
    final updated = existing.map((receipt) {
      if (updatedReceipt != null) {
        return receipt;
      }
      final matchesEnvelope =
          envelopeId == null || receipt.envelopeId == envelopeId;
      final isPending =
          receipt.outcome == GovernedLearningChatObservationOutcome.pending;
      final isFresh =
          now.difference(receipt.recordedAtUtc).abs() <= maxPendingAge;
      if (matchesEnvelope && isPending && isFresh) {
        updatedReceipt = receipt.copyWith(
          outcome: outcome,
          resolvedAtUtc: now,
        );
        return updatedReceipt!;
      }
      return receipt;
    }).toList(growable: false);
    if (updatedReceipt == null) {
      return null;
    }
    await _persistReceipts(ownerUserId: ownerUserId, receipts: updated);
    return updatedReceipt;
  }

  Future<GovernedLearningChatObservationReceipt?>
      markLatestUnvalidatedAsSurfacedAdoption({
    required String ownerUserId,
    required String envelopeId,
    required DateTime validatedAtUtc,
    required String surface,
    String? targetEntityTitle,
    Duration maxObservationAge = const Duration(days: 30),
  }) async {
    final existing = await listReceiptsForUser(
      ownerUserId: ownerUserId,
      limit: _maxReceiptsPerUser,
    );
    final now = validatedAtUtc.toUtc();
    GovernedLearningChatObservationReceipt? updatedReceipt;
    final updated = existing.map((receipt) {
      if (updatedReceipt != null) {
        return receipt;
      }
      final matchesEnvelope = receipt.envelopeId == envelopeId;
      final isFresh =
          now.difference(receipt.recordedAtUtc).abs() <= maxObservationAge;
      final notYetValidated = receipt.validationStatus ==
          GovernedLearningChatObservationValidationStatus.pending;
      if (matchesEnvelope && isFresh && notYetValidated) {
        updatedReceipt = receipt.copyWith(
          validationStatus: GovernedLearningChatObservationValidationStatus
              .validatedBySurfacedAdoption,
          validatedAtUtc: now,
          validatedSurface: surface,
          validatedTargetEntityTitle: targetEntityTitle,
        );
        return updatedReceipt!;
      }
      return receipt;
    }).toList(growable: false);
    if (updatedReceipt == null) {
      return null;
    }
    await _persistReceipts(ownerUserId: ownerUserId, receipts: updated);
    return updatedReceipt;
  }

  Future<GovernedLearningChatObservationReceipt?>
      markLatestWithoutGovernanceAsGoverned({
    required String ownerUserId,
    required String envelopeId,
    required GovernedLearningChatObservationGovernanceStatus governanceStatus,
    required DateTime governanceUpdatedAtUtc,
    required String governanceStage,
    required String governanceReason,
    Duration maxObservationAge = const Duration(days: 45),
  }) async {
    final existing = await listReceiptsForUser(
      ownerUserId: ownerUserId,
      limit: _maxReceiptsPerUser,
    );
    final now = governanceUpdatedAtUtc.toUtc();
    GovernedLearningChatObservationReceipt? updatedReceipt;
    final updated = existing.map((receipt) {
      if (updatedReceipt != null) {
        return receipt;
      }
      final matchesEnvelope = receipt.envelopeId == envelopeId;
      final isFresh =
          now.difference(receipt.recordedAtUtc).abs() <= maxObservationAge;
      final governancePending = receipt.governanceStatus ==
          GovernedLearningChatObservationGovernanceStatus.pending;
      if (matchesEnvelope && isFresh && governancePending) {
        final nextAttentionStatus = _attentionStatusForGovernance(
          outcome: receipt.outcome,
          governanceStatus: governanceStatus,
        );
        updatedReceipt = receipt.copyWith(
          governanceStatus: governanceStatus,
          governanceUpdatedAtUtc: now,
          governanceStage: governanceStage,
          governanceReason: governanceReason,
          attentionStatus: nextAttentionStatus,
          attentionUpdatedAtUtc: nextAttentionStatus ==
                  GovernedLearningChatObservationAttentionStatus.pending
              ? receipt.attentionUpdatedAtUtc
              : now,
        );
        return updatedReceipt!;
      }
      return receipt;
    }).toList(growable: false);
    if (updatedReceipt == null) {
      return null;
    }
    await _persistReceipts(ownerUserId: ownerUserId, receipts: updated);
    return updatedReceipt;
  }

  String _storageKey(String ownerUserId) => '$_receiptKeyPrefix:$ownerUserId';

  GovernedLearningChatObservationAttentionStatus _attentionStatusForGovernance({
    required GovernedLearningChatObservationOutcome outcome,
    required GovernedLearningChatObservationGovernanceStatus governanceStatus,
  }) {
    final isPressureOutcome = outcome ==
            GovernedLearningChatObservationOutcome.requestedFollowUp ||
        outcome == GovernedLearningChatObservationOutcome.correctedRecord ||
        outcome == GovernedLearningChatObservationOutcome.forgotRecord ||
        outcome == GovernedLearningChatObservationOutcome.stoppedUsingSignal;
    if (!isPressureOutcome) {
      return GovernedLearningChatObservationAttentionStatus.pending;
    }
    return switch (governanceStatus) {
      GovernedLearningChatObservationGovernanceStatus.reinforcedByGovernance =>
        GovernedLearningChatObservationAttentionStatus.satisfiedByGovernance,
      GovernedLearningChatObservationGovernanceStatus.constrainedByGovernance ||
      GovernedLearningChatObservationGovernanceStatus.overruledByGovernance =>
        GovernedLearningChatObservationAttentionStatus.clearedByGovernance,
      GovernedLearningChatObservationGovernanceStatus.pending =>
        GovernedLearningChatObservationAttentionStatus.pending,
    };
  }

  Future<void> _persistReceipts({
    required String ownerUserId,
    required List<GovernedLearningChatObservationReceipt> receipts,
  }) async {
    final threshold = DateTime.now().toUtc().subtract(_retentionWindow);
    final retained = receipts
        .where((receipt) => !receipt.recordedAtUtc.isBefore(threshold))
        .toList()
      ..sort(
        (left, right) => left.recordedAtUtc.compareTo(right.recordedAtUtc),
      );
    final capped = retained.length <= _maxReceiptsPerUser
        ? retained
        : retained.sublist(retained.length - _maxReceiptsPerUser);
    await _storageService.setStringList(
      _storageKey(ownerUserId),
      capped.map((receipt) => jsonEncode(receipt.toJson())).toList(),
      box: _box,
    );
  }
}
