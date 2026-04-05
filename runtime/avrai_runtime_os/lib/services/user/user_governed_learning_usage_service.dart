import 'dart:convert';

import 'package:avrai_core/models/reality/governed_learning_usage_receipt.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

class UserGovernedLearningUsageService {
  const UserGovernedLearningUsageService({
    required StorageService storageService,
    Duration retentionWindow = const Duration(days: 30),
    int maxReceiptsPerUser = 500,
  })  : _storageService = storageService,
        _retentionWindow = retentionWindow,
        _maxReceiptsPerUser = maxReceiptsPerUser;

  static const String _box = 'spots_user';
  static const String _receiptKeyPrefix =
      'user_governed_learning_usage_receipts_v1';

  final StorageService _storageService;
  final Duration _retentionWindow;
  final int _maxReceiptsPerUser;

  Future<void> recordReceipts(
    List<GovernedLearningUsageReceipt> receipts,
  ) async {
    if (receipts.isEmpty) {
      return;
    }
    final grouped = <String, List<GovernedLearningUsageReceipt>>{};
    for (final receipt in receipts) {
      grouped
          .putIfAbsent(
              receipt.ownerUserId, () => <GovernedLearningUsageReceipt>[])
          .add(receipt);
    }
    for (final entry in grouped.entries) {
      final existing = await listReceiptsForUser(
        ownerUserId: entry.key,
        limit: _maxReceiptsPerUser,
      );
      final byId = <String, GovernedLearningUsageReceipt>{
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

  Future<List<GovernedLearningUsageReceipt>> listReceiptsForUser({
    required String ownerUserId,
    int limit = 100,
  }) async {
    final raw = _storageService.getStringList(
          _storageKey(ownerUserId),
          box: _box,
        ) ??
        const <String>[];
    final receipts = <GovernedLearningUsageReceipt>[];
    for (final item in raw) {
      try {
        receipts.add(
          GovernedLearningUsageReceipt.fromJson(
            Map<String, dynamic>.from(jsonDecode(item) as Map),
          ),
        );
      } catch (_) {
        // Ignore malformed receipt payloads.
      }
    }
    receipts.sort((left, right) => right.usedAtUtc.compareTo(left.usedAtUtc));
    if (receipts.length <= limit) {
      return receipts;
    }
    return receipts.sublist(0, limit);
  }

  Future<List<GovernedLearningUsageReceipt>> listReceiptsForEnvelope({
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

  String _storageKey(String ownerUserId) => '$_receiptKeyPrefix:$ownerUserId';

  Future<void> _persistReceipts({
    required String ownerUserId,
    required List<GovernedLearningUsageReceipt> receipts,
  }) async {
    final threshold = DateTime.now().toUtc().subtract(_retentionWindow);
    final retained = receipts
        .where((receipt) => !receipt.usedAtUtc.isBefore(threshold))
        .toList()
      ..sort((left, right) => left.usedAtUtc.compareTo(right.usedAtUtc));
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
