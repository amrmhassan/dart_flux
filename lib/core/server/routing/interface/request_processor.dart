import 'package:dart_flux/core/server/routing/interface/routing_entity.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/repo/handler.dart';

/// is the request processor like Handler, Middleware or Router
abstract class RequestProcessor {
  List<RoutingEntity> processors(String path, HttpMethod method);
  List<Handler> wrongMethodProcessors(String path, HttpMethod method);
  List<Handler> wrongPathProcessors(String path, HttpMethod method);
}
