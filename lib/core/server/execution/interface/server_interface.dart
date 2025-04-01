import 'dart:io';

import 'package:dart_flux/core/server/execution/interface/request_logger.dart';
import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';

/// this is the template for the server runner classes
abstract class ServerInterface {
  late final dynamic ip;
  late final int port;
  late final RequestProcessor requestProcessor;
  late final List<Middleware> upperMiddlewares;
  late final List<Middleware> lowerMiddlewares;
  HttpServer get server;
  late RequestLogger? logger;
  Future<void> run();
}
