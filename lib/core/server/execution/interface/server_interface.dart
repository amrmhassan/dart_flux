import 'dart:io';

import 'package:dart_flux/core/server/execution/interface/flux_logger_interface.dart';
import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/models/lower_middleware.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';

/// Template (abstract base class) for server runner classes in the Flux framework.
/// Implement this interface to customize how your server runs and manages incoming requests.
abstract class ServerInterface {
  /// The IP address the server should bind to (e.g., '127.0.0.1', '0.0.0.0').
  /// Can be a String, InternetAddress, or other supported types.
  late final dynamic ip;

  /// The port number the server listens on.
  late final int port;

  /// The core request handler — could be a Router, Handler, or a Middleware chain.
  /// This is the main entry point that processes user requests after upper middleware.
  late final RequestProcessor requestProcessor;

  /// Middleware executed *before* the main request processor.
  /// Ideal for things like authentication, logging, request parsing, etc.
  late List<Middleware>? upperMiddlewares;

  /// Middleware executed *after* the main request processor.
  /// Useful for response formatting, error handling, or analytics.
  late List<LowerMiddleware>? lowerMiddlewares;

  /// The actual Dart [HttpServer] instance managing connections and HTTP requests.
  HttpServer get server;

  /// Starts the server — binds to the given [ip] and [port], applies middleware and request routing.
  Future<void> run();

  /// Closes the server and releases any open sockets.
  /// Set [force] to true to close immediately, cancelling ongoing connections.
  Future<void> close({bool force = true});

  /// Whether logging is enabled for this server instance.
  late final bool loggerEnabled;

  /// The logger implementation for structured logging (if any).
  /// Must implement [FluxLoggerInterface].
  late FluxLoggerInterface? logger;

  /// Custom handler executed when no matching route or handler is found.
  /// Can be used to return a 404 or fallback response.
  late ProcessorHandler? onNotFound;

  late bool disableCors;
}
