# Troubleshooting Guide

This guide helps you resolve common issues when working with Dart Flux.

> 🔧 **Quick Help:** Use Ctrl+F to search for specific error messages or issues.
>
> 📖 **Documentation Links:**
> - [Getting Started](getting-started.md) - Basic setup troubleshooting
> - [Architecture Overview](architecture-overview.md) - Understanding system behavior
> - [Best Practices](best-practices-security.md) - Prevent common issues
> - [API Reference](api-reference.md) - Technical specifications

## Table of Contents

- [Server Issues](#server-issues)
- [Routing Problems](#routing-problems)
- [Authentication Issues](#authentication-issues)
- [Database Connection Problems](#database-connection-problems)
- [File Upload Issues](#file-upload-issues)
- [Middleware Problems](#middleware-problems)
- [Performance Issues](#performance-issues)
- [Common Error Messages](#common-error-messages)
- [Debugging Tips](#debugging-tips)
- [Frequently Asked Questions](#frequently-asked-questions)

## Server Issues

### Server Won't Start

**Problem:** Server fails to start or throws binding errors.

**Common Causes:**
- Port already in use
- Insufficient permissions
- Invalid IP address

**Solutions:**

1. **Check if port is in use:**
```bash
netstat -tulpn | grep :8080
# Or on Windows
netstat -ano | findstr :8080
```

2. **Use a different port:**
```dart
final server = Server(
  InternetAddress.anyIPv4,
  3000, // Try a different port
  router,
);
```

3. **Run with administrator privileges** (if binding to port < 1024)

4. **Check IP address binding:**
```dart
// Bind to all interfaces
final server = Server(InternetAddress.anyIPv4, 8080, router);

// Bind to localhost only
final server = Server(InternetAddress.loopbackIPv4, 8080, router);

// Bind to specific IP
final server = Server(InternetAddress('192.168.1.100'), 8080, router);
```

### Server Crashes Unexpectedly

**Problem:** Server stops responding or crashes without clear error messages.

**Solutions:**

1. **Enable comprehensive logging:**
```dart
final server = Server(
  InternetAddress.anyIPv4,
  8080,
  router,
  loggerEnabled: true,
  logger: CustomLogger(), // Implement your own logger
);
```

2. **Add global error handling:**
```dart
void main() {
  runZonedGuarded(() async {
    final server = Server(InternetAddress.anyIPv4, 8080, router);
    await server.run();
  }, (error, stackTrace) {
    print('Uncaught error: $error');
    print('Stack trace: $stackTrace');
  });
}
```

3. **Monitor resource usage:**
```dart
// Add memory monitoring
Timer.periodic(Duration(minutes: 5), (timer) {
  print('Memory usage: ${ProcessInfo.currentRss ~/ 1024 ~/ 1024} MB');
});
```

## Routing Problems

### 404 Not Found Errors

**Problem:** Routes return 404 even when they appear to be correctly defined.

**Common Causes:**
- Incorrect path patterns
- Router hierarchy issues
- Missing route registration

**Solutions:**

1. **Check path patterns:**
```dart
// Correct
router.get('/users/:id', handler);

// Incorrect - missing leading slash
router.get('users/:id', handler);
```

2. **Verify router hierarchy:**
```dart
final apiRouter = Router.path('/api');
apiRouter.get('/users', getUsersHandler);

final mainRouter = Router();
mainRouter.addRouter(apiRouter); // Don't forget to add the sub-router
```

3. **Add debug logging:**
```dart
router.use((request, response, next) async {
  print('Request: ${request.method} ${request.url.path}');
  await next();
});
```

4. **Add a catch-all route for debugging:**
```dart
router.get('/*', (request, response, pathArgs) async {
  response.status(404).json({
    'error': 'Route not found',
    'path': request.url.path,
    'method': request.method,
  });
});
```

### Path Parameters Not Working

**Problem:** Path parameters are empty or not correctly extracted.

**Solutions:**

1. **Check parameter syntax:**
```dart
// Correct
router.get('/users/:userId/posts/:postId', handler);

// Incorrect
router.get('/users/{userId}/posts/{postId}', handler);
```

2. **Verify parameter extraction:**
```dart
router.get('/users/:id', (request, response, pathArgs) async {
  final userId = pathArgs['id'];
  if (userId == null) {
    response.status(400).json({'error': 'Missing user ID'});
    return;
  }
  // Handle request...
});
```

## Authentication Issues

### JWT Token Problems

**Problem:** JWT tokens are rejected or cause authentication errors.

**Common Causes:**
- Token expiry
- Invalid secret
- Token corruption

**Solutions:**

1. **Verify token configuration:**
```dart
final authenticator = FluxAuthenticator(
  accessTokenSecret: 'your-secret-key', // Must be consistent
  refreshTokenSecret: 'your-refresh-secret',
  accessTokenExpiry: Duration(hours: 1),
  refreshTokenExpiry: Duration(days: 7),
);
```

2. **Add token validation logging:**
```dart
try {
  final payload = authenticator.verifyAccessToken(token);
  print('Token valid for user: ${payload.userId}');
} catch (e) {
  print('Token validation failed: $e');
  // Handle invalid token
}
```

3. **Check token format in requests:**
```dart
// Client should send token as:
// Authorization: Bearer <token>

// Server extraction:
final authHeader = request.headers.value('Authorization');
if (authHeader == null || !authHeader.startsWith('Bearer ')) {
  response.status(401).json({'error': 'Missing or invalid authorization header'});
  return;
}
final token = authHeader.substring(7); // Remove 'Bearer '
```

### Authentication Cache Issues

**Problem:** Authentication cache returns stale or incorrect data.

**Solutions:**

1. **Clear cache manually:**
```dart
await authenticator.cache.clearAllCache();
```

2. **Check cache configuration:**
```dart
final cache = InMemoryAuthCache()
  ..allowCache = true
  ..cacheDuration = Duration(minutes: 15)
  ..clearCacheEvery = Duration(hours: 1);
```

3. **Debug cache operations:**
```dart
class DebugAuthCache extends InMemoryAuthCache {
  @override
  Future<void> setAccessToken(String token, JwtPayloadModel payload) async {
    print('Caching token for user: ${payload.userId}');
    await super.setAccessToken(token, payload);
  }

  @override
  Future<JwtPayloadModel?> getAccessToken(String token) async {
    final result = await super.getAccessToken(token);
    print('Cache ${result != null ? 'hit' : 'miss'} for token');
    return result;
  }
}
```

## Database Connection Problems

### MongoDB Connection Failures

**Problem:** Cannot connect to MongoDB or connection drops frequently.

**Solutions:**

1. **Verify connection string:**
```dart
// Local MongoDB
final db = MongoDbConnection('mongodb://localhost:27017/mydb');

// MongoDB Atlas
final db = MongoDbConnection('mongodb+srv://user:pass@cluster.mongodb.net/mydb');

// With authentication
final db = MongoDbConnection('mongodb://username:password@localhost:27017/mydb');
```

2. **Add connection retry logic:**
```dart
Future<void> connectWithRetry(MongoDbConnection db, {int maxRetries = 3}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      await db.connect();
      print('Database connected successfully');
      return;
    } catch (e) {
      print('Connection attempt ${i + 1} failed: $e');
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(Duration(seconds: 2 * (i + 1)));
    }
  }
}
```

3. **Monitor connection status:**
```dart
Timer.periodic(Duration(minutes: 1), (timer) async {
  if (!db.connected) {
    print('Database connection lost, attempting to reconnect...');
    try {
      await db.fixConnection();
    } catch (e) {
      print('Reconnection failed: $e');
    }
  }
});
```

### Query Performance Issues

**Problem:** Database queries are slow or timing out.

**Solutions:**

1. **Add indexes for frequently queried fields:**
```dart
await collection.createIndex(
  keys: {'email': 1},
  unique: true,
);

// Compound index
await collection.createIndex(
  keys: {'userId': 1, 'createdAt': -1},
);
```

2. **Use query limits and pagination:**
```dart
final results = await collection.find(
  query,
  limit: 50,
  skip: page * 50,
  sort: {'createdAt': -1},
);
```

3. **Monitor query performance:**
```dart
class MonitoredCollection extends CollRefMongo {
  @override
  Future<List<Map<String, dynamic>>> find(
    Map<String, dynamic> query, {
    Map<String, dynamic>? sort,
    int? limit,
    int? skip,
    Map<String, dynamic>? projection,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await super.find(query, sort: sort, limit: limit, skip: skip, projection: projection);
      stopwatch.stop();
      print('Query took ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      print('Query failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }
}
```

## File Upload Issues

### Large File Upload Problems

**Problem:** Large file uploads fail or timeout.

**Solutions:**

1. **Increase server timeouts:**
```dart
final server = HttpServer.bind(InternetAddress.anyIPv4, 8080);
server.forEach((request) {
  request.response.deadline = DateTime.now().add(Duration(minutes: 10));
  // Handle request...
});
```

2. **Implement streaming upload:**
```dart
router.post('/upload/stream/:filename', (request, response, pathArgs) async {
  final filename = pathArgs['filename']!;
  final file = File('uploads/$filename');
  final sink = file.openWrite();
  
  try {
    await request.rawRequest.pipe(sink);
    response.json({'message': 'File uploaded successfully'});
  } catch (e) {
    response.status(500).json({'error': 'Upload failed: $e'});
  } finally {
    await sink.close();
  }
});
```

3. **Add upload progress tracking:**
```dart
router.post('/upload/progress', (request, response, pathArgs) async {
  final contentLength = int.tryParse(
    request.headers.value('content-length') ?? '0'
  );
  
  int bytesReceived = 0;
  final chunks = <List<int>>[];
  
  await for (final chunk in request.rawRequest) {
    chunks.add(chunk);
    bytesReceived += chunk.length;
    
    if (contentLength != null) {
      final progress = (bytesReceived / contentLength * 100).round();
      print('Upload progress: $progress%');
    }
  }
  
  // Process complete file
  final bytes = chunks.expand((chunk) => chunk).toList();
  await File('uploads/file.bin').writeAsBytes(bytes);
  
  response.json({'message': 'Upload complete'});
});
```

### File Permission Issues

**Problem:** Cannot read or write files due to permission errors.

**Solutions:**

1. **Check directory permissions:**
```dart
Future<void> ensureDirectoryExists(String path) async {
  final dir = Directory(path);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  
  // Check write permission
  try {
    final testFile = File('$path/.test');
    await testFile.writeAsString('test');
    await testFile.delete();
  } catch (e) {
    throw Exception('No write permission for directory: $path');
  }
}
```

2. **Use relative paths from application directory:**
```dart
final appDir = Directory.current.path;
final uploadsDir = '$appDir/uploads';
await ensureDirectoryExists(uploadsDir);
```

## Middleware Problems

### Middleware Execution Order

**Problem:** Middlewares execute in unexpected order or some don't run.

**Solutions:**

1. **Understand pipeline execution order:**
```dart
// Execution order:
// 1. System Upper Middlewares
// 2. Server Upper Middlewares  
// 3. Router Upper Middlewares
// 4. Main Pipeline (Route Handler)
// 5. Router Lower Middlewares
// 6. Server Lower Middlewares
// 7. System Lower Middlewares
```

2. **Add middleware ordering debugging:**
```dart
Middleware createDebugMiddleware(String name) {
  return (request, response, next) async {
    print('Entering middleware: $name');
    await next();
    print('Exiting middleware: $name');
  };
}

router.use(createDebugMiddleware('Router Middleware'));
```

3. **Ensure `next()` is called:**
```dart
// Correct - calls next()
router.use((request, response, next) async {
  print('Processing request');
  await next(); // Don't forget this!
});

// Incorrect - doesn't call next()
router.use((request, response, next) async {
  print('Processing request');
  // Missing next() call - pipeline stops here
});
```

### CORS Issues

**Problem:** Browser blocks requests due to CORS policy.

**Solutions:**

1. **Add CORS middleware:**
```dart
final corsMiddleware = (FluxRequest request, FluxResponse response, Function next) async {
  response.header('Access-Control-Allow-Origin', '*');
  response.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  response.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  if (request.method == 'OPTIONS') {
    response.status(200).send();
    return;
  }
  
  await next();
};

router.use(corsMiddleware);
```

2. **Handle preflight requests:**
```dart
router.options('/*', (request, response, pathArgs) async {
  response.status(200).send();
});
```

## Performance Issues

### High Memory Usage

**Problem:** Application consumes excessive memory.

**Solutions:**

1. **Monitor memory usage:**
```dart
Timer.periodic(Duration(minutes: 5), (timer) {
  final rss = ProcessInfo.currentRss;
  final maxRss = ProcessInfo.maxRss;
  print('Memory: ${rss ~/ 1024 ~/ 1024} MB / ${maxRss ~/ 1024 ~/ 1024} MB');
});
```

2. **Implement memory limits:**
```dart
const maxMemoryMB = 512;

if (ProcessInfo.currentRss > maxMemoryMB * 1024 * 1024) {
  print('Memory limit exceeded, restarting...');
  exit(1); // Let process manager restart
}
```

3. **Clear caches periodically:**
```dart
Timer.periodic(Duration(hours: 1), (timer) async {
  await authenticator.cache.clearAllCache();
  // Clear other caches
});
```

### Slow Response Times

**Problem:** API responses are slow.

**Solutions:**

1. **Add response time logging:**
```dart
Middleware responseTimeMiddleware = (request, response, next) async {
  final stopwatch = Stopwatch()..start();
  await next();
  stopwatch.stop();
  
  final duration = stopwatch.elapsedMilliseconds;
  response.header('X-Response-Time', '${duration}ms');
  
  if (duration > 1000) {
    print('Slow request: ${request.method} ${request.url.path} took ${duration}ms');
  }
};
```

2. **Implement caching:**
```dart
final cache = <String, CacheEntry>{};

router.get('/api/expensive-operation', (request, response, pathArgs) async {
  final cacheKey = 'expensive_${request.url.query}';
  final cached = cache[cacheKey];
  
  if (cached != null && cached.isValid) {
    response.json(cached.data);
    return;
  }
  
  final result = await expensiveOperation();
  cache[cacheKey] = CacheEntry(result, DateTime.now().add(Duration(minutes: 5)));
  
  response.json(result);
});
```

3. **Use database connection pooling:**
```dart
class ConnectionPool {
  final List<MongoDbConnection> _connections = [];
  final int maxConnections;
  
  ConnectionPool({this.maxConnections = 10});
  
  Future<MongoDbConnection> getConnection() async {
    if (_connections.isNotEmpty) {
      return _connections.removeLast();
    }
    
    if (_connections.length < maxConnections) {
      final conn = MongoDbConnection(connectionString);
      await conn.connect();
      return conn;
    }
    
    // Wait for available connection
    while (_connections.isEmpty) {
      await Future.delayed(Duration(milliseconds: 10));
    }
    return _connections.removeLast();
  }
  
  void releaseConnection(MongoDbConnection conn) {
    _connections.add(conn);
  }
}
```

## Common Error Messages

### "Port already in use"

**Solution:** Change the port or stop the process using it:
```bash
# Find process using port 8080
lsof -i :8080

# Kill process
kill -9 <PID>
```

### "Connection refused"

**Solutions:**
- Check if the server is running
- Verify firewall settings
- Ensure correct IP/port combination

### "Invalid token"

**Solutions:**
- Check token expiry
- Verify signing secret
- Ensure proper token format

### "File not found"

**Solutions:**
- Verify file paths are absolute
- Check file permissions
- Ensure directory exists

## Debugging Tips

### 1. Enable Verbose Logging

```dart
final logger = VerboseLogger();

final server = Server(
  InternetAddress.anyIPv4,
  8080,
  router,
  loggerEnabled: true,
  logger: logger,
);
```

### 2. Use Request/Response Interceptors

```dart
router.use((request, response, next) async {
  print('📨 ${request.method} ${request.url.path}');
  print('📋 Headers: ${request.headers}');
  print('📦 Body: ${request.body}');
  
  await next();
  
  print('📤 Response Status: ${response.statusCode}');
});
```

### 3. Add Health Check Endpoint

```dart
router.get('/health', (request, response, pathArgs) async {
  final health = {
    'status': 'OK',
    'timestamp': DateTime.now().toIso8601String(),
    'uptime': DateTime.now().difference(serverStartTime).inSeconds,
    'database': db.connected ? 'connected' : 'disconnected',
    'memory': '${ProcessInfo.currentRss ~/ 1024 ~/ 1024} MB',
  };
  
  response.json(health);
});
```

### 4. Use Environment-Specific Configuration

```dart
class Config {
  static final bool isDevelopment = Platform.environment['ENV'] != 'production';
  static final String dbUrl = Platform.environment['DATABASE_URL'] ?? 'mongodb://localhost:27017/mydb';
  static final int port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  
  static final bool enableVerboseLogging = isDevelopment;
  static final bool enableCors = isDevelopment;
}
```

## Frequently Asked Questions

### Q: How do I handle file uploads larger than available memory?

**A:** Use streaming uploads instead of loading the entire file into memory:

```dart
router.post('/upload/large', (request, response, pathArgs) async {
  final file = File('uploads/${DateTime.now().millisecondsSinceEpoch}.bin');
  final sink = file.openWrite();
  
  try {
    await request.rawRequest.pipe(sink);
    response.json({'message': 'File uploaded successfully'});
  } finally {
    await sink.close();
  }
});
```

### Q: Can I use Dart Flux with WebSockets?

**A:** Yes, you can handle WebSocket upgrades in your routes:

```dart
router.get('/ws', (request, response, pathArgs) async {
  if (WebSocketTransformer.isUpgradeRequest(request.rawRequest)) {
    final socket = await WebSocketTransformer.upgrade(request.rawRequest);
    handleWebSocket(socket);
  } else {
    response.status(400).json({'error': 'WebSocket upgrade required'});
  }
});
```

### Q: How do I implement rate limiting?

**A:** Create a rate limiting middleware:

```dart
final rateLimiter = <String, List<DateTime>>{};

Middleware createRateLimit({required int maxRequests, required Duration window}) {
  return (request, response, next) async {
    final clientId = request.rawRequest.connectionInfo?.remoteAddress.address ?? 'unknown';
    final now = DateTime.now();
    
    rateLimiter.putIfAbsent(clientId, () => []);
    final requests = rateLimiter[clientId]!;
    
    // Remove old requests
    requests.removeWhere((time) => now.difference(time) > window);
    
    if (requests.length >= maxRequests) {
      response.status(429).json({'error': 'Rate limit exceeded'});
      return;
    }
    
    requests.add(now);
    await next();
  };
}
```

### Q: How do I deploy Dart Flux to production?

**A:** Create a deployment configuration:

1. **Build executable:**
```bash
dart compile exe bin/main.dart -o server
```

2. **Create systemd service (Linux):**
```ini
[Unit]
Description=Dart Flux Server
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/path/to/app
ExecStart=/path/to/app/server
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

3. **Use environment variables:**
```dart
void main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final dbUrl = Platform.environment['DATABASE_URL'] ?? 'mongodb://localhost:27017/mydb';
  
  final server = Server(InternetAddress.anyIPv4, port, router);
  await server.run();
}
```

### Q: How do I handle database transactions?

**A:** MongoDB doesn't support traditional transactions, but you can use sessions:

```dart
Future<void> transferFunds(String fromUserId, String toUserId, double amount) async {
  final session = await db.db.createSession();
  
  try {
    await session.withTransaction(() async {
      // Debit from user
      await usersCollection.updateOne(
        where.eq('_id', ObjectId.fromHexString(fromUserId)),
        modify.inc('balance', -amount),
        session: session,
      );
      
      // Credit to user
      await usersCollection.updateOne(
        where.eq('_id', ObjectId.fromHexString(toUserId)),
        modify.inc('balance', amount),
        session: session,
      );
    });
  } finally {
    await session.close();
  }
}
```

This troubleshooting guide covers the most common issues you might encounter when working with Dart Flux. If you encounter issues not covered here, check the server logs, enable verbose debugging, and consider opening an issue in the project repository.

---

## 📚 Need More Help?

### Common Issues by Topic
- **[Server Setup Issues →](server-setup.md)** - Production deployment problems
- **[Authentication Troubles →](authentication.md)** - Security and login issues
- **[Database Problems →](database.md)** - MongoDB connection and query issues
- **[File Upload Issues →](file-management.md)** - File handling problems
- **[Routing Confusion →](routing_examples.md)** - Routing and middleware issues

### Advanced Debugging
- **[Architecture Overview](architecture-overview.md)** - Understand system flow
- **[Advanced Patterns](advanced-usage-patterns.md)** - Complex implementation issues
- **[Best Practices](best-practices-security.md)** - Performance and security

### Documentation
- **[API Reference](api-reference.md)** - Complete technical reference
- **[Integration Guides](integration-guides.md)** - Third-party service issues

### Community Support
- **GitHub Issues** - Report bugs or request features
- **Documentation Feedback** - Suggest improvements to this guide

---

📖 **[Back to Documentation Index](README.md)**
