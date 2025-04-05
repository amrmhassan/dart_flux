abstract class FluxLoggerInterface {
  bool loggerEnabled = true;
  void rawLog(
    Object msg, {
    LogLevel level = LogLevel.info,
    String? tag,
    String? signature,
  });

  void log(
    Object msg, {
    LogLevel level = LogLevel.info,
    String? tag,
    String? signature,
  });
}

enum LogLevel { debug, info, warning, error, fatal }
