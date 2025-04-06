import 'package:dart_flux/core/errors/server_error.dart';

/// A generic class to manage key-value pairs in a context.
///
/// This class allows you to store, retrieve, and remove data associated with a key.
/// It provides methods for adding, getting, and removing context data with checks for duplicate keys.
class Context<V> {
  // The internal map holding the context data.
  // Stores key-value pairs where the key is a String and the value can be any dynamic type.
  Map<String, dynamic> _data = {};

  /// Constructor to initialize the context with an optional initial data map.
  ///
  /// If no initial context is provided, it defaults to an empty map.
  /// [initContext] allows pre-populating the context with data.
  Context({Map<String, dynamic>? initContext}) : _data = initContext ?? {};

  /// A getter to return a copy of the current context data as a Map.
  ///
  /// This ensures that the internal `_data` map cannot be directly modified by the caller.
  Map<String, dynamic> get data => {..._data};

  /// Adds a new key-value pair to the context.
  ///
  /// If the key already exists and [replace] is false, a [ServerError] will be thrown.
  /// If [replace] is true, the existing value for the key will be replaced.
  ///
  /// [key] - The key under which the value will be stored.
  /// [value] - The value to be associated with the key.
  /// [replace] - Determines whether to replace an existing value for the key. Defaults to false.
  void add(String key, dynamic value, {bool replace = false}) {
    if (_data.containsKey(key) && !replace) {
      // Prevent adding duplicate keys unless explicitly allowed.
      throw ServerError('context already has this key: $key');
    }

    // Add or update the context with the new key-value pair.
    _data[key] = value;
  }

  /// Retrieves the value associated with the given key from the context.
  ///
  /// [key] - The key whose value you want to retrieve.
  /// Returns the value associated with the key, or null if the key does not exist.
  dynamic get(String key) {
    // Retrieve the value from the context map using the provided key.
    var v = _data[key];
    return v;
  }

  /// Removes the key-value pair associated with the provided key.
  ///
  /// [key] - The key to remove from the context.
  /// Returns the value that was associated with the key, or null if the key was not found.
  V? remove(String key) {
    // Remove the entry for the given key from the context and return its value.
    return _data.remove(key);
  }
}
