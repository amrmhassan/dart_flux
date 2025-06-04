# Server Setup

This guide explains how to set up and configure a Dart Flux server for your application.

> 📖 **Related Documentation:**
> - [Getting Started](getting-started.md) - Basic server setup
> - [Architecture Overview](architecture-overview.md) - Server architecture
> - [Best Practices & Security](best-practices-security.md) - Production security
> - [Troubleshooting](troubleshooting-guide.md) - Server issues

## Basic Server Setup

To create a server, you need to specify the IP address, port, and a router:

```dart
import 'dart:io';
import 'package:dart_flux/dart_flux.dart';

void main() async {
  // Create a router
  Router router = Router()
    .get('hello', (req, res, pathArgs) {
      return res.write('Hello, World!');
    });
  
  // Create a server
  Server server = Server(
    InternetAddress.anyIPv4,  // Listen on all IPv4 addresses
    3000,                     // Port number
    router,                   // Router instance
  );
  
  // Start the server
  await server.run();
  print('Server running on port 3000');
}
```

## Server Configuration Options

The `Server` class constructor accepts several parameters for customization:

```dart
Server(
  this.ip,                  // IP address to bind to
  this.port,                // Port number
  this.requestProcessor,    // Router instance
  {
    this.upperMiddlewares,  // Middlewares to run before request processing
    this.lowerMiddlewares,  // Middlewares to run after request processing
    this.loggerEnabled = true, // Enable/disable logging
    this.logger,            // Custom logger instance
    this.onNotFound,        // Custom handler for 404 errors
  }
)
```

## Binding to Different IP Addresses

You can bind your server to different network interfaces:

```dart
// Listen on all available network interfaces (IPv4)
Server server = Server(InternetAddress.anyIPv4, 3000, router);

// Listen on all available network interfaces (IPv6)
Server server = Server(InternetAddress.anyIPv6, 3000, router);

// Listen only on localhost (for development)
Server server = Server(InternetAddress.loopbackIPv4, 3000, router);

// Listen on a specific IP address
Server server = Server(InternetAddress('192.168.1.100'), 3000, router);
```

## Custom 404 Handler

You can define a custom handler for requests to undefined routes:

```dart
Server server = Server(
  InternetAddress.anyIPv4, 
  3000, 
  router,
  onNotFound: (req, res, pathArgs) {
    return res
      .status(404)
      .json({
        'error': 'Not Found',
        'message': 'The requested resource does not exist',
        'path': req.url.path,
      });
  },
);
```

## Logging

By default, Dart Flux enables request logging. You can customize or disable it:

```dart
// Disable logging
Server server = Server(
  InternetAddress.anyIPv4, 
  3000, 
  router,
  loggerEnabled: false,
);

// Use a custom logger
Server server = Server(
  InternetAddress.anyIPv4, 
  3000, 
  router,
  logger: MyCustomLogger(),
);
```

To implement a custom logger, create a class that implements the `FluxLoggerInterface`:

```dart
class MyCustomLogger implements FluxLoggerInterface {
  @override
  void logRequest(FluxRequest request) {
    // Custom request logging logic
  }
  
  @override
  void logResponse(FluxResponse response, Duration processingTime) {
    // Custom response logging logic
  }
  
  @override
  void rawLog(String message) {
    // Custom raw message logging
  }
}
```

## Using Middlewares

Middlewares allow you to execute code before or after request processing:

```dart
// Create middlewares
Middleware authMiddleware = (req, res, next) {
  // Check for authorization header
  final authHeader = req.headers.value('Authorization');
  if (authHeader == null) {
    return res.status(401).json({'error': 'Unauthorized'});
  }
  // Continue processing if authorized
  return next();
};

// Add middleware to server
Server server = Server(
  InternetAddress.anyIPv4, 
  3000, 
  router,
  upperMiddlewares: [authMiddleware],
);
```

See the [Routing documentation](routing.md) for more information on adding middlewares to specific routes.

## HTTPS Support

To enable HTTPS, you need to provide a SecurityContext:

```dart
import 'dart:io';
import 'package:dart_flux/dart_flux.dart';

void main() async {
  // Create a router
  Router router = Router()
    .get('hello', (req, res, pathArgs) {
      return res.write('Hello, Secure World!');
    });
  
  // Create a security context with certificate and key
  SecurityContext securityContext = SecurityContext()
    ..useCertificateChain('path_to_cert.pem')
    ..usePrivateKey('path_to_key.pem');
  
  // Create an HTTPS server
  SecureServer server = SecureServer(
    InternetAddress.anyIPv4,
    443,
    router,
    securityContext,
  );
  
  // Start the server
  await server.run();
  print('Secure server running on port 443');
}
```

## Error Handling

Dart Flux provides error handling capabilities to manage unexpected exceptions:

```dart
Server server = Server(
  InternetAddress.anyIPv4, 
  3000, 
  router,
  onError: (error, req, res) {
    print('Error occurred: $error');
    return res.status(500).json({
      'error': 'Internal Server Error',
      'message': 'Something went wrong',
    });
  },
);
```

## Graceful Shutdown

Implement graceful shutdown to handle server termination properly:

```dart
Server server = Server(InternetAddress.anyIPv4, 3000, router);
await server.run();

// Set up signal handling for graceful shutdown
ProcessSignal.sigint.watch().listen((_) async {
  print('Shutting down server...');
  await server.close();
  print('Server stopped');
  exit(0);
});
```

This ensures that all ongoing requests are completed before the server stops.

---

## 📚 Documentation Navigation

### Getting Started
- **[← Getting Started](getting-started.md)** - Basic server setup
- **[Routing →](routing.md)** - Configure routing and middleware
- **[Architecture Overview](architecture-overview.md)** - Understand server architecture

### Production Setup
- **[Best Practices & Security →](best-practices-security.md)** - Production security guidelines
- **[Integration Guides](integration-guides.md)** - Docker, load balancing, and CI/CD
- **[Webhooks](webhooks.md)** - Automated deployment

### Core Features
- **[Authentication](authentication.md)** - Secure your server
- **[Database Operations](database.md)** - Database connections
- **[File Management](file-management.md)** - File storage configuration

### Support
- **[Troubleshooting](troubleshooting-guide.md#server-issues)** - Server troubleshooting
- **[API Reference](api-reference.md)** - Server API documentation
- **[Error Handling](error-handling.md)** - Error management

---

📖 **[Back to Documentation Index](README.md)**
