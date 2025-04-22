import 'package:dart_flux/core/auth/auth_provider/repo/flux_memory_auth_cache.dart';
import 'package:dart_flux/core/server/routing/models/model.dart';
import 'package:test/test.dart';
import 'package:dart_flux/core/auth/authenticator/models/jwt_payload_model.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_auth_interface.dart';

void main() {
  group('FluxMemoryAuthCache', () {
    late FluxMemoryAuthCache cache;
    const testToken = 'token123';
    const testRefreshToken = 'refresh123';
    const testId = 'user123';
    const testEmail = 'user@example.com';
    final jwtPayload = JwtPayloadModel(
      userId: 'user123',
      issuedAt: DateTime.now(),
      type: TokenType.access,
    );

    setUp(() {
      cache = FluxMemoryAuthCache(
        allowCache: true,
        cacheDuration: Duration(seconds: 1),
      );
    });

    test('set and get access token', () async {
      cache.setAccessToken(testToken, jwtPayload);
      final result = await cache.getAccessToken(testToken);
      expect(result, isNotNull);
      expect(result!.userId, equals(jwtPayload.userId));
    });

    test('set and get refresh token', () async {
      cache.addRefreshToken(testRefreshToken, jwtPayload);
      final result = await cache.getRefreshToken(testRefreshToken);
      expect(result, isNotNull);
      expect(result!.userId, equals(jwtPayload.userId));
    });

    test('set and get user', () async {
      final user = MockUser();
      cache.setUser(testId, user);
      final result = await cache.getUser(testId);
      expect(result, isNotNull);
      expect(result!.email, equals(user.email));
    });

    test('set and get auth', () async {
      final auth = MockUserAuth();
      cache.setAuth(testId, auth);
      final result = await cache.getAuth(testId);
      expect(result, isNotNull);
      expect(result!.email, equals(auth.email));
    });

    test('assign and get email id', () async {
      await cache.assignIdToEmail(testEmail, testId);
      final result = await cache.getIdByEmail(testEmail);
      expect(result, equals(testId));
    });

    test('remove access token', () async {
      cache.setAccessToken(testToken, jwtPayload);
      cache.removeAccessToken(testToken);
      final result = await cache.getAccessToken(testToken);
      expect(result, isNull);
    });

    test('remove refresh token', () async {
      cache.addRefreshToken(testRefreshToken, jwtPayload);
      cache.removeRefreshToken(testRefreshToken);
      final result = await cache.getRefreshToken(testRefreshToken);
      expect(result, isNull);
    });

    test('remove auth', () async {
      final auth = MockUserAuth();
      cache.setAuth(testId, auth);
      cache.removeAuth(testId);
      final result = await cache.getAuth(testId);
      expect(result, isNull);
    });

    test('remove user', () async {
      final user = MockUser();
      cache.setUser(testId, user);
      cache.removeUser(testId);
      final result = await cache.getUser(testId);
      expect(result, isNull);
    });

    test('remove assigned email id', () async {
      await cache.assignIdToEmail(testEmail, testId);
      await cache.removeAssignedId(testEmail);
      final result = await cache.getIdByEmail(testEmail);
      expect(result, isNull);
    });

    test('clear all cache', () async {
      final auth = MockUserAuth();
      final user = MockUser();

      cache
        ..setAccessToken(testToken, jwtPayload)
        ..addRefreshToken(testRefreshToken, jwtPayload)
        ..setAuth(testId, auth)
        ..setUser(testId, user);

      await cache.clearAllCache();

      expect(await cache.getAccessToken(testToken), isNull);
      expect(await cache.getRefreshToken(testRefreshToken), isNull);
      expect(await cache.getAuth(testId), isNull);
      expect(await cache.getUser(testId), isNull);
    });

    test('respects allowCache = false', () async {
      final noCache = FluxMemoryAuthCache(allowCache: false);
      noCache.setAccessToken(testToken, jwtPayload);
      expect(await noCache.getAccessToken(testToken), isNull);
    });

    test('expires after duration', () async {
      cache.setAccessToken(testToken, jwtPayload);
      await Future.delayed(Duration(seconds: 2));
      final result = await cache.getAccessToken(testToken);
      expect(result, isNull);
    });
  });
}

// Mock Implementations

class MockUser implements UserInterface {
  @override
  String id = 'user123';

  @override
  String email = 'user@example.com';

  @override
  Map<String, dynamic>? data = {'role': 'tester'};

  @override
  Json toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class MockUserAuth implements UserAuthInterface {
  @override
  String id = 'auth123';

  @override
  String passwordHash = 'hashedPassword';

  @override
  String email = 'user@example.com';

  @override
  DateTime? revokeDate = null;

  @override
  Json toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
