# API Reference

This document provides a comprehensive reference of the Dart Flux API, including classes, methods, and properties.

> 📖 **Navigation:**
> - [Getting Started](getting-started.md) - Basic usage examples
> - [Architecture Overview](architecture-overview.md) - System design context
> - [Routing Examples](routing_examples.md) - Practical API usage
> - [Advanced Patterns](advanced-usage-patterns.md) - Complex API implementations
> - [Troubleshooting](troubleshooting-guide.md) - API-related issues

## Table of Contents

- [Server](#server)
- [Router](#router)
- [Request and Response](#request-and-response)
- [Authentication](#authentication)
- [Database](#database)
- [Webhook](#webhook)
- [File Management](#file-management)
- [Pipeline and Middleware](#pipeline-and-middleware)
- [Error Handling](#error-handling)
- [Utilities](#utilities)
- [Type Definitions](#type-definitions)
- [Constants and Enums](#constants-and-enums)

## Server

### Server Class

The main server class that handles HTTP requests.

```dart
Server(
  InternetAddress ip,
  int port,
  RequestProcessor requestProcessor, {
  List<Middleware>? upperMiddlewares,
  List<LowerMiddleware>? lowerMiddlewares,
  bool loggerEnabled = true,
  FluxLoggerInterface? logger,
  ProcessorHandler? onNotFound,
})
```

**Methods:**

| Method | Description |
|--------|-------------|
| `run()` | Starts the server and begins listening for requests |
| `close()` | Stops the server and closes all connections |
| `_addLoggerMiddlewares()` | Private method to configure logging |

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `ip` | `InternetAddress` | The IP address the server binds to |
| `port` | `int` | The port the server listens on |
| `requestProcessor` | `RequestProcessor` | The processor handling request routing |
| `upperMiddlewares` | `List<Middleware>?` | Middlewares executed before request handling |
| `lowerMiddlewares` | `List<LowerMiddleware>?` | Middlewares executed after request handling |
| `loggerEnabled` | `bool` | Flag to enable/disable logging |
| `logger` | `FluxLoggerInterface?` | Logger instance for request/response logging |
| `onNotFound` | `ProcessorHandler?` | Handler for 404 (not found) responses |

### FluxLoggerInterface

Interface for logger implementations.

```dart
abstract class FluxLoggerInterface {
  void logRequest(FluxRequest request);
  void logResponse(FluxResponse response, Duration processingTime);
  void rawLog(String message);
}
```

## Router

### Router Class

Handles URL routing and request processing.

```dart
Router({
  List<Middleware>? upperPipeline,
  List<RequestProcessor>? mainPipeline,
  List<LowerMiddleware>? lowerPipeline,
})
```

**Factory Methods:**

| Method | Description |
|--------|-------------|
| `Router.path(String path)` | Creates a router with a base path |
| `Router.crud(String entity, {ModelRepositoryInterface? repo})` | Creates a CRUD router for an entity |

**HTTP Method Methods:**

| Method | Description |
|--------|-------------|
| `get(String path, ProcessorHandler handler)` | Registers a GET route |
| `post(String path, ProcessorHandler handler)` | Registers a POST route |
| `put(String path, ProcessorHandler handler)` | Registers a PUT route |
| `delete(String path, ProcessorHandler handler)` | Registers a DELETE route |
| `patch(String path, ProcessorHandler handler)` | Registers a PATCH route |
| `options(String path, ProcessorHandler handler)` | Registers an OPTIONS route |
| `head(String path, ProcessorHandler handler)` | Registers a HEAD route |

**Router Methods:**

| Method | Description |
|--------|-------------|
| `addRouter(Router router)` | Adds a nested router |
| `use(Middleware middleware)` | Adds middleware to all routes |
| `setPath(String path)` | Sets the base path for this router |

### Handler Type

```dart
typedef ProcessorHandler = FutureOr<void> Function(
  FluxRequest request,
  FluxResponse response,
  Map<String, String> pathArgs,
);
```

### Middleware Type

```dart
typedef Middleware = FutureOr<void> Function(
  FluxRequest request,
  FluxResponse response,
  FutureOr<void> Function() next,
);
```

## Request and Response

### FluxRequest Class

Represents an HTTP request.

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `url` | `Uri` | The request URL |
| `method` | `String` | The HTTP method (GET, POST, etc.) |
| `headers` | `HttpHeaders` | HTTP request headers |
| `body` | `dynamic` | The parsed request body |
| `rawRequest` | `HttpRequest` | The underlying HttpRequest |
| `hasFormData` | `bool` | Whether the request contains form data |
| `formData` | `Future<FormData>` | The parsed form data |
| `context` | `Map<String, dynamic>` | Context data for request processing |

### FluxResponse Class

Represents an HTTP response.

**Methods:**

| Method | Description |
|--------|-------------|
| `status(int code)` | Sets the response status code |
| `header(String name, String value)` | Sets a response header |
| `write(String data)` | Writes string data to the response |
| `json(dynamic data)` | Writes JSON data to the response |
| `redirect(String url)` | Redirects to another URL |
| `stream(Stream<List<int>> stream)` | Streams data to the response |
| `streamFile(File file, {String contentType})` | Streams a file to the response |
| `send()` | Sends the response |

## Authentication

### JwtAuthenticator Class

Handles JWT authentication.

```dart
JwtAuthenticator({
  required String accessTokenSecret,
  required String refreshTokenSecret,
  Duration accessTokenExpiry = const Duration(hours: 1),
  Duration refreshTokenExpiry = const Duration(days: 7),
})
```

**Methods:**

| Method | Description |
|--------|-------------|
| `createTokens(Map<String, dynamic> payload)` | Creates access and refresh tokens |
| `verifyAccessToken(String token)` | Verifies an access token and returns the payload |
| `verifyRefreshToken(String token)` | Verifies a refresh token and returns the payload |
| `refreshTokens(String refreshToken)` | Issues new tokens using a refresh token |
| `hashPassword(String password)` | Hashes a password |
| `verifyPassword(String password, String hash)` | Verifies a password against a hash |

### AuthCacheInterface

Interface for authentication caching.

```dart
abstract class AuthCacheInterface {
  late bool allowCache;
  late Duration? cacheDuration;
  late Duration? clearCacheEvery;

  FutureOr<JwtPayloadModel?> getAccessToken(String token);
  FutureOr<void> setAccessToken(String token, JwtPayloadModel payload);
  FutureOr<void> removeAccessToken(String token);

  FutureOr<UserInterface?> getUser(String id);
  FutureOr<void> setUser(String id, UserInterface user);
  FutureOr<void> removeUser(String id);

  FutureOr<UserAuthInterface?> getAuth(String id);
  FutureOr<void> setAuth(String id, UserAuthInterface auth);
  FutureOr<void> removeAuth(String id);

  FutureOr<String?> getIdByEmail(String email);
  FutureOr<void> assignIdToEmail(String email, String id);
  FutureOr<void> removeAssignedId(String email);

  FutureOr<void> addRefreshToken(String token, JwtPayloadModel payload);
  FutureOr<JwtPayloadModel?> getRefreshToken(String token);
  FutureOr<void> removeRefreshToken(String token);

  FutureOr<void> clearAllCache();
}
```

## Database

### MongoDbConnection Class

Manages connections to MongoDB.

```dart
MongoDbConnection(
  String connLink, {
  bool loggerEnabled = true,
  FluxLoggerInterface? logger,
})
```

**Methods:**

| Method | Description |
|--------|-------------|
| `connect()` | Establishes a connection to the database |
| `fixConnection()` | Attempts to fix a broken connection |
| `collection(String name)` | Gets a reference to a collection |

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `connLink` | `String` | The MongoDB connection string |
| `connected` | `bool` | Whether the database is connected |
| `db` | `Db` | The MongoDB database instance |
| `loggerEnabled` | `bool` | Whether logging is enabled |
| `logger` | `FluxLoggerInterface?` | The logger instance |

### CollRefMongo Class

Represents a MongoDB collection.

**Methods:**

| Method | Description |
|--------|-------------|
| `add(Map<String, dynamic> data)` | Adds a document to the collection |
| `getAll()` | Gets all documents in the collection |
| `find(Map<String, dynamic> query, {Map<String, dynamic>? sort, int? limit, int? skip, Map<String, dynamic>? projection})` | Finds documents matching a query |
| `findOne(Map<String, dynamic> query)` | Finds a single document matching a query |
| `updateMany(Map<String, dynamic> query, Map<String, dynamic> update)` | Updates multiple documents |
| `deleteMany(Map<String, dynamic> query)` | Deletes multiple documents |
| `doc(String id)` | Gets a document reference by ID |
| `createIndex({required Map<String, dynamic> keys, bool? unique})` | Creates an index on the collection |

### DocRefMongo Class

Represents a document in a MongoDB collection.

**Methods:**

| Method | Description |
|--------|-------------|
| `get()` | Gets the document data |
| `set(Map<String, dynamic> data)` | Sets the document data |
| `update(Map<String, dynamic> data)` | Updates the document data |
| `delete()` | Deletes the document |

## Webhook

### WebhookHandler Class

Handles webhook requests and executes commands.

```dart
WebhookHandler({
  String? branch,
  String? event,
  String? projectPath,
  List<String> runCommand = PredefinedCommands.dartProjectUpdate,
  Duration? timeout,
  int maxRetries = 3,
  WebhookSecret? secret,
  bool concurrent = false,
})
```

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `branch` | `String?` | The Git branch to monitor |
| `event` | `String?` | The webhook event to listen for |
| `projectPath` | `String?` | The project path for command execution |
| `runCommand` | `List<String>` | Commands to execute when triggered |
| `timeout` | `Duration?` | Maximum execution time |
| `maxRetries` | `int` | Maximum number of retry attempts |
| `secret` | `WebhookSecret?` | Secret for webhook validation |
| `concurrent` | `bool` | Whether to run commands concurrently |
| `handler` | `ProcessorHandler` | The handler function for routing |

### WebhookSecret Class

Handles webhook request verification.

```dart
WebhookSecret({
  required String secret,
  String headerKey = 'X-Hub-Signature-256',
  String algorithm = 'sha256',
})
```

## File Management

### FileEntity Class

Represents a file in the storage system.

**Methods:**

| Method | Description |
|--------|-------------|
| `exists()` | Checks if the file exists |
| `readText()` | Reads the file as text |
| `writeText(String content)` | Writes text to the file |
| `appendText(String content)` | Appends text to the file |
| `readBytes()` | Reads the file as bytes |
| `writeBytes(List<int> bytes)` | Writes bytes to the file |
| `delete()` | Deletes the file |
| `copyTo(String destinationPath)` | Copies the file |
| `moveTo(String destinationPath)` | Moves/renames the file |
| `size()` | Gets the file size |
| `lastModified()` | Gets the last modified time |

### FolderEntity Class

Represents a folder in the storage system.

**Methods:**

| Method | Description |
|--------|-------------|
| `exists()` | Checks if the folder exists |
| `create()` | Creates the folder |
| `delete({bool recursive = false})` | Deletes the folder |
| `listFiles()` | Lists files in the folder |
| `listFolders()` | Lists subfolders in the folder |
| `getFile(String name)` | Gets a file in the folder |
| `getFolder(String name)` | Gets a subfolder |
| `copyTo(String destinationPath)` | Copies the folder and contents |

### FolderServer Class

Serves files from a folder.

```dart
FolderServer({
  required String rootPath,
  String prefix = '',
})
```

**Methods:**

| Method | Description |
|--------|-------------|
| `serveFile(String path, FluxResponse response)` | Serves a file from the folder |

### FormData Class

Represents multipart form data.

**Methods:**

| Method | Description |
|--------|-------------|
| `file(String name)` | Gets a file field by name |
| `files(String name)` | Gets multiple file fields by name |
| `text(String name)` | Gets a text field by name |
| `texts(String name)` | Gets multiple text fields by name |

## Pipeline and Middleware

### PipelineRunner Class

Orchestrates the execution of middleware pipelines.

```dart
class PipelineRunner {
  static Future<void> runPipelines(
    FluxRequest request,
    FluxResponse response,
    List<Middleware> upperPipeline,
    List<RequestProcessor> mainPipeline,
    List<LowerMiddleware> lowerPipeline,
  );
}
```

**Pipeline Execution Order:**
1. System Upper Middlewares
2. Server Upper Middlewares
3. Router Upper Middlewares
4. Main Pipeline (Route Handlers)
5. Router Lower Middlewares
6. Server Lower Middlewares
7. System Lower Middlewares

### Middleware Types

#### Processor
```dart
typedef Processor = FutureOr<void> Function(
  FluxRequest request,
  FluxResponse response,
  Map<String, String> pathArgs,
);
```

Can return early to stop the pipeline execution.

#### LowerProcessor
```dart
typedef LowerProcessor = FutureOr<void> Function(
  FluxRequest request,
  FluxResponse response,
  Map<String, String> pathArgs,
);
```

Post-processing middleware that cannot stop pipeline execution.

#### RequestProcessor
```dart
abstract class RequestProcessor {
  FutureOr<void> call(
    FluxRequest request,
    FluxResponse response,
    Map<String, String> pathArgs,
  );
}
```

Main request processing interface used in the main pipeline.

### Built-in Middlewares

#### CorsMiddleware
```dart
class CorsMiddleware implements Middleware {
  CorsMiddleware({
    List<String> allowedOrigins = const ['*'],
    List<String> allowedMethods = const ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    List<String> allowedHeaders = const ['Content-Type', 'Authorization'],
    bool allowCredentials = false,
    int maxAge = 86400,
  });
}
```

#### AuthMiddleware
```dart
class AuthMiddleware implements Middleware {
  AuthMiddleware({
    required FluxAuthenticator authenticator,
    List<String> excludePaths = const [],
    bool requireAuth = true,
  });
}
```

#### RateLimitMiddleware
```dart
class RateLimitMiddleware implements Middleware {
  RateLimitMiddleware({
    required int maxRequests,
    required Duration window,
    String keyGenerator(FluxRequest request)?,
  });
}
```

## Error Handling

### ServerError Class

Base class for server errors.

```dart
class ServerError extends Error {
  final String message;
  
  ServerError(this.message);
  
  @override
  String toString() => message;
}
```

### FluxException Class

Base exception class for Flux-specific errors.

```dart
class FluxException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? details;
  
  FluxException(this.message, {this.statusCode = 500, this.details});
  
  @override
  String toString() => 'FluxException: $message';
}
```

### ValidationException Class

Exception for validation errors.

```dart
class ValidationException extends FluxException {
  ValidationException(String message, {Map<String, dynamic>? details})
      : super(message, statusCode: 400, details: details);
}
```

### AuthenticationException Class

Exception for authentication errors.

```dart
class AuthenticationException extends FluxException {
  AuthenticationException(String message)
      : super(message, statusCode: 401);
}
```

### AuthorizationException Class

Exception for authorization errors.

```dart
class AuthorizationException extends FluxException {
  AuthorizationException(String message)
      : super(message, statusCode: 403);
}
```

### DatabaseException Class

Exception for database-related errors.

```dart
class DatabaseException extends FluxException {
  DatabaseException(String message, {Map<String, dynamic>? details})
      : super(message, statusCode: 500, details: details);
}
```

## Utilities

### StringUtils

Utility functions for string manipulation.

**Static Methods:**

| Method | Description |
|--------|-------------|
| `isEmail(String str)` | Checks if a string is a valid email |
| `isUrl(String str)` | Checks if a string is a valid URL |
| `isNumeric(String str)` | Checks if a string is numeric |
| `randomString(int length)` | Generates a random string |
| `slugify(String text)` | Converts text to a URL-friendly slug |

### PathUtils

Utility functions for path manipulation.

**Static Methods:**

| Method | Description |
|--------|-------------|
| `join(String path1, String path2)` | Joins two path segments |
| `isPathMatch(String pattern, String path)` | Checks if a path matches a pattern |
| `extractPathParams(String pattern, String path)` | Extracts parameters from a path |

## Type Definitions

### Handler Types

```dart
// Basic processor handler
typedef ProcessorHandler = FutureOr<void> Function(
  FluxRequest request,
  FluxResponse response,
  Map<String, String> pathArgs,
);

// Middleware handler with next function
typedef Middleware = FutureOr<void> Function(
  FluxRequest request,
  FluxResponse response,
  FutureOr<void> Function() next,
);

// Lower middleware (post-processing)
typedef LowerMiddleware = FutureOr<void> Function(
  FluxRequest request,
  FluxResponse response,
);
```

### Entity Types

```dart
// User interface for authentication
abstract class UserInterface {
  String get id;
  String get email;
  Map<String, dynamic> toJson();
}

// User authentication data
abstract class UserAuthInterface {
  String get id;
  String get passwordHash;
  Map<String, dynamic> toJson();
}

// JWT payload model
class JwtPayloadModel {
  final String userId;
  final int exp;
  final int iat;
  final Map<String, dynamic> extra;
  
  JwtPayloadModel({
    required this.userId,
    required this.exp,
    required this.iat,
    this.extra = const {},
  });
}
```

### Repository Interfaces

```dart
// Base repository interface
abstract class ModelRepositoryInterface<T> {
  Future<T?> findById(String id);
  Future<List<T>> findAll();
  Future<T> create(Map<String, dynamic> data);
  Future<T?> update(String id, Map<String, dynamic> data);
  Future<bool> delete(String id);
}

// User repository interface
abstract class UserRepositoryInterface extends ModelRepositoryInterface<UserInterface> {
  Future<UserInterface?> findByEmail(String email);
  Future<UserAuthInterface?> getAuth(String userId);
  Future<void> updateAuth(String userId, Map<String, dynamic> authData);
}
```

## Constants and Enums

### HTTP Methods

```dart
class HttpMethods {
  static const String GET = 'GET';
  static const String POST = 'POST';
  static const String PUT = 'PUT';
  static const String DELETE = 'DELETE';
  static const String PATCH = 'PATCH';
  static const String OPTIONS = 'OPTIONS';
  static const String HEAD = 'HEAD';
}
```

### Content Types

```dart
class ContentTypes {
  static const String json = 'application/json';
  static const String html = 'text/html';
  static const String text = 'text/plain';
  static const String xml = 'application/xml';
  static const String formData = 'multipart/form-data';
  static const String formUrlEncoded = 'application/x-www-form-urlencoded';
  static const String octetStream = 'application/octet-stream';
}
```

### Status Codes

```dart
class StatusCodes {
  // Success
  static const int ok = 200;
  static const int created = 201;
  static const int accepted = 202;
  static const int noContent = 204;
  
  // Redirection
  static const int movedPermanently = 301;
  static const int found = 302;
  static const int notModified = 304;
  
  // Client Error
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int methodNotAllowed = 405;
  static const int conflict = 409;
  static const int unprocessableEntity = 422;
  static const int tooManyRequests = 429;
  
  // Server Error
  static const int internalServerError = 500;
  static const int notImplemented = 501;
  static const int badGateway = 502;
  static const int serviceUnavailable = 503;
  static const int gatewayTimeout = 504;
}
```

### Predefined Commands

```dart
class PredefinedCommands {
  static const List<String> dartProjectUpdate = [
    'dart pub get',
    'dart pub upgrade',
    'dart compile exe bin/main.dart -o server',
  ];
  
  static const List<String> flutterProjectUpdate = [
    'flutter pub get',
    'flutter pub upgrade',
    'flutter build web',
  ];
  
  static const List<String> dockerBuild = [
    'docker build -t app .',
    'docker run -d -p 8080:8080 app',
  ];
}
```

### Cache Constants

```dart
class CacheConstants {
  static const Duration defaultAccessTokenCache = Duration(minutes: 15);
  static const Duration defaultRefreshTokenCache = Duration(hours: 24);
  static const Duration defaultUserCache = Duration(minutes: 30);
  static const Duration defaultClearCacheInterval = Duration(hours: 1);
}
```

---

## 📚 Documentation Navigation

### Implementation Guides
- **[← Getting Started](getting-started.md)** - See APIs in basic usage
- **[Routing Examples →](routing_examples.md)** - API usage in practice
- **[Authentication →](authentication.md)** - Authentication API usage
- **[Database Operations →](database.md)** - Database API patterns

### Advanced Usage
- **[Architecture Overview](architecture-overview.md)** - API design context
- **[Advanced Patterns](advanced-usage-patterns.md)** - Complex API implementations
- **[Best Practices](best-practices-security.md)** - API security guidelines

### Specific Features
- **[File Management](file-management.md)** - File API usage
- **[Webhooks](webhooks.md)** - Webhook API implementation
- **[Error Handling](error-handling.md)** - Error API patterns

### Support
- **[Troubleshooting](troubleshooting-guide.md)** - API-related issues
- **[Integration Guides](integration-guides.md)** - API integration patterns

---

📖 **[Back to Documentation Index](README.md)**
