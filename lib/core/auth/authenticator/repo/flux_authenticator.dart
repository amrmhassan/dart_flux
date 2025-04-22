import 'package:dart_flux/constants/global.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/auth_cache_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/auth_db_provider.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_auth_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/models/flux_user.dart';
import 'package:dart_flux/core/auth/auth_provider/models/flux_user_auth.dart';
import 'package:dart_flux/core/auth/authenticator/interface/auth_hashing_interface.dart';
import 'package:dart_flux/core/auth/authenticator/interface/authenticator_interface.dart';
import 'package:dart_flux/core/auth/authenticator/interface/jwt_controller_interface.dart';
import 'package:dart_flux/core/auth/authenticator/models/jwt_payload_model.dart';
import 'package:dart_flux/core/auth/authenticator/models/tokens_model.dart';
import 'package:dart_flux/core/errors/types/auth_errors.dart';

class FluxAuthenticator implements AuthenticatorInterface {
  @override
  JwtControllerInterface jwtController;

  @override
  AuthDbProvider authProvider;

  @override
  AuthHashingInterface hashing;

  @override
  AuthCacheInterface cache;

  FluxAuthenticator({
    required this.jwtController,
    required this.authProvider,
    required this.hashing,
    required this.cache,
  });

  @override
  Future<TokensModel> login(String email, String password) async {
    var authDoc = await authProvider.userAuthByEmail(email);
    if (authDoc == null) {
      throw UserNotFoundError();
    }
    final isValidPassword = await verifyPassword(
      password,
      authDoc.passwordHash,
    );
    if (!isValidPassword) {
      throw InvalidPasswordError();
    }
    final accessToken = await jwtController.generateAccessToken(authDoc.id);
    final refreshToken = await jwtController.generateRefreshToken(authDoc.id);
    return TokensModel(accessToken: accessToken, refreshToken: refreshToken);
  }

  @override
  Future<void> logout(String refreshToken) async {
    var model = await loginWithRefreshToken(refreshToken);
    await invalidateTokens(model.id);
  }

  @override
  Future<TokensModel> refreshAccessToken(String refreshToken) async {
    var model = await loginWithRefreshToken(refreshToken);
    var tokens = jwtController.refreshTokens(refreshToken, model);
    return tokens;
  }

  @override
  Future<TokensModel> register(
    String email,
    String password, {
    Map<String, dynamic>? userData,
  }) async {
    // check for user data
    var userDataExists = await authProvider.userDataByEmail(email);
    if (userDataExists != null) {
      throw UserAlreadyExistsError('User data with this email already exists');
    }
    var userAuthExists = await authProvider.userAuthByEmail(email);
    if (userAuthExists != null) {
      throw UserAlreadyExistsError('User with this email already authorized');
    }

    String id = dartID.generate();
    FluxUser user = FluxUser(email: email, id: id, data: userData);

    await authProvider.saveUserData(user);
    String passwordHash = await hashing.hash(password);
    FluxUserAuth auth = FluxUserAuth(
      id: id,
      email: email,
      passwordHash: passwordHash,
    );
    await authProvider.saveUserAuth(auth);
    var accessToken = await jwtController.generateAccessToken(id);
    var refreshToken = await jwtController.generateRefreshToken(id);
    var tokensModel = TokensModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    return tokensModel;
  }

  @override
  Future<bool> verifyPassword(String password, String hash) {
    return hashing.verify(password, hash);
  }

  @override
  Future<void> invalidateTokens(String userId) async {
    await authProvider.revokeTokens(userId);
  }

  @override
  Future<UserAuthInterface> loginWithRefreshToken(String refreshToken) async {
    var model = await jwtController.decodeToken(refreshToken);
    if (model.type != TokenType.refresh) {
      throw InvalidTokenTypeError('Use refresh token');
    }
    var authModel = await authProvider.userAuthById(model.userId);
    if (authModel == null) {
      throw UserNotFoundError();
    }
    return authModel;
  }

  @override
  Future<UserAuthInterface> loginWithAccessToken(String accessToken) async {
    var model = await jwtController.decodeToken(accessToken);
    if (model.type != TokenType.access) {
      throw InvalidTokenTypeError('Use access token');
    }
    var authModel = await authProvider.userAuthById(model.userId);
    if (authModel == null) {
      throw UserNotFoundError();
    }
    return authModel;
  }
}
