import 'package:avrai_core/models/payment/tax_profile.dart';
import 'package:get_storage/get_storage.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/data/repositories/repository_patterns.dart';

/// Tax Profile Repository
///
/// Handles persistence of tax profiles using Sembast database.
/// Local-only repository - no remote operations.
class TaxProfileRepository extends SimplifiedRepositoryBase {
  static const AppLogger _logger =
      AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  static const String _storeName = 'tax_profiles';

  TaxProfileRepository()
      : super(connectivity: null); // Local-only, no connectivity needed

  GetStorage get _box => GetStorage(_storeName);

  /// Save tax profile
  Future<void> saveTaxProfile(TaxProfile profile) async {
    return executeLocalOnly(
      localOperation: () async {
        await _box.write('tax_profile_${profile.userId}', profile.toJson());

        // Maintain a list of all profile user IDs for iteration
        final List<dynamic> allIds =
            _box.read<List<dynamic>>('all_profile_ids') ?? [];
        if (!allIds.contains(profile.userId)) {
          allIds.add(profile.userId);
          await _box.write('all_profile_ids', allIds);
        }

        _logger.info('Tax profile saved: ${profile.userId}',
            tag: 'TaxProfileRepository');
      },
    );
  }

  /// Get tax profile by user ID
  Future<TaxProfile?> getTaxProfile(String userId) async {
    return executeLocalOnly<TaxProfile?>(
      localOperation: () async {
        final data = _box.read<Map<String, dynamic>>('tax_profile_$userId');
        if (data == null) return null;
        return TaxProfile.fromJson(data);
      },
    );
  }

  /// Get all tax profiles
  Future<List<TaxProfile>> getAllTaxProfiles() async {
    return executeLocalOnly<List<TaxProfile>>(
      localOperation: () async {
        final List<dynamic> allIds =
            _box.read<List<dynamic>>('all_profile_ids') ?? [];
        final profiles = <TaxProfile>[];

        for (final userId in allIds) {
          final data = _box.read<Map<String, dynamic>>('tax_profile_$userId');
          if (data != null) {
            profiles.add(TaxProfile.fromJson(data));
          }
        }

        return profiles;
      },
    );
  }

  /// Get users with W-9 submitted
  Future<List<String>> getUsersWithW9() async {
    return executeLocalOnly<List<String>>(
      localOperation: () async {
        final List<dynamic> allIds =
            _box.read<List<dynamic>>('all_profile_ids') ?? [];
        final results = <String>[];

        for (final userId in allIds) {
          final data = _box.read<Map<String, dynamic>>('tax_profile_$userId');
          if (data != null && data['w9Submitted'] == true) {
            results.add(userId as String);
          }
        }

        return results;
      },
    );
  }

  /// Delete tax profile
  Future<void> deleteTaxProfile(String userId) async {
    return executeLocalOnly(
      localOperation: () async {
        await _box.remove('tax_profile_$userId');

        final List<dynamic> allIds =
            _box.read<List<dynamic>>('all_profile_ids') ?? [];
        allIds.remove(userId);
        await _box.write('all_profile_ids', allIds);

        _logger.info('Tax profile deleted: $userId',
            tag: 'TaxProfileRepository');
      },
    );
  }
}
