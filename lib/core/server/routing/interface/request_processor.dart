import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';

/// is the request processor like Handler, Middleware or Router
abstract class RequestProcessor {
  List<Processor> processors(String path, HttpMethod method);
}
