import 'dart:typed_data';
import 'dart:math';
import 'package:dart_flux/core/auth/authenticator/interface/auth_hashing_interface.dart';
import 'package:argon2/argon2.dart';
import 'package:dart_flux/core/errors/server_error.dart';
import 'package:hex/hex.dart';

class FluxAuthHashing implements AuthHashingInterface {
  final Argon2BytesGenerator _argon2;

  FluxAuthHashing() : _argon2 = Argon2BytesGenerator();

  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
  }

  @override
  Future<String> hash(String plain) async {
    try {
      final salt = _generateSalt();
      final parameters = Argon2Parameters(
        Argon2Parameters.ARGON2_id,
        salt,
        version: Argon2Parameters.ARGON2_VERSION_13,
        iterations: 3,
        memoryPowerOf2: 16,
      );

      _argon2.init(parameters);
      final passwordBytes = parameters.converter.convert(plain);
      final result = Uint8List(32);
      _argon2.generateBytes(passwordBytes, result, 0, result.length);

      return '${salt.toHexString()}:${result.toHexString()}';
    } catch (e) {
      throw ServerError('Error hashing password');
    }
  }

  @override
  Future<bool> verify(String plain, String hashed) async {
    try {
      final parts = hashed.split(':');
      if (parts.length != 2) return false;

      final salt = Uint8List.fromList(HEX.decode(parts[0]));
      // Removed unused variable 'hashedBytes'

      final parameters = Argon2Parameters(
        Argon2Parameters.ARGON2_id,
        salt,
        version: Argon2Parameters.ARGON2_VERSION_13,
        iterations: 3,
        memoryPowerOf2: 16,
      );

      _argon2.init(parameters);
      final passwordBytes = parameters.converter.convert(plain);
      final result = Uint8List(32);
      _argon2.generateBytes(passwordBytes, result, 0, result.length);

      return result.toHexString() == parts[1];
    } catch (e) {
      throw ServerError('Error verifying password');
    }
  }
}
