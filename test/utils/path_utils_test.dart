import 'package:dart_flux/utils/path_utils.dart';
import 'package:test/test.dart';

void main() {
  group('PathUtils.pathMatches', () {
    test('Exact match', () {
      expect(
        PathUtils.pathMatches(requestPath: '/home', handlerPath: '/home'),
        isTrue,
      );
    });

    test('Mismatch', () {
      expect(
        PathUtils.pathMatches(requestPath: '/home', handlerPath: '/dashboard'),
        isFalse,
      );
    });

    test('Match with single parameter', () {
      expect(
        PathUtils.pathMatches(
          requestPath: '/user/123',
          handlerPath: '/user/:id',
        ),
        isTrue,
      );
    });

    test('Match with multiple parameters', () {
      expect(
        PathUtils.pathMatches(
          requestPath: '/user/123/profile',
          handlerPath: '/user/:id/profile',
        ),
        isTrue,
      );
    });

    test('Mismatch due to extra request segments', () {
      expect(
        PathUtils.pathMatches(
          requestPath: '/user/123/profile/settings',
          handlerPath: '/user/:id/profile',
        ),
        isFalse,
      );
    });

    test('Wildcard match', () {
      expect(
        PathUtils.pathMatches(
          requestPath: '/user/123/settings',
          handlerPath: '/user/*',
        ),
        isTrue,
      );
    });

    test('Wildcard match with deep nesting', () {
      expect(
        PathUtils.pathMatches(
          requestPath: '/user/123/settings/security',
          handlerPath: '/user/*',
        ),
        isTrue,
      );
    });

    test('Wildcard at the end only', () {
      expect(
        PathUtils.pathMatches(requestPath: '/user/123', handlerPath: '/user/*'),
        isTrue,
      );
    });

    test('Mismatch due to fewer request segments', () {
      expect(
        PathUtils.pathMatches(requestPath: '/user', handlerPath: '/user/:id'),
        isFalse,
      );
    });
  });

  group('PathUtils.extractParams', () {
    test('Extract single parameter', () {
      expect(PathUtils.extractParams('/user/123', '/user/:id'), {'id': '123'});
    });

    test('Extract multiple parameters', () {
      expect(
        PathUtils.extractParams(
          '/user/123/profile/456',
          '/user/:id/profile/:profileId',
        ),
        {'id': '123', 'profileId': '456'},
      );
    });

    test('No parameters in handler', () {
      expect(PathUtils.extractParams('/home', '/home'), {});
    });

    test('Mismatch does not extract params', () {
      expect(PathUtils.extractParams('/home', '/dashboard'), {});
    });

    test('Extra segments ignored in extraction', () {
      expect(
        PathUtils.extractParams('/user/123/profile', '/user/:id/profile'),
        {'id': '123'},
      );
    });
  });
}
