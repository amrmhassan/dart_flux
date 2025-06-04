# Dart Flux

A lightweight and scalable Dart backend framework with built-in web server, authentication, file management, database integration, and more.

## Overview

Dart Flux provides a complete solution for building robust backend applications in Dart. It offers a set of tools and utilities to simplify server setup, routing, database operations, authentication, and more.

## Features

- 🚀 **Fast Server Implementation**: Lightweight HTTP server with optimized performance
- 🛣️ **Intuitive Routing**: Simple and flexible routing system with middleware support
- 🔐 **Authentication**: Built-in authentication with JWT support and efficient LRU caching
- 📁 **File Management**: Easy file handling and storage operations
- 💾 **Database Integration**: MongoDB support with simple abstractions
- 🔄 **Webhooks**: Support for webhook integrations with GitHub and other platforms
- 🧩 **Modular Design**: Extensible architecture for flexible customization
- 📝 **Logging**: Comprehensive logging system

## Installation

Add Dart Flux to your `pubspec.yaml`:

```yaml
dependencies:
  dart_flux: ^0.0.3
```

Then run:

```bash
dart pub get
```

## Quick Example

```dart
import 'dart:io';
import 'package:dart_flux/dart_flux.dart';

void main() async {
  Router router = Router()
    .get('hello', (req, res, pathArgs) {
      return res.write('Hello, World!');
    })
    .post('users', (req, res, pathArgs) {
      // Handle user creation
      return res.json({'status': 'success'});
    });
  
  Server server = Server(InternetAddress.anyIPv4, 3000, router);
  await server.run();
  print('Server running on port 3000');
}
```

## Documentation

📚 **Comprehensive documentation is available in the [doc](doc/README.md) directory**

### 🚀 Quick Start
- [Getting Started](doc/getting-started.md) - Installation and basic setup
- [Server Setup](doc/server-setup.md) - Server configuration and deployment

### 🏗️ Core Concepts
- [Architecture Overview](doc/architecture-overview.md) - Framework architecture and pipeline system
- [Routing](doc/routing.md) - URL routing and middleware
  - [Routing Examples](doc/routing_examples.md) - Real-world routing patterns
- [Authentication](doc/authentication.md) - JWT authentication and security
- [Database Operations](doc/database.md) - MongoDB integration
- [File Management](doc/file-management.md) - File upload/download handling
- [Webhooks](doc/webhooks.md) - GitHub integration and automation

### 🔧 Advanced Topics
- [Advanced Usage Patterns](doc/advanced-usage-patterns.md) - Complex implementation patterns
- [Best Practices and Security](doc/best-practices-security.md) - Production guidelines
- [Integration Guides](doc/integration-guides.md) - Third-party service integrations

### 📖 Reference
- [API Reference](doc/api-reference.md) - Complete API documentation
- [Error Handling](doc/error-handling.md) - Error management strategies
- [Troubleshooting Guide](doc/troubleshooting-guide.md) - Common issues and solutions

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.