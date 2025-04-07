import 'package:dart_flux/core/server/parser/models/bytes_form_data.dart';
import 'package:dart_flux/core/server/routing/interface/model_repository_interface.dart';
import 'package:dart_flux/core/server/routing/models/model.dart';

var _testModel = {'id': 'id', 'name': 'Amr'};

class TestModelRepository implements ModelRepositoryInterface {
  @override
  Future<Json> delete(String? id) {
    return Future.value(_testModel);
  }

  @override
  Future<List<Json>> getAll() {
    return Future.value([_testModel]);
  }

  @override
  Future<Json> getById(String? id) {
    return Future.value(_testModel);
  }

  @override
  Future<Json> insert(BytesFormData json) {
    return Future.value(_testModel);
  }

  @override
  Future<Json> update(String? id, Json updateData) {
    return Future.value(_testModel);
  }
}
