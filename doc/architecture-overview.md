# Architecture Overview

Dart Flux is built around a pipeline-based request processing architecture that provides flexible middleware composition and clean separation of concerns. This document explains the core architectural concepts and design patterns.

> 📖 **Related Documentation:**
> - [Getting Started](getting-started.md) - Basic concepts in practice
> - [Routing](routing.md) - Router implementation details
> - [Advanced Usage Patterns](advanced-usage-patterns.md) - Complex architectural patterns
> - [API Reference](api-reference.md) - Technical API details
> - [Best Practices](best-practices-security.md) - Architectural best practices

## Table of Contents

- [Core Architecture](#core-architecture)
- [Pipeline System](#pipeline-system)
- [Request Lifecycle](#request-lifecycle)
- [Middleware Composition](#middleware-composition)
- [Router Hierarchy](#router-hierarchy)
- [Entity Processing](#entity-processing)
- [Error Handling Flow](#error-handling-flow)

## Core Architecture

Dart Flux follows a layered architecture with the following key components:

```
┌─────────────────────────────────────────────┐
│                Server Layer                 │
│  - HTTP Server Management                   │
│  - Request/Response Coordination            │
│  - Logging and Error Handling              │
└─────────────────────────────────────────────┘
                       │
┌─────────────────────────────────────────────┐
│               Pipeline Layer                │
│  - Middleware Execution                     │
│  - Request Processing Flow                  │
│  - Entity Coordination                      │
└─────────────────────────────────────────────┘
                       │
┌─────────────────────────────────────────────┐
│               Routing Layer                 │
│  - Path Matching                            │
│  - HTTP Method Routing                      │
│  - Handler Discovery                        │
└─────────────────────────────────────────────┘
                       │
┌─────────────────────────────────────────────┐
│              Handler Layer                  │
│  - Business Logic Execution                 │
│  - Request/Response Processing              │
│  - Authentication and Authorization         │
└─────────────────────────────────────────────┘
```

## Pipeline System

The heart of Dart Flux is its pipeline system, which processes requests through multiple layers of middleware and handlers in a predictable order.

### Pipeline Structure

Each router maintains three distinct pipelines:

1. **Upper Pipeline** (`List<Middleware>`)
   - Executes before any handler processing
   - Ideal for authentication, logging, request parsing
   - Can modify the request or return early responses

2. **Main Pipeline** (`List<RequestProcessor>`)
   - Contains handlers, middleware, and nested routers
   - Where the core business logic resides
   - Processes the actual request and generates responses

3. **Lower Pipeline** (`List<LowerMiddleware>`)
   - Executes after handler processing
   - Used for cleanup, logging, response modification
   - Cannot return early responses (void return type)

### Pipeline Execution Order

```
System Upper Middlewares (Framework Level)
    ↓
Server Upper Middlewares (Application Level)
    ↓
Router Upper Pipeline
    ↓
Router Main Pipeline
    ├── Middleware
    ├── Handlers
    └── Nested Routers
    ↓
Router Lower Pipeline
    ↓
Server Lower Middlewares (Application Level)
    ↓
System Lower Middlewares (Framework Level)
```

## Request Lifecycle

Understanding the complete request lifecycle is crucial for effective middleware and handler design:

### 1. Request Reception

```dart
// Server receives HTTP request
HttpRequest httpRequest = // incoming request

// Wrapped in FluxRequest for enhanced functionality
FluxRequest request = FluxRequest(httpRequest);
FluxResponse response = request.response;
```

### 2. Path and Method Extraction

```dart
String path = request.uri.path;        // e.g., "/api/users/123"
HttpMethod method = request.method;     // e.g., HttpMethod.get
```

### 3. Entity Discovery

The system finds all entities (middlewares, handlers, routers) that match the request:

```dart
List<RoutingEntity> entities = requestProcessor.processors(path, method);
```

### 4. Pipeline Execution

The `PipelineRunner` orchestrates the execution:

```dart
await PipelineRunner(
  systemUpper: systemUpperMiddlewares,
  systemLower: systemLowerMiddlewares,
  upperMiddlewares: serverUpperMiddlewares,
  lowerMiddlewares: serverLowerMiddlewares,
  entities: matchingEntities,
  // ... other parameters
).run();
```

### 5. Response Delivery

The final response is sent back to the client with appropriate headers and status codes.

## Middleware Composition

Middleware in Dart Flux can be composed at multiple levels, providing fine-grained control over request processing.

### Server-Level Middleware

Applied to all requests handled by the server:

```dart
Server server = Server(
  InternetAddress.anyIPv4,
  3000,
  router,
  upperMiddlewares: [authMiddleware, corsMiddleware],
  lowerMiddlewares: [loggingMiddleware, cleanupMiddleware],
);
```

### Router-Level Middleware

Applied to all routes within a specific router:

```dart
Router apiRouter = Router()
  .upper(authenticationMiddleware)  // Runs before all handlers
  .middleware(validationMiddleware) // Runs with handlers
  .lower(auditMiddleware);          // Runs after all handlers
```

### Handler-Level Middleware

Applied only to specific handlers:

```dart
Handler userHandler = Handler('users/:id', HttpMethod.get, getUserHandler)
  .middleware(userValidationMiddleware)
  .lower(userAuditMiddleware);
```

### Middleware Types and Return Values

1. **Upper/Regular Middleware** (`Processor`)
   ```dart
   typedef Processor = FutureOr<HttpEntity> Function(
     FluxRequest request,
     FluxResponse response,
     Map<String, dynamic> pathArgs,
   );
   ```
   - Can return `FluxRequest` to continue processing
   - Can return `FluxResponse` to end processing early

2. **Lower Middleware** (`LowerProcessor`)
   ```dart
   typedef LowerProcessor = FutureOr<void> Function(
     FluxRequest request,
     FluxResponse response,
     Map<String, dynamic> pathArgs,
   );
   ```
   - Cannot return early responses
   - Used for cleanup and post-processing

## Router Hierarchy

Dart Flux supports nested router structures, allowing for modular application design:

### Hierarchical Routing

```dart
// Main application router
Router appRouter = Router()
  .router(apiRouter)      // /api/*
  .router(adminRouter)    // /admin/*
  .router(publicRouter);  // /*

// API router with versioning
Router apiRouter = Router.path('api')
  .router(v1Router)       // /api/v1/*
  .router(v2Router);      // /api/v2/*

// Resource-specific routers
Router v1Router = Router.path('v1')
  .router(usersRouter)    // /api/v1/users/*
  .router(postsRouter);   // /api/v1/posts/*
```

### Path Resolution

Router paths are resolved hierarchically:

```
Request: GET /api/v1/users/123

Resolution:
appRouter (/)
  └── apiRouter (/api)
      └── v1Router (/api/v1)
          └── usersRouter (/api/v1/users)
              └── userHandler (/api/v1/users/:id)
```

## Entity Processing

### Entity Types

1. **Handler**: Processes specific HTTP methods and paths
2. **Middleware**: Processes requests/responses with optional path matching
3. **Router**: Contains other entities and provides nested routing
4. **LowerMiddleware**: Post-processing middleware

### Entity Matching

Entities are matched based on:

1. **Path Matching**: Using path templates with parameter support
2. **HTTP Method**: Exact method matching
3. **Priority**: Order of registration and specificity

### Path Parameters

Dynamic path segments are extracted and passed to handlers:

```dart
// Path template: /users/:userId/posts/:postId
// Request path: /users/123/posts/456
// pathArgs: {'userId': '123', 'postId': '456'}

Handler handler = Handler('users/:userId/posts/:postId', HttpMethod.get,
  (request, response, pathArgs) {
    String userId = pathArgs['userId'];
    String postId = pathArgs['postId'];
    // ... process request
  }
);
```

## Error Handling Flow

Dart Flux provides comprehensive error handling at multiple levels:

### Pipeline Error Handling

```dart
try {
  // Execute middleware and handlers
  response = await processRequest();
} catch (error, stackTrace) {
  // Log error details
  logger?.rawLog(error);
  logger?.rawLog(stackTrace);
  
  // Generate error response
  response = await SendResponse.error(response, error);
}
```

### 404 Handling

When no handler matches a request:

1. Check for wrong HTTP method (405 Method Not Allowed)
2. Find similar paths for suggestions
3. Call custom `onNotFound` handler if provided
4. Return default 404 response

### Error Response Generation

```dart
// Automatic error response generation
FluxResponse errorResponse = await SendResponse.error(response, exception);

// Custom error handling
if (onNotFound != null) {
  return await onNotFound(request, response, {});
}
```

## Key Design Principles

### 1. Composability
- Middleware can be composed at multiple levels
- Routers can be nested arbitrarily deep
- Handlers can have their own middleware chains

### 2. Predictable Execution Order
- Clear pipeline execution sequence
- Documented middleware lifecycle
- Consistent parameter passing

### 3. Flexibility
- Multiple ways to achieve the same functionality
- Optional components (logging, authentication, etc.)
- Extensible through custom middleware

### 4. Performance
- Efficient path matching algorithms
- Minimal overhead in request processing
- Lazy evaluation where possible

### 5. Developer Experience
- Clear separation of concerns
- Intuitive API design
- Comprehensive error messages

## Best Practices

### 1. Middleware Organization
- Keep middleware focused on single responsibilities
- Use upper middleware for request preprocessing
- Use lower middleware for response postprocessing

### 2. Router Structure
- Group related functionality in dedicated routers
- Use meaningful path prefixes
- Implement proper error boundaries

### 3. Error Handling
- Implement custom error handlers for better user experience
- Log errors appropriately for debugging
- Provide meaningful error messages

### 4. Performance Optimization
- Order middleware by execution frequency
- Cache expensive operations where appropriate
- Use appropriate HTTP status codes

This architecture enables building scalable, maintainable backend applications with clear separation of concerns and flexible request processing capabilities.

---

## 📚 Documentation Navigation

### Implementation Guides
- **[← Getting Started](getting-started.md)** - See architecture in practice
- **[Routing Examples →](routing_examples.md)** - Pipeline and middleware examples
- **[Advanced Usage Patterns →](advanced-usage-patterns.md)** - Complex architectural patterns

### Core Features
- **[Authentication](authentication.md)** - Security layer architecture
- **[Database Operations](database.md)** - Data layer integration
- **[File Management](file-management.md)** - File processing pipeline
- **[Error Handling](error-handling.md)** - Error flow patterns

### Production Guidance
- **[Best Practices & Security](best-practices-security.md)** - Architectural best practices
- **[Server Setup](server-setup.md)** - Production deployment architecture
- **[Troubleshooting](troubleshooting-guide.md)** - Architecture-related issues

### Reference
- **[API Reference](api-reference.md)** - Technical implementation details

---

📖 **[Back to Documentation Index](README.md)**
