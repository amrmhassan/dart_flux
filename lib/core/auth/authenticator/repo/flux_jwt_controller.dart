import 'dart:io';
import 'package:dart_flux/constants/date_constants.dart';
import 'package:dart_flux/constants/global.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_auth_interface.dart';
import 'package:dart_flux/core/auth/authenticator/interface/jwt_controller_interface.dart';
import 'package:dart_flux/core/auth/authenticator/models/jwt_payload_model.dart';
import 'package:dart_flux/core/auth/authenticator/models/tokens_model.dart';
import 'package:dart_flux/core/errors/error_string.dart';
import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/errors/types/auth_errors.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class FluxJwtController implements JwtControllerInterface {
  @override
  Duration? accessTokenExpiry;

  @override
  JWTAlgorithm jwtAlgorithm;

  @override
  JWTKey jwtKey;

  @override
  Duration? refreshTokenExpiry;

  FluxJwtController({
    this.accessTokenExpiry,
    this.jwtAlgorithm = JWTAlgorithm.HS256,
    required this.jwtKey,
    this.refreshTokenExpiry,
  });

  @override
  JwtPayloadModel decodeToken(String token) {
    try {
      final jwt = JWT.decode(token);
      var payload = jwt.payload as Map<String, dynamic>;
      JwtPayloadModel model = JwtPayloadModel.fromJson(payload);
      return model;
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
  String generateAccessToken(String userId) {
    var payload = JwtPayloadModel(
      userId: userId,
      issuedAt: utc,
      expiresAfter: accessTokenExpiry?.inSeconds,
      type: TokenType.access,
    );

    final jwt = JWT(payload.toJson(), issuer: frameworkName);
    return jwt.sign(
      jwtKey,
      expiresIn: accessTokenExpiry,
      algorithm: jwtAlgorithm,
    );
  }

  @override
  String generateRefreshToken(String userId) {
    var payload = JwtPayloadModel(
      userId: userId,
      issuedAt: utc,
      expiresAfter: refreshTokenExpiry?.inSeconds,
      type: TokenType.refresh,
    );
    final jwt = JWT(payload.toJson(), issuer: frameworkName);
    return jwt.sign(
      jwtKey,
      expiresIn: refreshTokenExpiry,
      algorithm: jwtAlgorithm,
    );
  }

  @override
  bool isTokenExpired(String token) {
    try {
      JWT.verify(token, jwtKey);
      return false;
    } on JWTExpiredException catch (_) {
      return true;
    }
  }

  @override
  TokensModel refreshTokens(String refreshToken, UserAuthInterface authModel) {
    try {
      final payload = verifyToken(refreshToken, authModel);

      final newAccessToken = generateAccessToken(payload.userId);
      final newRefreshToken = generateRefreshToken(payload.userId);
      return TokensModel(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
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
  JwtPayloadModel verifyToken(String token, UserAuthInterface authModel) {
    try {
      final jwt = JWT.verify(token, jwtKey);
      var payload = jwt.payload as Map<String, dynamic>;
      JwtPayloadModel model = JwtPayloadModel.fromJson(payload);
      // here check if the token is revoked or not from the auth model
      if (model.isRevoked(authModel.revokeDate)) {
        throw JwtRevokedError();
      }

      return model;
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
