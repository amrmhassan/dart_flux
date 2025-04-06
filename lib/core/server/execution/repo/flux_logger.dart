import 'package:dart_flux/constants/date_constants.dart';
import 'package:dart_flux/core/server/execution/interface/flux_logger_interface.dart';

/// A simple implementation of [FluxLoggerInterface] that logs messages to the console using `print()`.
/// This is mainly intended for development and debugging purposes.
class FluxPrintLogger implements FluxLoggerInterface {
  /// Whether this logger is enabled.
  /// Set to `false` to disable all logging output from this logger.
  @override
  bool loggerEnabled;

  /// Constructor to optionally enable or disable the logger on initialization.
  FluxPrintLogger({this.loggerEnabled = true});

  /// Logs a formatted message with timestamp, log level, and optional tag/signature.
  ///
  /// Example output:
  /// ```
  /// [LogLevel.info] 2025-04-06 18:45:32 - Server started [Server] [Main]
  /// ```
  @override
  void log(
    Object msg, {
    LogLevel level = LogLevel.info,
    String? tag,
    String? signature,
  }) {
    if (!loggerEnabled) return;

    String logMessage = '[$level] $now - $msg';
    if (tag != null) {
      logMessage += ' [$tag]';
    }
    if (signature != null) {
      logMessage += ' [$signature]';
    }
    print(logMessage);
  }

  /// Outputs a raw message directly to the console, with optional tag/signature.
  /// Unlike [log], this does not prefix the log with timestamp or log level.
  @override
  void rawLog(
    Object msg, {
    LogLevel level = LogLevel.info,
    String? tag,
    String? signature,
  }) {
    if (!loggerEnabled) return;

    String logMessage = msg.toString();
    if (tag != null) {
      logMessage += ' [$tag]';
    }
    if (signature != null) {
      logMessage += ' [$signature]';
    }
    print(logMessage);
  }
}
