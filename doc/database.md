# Database Operations

This guide explains how to perform database operations using Dart Flux's database integration capabilities.

## Overview

Dart Flux provides built-in support for MongoDB, with an abstraction layer that makes it easy to work with database connections, collections, and documents.

## MongoDB Integration

### Setting Up a Connection

```dart
import 'package:dart_flux/dart_flux.dart';

void main() async {
  // Create a MongoDB connection
  final dbConnection = MongoDbConnection(
    'mongodb://localhost:27017/my_database',
    loggerEnabled: true,
  );
  
  // Connect to the database
  await dbConnection.connect();
  
  // Check if connected
  if (dbConnection.connected) {
    print('Connected to database');
  }
  
  // Create a server with the database
  final router = Router()
    // ...define routes
  
  final server = Server(InternetAddress.anyIPv4, 3000, router);
  await server.run();
}
```

### Working with Collections

```dart
// Get a reference to a collection
final usersCollection = dbConnection.collection('users');

// Create an API for users
Router usersRouter = Router.path('users')
  .get('/', (req, res, pathArgs) async {
    // Get all users
    final users = await usersCollection.getAll();
    return res.json(users);
  })
  .get('/:id', (req, res, pathArgs) async {
    final id = pathArgs['id'];
    // Get a specific user by ID
    final user = await usersCollection.doc(id).get();
    
    if (user == null) {
      return res.status(404).json({'error': 'User not found'});
    }
    
    return res.json(user);
  })
  .post('/', (req, res, pathArgs) async {
    // Create a new user
    final userData = req.body;
    final newUser = await usersCollection.add(userData);
    
    return res.status(201).json(newUser);
  })
  .put('/:id', (req, res, pathArgs) async {
    final id = pathArgs['id'];
    final userData = req.body;
    
    // Update an existing user
    final updated = await usersCollection.doc(id).update(userData);
    
    if (updated) {
      return res.json({'message': 'User updated'});
    } else {
      return res.status(404).json({'error': 'User not found'});
    }
  })
  .delete('/:id', (req, res, pathArgs) async {
    final id = pathArgs['id'];
    
    // Delete a user
    final deleted = await usersCollection.doc(id).delete();
    
    if (deleted) {
      return res.json({'message': 'User deleted'});
    } else {
      return res.status(404).json({'error': 'User not found'});
    }
  });
```

## CRUD Operations

### Creating Documents

```dart
// Add a document with auto-generated ID
final newDoc = await collection.add({
  'name': 'John Doe',
  'email': 'john@example.com',
  'age': 30,
});

// Get the ID of the new document
final id = newDoc['_id'];

// Add a document with a specific ID
await collection.doc('custom-id').set({
  'name': 'Jane Doe',
  'email': 'jane@example.com',
  'age': 25,
});
```

### Reading Documents

```dart
// Get a document by ID
final doc = await collection.doc(id).get();

// Get all documents in a collection
final allDocs = await collection.getAll();

// Get documents with a query
final filteredDocs = await collection.find({
  'age': {'$gt': 25},
});

// Get a single document with a query
final singleDoc = await collection.findOne({
  'email': 'john@example.com',
});
```

### Updating Documents

```dart
// Update a document by ID
await collection.doc(id).update({
  'age': 31,
  'lastUpdated': DateTime.now().toIso8601String(),
});

// Update multiple documents
await collection.updateMany(
  {'age': {'$lt': 30}},
  {'$set': {'category': 'young'}},
);
```

### Deleting Documents

```dart
// Delete a document by ID
await collection.doc(id).delete();

// Delete multiple documents
await collection.deleteMany({
  'age': {'$lt': 20},
});
```

## Advanced Queries

### Sorting

```dart
// Get documents sorted by age in ascending order
final sortedDocs = await collection.find(
  {},
  sort: {'age': 1},
);

// Get documents sorted by age in descending order
final sortedDocs = await collection.find(
  {},
  sort: {'age': -1},
);
```

### Limiting Results

```dart
// Get first 10 documents
final limitedDocs = await collection.find(
  {},
  limit: 10,
);
```

### Skipping Results

```dart
// Skip first 20 documents (for pagination)
final skippedDocs = await collection.find(
  {},
  skip: 20,
  limit: 10,
);
```

### Projections

```dart
// Get only specific fields
final projectedDocs = await collection.find(
  {},
  projection: {'name': 1, 'email': 1, '_id': 0},
);
```

## Transactions

For operations that need to be atomic:

```dart
// Start a session
final session = await dbConnection.db.startSession();

try {
  // Start a transaction
  await session.startTransaction();
  
  // Perform operations
  await collection.doc('user1').update({'balance': 500}, session: session);
  await collection.doc('user2').update({'balance': 1500}, session: session);
  
  // Commit the transaction
  await session.commitTransaction();
} catch (e) {
  // If an error occurs, abort the transaction
  await session.abortTransaction();
  throw e;
} finally {
  // End the session
  await session.close();
}
```

## Connection Management

### Connection Pooling

MongoDB's Dart driver handles connection pooling automatically. You can customize the pool size:

```dart
final dbConnection = MongoDbConnection(
  'mongodb://localhost:27017/my_database?maxPoolSize=20',
  loggerEnabled: true,
);
```

### Handling Connection Failures

```dart
try {
  await dbConnection.connect();
} catch (e) {
  print('Failed to connect to database: $e');
  // Implement retry logic or graceful fallback
}

// Later, before operations, check if connected
if (!dbConnection.connected) {
  try {
    await dbConnection.fixConnection();
  } catch (e) {
    // Handle persistent connection failure
  }
}
```

## Data Models

For better type safety, create model classes for your data:

```dart
class User {
  final String id;
  final String name;
  final String email;
  final int age;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
  });
  
  // Convert from database document
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['_id'].toString(),
      name: map['name'] as String,
      email: map['email'] as String,
      age: map['age'] as int,
    );
  }
  
  // Convert to database document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'age': age,
    };
  }
}

// Usage
final userDoc = await collection.doc(id).get();
final user = User.fromMap(userDoc);

// Update user
await collection.doc(user.id).update({
  'age': user.age + 1,
});
```

## Repository Pattern

Implement the repository pattern for cleaner code:

```dart
class UserRepository {
  final CollRefMongo collection;
  
  UserRepository(MongoDbConnection dbConnection)
      : collection = dbConnection.collection('users');
  
  // Create
  Future<User> create(User user) async {
    final doc = await collection.add(user.toMap());
    return User.fromMap(doc);
  }
  
  // Read
  Future<User?> getById(String id) async {
    final doc = await collection.doc(id).get();
    if (doc == null) return null;
    return User.fromMap(doc);
  }
  
  Future<List<User>> getAll() async {
    final docs = await collection.getAll();
    return docs.map((doc) => User.fromMap(doc)).toList();
  }
  
  // Update
  Future<bool> update(String id, User user) async {
    return await collection.doc(id).update(user.toMap());
  }
  
  // Delete
  Future<bool> delete(String id) async {
    return await collection.doc(id).delete();
  }
  
  // Custom query
  Future<List<User>> getByAgeRange(int min, int max) async {
    final docs = await collection.find({
      'age': {
        '$gte': min,
        '$lte': max,
      },
    });
    return docs.map((doc) => User.fromMap(doc)).toList();
  }
}
```

## Database Configuration

For production environments, consider these configuration parameters:

```dart
final dbConnection = MongoDbConnection(
  'mongodb+srv://username:password@cluster.mongodb.net/my_database?retryWrites=true&w=majority&maxPoolSize=20&connectTimeoutMS=10000',
  loggerEnabled: true,
);
```

Key parameters:
- `retryWrites`: Auto-retry failed write operations
- `w=majority`: Ensures writes are acknowledged by a majority of replicas
- `maxPoolSize`: Maximum connection pool size
- `connectTimeoutMS`: Connection timeout in milliseconds

## Security Best Practices

1. **Use Environment Variables**: Never hardcode database credentials in your code:

```dart
final dbConnection = MongoDbConnection(
  Platform.environment['MONGODB_URI'] ?? 'mongodb://localhost:27017/my_database',
  loggerEnabled: true,
);
```

2. **Input Validation**: Always validate data before storing it in the database

3. **Index Creation**: Create proper indexes for performance:

```dart
// Create indexes when setting up your database
await dbConnection.collection('users').createIndex(
  keys: {'email': 1},
  unique: true,
);
```

4. **Sanitize Queries**: Be careful with user-provided query parameters to prevent injection attacks
