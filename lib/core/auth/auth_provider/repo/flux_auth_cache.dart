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
  @override
  FutureOr<void> addAccessToken(String token, JwtPayloadModel payload) {
    if (!allowCache) return null;
    _accessTokenCache[token] = CachedItem(payload, expiresAfter: cacheDuration);
  }

  @override
  FutureOr<void> addAuth(String id, UserAuthInterface auth) {
    if (!allowCache) return null;

    _authCache[id] = CachedItem(auth, expiresAfter: cacheDuration);
  }

  @override
  FutureOr<void> addUser(String id, UserInterface user) {
    if (!allowCache) return null;

    _userCache[id] = CachedItem(user, expiresAfter: cacheDuration);
  }

  @override
  FutureOr<JwtPayloadModel?> getAccessToken(String token) async {
    if (!allowCache) return null;

    var cache = _accessTokenCache[token];
    if (cache == null) return null;
    if (cache.isExpired) {
      await removeAccessToken(token);
      return null;
    }
    return cache.value;
  }

  @override
  FutureOr<UserAuthInterface?> getAuth(String id) async {
    if (!allowCache) return null;

    var cache = _authCache[id];
    if (cache == null) return null;
    if (cache.isExpired) {
      await removeAuth(id);
      return null;
    }
    return cache.value;
  }

  @override
  FutureOr<UserInterface?> getUser(String id) async {
    if (!allowCache) return null;

    var cache = _userCache[id];
    if (cache == null) return null;
    if (cache.isExpired) {
      await removeUser(id);
      return null;
    }
    return cache.value;
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
    _userCache.clear();
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
    if (!allowCache) return null;

    var cache = _refreshTokenCache[token];
    if (cache == null) return null;
    if (cache.isExpired) {
      removeRefreshToken(token);
      return null;
    }
    return cache.value;
  }

  @override
  FutureOr<void> removeRefreshToken(String token) {
    _refreshTokenCache.remove(token);
  }
}
