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
    authProvider: MongoAuthProvider(mongoDbConnection),
    hashing: FluxAuthHashing(),
  );
  String access =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiIxNzQ1MzQ3MzIyODY4NjMwLWhxb0dITjhkVDBzSTVCcldVWG9UIiwiaXNzdWVkQXQiOiIyMDI1LTA0LTIzVDE3OjUyOjIzLjc2NTI5MFoiLCJ0eXBlIjoiYWNjZXNzIiwiZXhwaXJlc0FmdGVyIjpudWxsLCJpYXQiOjE3NDU0MzA3NDMsImlzcyI6IkRhcnQgRmx1eCJ9.8kkdhl--NxjfuaIMQBiLeEKPY0QuJkuejsAsjpetFzg';
  String refresh =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiIxNzQ1MzQ3MzIyODY4NjMwLWhxb0dITjhkVDBzSTVCcldVWG9UIiwiaXNzdWVkQXQiOiIyMDI1LTA0LTIzVDE3OjUyOjIzLjc3OTI5MFoiLCJ0eXBlIjoicmVmcmVzaCIsImV4cGlyZXNBZnRlciI6bnVsbCwiaWF0IjoxNzQ1NDMwNzQzLCJpc3MiOiJEYXJ0IEZsdXgifQ.cJSRj21ylxS5ZrhjJkCwXjNMYX70wr6XanAnjT-Z_zs';
  var tokens = await authenticator.loginWithAccessToken(access);
  print(tokens.toJson());
}
