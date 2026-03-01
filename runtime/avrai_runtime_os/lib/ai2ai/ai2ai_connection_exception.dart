// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
class AI2AIConnectionException implements Exception {
  final String message;

  AI2AIConnectionException(this.message);

  @override
  String toString() => 'AI2AIConnectionException: $message';
}
