import 'package:dart_flux/constants/global.dart';
import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/server/routing/interface/base_path.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/repo/handler.dart';
import 'package:dart_flux/core/server/utils/path_checker.dart';

/// The entity responsible for making a change to the request,
/// such as executing a handler or middleware.
///
/// This class represents either a middleware or a handler, each associated with
/// a path template and HTTP method to match requests and execute the processor function.
class RoutingEntity extends BasePath {
  /// this is the same as the pathTemplate
  @override
  String? pathTemplate;

  /// this is the parent of the handler, mostly a router
  @override
  BasePath? parent;

  /// The path template of the handler or middleware.
  ///
  /// If null, this entity will apply to all paths.
  /// A non-null value indicates that the entity will only apply to paths that match the template.
  /// For a global middleware, set [pathTemplate] to null and [method] to [HttpMethod.all].

  /// The HTTP method associated with this handler or middleware.
  ///
  /// If null, the entity will trigger on any HTTP method.
  /// The method restricts the entity to match only certain HTTP methods.
  final HttpMethod? method;

  /// The function (processor) that will be executed when this routing entity is triggered.
  /// This could be either a handler (request processor) or middleware function.
  final dynamic processor;

  late String
  _signature; // Internal signature used for unique identification of the entity

  /// Constructs a [RoutingEntity] with the given [pathTemplate], [method], and [processor].
  ///
  /// If a [signature] is provided, it will be used to uniquely identify this entity.
  /// If no [signature] is provided, a unique one will be generated.
  /// Throws a [ServerError] if the signature contains the special character '|'.
  RoutingEntity(
    this.pathTemplate,
    this.method,
    this.processor, {
    String? signature,
  }) {
    if (signature != null) {
      // Ensures that the signature does not contain the special character '|'.
      if (signature.contains('|')) {
        throw ServerError('signature can\'t contain the special letter |');
      }
    }
    // Determines whether this is a handler or middleware by checking the runtime type.
    String type = this is Handler ? 'H|' : 'M|';
    // Creates a signature using the entity type and the provided or generated signature.
    _signature = type + (signature ?? dartID.generate());
  }

  /// Returns the unique signature of this routing entity.
  ///
  /// The signature helps uniquely identify the entity, distinguishing between
  /// handlers and middleware.
  String get signature {
    return _signature;
  }

  /// Checks whether this routing entity applies to a given path and HTTP method.
  ///
  /// This method uses the [PathChecker] to verify if the [path] and [method]
  /// of the incoming request match this entity's path template and method.
  ///
  /// Returns true if the entity applies to the request, false otherwise.
  bool checkMine(String path, HttpMethod method) {
    return PathChecker(
      requestPath: path,
      requestMethod: method,
      entity: this,
    ).matches;
  }

  /// Returns a string representation of the routing entity, including its
  /// runtime type and signature, for debugging and logging purposes.
  @override
  String toString() {
    return this.runtimeType.toString() + _signature;
  }
}
