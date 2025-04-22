import 'package:dart_flux/core/auth/auth_provider/repo/flux_memory_auth_cache.dart';
import 'package:dart_flux/core/auth/auth_provider/repo/mongo/mongo_auth_provider.dart';
import 'package:dart_flux/core/auth/authenticator/repo/flux_auth_hashing.dart';
import 'package:dart_flux/core/auth/authenticator/repo/flux_authenticator.dart';
import 'package:dart_flux/core/auth/authenticator/repo/flux_jwt_controller.dart';
import 'package:dart_flux/dart_flux.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

void main(List<String> args) async {
  var mongoDbConnection = MongoDbConnection('mongodb://localhost:27017/flux');
  await mongoDbConnection.connect();
  FluxAuthenticator authenticator = FluxAuthenticator(
    jwtController: FluxJwtController(jwtKey: SecretKey('jwtKey')),
    authProvider: MongoAuthProvider(
      mongoDbConnection,
      cache: FluxMemoryAuthCache(),
    ),
    hashing: FluxAuthHashing(),
  );
  var tokens = await authenticator.login('amr@gmail.com', 'password');
  print(tokens.toJson());
}
