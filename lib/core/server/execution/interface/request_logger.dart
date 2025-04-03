import 'package:dart_flux/constants/date_constants.dart';
import 'package:dart_flux/core/server/execution/repo/flux_request_logger_saver.dart';
import 'package:dart_flux/core/server/routing/models/flux_request.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';

abstract class RequestLogger {
  DateTime? start;
  DateTime? end;
  void hit(FluxRequest request) {
    start = now;
  }

  void log(FluxRequest request, FluxResponse response) {
    end = now;
    FluxRequestLoggerSaver(
      hitAt: start!,
      leftAt: end!,
      request: request,
      response: response,
    ).log();
  }
}
