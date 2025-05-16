import 'package:dart_flux/core/misc/cache/cache_item.dart';

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() {
    return _instance;
  }
  CacheManager._internal();
  static CacheManager get instance => _instance;

  final Map<String, CacheItem> _cache = {};
  void setItem<T>(
    String key,
    T value, {
    Duration expiration = const Duration(hours: 1),
  }) {
    _cache[key] = CacheItem(key: key, value: value, expiration: expiration);
  }

  T? getItem<T>(String key) {
    final item = _cache[key];
    if (item == null || item.isExpired) {
      _cache.remove(key);
      return null;
    }
    return item.value as T;
  }

  void removeItem(String key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  bool containsKey(String key) {
    return _cache.containsKey(key) && !_cache[key]!.isExpired;
  }

  int get length {
    return _cache.values.where((item) => !item.isExpired).length;
  }

  List<String> get keys {
    return _cache.keys.where((key) => !_cache[key]!.isExpired).toList();
  }

  List<CacheItem> get items {
    return _cache.values.where((item) => !item.isExpired).toList();
  }

  Duration? getRemainingTTL(String key) {
    final item = _cache[key];
    if (item == null || item.isExpired) return null;
    return item.expiration - DateTime.now().difference(item.creationTime);
  }
}
