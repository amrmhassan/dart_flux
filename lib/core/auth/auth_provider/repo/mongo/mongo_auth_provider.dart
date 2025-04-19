import 'package:dart_flux/core/auth/auth_provider/interface/auth_db_provider.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_auth_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_interface.dart';
import 'package:dart_flux/core/auth/constants/auth_constants.dart';
import 'package:dart_flux/core/db/connection/interface/db_connection_interface.dart';
import 'package:dart_flux/db_service_export.dart';

// how to inject a type to a class and the type is a child of another class
// like the dbConnection here will always be a MongoDbConnection not a DbConnectionInterface
class MongoAuthProvider implements AuthDbProvider {
  MongoAuthProvider(this._dbConnection);

  CollRefMongo get authData =>
      dbConnection.collection(AuthCollections.authData);
  CollRefMongo get userData =>
      dbConnection.collection(AuthCollections.userData);

  @override
  Future<void> saveUserAuth(UserAuthInterface auth) async {
    await authData.doc(auth.id).set(auth.toJson());
  }

  @override
  Future<void> saveUserData(UserInterface user) async {
    await userData.doc(user.id).set(user.toJson());
  }

  @override
  Future<void> updateUserAuth(UserAuthInterface auth) async {
    await authData.doc(auth.id).update(auth.toJson());
  }

  @override
  Future<void> updateUserData(UserInterface user) async {
    await userData.doc(user.id).update(user.toJson());
  }

  @override
  Future<bool> userAuthExists(String id) {
    // TODO: implement userAuthExists
    throw UnimplementedError();
  }

  @override
  MongoDbConnection get dbConnection => _dbConnection;

  final MongoDbConnection _dbConnection;

  @override
  set dbConnection(DbConnectionInterface _dbConnection) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>?> userAuthByEmail(String email) {
    // TODO: implement userAuthByEmail
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>?> userAuthById(String id) {
    // TODO: implement userAuthById
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>?> userDataByEmail(String email) {
    // TODO: implement userDataByEmail
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>?> userDataById(String id) {
    // TODO: implement userDataById
    throw UnimplementedError();
  }

  @override
  Future<bool> userDataExists(String email) {
    // TODO: implement userDataExists
    throw UnimplementedError();
  }
}
