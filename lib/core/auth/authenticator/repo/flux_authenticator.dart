import 'package:dart_flux/core/auth/auth_provider/interface/user_auth_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_interface.dart';
import 'package:dart_flux/core/auth/authenticator/interface/authenticator_interface.dart';
import 'package:dart_flux/core/auth/authenticator/interface/jwt_controller_interface.dart';
import 'package:dart_flux/core/auth/authenticator/repo/flux_jwt_controller.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class FluxAuthenticator implements AuthenticatorInterface {
  @override
  String jwtSecret;

  @override
  Duration? accessTokenExpiry;

  @override
  Duration? refreshTokenExpiry;

  @override
  JWTAlgorithm jwtAlgorithm;

  late JwtControllerInterface _jwt;

  FluxAuthenticator({
    required this.jwtSecret,
    this.accessTokenExpiry = const Duration(minutes: 15),
    this.refreshTokenExpiry = const Duration(days: 7),
    this.jwtAlgorithm = JWTAlgorithm.RS256,
  }) {
    _jwt = FluxJwtController(
      accessTokenExpiry: accessTokenExpiry,
      jwtAlgorithm: jwtAlgorithm,
      jwtSecret: jwtSecret,
      refreshTokenExpiry: refreshTokenExpiry,
    );
  }

  @override
  Future<UserAuthInterface?> login(String email, String password) {
    // TODO: implement login
    throw UnimplementedError();
  }

  @override
  Future<void> logout(String refreshToken) {
    // TODO: implement logout
    throw UnimplementedError();
  }

  @override
  Future<String> refreshAccessToken(String refreshToken) {
    // TODO: implement refreshAccessToken
    throw UnimplementedError();
  }

  @override
  Future<void> register(UserInterface user, String password) {
    // TODO: implement register
    throw UnimplementedError();
  }

  @override
  Future<bool> verifyPassword(String password, String hash) {
    // TODO: implement verifyPassword
    throw UnimplementedError();
  }
}
