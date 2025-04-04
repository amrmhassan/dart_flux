import 'dart:io';

import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/server/execution/interface/server_interface.dart';
import 'package:dart_flux/core/server/execution/repo/request_router.dart';
import 'package:dart_flux/core/server/execution/utils/server_utils.dart';
import 'package:dart_flux/core/server/middlewares/request_logger_middleware.dart';
import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
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
  }) {
    upperMiddlewares ??= [];
    lowerMiddlewares ??= [];
    _addLoggerMiddlewares();
  }

  void _addLoggerMiddlewares() {
    upperMiddlewares!.insert(0, RequestLoggerMiddleware.upper);
    lowerMiddlewares!.add(RequestLoggerMiddleware.lower);
  }

  HttpServer? _server;

  @override
  HttpServer get server {
    if (_server == null) {
      throw ServerError('Server is not running yet, call .run');
    }
    return _server!;
  }

  @override
  Future<void> run() async {
    _server = await HttpServer.bind(ip, port);
    String link = ServerUtils.serverLink(server);

    print('server running on $link');

    server.listen(
      (request) => RequestRouter.handle(
        request,
        requestProcessor,
        upperMiddlewares!,
        lowerMiddlewares!,
      ),
    );
  }
}
