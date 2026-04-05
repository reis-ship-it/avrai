// MIGRATION_SHIM: Legacy infrastructure oauth runtime retained temporarily.
/// Generic OAuth runtime contract.
///
/// Domain-specific providers (social, payments, etc.) should depend on this
/// infrastructure contract rather than re-implementing OAuth mechanics.
abstract class OAuthRuntime {
  /// Start listening for callback deep links.
  void startListening();

  /// Stop listening for callback deep links.
  void dispose();

  /// Returns initial callback link if app launched via deep link.
  Future<Uri?> getInitialLink();
}
