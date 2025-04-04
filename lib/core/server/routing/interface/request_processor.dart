import 'package:dart_flux/core/server/routing/interface/routing_entity.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';

/// is the request processor like Handler, Middleware or Router
abstract class RequestProcessor {
  String? basePathTemplate;

  List<RoutingEntity> processors(String path, HttpMethod method);
}
