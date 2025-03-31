import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/utils/path_checker.dart';

/// the entity responsible for making a change to the request
/// like a handler or a middleware
class RoutingEntity {
  /// this is the path of the handler or the middleware not the incoming request path
  /// the null pathTemplate means that this Middleware will run on every request no matter it's path
  /// but the method will restrict this, if you want to make a global middleware just make the pathTemplate to be null and the method to be HttpMethods.all
  final String? pathTemplate;

  /// this is the method of the handler or middleware not the incoming request method
  /// if null this means every request will trigger this entity(middleware)
  final HttpMethod? method;

  /// this is the function that will be executed when hitting this routing entity
  final dynamic processor;

  RoutingEntity(this.pathTemplate, this.method, this.processor);

  bool checkMine(String path, HttpMethod method, String? basePathTemplate) {
    return PathChecker(
      requestPath: path,
      requestMethod: method,
      entity: this,
      basePathTemplate: basePathTemplate,
    ).matches;
  }
}
