import 'dart:io';
import 'package:dart_flux/constants/global.dart';
import 'package:dart_flux/core/auth/authenticator/interface/jwt_controller_interface.dart';
import 'package:dart_flux/core/errors/error_string.dart';
import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class FluxJwtController implements JwtControllerInterface {
  @override
  Duration? accessTokenExpiry;

  @override
  JWTAlgorithm jwtAlgorithm;

  @override
  String jwtSecret;

  @override
  Duration? refreshTokenExpiry;

  FluxJwtController({
    required this.accessTokenExpiry,
    required this.jwtAlgorithm,
    required this.jwtSecret,
    required this.refreshTokenExpiry,
  });

  @override
  Map<String, dynamic> decodeToken(String token) {
    try {
      final jwt = JWT.decode(token);
      return jwt.payload as Map<String, dynamic>;
    } on JWTException catch (e, s) {
      throw ServerError(
        errorString.invalidToken,
        status: HttpStatus.unauthorized,
        code: errorCode.invalidToken,
        description: e,
        trace: s,
      );
    }
  }

  @override
  String generateAccessToken(Map<String, dynamic> payload) {
    final jwt = JWT(payload, issuer: frameworkName);
    return jwt.sign(
      SecretKey(jwtSecret),
      expiresIn: accessTokenExpiry,
      algorithm: jwtAlgorithm,
    );
  }

  @override
  String generateRefreshToken(Map<String, dynamic> payload) {
    final jwt = JWT(payload, issuer: frameworkName);
    return jwt.sign(
      SecretKey(jwtSecret),
      expiresIn: refreshTokenExpiry,
      algorithm: jwtAlgorithm,
    );
  }

  @override
  bool isTokenExpired(String token) {
    try {
      JWT.verify(token, SecretKey(jwtSecret));
      return false;
    } on JWTExpiredException catch (_) {
      return true;
    }
  }

  @override
  Map<String, String> refreshTokens(String refreshToken) {
    try {
      final payload = verifyToken(refreshToken);
      final newAccessToken = generateAccessToken(payload);
      final newRefreshToken = generateRefreshToken(payload);
      return {'accessToken': newAccessToken, 'refreshToken': newRefreshToken};
    } on JWTExpiredException catch (e, s) {
      throw ServerError(
        errorString.loginAgain,
        description: e,
        status: HttpStatus.unauthorized,
        code: errorCode.loginAgain,
        trace: s,
      );
    } catch (e, s) {
      throw ServerError(
        errorString.invalidToken,
        description: e,
        status: HttpStatus.unauthorized,
        code: errorCode.invalidToken,
        trace: s,
      );
    }
  }

  @override
  Map<String, dynamic> verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(jwtSecret));
      var payload = jwt.payload as Map<String, dynamic>;
      return payload;
    } on JWTExpiredException catch (e, s) {
      throw ServerError(
        errorString.jwtExpired,
        trace: s,
        status: HttpStatus.unauthorized,
        code: errorCode.jwtExpired,
      );
    } catch (e, s) {
      throw ServerError(
        errorString.invalidToken,
        status: HttpStatus.unauthorized,
        description: e,
        trace: s,
        code: errorCode.invalidToken,
      );
    }
  }
}
