import 'package:dart_flux/core/auth/auth_provider/interface/user_auth_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_interface.dart';

abstract class AuthDbProvider {
  // user data
  Future<UserInterface?> userDataById(String id);
  Future<UserInterface?> userAuthById(String id);
  Future<UserInterface?> userDataByEmail(String email);
  Future<UserInterface?> userAuthByEmail(String email);
  Future<void> saveUserData(UserInterface user);
  Future<void> saveUserAuth(UserAuthInterface auth);
  Future<void> updateUserData(UserInterface user);
  Future<void> updateUserAuth(UserAuthInterface auth);
  Future<bool> userAuthExists(String id);
  Future<bool> userDataExists(String email);
}
