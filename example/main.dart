import 'package:dart_flux/core/misc/cache/cache_manager.dart';

void main(List<String> args) async {
  var value = CacheManager.instance.getItem<String>('user');
  print(value);
}
