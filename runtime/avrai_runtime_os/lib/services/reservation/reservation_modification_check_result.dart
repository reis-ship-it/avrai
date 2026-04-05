// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
/// Result object for reservation modification eligibility checks.
class ModificationCheckResult {
  /// Whether the reservation can be modified.
  final bool canModify;

  /// Reason if cannot modify.
  final String? reason;

  /// Current modification count.
  final int? modificationCount;

  /// Remaining modifications allowed.
  final int? remainingModifications;

  const ModificationCheckResult({
    required this.canModify,
    this.reason,
    this.modificationCount,
    this.remainingModifications,
  });
}
