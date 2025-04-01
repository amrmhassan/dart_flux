import 'dart:io';

import 'package:dart_flux/core/server/execution/repo/server.dart';
import 'package:dart_flux/core/server/routing/models/router.dart';
import 'package:dart_flux/core/server/utils/send_response.dart';

void main(List<String> args) async {
  Router router = Router.path('/user')
      .get('', (request, response, pathArgs) {
        return SendResponse.data(response, 'list of users');
      })
      .post('', (request, response, pathArgs) {
        return SendResponse.data(response, 'user added');
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
