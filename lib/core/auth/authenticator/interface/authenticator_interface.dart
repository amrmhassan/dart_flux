import 'package:dart_flux/core/auth/auth_provider/interface/user_auth_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_interface.dart';

abstract class AuthenticatorInterface {
  Future<UserAuthInterface?> login(String email, String password);
  Future<void> register(UserInterface user, String password);
  // password/verification
  Future<bool> verifyPassword(String password, String hash);
  Future<String> generateAccessToken(UserInterface user);
  Future<String> generateRefreshToken(UserInterface user);
  Future<String> refreshAccessToken(String refreshToken);
  Future<void> logout(String refreshToken);
}
