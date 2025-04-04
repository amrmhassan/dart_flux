import 'package:dart_flux/core/errors/server_error.dart';

class Context<V> {
  Context({Map<String, dynamic>? initContext}) : _data = initContext ?? {};
  Map<String, dynamic> _data = {};
  Map<String, dynamic> get data => {..._data};

  void add(String key, dynamic value, {bool replace = false}) {
    if (_data.containsKey(key) && !replace) {
      throw ServerError('context already has this key: $key');
    }

    _data[key] = value;
  }

  dynamic get(String key) {
    var v = _data[key];
    return v;
  }

  V? remove(String key) {
    return _data.remove(key);
  }
}
