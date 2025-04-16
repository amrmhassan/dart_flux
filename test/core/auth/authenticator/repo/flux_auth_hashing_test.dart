// Unit Test file for flux_auth_hashing.dart

import 'package:test/test.dart';
import 'package:dart_flux/core/auth/authenticator/repo/flux_auth_hashing.dart';

void main() {
  group('FluxAuthHashing', () {
    final fluxAuthHashing = FluxAuthHashing();

    test('hash should return a valid hash string', () async {
      final plainText = 'password123';
      final hash = await fluxAuthHashing.hash(plainText);

      expect(hash, isNotEmpty);
      expect(hash.split(':').length, 2);
    });

    test('verify should return true for a valid hash', () async {
      final plainText = 'password123';
      final hash = await fluxAuthHashing.hash(plainText);

      final isValid = await fluxAuthHashing.verify(plainText, hash);
      expect(isValid, isTrue);
    });

    test('verify should return false for an invalid hash', () async {
      final plainText = 'password123';
      final invalidHash = 'invalid:salt';

      final isValid = await fluxAuthHashing.verify(plainText, invalidHash);
      expect(isValid, isFalse);
    });

    test('should return true', () async {
      var hashed = await fluxAuthHashing.hash('');
      var valid = await fluxAuthHashing.verify('', hashed);
      expect(valid, isTrue);
    });

    test('should return false for verification', () async {
      var res = await fluxAuthHashing.verify('', '');
      expect(res, isFalse);
    });
  });
}
