// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'package:dart_flux/core/auth/auth_provider/interface/user_auth_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_interface.dart';
import 'package:dart_flux/core/auth/authenticator/models/jwt_payload_model.dart';

abstract class AuthCacheInterface {
  late bool allowCache;

  /// this is for just one item lifetime in the cache
  late Duration? cacheDuration;

  /// this will periodically clear all the cache
  late Duration? clearCacheEvery;

  FutureOr<JwtPayloadModel?> getAccessToken(String token);
  FutureOr<void> addAccessToken(String token, JwtPayloadModel payload);
  FutureOr<void> removeAccessToken(String token);

  FutureOr<UserInterface?> getUser(String id);
  FutureOr<void> addUser(String id, UserInterface user);
  FutureOr<void> removeUser(String id);

  FutureOr<UserAuthInterface?> getAuth(String id);
  FutureOr<void> addAuth(String id, UserAuthInterface auth);
  FutureOr<void> removeAuth(String id);

  // add for refresh tokens
  FutureOr<void> addRefreshToken(String token, JwtPayloadModel payload);
  FutureOr<JwtPayloadModel?> getRefreshToken(String token);
  FutureOr<void> removeRefreshToken(String token);

  FutureOr<void> clearAllCache();
}
