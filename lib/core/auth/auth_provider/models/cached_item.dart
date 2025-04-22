// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:dart_flux/constants/date_constants.dart';

class CachedItem<T> {
  final T value;
  DateTime? _expiresAt;

  CachedItem(this.value, {Duration? expiresAfter}) {
    if (expiresAfter != null) {
      _expiresAt = utc.add(expiresAfter);
    }
  }
  bool get isExpired => _expiresAt != null && utc.isAfter(_expiresAt!);
}
