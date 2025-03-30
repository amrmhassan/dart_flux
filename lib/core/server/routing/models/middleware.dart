import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/interface/routing_entity.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';

class Middleware extends RoutingEntity implements RequestProcessor {
  Middleware(super.pathTemplate, super.method, super.processor);

  @override
  List<RoutingEntity> processors(String path, HttpMethod method) {
    bool mine = checkMine(path, method);
    if (mine) {
      return [this];
    }
    return [];
  }
}
