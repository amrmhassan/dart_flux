import 'package:dart_flux/core/db/connection/interface/db_connection_interface.dart';
import 'package:dart_flux/core/server/parser/models/bytes_form_data.dart';
import 'package:dart_flux/core/server/routing/models/model.dart';

abstract class ModelRepositoryInterface<T extends Model> {
  late DbConnectionInterface dbConnection;
  late String entity;
  // handle pagination here
  Future<List<Json>> getAll({
    Map<String, dynamic>? filter,
    int? limit,
    int? offset,
  });
  // handle passed id can be null => throw error
  // doc is null throw empty error or not found

  Future<Json> getById(String id);

  Future<Json> insert(BytesFormData json);

  Future<Json> update(String id, BytesFormData json);

  Future<Json> delete(String id);
}
