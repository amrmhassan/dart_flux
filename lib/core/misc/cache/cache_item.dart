class CacheItem<T> {
  final String key;
  final T value;
  final Duration expiration;
  late DateTime _createdAt;

  CacheItem({
    required this.key,
    required this.value,
    required this.expiration,
  }) {
    _createdAt = DateTime.now();
  }

  bool get isExpired {
    final now = DateTime.now();
    return now.isAfter(_createdAt.add(expiration));
  }

  DateTime get creationTime => _createdAt;
}
