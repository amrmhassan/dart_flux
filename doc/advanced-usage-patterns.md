# Advanced Usage Patterns

This guide covers advanced usage patterns and business logic implementations in Dart Flux, providing real-world examples and best practices for complex scenarios.

> 📖 **Prerequisites:**
> - [Getting Started](getting-started.md) - Basic framework knowledge
> - [Architecture Overview](architecture-overview.md) - Understanding the pipeline system
> - [Routing Examples](routing_examples.md) - Basic routing patterns
> 
> 📚 **Related Topics:**
> - [Best Practices & Security](best-practices-security.md) - Security considerations
> - [Integration Guides](integration-guides.md) - External service integrations
> - [API Reference](api-reference.md) - Advanced API features

## Table of Contents

- [Advanced Middleware Patterns](#advanced-middleware-patterns)
- [Dynamic Router Configuration](#dynamic-router-configuration)
- [Custom Authentication Flows](#custom-authentication-flows)
- [Advanced File Handling](#advanced-file-handling)
- [Database Integration Patterns](#database-integration-patterns)
- [WebSocket Integration](#websocket-integration)
- [Caching Strategies](#caching-strategies)
- [Rate Limiting and Throttling](#rate-limiting-and-throttling)
- [Request Validation and Transformation](#request-validation-and-transformation)
- [Response Formatting and Serialization](#response-formatting-and-serialization)

## Advanced Middleware Patterns

### Conditional Middleware Execution

Create middleware that executes conditionally based on request properties:

```dart
Processor conditionalAuth = (request, response, pathArgs) {
  // Skip authentication for public endpoints
  if (request.path.startsWith('/public/')) {
    return request;
  }
  
  // Skip authentication for OPTIONS requests (CORS preflight)
  if (request.method == HttpMethod.options) {
    return request;
  }
  
  // Perform authentication for all other requests
  String? token = request.headers.value('Authorization');
  if (token == null || !isValidToken(token)) {
    return response.unauthorized('Authentication required');
  }
  
  // Add user context to request
  User user = getUserFromToken(token);
  request.context.add('currentUser', user);
  
  return request;
};
```

### Middleware Chains with Dependencies

Create complex middleware chains where later middleware depends on earlier ones:

```dart
// Step 1: Parse and validate API key
Processor apiKeyMiddleware = (request, response, pathArgs) {
  String? apiKey = request.headers.value('X-API-Key');
  if (apiKey == null) {
    return response.unauthorized('API key required');
  }
  
  ApiClient client = getClientByApiKey(apiKey);
  if (client == null) {
    return response.unauthorized('Invalid API key');
  }
  
  request.context.add('apiClient', client);
  return request;
};

// Step 2: Check rate limits for the client
Processor rateLimitMiddleware = (request, response, pathArgs) {
  ApiClient client = request.context.get('apiClient');
  
  if (!rateLimiter.checkLimit(client.id)) {
    response.headers.add('Retry-After', '60');
    return response.error('Rate limit exceeded', status: 429);
  }
  
  return request;
};

// Step 3: Log API usage
Processor usageLogMiddleware = (request, response, pathArgs) {
  ApiClient client = request.context.get('apiClient');
  
  // Log API call for analytics
  usageLogger.logApiCall(
    clientId: client.id,
    endpoint: request.path,
    method: request.method.name,
    timestamp: DateTime.now(),
  );
  
  return request;
};

// Chain them together
Router apiRouter = Router.path('api')
  .upper(apiKeyMiddleware)
  .upper(rateLimitMiddleware) 
  .upper(usageLogMiddleware);
```

### Error Recovery Middleware

Implement middleware that can recover from certain types of errors:

```dart
Processor errorRecoveryMiddleware = (request, response, pathArgs) {
  try {
    // This middleware wraps the actual processing
    return request;
  } catch (e) {
    if (e is DatabaseConnectionError) {
      // Attempt to reconnect and retry
      await database.reconnect();
      return request; // Continue processing after recovery
    } else if (e is TemporaryServiceError) {
      // Return a graceful degraded response
      return response.json({
        'status': 'degraded',
        'message': 'Service temporarily unavailable',
        'data': getCachedData(request.path),
      }, status: 206); // Partial Content
    }
    
    // Re-throw unrecoverable errors
    throw e;
  }
};
```

## Dynamic Router Configuration

### Runtime Router Registration

Create routers dynamically based on configuration or database content:

```dart
class DynamicRouterManager {
  final Map<String, Router> _activeRouters = {};
  
  // Add a new tenant-specific router at runtime
  void addTenantRouter(String tenantId, TenantConfig config) {
    Router tenantRouter = Router.path('tenant/$tenantId')
      .upper(tenantAuthMiddleware(config))
      .get('dashboard', getDashboardHandler(config))
      .router(createTenantApiRouter(config));
    
    _activeRouters[tenantId] = tenantRouter;
    
    // Register with main application router
    mainRouter.router(tenantRouter);
  }
  
  // Remove a tenant router
  void removeTenantRouter(String tenantId) {
    Router? router = _activeRouters.remove(tenantId);
    if (router != null) {
      mainRouter.removeRouter(router);
    }
  }
  
  // Update tenant configuration
  void updateTenantConfig(String tenantId, TenantConfig newConfig) {
    removeTenantRouter(tenantId);
    addTenantRouter(tenantId, newConfig);
  }
}
```

### Plugin-Based Architecture

Create a plugin system for modular functionality:

```dart
abstract class FluxPlugin {
  String get name;
  String get version;
  List<String> get dependencies;
  
  Router createRouter();
  List<Middleware> get globalMiddlewares;
  void initialize(FluxApp app);
  void dispose();
}

class PluginManager {
  final Map<String, FluxPlugin> _plugins = {};
  final Router _mainRouter;
  
  PluginManager(this._mainRouter);
  
  // Register a plugin
  void registerPlugin(FluxPlugin plugin) {
    // Check dependencies
    for (String dep in plugin.dependencies) {
      if (!_plugins.containsKey(dep)) {
        throw Exception('Plugin ${plugin.name} requires ${dep}');
      }
    }
    
    // Initialize plugin
    plugin.initialize(app);
    
    // Register plugin router
    Router pluginRouter = plugin.createRouter();
    _mainRouter.router(pluginRouter);
    
    // Add global middlewares
    for (Middleware middleware in plugin.globalMiddlewares) {
      _mainRouter.upper(middleware.processor);
    }
    
    _plugins[plugin.name] = plugin;
  }
}

// Example plugin implementation
class AuthenticationPlugin implements FluxPlugin {
  @override
  String get name => 'authentication';
  
  @override
  String get version => '1.0.0';
  
  @override
  List<String> get dependencies => [];
  
  @override
  Router createRouter() {
    return Router.path('auth')
      .post('login', loginHandler)
      .post('register', registerHandler)
      .post('refresh', refreshTokenHandler)
      .post('logout', logoutHandler);
  }
  
  @override
  List<Middleware> get globalMiddlewares => [
    Middleware(null, null, jwtValidationMiddleware),
  ];
  
  @override
  void initialize(FluxApp app) {
    // Initialize JWT settings, database connections, etc.
  }
  
  @override
  void dispose() {
    // Cleanup resources
  }
}
```

## Custom Authentication Flows

### Multi-Factor Authentication

Implement a complete MFA flow:

```dart
class MFAAuthenticator {
  final JWTService jwtService;
  final SMSService smsService;
  final MemoryCache<String, PendingMFA> pendingMFA;
  
  ProcessorHandler initiateLogin = (request, response, pathArgs) async {
    var data = await request.readAsJson();
    String email = data['email'];
    String password = data['password'];
    
    // Validate primary credentials
    User? user = await userRepository.validateCredentials(email, password);
    if (user == null) {
      return response.unauthorized('Invalid credentials');
    }
    
    // Check if MFA is required
    if (user.mfaEnabled) {
      // Generate temporary token and send SMS
      String tempToken = generateTempToken();
      String verificationCode = generateVerificationCode();
      
      // Store pending MFA state
      pendingMFA.set(tempToken, PendingMFA(
        userId: user.id,
        verificationCode: verificationCode,
        expiresAt: DateTime.now().add(Duration(minutes: 5)),
      ));
      
      // Send SMS
      await smsService.sendVerificationCode(user.phoneNumber, verificationCode);
      
      return response.json({
        'requiresMFA': true,
        'tempToken': tempToken,
        'message': 'Verification code sent to your phone',
      });
    }
    
    // No MFA required, generate session token
    String sessionToken = jwtService.generateToken(user);
    return response.json({
      'sessionToken': sessionToken,
      'user': user.toJson(),
    });
  };
  
  ProcessorHandler completeMFA = (request, response, pathArgs) async {
    var data = await request.readAsJson();
    String tempToken = data['tempToken'];
    String verificationCode = data['verificationCode'];
    
    // Retrieve pending MFA
    PendingMFA? pending = pendingMFA.get(tempToken);
    if (pending == null || pending.isExpired) {
      return response.unauthorized('Invalid or expired verification code');
    }
    
    // Validate verification code
    if (pending.verificationCode != verificationCode) {
      return response.unauthorized('Invalid verification code');
    }
    
    // Generate session token
    User user = await userRepository.findById(pending.userId);
    String sessionToken = jwtService.generateToken(user);
    
    // Cleanup pending MFA
    pendingMFA.remove(tempToken);
    
    return response.json({
      'sessionToken': sessionToken,
      'user': user.toJson(),
    });
  };
}
```

### Role-Based Access Control

Implement granular permission checking:

```dart
class RBACMiddleware {
  static Processor requirePermission(String permission) {
    return (request, response, pathArgs) {
      User? user = request.context.get('currentUser');
      if (user == null) {
        return response.unauthorized('Authentication required');
      }
      
      if (!user.hasPermission(permission)) {
        return response.forbidden('Insufficient permissions');
      }
      
      return request;
    };
  }
  
  static Processor requireRole(String role) {
    return (request, response, pathArgs) {
      User? user = request.context.get('currentUser');
      if (user == null) {
        return response.unauthorized('Authentication required');
      }
      
      if (!user.hasRole(role)) {
        return response.forbidden('Insufficient role');
      }
      
      return request;
    };
  }
  
  static Processor requireOwnership(String resourceType) {
    return (request, response, pathArgs) async {
      User? user = request.context.get('currentUser');
      String? resourceId = pathArgs['id'];
      
      if (user == null || resourceId == null) {
        return response.unauthorized('Authentication required');
      }
      
      // Check if user owns the resource
      bool isOwner = await checkResourceOwnership(
        user.id, 
        resourceType, 
        resourceId
      );
      
      if (!isOwner && !user.hasRole('admin')) {
        return response.forbidden('You can only access your own resources');
      }
      
      return request;
    };
  }
}

// Usage in routes
Router userRouter = Router.path('users')
  .get(':id', getUserHandler)
    .middleware(RBACMiddleware.requireOwnership('user'))
  .put(':id', updateUserHandler)
    .middleware(RBACMiddleware.requireOwnership('user'))
  .delete(':id', deleteUserHandler)
    .middleware(RBACMiddleware.requirePermission('user:delete'));
```

## Advanced File Handling

### Streaming File Uploads

Handle large file uploads with streaming:

```dart
class StreamingFileUpload {
  static ProcessorHandler handleLargeUpload = (request, response, pathArgs) async {
    String? contentType = request.headers.value('content-type');
    
    if (contentType?.startsWith('multipart/form-data') != true) {
      return response.badRequest('Multipart form data required');
    }
    
    // Create a stream transformer for the upload
    StreamTransformer<List<int>, FileChunk> transformer = 
        StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        // Process chunks as they arrive
        FileChunk chunk = FileChunk(data, DateTime.now());
        sink.add(chunk);
      },
    );
    
    String uploadId = generateUploadId();
    String tempPath = getTempFilePath(uploadId);
    
    // Stream file to temporary location
    File tempFile = File(tempPath);
    IOSink sink = tempFile.openWrite();
    
    try {
      await request.request.transform(transformer).forEach((chunk) {
        sink.add(chunk.data);
        
        // Update upload progress
        uploadProgress.updateProgress(uploadId, chunk.size);
      });
      
      await sink.close();
      
      // Validate file
      FileValidationResult validation = await validateUploadedFile(tempFile);
      if (!validation.isValid) {
        await tempFile.delete();
        return response.badRequest(validation.errorMessage);
      }
      
      // Move to final location
      String finalPath = getFinalFilePath(validation.fileType, validation.fileName);
      await tempFile.rename(finalPath);
      
      return response.json({
        'uploadId': uploadId,
        'filePath': finalPath,
        'size': await File(finalPath).length(),
        'contentType': validation.contentType,
      });
      
    } catch (e) {
      // Cleanup on error
      await sink.close();
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      throw e;
    }
  };
}
```

### File Transformation Pipeline

Create a pipeline for processing uploaded files:

```dart
abstract class FileProcessor {
  Future<ProcessedFile> process(File input, Map<String, dynamic> options);
}

class ImageResizeProcessor implements FileProcessor {
  @override
  Future<ProcessedFile> process(File input, Map<String, dynamic> options) async {
    int width = options['width'] ?? 800;
    int height = options['height'] ?? 600;
    
    // Use image processing library
    Image image = await loadImage(input);
    Image resized = resize(image, width: width, height: height);
    
    String outputPath = '${input.path}_resized.jpg';
    await saveImage(resized, outputPath);
    
    return ProcessedFile(
      originalPath: input.path,
      processedPath: outputPath,
      metadata: {
        'originalSize': await input.length(),
        'newSize': await File(outputPath).length(),
        'dimensions': '${width}x${height}',
      },
    );
  }
}

class FileProcessingPipeline {
  final List<FileProcessor> processors = [];
  
  void addProcessor(FileProcessor processor) {
    processors.add(processor);
  }
  
  Future<List<ProcessedFile>> process(File input, Map<String, dynamic> options) async {
    List<ProcessedFile> results = [];
    File currentFile = input;
    
    for (FileProcessor processor in processors) {
      ProcessedFile result = await processor.process(currentFile, options);
      results.add(result);
      currentFile = File(result.processedPath);
    }
    
    return results;
  }
}

// Usage in handler
ProcessorHandler uploadAndProcess = (request, response, pathArgs) async {
  FormData formData = await request.readAsFormData(saveFolder: 'uploads');
  
  for (FileData file in formData.files) {
    FileProcessingPipeline pipeline = FileProcessingPipeline()
      ..addProcessor(ImageResizeProcessor())
      ..addProcessor(ImageOptimizationProcessor())
      ..addProcessor(ThumbnailGeneratorProcessor());
    
    List<ProcessedFile> results = await pipeline.process(
      File(file.filePath), 
      {
        'width': 1920,
        'height': 1080,
        'quality': 85,
      }
    );
    
    // Store file metadata in database
    await fileRepository.saveFileRecord(FileRecord(
      originalName: file.fileName,
      originalPath: file.filePath,
      processedFiles: results,
      uploadedAt: DateTime.now(),
    ));
  }
  
  return response.json({'message': 'Files processed successfully'});
};
```

## Database Integration Patterns

### Advanced Query Building

Create flexible query builders for complex database operations:

```dart
class QueryBuilder {
  final MongoDBConnection connection;
  String _collection = '';
  Map<String, dynamic> _filter = {};
  Map<String, dynamic> _sort = {};
  int? _limit;
  int? _skip;
  
  QueryBuilder(this.connection);
  
  QueryBuilder collection(String name) {
    _collection = name;
    return this;
  }
  
  QueryBuilder where(String field, dynamic value) {
    _filter[field] = value;
    return this;
  }
  
  QueryBuilder whereIn(String field, List<dynamic> values) {
    _filter[field] = {'\$in': values};
    return this;
  }
  
  QueryBuilder whereRange(String field, dynamic min, dynamic max) {
    _filter[field] = {'\$gte': min, '\$lte': max};
    return this;
  }
  
  QueryBuilder sortBy(String field, {bool ascending = true}) {
    _sort[field] = ascending ? 1 : -1;
    return this;
  }
  
  QueryBuilder limit(int count) {
    _limit = count;
    return this;
  }
  
  QueryBuilder skip(int count) {
    _skip = count;
    return this;
  }
  
  Future<List<Map<String, dynamic>>> execute() async {
    var cursor = connection.collection(_collection).find(_filter);
    
    if (_sort.isNotEmpty) {
      cursor = cursor.sort(_sort);
    }
    
    if (_skip != null) {
      cursor = cursor.skip(_skip!);
    }
    
    if (_limit != null) {
      cursor = cursor.limit(_limit!);
    }
    
    return await cursor.toList();
  }
  
  Future<int> count() async {
    return await connection.collection(_collection).count(_filter);
  }
}

// Usage in handlers
ProcessorHandler searchUsers = (request, response, pathArgs) async {
  Map<String, String> queryParams = request.uri.queryParameters;
  
  QueryBuilder query = QueryBuilder(mongoConnection)
    .collection('users');
  
  // Add filters based on query parameters
  if (queryParams.containsKey('status')) {
    query.where('status', queryParams['status']);
  }
  
  if (queryParams.containsKey('role')) {
    query.where('role', queryParams['role']);
  }
  
  if (queryParams.containsKey('createdAfter')) {
    DateTime date = DateTime.parse(queryParams['createdAfter']!);
    query.whereRange('createdAt', date, null);
  }
  
  // Add pagination
  int page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
  int limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
  
  query.skip((page - 1) * limit).limit(limit);
  
  // Add sorting
  String sortBy = queryParams['sortBy'] ?? 'createdAt';
  bool ascending = queryParams['order'] != 'desc';
  query.sortBy(sortBy, ascending: ascending);
  
  // Execute query
  List<Map<String, dynamic>> users = await query.execute();
  int totalCount = await query.count();
  
  return response.json({
    'users': users,
    'pagination': {
      'page': page,
      'limit': limit,
      'total': totalCount,
      'pages': (totalCount / limit).ceil(),
    },
  });
};
```

### Database Transaction Patterns

Implement transactional operations:

```dart
class TransactionManager {
  final MongoDBConnection connection;
  
  TransactionManager(this.connection);
  
  Future<T> executeTransaction<T>(
    Future<T> Function(TransactionContext) operation
  ) async {
    final session = await connection.startSession();
    
    try {
      await session.startTransaction();
      
      TransactionContext context = TransactionContext(session);
      T result = await operation(context);
      
      await session.commitTransaction();
      return result;
      
    } catch (e) {
      await session.abortTransaction();
      throw e;
      
    } finally {
      await session.endSession();
    }
  }
}

class TransactionContext {
  final ClientSession session;
  
  TransactionContext(this.session);
  
  Future<void> insertOne(String collection, Map<String, dynamic> document) async {
    await connection.collection(collection).insertOne(document, session: session);
  }
  
  Future<void> updateOne(
    String collection, 
    Map<String, dynamic> filter, 
    Map<String, dynamic> update
  ) async {
    await connection.collection(collection).updateOne(
      filter, 
      {'\$set': update}, 
      session: session
    );
  }
  
  Future<void> deleteOne(
    String collection, 
    Map<String, dynamic> filter
  ) async {
    await connection.collection(collection).deleteOne(filter, session: session);
  }
}

// Usage example
ProcessorHandler transferFunds = (request, response, pathArgs) async {
  var data = await request.readAsJson();
  String fromAccountId = data['fromAccountId'];
  String toAccountId = data['toAccountId'];
  double amount = data['amount'].toDouble();
  
  try {
    await transactionManager.executeTransaction((context) async {
      // Check source account balance
      var fromAccount = await getAccount(fromAccountId);
      if (fromAccount['balance'] < amount) {
        throw Exception('Insufficient funds');
      }
      
      // Update account balances
      await context.updateOne('accounts', 
        {'_id': fromAccountId}, 
        {'balance': fromAccount['balance'] - amount}
      );
      
      await context.updateOne('accounts',
        {'_id': toAccountId},
        {'\$inc': {'balance': amount}}
      );
      
      // Record transaction
      await context.insertOne('transactions', {
        'fromAccountId': fromAccountId,
        'toAccountId': toAccountId,
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'transfer',
      });
    });
    
    return response.json({'message': 'Transfer completed successfully'});
    
  } catch (e) {
    return response.badRequest('Transfer failed: ${e.toString()}');
  }
};
```

## WebSocket Integration

Although Dart Flux primarily handles HTTP requests, you can integrate WebSocket support:

```dart
class WebSocketManager {
  final Map<String, WebSocket> _connections = {};
  final Map<String, String> _userConnections = {}; // userId -> connectionId
  
  void handleWebSocketUpgrade(HttpRequest request) {
    WebSocketTransformer.upgrade(request).then((WebSocket webSocket) {
      String connectionId = generateConnectionId();
      _connections[connectionId] = webSocket;
      
      // Extract user ID from token or session
      String? userId = extractUserIdFromRequest(request);
      if (userId != null) {
        _userConnections[userId] = connectionId;
      }
      
      webSocket.listen(
        (message) => handleWebSocketMessage(connectionId, message),
        onDone: () => removeConnection(connectionId),
        onError: (error) => handleWebSocketError(connectionId, error),
      );
    });
  }
  
  void sendToUser(String userId, Map<String, dynamic> message) {
    String? connectionId = _userConnections[userId];
    if (connectionId != null) {
      WebSocket? socket = _connections[connectionId];
      socket?.add(jsonEncode(message));
    }
  }
  
  void broadcast(Map<String, dynamic> message) {
    String messageStr = jsonEncode(message);
    for (WebSocket socket in _connections.values) {
      socket.add(messageStr);
    }
  }
}

// Integration with HTTP handlers
ProcessorHandler sendNotification = (request, response, pathArgs) async {
  var data = await request.readAsJson();
  String userId = data['userId'];
  String message = data['message'];
  
  // Send via WebSocket if user is connected
  webSocketManager.sendToUser(userId, {
    'type': 'notification',
    'message': message,
    'timestamp': DateTime.now().toIso8601String(),
  });
  
  // Also store in database for offline users
  await notificationRepository.create({
    'userId': userId,
    'message': message,
    'read': false,
    'createdAt': DateTime.now(),
  });
  
  return response.json({'message': 'Notification sent'});
};
```

## Caching Strategies

### Multi-Level Caching

Implement comprehensive caching strategies:

```dart
abstract class CacheProvider {
  Future<T?> get<T>(String key);
  Future<void> set<T>(String key, T value, {Duration? ttl});
  Future<void> delete(String key);
  Future<void> clear();
}

class MemoryCacheProvider implements CacheProvider {
  final Map<String, CacheEntry> _cache = {};
  
  @override
  Future<T?> get<T>(String key) async {
    CacheEntry? entry = _cache[key];
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.value as T?;
  }
  
  @override
  Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    _cache[key] = CacheEntry(
      value: value,
      expiresAt: ttl != null ? DateTime.now().add(ttl) : null,
    );
  }
  
  // ... other methods
}

class RedisCacheProvider implements CacheProvider {
  final RedisConnection redis;
  
  @override
  Future<T?> get<T>(String key) async {
    String? value = await redis.get(key);
    if (value == null) return null;
    return jsonDecode(value) as T?;
  }
  
  // ... other methods
}

class MultiLevelCache {
  final List<CacheProvider> providers;
  
  MultiLevelCache(this.providers);
  
  Future<T?> get<T>(String key) async {
    for (int i = 0; i < providers.length; i++) {
      T? value = await providers[i].get<T>(key);
      if (value != null) {
        // Backfill earlier cache levels
        for (int j = 0; j < i; j++) {
          await providers[j].set(key, value);
        }
        return value;
      }
    }
    return null;
  }
  
  Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    // Set in all cache levels
    for (CacheProvider provider in providers) {
      await provider.set(key, value, ttl: ttl);
    }
  }
}

// Cache middleware
Processor cacheMiddleware(Duration ttl) {
  return (request, response, pathArgs) async {
    // Only cache GET requests
    if (request.method != HttpMethod.get) {
      return request;
    }
    
    String cacheKey = 'http:${request.path}:${request.uri.query}';
    
    // Try to get from cache
    Map<String, dynamic>? cached = await cache.get<Map<String, dynamic>>(cacheKey);
    if (cached != null) {
      response.headers.add('X-Cache', 'HIT');
      return response.json(cached);
    }
    
    // Add cache key to context for post-processing
    request.context.add('cacheKey', cacheKey);
    request.context.add('cacheTTL', ttl);
    
    return request;
  };
}

// Cache population in lower middleware
LowerProcessor cachePopulationMiddleware = (request, response, pathArgs) async {
  String? cacheKey = request.context.get('cacheKey');
  Duration? ttl = request.context.get('cacheTTL');
  
  if (cacheKey != null && ttl != null && response.code == 200) {
    // Cache successful responses
    var data = response.data;
    if (data != null) {
      await cache.set(cacheKey, data, ttl: ttl);
      response.headers.add('X-Cache', 'MISS');
    }
  }
};
```

This comprehensive guide covers advanced patterns that enable building sophisticated, production-ready applications with Dart Flux. Each pattern can be adapted and combined to meet specific application requirements.

---

## 📚 Documentation Navigation

### Foundation Knowledge
- **[← Architecture Overview](architecture-overview.md)** - Core architectural concepts
- **[Routing Examples](routing_examples.md)** - Basic to intermediate patterns
- **[Authentication](authentication.md)** - Security implementation basics

### Advanced Topics
- **[Best Practices & Security →](best-practices-security.md)** - Production security guidelines
- **[Integration Guides →](integration-guides.md)** - External service patterns
- **[Performance Optimization](best-practices-security.md#performance-optimization)** - Scale and optimize

### Specific Use Cases
- **[Database Operations](database.md)** - Data layer patterns
- **[File Management](file-management.md)** - Advanced file handling
- **[Webhooks](webhooks.md)** - Event-driven patterns

### Troubleshooting
- **[Troubleshooting Guide](troubleshooting-guide.md)** - Debug advanced patterns
- **[API Reference](api-reference.md)** - Complete technical reference

---

📖 **[Back to Documentation Index](README.md)**
