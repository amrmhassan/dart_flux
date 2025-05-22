# Dart Flux Routing Examples

This file contains practical examples that demonstrate the routing capabilities of Dart Flux.

## Basic Setup Example

```dart
import 'dart:io';
import 'package:dart_flux/dart_flux.dart';

void main() async {
  // Create a router for our application
  Router router = Router()
    .get('hello', (req, res, pathArgs) {
      return res.write('Hello, World!', code: HttpStatus.ok);
    });
    
  // Set up the server with our router
  Server server = Server(InternetAddress.anyIPv4, 3000, router);
  
  // Start the server
  await server.run();
  print('Server running on port 3000');
}
```

## Complete API Example

This example demonstrates a more complete REST API with middleware, nested routers, and CRUD operations.

```dart
import 'dart:io';
import 'package:dart_flux/dart_flux.dart';

// Sample in-memory data store
class UserStore {
  static final Map<String, Map<String, dynamic>> _users = {
    '1': {'id': '1', 'name': 'John Doe', 'email': 'john@example.com'},
    '2': {'id': '2', 'name': 'Jane Smith', 'email': 'jane@example.com'},
  };
  
  static List<Map<String, dynamic>> getAllUsers() {
    return _users.values.toList();
  }
  
  static Map<String, dynamic>? getUserById(String id) {
    return _users[id];
  }
  
  static Map<String, dynamic> createUser(Map<String, dynamic> userData) {
    String id = (int.parse(_users.keys.toList().last) + 1).toString();
    _users[id] = {...userData, 'id': id};
    return _users[id]!;
  }
  
  static Map<String, dynamic>? updateUser(String id, Map<String, dynamic> userData) {
    if (_users.containsKey(id)) {
      _users[id] = {..._users[id]!, ...userData, 'id': id};
      return _users[id];
    }
    return null;
  }
  
  static bool deleteUser(String id) {
    if (_users.containsKey(id)) {
      _users.remove(id);
      return true;
    }
    return false;
  }
}

// Sample repository implementing ModelRepositoryInterface
class UserRepository implements ModelRepositoryInterface {
  @override
  Future<List<Map<String, dynamic>>> getAll() async {
    return UserStore.getAllUsers();
  }
  
  @override
  Future<Map<String, dynamic>?> getById(String id) async {
    return UserStore.getUserById(id);
  }
  
  @override
  Future<Map<String, dynamic>> insert(dynamic data) async {
    return UserStore.createUser(data as Map<String, dynamic>);
  }
  
  @override
  Future<Map<String, dynamic>?> update(String id, dynamic data) async {
    return UserStore.updateUser(id, data as Map<String, dynamic>);
  }
  
  @override
  Future<bool> delete(String id) async {
    return UserStore.deleteUser(id);
  }
}

// Middleware functions
Processor loggerMiddleware = (req, res, pathArgs) {
  print('${DateTime.now()} - ${req.method.name} ${req.path}');
  return req;
};

Processor authMiddleware = (req, res, pathArgs) {
  // Simple authentication check - in a real app, you'd validate a token
  String? apiKey = req.headers.value('X-API-Key');
  if (apiKey != 'secret-api-key') {
    return res.unauthorized('Invalid or missing API key');
  }
  return req;
};

void main() async {
  // Create user routes both with automatic CRUD router and manual definitions
  Router usersCrudRouter = Router.crud('users-crud', repo: UserRepository());
  
  // Manual user router with more control
  Router usersRouter = Router.path('users')
    // Get all users
    .get('/', (req, res, pathArgs) async {
      var users = await UserRepository().getAll();
      return res.json(res, users);
    })
    
    // Get user by ID
    .get('/:id', (req, res, pathArgs) async {
      String id = pathArgs['id'];
      var user = await UserRepository().getById(id);
      
      if (user == null) {
        return res.notFound('User not found');
      }
      
      return res.json(res, user);
    })
    
    // Create a new user
    .post('/', (req, res, pathArgs) async {
      var userData = await req.asJson;
      var newUser = await UserRepository().insert(userData);
      return res.json(res, newUser, status: HttpStatus.created);
    })
    
    // Update a user
    .put('/:id', (req, res, pathArgs) async {
      String id = pathArgs['id'];
      var userData = await req.asJson;
      var updatedUser = await UserRepository().update(id, userData);
      
      if (updatedUser == null) {
        return res.notFound('User not found');
      }
      
      return res.json(res, updatedUser);
    })
    
    // Delete a user
    .delete('/:id', (req, res, pathArgs) async {
      String id = pathArgs['id'];
      bool deleted = await UserRepository().delete(id);
      
      if (!deleted) {
        return res.notFound('User not found');
      }
      
      return res.json(res, {'success': true, 'message': 'User deleted'});
    });
  
  // Create an authentication-protected admin router
  Router adminRouter = Router.path('admin')
    // Apply authentication middleware to all admin routes
    .middleware(authMiddleware)
    
    // Admin dashboard
    .get('/dashboard', (req, res, pathArgs) {
      return res.json(res, {
        'status': 'ok',
        'message': 'Welcome to the admin dashboard',
        'serverTime': DateTime.now().toIso8601String()
      });
    });
  
  // Create a nested router for file operations
  Router filesRouter = Router.path('files')
    .post('/upload', (req, res, pathArgs) async {
      try {
        var form = await req.form(saveFolder: 'uploads', acceptFormFiles: true);
        
        if (form.hasFiles) {
          var file = form.files.first;
          return res.json(res, {
            'success': true,
            'filename': file.filename,
            'size': file.length
          });
        } else {
          return res.badRequest('No file uploaded');
        }
      } catch (e) {
        return res.error('Upload failed: $e');
      }
    })
    
    .get('/:filename', (req, res, pathArgs) {
      String filename = pathArgs['filename'];
      File file = File('uploads/$filename');
      
      if (!file.existsSync()) {
        return res.notFound('File not found');
      }
      
      return res.file(file);
    });
  
  // Main router that combines all sub-routers
  Router mainRouter = Router()
    // Apply global logging middleware to all routes
    .upper(loggerMiddleware)
    
    // Welcome route
    .get('/', (req, res, pathArgs) {
      return res.json(res, {
        'message': 'Welcome to the Dart Flux API',
        'version': '1.0.0',
        'documentation': '/docs'
      });
    })
    
    // Add all sub-routers
    .router(usersCrudRouter)  // /users-crud routes
    .router(usersRouter)      // /users routes
    .router(adminRouter)      // /admin routes
    .router(filesRouter)      // /files routes
    
    // Add global error handler as lower middleware
    .lower((req, res, pathArgs) {
      if (res.code >= 400) {
        print('ERROR: ${res.code} on ${req.path}');
      }
    });
  
  // Create and start the server
  Server server = Server(InternetAddress.anyIPv4, 3000, mainRouter);
  await server.run();
  print('Server running on http://localhost:3000');
}
```

## Testing the API

You can test the routes using curl:

```bash
# Get welcome message
curl http://localhost:3000/

# Get all users
curl http://localhost:3000/users

# Get user by ID
curl http://localhost:3000/users/1

# Create a new user
curl -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice Johnson","email":"alice@example.com"}'

# Update a user
curl -X PUT http://localhost:3000/users/1 \
  -H "Content-Type: application/json" \
  -d '{"email":"john.doe@example.com"}'

# Delete a user
curl -X DELETE http://localhost:3000/users/2

# Access admin dashboard (will fail without API key)
curl http://localhost:3000/admin/dashboard

# Access admin dashboard with API key
curl http://localhost:3000/admin/dashboard \
  -H "X-API-Key: secret-api-key"

# Upload a file
curl -X POST http://localhost:3000/files/upload \
  -F "file=@/path/to/file.txt"

# Download a file
curl http://localhost:3000/files/file.txt > downloaded_file.txt
```

## Middleware Execution Order Example

This example demonstrates the execution order of middlewares:

```dart
import 'dart:io';
import 'package:dart_flux/dart_flux.dart';

void main() async {
  Router router = Router()
    // System middlewares (handled by Dart Flux internally)
    // Upper middlewares
    .upper((req, res, pathArgs) {
      print('1. Router Upper Middleware');
      res.headers.add('X-Middleware-1', 'executed');
      return req;
    })
    
    // Regular middlewares
    .middleware((req, res, pathArgs) {
      print('2. Router Regular Middleware');
      res.headers.add('X-Middleware-2', 'executed');
      return req;
    })
    
    // Handler with its own middlewares
    .handler(
      Handler('test', HttpMethod.get, (req, res, pathArgs) {
        print('4. Handler Execution');
        res.headers.add('X-Handler', 'executed');
        return res.write('Handler executed', code: HttpStatus.ok);
      })
      .middleware((req, res, pathArgs) {
        print('3. Handler Middleware');
        res.headers.add('X-Middleware-3', 'executed');
        return req;
      })
      .lower((req, res, pathArgs) {
        print('5. Handler Lower Middleware');
        // Cannot modify response headers if already sent
        print('  Response code: ${res.code}');
      })
    )
    
    // Router lower middlewares
    .lower((req, res, pathArgs) {
      print('6. Router Lower Middleware');
      print('  Final response code: ${res.code}');
    });
    
  // System lower middlewares (handled by Dart Flux internally)
  
  Server server = Server(InternetAddress.anyIPv4, 3000, router);
  await server.run();
  print('Server running on http://localhost:3000/test');
  print('Request this URL to see middleware execution order in the console');
}
```

The console output will show the execution order when you access `/test`:

```
1. Router Upper Middleware
2. Router Regular Middleware
3. Handler Middleware
4. Handler Execution 
5. Handler Lower Middleware
  Response code: 200
6. Router Lower Middleware
  Final response code: 200
```

These examples demonstrate how to use Dart Flux's routing system for building APIs with proper middleware, error handling, and nested routers.
