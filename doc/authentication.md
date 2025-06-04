# Authentication

This guide explains how to implement authentication in your Dart Flux application.

> 📖 **Related Documentation:**
> - [Getting Started](getting-started.md) - Basic application setup
> - [Routing Examples](routing_examples.md) - Authentication examples in action
> - [Best Practices & Security](best-practices-security.md) - Security guidelines
> - [Advanced Patterns](advanced-usage-patterns.md) - Custom authentication flows
> - [API Reference](api-reference.md) - Authentication API details

## Overview

Dart Flux provides a flexible authentication system with support for:

- JWT (JSON Web Tokens)
- Custom authentication providers
- Auth caching
- Session management

## Basic JWT Authentication

### Setting Up Authentication

```dart
import 'package:dart_flux/dart_flux.dart';

void main() async {
  // Create JWT authenticator with secret key
  final jwtAuth = JwtAuthenticator(
    accessTokenSecret: 'your-access-token-secret',
    refreshTokenSecret: 'your-refresh-token-secret',
    accessTokenExpiry: Duration(hours: 1),
    refreshTokenExpiry: Duration(days: 7),
  );
  
  // Create auth router
  final authRouter = Router.path('auth')
    .post('login', (req, res, pathArgs) async {
      // Get credentials from request body
      final email = req.body['email'];
      final password = req.body['password'];
      
      // Validate credentials (implement your own logic)
      if (await validateCredentials(email, password)) {
        // Generate tokens
        final tokens = await jwtAuth.createTokens({
          'userId': '12345',
          'email': email,
          'role': 'user',
        });
        
        return res.json({
          'accessToken': tokens.accessToken,
          'refreshToken': tokens.refreshToken,
        });
      }
      
      return res.status(401).json({
        'error': 'Invalid credentials',
      });
    })
    .post('refresh', (req, res, pathArgs) async {
      final refreshToken = req.body['refreshToken'];
      
      try {
        // Verify and refresh tokens
        final tokens = await jwtAuth.refreshTokens(refreshToken);
        
        return res.json({
          'accessToken': tokens.accessToken,
          'refreshToken': tokens.refreshToken,
        });
      } catch (e) {
        return res.status(401).json({
          'error': 'Invalid or expired refresh token',
        });
      }
    });
  
  // Create protected router with auth middleware
  final protectedRouter = Router.path('api')
    .use((req, res, next) async {
      final authHeader = req.headers.value('Authorization');
      
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({
          'error': 'Authorization header missing or invalid',
        });
      }
      
      final token = authHeader.substring(7); // Remove 'Bearer ' prefix
      
      try {
        // Verify token
        final payload = await jwtAuth.verifyAccessToken(token);
        
        // Add user info to request for later use
        req.context['user'] = payload;
        
        return next();
      } catch (e) {
        return res.status(401).json({
          'error': 'Invalid or expired token',
        });
      }
    })
    .get('profile', (req, res, pathArgs) {
      // Access user info from the verified token
      final user = req.context['user'];
      
      return res.json({
        'userId': user['userId'],
        'email': user['email'],
        'role': user['role'],
      });
    });
  
  // Set up server with both routers
  final router = Router()
    .addRouter(authRouter)
    .addRouter(protectedRouter);
  
  final server = Server(InternetAddress.anyIPv4, 3000, router);
  await server.run();
}

// Implement your credential validation logic
Future<bool> validateCredentials(String email, String password) async {
  // In a real app, check against database
  return email == 'user@example.com' && password == 'password';
}
```

## Auth Cache

Use the auth cache to improve performance by reducing database queries:

```dart
// Create memory-based auth cache
final authCache = FluxMemoryAuthCache(
  allowCache: true,                           // Enable caching
  cacheDuration: Duration(minutes: 15),       // Set item expiration time
  clearCacheEvery: Duration(hours: 1),        // Periodically clear all cache
  maxEntries: 5000,                           // Limit cache entries
  enableLruBehavior: true,                    // Enable LRU (Least Recently Used) behavior
);

// Create auth provider with cache
final authProvider = FluxAuthProvider(
  cache: authCache,
  // Implement these methods based on your data storage
  getUserById: (id) async => getUserFromDatabase(id),
  getUserAuthById: (id) async => getUserAuthFromDatabase(id),
  getUserIdByEmail: (email) async => getUserIdFromDatabaseByEmail(email),
);

// Create authenticator with auth provider
final authenticator = FluxAuthenticator(
  authProvider: authProvider,
  accessTokenSecret: 'your-access-token-secret',
  refreshTokenSecret: 'your-refresh-token-secret',
);
```

### Cache Features

#### Efficient Size Management

FluxMemoryAuthCache includes efficient cache size management to prevent excessive memory usage without impacting performance:

```dart
final authCache = FluxMemoryAuthCache(
  allowCache: true,
  cacheDuration: Duration(minutes: 15),
  maxEntries: 5000, // Limit each cache map to 5000 entries
);
```

The `maxEntries` parameter limits the number of entries in each cache collection:

#### LRU Cache Behavior

Enable true LRU (Least Recently Used) eviction policy to keep frequently used items in cache longer:

```dart
final authCache = FluxMemoryAuthCache(
  enableLruBehavior: true, // Moves accessed items to end of queue
  // Other options...
);
```

#### Cache Eviction Events

Listen for cache eviction events to monitor cache behavior and perform custom actions:

```dart
// Subscribe to eviction events
authCache.onEviction.listen((event) {
  print('Item evicted: ${event.key} from ${event.cacheType} due to ${event.reason}');
  
  // Perform custom actions based on eviction events
  if (event.reason == EvictionReason.expired) {
    // Handle expired item
  } else if (event.reason == EvictionReason.sizeLimitReached) {
    // Handle size-based eviction
  }
});
```

#### Resource Management

Properly dispose cache resources when no longer needed:

```dart
// When shutting down your application or when cache is no longer needed
authCache.dispose();
```
- User cache
- Authentication cache
- Access token cache
- Refresh token cache
- Email-to-ID mapping cache

When a cache reaches its size limit, the oldest entries (based on insertion order) are automatically removed when new entries are added. This is implemented using an efficient queue-based approach with O(1) insertion and O(k) removal (where k is only the number of entries to remove), keeping the cache operation time complexity constant regardless of cache size.

## User Registration

Implement user registration with password hashing:

```dart
Router.path('auth')
  .post('register', (req, res, pathArgs) async {
    final email = req.body['email'];
    final password = req.body['password'];
    final name = req.body['name'];
    
    // Check if user already exists
    if (await userExists(email)) {
      return res.status(409).json({
        'error': 'User already exists',
      });
    }
    
    // Hash password
    final hashedPassword = await FluxAuthenticator.hashPassword(password);
    
    // Create user
    final userId = await createUser({
      'email': email,
      'name': name,
      'hashedPassword': hashedPassword,
    });
    
    return res.status(201).json({
      'message': 'User created successfully',
      'userId': userId,
    });
  });
```

## Role-Based Access Control

Implement role-based access control with middleware:

```dart
// Middleware to check user role
Middleware checkRole(String requiredRole) {
  return (req, res, next) {
    final user = req.context['user'];
    
    if (user == null || user['role'] != requiredRole) {
      return res.status(403).json({
        'error': 'Forbidden',
        'message': 'Insufficient permissions',
      });
    }
    
    return next();
  };
}

// Apply role-based middleware to specific routes
Router.path('admin')
  .use(authMiddleware) // First verify authentication
  .use(checkRole('admin')) // Then check role
  .get('dashboard', (req, res, pathArgs) {
    return res.json({
      'message': 'Admin dashboard data',
    });
  });
```

## Password Reset Flow

Implement a password reset flow:

```dart
Router.path('auth')
  .post('forgot-password', (req, res, pathArgs) async {
    final email = req.body['email'];
    
    // Generate reset token
    final resetToken = generateRandomToken();
    const expiryTime = Duration(hours: 1);
    
    // Store token with expiry time
    await storeResetToken(email, resetToken, expiryTime);
    
    // In a real app, send email with reset link
    // sendResetEmail(email, resetToken);
    
    return res.json({
      'message': 'Password reset instructions sent',
    });
  })
  .post('reset-password', (req, res, pathArgs) async {
    final email = req.body['email'];
    final resetToken = req.body['token'];
    final newPassword = req.body['newPassword'];
    
    // Verify token
    if (!await isValidResetToken(email, resetToken)) {
      return res.status(400).json({
        'error': 'Invalid or expired reset token',
      });
    }
    
    // Hash new password
    final hashedPassword = await FluxAuthenticator.hashPassword(newPassword);
    
    // Update password
    await updateUserPassword(email, hashedPassword);
    
    // Invalidate token
    await invalidateResetToken(email, resetToken);
    
    return res.json({
      'message': 'Password updated successfully',
    });
  });
```

## Social Authentication

For OAuth with third-party providers:

```dart
Router.path('auth')
  .get('google', (req, res, pathArgs) {
    // Redirect to Google OAuth
    final authUrl = 'https://accounts.google.com/o/oauth2/auth?'
        'client_id=YOUR_CLIENT_ID'
        '&redirect_uri=http://localhost:3000/auth/google/callback'
        '&response_type=code'
        '&scope=email profile';
    
    return res.redirect(authUrl);
  })
  .get('google/callback', (req, res, pathArgs) async {
    final code = req.url.queryParameters['code'];
    
    // Exchange code for tokens
    // final tokens = await exchangeCodeForTokens(code);
    
    // Get user info from Google
    // final googleUser = await getGoogleUserInfo(tokens['access_token']);
    
    // Find or create user in your system
    // final userId = await findOrCreateUser(googleUser);
    
    // Generate JWT tokens
    // final jwtTokens = await authenticator.createTokens({'userId': userId});
    
    // In a real app, redirect with tokens or set cookies
    return res.json({
      'message': 'Google authentication successful',
      // 'accessToken': jwtTokens.accessToken,
      // 'refreshToken': jwtTokens.refreshToken,
    });
  });
```

## Logout

Implement logout functionality:

```dart
Router.path('auth')
  .post('logout', authMiddleware, (req, res, pathArgs) async {
    final refreshToken = req.body['refreshToken'];
    
    // Add token to blacklist
    await blacklistToken(refreshToken);
    
    return res.json({
      'message': 'Logged out successfully',
    });
  });
```

## Security Considerations

1. **Use HTTPS**: Always use HTTPS in production to protect tokens and credentials.

2. **Token Storage**: Store tokens securely:
   - Access tokens: Short-lived, can be stored in memory
   - Refresh tokens: Store securely with HttpOnly cookies

3. **Token Validation**: Always validate tokens on the server side for each request.

4. **Password Hashing**: Use strong password hashing (Dart Flux uses Argon2).

5. **Rate Limiting**: Implement rate limiting for login attempts.

6. **Token Revocation**: Implement a token blacklist for logout and security incidents.

7. **CORS**: Configure proper CORS headers to prevent unauthorized cross-origin requests.

---

## 📚 Documentation Navigation

### Related Topics
- **[← Routing Examples](routing_examples.md)** - See authentication in action
- **[Best Practices & Security →](best-practices-security.md)** - Security guidelines
- **[Advanced Patterns →](advanced-usage-patterns.md)** - Custom authentication flows
- **[Database Operations](database.md)** - Store user data securely

### Implementation Examples
- **[Routing Examples](routing_examples.md#authentication--authorization)** - Complete auth examples
- **[Integration Guides](integration-guides.md)** - OAuth2, SAML, and external providers
- **[File Management](file-management.md)** - Secure file access control

### Reference
- **[API Reference](api-reference.md)** - Authentication API details
- **[Troubleshooting](troubleshooting-guide.md#authentication-issues)** - Common auth problems

---

📖 **[Back to Documentation Index](README.md)**
