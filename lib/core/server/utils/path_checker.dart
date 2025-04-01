// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dart_flux/core/server/routing/interface/routing_entity.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/utils/path_utils.dart';

class PathChecker {
  final String _requestPath;
  final HttpMethod _requestMethod;
  final RoutingEntity _entity;
  final String? _basePathTemplate;

  PathChecker({
    required String requestPath,
    required HttpMethod requestMethod,
    required RoutingEntity entity,
    required String? basePathTemplate,
  }) : _entity = entity,
       _requestMethod = requestMethod,
       _requestPath = requestPath,
       _basePathTemplate = basePathTemplate;

  /// Checks if the request path matches the handler/middleware path template.
  /// Supports:
  /// - Exact match (`/user` == `/user`)
  /// - Path parameters (`/user/:id` == `/user/123`)
  /// - Wildcards (`/user/*` matches `/user/any/number/of/paths`)
  bool get matches {
    // handler data
    var handlerPath = PathUtils.finalPath(
      _basePathTemplate,
      _entity.pathTemplate,
    );
    (_entity.pathTemplate ?? '');
    var handlerMethod =
        _entity.method == null ? _requestMethod : _entity.method;

    // request data
    var requestPath = _requestPath;
    var requestMethod = _requestMethod;

    // http method check
    if (requestMethod != handlerMethod) return false;

    // if the handler path template is null this means that it will work on every request
    if (handlerPath == null) return true;

    bool pathMatches = PathUtils.pathMatches(
      requestPath: requestPath,
      handlerPath: handlerPath,
    );
    return pathMatches;
  }
}
