import 'package:dart_flux/core/server/routing/models/flux_request.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';

abstract class RequestLogger {
  void hit(FluxRequest request);
  void log(FluxRequest request, FluxResponse response);
}
