import 'package:dart_flux/constants/date_constants.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/auth_db_provider.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_auth_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/models/flux_user.dart';
import 'package:dart_flux/core/auth/auth_provider/models/flux_user_auth.dart';
import 'package:dart_flux/core/auth/constants/auth_constants.dart';
import 'package:dart_flux/core/db/connection/interface/db_connection_interface.dart';
import 'package:dart_flux/core/errors/types/auth_errors.dart';
import 'package:dart_flux/db_service_export.dart';
import 'package:mongo_dart/mongo_dart.dart';

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
  Future<bool> userAuthExists(String email) async {
    var userAuth = await userAuthByEmail(email);
    return userAuth != null;
  }

  @override
  MongoDbConnection get dbConnection => _dbConnection;

  final MongoDbConnection _dbConnection;

  @override
  set dbConnection(DbConnectionInterface _dbConnection) {
    throw UnimplementedError();
  }

  @override
  Future<FluxUserAuth?> userAuthByEmail(String email) async {
    var selector = where.eq('email', email);
    var doc = await authData.findOne(selector);
    if (doc == null) return null;
    var model = FluxUserAuth.fromJson(doc);
    return model;
  }

  @override
  Future<FluxUserAuth?> userAuthById(String id) async {
    var doc = await authData.doc(id).getData();
    if (doc == null) return null;
    var model = FluxUserAuth.fromJson(doc);
    return model;
  }

  @override
  Future<FluxUser?> userDataByEmail(String email) async {
    var selector = where.eq('email', email);
    var doc = await userData.findOne(selector);
    if (doc == null) return null;
    var model = FluxUser.fromJson(doc);
    return model;
  }

  @override
  Future<FluxUser?> userDataById(String id) async {
    var doc = await userData.doc(id).getData();
    if (doc == null) return null;
    var model = FluxUser.fromJson(doc);
    return model;
  }

  @override
  Future<bool> userDataExists(String email) async {
    var userData = await userDataByEmail(email);
    return userData != null;
  }

  @override
  Future<void> revokeTokens(String id) async {
    var auth = await userAuthById(id);
    if (auth == null) {
      throw UserNotFoundError();
    }
    auth.revokeDate = utc;
    await updateUserAuth(auth);
  }
}
