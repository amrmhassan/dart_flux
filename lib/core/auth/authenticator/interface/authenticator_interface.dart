import 'package:dart_flux/core/auth/auth_provider/interface/user_auth_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_interface.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

abstract class AuthenticatorInterface {
  late String jwtSecret;
  late Duration? accessTokenExpiry;
  late Duration? refreshTokenExpiry;
  late JWTAlgorithm jwtAlgorithm;

  Future<UserAuthInterface?> login(String email, String password);
  Future<void> register(UserInterface user, String password);
  // password/verification
  Future<bool> verifyPassword(String password, String hash);
  Future<String> refreshAccessToken(String refreshToken);
  Future<void> logout(String refreshToken);
}
