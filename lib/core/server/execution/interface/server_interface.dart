import 'dart:io';

import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';

/// this is the template for the server runner classes
abstract class ServerInterface {
  /// the ip you want the server to run on
  late final dynamic ip;
  late final int port;

  /// the Router, Handler or the middleware which will receive the request of the user  and route or handle it
  late final RequestProcessor requestProcessor;

  /// middleware that runs before the requestProcessor
  late final List<Middleware> upperMiddlewares;

  /// middleware that runs after the requestProcessor
  late final List<Middleware> lowerMiddlewares;
  HttpServer get server;
  Future<void> run();
}
