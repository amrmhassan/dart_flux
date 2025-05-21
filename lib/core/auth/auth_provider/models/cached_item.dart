// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:dart_flux/constants/date_constants.dart';

/// A generic class representing an item in the cache
class CachedItem<T> {
  /// The value stored in the cache
  final T value;

  /// When the item expires (if null, it never expires)
  DateTime? _expiresAt;

  /// When the item was created
  final DateTime createdAt;

  /// When the item was last accessed
  DateTime lastAccessed;

  /// Create a new cached item
  ///
  /// [value] The value to cache
  /// [expiresAfter] Optional duration after which this item should expire
  CachedItem(this.value, {Duration? expiresAfter})
    : createdAt = utc,
      lastAccessed = utc {
    if (expiresAfter != null) {
      _expiresAt = utc.add(expiresAfter);
    }
  }

  /// Whether this item has expired
  bool get isExpired => _expiresAt != null && utc.isAfter(_expiresAt!);

  /// When this item expires (null if it never expires)
  DateTime? get expiresAt => _expiresAt;

  /// Mark this item as accessed, updating the lastAccessed timestamp
  void touch() {
    lastAccessed = utc;
  }

  /// Extend the expiration time by the given duration from now
  void extendExpiration(Duration duration) {
    _expiresAt = utc.add(duration);
  }
}
