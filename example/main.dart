import 'package:dart_flux/core/app/models/fast_flux_app.dart';
import 'package:dart_flux/core/server/routing/repo/crud_router.dart';
import 'package:dart_flux/core/server/routing/repo/router.dart';
import 'package:dart_flux/core/server/utils/send_response.dart';

import '../test/integration/constants/test_processors.dart';

void main(List<String> args) async {
  var pathRouter = CrudRouter('path');
  Router router = Router()
      .router(pathRouter)
      .get('/', Processors.file)
      .post('/userForm', Processors.bytesFormBodyNoFiles)
      .get('/hello/:id', (request, response, pathArgs) {
        return SendResponse.data(response, 'hello user, ${pathArgs['id']}');
      })
      .post('/', (request, response, pathArgs) {
        return SendResponse.data(response, {'msg': 'Hello'});
      })
      .get('/before/*', (request, response, pathArgs) {
        return SendResponse.data(response, {'path': pathArgs});
      })
      .delete('/:id', (request, response, pathArgs) {
        return SendResponse.data(
          response,
          'user with ${pathArgs['id']} will be deleted',
        );
      });

  FastFluxApp app = FastFluxApp(pathRouter, port: 3000);
  await app.run();
}
