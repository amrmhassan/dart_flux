import 'package:dart_flux/core/db/base/mongo/models/coll_ref_mongo.dart';
import 'package:dart_flux/core/db/connection/interface/db_connection_interface.dart';
import 'package:dart_flux/core/db/connection/mongo/repo/mongo_db_connection.dart';
import 'package:dart_flux/core/errors/types/not_found_error.dart';
import 'package:dart_flux/core/server/parser/models/bytes_form_data.dart';
import 'package:dart_flux/core/server/routing/interface/model_repository_interface.dart';
import 'package:dart_flux/core/server/routing/models/model.dart';
import 'package:mongo_dart/mongo_dart.dart';

//! here i need a class to get the form and have a method that returns a model
class FluxModelRepo<T> implements ModelRepositoryInterface {
  FluxModelRepo(this.connection, this.entity);
  CollRefMongo get collection => connection.collection(entity);
  @override
  Future<Json> delete(String id) {
    throw UnimplementedError();
  }

  @override
  Future<List<Json>> getAll({
    Map<String, dynamic>? filter,
    int? limit,
    int? offset,
  }) async {
    var selector = where;
    if (filter != null) {
      for (var key in filter.keys) {
        selector = selector.eq(key, filter[key]);
      }
    }
    if (limit != null) {
      selector = selector.limit(limit);
    }
    if (offset != null) {
      selector = selector.skip(offset);
    }
    var docs = await collection.futureFind(selector);
    return docs;
  }

  @override
  Future<Json> getById(String id) async {
    var doc = await collection.doc(id).getData();
    if (doc == null) {
      throw NotFoundError('$entity with id $id not found');
    }
    return doc;
  }

  @override
  Future<Json> insert(BytesFormData json) async {
    throw UnimplementedError();
  }

  @override
  Future<Json> update(String id, BytesFormData json) {
    throw UnimplementedError();
  }

  @override
  DbConnectionInterface get dbConnection => connection;
  MongoDbConnection connection;

  @override
  String entity;

  @override
  set dbConnection(DbConnectionInterface _dbConnection) {
    throw UnimplementedError();
  }
}
