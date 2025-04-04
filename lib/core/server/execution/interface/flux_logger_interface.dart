abstract class FluxLoggerInterface {
  bool loggerEnabled = true;
  void rawLog(
    String msg, {
    LogLevel level = LogLevel.info,
    String? tag,
    String? signature,
  });

  void log(
    String msg, {
    LogLevel level = LogLevel.info,
    String? tag,
    String? signature,
  });
}

enum LogLevel { debug, info, warning, error, fatal }
