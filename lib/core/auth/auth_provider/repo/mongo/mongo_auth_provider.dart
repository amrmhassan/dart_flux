import 'package:dart_flux/constants/date_constants.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/auth_cache_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/auth_db_provider.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_auth_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/interface/user_interface.dart';
import 'package:dart_flux/core/auth/auth_provider/models/flux_user.dart';
import 'package:dart_flux/core/auth/auth_provider/models/flux_user_auth.dart';
import 'package:dart_flux/core/auth/auth_provider/repo/flux_memory_auth_cache.dart';
import 'package:dart_flux/core/auth/constants/auth_constants.dart';
import 'package:dart_flux/core/db/connection/interface/db_connection_interface.dart';
import 'package:dart_flux/core/errors/types/auth_errors.dart';
import 'package:dart_flux/db_service_export.dart';
import 'package:mongo_dart/mongo_dart.dart';

// how to inject a type to a class and the type is a child of another class
// like the dbConnection here will always be a MongoDbConnection not a DbConnectionInterface
class MongoAuthProvider implements AuthDbProvider {
  MongoAuthProvider(this._dbConnection, {AuthCacheInterface? cache}) {
    this.cache = cache ?? FluxMemoryAuthCache();
  }

  CollRefMongo get authData =>
      dbConnection.collection(AuthCollections.authData);
  CollRefMongo get userData =>
      dbConnection.collection(AuthCollections.userData);

  @override
  Future<void> saveUserAuth(UserAuthInterface auth) async {
    await authData.doc(auth.id).set(auth.toJson());
    await cache.setAuth(auth.id, auth);
  }

  @override
  Future<void> saveUserData(UserInterface user) async {
    await userData.doc(user.id).set(user.toJson());
    await cache.setUser(user.id, user);
  }

  @override
  Future<void> updateUserAuth(UserAuthInterface auth) async {
    await authData.doc(auth.id).update(auth.toJson());
    await cache.setAuth(auth.id, auth);
    await cache.assignIdToEmail(auth.email, auth.id);
  }

  @override
  Future<void> updateUserData(UserInterface user) async {
    await userData.doc(user.id).update(user.toJson());
    await cache.setUser(user.id, user);
    await cache.assignIdToEmail(user.email, user.id);
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
    String? id = await cache.getIdByEmail(email);
    if (id != null) {
      var auth = await cache.getAuth(id);
      if (auth != null) return auth as FluxUserAuth;
    }
    var selector = where.eq('email', email);
    var doc = await authData.findOne(selector);
    if (doc == null) return null;
    var model = FluxUserAuth.fromJson(doc);
    await cache.setAuth(model.id, model);
    await cache.assignIdToEmail(email, model.id);
    return model;
  }

  @override
  Future<FluxUserAuth?> userAuthById(String id) async {
    var cached = await cache.getAuth(id);
    if (cached != null) return cached as FluxUserAuth;
    var doc = await authData.doc(id).getData();
    if (doc == null) return null;
    var model = FluxUserAuth.fromJson(doc);
    await cache.setAuth(model.id, model);
    return model;
  }

  @override
  Future<FluxUser?> userDataByEmail(String email) async {
    String? id = await cache.getIdByEmail(email);
    if (id != null) {
      var user = await cache.getUser(id);
      if (user != null) return user as FluxUser;
    }
    var selector = where.eq('email', email);
    var doc = await userData.findOne(selector);
    if (doc == null) return null;
    var model = FluxUser.fromJson(doc);
    await cache.setUser(model.id, model);
    await cache.assignIdToEmail(email, model.id);
    return model;
  }

  @override
  Future<FluxUser?> userDataById(String id) async {
    var cached = await cache.getUser(id);
    if (cached != null) return cached as FluxUser;
    var doc = await userData.doc(id).getData();
    if (doc == null) return null;
    var model = FluxUser.fromJson(doc);
    await cache.setUser(model.id, model);
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
    await cache.removeAuth(id);
    await cache.removeUser(id);
    await cache.removeAssignedId(auth.email);
  }

  @override
  late AuthCacheInterface cache;
}
