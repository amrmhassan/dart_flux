# Error Handling

This guide explains how to handle errors effectively in your Dart Flux application.

## Overview

Proper error handling is essential for building robust applications. Dart Flux provides several mechanisms for handling errors at different levels:

- Server-level error handling
- Route-level error handling
- Custom error types
- Error logging

## Server-Level Error Handling

You can define global error handlers for your server:

```dart
import 'dart:io';
import 'package:dart_flux/dart_flux.dart';

void main() async {
  final router = Router()
    .get('hello', (req, res, pathArgs) {
      return res.write('Hello, World!');
    });
  
  final server = Server(
    InternetAddress.anyIPv4,
    3000,
    router,
    onError: (error, req, res) {
      print('Server error: $error');
      
      // Return a friendly error response
      return res.status(500).json({
        'error': 'Internal Server Error',
        'message': 'Something went wrong',
      });
    },
    onNotFound: (req, res, pathArgs) {
      // Custom 404 handler
      return res.status(404).json({
        'error': 'Not Found',
        'message': 'The requested resource ${req.url.path} does not exist',
      });
    },
  );
  
  await server.run();
  print('Server running on port 3000');
}
```

## Route-Level Error Handling

Handle errors within specific route handlers:

```dart
Router router = Router()
  .get('users/:id', (req, res, pathArgs) async {
    try {
      final userId = pathArgs['id'];
      
      // Attempt to fetch user data
      final userData = await fetchUserData(userId);
      
      if (userData == null) {
        // User not found
        return res.status(404).json({
          'error': 'Not Found',
          'message': 'User with ID $userId does not exist',
        });
      }
      
      return res.json(userData);
    } catch (e) {
      print('Error fetching user data: $e');
      
      // Determine error type and return appropriate response
      if (e is DatabaseConnectionError) {
        return res.status(503).json({
          'error': 'Service Unavailable',
          'message': 'Database connection failed',
        });
      } else {
        return res.status(500).json({
          'error': 'Internal Server Error',
          'message': 'Failed to retrieve user data',
        });
      }
    }
  });
```

## Using Custom Error Types

Define custom error types for better error handling:

```dart
import 'package:dart_flux/core/errors/server_error.dart';

// Custom error types
class ValidationError extends ServerError {
  final Map<String, String> validationErrors;
  
  ValidationError(String message, this.validationErrors) : super(message);
}

class AuthorizationError extends ServerError {
  AuthorizationError(String message) : super(message);
}

class ResourceNotFoundError extends ServerError {
  final String resource;
  final String id;
  
  ResourceNotFoundError(this.resource, this.id)
      : super('$resource with ID $id not found');
}

// Using custom errors in routes
Router router = Router()
  .post('users', (req, res, pathArgs) async {
    try {
      final userData = req.body;
      
      // Validate user data
      final validationErrors = validateUserData(userData);
      if (validationErrors.isNotEmpty) {
        throw ValidationError('Invalid user data', validationErrors);
      }
      
      // Create user
      final newUser = await createUser(userData);
      
      return res.status(201).json(newUser);
    } catch (e) {
      if (e is ValidationError) {
        return res.status(400).json({
          'error': 'Validation Error',
          'message': e.message,
          'details': e.validationErrors,
        });
      } else if (e is AuthorizationError) {
        return res.status(403).json({
          'error': 'Forbidden',
          'message': e.message,
        });
      } else {
        print('Unexpected error: $e');
        return res.status(500).json({
          'error': 'Internal Server Error',
          'message': 'Failed to create user',
        });
      }
    }
  });
```

## Middleware for Error Handling

You can create error-handling middleware:

```dart
Middleware errorHandlingMiddleware = (req, res, next) async {
  try {
    // Attempt to execute the next handler in the pipeline
    return await next();
  } catch (e) {
    print('Caught error in middleware: $e');
    
    // Handle different error types
    if (e is ValidationError) {
      return res.status(400).json({
        'error': 'Validation Error',
        'message': e.message,
        'details': e.validationErrors,
      });
    } else if (e is AuthorizationError) {
      return res.status(403).json({
        'error': 'Forbidden',
        'message': e.message,
      });
    } else if (e is ResourceNotFoundError) {
      return res.status(404).json({
        'error': 'Not Found',
        'message': e.message,
      });
    } else {
      // Generic error handler
      return res.status(500).json({
        'error': 'Internal Server Error',
        'message': 'Something went wrong',
      });
    }
  }
};

// Apply the middleware to all routes
Router router = Router()
  .use(errorHandlingMiddleware)
  .get('users', (req, res, pathArgs) async {
    // This route can now throw errors without try-catch
    if (!isAuthorized(req)) {
      throw AuthorizationError('Not authorized to view users');
    }
    
    final users = await getUsers();
    return res.json(users);
  });
```

## Error Logging

Implement comprehensive error logging:

```dart
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:dart_flux/dart_flux.dart';

void main() async {
  // Create a logger
  final logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );
  
  // Create an error logging middleware
  Middleware loggingMiddleware = (req, res, next) async {
    try {
      // Log the request
      logger.i('${req.method} ${req.url.path}');
      
      // Process the request
      return await next();
    } catch (e, stackTrace) {
      // Log the error with stack trace
      logger.e(
        'Error processing request: ${req.method} ${req.url.path}',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Rethrow to be handled by error handlers
      rethrow;
    }
  };
  
  // Create a router with the logging middleware
  final router = Router()
    .use(loggingMiddleware)
    .get('hello', (req, res, pathArgs) {
      return res.write('Hello, World!');
    });
  
  // Create the server with error handling
  final server = Server(
    InternetAddress.anyIPv4,
    3000,
    router,
    onError: (error, req, res) {
      // Log server errors
      logger.e('Server error', error: error);
      
      return res.status(500).json({
        'error': 'Internal Server Error',
        'message': 'Something went wrong',
      });
    },
  );
  
  await server.run();
  logger.i('Server running on port 3000');
}
```

## Handling Asynchronous Errors

Be careful with asynchronous errors:

```dart
// Incorrect - error in async operation is not caught
Router router = Router()
  .get('users', (req, res, pathArgs) {
    fetchUsers().then((users) {
      // If fetchUsers() throws, the error is not caught
      return res.json(users);
    });
    
    // This returns before the async operation completes!
  });

// Correct - properly handling async errors
Router router = Router()
  .get('users', (req, res, pathArgs) async {
    try {
      final users = await fetchUsers();
      return res.json(users);
    } catch (e) {
      print('Error fetching users: $e');
      return res.status(500).json({
        'error': 'Internal Server Error',
        'message': 'Failed to fetch users',
      });
    }
  });
```

## Consistent Error Response Format

Use a consistent format for error responses:

```dart
// Helper function for error responses
FluxResponse errorResponse(
  FluxResponse res,
  int statusCode,
  String error,
  String message, {
  Map<String, dynamic>? details,
}) {
  final response = {
    'error': error,
    'message': message,
    'timestamp': DateTime.now().toIso8601String(),
  };
  
  if (details != null) {
    response['details'] = details;
  }
  
  return res.status(statusCode).json(response);
}

// Using the helper function
Router router = Router()
  .get('users/:id', (req, res, pathArgs) async {
    try {
      final userId = pathArgs['id'];
      final user = await getUserById(userId);
      
      if (user == null) {
        return errorResponse(
          res,
          404,
          'Not Found',
          'User with ID $userId does not exist',
        );
      }
      
      return res.json(user);
    } catch (e) {
      print('Error: $e');
      return errorResponse(
        res,
        500,
        'Internal Server Error',
        'Failed to retrieve user data',
      );
    }
  });
```

## Validation Errors

For input validation errors, return detailed information:

```dart
class Validator {
  static Map<String, String> validateUser(Map<String, dynamic> userData) {
    final errors = <String, String>{};
    
    // Validate name
    if (!userData.containsKey('name') || userData['name'].toString().isEmpty) {
      errors['name'] = 'Name is required';
    }
    
    // Validate email
    if (!userData.containsKey('email') || userData['email'].toString().isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!isValidEmail(userData['email'].toString())) {
      errors['email'] = 'Invalid email format';
    }
    
    // Validate age
    if (userData.containsKey('age')) {
      final age = int.tryParse(userData['age'].toString());
      if (age == null) {
        errors['age'] = 'Age must be a number';
      } else if (age < 0 || age > 120) {
        errors['age'] = 'Age must be between 0 and 120';
      }
    }
    
    return errors;
  }
  
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
}

// Using the validator in a route
Router router = Router()
  .post('users', (req, res, pathArgs) async {
    final userData = req.body;
    
    // Validate input
    final validationErrors = Validator.validateUser(userData);
    if (validationErrors.isNotEmpty) {
      return errorResponse(
        res,
        400,
        'Validation Error',
        'Invalid user data',
        details: {'fields': validationErrors},
      );
    }
    
    // Process valid data
    final newUser = await createUser(userData);
    return res.status(201).json(newUser);
  });
```

## Error Handling Best Practices

1. **Be Specific**: Use different error types and status codes for different errors

2. **Log Appropriately**: Log errors with sufficient context and stack traces

3. **Don't Expose Sensitive Information**: Sanitize error messages sent to clients

4. **Use try-catch Blocks**: Wrap code that might throw exceptions

5. **Handle Async Errors**: Always await promises and use try-catch with async/await

6. **Centralize Error Handling**: Use middleware or helper functions for consistent error responses

7. **Validate Input Early**: Catch validation errors before processing begins

8. **Include Correlation IDs**: Add unique identifiers to track errors across requests

9. **Return Appropriate Status Codes**:
   - 400: Bad Request (client error)
   - 401: Unauthorized (authentication required)
   - 403: Forbidden (not authorized)
   - 404: Not Found
   - 409: Conflict
   - 422: Unprocessable Entity (validation failed)
   - 500: Internal Server Error (server error)
   - 503: Service Unavailable (temporary server issue)
