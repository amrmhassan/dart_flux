import 'package:dart_flux/core/auth/auth_provider/interface/user_auth_interface.dart';
import 'package:dart_flux/core/auth/authenticator/models/jwt_payload_model.dart';
import 'package:dart_flux/core/auth/authenticator/models/tokens_model.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

abstract class JwtControllerInterface {
  late Duration? accessTokenExpiry;
  late Duration? refreshTokenExpiry;
  late String jwtSecret;
  late JWTAlgorithm jwtAlgorithm;

  String generateAccessToken(String userId);
  String generateRefreshToken(String userId);
  JwtPayloadModel verifyToken(String token, UserAuthInterface authModel);
  JwtPayloadModel decodeToken(String token);
  bool isTokenExpired(String token);
  TokensModel refreshTokens(String refreshToken, UserAuthInterface authModel);
}
