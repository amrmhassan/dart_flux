# Dart Flux Routing Examples

This file contains practical examples that demonstrate the routing capabilities of Dart Flux, from basic setups to complex real-world applications.

> 📖 **Related Documentation:**
> - [Getting Started](getting-started.md) - Basic setup and first application
> - [Routing Core Concepts](routing.md) - Fundamental routing principles
> - [Architecture Overview](architecture-overview.md) - Pipeline system and middleware
> - [Authentication](authentication.md) - Security and access control
> - [API Reference](api-reference.md) - Complete API documentation

## Table of Contents

- [Basic Setup Example](#basic-setup-example)
- [Complete REST API Example](#complete-rest-api-example)
- [Real-World E-commerce API](#real-world-e-commerce-api)
- [Blog Platform API](#blog-platform-api)
- [File Management System](#file-management-system)
- [Authentication & Authorization](#authentication--authorization)
- [Middleware Execution Order](#middleware-execution-order-example)
- [WebSocket Integration](#websocket-integration)
- [Rate Limiting Example](#rate-limiting-example)
- [Testing the APIs](#testing-the-apis)

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

## Complete REST API Example

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

## Testing the APIs

Here are comprehensive testing examples for all the APIs demonstrated above:

### E-commerce API Testing

```bash
# Create products
curl -X POST http://localhost:8080/api/v1/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Smartphone",
    "description": "Latest model smartphone",
    "price": 699.99,
    "stock": 100,
    "category": "Electronics",
    "images": ["phone1.jpg", "phone2.jpg"]
  }'

# Get all products
curl http://localhost:8080/api/v1/products

# Filter products by category and price
curl "http://localhost:8080/api/v1/products?category=Electronics&minPrice=500&maxPrice=1000"

# Create an order
curl -X POST http://localhost:8080/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "items": [
      {"productId": "1", "quantity": 2},
      {"productId": "2", "quantity": 1}
    ]
  }'

# Get orders for a user
curl http://localhost:8080/api/v1/orders/user/user123
```

### Blog API Testing

```bash
# Create a blog post
curl -X POST http://localhost:8080/api/blog/posts \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Introduction to Dart Flux",
    "content": "Dart Flux is a powerful web framework...",
    "authorId": "author1",
    "categoryId": "1",
    "tags": ["dart", "web", "framework"],
    "published": true
  }'

# Get all published posts
curl "http://localhost:8080/api/blog/posts?published=true"

# Filter posts by category
curl "http://localhost:8080/api/blog/posts?category=1"

# Add a comment to a post
curl -X POST http://localhost:8080/api/blog/posts/1/comments \
  -H "Content-Type: application/json" \
  -d '{
    "authorId": "user1",
    "content": "Great article! Very helpful."
  }'

# Get comments for a post
curl http://localhost:8080/api/blog/posts/1/comments
```

### File Management API Testing

```bash
# Upload a single file
curl -X POST http://localhost:8080/files/upload \
  -F "file=@/path/to/document.pdf"

# Upload multiple files
curl -X POST http://localhost:8080/files/upload \
  -F "file=@/path/to/image1.jpg" \
  -F "file=@/path/to/image2.png"

# List all files
curl http://localhost:8080/files

# Get file metadata
curl http://localhost:8080/files/1234567890/info

# Download a file
curl http://localhost:8080/files/1234567890/download -o downloaded_file.pdf

# View a file in browser
curl http://localhost:8080/files/1234567890/view

# Delete a file
curl -X DELETE http://localhost:8080/files/1234567890
```

### Authentication API Testing

```bash
# Login as admin
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "admin123"
  }'

# Save the token from the response and use it in subsequent requests
TOKEN="your-token-here"

# Get user profile
curl http://localhost:8080/auth/profile \
  -H "Authorization: Bearer $TOKEN"

# Access user-level protected data
curl http://localhost:8080/protected/user-data \
  -H "Authorization: Bearer $TOKEN"

# Access admin-only data (requires admin role)
curl http://localhost:8080/protected/admin-data \
  -H "Authorization: Bearer $TOKEN"

# Login as regular user
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "user123"
  }'

# Try to access admin data with user token (should fail)
USER_TOKEN="user-token-here"
curl http://localhost:8080/protected/admin-data \
  -H "Authorization: Bearer $USER_TOKEN"
```

### Rate Limiting API Testing

```bash
# Test public endpoint (limited to 5 requests per minute)
for i in {1..10}; do
  echo "Request $i:"
  curl -w "%{http_code}\n" http://localhost:8080/api/public/data
  echo "---"
done

# Test premium endpoint with API key
curl http://localhost:8080/api/premium/data \
  -H "X-API-Key: your-api-key-here"

# Test without API key (should fail)
curl http://localhost:8080/api/premium/data
```

### WebSocket Chat Testing

You can test the WebSocket chat in several ways:

1. **Using the built-in client:**
   - Open http://localhost:8080/client?room=general in your browser
   - Open multiple browser tabs to simulate multiple users

2. **Using curl to send HTTP messages:**
```bash
# Send a message to the chat room via HTTP
curl -X POST http://localhost:8080/chat/rooms/general/message \
  -H "Content-Type: application/json" \
  -d '{
    "user": "API User",
    "message": "Hello from the API!"
  }'
```

3. **Using a WebSocket client library:**
```javascript
// JavaScript WebSocket client example
const ws = new WebSocket('ws://localhost:8080/chat/ws/general');

ws.onopen = () => {
  console.log('Connected to chat');
  ws.send(JSON.stringify({
    user: 'TestUser',
    message: 'Hello everyone!'
  }));
};

ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  console.log('Received:', message);
};
```

### Load Testing Examples

You can use tools like `ab` (Apache Bench) or `wrk` to test performance:

```bash
# Test with Apache Bench
ab -n 1000 -c 10 http://localhost:8080/api/v1/products

# Test POST requests with wrk
wrk -t4 -c100 -d30s -s post.lua http://localhost:8080/api/v1/products
```

Where `post.lua` contains:
```lua
wrk.method = "POST"
wrk.body = '{"name":"Test Product","description":"Test","price":10.99,"stock":50,"category":"Test"}'
wrk.headers["Content-Type"] = "application/json"
```

### Automated Testing with Dart

Create comprehensive tests for your APIs:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('E-commerce API Tests', () {
    late HttpServer server;
    late String baseUrl;

    setUpAll(() async {
      // Start your server here
      baseUrl = 'http://localhost:8080';
    });

    tearDownAll(() async {
      // Stop your server here
    });

    test('should create a product', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': 'Test Product',
          'description': 'A test product',
          'price': 29.99,
          'stock': 10,
          'category': 'Test',
        }),
      );

      expect(response.statusCode, equals(201));
      final data = jsonDecode(response.body);
      expect(data['name'], equals('Test Product'));
    });

    test('should get all products', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/products'),
      );

      expect(response.statusCode, equals(200));
      final data = jsonDecode(response.body);
      expect(data['products'], isA<List>());
    });

    test('should handle authentication', () async {
      // Login
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'admin@example.com',
          'password': 'admin123',
        }),
      );

      expect(loginResponse.statusCode, equals(200));
      final loginData = jsonDecode(loginResponse.body);
      final token = loginData['token'];

      // Use token to access protected route
      final protectedResponse = await http.get(
        Uri.parse('$baseUrl/protected/user-data'),
        headers: {'Authorization': 'Bearer $token'},
      );

      expect(protectedResponse.statusCode, equals(200));
    });
  });
}
```

These examples demonstrate comprehensive testing strategies for Dart Flux applications, from simple curl commands to automated test suites. Choose the testing approach that best fits your development workflow and requirements.

These examples demonstrate how to use Dart Flux's routing system for building APIs with proper middleware, error handling, and nested routers.

## Real-World E-commerce API

This example shows how to build a comprehensive e-commerce API with products, orders, and user management.

```dart
import 'dart:io';
import 'dart:convert';
import 'package:dart_flux/dart_flux.dart';

// Models
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String category;
  final List<String> images;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.category,
    required this.images,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'stock': stock,
    'category': category,
    'images': images,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    price: json['price'].toDouble(),
    stock: json['stock'],
    category: json['category'],
    images: List<String>.from(json['images']),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double total;
  final String status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'items': items.map((item) => item.toJson()).toList(),
    'total': total,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };
}

class OrderItem {
  final String productId;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
    'price': price,
  };
}

// Services
class ProductService {
  static final Map<String, Product> _products = {};
  
  static List<Product> getAllProducts({String? category, double? minPrice, double? maxPrice}) {
    var products = _products.values.where((product) {
      if (category != null && product.category != category) return false;
      if (minPrice != null && product.price < minPrice) return false;
      if (maxPrice != null && product.price > maxPrice) return false;
      return true;
    }).toList();
    
    return products;
  }
  
  static Product? getProduct(String id) => _products[id];
  
  static Product createProduct(Map<String, dynamic> data) {
    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: data['name'],
      description: data['description'],
      price: data['price'].toDouble(),
      stock: data['stock'],
      category: data['category'],
      images: List<String>.from(data['images'] ?? []),
      createdAt: DateTime.now(),
    );
    
    _products[product.id] = product;
    return product;
  }
  
  static Product? updateProduct(String id, Map<String, dynamic> data) {
    final product = _products[id];
    if (product == null) return null;
    
    final updated = Product(
      id: product.id,
      name: data['name'] ?? product.name,
      description: data['description'] ?? product.description,
      price: data['price']?.toDouble() ?? product.price,
      stock: data['stock'] ?? product.stock,
      category: data['category'] ?? product.category,
      images: data['images'] != null ? List<String>.from(data['images']) : product.images,
      createdAt: product.createdAt,
    );
    
    _products[id] = updated;
    return updated;
  }
  
  static bool deleteProduct(String id) {
    return _products.remove(id) != null;
  }
  
  static bool updateStock(String productId, int quantity) {
    final product = _products[productId];
    if (product == null || product.stock < quantity) return false;
    
    final updated = Product(
      id: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      stock: product.stock - quantity,
      category: product.category,
      images: product.images,
      createdAt: product.createdAt,
    );
    
    _products[productId] = updated;
    return true;
  }
}

class OrderService {
  static final Map<String, Order> _orders = {};
  
  static List<Order> getOrdersByUser(String userId) {
    return _orders.values.where((order) => order.userId == userId).toList();
  }
  
  static Order? getOrder(String id) => _orders[id];
  
  static Order? createOrder(String userId, List<Map<String, dynamic>> items) {
    // Validate and calculate total
    double total = 0;
    final orderItems = <OrderItem>[];
    
    for (final item in items) {
      final product = ProductService.getProduct(item['productId']);
      if (product == null) return null;
      
      final quantity = item['quantity'] as int;
      if (product.stock < quantity) return null;
      
      orderItems.add(OrderItem(
        productId: product.id,
        quantity: quantity,
        price: product.price,
      ));
      
      total += product.price * quantity;
    }
    
    // Update stock for all products
    for (final item in orderItems) {
      ProductService.updateStock(item.productId, item.quantity);
    }
    
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      items: orderItems,
      total: total,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    
    _orders[order.id] = order;
    return order;
  }
}

// Middleware
Middleware corsMiddleware = (request, response, next) async {
  response.header('Access-Control-Allow-Origin', '*');
  response.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  response.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  if (request.method == 'OPTIONS') {
    response.status(200).send();
    return;
  }
  
  await next();
};

Middleware validateProductMiddleware = (request, response, next) async {
  if (request.method == 'POST' || request.method == 'PUT') {
    final body = request.body as Map<String, dynamic>?;
    
    if (body == null) {
      response.status(400).json({'error': 'Request body required'});
      return;
    }
    
    final requiredFields = ['name', 'description', 'price', 'stock', 'category'];
    for (final field in requiredFields) {
      if (!body.containsKey(field)) {
        response.status(400).json({'error': 'Missing required field: $field'});
        return;
      }
    }
    
    if (body['price'] <= 0) {
      response.status(400).json({'error': 'Price must be greater than 0'});
      return;
    }
    
    if (body['stock'] < 0) {
      response.status(400).json({'error': 'Stock cannot be negative'});
      return;
    }
  }
  
  await next();
};

void main() async {
  // Seed some sample data
  ProductService.createProduct({
    'name': 'Wireless Headphones',
    'description': 'High-quality wireless headphones with noise cancellation',
    'price': 199.99,
    'stock': 50,
    'category': 'Electronics',
    'images': ['headphones1.jpg', 'headphones2.jpg'],
  });
  
  ProductService.createProduct({
    'name': 'Running Shoes',
    'description': 'Comfortable running shoes for all terrains',
    'price': 89.99,
    'stock': 30,
    'category': 'Sports',
    'images': ['shoes1.jpg', 'shoes2.jpg'],
  });
  
  // Products router
  final productsRouter = Router.path('/products')
    .use(corsMiddleware)
    
    // Get all products with filtering
    .get('/', (request, response, pathArgs) async {
      final params = request.url.queryParameters;
      final category = params['category'];
      final minPrice = double.tryParse(params['minPrice'] ?? '');
      final maxPrice = double.tryParse(params['maxPrice'] ?? '');
      
      final products = ProductService.getAllProducts(
        category: category,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );
      
      response.json({
        'products': products.map((p) => p.toJson()).toList(),
        'total': products.length,
      });
    })
    
    // Get product by ID
    .get('/:id', (request, response, pathArgs) async {
      final product = ProductService.getProduct(pathArgs['id']!);
      
      if (product == null) {
        response.status(404).json({'error': 'Product not found'});
        return;
      }
      
      response.json(product.toJson());
    })
    
    // Create product (admin only - simplified for example)
    .post('/', validateProductMiddleware, (request, response, pathArgs) async {
      final product = ProductService.createProduct(request.body);
      response.status(201).json(product.toJson());
    })
    
    // Update product
    .put('/:id', validateProductMiddleware, (request, response, pathArgs) async {
      final product = ProductService.updateProduct(pathArgs['id']!, request.body);
      
      if (product == null) {
        response.status(404).json({'error': 'Product not found'});
        return;
      }
      
      response.json(product.toJson());
    })
    
    // Delete product
    .delete('/:id', (request, response, pathArgs) async {
      final deleted = ProductService.deleteProduct(pathArgs['id']!);
      
      if (!deleted) {
        response.status(404).json({'error': 'Product not found'});
        return;
      }
      
      response.json({'message': 'Product deleted successfully'});
    });
  
  // Orders router
  final ordersRouter = Router.path('/orders')
    .use(corsMiddleware)
    
    // Create order
    .post('/', (request, response, pathArgs) async {
      final body = request.body as Map<String, dynamic>;
      final userId = body['userId'] as String?;
      final items = body['items'] as List<dynamic>?;
      
      if (userId == null || items == null) {
        response.status(400).json({'error': 'userId and items are required'});
        return;
      }
      
      final order = OrderService.createOrder(
        userId,
        items.cast<Map<String, dynamic>>(),
      );
      
      if (order == null) {
        response.status(400).json({'error': 'Invalid order or insufficient stock'});
        return;
      }
      
      response.status(201).json(order.toJson());
    })
    
    // Get orders by user
    .get('/user/:userId', (request, response, pathArgs) async {
      final orders = OrderService.getOrdersByUser(pathArgs['userId']!);
      response.json({
        'orders': orders.map((o) => o.toJson()).toList(),
        'total': orders.length,
      });
    })
    
    // Get order by ID
    .get('/:id', (request, response, pathArgs) async {
      final order = OrderService.getOrder(pathArgs['id']!);
      
      if (order == null) {
        response.status(404).json({'error': 'Order not found'});
        return;
      }
      
      response.json(order.toJson());
    });
  
  // Main API router
  final apiRouter = Router.path('/api/v1')
    .addRouter(productsRouter)
    .addRouter(ordersRouter)
    
    // Health check
    .get('/health', (request, response, pathArgs) async {
      response.json({
        'status': 'OK',
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      });
    });
  
  // Main router
  final mainRouter = Router()
    .addRouter(apiRouter)
    
    // Root endpoint
    .get('/', (request, response, pathArgs) async {
      response.json({
        'message': 'E-commerce API',
        'version': '1.0.0',
        'endpoints': {
          'products': '/api/v1/products',
          'orders': '/api/v1/orders',
          'health': '/api/v1/health',
        },
      });
    });
  
  // Start server
  final server = Server(
    InternetAddress.anyIPv4,
    8080,
    mainRouter,
    loggerEnabled: true,
  );
  
  await server.run();
  print('E-commerce API running on http://localhost:8080');
}
```

## Blog Platform API

A complete blog platform with posts, comments, categories, and user management.

```dart
import 'dart:io';
import 'package:dart_flux/dart_flux.dart';

// Models
class BlogPost {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String categoryId;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool published;

  BlogPost({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.categoryId,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.published,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'authorId': authorId,
    'categoryId': categoryId,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'published': published,
  };
}

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'postId': postId,
    'authorId': authorId,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };
}

// Services
class BlogService {
  static final Map<String, BlogPost> _posts = {};
  static final Map<String, Comment> _comments = {};
  static final Map<String, String> _categories = {
    '1': 'Technology',
    '2': 'Science',
    '3': 'Travel',
    '4': 'Food',
  };
  
  // Posts
  static List<BlogPost> getPosts({String? category, List<String>? tags, bool? published}) {
    return _posts.values.where((post) {
      if (published != null && post.published != published) return false;
      if (category != null && post.categoryId != category) return false;
      if (tags != null && !tags.any((tag) => post.tags.contains(tag))) return false;
      return true;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  
  static BlogPost? getPost(String id) => _posts[id];
  
  static BlogPost createPost(Map<String, dynamic> data) {
    final now = DateTime.now();
    final post = BlogPost(
      id: now.millisecondsSinceEpoch.toString(),
      title: data['title'],
      content: data['content'],
      authorId: data['authorId'],
      categoryId: data['categoryId'],
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: now,
      updatedAt: now,
      published: data['published'] ?? false,
    );
    
    _posts[post.id] = post;
    return post;
  }
  
  static BlogPost? updatePost(String id, Map<String, dynamic> data) {
    final post = _posts[id];
    if (post == null) return null;
    
    final updated = BlogPost(
      id: post.id,
      title: data['title'] ?? post.title,
      content: data['content'] ?? post.content,
      authorId: post.authorId,
      categoryId: data['categoryId'] ?? post.categoryId,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : post.tags,
      createdAt: post.createdAt,
      updatedAt: DateTime.now(),
      published: data['published'] ?? post.published,
    );
    
    _posts[id] = updated;
    return updated;
  }
  
  // Comments
  static List<Comment> getCommentsByPost(String postId) {
    return _comments.values.where((comment) => comment.postId == postId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
  
  static Comment createComment(Map<String, dynamic> data) {
    final comment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: data['postId'],
      authorId: data['authorId'],
      content: data['content'],
      createdAt: DateTime.now(),
    );
    
    _comments[comment.id] = comment;
    return comment;
  }
  
  // Categories
  static Map<String, String> getCategories() => Map.from(_categories);
}

void main() async {
  // Seed data
  BlogService.createPost({
    'title': 'Getting Started with Dart Flux',
    'content': 'Dart Flux is a powerful framework for building web servers...',
    'authorId': 'user1',
    'categoryId': '1',
    'tags': ['dart', 'web', 'tutorial'],
    'published': true,
  });
  
  // Blog posts router
  final postsRouter = Router.path('/posts')
    // Get all posts with filtering
    .get('/', (request, response, pathArgs) async {
      final params = request.url.queryParameters;
      final category = params['category'];
      final tags = params['tags']?.split(',');
      final published = params['published'] == 'true';
      
      final posts = BlogService.getPosts(
        category: category,
        tags: tags,
        published: published,
      );
      
      response.json({
        'posts': posts.map((p) => p.toJson()).toList(),
        'total': posts.length,
      });
    })
    
    // Get post by ID
    .get('/:id', (request, response, pathArgs) async {
      final post = BlogService.getPost(pathArgs['id']!);
      
      if (post == null) {
        response.status(404).json({'error': 'Post not found'});
        return;
      }
      
      response.json(post.toJson());
    })
    
    // Create post
    .post('/', (request, response, pathArgs) async {
      final body = request.body as Map<String, dynamic>;
      
      // Validation
      if (body['title'] == null || body['content'] == null) {
        response.status(400).json({'error': 'Title and content are required'});
        return;
      }
      
      final post = BlogService.createPost(body);
      response.status(201).json(post.toJson());
    })
    
    // Update post
    .put('/:id', (request, response, pathArgs) async {
      final post = BlogService.updatePost(pathArgs['id']!, request.body);
      
      if (post == null) {
        response.status(404).json({'error': 'Post not found'});
        return;
      }
      
      response.json(post.toJson());
    })
    
    // Get comments for post
    .get('/:id/comments', (request, response, pathArgs) async {
      final comments = BlogService.getCommentsByPost(pathArgs['id']!);
      response.json({
        'comments': comments.map((c) => c.toJson()).toList(),
        'total': comments.length,
      });
    })
    
    // Add comment to post
    .post('/:id/comments', (request, response, pathArgs) async {
      final body = request.body as Map<String, dynamic>;
      body['postId'] = pathArgs['id'];
      
      if (body['content'] == null || body['authorId'] == null) {
        response.status(400).json({'error': 'Content and authorId are required'});
        return;
      }
      
      final comment = BlogService.createComment(body);
      response.status(201).json(comment.toJson());
    });
  
  // Categories router
  final categoriesRouter = Router.path('/categories')
    .get('/', (request, response, pathArgs) async {
      final categories = BlogService.getCategories();
      response.json({'categories': categories});
    });
  
  // Main blog API
  final blogRouter = Router.path('/api/blog')
    .addRouter(postsRouter)
    .addRouter(categoriesRouter);
  
  final mainRouter = Router()
    .addRouter(blogRouter)
    .get('/', (request, response, pathArgs) async {
      response.json({
        'message': 'Blog Platform API',
        'endpoints': {
          'posts': '/api/blog/posts',
          'categories': '/api/blog/categories',
        },
      });
    });
  
  final server = Server(InternetAddress.anyIPv4, 8080, mainRouter);
  await server.run();
  print('Blog API running on http://localhost:8080');
}
```

## File Management System

A complete file management system with upload, download, and organization features.

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:dart_flux/dart_flux.dart';
import 'package:path/path.dart' as path;

class FileMetadata {
  final String id;
  final String originalName;
  final String storedName;
  final String mimeType;
  final int size;
  final String path;
  final DateTime uploadedAt;
  final Map<String, dynamic> metadata;

  FileMetadata({
    required this.id,
    required this.originalName,
    required this.storedName,
    required this.mimeType,
    required this.size,
    required this.path,
    required this.uploadedAt,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'originalName': originalName,
    'storedName': storedName,
    'mimeType': mimeType,
    'size': size,
    'path': path,
    'uploadedAt': uploadedAt.toIso8601String(),
    'metadata': metadata,
  };
}

class FileService {
  static final Map<String, FileMetadata> _files = {};
  static const String uploadsDir = 'uploads';
  
  static Future<void> initialize() async {
    final dir = Directory(uploadsDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }
  
  static String _generateFileName(String originalName) {
    final ext = path.extension(originalName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$timestamp$ext';
  }
  
  static String _getMimeType(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      case '.txt':
        return 'text/plain';
      case '.json':
        return 'application/json';
      default:
        return 'application/octet-stream';
    }
  }
  
  static Future<FileMetadata> saveFile(
    String originalName,
    Uint8List bytes, {
    Map<String, dynamic>? metadata,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final storedName = _generateFileName(originalName);
    final filePath = path.join(uploadsDir, storedName);
    
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    
    final fileMetadata = FileMetadata(
      id: id,
      originalName: originalName,
      storedName: storedName,
      mimeType: _getMimeType(originalName),
      size: bytes.length,
      path: filePath,
      uploadedAt: DateTime.now(),
      metadata: metadata ?? {},
    );
    
    _files[id] = fileMetadata;
    return fileMetadata;
  }
  
  static FileMetadata? getFileMetadata(String id) => _files[id];
  
  static List<FileMetadata> getAllFiles() => _files.values.toList();
  
  static Future<bool> deleteFile(String id) async {
    final fileMetadata = _files[id];
    if (fileMetadata == null) return false;
    
    final file = File(fileMetadata.path);
    if (await file.exists()) {
      await file.delete();
    }
    
    _files.remove(id);
    return true;
  }
}

void main() async {
  await FileService.initialize();
  
  final fileRouter = Router.path('/files')
    // Upload file
    .post('/upload', (request, response, pathArgs) async {
      if (!request.hasFormData) {
        response.status(400).json({'error': 'No form data provided'});
        return;
      }
      
      try {
        final formData = await request.formData;
        final files = formData.files('file');
        
        if (files.isEmpty) {
          response.status(400).json({'error': 'No file provided'});
          return;
        }
        
        final uploadedFiles = <Map<String, dynamic>>[];
        
        for (final file in files) {
          final metadata = await FileService.saveFile(
            file.filename ?? 'unknown',
            file.bytes,
            metadata: {
              'uploadedBy': request.headers.value('X-User-ID') ?? 'anonymous',
              'userAgent': request.headers.value('User-Agent'),
            },
          );
          
          uploadedFiles.add(metadata.toJson());
        }
        
        response.status(201).json({
          'message': 'Files uploaded successfully',
          'files': uploadedFiles,
        });
      } catch (e) {
        response.status(500).json({'error': 'Upload failed: $e'});
      }
    })
    
    // Upload multiple files with progress
    .post('/upload/batch', (request, response, pathArgs) async {
      // Set response headers for SSE (Server-Sent Events)
      response.header('Content-Type', 'text/event-stream');
      response.header('Cache-Control', 'no-cache');
      response.header('Connection', 'keep-alive');
      
      try {
        final formData = await request.formData;
        final files = formData.files('files');
        final total = files.length;
        
        if (total == 0) {
          response.write('data: {"error": "No files provided"}\n\n');
          return;
        }
        
        final uploadedFiles = <Map<String, dynamic>>[];
        
        for (int i = 0; i < files.length; i++) {
          final file = files[i];
          
          // Send progress update
          response.write('data: {"progress": ${((i / total) * 100).round()}, "current": "${file.filename}"}\n\n');
          
          final metadata = await FileService.saveFile(
            file.filename ?? 'unknown',
            file.bytes,
          );
          
          uploadedFiles.add(metadata.toJson());
        }
        
        // Send completion
        response.write('data: {"complete": true, "files": ${jsonEncode(uploadedFiles)}}\n\n');
      } catch (e) {
        response.write('data: {"error": "Upload failed: $e"}\n\n');
      }
    })
    
    // List all files
    .get('/', (request, response, pathArgs) async {
      final files = FileService.getAllFiles();
      response.json({
        'files': files.map((f) => f.toJson()).toList(),
        'total': files.length,
      });
    })
    
    // Get file metadata
    .get('/:id/info', (request, response, pathArgs) async {
      final fileMetadata = FileService.getFileMetadata(pathArgs['id']!);
      
      if (fileMetadata == null) {
        response.status(404).json({'error': 'File not found'});
        return;
      }
      
      response.json(fileMetadata.toJson());
    })
    
    // Download file
    .get('/:id/download', (request, response, pathArgs) async {
      final fileMetadata = FileService.getFileMetadata(pathArgs['id']!);
      
      if (fileMetadata == null) {
        response.status(404).json({'error': 'File not found'});
        return;
      }
      
      final file = File(fileMetadata.path);
      if (!await file.exists()) {
        response.status(404).json({'error': 'File not found on disk'});
        return;
      }
      
      response.header('Content-Type', fileMetadata.mimeType);
      response.header('Content-Disposition', 'attachment; filename="${fileMetadata.originalName}"');
      response.header('Content-Length', fileMetadata.size.toString());
      
      await response.streamFile(file);
    })
    
    // View file (inline)
    .get('/:id/view', (request, response, pathArgs) async {
      final fileMetadata = FileService.getFileMetadata(pathArgs['id']!);
      
      if (fileMetadata == null) {
        response.status(404).json({'error': 'File not found'});
        return;
      }
      
      final file = File(fileMetadata.path);
      if (!await file.exists()) {
        response.status(404).json({'error': 'File not found on disk'});
        return;
      }
      
      response.header('Content-Type', fileMetadata.mimeType);
      response.header('Content-Length', fileMetadata.size.toString());
      
      await response.streamFile(file);
    })
    
    // Delete file
    .delete('/:id', (request, response, pathArgs) async {
      final deleted = await FileService.deleteFile(pathArgs['id']!);
      
      if (!deleted) {
        response.status(404).json({'error': 'File not found'});
        return;
      }
      
      response.json({'message': 'File deleted successfully'});
    });
  
  final mainRouter = Router()
    .addRouter(fileRouter)
    .get('/', (request, response, pathArgs) async {
      response.json({
        'message': 'File Management API',
        'endpoints': {
          'upload': 'POST /files/upload',
          'list': 'GET /files',
          'download': 'GET /files/:id/download',
          'view': 'GET /files/:id/view',
          'delete': 'DELETE /files/:id',
        },
      });
    });
  
  final server = Server(InternetAddress.anyIPv4, 8080, mainRouter);
  await server.run();
  print('File Management API running on http://localhost:8080');
}
```

## Authentication & Authorization

Comprehensive authentication system with JWT tokens, role-based access control, and session management.

```dart
import 'dart:io';
import 'dart:convert';
import 'package:dart_flux/dart_flux.dart';
import 'package:crypto/crypto.dart';

// User and role models
class User {
  final String id;
  final String email;
  final String name;
  final List<String> roles;
  final DateTime createdAt;
  final bool active;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.roles,
    required this.createdAt,
    required this.active,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'roles': roles,
    'createdAt': createdAt.toIso8601String(),
    'active': active,
  };
}

// Simple auth service
class AuthService {
  static final Map<String, User> _users = {};
  static final Map<String, String> _passwords = {}; // In production, use proper password hashing
  static final Map<String, DateTime> _sessions = {};
  static const String secretKey = 'your-secret-key-here';
  
  static void initialize() {
    // Create default admin user
    final adminUser = User(
      id: '1',
      email: 'admin@example.com',
      name: 'Admin User',
      roles: ['admin', 'user'],
      createdAt: DateTime.now(),
      active: true,
    );
    
    _users[adminUser.id] = adminUser;
    _passwords[adminUser.id] = _hashPassword('admin123');
    
    // Create regular user
    final regularUser = User(
      id: '2',
      email: 'user@example.com',
      name: 'Regular User',
      roles: ['user'],
      createdAt: DateTime.now(),
      active: true,
    );
    
    _users[regularUser.id] = regularUser;
    _passwords[regularUser.id] = _hashPassword('user123');
  }
  
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  static User? authenticate(String email, String password) {
    final user = _users.values.firstWhere(
      (u) => u.email == email && u.active,
      orElse: () => throw StateError('User not found'),
    );
    
    final hashedPassword = _hashPassword(password);
    if (_passwords[user.id] == hashedPassword) {
      return user;
    }
    
    return null;
  }
  
  static String generateToken(User user) {
    final payload = {
      'userId': user.id,
      'email': user.email,
      'roles': user.roles,
      'iat': DateTime.now().millisecondsSinceEpoch,
      'exp': DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch,
    };
    
    // Simple token generation (use proper JWT library in production)
    final tokenData = base64Encode(utf8.encode(jsonEncode(payload)));
    return '$tokenData.signature';
  }
  
  static Map<String, dynamic>? verifyToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 2) return null;
      
      final payload = jsonDecode(utf8.decode(base64Decode(parts[0])));
      final exp = payload['exp'] as int;
      
      if (DateTime.now().millisecondsSinceEpoch > exp) {
        return null; // Token expired
      }
      
      return payload;
    } catch (e) {
      return null;
    }
  }
  
  static User? getUserById(String id) => _users[id];
}

// Authentication middleware
Middleware authMiddleware = (request, response, next) async {
  final authHeader = request.headers.value('Authorization');
  
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    response.status(401).json({'error': 'Missing or invalid authorization header'});
    return;
  }
  
  final token = authHeader.substring(7);
  final payload = AuthService.verifyToken(token);
  
  if (payload == null) {
    response.status(401).json({'error': 'Invalid or expired token'});
    return;
  }
  
  // Add user info to request context
  request.context['user'] = payload;
  await next();
};

// Role-based authorization middleware
Middleware requireRole(String role) {
  return (request, response, next) async {
    final user = request.context['user'] as Map<String, dynamic>?;
    
    if (user == null) {
      response.status(401).json({'error': 'Authentication required'});
      return;
    }
    
    final roles = List<String>.from(user['roles'] ?? []);
    if (!roles.contains(role)) {
      response.status(403).json({'error': 'Insufficient permissions'});
      return;
    }
    
    await next();
  };
}

void main() async {
  AuthService.initialize();
  
  // Auth router
  final authRouter = Router.path('/auth')
    // Login
    .post('/login', (request, response, pathArgs) async {
      final body = request.body as Map<String, dynamic>;
      final email = body['email'] as String?;
      final password = body['password'] as String?;
      
      if (email == null || password == null) {
        response.status(400).json({'error': 'Email and password are required'});
        return;
      }
      
      final user = AuthService.authenticate(email, password);
      
      if (user == null) {
        response.status(401).json({'error': 'Invalid credentials'});
        return;
      }
      
      final token = AuthService.generateToken(user);
      
      response.json({
        'token': token,
        'user': user.toJson(),
      });
    })
    
    // Get current user profile
    .get('/profile', authMiddleware, (request, response, pathArgs) async {
      final userPayload = request.context['user'] as Map<String, dynamic>;
      final user = AuthService.getUserById(userPayload['userId']);
      
      if (user == null) {
        response.status(404).json({'error': 'User not found'});
        return;
      }
      
      response.json(user.toJson());
    })
    
    // Refresh token
    .post('/refresh', authMiddleware, (request, response, pathArgs) async {
      final userPayload = request.context['user'] as Map<String, dynamic>;
      final user = AuthService.getUserById(userPayload['userId']);
      
      if (user == null) {
        response.status(404).json({'error': 'User not found'});
        return;
      }
      
      final newToken = AuthService.generateToken(user);
      response.json({'token': newToken});
    });
  
  // Protected routes
  final protectedRouter = Router.path('/protected')
    .use(authMiddleware)
    
    // User-level protected route
    .get('/user-data', (request, response, pathArgs) async {
      final user = request.context['user'] as Map<String, dynamic>;
      response.json({
        'message': 'This is protected user data',
        'userId': user['userId'],
        'timestamp': DateTime.now().toIso8601String(),
      });
    })
    
    // Admin-only route
    .get('/admin-data', requireRole('admin'), (request, response, pathArgs) async {
      response.json({
        'message': 'This is admin-only data',
        'serverStats': {
          'uptime': DateTime.now().difference(DateTime.now().subtract(Duration(hours: 2))).inMinutes,
          'memoryUsage': '45 MB',
        },
      });
    })
    
    // Moderator or admin route
    .get('/moderation', (request, response, next) async {
      final user = request.context['user'] as Map<String, dynamic>;
      final roles = List<String>.from(user['roles'] ?? []);
      
      if (!roles.any((role) => ['admin', 'moderator'].contains(role))) {
        response.status(403).json({'error': 'Requires admin or moderator role'});
        return;
      }
      
      await next();
    }, (request, response, pathArgs) async {
      response.json({
        'message': 'Moderation tools',
        'actions': ['ban_user', 'delete_post', 'edit_content'],
      });
    });
  
  final mainRouter = Router()
    .addRouter(authRouter)
    .addRouter(protectedRouter)
    
    // Public route
    .get('/', (request, response, pathArgs) async {
      response.json({
        'message': 'Authentication Demo API',
        'endpoints': {
          'login': 'POST /auth/login',
          'profile': 'GET /auth/profile (requires auth)',
          'userData': 'GET /protected/user-data (requires auth)',
          'adminData': 'GET /protected/admin-data (requires admin role)',
        },
        'testCredentials': {
          'admin': {'email': 'admin@example.com', 'password': 'admin123'},
          'user': {'email': 'user@example.com', 'password': 'user123'},
        },
      });
    });
  
  final server = Server(InternetAddress.anyIPv4, 8080, mainRouter);
  await server.run();
  print('Auth API running on http://localhost:8080');
}
```

## WebSocket Integration

Example showing how to integrate WebSockets with Dart Flux for real-time communication.

```dart
import 'dart:io';
import 'dart:convert';
import 'package:dart_flux/dart_flux.dart';

class ChatRoom {
  final String id;
  final String name;
  final Set<WebSocket> clients = {};
  final List<Map<String, dynamic>> messages = [];

  ChatRoom({required this.id, required this.name});

  void addClient(WebSocket socket) {
    clients.add(socket);
    print('Client joined room $name. Total clients: ${clients.length}');
    
    // Send recent messages to new client
    for (final message in messages.take(10)) {
      socket.add(jsonEncode(message));
    }
  }

  void removeClient(WebSocket socket) {
    clients.remove(socket);
    print('Client left room $name. Total clients: ${clients.length}');
  }

  void broadcast(Map<String, dynamic> message) {
    messages.add(message);
    if (messages.length > 100) {
      messages.removeAt(0); // Keep only recent messages
    }
    
    final messageStr = jsonEncode(message);
    final deadSockets = <WebSocket>[];
    
    for (final client in clients) {
      try {
        client.add(messageStr);
      } catch (e) {
        deadSockets.add(client);
      }
    }
    
    // Remove dead connections
    for (final deadSocket in deadSockets) {
      clients.remove(deadSocket);
    }
  }
}

class ChatService {
  static final Map<String, ChatRoom> _rooms = {};
  
  static ChatRoom getOrCreateRoom(String roomId) {
    return _rooms.putIfAbsent(roomId, () => ChatRoom(
      id: roomId,
      name: 'Room $roomId',
    ));
  }
  
  static List<Map<String, dynamic>> getRoomList() {
    return _rooms.values.map((room) => {
      'id': room.id,
      'name': room.name,
      'clientCount': room.clients.length,
    }).toList();
  }
}

void main() async {
  // WebSocket chat router
  final chatRouter = Router.path('/chat')
    // Get list of chat rooms
    .get('/rooms', (request, response, pathArgs) async {
      final rooms = ChatService.getRoomList();
      response.json({'rooms': rooms});
    })
    
    // WebSocket endpoint for chat
    .get('/ws/:roomId', (request, response, pathArgs) async {
      if (!WebSocketTransformer.isUpgradeRequest(request.rawRequest)) {
        response.status(400).json({'error': 'WebSocket upgrade required'});
        return;
      }
      
      final roomId = pathArgs['roomId']!;
      final room = ChatService.getOrCreateRoom(roomId);
      
      try {
        final socket = await WebSocketTransformer.upgrade(request.rawRequest);
        room.addClient(socket);
        
        // Send welcome message
        socket.add(jsonEncode({
          'type': 'system',
          'message': 'Welcome to $roomId',
          'timestamp': DateTime.now().toIso8601String(),
        }));
        
        // Listen for messages
        socket.listen(
          (data) {
            try {
              final message = jsonDecode(data as String);
              
              // Broadcast message to all clients in room
              room.broadcast({
                'type': 'message',
                'user': message['user'] ?? 'Anonymous',
                'message': message['message'],
                'timestamp': DateTime.now().toIso8601String(),
              });
            } catch (e) {
              socket.add(jsonEncode({
                'type': 'error',
                'message': 'Invalid message format',
              }));
            }
          },
          onDone: () {
            room.removeClient(socket);
          },
          onError: (error) {
            print('WebSocket error: $error');
            room.removeClient(socket);
          },
        );
      } catch (e) {
        response.status(500).json({'error': 'Failed to upgrade to WebSocket'});
      }
    })
    
    // HTTP endpoint to send message to room
    .post('/rooms/:roomId/message', (request, response, pathArgs) async {
      final roomId = pathArgs['roomId']!;
      final body = request.body as Map<String, dynamic>;
      
      if (!ChatService._rooms.containsKey(roomId)) {
        response.status(404).json({'error': 'Room not found'});
        return;
      }
      
      final room = ChatService._rooms[roomId]!;
      room.broadcast({
        'type': 'message',
        'user': body['user'] ?? 'API User',
        'message': body['message'],
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      response.json({'message': 'Message sent to room'});
    });
  
  // Serve a simple chat client
  final clientRouter = Router.path('/client')
    .get('/', (request, response, pathArgs) async {
      final html = '''
<!DOCTYPE html>
<html>
<head>
    <title>Dart Flux Chat</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        #messages { border: 1px solid #ccc; height: 400px; overflow-y: scroll; padding: 10px; margin-bottom: 10px; }
        #messageInput { width: 70%; padding: 5px; }
        #sendButton { padding: 5px 10px; }
        .message { margin-bottom: 5px; }
        .system { color: #666; font-style: italic; }
        .user { font-weight: bold; }
    </style>
</head>
<body>
    <h1>Chat Room: <span id="roomId">general</span></h1>
    <div id="messages"></div>
    <input type="text" id="messageInput" placeholder="Type your message...">
    <button id="sendButton">Send</button>
    
    <script>
        const roomId = new URLSearchParams(window.location.search).get('room') || 'general';
        document.getElementById('roomId').textContent = roomId;
        
        const ws = new WebSocket(\`ws://localhost:8080/chat/ws/\${roomId}\`);
        const messages = document.getElementById('messages');
        const messageInput = document.getElementById('messageInput');
        const sendButton = document.getElementById('sendButton');
        
        ws.onmessage = (event) => {
            const data = JSON.parse(event.data);
            const messageDiv = document.createElement('div');
            messageDiv.className = 'message';
            
            if (data.type === 'system') {
                messageDiv.className += ' system';
                messageDiv.textContent = data.message;
            } else {
                messageDiv.innerHTML = \`<span class="user">\${data.user}:</span> \${data.message}\`;
            }
            
            messages.appendChild(messageDiv);
            messages.scrollTop = messages.scrollHeight;
        };
        
        function sendMessage() {
            const message = messageInput.value.trim();
            if (message) {
                ws.send(JSON.stringify({
                    user: 'User' + Math.floor(Math.random() * 1000),
                    message: message
                }));
                messageInput.value = '';
            }
        }
        
        sendButton.onclick = sendMessage;
        messageInput.onkeypress = (e) => {
            if (e.key === 'Enter') sendMessage();
        };
    </script>
</body>
</html>
      ''';
      
      response.header('Content-Type', 'text/html');
      response.write(html);
    });
  
  final mainRouter = Router()
    .addRouter(chatRouter)
    .addRouter(clientRouter)
    .get('/', (request, response, pathArgs) async {
      response.json({
        'message': 'WebSocket Chat API',
        'endpoints': {
          'rooms': 'GET /chat/rooms',
          'websocket': 'WS /chat/ws/:roomId',
          'chatClient': 'GET /client?room=roomName',
        },
      });
    });
  
  final server = Server(InternetAddress.anyIPv4, 8080, mainRouter);
  await server.run();
  print('WebSocket Chat running on http://localhost:8080');
  print('Open http://localhost:8080/client?room=general to test the chat');
}
```

## Rate Limiting Example

Implementing rate limiting to protect your API from abuse.

```dart
import 'dart:io';
import 'package:dart_flux/dart_flux.dart';

class RateLimiter {
  final Map<String, List<DateTime>> _requests = {};
  final int maxRequests;
  final Duration window;
  final Duration? banDuration;

  RateLimiter({
    required this.maxRequests,
    required this.window,
    this.banDuration,
  });

  bool isAllowed(String clientId) {
    final now = DateTime.now();
    final requests = _requests.putIfAbsent(clientId, () => []);
    
    // Remove old requests outside the window
    requests.removeWhere((request) => now.difference(request) > window);
    
    if (requests.length >= maxRequests) {
      return false;
    }
    
    requests.add(now);
    return true;
  }

  int getRemainingRequests(String clientId) {
    final requests = _requests[clientId] ?? [];
    return maxRequests - requests.length;
  }

  Duration? getResetTime(String clientId) {
    final requests = _requests[clientId] ?? [];
    if (requests.isEmpty) return null;
    
    final oldest = requests.first;
    final resetTime = oldest.add(window);
    return resetTime.difference(DateTime.now());
  }
}

// Rate limiting middleware
Middleware createRateLimit({
  required int maxRequests,
  required Duration window,
  String Function(FluxRequest)? keyGenerator,
}) {
  final limiter = RateLimiter(
    maxRequests: maxRequests,
    window: window,
  );
  
  return (request, response, next) async {
    final clientId = keyGenerator?.call(request) ?? 
        request.rawRequest.connectionInfo?.remoteAddress.address ?? 'unknown';
    
    if (!limiter.isAllowed(clientId)) {
      final resetTime = limiter.getResetTime(clientId);
      
      response.status(429)
        .header('X-RateLimit-Limit', maxRequests.toString())
        .header('X-RateLimit-Remaining', '0')
        .header('X-RateLimit-Reset', resetTime?.inSeconds.toString() ?? '0')
        .json({
          'error': 'Rate limit exceeded',
          'retryAfter': resetTime?.inSeconds,
        });
      return;
    }
    
    // Add rate limit headers
    response
      .header('X-RateLimit-Limit', maxRequests.toString())
      .header('X-RateLimit-Remaining', limiter.getRemainingRequests(clientId).toString());
    
    await next();
  };
}

void main() async {
  // Different rate limits for different endpoints
  final strictRateLimit = createRateLimit(
    maxRequests: 5,
    window: Duration(minutes: 1),
  );
  
  final normalRateLimit = createRateLimit(
    maxRequests: 100,
    window: Duration(minutes: 1),
  );
  
  // API key based rate limiting
  final apiKeyRateLimit = createRateLimit(
    maxRequests: 1000,
    window: Duration(minutes: 1),
    keyGenerator: (request) => request.headers.value('X-API-Key') ?? 'anonymous',
  );
  
  final apiRouter = Router.path('/api')
    .use(normalRateLimit)
    
    // Public endpoints with strict limits
    .get('/public/data', strictRateLimit, (request, response, pathArgs) async {
      response.json({
        'message': 'Public data - limited to 5 requests per minute',
        'timestamp': DateTime.now().toIso8601String(),
      });
    })
    
    // API key endpoints with higher limits
    .get('/premium/data', apiKeyRateLimit, (request, response, pathArgs) async {
      final apiKey = request.headers.value('X-API-Key');
      
      if (apiKey == null) {
        response.status(401).json({'error': 'API key required'});
        return;
      }
      
      response.json({
        'message': 'Premium data - 1000 requests per minute with API key',
        'apiKey': apiKey,
        'timestamp': DateTime.now().toIso8601String(),
      });
    })
    
    // No rate limit on status
    .get('/status', (request, response, pathArgs) async {
      response.json({
        'status': 'OK',
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  
  final mainRouter = Router()
    .addRouter(apiRouter)
    .get('/', (request, response, pathArgs) async {
      response.json({
        'message': 'Rate Limiting Demo',
        'endpoints': {
          'public': 'GET /api/public/data (5 req/min)',
          'premium': 'GET /api/premium/data (1000 req/min with API key)',
          'status': 'GET /api/status (no limit)',
        },
      });
    });
  
  final server = Server(InternetAddress.anyIPv4, 8080, mainRouter);
  await server.run();
  print('Rate Limiting Demo running on http://localhost:8080');
}
```

---

## 📚 Documentation Navigation

### Related Topics
- **[← Getting Started](getting-started.md)** - Your first Dart Flux application
- **[Routing Core Concepts](routing.md)** - Fundamental routing principles  
- **[Architecture Overview](architecture-overview.md)** - Pipeline system and middleware
- **[Authentication Examples →](authentication.md)** - Security implementations
- **[Advanced Patterns →](advanced-usage-patterns.md)** - Complex routing patterns

### Next Steps
- **[File Management](file-management.md)** - Handle file uploads and downloads
- **[Database Operations](database.md)** - MongoDB integration examples
- **[Best Practices](best-practices-security.md)** - Production guidelines
- **[API Reference](api-reference.md)** - Complete API documentation

---

📖 **[Back to Documentation Index](README.md)**
