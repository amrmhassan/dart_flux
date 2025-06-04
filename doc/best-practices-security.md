# Best Practices and Security

This guide outlines essential best practices and security considerations for building secure, maintainable, and performant applications with Dart Flux.

> 🔒 **Security First:** This guide focuses on production-ready security practices. Implement these patterns from the start of your project.
>
> 📖 **Related Documentation:**
> - [Authentication](authentication.md) - Secure authentication implementation
> - [Advanced Patterns](advanced-usage-patterns.md) - Security-focused advanced patterns
> - [Integration Guides](integration-guides.md) - Secure third-party integrations
> - [Troubleshooting](troubleshooting-guide.md) - Security issue resolution

## Table of Contents

- [Security Best Practices](#security-best-practices)
- [Authentication and Authorization](#authentication-and-authorization)
- [Input Validation and Sanitization](#input-validation-and-sanitization)
- [Error Handling and Logging](#error-handling-and-logging)
- [Performance Optimization](#performance-optimization)
- [Database Security](#database-security)
- [File Upload Security](#file-upload-security)
- [CORS and Cross-Origin Security](#cors-and-cross-origin-security)
- [Monitoring and Observability](#monitoring-and-observability)
- [Code Organization](#code-organization)

## Security Best Practices

### 1. Secure Headers

Always implement security headers to protect against common attacks:

```dart
Processor securityHeadersMiddleware = (request, response, pathArgs) {
  // Prevent clickjacking
  response.headers.add('X-Frame-Options', 'DENY');
  
  // Prevent MIME type sniffing
  response.headers.add('X-Content-Type-Options', 'nosniff');
  
  // Enable XSS protection
  response.headers.add('X-XSS-Protection', '1; mode=block');
  
  // Enforce HTTPS
  response.headers.add('Strict-Transport-Security', 
    'max-age=31536000; includeSubDomains; preload');
  
  // Content Security Policy
  response.headers.add('Content-Security-Policy',
    "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'");
  
  // Referrer Policy
  response.headers.add('Referrer-Policy', 'strict-origin-when-cross-origin');
  
  // Permissions Policy
  response.headers.add('Permissions-Policy',
    'geolocation=(), microphone=(), camera=()');
  
  return request;
};

// Apply to all routes
Router mainRouter = Router()
  .upper(securityHeadersMiddleware);
```

### 2. Rate Limiting

Implement comprehensive rate limiting to prevent abuse:

```dart
class RateLimiter {
  final Map<String, List<DateTime>> _requests = {};
  final int maxRequests;
  final Duration timeWindow;
  final Duration blockDuration;
  
  RateLimiter({
    required this.maxRequests,
    required this.timeWindow,
    this.blockDuration = const Duration(minutes: 15),
  });
  
  bool isAllowed(String identifier) {
    DateTime now = DateTime.now();
    
    // Clean old requests
    _requests[identifier]?.removeWhere(
      (timestamp) => now.difference(timestamp) > timeWindow
    );
    
    List<DateTime> requests = _requests[identifier] ??= [];
    
    if (requests.length >= maxRequests) {
      // Check if still in block period
      if (requests.isNotEmpty && 
          now.difference(requests.last) < blockDuration) {
        return false;
      }
      // Reset if block period has passed
      requests.clear();
    }
    
    requests.add(now);
    return true;
  }
  
  Duration getRemainingBlockTime(String identifier) {
    List<DateTime>? requests = _requests[identifier];
    if (requests == null || requests.isEmpty) return Duration.zero;
    
    Duration elapsed = DateTime.now().difference(requests.last);
    return blockDuration - elapsed;
  }
}

// Rate limiting middleware
Processor rateLimitMiddleware = (request, response, pathArgs) {
  String clientIp = request.request.connectionInfo?.remoteAddress.address ?? 'unknown';
  
  if (!rateLimiter.isAllowed(clientIp)) {
    Duration remaining = rateLimiter.getRemainingBlockTime(clientIp);
    response.headers.add('Retry-After', remaining.inSeconds.toString());
    response.headers.add('X-RateLimit-Limit', rateLimiter.maxRequests.toString());
    response.headers.add('X-RateLimit-Remaining', '0');
    
    return response.error(
      'Rate limit exceeded. Try again in ${remaining.inMinutes} minutes.',
      status: HttpStatus.tooManyRequests
    );
  }
  
  return request;
};
```

### 3. Request Size Limiting

Protect against large payload attacks:

```dart
Processor requestSizeLimitMiddleware = (request, response, pathArgs) {
  const int maxBodySize = 10 * 1024 * 1024; // 10MB
  
  int? contentLength = request.headers.contentLength;
  if (contentLength != null && contentLength > maxBodySize) {
    return response.error(
      'Request body too large',
      status: HttpStatus.requestEntityTooLarge
    );
  }
  
  return request;
};
```

## Authentication and Authorization

### 1. JWT Best Practices

Implement secure JWT handling:

```dart
class SecureJWTService {
  final String _secretKey;
  final Duration _accessTokenExpiry;
  final Duration _refreshTokenExpiry;
  
  SecureJWTService({
    required String secretKey,
    this._accessTokenExpiry = const Duration(minutes: 15),
    this._refreshTokenExpiry = const Duration(days: 7),
  }) : _secretKey = secretKey;
  
  TokenPair generateTokens(User user) {
    // Short-lived access token
    String accessToken = JWT.encode({
      'sub': user.id,
      'email': user.email,
      'roles': user.roles,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now().add(_accessTokenExpiry).millisecondsSinceEpoch ~/ 1000,
      'type': 'access',
    }, _secretKey);
    
    // Long-lived refresh token (store hash in database)
    String refreshToken = JWT.encode({
      'sub': user.id,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now().add(_refreshTokenExpiry).millisecondsSinceEpoch ~/ 1000,
      'type': 'refresh',
      'jti': generateUuid(), // Unique token ID for revocation
    }, _secretKey);
    
    return TokenPair(accessToken, refreshToken);
  }
  
  ClaimSet? validateToken(String token, {required String expectedType}) {
    try {
      Map<String, dynamic> payload = JWT.decode(token, _secretKey);
      
      // Verify token type
      if (payload['type'] != expectedType) {
        return null;
      }
      
      // Check expiration
      int exp = payload['exp'];
      if (DateTime.now().millisecondsSinceEpoch ~/ 1000 > exp) {
        return null;
      }
      
      return ClaimSet.fromMap(payload);
    } catch (e) {
      return null;
    }
  }
}

// Authentication middleware
Processor jwtAuthMiddleware = (request, response, pathArgs) {
  String? authHeader = request.headers.value('Authorization');
  
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    return response.unauthorized('Missing or invalid authorization header');
  }
  
  String token = authHeader.substring(7);
  ClaimSet? claims = jwtService.validateToken(token, expectedType: 'access');
  
  if (claims == null) {
    return response.unauthorized('Invalid or expired token');
  }
  
  // Add user info to request context
  request.context.add('userId', claims.subject);
  request.context.add('userRoles', claims.roles);
  
  return request;
};
```

### 2. Session Management

Implement secure session handling:

```dart
class SessionManager {
  final MemoryCache<String, Session> _sessions;
  final Duration _sessionTimeout;
  
  SessionManager({
    this._sessionTimeout = const Duration(hours: 24),
  }) : _sessions = MemoryCache();
  
  String createSession(User user) {
    String sessionId = generateSecureSessionId();
    
    Session session = Session(
      id: sessionId,
      userId: user.id,
      createdAt: DateTime.now(),
      lastAccessedAt: DateTime.now(),
      ipAddress: getCurrentRequestIP(),
      userAgent: getCurrentRequestUserAgent(),
    );
    
    _sessions.set(sessionId, session, ttl: _sessionTimeout);
    return sessionId;
  }
  
  Session? getSession(String sessionId) {
    Session? session = _sessions.get(sessionId);
    if (session != null) {
      // Update last accessed time
      session.lastAccessedAt = DateTime.now();
      _sessions.set(sessionId, session, ttl: _sessionTimeout);
    }
    return session;
  }
  
  void invalidateSession(String sessionId) {
    _sessions.remove(sessionId);
  }
  
  void invalidateAllUserSessions(String userId) {
    // Remove all sessions for a specific user
    _sessions.removeWhere((key, session) => session.userId == userId);
  }
}
```

## Input Validation and Sanitization

### 1. Request Validation

Create comprehensive input validation:

```dart
abstract class Validator<T> {
  ValidationResult validate(T value);
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  
  ValidationResult(this.isValid, [this.errors = const []]);
  
  factory ValidationResult.success() => ValidationResult(true);
  factory ValidationResult.failure(List<String> errors) => 
    ValidationResult(false, errors);
}

class EmailValidator implements Validator<String> {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
  );
  
  @override
  ValidationResult validate(String email) {
    if (!_emailRegex.hasMatch(email)) {
      return ValidationResult.failure(['Invalid email format']);
    }
    return ValidationResult.success();
  }
}

class PasswordValidator implements Validator<String> {
  final int minLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireNumbers;
  final bool requireSpecialChars;
  
  PasswordValidator({
    this.minLength = 8,
    this.requireUppercase = true,
    this.requireLowercase = true,
    this.requireNumbers = true,
    this.requireSpecialChars = true,
  });
  
  @override
  ValidationResult validate(String password) {
    List<String> errors = [];
    
    if (password.length < minLength) {
      errors.add('Password must be at least $minLength characters long');
    }
    
    if (requireUppercase && !password.contains(RegExp(r'[A-Z]'))) {
      errors.add('Password must contain at least one uppercase letter');
    }
    
    if (requireLowercase && !password.contains(RegExp(r'[a-z]'))) {
      errors.add('Password must contain at least one lowercase letter');
    }
    
    if (requireNumbers && !password.contains(RegExp(r'[0-9]'))) {
      errors.add('Password must contain at least one number');
    }
    
    if (requireSpecialChars && !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('Password must contain at least one special character');
    }
    
    return errors.isEmpty 
      ? ValidationResult.success() 
      : ValidationResult.failure(errors);
  }
}

// Validation middleware
Processor validationMiddleware(Map<String, Validator> validators) {
  return (request, response, pathArgs) async {
    Map<String, dynamic> data = await request.readAsJson();
    Map<String, List<String>> allErrors = {};
    
    for (String field in validators.keys) {
      if (data.containsKey(field)) {
        ValidationResult result = validators[field]!.validate(data[field]);
        if (!result.isValid) {
          allErrors[field] = result.errors;
        }
      }
    }
    
    if (allErrors.isNotEmpty) {
      return response.badRequest({
        'message': 'Validation failed',
        'errors': allErrors,
      });
    }
    
    return request;
  };
}

// Usage
Router authRouter = Router.path('auth')
  .post('register', registerHandler)
  .middleware(validationMiddleware({
    'email': EmailValidator(),
    'password': PasswordValidator(),
    'firstName': RequiredStringValidator(minLength: 2, maxLength: 50),
    'lastName': RequiredStringValidator(minLength: 2, maxLength: 50),
  }));
```

### 2. SQL Injection Prevention

Even with NoSQL databases, prevent injection attacks:

```dart
class QuerySanitizer {
  static Map<String, dynamic> sanitizeFilter(Map<String, dynamic> filter) {
    Map<String, dynamic> sanitized = {};
    
    for (String key in filter.keys) {
      // Prevent NoSQL injection operators
      if (key.startsWith('\$')) {
        continue; // Skip potentially dangerous operators
      }
      
      dynamic value = filter[key];
      
      if (value is String) {
        // Sanitize string values
        sanitized[key] = value.replaceAll(RegExp(r'[^\w\s@.-]'), '');
      } else if (value is Map) {
        // Recursively sanitize nested objects
        sanitized[key] = sanitizeFilter(value.cast<String, dynamic>());
      } else {
        sanitized[key] = value;
      }
    }
    
    return sanitized;
  }
  
  static List<String> getAllowedSortFields() {
    return ['name', 'email', 'createdAt', 'updatedAt'];
  }
  
  static Map<String, int> sanitizeSortOptions(Map<String, dynamic> sort) {
    Map<String, int> sanitized = {};
    List<String> allowed = getAllowedSortFields();
    
    for (String key in sort.keys) {
      if (allowed.contains(key)) {
        int direction = sort[key] == -1 ? -1 : 1;
        sanitized[key] = direction;
      }
    }
    
    return sanitized;
  }
}
```

## Error Handling and Logging

### 1. Structured Error Handling

Implement comprehensive error handling:

```dart
abstract class AppException implements Exception {
  String get message;
  int get statusCode;
  String get code;
  Map<String, dynamic> get details;
}

class ValidationException extends AppException {
  @override
  final String message;
  @override
  final int statusCode = HttpStatus.badRequest;
  @override
  final String code = 'VALIDATION_ERROR';
  final Map<String, List<String>> fieldErrors;
  
  ValidationException(this.message, this.fieldErrors);
  
  @override
  Map<String, dynamic> get details => {'fieldErrors': fieldErrors};
}

class AuthenticationException extends AppException {
  @override
  final String message;
  @override
  final int statusCode = HttpStatus.unauthorized;
  @override
  final String code = 'AUTHENTICATION_ERROR';
  
  AuthenticationException(this.message);
  
  @override
  Map<String, dynamic> get details => {};
}

class AuthorizationException extends AppException {
  @override
  final String message;
  @override
  final int statusCode = HttpStatus.forbidden;
  @override
  final String code = 'AUTHORIZATION_ERROR';
  final String? requiredPermission;
  
  AuthorizationException(this.message, {this.requiredPermission});
  
  @override
  Map<String, dynamic> get details => {
    if (requiredPermission != null) 'requiredPermission': requiredPermission,
  };
}

// Global error handler
ProcessorHandler globalErrorHandler = (request, response, pathArgs) async {
  return response.json({
    'error': {
      'message': 'Internal server error',
      'code': 'INTERNAL_ERROR',
      'timestamp': DateTime.now().toIso8601String(),
      'requestId': generateRequestId(),
    }
  }, status: HttpStatus.internalServerError);
};

// Error handling middleware
LowerProcessor errorHandlingMiddleware = (request, response, pathArgs) async {
  if (response.code >= 400) {
    String? errorData = response.data as String?;
    
    // Log error details
    logger.error('Request failed', extra: {
      'path': request.path,
      'method': request.method.name,
      'statusCode': response.code,
      'errorData': errorData,
      'userAgent': request.headers.value('user-agent'),
      'clientIp': request.request.connectionInfo?.remoteAddress.address,
    });
  }
};
```

### 2. Structured Logging

Implement comprehensive logging:

```dart
enum LogLevel { debug, info, warn, error, fatal }

class StructuredLogger {
  final String serviceName;
  final String version;
  final LogLevel minLevel;
  
  StructuredLogger({
    required this.serviceName,
    required this.version,
    this.minLevel = LogLevel.info,
  });
  
  void log(
    LogLevel level, 
    String message, {
    Map<String, dynamic>? extra,
    Exception? exception,
    StackTrace? stackTrace,
  }) {
    if (level.index < minLevel.index) return;
    
    Map<String, dynamic> logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level.name.toUpperCase(),
      'service': serviceName,
      'version': version,
      'message': message,
      if (extra != null) ...extra,
      if (exception != null) 'exception': exception.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };
    
    // Output as JSON for structured logging systems
    print(jsonEncode(logEntry));
  }
  
  void debug(String message, {Map<String, dynamic>? extra}) =>
    log(LogLevel.debug, message, extra: extra);
  
  void info(String message, {Map<String, dynamic>? extra}) =>
    log(LogLevel.info, message, extra: extra);
  
  void warn(String message, {Map<String, dynamic>? extra}) =>
    log(LogLevel.warn, message, extra: extra);
  
  void error(String message, {Map<String, dynamic>? extra, Exception? exception, StackTrace? stackTrace}) =>
    log(LogLevel.error, message, extra: extra, exception: exception, stackTrace: stackTrace);
  
  void fatal(String message, {Map<String, dynamic>? extra, Exception? exception, StackTrace? stackTrace}) =>
    log(LogLevel.fatal, message, extra: extra, exception: exception, stackTrace: stackTrace);
}

// Request logging middleware
Processor requestLoggingMiddleware = (request, response, pathArgs) {
  String requestId = generateRequestId();
  request.context.add('requestId', requestId);
  request.context.add('startTime', DateTime.now());
  
  logger.info('Request started', extra: {
    'requestId': requestId,
    'method': request.method.name,
    'path': request.path,
    'query': request.uri.query,
    'userAgent': request.headers.value('user-agent'),
    'clientIp': request.request.connectionInfo?.remoteAddress.address,
  });
  
  return request;
};

LowerProcessor responseLoggingMiddleware = (request, response, pathArgs) async {
  String requestId = request.context.get('requestId');
  DateTime startTime = request.context.get('startTime');
  Duration processingTime = DateTime.now().difference(startTime);
  
  logger.info('Request completed', extra: {
    'requestId': requestId,
    'statusCode': response.code,
    'processingTimeMs': processingTime.inMilliseconds,
    'responseSize': response.data?.toString().length ?? 0,
  });
};
```

## Performance Optimization

### 1. Connection Pooling

Implement efficient database connection management:

```dart
class ConnectionPool {
  final Queue<MongoDBConnection> _available = Queue();
  final Set<MongoDBConnection> _inUse = {};
  final int maxConnections;
  final int minConnections;
  
  ConnectionPool({
    this.maxConnections = 10,
    this.minConnections = 2,
  });
  
  Future<void> initialize() async {
    for (int i = 0; i < minConnections; i++) {
      MongoDBConnection conn = await createConnection();
      _available.add(conn);
    }
  }
  
  Future<MongoDBConnection> acquire() async {
    if (_available.isNotEmpty) {
      MongoDBConnection conn = _available.removeFirst();
      _inUse.add(conn);
      return conn;
    }
    
    if (_inUse.length < maxConnections) {
      MongoDBConnection conn = await createConnection();
      _inUse.add(conn);
      return conn;
    }
    
    // Wait for connection to become available
    while (_available.isEmpty) {
      await Future.delayed(Duration(milliseconds: 10));
    }
    
    return acquire();
  }
  
  void release(MongoDBConnection connection) {
    if (_inUse.remove(connection)) {
      _available.add(connection);
    }
  }
  
  Future<T> execute<T>(Future<T> Function(MongoDBConnection) operation) async {
    MongoDBConnection conn = await acquire();
    try {
      return await operation(conn);
    } finally {
      release(conn);
    }
  }
}
```

### 2. Response Compression

Implement automatic response compression:

```dart
Processor compressionMiddleware = (request, response, pathArgs) {
  String? acceptEncoding = request.headers.value('accept-encoding');
  
  if (acceptEncoding != null && acceptEncoding.contains('gzip')) {
    request.context.add('enableCompression', true);
    response.headers.add('Content-Encoding', 'gzip');
    response.headers.add('Vary', 'Accept-Encoding');
  }
  
  return request;
};

LowerProcessor compressionLowerMiddleware = (request, response, pathArgs) async {
  bool enableCompression = request.context.get('enableCompression') ?? false;
  
  if (enableCompression && response.data != null) {
    String responseData = response.data.toString();
    
    // Only compress if response is large enough to benefit
    if (responseData.length > 1024) {
      List<int> compressed = gzip.encode(utf8.encode(responseData));
      response.data = compressed;
      response.headers.add('Content-Length', compressed.length.toString());
    }
  }
};
```

## Database Security

### 1. Connection Security

Secure database connections:

```dart
class SecureMongoDBConnection {
  static Future<MongoDBConnection> connect({
    required String host,
    required int port,
    required String database,
    required String username,
    required String password,
    bool enableSSL = true,
    String? certificatePath,
  }) async {
    String connectionString = 'mongodb://$username:$password@$host:$port/$database';
    
    if (enableSSL) {
      connectionString += '?ssl=true';
      
      if (certificatePath != null) {
        connectionString += '&sslCertificateKeyFile=$certificatePath';
      }
    }
    
    MongoDBConnection connection = await MongoDBConnection.connect(connectionString);
    
    // Test connection
    await connection.collection('_healthcheck').findOne({});
    
    return connection;
  }
}
```

### 2. Data Encryption

Implement field-level encryption for sensitive data:

```dart
class FieldEncryption {
  final String _encryptionKey;
  
  FieldEncryption(this._encryptionKey);
  
  String encrypt(String plaintext) {
    // Use a proper encryption library like cryptography
    var encryptor = AES(Key.fromBase64(_encryptionKey));
    var encrypted = encryptor.encrypt(plaintext);
    return encrypted.base64;
  }
  
  String decrypt(String ciphertext) {
    var encryptor = AES(Key.fromBase64(_encryptionKey));
    var decrypted = encryptor.decrypt64(ciphertext);
    return decrypted;
  }
  
  Map<String, dynamic> encryptFields(
    Map<String, dynamic> document, 
    List<String> fieldsToEncrypt
  ) {
    Map<String, dynamic> encrypted = Map.from(document);
    
    for (String field in fieldsToEncrypt) {
      if (encrypted.containsKey(field) && encrypted[field] is String) {
        encrypted[field] = encrypt(encrypted[field]);
        encrypted['${field}_encrypted'] = true;
      }
    }
    
    return encrypted;
  }
  
  Map<String, dynamic> decryptFields(
    Map<String, dynamic> document, 
    List<String> fieldsToDecrypt
  ) {
    Map<String, dynamic> decrypted = Map.from(document);
    
    for (String field in fieldsToDecrypt) {
      if (decrypted.containsKey(field) && 
          decrypted['${field}_encrypted'] == true) {
        decrypted[field] = decrypt(decrypted[field]);
        decrypted.remove('${field}_encrypted');
      }
    }
    
    return decrypted;
  }
}
```

## File Upload Security

### 1. File Type Validation

Implement comprehensive file validation:

```dart
class FileValidator {
  static final Map<String, List<String>> _allowedMimeTypes = {
    'image': ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
    'document': ['application/pdf', 'text/plain', 'application/msword'],
    'archive': ['application/zip', 'application/x-rar-compressed'],
  };
  
  static final Map<String, List<int>> _fileSignatures = {
    'image/jpeg': [0xFF, 0xD8, 0xFF],
    'image/png': [0x89, 0x50, 0x4E, 0x47],
    'application/pdf': [0x25, 0x50, 0x44, 0x46],
  };
  
  static ValidationResult validateFile(File file, String category) {
    List<String> errors = [];
    
    // Check file size (10MB limit)
    int fileSize = file.lengthSync();
    if (fileSize > 10 * 1024 * 1024) {
      errors.add('File size exceeds 10MB limit');
    }
    
    // Check file extension
    String extension = path.extension(file.path).toLowerCase();
    String mimeType = lookupMimeType(file.path) ?? '';
    
    List<String>? allowedTypes = _allowedMimeTypes[category];
    if (allowedTypes == null || !allowedTypes.contains(mimeType)) {
      errors.add('File type not allowed for category: $category');
    }
    
    // Validate file signature (magic bytes)
    if (!_validateFileSignature(file, mimeType)) {
      errors.add('File content does not match declared type');
    }
    
    return errors.isEmpty 
      ? ValidationResult.success() 
      : ValidationResult.failure(errors);
  }
  
  static bool _validateFileSignature(File file, String mimeType) {
    List<int>? expectedSignature = _fileSignatures[mimeType];
    if (expectedSignature == null) return true; // No signature check for this type
    
    List<int> fileBytes = file.readAsBytesSync().take(expectedSignature.length).toList();
    
    for (int i = 0; i < expectedSignature.length; i++) {
      if (i >= fileBytes.length || fileBytes[i] != expectedSignature[i]) {
        return false;
      }
    }
    
    return true;
  }
}

// Secure file upload handler
ProcessorHandler secureFileUpload = (request, response, pathArgs) async {
  String category = pathArgs['category'] ?? 'document';
  
  FormData formData = await request.readAsFormData(saveFolder: 'temp');
  
  for (FileData file in formData.files) {
    File uploadedFile = File(file.filePath);
    
    // Validate file
    ValidationResult validation = FileValidator.validateFile(uploadedFile, category);
    if (!validation.isValid) {
      await uploadedFile.delete();
      return response.badRequest({
        'message': 'File validation failed',
        'errors': validation.errors,
      });
    }
    
    // Generate secure filename
    String secureFilename = generateSecureFilename(file.fileName);
    String finalPath = path.join('uploads', category, secureFilename);
    
    // Move to secure location
    await uploadedFile.rename(finalPath);
    
    // Store file metadata
    await fileRepository.create({
      'originalName': file.fileName,
      'storedName': secureFilename,
      'path': finalPath,
      'size': await File(finalPath).length(),
      'mimeType': lookupMimeType(finalPath),
      'uploadedAt': DateTime.now(),
      'category': category,
    });
  }
  
  return response.json({'message': 'Files uploaded successfully'});
};
```

---

## 📚 Documentation Navigation

### Security Implementation
- **[← Authentication](authentication.md)** - Secure authentication patterns
- **[Advanced Patterns](advanced-usage-patterns.md)** - Security-focused implementations
- **[File Management](file-management.md)** - Secure file handling

### Production Setup
- **[Server Setup →](server-setup.md)** - Production deployment security
- **[Integration Guides →](integration-guides.md)** - Secure external integrations
- **[Database Operations](database.md)** - Database security practices

### Monitoring & Maintenance
- **[Error Handling](error-handling.md)** - Secure error management
- **[Troubleshooting](troubleshooting-guide.md)** - Security issue resolution
- **[Webhooks](webhooks.md)** - Secure webhook handling

### Reference
- **[API Reference](api-reference.md)** - Security-related APIs
- **[Architecture Overview](architecture-overview.md)** - Security architecture

---

📖 **[Back to Documentation Index](README.md)**

This comprehensive guide provides essential security practices and optimizations for building robust Dart Flux applications. Always stay updated with the latest security practices and regularly audit your application for vulnerabilities.
