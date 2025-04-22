import 'package:dart_flux/core/auth/auth_provider/interface/auth_cache_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/auth_db_provider.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_auth_interface.dart';
import 'package:dart_flux/core/auth/authenticator/interface/auth_hashing_interface.dart';
import 'package:dart_flux/core/auth/authenticator/interface/jwt_controller_interface.dart';
import 'package:dart_flux/core/auth/authenticator/models/tokens_model.dart';

abstract class AuthenticatorInterface {
  late JwtControllerInterface jwtController;
  late AuthDbProvider authProvider;
  late AuthHashingInterface hashing;
  late AuthCacheInterface cache;

  Future<TokensModel> login(String email, String password);
  Future<TokensModel> register(
    String email,
    String password, {
    Map<String, dynamic>? userData,
  });
  // password/verification
  Future<bool> verifyPassword(String password, String hash);
  Future<TokensModel> refreshAccessToken(String refreshToken);
  Future<void> logout(String refreshToken);
  Future<void> invalidateTokens(String userId);
  Future<UserAuthInterface> loginWithRefreshToken(String refreshToken);
  Future<UserAuthInterface> loginWithAccessToken(String accessToken);
}
