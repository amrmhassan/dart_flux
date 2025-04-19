import 'package:dart_flux/core/auth/auth_provider/interface/user_auth_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_interface.dart';
import 'package:dart_flux/core/db/connection/interface/db_connection_interface.dart';

abstract class AuthDbProvider {
  late DbConnectionInterface dbConnection;
  // user data
  Future<Map<String, dynamic>?> userDataById(String id);
  Future<Map<String, dynamic>?> userAuthById(String id);
  Future<Map<String, dynamic>?> userDataByEmail(String email);
  Future<Map<String, dynamic>?> userAuthByEmail(String email);
  Future<void> saveUserData(UserInterface user);
  Future<void> saveUserAuth(UserAuthInterface auth);
  Future<void> updateUserData(UserInterface user);
  Future<void> updateUserAuth(UserAuthInterface auth);
  Future<bool> userAuthExists(String id);
  Future<bool> userDataExists(String email);
}
