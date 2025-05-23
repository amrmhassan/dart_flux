import 'dart:io';

import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/server/execution/interface/flux_logger_interface.dart';
import 'package:dart_flux/core/server/execution/interface/server_interface.dart';
import 'package:dart_flux/core/server/execution/repo/flux_logger.dart';
import 'package:dart_flux/core/server/execution/repo/pipeline_runner.dart';
import 'package:dart_flux/core/server/middlewares/cors_middleware.dart';
import 'package:dart_flux/core/server/routing/models/lower_middleware.dart';
import 'package:dart_flux/core/server/utils/server_utils.dart';
import 'package:dart_flux/core/server/middlewares/request_logger_middleware.dart';
import 'package:dart_flux/core/server/routing/interface/request_processor.dart';
import 'package:dart_flux/core/server/routing/models/flux_request.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';

/// The `Server` class implements the [ServerInterface] to manage the server setup,
/// request handling, middlewares, and logging for the application.
class Server implements ServerInterface {
  /// The IP address to which the server will bind.
  @override
  var ip;

  /// List of middlewares to be executed after the main processing.
  @override
  List<LowerMiddleware>? lowerMiddlewares;

  /// The port on which the server will listen for incoming requests.
  @override
  int port;

  /// The processor responsible for handling request routing.
  @override
  RequestProcessor requestProcessor;

  /// List of middlewares to be executed before the main processing.
  @override
  List<Middleware>? upperMiddlewares;

  /// Flag indicating whether logging is enabled.
  @override
  bool loggerEnabled;

  /// Logger interface for logging messages.
  @override
  FluxLoggerInterface? logger;

  /// Handler to manage cases where a route is not found.
  @override
  ProcessorHandler? onNotFound;

  /// Constructor for initializing the server with necessary configurations.
  ///
  /// Takes in:
  /// - [ip]: The IP address to bind the server to.
  /// - [port]: The port for the server to listen on.
  /// - [requestProcessor]: The request processor for routing.
  /// - [upperMiddlewares]: A list of middlewares to be executed before request handling.
  /// - [lowerMiddlewares]: A list of middlewares to be executed after request handling.
  /// - [loggerEnabled]: A flag to enable or disable logging (defaults to true).
  /// - [logger]: The logger instance (optional).
  /// - [onNotFound]: Handler for cases where a route is not found (optional).
  Server(
    this.ip,
    this.port,
    this.requestProcessor, {
    this.upperMiddlewares,
    this.lowerMiddlewares,
    this.loggerEnabled = true,
    this.logger,
    this.onNotFound,
    this.disableCors = true,
  }) {
    // Ensure default values for middlewares if not provided.
    upperMiddlewares ??= [];
    lowerMiddlewares ??= [];

    // Add logging middlewares if enabled.
    _addLoggerMiddlewares();
    _disableCorsProtection();
  }

  void _disableCorsProtection() {
    if (disableCors) {
      // Add CORS middleware to the upper middlewares if CORS is disabled.
      upperMiddlewares?.add(CorsMiddleware.middleware);
    }
  }

  /// Private lists to manage system-level middlewares (upper and lower).
  List<Middleware> _systemUpper = [];
  List<LowerMiddleware> _systemLower = [];

  /// Adds the logger middlewares if logging is enabled.
  ///
  /// If logging is enabled, this method adds the logging middlewares to the
  /// upper and lower middleware stacks, ensuring that request logging happens
  /// before and after the main request processing.
  void _addLoggerMiddlewares() {
    if (!loggerEnabled)
      return; // Only add logging middlewares if logging is enabled.
    logger ??= FluxPrintLogger(
      loggerEnabled: loggerEnabled,
    ); // Initialize the logger if not provided.

    // Insert logger middleware at the beginning of the system upper middlewares.
    _systemUpper.insert(0, RequestLoggerMiddleware.upper(logger));
    // Add logger middleware at the end of the system lower middlewares.
    _systemLower.add(RequestLoggerMiddleware.lower);
  }

  /// Internal reference to the HTTP server.
  HttpServer? _server;

  /// The HTTP server instance, throwing an error if not running.
  ///
  /// This getter ensures that the server is running before allowing access to the
  /// server object. If the server is not running, it throws a [ServerError].
  @override
  HttpServer get server {
    if (_server == null) {
      throw ServerError('Server is not running yet or closed, call .run');
    }
    return _server!;
  }

  /// Starts the HTTP server and binds it to the specified IP and port.
  ///
  /// This method binds the server to the provided IP and port and begins
  /// listening for incoming HTTP requests. The server link is logged once
  /// the server is up and running.
  @override
  Future<void> run() async {
    // Bind the server to the specified IP and port.
    _server = await HttpServer.bind(ip, port);
    port = _server!.port; // Get the actual port after binding.

    // Generate the server link for logging purposes.
    String link = ServerUtils.serverLink(server);
    logger?.rawLog('server running on $link'); // Log the server start message.

    // Start listening for incoming requests and pass them to the `_run` handler.
    server.listen(_run);
  }

  /// Handles incoming requests by processing them through the pipeline.
  ///
  /// This method is called whenever a new HTTP request is received by the server.
  /// It processes the request, passes it through the middlewares, and eventually
  /// invokes the appropriate response handler.
  void _run(HttpRequest _request) async {
    String path =
        _request.uri.path; // Extract the path from the incoming request.
    String httpMethod = _request.method; // Extract the HTTP method.

    // Convert the HTTP method from string to HttpMethod enum.
    HttpMethod method = methodFromString(httpMethod);

    // Get the processors that are responsible for handling the request.
    var entities = requestProcessor.processors(path, method);

    // Wrap the incoming HTTP request into a FluxRequest.
    FluxRequest request = FluxRequest(_request);

    // Initialize a FluxResponse to capture the response to be sent.
    FluxResponse response = request.response;

    // Run the request through the pipeline and send the response.
    await PipelineRunner(
      systemUpper: _systemUpper,
      systemLower: _systemLower,
      upperMiddlewares: upperMiddlewares ?? [],
      lowerMiddlewares: lowerMiddlewares ?? [],
      request: request,
      response: response,
      fluxLogger: logger,
      onNotFound: onNotFound,
      entities: entities,
      requestProcessor: requestProcessor,
    ).run();
  }

  /// Closes the server and stops listening for incoming requests.
  ///
  /// This method gracefully shuts down the server. If the [force] flag is true,
  /// it will close the server forcefully. A log is generated when the server is closed.
  @override
  Future<void> close({bool force = true}) async {
    await server.close(
      force: force,
    ); // Close the server, optionally forcefully.
    _server = null; // Set the server reference to null to indicate it’s closed.
    logger?.rawLog('server closed'); // Log the server shutdown message.
  }

  @override
  bool disableCors;
}
