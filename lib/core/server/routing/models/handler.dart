import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/interface/routing_entity.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';

class Handler extends RoutingEntity implements RequestProcessor {
  Handler(super.pathTemplate, super.method, super.processor);
  List<Middleware> _middlewares = [];
  List<Middleware> _lowerMiddleware = [];

  Handler addMiddleware(Middleware middleware) {
    _middlewares.add(middleware);
    return this;
  }

  Handler addLowerMiddleware(Middleware middleware) {
    _lowerMiddleware.add(middleware);
    return this;
  }

  @override
  List<Processor> processors(String path, HttpMethod method) {
    var middlewaresProcessors =
        _middlewares
            .where((middleware) => middleware.checkMine(path, method))
            .map((middleware) => middleware.processor)
            .toList();

    var lowerMiddlewaresProcessors =
        _lowerMiddleware
            .where((middleware) => middleware.checkMine(path, method))
            .map((middleware) => middleware.processor)
            .toList();

    bool mine = checkMine(path, method);
    if (mine) {
      return [
        ...middlewaresProcessors,
        processor,
        ...lowerMiddlewaresProcessors,
      ];
    }
    return [];
  }
}
