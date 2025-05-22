# Routing in Dart Flux

This guide provides comprehensive documentation on how to use Dart Flux's routing system to map HTTP requests to handler functions in your application.

## Table of Contents

- [Routing Basics](#routing-basics)
- [Route Handlers](#route-handlers)
- [HTTP Methods](#http-methods)
- [Path Parameters](#path-parameters)
- [Query Parameters](#query-parameters)
- [Nested Routers](#nested-routers)
- [Middleware](#middleware)
- [Upper and Lower Middleware](#upper-and-lower-middleware)
- [Error Handling](#error-handling)
- [CRUD Router](#crud-router)
- [Best Practices](#best-practices)
- [Advanced Examples](#advanced-examples)

## Routing Basics

The routing system in Dart Flux is built around the `Router` class, which allows you to define routes that map URL paths to handler functions. Each route is associated with a specific HTTP method and path pattern.

```dart
import 'package:dart_flux/dart_flux.dart';

// Create a router instance
Router router = Router()
  .get('hello', (req, res, pathArgs) {
    return res.write('Hello, World!', code: HttpStatus.ok);
  });

// Create a server with this router
Server server = Server(InternetAddress.anyIPv4, 3000, router);
await server.run();
```

## Route Handlers

Route handlers are functions that process HTTP requests and return responses. They follow the `ProcessorHandler` type definition and take three parameters:

```dart
typedef ProcessorHandler = FutureOr<FluxResponse> Function(
  FluxRequest request, 
  FluxResponse response, 
  Map<String, dynamic> pathArgs
);
```

- `request`: The `FluxRequest` object containing details about the HTTP request
- `response`: The `FluxResponse` object used to build and send the response
- `pathArgs`: A map containing path parameters extracted from the URL

Example of a standalone handler function:

```dart
ProcessorHandler userHandler = (req, res, pathArgs) {
  // Access path parameters from the URL
  String userId = pathArgs['id'];
  
  // Process the request and return a response
  return res.json(res, {'id': userId, 'name': 'John Doe'});
};

Router router = Router()
  .get('users/:id', userHandler);
```

## HTTP Methods

Dart Flux supports all standard HTTP methods through dedicated router methods:

```dart
Router router = Router()
  // GET request for retrieving resources
  .get('users', (req, res, pathArgs) {
    return res.write('List of users');
  })
  
  // POST request for creating resources
  .post('users', (req, res, pathArgs) async {
    var data = await req.asJson;
    return res.json(res, {'message': 'User created', 'data': data});
  })
  
  // PUT request for updating resources
  .put('users/:id', (req, res, pathArgs) async {
    String id = pathArgs['id'];
    var data = await req.asJson;
    return res.json(res, {'message': 'User $id updated', 'data': data});
  })
  
  // DELETE request for removing resources
  .delete('users/:id', (req, res, pathArgs) {
    String id = pathArgs['id'];
    return res.json(res, {'message': 'User $id deleted'});
  })
  
  // HEAD request for retrieving metadata
  .head('users', (req, res, pathArgs) {
    res.headers.add('X-Total-Count', '42');
    return res.write('');
  })
  
  // PATCH request for partial updates
  .patch('users/:id', (req, res, pathArgs) async {
    String id = pathArgs['id'];
    var data = await req.asJson;
    return res.json(res, {'message': 'User $id partially updated', 'data': data});
  })
  
  // OPTIONS request for communication options
  .options('users', (req, res, pathArgs) {
    res.headers.add('Allow', 'GET, POST, PUT, DELETE, HEAD, PATCH');
    return res.write('');
  })
  
  // CONNECT request for tunneling
  .connect('proxy', (req, res, pathArgs) {
    return res.write('Connection established');
  })
  
  // TRACE request for diagnostics
  .trace('debug', (req, res, pathArgs) {
    return res.write('TRACE request received');
  });
```

## Path Parameters

You can define dynamic path segments using the `:paramName` syntax in your route paths. These values will be available in the `pathArgs` map in your handler function:

```dart
Router router = Router()
  // Route with a single path parameter
  .get('users/:id', (req, res, pathArgs) {
    String userId = pathArgs['id'];
    return res.write('User ID: $userId');
  })
  
  // Route with multiple path parameters
  .get('organizations/:orgId/users/:userId', (req, res, pathArgs) {
    String orgId = pathArgs['orgId'];
    String userId = pathArgs['userId'];
    return res.write('Organization: $orgId, User: $userId');
  });
```

For the URL `/users/123`, the `pathArgs` map would contain `{'id': '123'}`.

## Query Parameters

You can access query parameters from the request URL:

```dart
Router router = Router()
  .get('search', (req, res, pathArgs) {
    // Access query parameters from the URL
    String query = req.queryParameters['q'] ?? '';
    int page = int.tryParse(req.queryParameters['page'] ?? '1') ?? 1;
    
    return res.json(res, {
      'search': query,
      'page': page,
      'results': ['result1', 'result2']
    });
  });
```

For the URL `/search?q=dart&page=2`, this handler would access 'dart' as the query and 2 as the page.

## Nested Routers

For more complex applications, you can nest routers to create a hierarchical routing structure:

```dart
// Create a router for user-related endpoints
Router usersRouter = Router.path('users')
  .get('/', (req, res, pathArgs) {
    return res.write('List of users');
  })
  .get('/:id', (req, res, pathArgs) {
    String id = pathArgs['id'];
    return res.write('User details for ID: $id');
  });

// Create a router for product-related endpoints
Router productsRouter = Router.path('products')
  .get('/', (req, res, pathArgs) {
    return res.write('List of products');
  })
  .get('/:id', (req, res, pathArgs) {
    String id = pathArgs['id'];
    return res.write('Product details for ID: $id');
  });

// Main router that includes the nested routers
Router mainRouter = Router()
  .router(usersRouter)    // Mounts at /users
  .router(productsRouter) // Mounts at /products
  .get('/', (req, res, pathArgs) {
    return res.write('Welcome to the API');
  });
```

This structure would handle the following routes:
- `GET /` → Welcome message
- `GET /users` → List of users
- `GET /users/123` → Details for user with ID 123
- `GET /products` → List of products
- `GET /products/456` → Details for product with ID 456

## Middleware

Middleware functions process requests before or after they reach your route handlers. They can modify the request or response, perform authentication checks, log requests, and more.

### Adding Middleware to a Router

```dart
// Logging middleware that runs before handlers
Router router = Router()
  .middleware((req, res, pathArgs) {
    print('Request received: ${req.method.name} ${req.path}');
    // Return the request to continue processing
    return req;
  })
  .get('hello', (req, res, pathArgs) {
    return res.write('Hello, World!');
  });
```

### Adding Middleware to a Specific Handler

```dart
// Create a handler with middleware
Handler handler = Handler('data', HttpMethod.get, (req, res, pathArgs) {
    return res.write('Data endpoint');
  })
  .middleware((req, res, pathArgs) {
    // Authentication check
    String? token = req.headers.value('Authorization');
    if (token == null) {
      return res.unauthorized('Missing authorization token');
    }
    // If authenticated, continue to the handler
    return req;
  });

// Add the handler to a router
Router router = Router().handler(handler);
```

## Upper and Lower Middleware

Dart Flux provides a structured way to organize middleware execution:

1. **Upper Middleware**: Runs before all other middleware and handlers
2. **Regular Middleware**: Runs in the order added, within each router
3. **Lower Middleware**: Runs after the handler has processed the request

```dart
Router router = Router()
  // Upper middleware (runs first)
  .upper((req, res, pathArgs) {
    print('Start request processing');
    res.headers.add('X-Request-Start', DateTime.now().toString());
    return req;
  })
  
  // Regular middleware (runs next)
  .middleware((req, res, pathArgs) {
    print('Before handler execution');
    return req;
  })
  
  // Handler (runs next)
  .get('test', (req, res, pathArgs) {
    return res.write('Handler executed');
  })
  
  // Lower middleware (runs last, after handler)
  .lower((req, res, pathArgs) {
    print('After request processing');
    // Lower middleware doesn't return anything (void)
  });
```

## Error Handling

You can handle errors in your route handlers directly:

```dart
Router router = Router()
  .get('safe', (req, res, pathArgs) {
    try {
      // Some operation that might fail
      return res.write('Operation succeeded');
    } catch (e) {
      return res.error(e, status: HttpStatus.internalServerError);
    }
  });
```

You can also create error-handling middleware:

```dart
Router router = Router()
  .upper((req, res, pathArgs) {
    try {
      return req;
    } catch (e) {
      return res.error('Global error: $e', status: HttpStatus.internalServerError);
    }
  })
  .get('data', (req, res, pathArgs) {
    // This might throw an error
    throw Exception('Something went wrong');
  });
```

## CRUD Router

Dart Flux provides a convenient way to create CRUD (Create, Read, Update, Delete) endpoints with minimal code using the `Router.crud` factory:

```dart
// Create a CRUD router for a 'users' entity
Router usersRouter = Router.crud('users');

// This automatically creates these routes:
// GET /users - Get all users
// GET /users/:id - Get user by ID
// POST /users - Create a new user
// PUT /users/:id - Update a user
// DELETE /users/:id - Delete a user
```

You can provide a custom repository to handle the actual data operations:

```dart
class UserRepository implements ModelRepositoryInterface {
  List<Map<String, dynamic>> users = [];
  
  @override
  Future<List<Map<String, dynamic>>> getAll() async {
    return users;
  }
  
  @override
  Future<Map<String, dynamic>> getById(String id) async {
    final index = users.indexWhere((user) => user['id'].toString() == id);
    if (index >= 0) {
      return users[index];
    }
    throw Exception('User not found');
  }
  
  @override
  Future<Map<String, dynamic>> insert(dynamic data) async {
    final id = users.length + 1;
    final user = {...data as Map<String, dynamic>, 'id': id};
    users.add(user);
    return user;
  }
  
  @override
  Future<Map<String, dynamic>> update(String id, dynamic data) async {
    final index = users.indexWhere((user) => user['id'].toString() == id);
    if (index >= 0) {
      users[index] = {...users[index], ...data as Map<String, dynamic>};
      return users[index];
    }
    throw Exception('User not found');
  }
  
  @override
  Future<bool> delete(String id) async {
    final index = users.indexWhere((user) => user['id'].toString() == id);
    if (index >= 0) {
      users.removeAt(index);
      return true;
    }
    return false;
  }
}

// Create a CRUD router with a custom repository
Router usersRouter = Router.crud('users', repo: UserRepository());
```

## Best Practices

1. **Organize Routes Logically**: Group related routes under nested routers
2. **Keep Handlers Focused**: Each handler should do one thing well
3. **Use Middleware for Cross-Cutting Concerns**: Authentication, logging, etc.
4. **Validate Input**: Check request data before processing
5. **Handle Errors Gracefully**: Return appropriate status codes and error messages
6. **Use Path Parameters for Resource Identifiers**: Like `/users/:id`
7. **Use Query Parameters for Filtering and Sorting**: Like `/users?role=admin&sort=name`

## Advanced Examples

### Authentication Middleware

```dart
Processor authMiddleware = (req, res, pathArgs) {
  String? token = req.headers.value('Authorization');
  
  if (token == null) {
    return res.unauthorized('Missing authorization token');
  }
  
  if (!token.startsWith('Bearer ')) {
    return res.unauthorized('Invalid token format');
  }
  
  try {
    // Validate the token (example implementation)
    String tokenValue = token.substring(7); // Remove 'Bearer ' prefix
    
    // Add user info to request context for later use
    req.context.set('userId', 'user_12345');
    req.context.set('userRole', 'admin');
    
    return req;
  } catch (e) {
    return res.unauthorized('Invalid token');
  }
};

Router secureRouter = Router()
  .middleware(authMiddleware)
  .get('profile', (req, res, pathArgs) {
    String userId = req.context.get('userId');
    String userRole = req.context.get('userRole');
    
    return res.json(res, {
      'id': userId,
      'role': userRole,
      'name': 'John Doe'
    });
  });
```

### File Upload Handling

```dart
Router fileRouter = Router()
  .post('upload', (req, res, pathArgs) async {
    try {
      // Process uploaded file
      var form = await req.form(saveFolder: 'uploads', acceptFormFiles: true);
      
      // Access file information
      if (form.hasFiles) {
        var uploadedFile = form.files.first;
        return res.json(res, {
          'success': true,
          'filename': uploadedFile.filename,
          'path': uploadedFile.path,
          'size': uploadedFile.length
        });
      } else {
        return res.badRequest('No file uploaded');
      }
    } catch (e) {
      return res.error('File upload failed: $e');
    }
  });
```

### Rate Limiting Middleware

```dart
// Simple in-memory rate limiter
class RateLimiter {
  final Map<String, int> _requestCounts = {};
  final Map<String, DateTime> _firstRequestTime = {};
  final int _maxRequests;
  final Duration _window;
  
  RateLimiter({int maxRequests = 100, Duration? window})
      : _maxRequests = maxRequests,
        _window = window ?? Duration(minutes: 15);
  
  bool checkLimit(String clientIp) {
    final now = DateTime.now();
    
    if (!_requestCounts.containsKey(clientIp)) {
      _requestCounts[clientIp] = 1;
      _firstRequestTime[clientIp] = now;
      return true;
    }
    
    final windowStart = _firstRequestTime[clientIp]!;
    final windowEnd = windowStart.add(_window);
    
    if (now.isAfter(windowEnd)) {
      // Reset counter if window has passed
      _requestCounts[clientIp] = 1;
      _firstRequestTime[clientIp] = now;
      return true;
    }
    
    // Increment counter and check limit
    _requestCounts[clientIp] = (_requestCounts[clientIp] ?? 0) + 1;
    return _requestCounts[clientIp]! <= _maxRequests;
  }
}

// Create a rate limiter middleware
final rateLimiter = RateLimiter(maxRequests: 5, window: Duration(minutes: 1));

Processor rateLimitMiddleware = (req, res, pathArgs) {
  String clientIp = req.request.connectionInfo?.remoteAddress.address ?? 'unknown';
  
  if (!rateLimiter.checkLimit(clientIp)) {
    res.headers.add('Retry-After', '60');
    return res.error('Rate limit exceeded', status: HttpStatus.tooManyRequests);
  }
  
  return req;
};

Router apiRouter = Router()
  .upper(rateLimitMiddleware)
  .get('data', (req, res, pathArgs) {
    return res.write('Data access granted');
  });
```

By structuring your routes and middleware effectively, you can create a robust and maintainable API with Dart Flux's routing system.
