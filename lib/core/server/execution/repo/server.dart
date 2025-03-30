import 'dart:io';

import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/server/execution/interface/server_interface.dart';
import 'package:dart_flux/core/server/execution/repo/request_router.dart';
import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';

class Server implements ServerInterface {
  final dynamic _ip;
  final int _port;
  final RequestProcessor _requestProcessor;
  final List<Middleware> _upperMiddlewares;
  final List<Middleware> _lowerMiddlewares;

  Server(
    this._ip,
    this._port,
    this._requestProcessor, {
    List<Middleware> upperMiddlewares = const [],
    List<Middleware> lowerMiddlewares = const [],
  }) : _lowerMiddlewares = lowerMiddlewares,
       _upperMiddlewares = upperMiddlewares;

  HttpServer get server {
    if (_server == null) {
      throw ServerError('Server is not running yet, call .run');
    }
    return _server!;
  }

  HttpServer? _server;
  Future<void> run() async {
    _server = await HttpServer.bind(_ip, _port);
    print('server running on http://$_ip:$_port');

    server.listen(
      (request) => RequestRouter.handle(
        request,
        _requestProcessor,
        _upperMiddlewares,
        _lowerMiddlewares,
      ),
    );
  }
}
