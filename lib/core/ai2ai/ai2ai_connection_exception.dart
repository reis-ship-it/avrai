class AI2AIConnectionException implements Exception {
  final String message;

  AI2AIConnectionException(this.message);

  @override
  String toString() => 'AI2AIConnectionException: $message';
}
