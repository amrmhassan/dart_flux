# Integration Guides

This guide provides comprehensive examples for integrating Dart Flux with various services, databases, and third-party systems commonly used in production applications.

> 🔌 **Integration Ready:** These guides assume you have a working Dart Flux application.
>
> 📖 **Prerequisites:**
> - [Getting Started](getting-started.md) - Basic Dart Flux setup
> - [Architecture Overview](architecture-overview.md) - Understanding system design
> - [Advanced Patterns](advanced-usage-patterns.md) - Complex integration patterns
>
> 🔒 **Security:** See [Best Practices & Security](best-practices-security.md) for secure integration guidelines.

## Table of Contents

- [Database Integrations](#database-integrations)
- [Authentication Providers](#authentication-providers)
- [File Storage Services](#file-storage-services)
- [Message Queues](#message-queues)
- [Email Services](#email-services)
- [Payment Processors](#payment-processors)
- [Monitoring and Analytics](#monitoring-and-analytics)
- [CI/CD Integration](#cicd-integration)
- [Docker and Container Deployment](#docker-and-container-deployment)
- [Load Balancing and Clustering](#load-balancing-and-clustering)

## Database Integrations

### PostgreSQL Integration

```dart
import 'package:postgres/postgres.dart';

class PostgreSQLConnection {
  late PostgreSQLConnection _connection;
  
  Future<void> connect({
    required String host,
    required int port,
    required String database,
    required String username,
    required String password,
  }) async {
    _connection = PostgreSQLConnection(
      host,
      port,
      database,
      username: username,
      password: password,
    );
    
    await _connection.open();
  }
  
  Future<List<Map<String, Map<String, dynamic>>>> query(
    String sql, 
    [Map<String, dynamic>? substitutionValues]
  ) async {
    return await _connection.query(sql, substitutionValues: substitutionValues);
  }
  
  Future<void> execute(
    String sql, 
    [Map<String, dynamic>? substitutionValues]
  ) async {
    await _connection.execute(sql, substitutionValues: substitutionValues);
  }
}

// PostgreSQL service layer
class PostgreSQLUserService {
  final PostgreSQLConnection connection;
  
  PostgreSQLUserService(this.connection);
  
  Future<Map<String, dynamic>?> findById(String id) async {
    var results = await connection.query(
      'SELECT * FROM users WHERE id = @id',
      {'id': id}
    );
    
    return results.isNotEmpty ? results.first : null;
  }
  
  Future<String> create(Map<String, dynamic> userData) async {
    var results = await connection.query(
      '''
      INSERT INTO users (email, password_hash, first_name, last_name, created_at)
      VALUES (@email, @password_hash, @first_name, @last_name, @created_at)
      RETURNING id
      ''',
      {
        'email': userData['email'],
        'password_hash': userData['passwordHash'],
        'first_name': userData['firstName'],
        'last_name': userData['lastName'],
        'created_at': DateTime.now().toIso8601String(),
      }
    );
    
    return results.first['id'];
  }
  
  Future<void> update(String id, Map<String, dynamic> updates) async {
    List<String> setParts = [];
    Map<String, dynamic> values = {'id': id};
    
    updates.forEach((key, value) {
      setParts.add('$key = @$key');
      values[key] = value;
    });
    
    await connection.execute(
      'UPDATE users SET ${setParts.join(', ')}, updated_at = @updated_at WHERE id = @id',
      {...values, 'updated_at': DateTime.now().toIso8601String()}
    );
  }
}

// Integration with Dart Flux
class PostgreSQLModule {
  static Router createUserRouter() {
    return Router.path('users')
      .get(':id', getUserHandler)
      .post('/', createUserHandler)
      .put(':id', updateUserHandler)
      .delete(':id', deleteUserHandler);
  }
  
  static ProcessorHandler getUserHandler = (request, response, pathArgs) async {
    String userId = pathArgs['id'];
    
    Map<String, dynamic>? user = await userService.findById(userId);
    if (user == null) {
      return response.notFound('User not found');
    }
    
    // Remove sensitive data
    user.remove('password_hash');
    
    return response.json(user);
  };
  
  static ProcessorHandler createUserHandler = (request, response, pathArgs) async {
    var data = await request.readAsJson();
    
    // Validate input
    if (data['email'] == null || data['password'] == null) {
      return response.badRequest('Email and password are required');
    }
    
    // Hash password
    String passwordHash = hashPassword(data['password']);
    data['passwordHash'] = passwordHash;
    data.remove('password');
    
    try {
      String userId = await userService.create(data);
      return response.json({'id': userId, 'message': 'User created successfully'});
    } catch (e) {
      if (e.toString().contains('unique constraint')) {
        return response.conflict('Email already exists');
      }
      throw e;
    }
  };
}
```

### Redis Integration

```dart
import 'package:redis/redis.dart';

class RedisService {
  late RedisConnection _connection;
  late Command _command;
  
  Future<void> connect({
    String host = 'localhost',
    int port = 6379,
    String? password,
    int database = 0,
  }) async {
    _connection = RedisConnection();
    _command = await _connection.connect(host, port);
    
    if (password != null) {
      await _command.send_object(['AUTH', password]);
    }
    
    if (database != 0) {
      await _command.send_object(['SELECT', database]);
    }
  }
  
  // Session management
  Future<void> setSession(String sessionId, Map<String, dynamic> data, {Duration? ttl}) async {
    String jsonData = jsonEncode(data);
    
    if (ttl != null) {
      await _command.send_object(['SETEX', 'session:$sessionId', ttl.inSeconds, jsonData]);
    } else {
      await _command.send_object(['SET', 'session:$sessionId', jsonData]);
    }
  }
  
  Future<Map<String, dynamic>?> getSession(String sessionId) async {
    var result = await _command.send_object(['GET', 'session:$sessionId']);
    if (result == null) return null;
    
    return jsonDecode(result);
  }
  
  Future<void> deleteSession(String sessionId) async {
    await _command.send_object(['DEL', 'session:$sessionId']);
  }
  
  // Caching
  Future<void> cache(String key, dynamic value, {Duration? ttl}) async {
    String jsonValue = jsonEncode(value);
    
    if (ttl != null) {
      await _command.send_object(['SETEX', 'cache:$key', ttl.inSeconds, jsonValue]);
    } else {
      await _command.send_object(['SET', 'cache:$key', jsonValue]);
    }
  }
  
  Future<T?> getCached<T>(String key) async {
    var result = await _command.send_object(['GET', 'cache:$key']);
    if (result == null) return null;
    
    return jsonDecode(result) as T?;
  }
  
  // Rate limiting
  Future<bool> checkRateLimit(String identifier, int maxRequests, Duration window) async {
    String key = 'ratelimit:$identifier';
    
    var pipeline = _command.pipe_start();
    pipeline.send_object(['INCR', key]);
    pipeline.send_object(['EXPIRE', key, window.inSeconds]);
    var results = await pipeline.pipe_end();
    
    int currentCount = results[0];
    return currentCount <= maxRequests;
  }
}

// Redis-backed session middleware
Processor redisSessionMiddleware = (request, response, pathArgs) async {
  String? sessionId = request.cookies['sessionId'];
  
  if (sessionId != null) {
    Map<String, dynamic>? sessionData = await redisService.getSession(sessionId);
    if (sessionData != null) {
      request.context.add('session', sessionData);
      request.context.add('sessionId', sessionId);
    }
  }
  
  return request;
};

LowerProcessor saveSessionMiddleware = (request, response, pathArgs) async {
  Map<String, dynamic>? session = request.context.get('session');
  String? sessionId = request.context.get('sessionId');
  
  if (session != null && sessionId != null) {
    await redisService.setSession(
      sessionId, 
      session, 
      ttl: Duration(hours: 24)
    );
  }
};
```

## Authentication Providers

### OAuth2 Integration (Google, GitHub, etc.)

```dart
import 'package:oauth2/oauth2.dart' as oauth2;

class OAuth2Provider {
  final String clientId;
  final String clientSecret;
  final String authorizationEndpoint;
  final String tokenEndpoint;
  final List<String> scopes;
  final String redirectUri;
  
  OAuth2Provider({
    required this.clientId,
    required this.clientSecret,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.scopes,
    required this.redirectUri,
  });
  
  // Factory methods for common providers
  factory OAuth2Provider.google({
    required String clientId,
    required String clientSecret,
    required String redirectUri,
  }) {
    return OAuth2Provider(
      clientId: clientId,
      clientSecret: clientSecret,
      authorizationEndpoint: 'https://accounts.google.com/o/oauth2/v2/auth',
      tokenEndpoint: 'https://oauth2.googleapis.com/token',
      scopes: ['openid', 'email', 'profile'],
      redirectUri: redirectUri,
    );
  }
  
  factory OAuth2Provider.github({
    required String clientId,
    required String clientSecret,
    required String redirectUri,
  }) {
    return OAuth2Provider(
      clientId: clientId,
      clientSecret: clientSecret,
      authorizationEndpoint: 'https://github.com/login/oauth/authorize',
      tokenEndpoint: 'https://github.com/login/oauth/access_token',
      scopes: ['user:email'],
      redirectUri: redirectUri,
    );
  }
  
  String getAuthorizationUrl(String state) {
    var grant = oauth2.AuthorizationCodeGrant(
      clientId,
      Uri.parse(authorizationEndpoint),
      Uri.parse(tokenEndpoint),
      secret: clientSecret,
    );
    
    return grant.getAuthorizationUrl(
      Uri.parse(redirectUri),
      scopes: scopes,
      state: state,
    ).toString();
  }
  
  Future<oauth2.Client> handleCallback(String code, String state) async {
    var grant = oauth2.AuthorizationCodeGrant(
      clientId,
      Uri.parse(authorizationEndpoint),
      Uri.parse(tokenEndpoint),
      secret: clientSecret,
    );
    
    return await grant.handleAuthorizationResponse({
      'code': code,
      'state': state,
    });
  }
}

// OAuth2 routes
class OAuth2Module {
  static final OAuth2Provider googleProvider = OAuth2Provider.google(
    clientId: Environment.googleClientId,
    clientSecret: Environment.googleClientSecret,
    redirectUri: '${Environment.baseUrl}/auth/google/callback',
  );
  
  static Router createAuthRouter() {
    return Router.path('auth')
      .get('google', initiateGoogleAuth)
      .get('google/callback', handleGoogleCallback)
      .get('github', initiateGitHubAuth)
      .get('github/callback', handleGitHubCallback);
  }
  
  static ProcessorHandler initiateGoogleAuth = (request, response, pathArgs) async {
    String state = generateSecureRandomString(32);
    
    // Store state in session for validation
    await redisService.cache('oauth_state:$state', {
      'provider': 'google',
      'timestamp': DateTime.now().toIso8601String(),
    }, ttl: Duration(minutes: 10));
    
    String authUrl = googleProvider.getAuthorizationUrl(state);
    return response.redirect(authUrl);
  };
  
  static ProcessorHandler handleGoogleCallback = (request, response, pathArgs) async {
    String? code = request.uri.queryParameters['code'];
    String? state = request.uri.queryParameters['state'];
    String? error = request.uri.queryParameters['error'];
    
    if (error != null) {
      return response.badRequest('OAuth error: $error');
    }
    
    if (code == null || state == null) {
      return response.badRequest('Missing code or state parameter');
    }
    
    // Validate state
    var stateData = await redisService.getCached('oauth_state:$state');
    if (stateData == null) {
      return response.badRequest('Invalid or expired state');
    }
    
    try {
      // Exchange code for token
      oauth2.Client client = await googleProvider.handleCallback(code, state);
      
      // Get user info from Google
      var userResponse = await client.get(Uri.parse('https://www.googleapis.com/oauth2/v1/userinfo'));
      var userData = jsonDecode(userResponse.body);
      
      // Find or create user
      User user = await findOrCreateOAuthUser(userData, 'google');
      
      // Create session
      String sessionToken = await createUserSession(user);
      
      // Set session cookie and redirect
      response.cookies.add(Cookie('sessionToken', sessionToken)
        ..httpOnly = true
        ..secure = true
        ..maxAge = Duration(days: 7).inSeconds);
      
      return response.redirect('/dashboard');
      
    } catch (e) {
      return response.internalServerError('Authentication failed');
    }
  };
}
```

### SAML Integration

```dart
import 'package:saml2/saml2.dart';

class SAMLProvider {
  final String entityId;
  final String ssoUrl;
  final String certificate;
  final String privateKey;
  
  SAMLProvider({
    required this.entityId,
    required this.ssoUrl,
    required this.certificate,
    required this.privateKey,
  });
  
  String createAuthRequest(String relayState) {
    var request = AuthnRequest(
      id: generateUuid(),
      issueInstant: DateTime.now(),
      destination: ssoUrl,
      issuer: entityId,
      nameIdPolicy: NameIdPolicy(format: NameIdFormat.emailAddress),
    );
    
    String xml = request.toXml();
    String encoded = base64Url.encode(utf8.encode(xml));
    
    return '$ssoUrl?SAMLRequest=$encoded&RelayState=$relayState';
  }
  
  SAMLResponse parseResponse(String samlResponse) {
    String decodedXml = utf8.decode(base64.decode(samlResponse));
    return SAMLResponse.fromXml(decodedXml);
  }
  
  bool validateResponse(SAMLResponse response) {
    // Validate signature
    if (!response.isSignatureValid(certificate)) {
      return false;
    }
    
    // Check timestamps
    if (response.isExpired) {
      return false;
    }
    
    // Validate destination
    if (response.destination != entityId) {
      return false;
    }
    
    return true;
  }
}

// SAML routes
Router samlRouter = Router.path('saml')
  .get('login', initiateSAMLAuth)
  .post('acs', handleSAMLResponse)
  .get('metadata', getSAMLMetadata);

ProcessorHandler initiateSAMLAuth = (request, response, pathArgs) async {
  String relayState = generateSecureRandomString(32);
  
  // Store relay state
  await redisService.cache('saml_state:$relayState', {
    'timestamp': DateTime.now().toIso8601String(),
  }, ttl: Duration(minutes: 10));
  
  String authUrl = samlProvider.createAuthRequest(relayState);
  return response.redirect(authUrl);
};

ProcessorHandler handleSAMLResponse = (request, response, pathArgs) async {
  var formData = await request.readAsFormData();
  String? samlResponse = formData.fields['SAMLResponse'];
  String? relayState = formData.fields['RelayState'];
  
  if (samlResponse == null) {
    return response.badRequest('Missing SAML response');
  }
  
  // Validate relay state
  if (relayState != null) {
    var stateData = await redisService.getCached('saml_state:$relayState');
    if (stateData == null) {
      return response.badRequest('Invalid relay state');
    }
  }
  
  try {
    SAMLResponse response = samlProvider.parseResponse(samlResponse);
    
    if (!samlProvider.validateResponse(response)) {
      return response.unauthorized('Invalid SAML response');
    }
    
    // Extract user attributes
    Map<String, dynamic> attributes = response.getAttributes();
    
    // Find or create user
    User user = await findOrCreateSAMLUser(attributes);
    
    // Create session
    String sessionToken = await createUserSession(user);
    
    return response.json({'sessionToken': sessionToken});
    
  } catch (e) {
    return response.internalServerError('SAML authentication failed');
  }
};
```

## File Storage Services

### AWS S3 Integration

```dart
import 'package:aws_s3_api/s3-2006-03-01.dart';

class S3Service {
  late S3 _s3;
  final String bucketName;
  
  S3Service({
    required String accessKey,
    required String secretKey,
    required String region,
    required this.bucketName,
  }) {
    _s3 = S3(
      region: region,
      credentials: AwsClientCredentials(
        accessKey: accessKey,
        secretKey: secretKey,
      ),
    );
  }
  
  Future<String> uploadFile(
    String key,
    File file, {
    String? contentType,
    Map<String, String>? metadata,
  }) async {
    List<int> fileBytes = await file.readAsBytes();
    
    await _s3.putObject(
      bucket: bucketName,
      key: key,
      body: fileBytes,
      contentType: contentType ?? 'application/octet-stream',
      metadata: metadata,
    );
    
    return 'https://$bucketName.s3.amazonaws.com/$key';
  }
  
  Future<Uint8List> downloadFile(String key) async {
    var response = await _s3.getObject(bucket: bucketName, key: key);
    return response.body!;
  }
  
  Future<String> generatePresignedUrl(
    String key, {
    Duration expiry = const Duration(hours: 1),
    String method = 'GET',
  }) async {
    return await _s3.presignUrl(
      bucket: bucketName,
      key: key,
      expiresIn: expiry,
      method: method,
    );
  }
  
  Future<void> deleteFile(String key) async {
    await _s3.deleteObject(bucket: bucketName, key: key);
  }
  
  Future<List<S3Object>> listFiles({String? prefix}) async {
    var response = await _s3.listObjectsV2(
      bucket: bucketName,
      prefix: prefix,
    );
    
    return response.contents ?? [];
  }
}

// S3 file upload handler
ProcessorHandler s3UploadHandler = (request, response, pathArgs) async {
  FormData formData = await request.readAsFormData(saveFolder: 'temp');
  List<Map<String, dynamic>> uploadedFiles = [];
  
  for (FileData fileData in formData.files) {
    File file = File(fileData.filePath);
    
    // Generate unique key
    String key = '${DateTime.now().millisecondsSinceEpoch}_${fileData.fileName}';
    
    try {
      // Upload to S3
      String url = await s3Service.uploadFile(
        key,
        file,
        contentType: fileData.contentType,
        metadata: {
          'originalName': fileData.fileName,
          'uploadedBy': request.context.get('userId') ?? 'anonymous',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      uploadedFiles.add({
        'key': key,
        'url': url,
        'originalName': fileData.fileName,
        'size': file.lengthSync(),
        'contentType': fileData.contentType,
      });
      
      // Save file record to database
      await fileRepository.create({
        'key': key,
        'url': url,
        'originalName': fileData.fileName,
        'size': file.lengthSync(),
        'contentType': fileData.contentType,
        'uploadedBy': request.context.get('userId'),
        'uploadedAt': DateTime.now(),
      });
      
    } finally {
      // Clean up temporary file
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
  
  return response.json({
    'message': 'Files uploaded successfully',
    'files': uploadedFiles,
  });
};

// Presigned URL generator
ProcessorHandler generatePresignedUrl = (request, response, pathArgs) async {
  String fileKey = pathArgs['key'];
  String method = request.uri.queryParameters['method'] ?? 'GET';
  int expiryHours = int.tryParse(request.uri.queryParameters['expiry'] ?? '1') ?? 1;
  
  // Check if user has access to this file
  var fileRecord = await fileRepository.findByKey(fileKey);
  if (fileRecord == null) {
    return response.notFound('File not found');
  }
  
  String userId = request.context.get('userId');
  if (fileRecord['uploadedBy'] != userId && !userHasRole(userId, 'admin')) {
    return response.forbidden('Access denied');
  }
  
  String presignedUrl = await s3Service.generatePresignedUrl(
    fileKey,
    expiry: Duration(hours: expiryHours),
    method: method,
  );
  
  return response.json({
    'url': presignedUrl,
    'expiresIn': Duration(hours: expiryHours).inSeconds,
  });
};
```

### Google Cloud Storage Integration

```dart
import 'package:gcloud/storage.dart';
import 'package:googleapis_auth/auth_io.dart';

class GCStorageService {
  late Storage _storage;
  final String bucketName;
  
  static Future<GCStorageService> create({
    required String projectId,
    required String bucketName,
    required String serviceAccountKey,
  }) async {
    var credentials = ServiceAccountCredentials.fromJson(serviceAccountKey);
    var client = await clientViaServiceAccount(credentials, Storage.SCOPES);
    
    var storage = Storage(client, projectId);
    
    return GCStorageService._(storage, bucketName);
  }
  
  GCStorageService._(this._storage, this.bucketName);
  
  Future<String> uploadFile(
    String objectName,
    File file, {
    Map<String, String>? metadata,
  }) async {
    var bucket = _storage.bucket(bucketName);
    
    var objectInfo = ObjectInfo(
      objectName,
      metadata: ObjectMetadata(
        custom: metadata ?? {},
        contentType: lookupMimeType(file.path),
      ),
    );
    
    var sink = bucket.write(objectInfo);
    
    await file.openRead().pipe(sink);
    
    return 'gs://$bucketName/$objectName';
  }
  
  Future<List<int>> downloadFile(String objectName) async {
    var bucket = _storage.bucket(bucketName);
    var stream = bucket.read(objectName);
    
    var bytes = <int>[];
    await for (var chunk in stream) {
      bytes.addAll(chunk);
    }
    
    return bytes;
  }
  
  Future<String> generateSignedUrl(
    String objectName, {
    Duration expiry = const Duration(hours: 1),
    String method = 'GET',
  }) async {
    var bucket = _storage.bucket(bucketName);
    
    return await bucket.info(objectName).then((_) {
      // Generate signed URL (implementation depends on specific library version)
      return 'https://storage.googleapis.com/$bucketName/$objectName';
    });
  }
}
```

## Message Queues

### RabbitMQ Integration

```dart
import 'package:dart_amqp/dart_amqp.dart';

class RabbitMQService {
  late Client _client;
  late Channel _channel;
  
  Future<void> connect({
    String host = 'localhost',
    int port = 5672,
    String username = 'guest',
    String password = 'guest',
    String virtualHost = '/',
  }) async {
    var settings = ConnectionSettings(
      host: host,
      port: port,
      authProvider: PlainAuthenticator(username, password),
      virtualHost: virtualHost,
    );
    
    _client = Client(settings: settings);
    _channel = await _client.channel();
  }
  
  Future<void> declareQueue(String queueName, {bool durable = true}) async {
    await _channel.queue(queueName, durable: durable);
  }
  
  Future<void> publishMessage(
    String queueName,
    Map<String, dynamic> message, {
    bool persistent = true,
  }) async {
    var queue = await _channel.queue(queueName);
    
    queue.publish(
      jsonEncode(message),
      properties: MessageProperties(
        deliveryMode: persistent ? 2 : 1,
        timestamp: DateTime.now(),
      ),
    );
  }
  
  Future<void> consumeMessages(
    String queueName,
    Future<void> Function(Map<String, dynamic>) handler,
  ) async {
    var queue = await _channel.queue(queueName);
    var consumer = await queue.consume();
    
    consumer.listen((AmqpMessage message) async {
      try {
        var data = jsonDecode(message.payloadAsString);
        await handler(data);
        message.ack();
      } catch (e) {
        message.reject(requeue: false);
        print('Error processing message: $e');
      }
    });
  }
}

// Background job processing
class JobProcessor {
  static final Map<String, Future<void> Function(Map<String, dynamic>)> _handlers = {};
  
  static void registerHandler(String jobType, Future<void> Function(Map<String, dynamic>) handler) {
    _handlers[jobType] = handler;
  }
  
  static Future<void> processJob(Map<String, dynamic> job) async {
    String jobType = job['type'];
    var handler = _handlers[jobType];
    
    if (handler != null) {
      await handler(job);
    } else {
      throw Exception('Unknown job type: $jobType');
    }
  }
  
  static Future<void> startWorker() async {
    await rabbitMQService.consumeMessages('job_queue', processJob);
  }
}

// Email job handler
Future<void> emailJobHandler(Map<String, dynamic> job) async {
  String to = job['to'];
  String subject = job['subject'];
  String body = job['body'];
  
  await emailService.sendEmail(to, subject, body);
  print('Email sent to $to');
}

// Image processing job handler
Future<void> imageProcessingJobHandler(Map<String, dynamic> job) async {
  String imagePath = job['imagePath'];
  List<String> operations = List<String>.from(job['operations']);
  
  for (String operation in operations) {
    await imageProcessor.processImage(imagePath, operation);
  }
  
  print('Image processing completed for $imagePath');
}

// Initialize job handlers
void initializeJobHandlers() {
  JobProcessor.registerHandler('send_email', emailJobHandler);
  JobProcessor.registerHandler('process_image', imageProcessingJobHandler);
}

// Queue a job from an HTTP handler
ProcessorHandler queueEmailJob = (request, response, pathArgs) async {
  var data = await request.readAsJson();
  
  await rabbitMQService.publishMessage('job_queue', {
    'type': 'send_email',
    'to': data['to'],
    'subject': data['subject'],
    'body': data['body'],
    'scheduledAt': DateTime.now().toIso8601String(),
  });
  
  return response.json({'message': 'Email queued for sending'});
};
```

### Apache Kafka Integration

```dart
import 'package:kafka/kafka.dart';

class KafkaService {
  late KafkaProducer _producer;
  late KafkaConsumer _consumer;
  
  Future<void> initialize({
    required List<String> brokers,
    String? clientId,
  }) async {
    var config = KafkaConfig(
      brokers: brokers,
      clientId: clientId ?? 'dart_flux_app',
    );
    
    _producer = KafkaProducer(config);
    _consumer = KafkaConsumer(config);
  }
  
  Future<void> publishEvent(
    String topic,
    String key,
    Map<String, dynamic> event,
  ) async {
    await _producer.send(ProducerRecord(
      topic: topic,
      key: key,
      value: jsonEncode(event),
      timestamp: DateTime.now(),
    ));
  }
  
  Stream<Map<String, dynamic>> consumeEvents(
    String topic,
    String groupId,
  ) async* {
    await _consumer.subscribe([topic], groupId: groupId);
    
    await for (var record in _consumer.stream) {
      yield {
        'topic': record.topic,
        'key': record.key,
        'value': jsonDecode(record.value),
        'timestamp': record.timestamp,
        'offset': record.offset,
      };
    }
  }
}

// Event-driven architecture
class EventBus {
  static final Map<String, List<Function(Map<String, dynamic>)>> _listeners = {};
  
  static void subscribe(String eventType, Function(Map<String, dynamic>) handler) {
    _listeners.putIfAbsent(eventType, () => []).add(handler);
  }
  
  static Future<void> publish(String eventType, Map<String, dynamic> event) async {
    // Publish to local listeners
    var listeners = _listeners[eventType] ?? [];
    for (var listener in listeners) {
      try {
        await listener(event);
      } catch (e) {
        print('Error in event listener: $e');
      }
    }
    
    // Publish to Kafka
    await kafkaService.publishEvent(
      'app_events',
      eventType,
      {
        'type': eventType,
        'data': event,
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'dart_flux_app',
      },
    );
  }
}

// Event handlers
void setupEventHandlers() {
  EventBus.subscribe('user_registered', (event) async {
    // Send welcome email
    await emailService.sendWelcomeEmail(event['email']);
    
    // Create user profile
    await profileService.createProfile(event['userId']);
  });
  
  EventBus.subscribe('order_placed', (event) async {
    // Update inventory
    await inventoryService.updateStock(event['items']);
    
    // Send confirmation email
    await emailService.sendOrderConfirmation(event['orderId']);
  });
}

// Publish events from handlers
ProcessorHandler createUserHandler = (request, response, pathArgs) async {
  var userData = await request.readAsJson();
  
  // Create user
  String userId = await userService.create(userData);
  
  // Publish event
  await EventBus.publish('user_registered', {
    'userId': userId,
    'email': userData['email'],
    'timestamp': DateTime.now().toIso8601String(),
  });
  
  return response.json({'id': userId});
};
```

## Email Services

### SendGrid Integration

```dart
import 'package:sendgrid_mailer/sendgrid_mailer.dart';

class EmailService {
  final Mailer _mailer;
  
  EmailService(String apiKey) : _mailer = Mailer(apiKey);
  
  Future<void> sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
    String? textContent,
    String? fromEmail,
    String? fromName,
    List<Attachment>? attachments,
  }) async {
    var email = Email(
      [Address(to)],
      subject: subject,
      content: [
        Content('text/html', htmlContent),
        if (textContent != null) Content('text/plain', textContent),
      ],
      from: Address(fromEmail ?? 'noreply@yourapp.com', fromName ?? 'Your App'),
      attachments: attachments,
    );
    
    await _mailer.send(email);
  }
  
  Future<void> sendTemplateEmail({
    required String to,
    required String templateId,
    required Map<String, dynamic> templateData,
    String? fromEmail,
    String? fromName,
  }) async {
    var email = Email(
      [Address(to)],
      from: Address(fromEmail ?? 'noreply@yourapp.com', fromName ?? 'Your App'),
      templateId: templateId,
      substitutions: templateData,
    );
    
    await _mailer.send(email);
  }
  
  Future<void> sendBulkEmail({
    required List<String> recipients,
    required String subject,
    required String htmlContent,
    String? textContent,
  }) async {
    var addresses = recipients.map((email) => Address(email)).toList();
    
    var email = Email(
      addresses,
      subject: subject,
      content: [
        Content('text/html', htmlContent),
        if (textContent != null) Content('text/plain', textContent),
      ],
    );
    
    await _mailer.send(email);
  }
}

// Email templates
class EmailTemplates {
  static String welcomeEmail(String userName) {
    return '''
    <!DOCTYPE html>
    <html>
    <body>
      <h1>Welcome, $userName!</h1>
      <p>Thank you for joining our platform.</p>
      <p>Get started by exploring our features.</p>
    </body>
    </html>
    ''';
  }
  
  static String passwordResetEmail(String resetToken, String baseUrl) {
    return '''
    <!DOCTYPE html>
    <html>
    <body>
      <h1>Password Reset Request</h1>
      <p>Click the link below to reset your password:</p>
      <a href="$baseUrl/reset-password?token=$resetToken">Reset Password</a>
      <p>This link will expire in 1 hour.</p>
    </body>
    </html>
    ''';
  }
}

// Email notification handlers
ProcessorHandler sendPasswordResetEmail = (request, response, pathArgs) async {
  var data = await request.readAsJson();
  String email = data['email'];
  
  // Find user
  var user = await userService.findByEmail(email);
  if (user == null) {
    // Don't reveal if email exists
    return response.json({'message': 'If the email exists, a reset link has been sent'});
  }
  
  // Generate reset token
  String resetToken = generateSecureRandomString(32);
  await redisService.cache('reset_token:$resetToken', {
    'userId': user['id'],
    'email': email,
  }, ttl: Duration(hours: 1));
  
  // Send email
  String htmlContent = EmailTemplates.passwordResetEmail(resetToken, Environment.baseUrl);
  await emailService.sendEmail(
    to: email,
    subject: 'Password Reset Request',
    htmlContent: htmlContent,
  );
  
  return response.json({'message': 'If the email exists, a reset link has been sent'});
};
```

This comprehensive integration guide provides practical examples for connecting Dart Flux with essential third-party services. Each integration can be customized and extended based on specific application requirements and service configurations.

---

## 📚 Documentation Navigation

### Foundation Knowledge
- **[← Advanced Patterns](advanced-usage-patterns.md)** - Complex implementation patterns
- **[Best Practices & Security →](best-practices-security.md)** - Secure integration practices
- **[Authentication](authentication.md)** - Authentication provider integrations

### Core Features
- **[Database Operations](database.md)** - Core database patterns
- **[File Management](file-management.md)** - File storage integrations
- **[Webhooks](webhooks.md)** - Event-driven integrations

### Production Setup
- **[Server Setup](server-setup.md)** - Production deployment
- **[Error Handling](error-handling.md)** - Integration error management
- **[Troubleshooting](troubleshooting-guide.md)** - Integration issues

### Implementation Examples
- **[Routing Examples](routing_examples.md)** - Integration in routing context
- **[API Reference](api-reference.md)** - Integration APIs

### Architecture
- **[Architecture Overview](architecture-overview.md)** - Integration architecture patterns

---

📖 **[Back to Documentation Index](README.md)**
