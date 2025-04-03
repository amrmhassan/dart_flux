import 'package:dart_flux/constants/date_constants.dart';
import 'package:dart_flux/core/server/execution/repo/flux_request_logger_saver.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';

class RequestLoggerMiddleware {
  static Middleware upper = Middleware(null, null, (
    request,
    response,
    pathArgs,
  ) {
    request.context.add('hitAt', now);
    return request;
  });
  static Middleware lower = Middleware(null, null, (
    request,
    response,
    pathArgs,
  ) {
    request.context.add('leftAt', now);
    var hitAt = request.context.get('hitAt') as DateTime;
    var leftAt = request.context.get('leftAt') as DateTime;
    FluxRequestLoggerSaver(
      hitAt: hitAt,
      leftAt: leftAt,
      request: request,
      response: response,
    ).log();

    return request;
  });
}
