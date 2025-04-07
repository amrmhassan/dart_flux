import 'package:dart_flux/constants/date_constants.dart';
import 'package:dart_flux/core/server/execution/interface/flux_logger_interface.dart';
import 'package:dart_flux/core/server/execution/repo/flux_request_logger_saver.dart';
import 'package:dart_flux/core/server/routing/models/lower_middleware.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';

/// `RequestLoggerMiddleware` provides middlewares for logging request
/// details, including when a request was received and when it was completed.
class RequestLoggerMiddleware {
  /// Adds the "hit time" (the time when the request was received) to the request context.
  /// This middleware is executed before the main request processing (upper middleware).
  ///
  /// [logger]: The logger interface used for logging purposes.
  ///
  /// The hit time is added to the request context, and if a logger is provided,
  /// it's also stored in the request context for use in the lower middleware.
  static Middleware upper(FluxLoggerInterface? logger) =>
      Middleware(null, null, (request, response, pathArgs) {
        // If a logger is provided, add it to the request context
        if (logger != null) {
          request.context.add('logger', logger);
        }

        // Add the current hit time (the time the request was received)
        request.context.add('hitAt', now);
        return request;
      }, signature: 'adding hit time middleware');

  /// Adds the "left time" (the time when the response is sent) and logs the request and response.
  /// This middleware is executed after the main request processing (lower middleware).
  ///
  /// The hit and left times are used to measure the duration of the request lifecycle.
  /// If a logger is present, the request and response details are logged using `FluxRequestLoggerSaver`.
  static LowerMiddleware lower = LowerMiddleware(null, null, (
    request,
    response,
    pathArgs,
  ) {
    // Add the current left time (the time the response was sent)
    request.context.add('leftAt', now);

    // Retrieve the hit and left times from the request context
    var hitAt = request.context.get('hitAt') as DateTime;
    var leftAt = request.context.get('leftAt') as DateTime;

    // Retrieve the logger from the request context
    var logger = request.context.get('logger') as FluxLoggerInterface?;

    // If no logger is available, skip logging
    if (logger == null) return request;

    // Save the log using `FluxRequestLoggerSaver`
    FluxRequestLoggerSaver(
      hitAt: hitAt,
      leftAt: leftAt,
      request: request,
      response: response,
    ).log();
  }, signature: 'adding left time and logging middleware');
}
