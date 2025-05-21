# API Reference

This document provides a comprehensive reference of the Dart Flux API, including classes, methods, and properties.

## Table of Contents

- [Server](#server)
- [Router](#router)
- [Request and Response](#request-and-response)
- [Authentication](#authentication)
- [Database](#database)
- [Webhook](#webhook)
- [File Management](#file-management)
- [Error Handling](#error-handling)
- [Utilities](#utilities)

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
