import 'package:dart_flux/core/server/routing/models/flux_request.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';

/// Abstract class used to define how HTTP request/response logs are saved or processed.
/// Implement this class to store logs in databases, files, or send them to external monitoring tools.
abstract class RequestLoggerSaver {
  /// Timestamp when the request was received.
  late DateTime hitAt;

  /// Timestamp when the response was sent.
  late DateTime leftAt;

  /// The incoming HTTP request object containing headers, body, method, etc.
  late FluxRequest request;

  /// The corresponding HTTP response object returned to the client.
  late FluxResponse response;

  /// Called after the request has been processed and a response is generated.
  /// Implement this method to define how the request-response log should be handled.
  void log();
}
