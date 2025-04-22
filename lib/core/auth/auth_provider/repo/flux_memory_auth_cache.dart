// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:dart_flux/core/auth/auth_provider/interface/auth_cache_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_auth_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/models/cached_item.dart';
import 'package:dart_flux/core/auth/authenticator/models/jwt_payload_model.dart';

class FluxMemoryAuthCache implements AuthCacheInterface {
  Map<String, CachedItem<JwtPayloadModel>> _accessTokenCache = {};
  Map<String, CachedItem<JwtPayloadModel>> _refreshTokenCache = {};
  Map<String, CachedItem<UserAuthInterface>> _authCache = {};
  Map<String, CachedItem<UserInterface>> _userCache = {};
  Map<String, String> _emailIdCache = {};

  T? _getValidCache<T>(
    Map<String, CachedItem<T>> map,
    String key,
    void Function(String) onRemove,
  ) {
    var cache = map[key];
    if (cache == null) return null;
    if (cache.isExpired) {
      onRemove(key);
      return null;
    }
    return cache.value;
  }

  @override
  FutureOr<void> setAccessToken(String token, JwtPayloadModel payload) {
    if (!allowCache) return null;
    _accessTokenCache[token] = CachedItem(payload, expiresAfter: cacheDuration);
  }

  @override
  FutureOr<void> setAuth(String id, UserAuthInterface auth) {
    if (!allowCache) return null;

    _authCache[id] = CachedItem(auth, expiresAfter: cacheDuration);
  }

  @override
  FutureOr<void> setUser(String id, UserInterface user) {
    if (!allowCache) return null;

    _userCache[id] = CachedItem(user, expiresAfter: cacheDuration);
  }

  @override
  FutureOr<JwtPayloadModel?> getAccessToken(String token) async {
    return _getValidCache(_accessTokenCache, token, removeAccessToken);
  }

  @override
  FutureOr<UserAuthInterface?> getAuth(String id) async {
    return _getValidCache(_authCache, id, removeAuth);
  }

  @override
  FutureOr<UserInterface?> getUser(String id) async {
    return _getValidCache(_userCache, id, removeUser);
  }

  @override
  FutureOr<void> removeAccessToken(String token) {
    _accessTokenCache.remove(token);
  }

  @override
  FutureOr<void> removeAuth(String id) {
    _authCache.remove(id);
  }

  @override
  FutureOr<void> removeUser(String id) {
    _userCache.remove(id);
  }

  @override
  bool allowCache;

  @override
  Duration? cacheDuration;
  FluxMemoryAuthCache({
    this.allowCache = true,
    this.cacheDuration = const Duration(minutes: 5),
    this.clearCacheEvery,
  }) {
    if (clearCacheEvery != null) {
      Timer.periodic(clearCacheEvery!, (v) => clearAllCache());
    }
  }

  @override
  FutureOr<void> clearAllCache() {
    _accessTokenCache.clear();
    _authCache.clear();
    _refreshTokenCache.clear();
    _userCache.clear();
    _emailIdCache.clear();
  }

  @override
  Duration? clearCacheEvery;

  @override
  FutureOr<void> addRefreshToken(String token, JwtPayloadModel payload) {
    if (!allowCache) return null;
    _refreshTokenCache[token] = CachedItem(
      payload,
      expiresAfter: cacheDuration,
    );
  }

  @override
  FutureOr<JwtPayloadModel?> getRefreshToken(String token) {
    return _getValidCache(_refreshTokenCache, token, removeRefreshToken);
  }

  @override
  FutureOr<void> removeRefreshToken(String token) {
    _refreshTokenCache.remove(token);
  }

  @override
  FutureOr<void> assignIdToEmail(String email, String id) async {
    if (!allowCache) return null;
    _emailIdCache[email] = id;
  }

  @override
  FutureOr<String?> getIdByEmail(String email) {
    return _emailIdCache[email];
  }

  @override
  FutureOr<void> removeAssignedId(String email) {
    _emailIdCache.remove(email);
  }
}
