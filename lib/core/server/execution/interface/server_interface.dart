import 'dart:io';

import 'package:dart_flux/core/server/execution/interface/flux_logger_interface.dart';
import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';

/// this is the template for the server runner classes
abstract class ServerInterface {
  /// the ip you want the server to run on
  late final dynamic ip;
  late final int port;

  /// the Router, Handler or the middleware which will receive the request of the user  and route or handle it
  late final RequestProcessor requestProcessor;

  /// middleware that runs before the requestProcessor
  late List<Middleware>? upperMiddlewares;

  /// middleware that runs after the requestProcessor
  late List<Middleware>? lowerMiddlewares;
  HttpServer get server;
  Future<void> run();
  Future<void> close({bool force = true});
  late final bool loggerEnabled;
  late FluxLoggerInterface? logger;
  late ProcessorHandler? onNotFound;
}
