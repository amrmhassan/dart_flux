import 'package:dart_flux/core/server/routing/interface/model_repository_interface.dart';
import 'package:dart_flux/core/server/routing/repo/router.dart';
import 'package:dart_flux/core/server/routing/repo/test_model_repository.dart';
import 'package:dart_flux/core/server/utils/send_response.dart';

class CrudRouter {
  static Router init(String entity, {ModelRepositoryInterface? repo}) {
    ModelRepositoryInterface finalRepo = repo ?? TestModelRepository();
    return generateCrudRouter(Router.path(entity), finalRepo);
  }

  static Router generateCrudRouter(
    Router router,
    ModelRepositoryInterface repo,
  ) {
    router = router
        .get(
          '/',
          (req, res, pathArgs) async =>
              SendResponse.json(res, await repo.getAll()),
          signature: 'get all models',
        )
        .get('/:id', (req, res, pathArgs) async {
          final id = pathArgs['id'];
          final data = await repo.getById(id);
          return SendResponse.json(res, data);
        }, signature: 'get single model by id')
        .post('/', (req, res, pathArgs) async {
          final json = await req.bytesForm();
          var model = await repo.insert(json);
          return SendResponse.json(res, model);
        }, signature: 'add new model')
        .put('/:id', (req, res, pathArgs) async {
          final id = pathArgs['id'];
          final json = await req.asJson;
          var updated = await repo.update(id, json);
          return SendResponse.json(res, updated);
        }, signature: 'update a model')
        .delete('/:id', (req, res, pathArgs) async {
          final id = pathArgs['id'];
          var deleted = await repo.delete(id);
          return SendResponse.json(res, deleted);
        }, signature: 'deletes a model');
    return router;
  }
}
