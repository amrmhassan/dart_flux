/// Abstract interface for a customizable logging system within the Flux framework.
/// Implement this interface to define how logs should be handled and output.
abstract class FluxLoggerInterface {
  /// Controls whether logging is enabled or not.
  /// Can be toggled at runtime to disable all logging globally.
  bool loggerEnabled = true;

  /// Logs a raw message directly without any formatting or processing.
  /// Useful for debugging low-level behavior or outputting unprocessed logs.
  ///
  /// [msg] - The message or object to log.
  /// [level] - The severity level of the log (default is [LogLevel.info]).
  /// [tag] - Optional category or source tag for grouping logs.
  /// [signature] - Optional identifier to trace log origin (e.g., class, method).
  void rawLog(
    Object msg, {
    LogLevel level = LogLevel.info,
    String? tag,
    String? signature,
  });

  /// Logs a message with possible formatting, prefixes, or metadata.
  /// Intended for structured and consistent logging across the application.
  ///
  /// [msg] - The message or object to log.
  /// [level] - The severity level of the log (default is [LogLevel.info]).
  /// [tag] - Optional category or source tag for grouping logs.
  /// [signature] - Optional identifier to trace log origin (e.g., class, method).
  void log(
    Object msg, {
    LogLevel level = LogLevel.info,
    String? tag,
    String? signature,
  });
}

/// Defines the severity level of log messages.
/// This is useful for filtering logs based on importance.
enum LogLevel {
  /// Fine-grained information useful for debugging.
  debug,

  /// General runtime information, typical for normal operation.
  info,

  /// Something unexpected happened, but the app can continue.
  warning,

  /// A serious issue occurred that might affect stability.
  error,

  /// A critical problem that may cause the app to crash or become unusable.
  fatal,
}
