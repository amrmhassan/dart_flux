import 'package:dart_flux/core/auth/auth_provider/interface/auth_cache_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_auth_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_interface.dart';
import 'package:dart_flux/core/db/connection/interface/db_connection_interface.dart';

abstract class AuthDbProvider {
  late DbConnectionInterface dbConnection;
  late AuthCacheInterface cache;
  // user data
  Future<UserInterface?> userDataById(String id);
  Future<UserAuthInterface?> userAuthById(String id);
  Future<UserInterface?> userDataByEmail(String email);
  Future<UserAuthInterface?> userAuthByEmail(String email);
  Future<void> saveUserData(UserInterface user);
  Future<void> saveUserAuth(UserAuthInterface auth);
  Future<void> updateUserData(UserInterface user);
  Future<void> updateUserAuth(UserAuthInterface auth);
  Future<bool> userAuthExists(String email);
  Future<bool> userDataExists(String email);
  Future<void> revokeTokens(String id);
}
