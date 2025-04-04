import 'package:dart_flux/constants/date_constants.dart';
import 'package:dart_flux/core/server/execution/interface/flux_logger_interface.dart';
import 'package:dart_flux/core/server/execution/repo/flux_request_logger_saver.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';

class RequestLoggerMiddleware {
  static Middleware upper(FluxLoggerInterface? logger) =>
      Middleware(null, null, (request, response, pathArgs) {
        if (logger != null) {
          request.context.add('logger', logger);
        }
        request.context.add('hitAt', now);
        return request;
      }, signature: 'adding hit time middleware');
  static Middleware lower = Middleware(null, null, (
    request,
    response,
    pathArgs,
  ) {
    request.context.add('leftAt', now);
    var hitAt = request.context.get('hitAt') as DateTime;
    var leftAt = request.context.get('leftAt') as DateTime;
    var logger = request.context.get('logger') as FluxLoggerInterface?;
    if (logger == null) return request;
    FluxRequestLoggerSaver(
      hitAt: hitAt,
      leftAt: leftAt,
      request: request,
      response: response,
    ).log();

    return request;
  }, signature: 'adding left time and logging middleware');
}
