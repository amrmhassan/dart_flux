// Represents a cache eviction event
class EvictionEvent {
  /// The type of cache from which the item was evicted
  final String cacheType;

  /// The key of the evicted item
  final String key;

  /// The reason for eviction
  final EvictionReason reason;

  EvictionEvent({
    required this.cacheType,
    required this.key,
    required this.reason,
  });
}

/// The reason an item was evicted from the cache
enum EvictionReason {
  /// Evicted due to expiration
  expired,

  /// Evicted due to cache size limit
  sizeLimitReached,

  /// Evicted due to manual removal
  manualRemoval,

  /// Evicted due to cache clear
  cacheClear,
}
