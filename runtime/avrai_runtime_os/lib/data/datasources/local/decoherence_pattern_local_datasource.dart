import 'package:avrai_core/models/quantum/decoherence_pattern.dart';

/// Local Data Source Interface for Decoherence Patterns
///
/// Defines the contract for local storage of decoherence patterns.
abstract class DecoherencePatternLocalDataSource {
  /// Get decoherence pattern by user ID
  Future<DecoherencePattern?> getByUserId(String userId);

  /// Save decoherence pattern
  Future<void> save(DecoherencePattern pattern);

  /// Get all patterns
  Future<List<DecoherencePattern>> getAll();

  /// Delete pattern by user ID
  Future<void> delete(String userId);
}
