import 'dart:developer' as developer;

/// Logging levels used across the SPOTS codebase.
enum LogLevel { debug, info, warn, error }

/// Simple structured logger that writes to DevTools.
///
/// Note: Per SPOTS logging standards, this intentionally avoids `print()` in
/// production code. Use `developer.log()` for consistent structured logging.
class AppLogger {
  final String defaultTag;
  final LogLevel minimumLevel;

  const AppLogger({
    this.defaultTag = 'SPOTS',
    this.minimumLevel = LogLevel.debug,
  });

  void debug(String message, {String? tag}) =>
      _log(LogLevel.debug, message, tag: tag);

  void info(String message, {String? tag}) => _log(LogLevel.info, message, tag: tag);

  void warn(String message, {String? tag}) => _log(LogLevel.warn, message, tag: tag);

  // Backwards-compatible alias used by some call sites.
  void warning(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final composed = error != null ? '$message | error: $error' : message;
    _log(LogLevel.warn, composed, tag: tag, stackTrace: stackTrace);
  }

  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final composed = error != null ? '$message | error: $error' : message;
    _log(LogLevel.error, composed, tag: tag, stackTrace: stackTrace);
  }

  void _log(
    LogLevel level,
    String message, {
    String? tag,
    StackTrace? stackTrace,
  }) {
    if (level.index < minimumLevel.index) return;
    final name = tag ?? defaultTag;
    final prefix = switch (level) {
      LogLevel.debug => '[debug]',
      LogLevel.info => '[info]',
      LogLevel.warn => '[warn]',
      LogLevel.error => '[error]',
    };
    developer.log('$prefix $message', name: name, stackTrace: stackTrace);
  }
}

