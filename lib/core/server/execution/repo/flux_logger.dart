import 'package:dart_flux/constants/date_constants.dart';
import 'package:dart_flux/core/server/execution/interface/flux_logger_interface.dart';

class FluxPrintLogger implements FluxLoggerInterface {
  FluxPrintLogger({this.loggerEnabled = true});
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

  @override
  bool loggerEnabled;
}
