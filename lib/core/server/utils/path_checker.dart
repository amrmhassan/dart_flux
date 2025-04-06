// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dart_flux/core/server/routing/interface/routing_entity.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/utils/path_utils.dart';

/// A class responsible for checking if a given request path and method
/// match a routing entity's path template and method.
class PathChecker {
  final String _requestPath;
  final HttpMethod _requestMethod;
  final RoutingEntity _entity;

  /// Constructor that initializes a [PathChecker] with the provided
  /// request path, request method, and routing entity to match against.
  PathChecker({
    required String requestPath,
    required HttpMethod requestMethod,
    required RoutingEntity entity,
  }) : _entity = entity,
       _requestMethod = requestMethod,
       _requestPath = requestPath;

  /// Checks if the request path matches the handler/middleware path template.
  /// Supports the following matching types:
  /// - Exact match (`/user` == `/user`)
  /// - Path parameters (`/user/:id` == `/user/123`)
  /// - Wildcards (`/user/*` matches `/user/any/number/of/paths`)
  ///
  /// Returns `true` if the request path and method match the routing entity's
  /// path and method, otherwise returns `false`.
  bool get matches {
    // handler data
    var handlerPath = _entity.finalPath;
    (_entity.pathTemplate ?? ''); // Path template from the routing entity.
    var handlerMethod =
        _entity.method == null ? _requestMethod : _entity.method;

    // request data
    var requestPath = _requestPath;
    var requestMethod = _requestMethod;

    // HTTP method check: If request method does not match the handler method, return false.
    if (requestMethod != handlerMethod) return false;

    // If the handler path template is null, it means the handler applies to all paths.
    if (handlerPath == null) return true;

    // Check if the request path matches the handler path using path utility functions.
    bool pathMatches = PathUtils.pathMatches(
      requestPath: requestPath,
      handlerPath: handlerPath,
    );
    return pathMatches;
  }
}
