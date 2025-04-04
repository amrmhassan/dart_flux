import 'package:dart_flux/core/server/execution/interface/request_logger_saver.dart';
import 'package:dart_flux/core/server/execution/repo/flux_logger.dart';
import 'package:dart_flux/core/server/routing/models/flux_request.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';

class FluxRequestLoggerSaver implements RequestLoggerSaver {
  FluxRequestLoggerSaver({
    required this.hitAt,
    required this.leftAt,
    required this.request,
    required this.response,
  });

  @override
  FluxRequest request;

  @override
  FluxResponse response;

  @override
  void log() {
    var duration = leftAt.difference(hitAt);
    String path = request.path;
    HttpMethod method = request.method;
    String msg =
        '$path - ${method.name.toUpperCase()} ${response.code} - ${duration.inMilliseconds} ms';

    FluxPrintLogger().rawLog(msg);
  }

  @override
  DateTime hitAt;

  @override
  DateTime leftAt;
}
