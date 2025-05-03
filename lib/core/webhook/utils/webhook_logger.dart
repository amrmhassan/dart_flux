import 'dart:io';

/// Utility class for logging webhook-related operations
class WebhookLogger {
  final File _logFile;
  final bool _enabled;

  /// Creates a new WebhookLogger
  ///
  /// - [logPath] specifies where log files will be stored
  /// - [enabled] determines if logging is active (default: true)
  WebhookLogger({required String logPath, bool enabled = true})
    : _enabled = enabled,
      _logFile = File(logPath);

  /// Logs an informational message
  Future<void> info(String message) async {
    if (!_enabled) return;
    await _appendLog('INFO', message);
  }

  /// Logs an error message
  Future<void> error(String message) async {
    if (!_enabled) return;
    await _appendLog('ERROR', message);
  }

  /// Logs a warning message
  Future<void> warning(String message) async {
    if (!_enabled) return;
    await _appendLog('WARNING', message);
  }

  /// Logs a debug message
  Future<void> debug(String message) async {
    if (!_enabled) return;
    await _appendLog('DEBUG', message);
  }

  Future<void> _appendLog(String level, String message) async {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $level: $message\n';

    try {
      if (!await _logFile.exists()) {
        await _logFile.create(recursive: true);
      }
      await _logFile.writeAsString(logMessage, mode: FileMode.append);
    } catch (e) {
      print('Failed to write to webhook log: ${e.toString()}');
    }
  }
}
