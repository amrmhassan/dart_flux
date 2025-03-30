import 'dart:io';

import 'package:dart_flux/constants/date_constants.dart';
import 'package:dart_flux/core/server/execution/repo/server.dart';
import 'package:dart_flux/core/server/routing/models/handler.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';

void main(List<String> args) async {
  var router = Handler('/hello', HttpMethod.get, (
    request,
    response,
    pathArgs,
  ) async {
    await response
      ..write('Hello world')
      ..close();
    return response;
  }).middleware((request, response, pathArgs) {
    request.context.add('Time', now);
    print('Hello');
    return request;
  });
  Server server = Server(InternetAddress.anyIPv4, 3000, router);
  await server.run();
}
