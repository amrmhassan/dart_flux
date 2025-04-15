import 'package:dart_flux/core/auth/authenticator/repo/flux_auth_hashing.dart';
import 'measure_time.dart';

void main(List<String> args) async {
  measureTime(() async {
    FluxAuthHashing hashing = FluxAuthHashing();
    var hashed = await hashing.hash('this is my password');
    print(hashed);
  });
}
