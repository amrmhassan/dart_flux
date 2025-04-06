import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/interface/routing_entity.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';
import 'package:dart_flux/utils/path_utils.dart';

class Middleware extends RoutingEntity implements RequestProcessor {
  Middleware(
    String? pathTemplate,
    HttpMethod? method,
    Processor processor, {
    String? signature,
  }) : super(pathTemplate, method, processor, signature: signature) {
    finalPath = null;
  }

  @override
  String? get finalPath {
    return PathUtils.finalPath(basePathTemplate, pathTemplate);
  }

  @override
  List<RoutingEntity> processors(String path, HttpMethod method) {
    bool mine = checkMine(path, method);
    if (mine) {
      return [this];
    }
    return [];
  }

  @override
  String? basePathTemplate;

  @override
  set finalPath(String? _finalPath) {
    super.finalPath = PathUtils.finalPath(basePathTemplate, pathTemplate);
  }
}
