import 'package:dart_flux/core/server/routing/models/flux_request.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';

abstract class RequestLoggerSaver {
  late DateTime hitAt;
  late DateTime leftAt;
  late FluxRequest request;
  late FluxResponse response;
  void log();
}
