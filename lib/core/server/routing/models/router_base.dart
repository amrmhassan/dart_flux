// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/interface/routing_entity.dart';
import 'package:dart_flux/core/server/routing/models/handler.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/core/server/routing/repo/router.dart';
import 'package:dart_flux/utils/path_utils.dart';

abstract class RouterBase implements RequestProcessor {
  /// this is a path template for the whole router and will apply for each sub request processor
  String? basePath;
  // only middlewares
  List<Middleware> upperPipeline = [];
  // can be middlewares or handlers or routers
  List<RequestProcessor> mainPipeline = [];
  // only middlewares
  List<Middleware> lowerPipeline = [];

  RouterBase({
    List<Middleware>? upperPipeline,
    List<RequestProcessor>? mainPipeline,
    List<Middleware>? lowerPipeline,
  }) : upperPipeline = upperPipeline ?? [],
       mainPipeline = mainPipeline ?? [],
       lowerPipeline = lowerPipeline ?? [];

  @override
  List<RoutingEntity> processors(String path, HttpMethod method) {
    // basePathTemplate is the passed one from the request processor parent (mostly a router)
    // basePath is the current router base path template and comes next after the basePathTemplate
    // so the passed down base path template should be the sum of the upper routers base path templates

    String? finalBasePathTemplate = PathUtils.finalPath(
      basePath,
      basePathTemplate,
    );
    // main pipeline
    var main = _extractFromPipeline(
      mainPipeline,
      path,
      method,
      finalBasePathTemplate,
      handlerIsAMust: true,
    );
    if (main.isEmpty) return [];

    // upper pipeline
    var upper = _extractFromPipeline(
      upperPipeline,
      path,
      method,
      finalBasePathTemplate,
      handlerIsAMust: false,
    );

    // lower pipeline
    var lower = _extractFromPipeline(
      lowerPipeline,
      path,
      method,
      finalBasePathTemplate,
      handlerIsAMust: false,
    );
    // then add them together then return
    return [...upper, ...main, ...lower];
  }

  List<RoutingEntity> _extractFromPipeline(
    List<RequestProcessor> pipeLine,
    String path,
    HttpMethod method,
    String? basePathTemplate, {

    /// this will ensure that the processors list must contain a handler at the end of the pipeline
    required bool handlerIsAMust,
  }) {
    bool foundHandler = false;
    List<RoutingEntity> mainProcessors = [];
    for (var requestProcessor in pipeLine) {
      if ((requestProcessor is Handler || requestProcessor is Router) &&
          foundHandler) {
        continue;
      }
      // if handler then it should be the last of the pipeline
      var entityProcessors = requestProcessor.processors(path, method);
      if (entityProcessors.isEmpty) continue;
      if (requestProcessor is Handler || requestProcessor is Router) {
        foundHandler = true;
      }

      mainProcessors.addAll(entityProcessors);
    }

    if (handlerIsAMust && !foundHandler) return [];

    return mainProcessors;
  }

  @override
  String? basePathTemplate;
}
