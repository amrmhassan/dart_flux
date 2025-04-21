import 'dart:io';
import 'package:dart_flux/core/errors/server_error.dart';

class AuthError extends ServerError {
  final String errorString;
  final String? errorCode;
  AuthError(this.errorString, {this.errorCode, int? status})
    : super(
        errorString,
        status: status ?? HttpStatus.unauthorized,
        code: errorCode,
      );
}

class UserNotFoundError extends AuthError {
  UserNotFoundError() : super('User not found', errorCode: 'user-not-found');
}

class InvalidPasswordError extends AuthError {
  InvalidPasswordError()
    : super('Invalid password', errorCode: 'invalid-password');
}

class JwtRevokedError extends AuthError {
  JwtRevokedError() : super('Jwt is revoked', errorCode: 'jwt-revoked');
}

class InvalidTokenTypeError extends AuthError {
  InvalidTokenTypeError(String msg)
    : super(msg, errorCode: 'invalid-token-type');
}

class UserAlreadyExistsError extends AuthError {
  UserAlreadyExistsError(String msg)
    : super(msg, errorCode: 'user-already-exists', status: HttpStatus.conflict);
}
