import 'dart:io';

import 'package:dart_flux/core/server/execution/repo/server.dart';
import 'package:dart_flux/core/server/routing/models/router.dart';
import 'package:dart_flux/core/server/utils/send_response.dart';

import '../test/integration/constants/test_processors.dart';

void main(List<String> args) async {
  Router router = Router()
      .get('/', (request, response, pathArgs) async {
        return SendResponse.data(response, 'name');
      })
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

  Server server = Server(InternetAddress.anyIPv4, 3000, router);
  await server.run();
}
