import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/interface/routing_entity.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';

class Middleware extends RoutingEntity implements RequestProcessor {
  Middleware(
    String? pathTemplate,
    HttpMethod? method,
    Processor processor, {
    String? signature,
  }) : super(pathTemplate, method, processor, signature: signature);

  @override
  List<RoutingEntity> processors(
    String path,
    HttpMethod method,
    String? basePathTemplate,
  ) {
    bool mine = checkMine(path, method, basePathTemplate);
    if (mine) {
      return [this];
    }
    return [];
  }
}
