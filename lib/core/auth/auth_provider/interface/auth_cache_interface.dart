// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'package:dart_flux/core/auth/auth_provider/interface/user_auth_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/models/eviction_event.dart';
import 'package:dart_flux/core/auth/authenticator/models/jwt_payload_model.dart';

abstract class AuthCacheInterface {
  late bool allowCache;

  /// this is for just one item lifetime in the cache
  late Duration? cacheDuration;

  /// this will periodically clear all the cache
  late Duration? clearCacheEvery;

  /// Maximum number of entries allowed in each cache map
  /// Set to null for unlimited entries
  late int? maxEntries;

  /// Whether to use true LRU behavior (move accessed items to the end)
  late bool enableLruBehavior;

  /// Stream of cache eviction events
  Stream<EvictionEvent> get onEviction;

  FutureOr<JwtPayloadModel?> getAccessToken(String token);
  FutureOr<void> setAccessToken(String token, JwtPayloadModel payload);
  FutureOr<void> removeAccessToken(String token);

  // for user data with id
  FutureOr<UserInterface?> getUser(String id);
  FutureOr<void> setUser(String id, UserInterface user);
  FutureOr<void> removeUser(String id);

  // for user auth with id
  FutureOr<UserAuthInterface?> getAuth(String id);
  FutureOr<void> setAuth(String id, UserAuthInterface auth);
  FutureOr<void> removeAuth(String id);

  // email => id
  FutureOr<String?> getIdByEmail(String email);
  FutureOr<void> assignIdToEmail(String email, String id);
  FutureOr<void> removeAssignedId(String email);

  // add for refresh tokens
  FutureOr<void> addRefreshToken(String token, JwtPayloadModel payload);
  FutureOr<JwtPayloadModel?> getRefreshToken(String token);
  FutureOr<void> removeRefreshToken(String token);

  FutureOr<void> clearAllCache();

  /// Dispose resources used by the cache
  void dispose();
}
