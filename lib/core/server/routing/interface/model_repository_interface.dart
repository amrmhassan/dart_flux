import 'package:dart_flux/core/server/routing/models/model.dart';

abstract class ModelRepositoryInterface<T extends Model> {
  // handle pagination here
  Future<List<Json>> getAll();
  // handle passed id can be null => throw error
  // doc is null throw empty error or not found

  Future<Json> getById(String? id);

  Future<Json> insert(Json json);

  Future<Json> update(String? id, Json updateData);

  Future<Json> delete(String? id);
}
