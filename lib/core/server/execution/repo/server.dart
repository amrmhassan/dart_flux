import 'dart:io';

import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/server/execution/interface/flux_logger_interface.dart';
import 'package:dart_flux/core/server/execution/interface/server_interface.dart';
import 'package:dart_flux/core/server/execution/repo/flux_logger.dart';
import 'package:dart_flux/core/server/execution/repo/pipeline_runner.dart';
import 'package:dart_flux/core/server/execution/utils/server_utils.dart';
import 'package:dart_flux/core/server/middlewares/request_logger_middleware.dart';
import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/models/flux_request.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';

class Server implements ServerInterface {
  @override
  var ip;

  @override
  List<Middleware>? lowerMiddlewares;

  @override
  int port;

  @override
  RequestProcessor requestProcessor;

  @override
  List<Middleware>? upperMiddlewares;
  Server(
    this.ip,
    this.port,
    this.requestProcessor, {
    this.upperMiddlewares,
    this.lowerMiddlewares,
    this.loggerEnabled = true,
    this.logger,
  }) {
    upperMiddlewares ??= [];
    lowerMiddlewares ??= [];

    _addLoggerMiddlewares();
  }
  List<Middleware> _systemUpper = [];
  List<Middleware> _systemLower = [];

  void _addLoggerMiddlewares() {
    if (!loggerEnabled) return;
    logger ??= FluxPrintLogger();
    _systemUpper.insert(0, RequestLoggerMiddleware.upper(logger));
    _systemLower.add(RequestLoggerMiddleware.lower);
  }

  HttpServer? _server;

  @override
  HttpServer get server {
    if (_server == null) {
      throw ServerError('Server is not running yet or closed, call .run');
    }
    return _server!;
  }

  @override
  Future<void> run() async {
    _server = await HttpServer.bind(ip, port);
    port = _server!.port;
    String link = ServerUtils.serverLink(server);
    if (loggerEnabled) {
      logger?.rawLog('server running on $link');
    }

    server.listen(_run);
  }

  void _run(HttpRequest _request) async {
    String path = _request.uri.path;
    String httpMethod = _request.method;
    HttpMethod method = methodFromString(httpMethod);
    var entities = requestProcessor.processors(path, method);
    FluxRequest request = FluxRequest(_request);
    FluxResponse response = request.response;
    await PipelineRunner(
      systemUpper: _systemUpper,
      systemLower: _systemLower,
      upperMiddlewares: upperMiddlewares ?? [],
      lowerMiddlewares: lowerMiddlewares ?? [],
      request: request,
      response: response,
      entities: entities,
    ).run();
  }

  @override
  Future<void> close({bool force = true}) async {
    await server.close(force: force);
    _server = null;
    if (loggerEnabled) {
      logger?.rawLog('server closed');
    }
  }

  @override
  bool loggerEnabled;

  @override
  FluxLoggerInterface? logger;
}
