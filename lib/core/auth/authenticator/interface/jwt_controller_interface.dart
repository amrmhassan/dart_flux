import 'package:dart_flux/core/auth/authenticator/models/tokens_model.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

abstract class JwtControllerInterface {
  late Duration? accessTokenExpiry;
  late Duration? refreshTokenExpiry;
  late String jwtSecret;
  late JWTAlgorithm jwtAlgorithm;

  String generateAccessToken(Map<String, dynamic> payload);
  String generateRefreshToken(Map<String, dynamic> payload);
  Map<String, dynamic> verifyToken(String token);
  Map<String, dynamic> decodeToken(String token);
  bool isTokenExpired(String token);
  TokensModel refreshTokens(String refreshToken);
}
