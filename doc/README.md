# Dart Flux Documentation

A lightweight and scalable Dart backend framework with built-in web server, authentication, file management, database integration, and more.

[![Dart Version](https://img.shields.io/badge/Dart-^3.7.2-blue.svg)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-0.0.3-green.svg)](https://github.com/amrmhassan/dart_flux)

## 🌟 Overview

Dart Flux provides a complete solution for building robust backend applications in Dart. It offers a set of tools and utilities to simplify server setup, routing, database operations, authentication, and more.

## ⚡ Key Features

- 🚀 **Fast Server Implementation**: Lightweight HTTP server with optimized performance
- 🛣️ **Intuitive Routing**: Simple and flexible routing system with middleware support
- 🔐 **Authentication**: Built-in authentication with JWT support
- 📁 **File Management**: Easy file handling and storage operations
- 💾 **Database Integration**: MongoDB support with simple abstractions
- 🔄 **Webhooks**: Support for webhook integrations with GitHub and other platforms
- 🧩 **Modular Design**: Extensible architecture for flexible customization
- 📝 **Logging**: Comprehensive logging system

## Documentation

## 📚 Documentation Structure

### 🚀 Getting Started
- **[Getting Started](getting-started.md)** - Your first Dart Flux application
- **[Server Setup](server-setup.md)** - Server configuration and deployment
- **[Architecture Overview](architecture-overview.md)** - Understanding the framework architecture

### 🏗️ Core Features
- **[Routing](routing.md)** - URL routing system and middleware
  - [Routing Examples](routing_examples.md) - Real-world implementation patterns
- **[Authentication](authentication.md)** - JWT authentication and session management
- **[Database Operations](database.md)** - MongoDB integration and operations
- **[File Management](file-management.md)** - File upload, download, and storage
- **[Webhooks](webhooks.md)** - GitHub integration and automation
- **[Error Handling](error-handling.md)** - Error management strategies

### 🔧 Advanced Topics
- **[Advanced Usage Patterns](advanced-usage-patterns.md)** - Complex middleware patterns and integrations
- **[Best Practices and Security](best-practices-security.md)** - Production security guidelines
- **[Integration Guides](integration-guides.md)** - Third-party service integrations

### 📖 Reference and Support
- **[API Reference](api-reference.md)** - Complete API documentation
- **[Troubleshooting Guide](troubleshooting-guide.md)** - Common issues and solutions

## 🎯 Quick Navigation

| I want to... | Go to... |
|--------------|----------|
| Start my first project | [Getting Started](getting-started.md) |
| Set up routing | [Routing](routing.md) → [Examples](routing_examples.md) |
| Add authentication | [Authentication](authentication.md) |
| Connect to database | [Database Operations](database.md) |
| Handle file uploads | [File Management](file-management.md) |
| Understand the architecture | [Architecture Overview](architecture-overview.md) |
| Learn advanced patterns | [Advanced Usage Patterns](advanced-usage-patterns.md) |
| Secure my application | [Best Practices and Security](best-practices-security.md) |
| Integrate with services | [Integration Guides](integration-guides.md) |
| Fix issues | [Troubleshooting Guide](troubleshooting-guide.md) |

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

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
