// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai_network/network/bloom_filter.dart';

class BloomLoopGuard {
  const BloomLoopGuard._();

  static bool allowForward({
    required OptimizedBloomFilter bloomFilter,
    required String messageHash,
    required String scope,
    required AppLogger logger,
    required String logName,
    String duplicateLabel = 'message',
  }) {
    if (bloomFilter.mightContain(messageHash)) {
      logger.debug(
        'Bloom filter: $duplicateLabel might be duplicate, skipping forward (scope: $scope)',
        tag: logName,
      );
      return false;
    }

    if (!bloomFilter.add(messageHash)) {
      logger.debug(
        'Bloom filter full, clearing and retrying (scope: $scope)',
        tag: logName,
      );
      bloomFilter.clear();
      bloomFilter.add(messageHash);
    }

    return true;
  }
}
