# Getting Started with Dart Flux

This guide will help you set up your first Dart Flux application and understand the basic concepts of the framework.

## Prerequisites

Before you begin, ensure you have the following installed:

- Dart SDK (version >=3.7.2)
- IDE with Dart support (VS Code, IntelliJ IDEA, etc.)

## Installation

Add Dart Flux to your `pubspec.yaml`:

```yaml
dependencies:
  dart_flux: ^0.0.3
```

Run the following command to install dependencies:

```bash
dart pub get
```

## Creating Your First Application

Let's create a simple web server that responds with a "Hello, World!" message.

Create a new file named `main.dart`:

```dart
import 'dart:io';

import 'package:dart_flux/dart_flux.dart';

void main() async {
  // Create a router with a single GET endpoint
  Router router = Router()
    .get('hello', (req, res, pathArgs) {
      return res.write('Hello, World!');
    });
  
  // Create a server with the router
  Server server = Server(InternetAddress.anyIPv4, 3000, router);
  
  // Start the server
  await server.run();
  print('Server running on port 3000');
}
```

Run the application:

```bash
dart run main.dart
```

Open your browser or use a tool like cURL to access `http://localhost:3000/hello`.

## Project Structure

A typical Dart Flux application might have the following structure:

```
my_app/
├── bin/
│   └── main.dart          # Entry point
├── lib/
│   ├── controllers/       # Business logic
│   ├── models/            # Data models
│   ├── routes/            # Route definitions
│   └── services/          # Services (DB, Auth, etc.)
├── test/                  # Tests
└── pubspec.yaml           # Project metadata
```

## Core Concepts

### Server

The `Server` class is the foundation of Dart Flux applications. It handles HTTP requests and manages middleware execution.

```dart
Server(
  InternetAddress.anyIPv4,  // IP address to bind to
  3000,                     // Port number
  router,                   // Router for handling requests
  upperMiddlewares: [],     // Middlewares that run before request handling
  lowerMiddlewares: [],     // Middlewares that run after request handling
  loggerEnabled: true,      // Enable/disable logging
);
```

### Router

The `Router` class manages HTTP routes and delegates requests to appropriate handlers:

```dart
Router router = Router()
  .get('user/:id', (req, res, pathArgs) {
    // Access path parameter: pathArgs['id']
    return res.json({'id': pathArgs['id']});
  })
  .post('data', (req, res, pathArgs) {
    // Handle POST request
    return res.json({'status': 'success'});
  });
```

### Request and Response

The framework provides `FluxRequest` and `FluxResponse` classes to handle HTTP requests and responses:

```dart
// Example handler function
(FluxRequest req, FluxResponse res, Map<String, String> pathArgs) {
  // Access request data
  final body = req.body;
  final headers = req.headers;
  
  // Send response
  return res.json({
    'message': 'Success',
    'data': body,
  });
}
```

## 🚀 Next Steps

Now that you have your first Dart Flux application running, explore these topics:

### Core Concepts
- **[Architecture Overview](architecture-overview.md)** - Learn about the pipeline system and framework architecture
- **[Routing](routing.md)** - Master URL routing and middleware patterns
- **[Routing Examples](routing_examples.md)** - See real-world routing implementations

### Essential Features
- **[Authentication](authentication.md)** - Add JWT authentication to secure your API
- **[Database Operations](database.md)** - Connect to MongoDB and manage data
- **[File Management](file-management.md)** - Handle file uploads and downloads
- **[Error Handling](error-handling.md)** - Implement robust error management

### Production Ready
- **[Server Setup](server-setup.md)** - Configure servers for production deployment
- **[Best Practices and Security](best-practices-security.md)** - Security guidelines and performance optimization
- **[Troubleshooting Guide](troubleshooting-guide.md)** - Common issues and solutions

### Advanced Topics
- **[Advanced Usage Patterns](advanced-usage-patterns.md)** - Complex middleware and integration patterns
- **[Integration Guides](integration-guides.md)** - Connect with third-party services

---

📖 **[← Back to Documentation Index](README.md)** | **[Continue to Routing →](routing.md)**

## Troubleshooting

If you encounter issues:

1. Check the server logs for error messages
2. Verify your port is not in use by another application
3. Ensure all dependencies are correctly installed
4. Check your firewall settings if accessing from remote clients
