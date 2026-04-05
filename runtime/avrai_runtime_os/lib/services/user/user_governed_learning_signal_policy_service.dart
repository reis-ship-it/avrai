import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

class UserGovernedLearningSignalPolicyService {
  const UserGovernedLearningSignalPolicyService({
    required StorageService storageService,
  }) : _storageService = storageService;

  static const String _box = 'spots_user';
  static const String _blockedSignalKeyPrefix =
      'user_governed_learning_blocked_signals_v1';

  final StorageService _storageService;

  String buildSignalKey({
    required String convictionTier,
    required String sourceProvider,
  }) {
    return '$convictionTier|$sourceProvider';
  }

  Future<List<String>> listBlockedSignalKeys({
    required String ownerUserId,
  }) async {
    return _storageService.getStringList(
          '$_blockedSignalKeyPrefix:$ownerUserId',
          box: _box,
        ) ??
        const <String>[];
  }

  Future<bool> isSignalBlocked({
    required String ownerUserId,
    required String convictionTier,
    required String sourceProvider,
  }) async {
    final blockedSignals =
        await listBlockedSignalKeys(ownerUserId: ownerUserId);
    return blockedSignals.contains(
      buildSignalKey(
        convictionTier: convictionTier,
        sourceProvider: sourceProvider,
      ),
    );
  }

  Future<void> blockSignal({
    required String ownerUserId,
    required String convictionTier,
    required String sourceProvider,
  }) async {
    final blockedSignals =
        await listBlockedSignalKeys(ownerUserId: ownerUserId);
    final signalKey = buildSignalKey(
      convictionTier: convictionTier,
      sourceProvider: sourceProvider,
    );
    if (blockedSignals.contains(signalKey)) {
      return;
    }
    await _storageService.setStringList(
      '$_blockedSignalKeyPrefix:$ownerUserId',
      <String>[...blockedSignals, signalKey],
      box: _box,
    );
  }
}
